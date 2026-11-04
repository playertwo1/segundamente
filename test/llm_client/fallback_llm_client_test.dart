import 'dart:async';

import 'package:dart_agent_core/dart_agent_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/llm_client/fallback_llm_client.dart';

class _MockTestLLMClient extends LLMClient {
  final Future<ModelMessage> Function(ModelConfig modelConfig)? onGenerate;
  final Future<Stream<StreamingMessage>> Function(ModelConfig modelConfig)?
      onStream;

  _MockTestLLMClient({this.onGenerate, this.onStream});

  @override
  Future<ModelMessage> generate(
    List<LLMMessage> messages, {
    List<Tool>? tools,
    ToolChoice? toolChoice,
    required ModelConfig modelConfig,
    bool? jsonOutput,
    CancelToken? cancelToken,
  }) async {
    if (onGenerate != null) {
      return onGenerate!(modelConfig);
    }
    return ModelMessage(
      model: modelConfig.model,
      textOutput: 'success from ${modelConfig.model}',
    );
  }

  @override
  Future<Stream<StreamingMessage>> stream(
    List<LLMMessage> messages, {
    List<Tool>? tools,
    ToolChoice? toolChoice,
    required ModelConfig modelConfig,
    bool? jsonOutput,
    CancelToken? cancelToken,
  }) async {
    if (onStream != null) {
      return onStream!(modelConfig);
    }
    return Stream.value(
      StreamingMessage(
        modelMessage: ModelMessage(
          model: modelConfig.model,
          textOutput: 'stream from ${modelConfig.model}',
        ),
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messages = [UserMessage.text('Hello')];
  final dummyModelConfig = ModelConfig(model: 'primary-model');

  group('FallbackLLMClient', () {
    test('returns primary result directly when primary succeeds', () async {
      int primaryCalls = 0;
      int fallbackCalls = 0;

      final primary = _MockTestLLMClient(
        onGenerate: (cfg) async {
          primaryCalls++;
          return ModelMessage(model: cfg.model, textOutput: 'chatgpt output');
        },
      );

      final fallback = _MockTestLLMClient(
        onGenerate: (cfg) async {
          fallbackCalls++;
          return ModelMessage(model: cfg.model, textOutput: 'claude output');
        },
      );

      final client = FallbackLLMClient(
        candidates: [
          FallbackCandidate(
            key: 'chatgpt',
            name: 'ChatGPT',
            client: primary,
            modelConfig: ModelConfig(model: 'gpt-5.6'),
          ),
          FallbackCandidate(
            key: 'claude',
            name: 'Claude',
            client: fallback,
            modelConfig: ModelConfig(model: 'claude-sonnet-5-5'),
          ),
        ],
      );

      final response = await client.generate(
        messages,
        modelConfig: dummyModelConfig,
      );

      expect(primaryCalls, 1);
      expect(fallbackCalls, 0);
      expect(response.textOutput, 'chatgpt output');
      expect(response.model, 'gpt-5.6');
    });

    test('falls back to secondary when primary throws rate limit or error',
        () async {
      int primaryCalls = 0;
      int fallbackCalls = 0;

      final primary = _MockTestLLMClient(
        onGenerate: (_) async {
          primaryCalls++;
          throw Exception('Rate limit 429');
        },
      );

      final fallback = _MockTestLLMClient(
        onGenerate: (cfg) async {
          fallbackCalls++;
          return ModelMessage(model: cfg.model, textOutput: 'claude recovered');
        },
      );

      final client = FallbackLLMClient(
        candidates: [
          FallbackCandidate(
            key: 'chatgpt',
            name: 'ChatGPT',
            client: primary,
            modelConfig: ModelConfig(model: 'gpt-5.6'),
          ),
          FallbackCandidate(
            key: 'claude',
            name: 'Claude',
            client: fallback,
            modelConfig: ModelConfig(model: 'claude-sonnet-5-5'),
          ),
        ],
      );

      final response = await client.generate(
        messages,
        modelConfig: dummyModelConfig,
      );

      expect(primaryCalls, 1);
      expect(fallbackCalls, 1);
      expect(response.textOutput, 'claude recovered');
      expect(response.model, 'claude-sonnet-5-5');
    });

    test('cascades through multiple failing models to find working one',
        () async {
      final primary = _MockTestLLMClient(
        onGenerate: (_) async => throw Exception('ChatGPT down'),
      );
      final secondary = _MockTestLLMClient(
        onGenerate: (_) async => throw Exception('Claude rate limited'),
      );
      final tertiary = _MockTestLLMClient(
        onGenerate: (cfg) async =>
            ModelMessage(model: cfg.model, textOutput: 'Gemini saved the day'),
      );

      final client = FallbackLLMClient(
        candidates: [
          FallbackCandidate(
            key: 'chatgpt',
            name: 'ChatGPT',
            client: primary,
            modelConfig: ModelConfig(model: 'gpt-5.6'),
          ),
          FallbackCandidate(
            key: 'claude',
            name: 'Claude',
            client: secondary,
            modelConfig: ModelConfig(model: 'claude-sonnet-5-5'),
          ),
          FallbackCandidate(
            key: 'gemini',
            name: 'Gemini',
            client: tertiary,
            modelConfig: ModelConfig(model: 'gemini-2.5-flash'),
          ),
        ],
      );

      final response = await client.generate(
        messages,
        modelConfig: dummyModelConfig,
      );

      expect(response.textOutput, 'Gemini saved the day');
      expect(response.model, 'gemini-2.5-flash');
    });

    test('throws error if all candidates fail', () async {
      final primary = _MockTestLLMClient(
        onGenerate: (_) async => throw Exception('Error 1'),
      );
      final secondary = _MockTestLLMClient(
        onGenerate: (_) async => throw Exception('Error 2'),
      );

      final client = FallbackLLMClient(
        candidates: [
          FallbackCandidate(
            key: 'c1',
            name: 'C1',
            client: primary,
            modelConfig: ModelConfig(model: 'm1'),
          ),
          FallbackCandidate(
            key: 'c2',
            name: 'C2',
            client: secondary,
            modelConfig: ModelConfig(model: 'm2'),
          ),
        ],
      );

      expect(
        () => client.generate(messages, modelConfig: dummyModelConfig),
        throwsA(isA<Exception>()),
      );
    });

    test('stream falls back to secondary when primary stream connection fails',
        () async {
      final primary = _MockTestLLMClient(
        onStream: (_) async => throw Exception('Connection timeout'),
      );
      final fallback = _MockTestLLMClient(
        onStream: (cfg) async => Stream.value(
          StreamingMessage(
            modelMessage: ModelMessage(
              model: cfg.model,
              textOutput: 'fallback stream output',
            ),
          ),
        ),
      );

      final client = FallbackLLMClient(
        candidates: [
          FallbackCandidate(
            key: 'chatgpt',
            name: 'ChatGPT',
            client: primary,
            modelConfig: ModelConfig(model: 'gpt-5.6'),
          ),
          FallbackCandidate(
            key: 'claude',
            name: 'Claude',
            client: fallback,
            modelConfig: ModelConfig(model: 'claude-sonnet-5-5'),
          ),
        ],
      );

      final stream =
          await client.stream(messages, modelConfig: dummyModelConfig);
      final chunks = await stream.toList();

      expect(chunks.length, 1);
      expect(chunks.first.modelMessage?.textOutput, 'fallback stream output');
      expect(chunks.first.modelMessage?.model, 'claude-sonnet-5-5');
    });
  });
}
