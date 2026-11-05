import 'package:flutter_test/flutter_test.dart';
import 'package:memex/domain/models/data_route.dart';
import 'package:memex/domain/models/llm_config.dart';

LLMConfig config(
  String type, {
  String model = 'm1',
  String apiKey = 'k',
  String baseUrl = '',
}) =>
    LLMConfig(
      key: 'c',
      type: type,
      modelId: model,
      apiKey: apiKey,
      baseUrl: baseUrl,
    );

void main() {
  test('ChatGPT OAuth sends audio to the transcription endpoint, text to chat',
      () {
    final routes = describeDataRoutes(
      config(LLMConfig.typeOpenAiOauth, model: 'gpt-6-luna', apiKey: ''),
    )!;
    expect(routes.transcription.model, 'chatgpt-transcribe');
    expect(routes.transcription.host, 'chatgpt.com');
    expect(routes.chat.model, 'gpt-6-luna');
    expect(routes.chat.host, 'chatgpt.com');
    expect(routes.chat.provider, 'ChatGPT (OAuth)');
  });

  test('an API key provider receives both audio and text at its base URL', () {
    final routes = describeDataRoutes(
      config(
        LLMConfig.typeChatCompletion,
        model: 'gpt-x',
        baseUrl: 'https://api.openai.com/v1',
      ),
    )!;
    expect(routes.transcription.host, 'api.openai.com');
    expect(routes.chat.host, 'api.openai.com');
    expect(routes.transcription.model, 'gpt-x');
    expect(routes.chat.provider, 'OpenAI (API Key)');
  });

  test('the Memex official service never names its model', () {
    final routes = describeDataRoutes(
      config(
        LLMConfig.typeMemex,
        model: 'memex-fast',
        baseUrl: 'https://memex.example/v1',
      ),
    )!;
    expect(routes.chat.model, isEmpty);
    expect(routes.transcription.model, isEmpty);
    expect(routes.chat.provider, 'Memex AI');
    expect(routes.chat.host, 'memex.example');
  });

  test('a local endpoint shows its own host', () {
    final routes = describeDataRoutes(
      config(
        LLMConfig.typeOllama,
        model: 'llama',
        apiKey: '',
        baseUrl: 'http://192.168.0.5:11434/v1',
      ),
    )!;
    expect(routes.chat.host, '192.168.0.5');
  });

  test('providers without a base URL fall back to their known host', () {
    expect(
      describeDataRoutes(config(LLMConfig.typeClaudeOauth, apiKey: ''))!
          .chat
          .host,
      'api.anthropic.com',
    );
    expect(
      describeDataRoutes(config(LLMConfig.typeGeminiOauth, apiKey: ''))!
          .transcription
          .host,
      'generativelanguage.googleapis.com',
    );
  });

  test('no model, or an incomplete one, means nothing is sent', () {
    expect(describeDataRoutes(null), isNull);
    expect(
      describeDataRoutes(config(LLMConfig.typeChatCompletion, apiKey: '')),
      isNull,
    );
    expect(describeDataRoutes(config(LLMConfig.typeOpenAiOauth, model: '')),
        isNull);
  });
}
