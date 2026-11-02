import 'dart:async';
import 'dart:convert';

import 'package:dart_agent_core/dart_agent_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/config/app_flavor.dart';
import 'package:memex/data/services/model_test_service.dart';
import 'package:memex/domain/models/llm_config.dart';
import 'package:memex/domain/models/model_catalog.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    AppFlavor.init('global');
    SharedPreferences.setMockInitialValues({});
    await UserStorage.initL10n();
  });

  const config = LLMConfig(
    key: 'probe',
    type: LLMConfig.typeChatCompletion,
    modelId: 'my-manual-model',
    apiKey: 'sk-test',
    baseUrl: 'https://llm.example.test/v1',
  );

  test('json probe asks for JSON output and records the verdict', () async {
    bool? sawJsonOutput;
    final result = await ModelTestService.testConfig(
      config,
      testType: ModelCapability.json,
      resourcesBuilder: (_) async => (
        client: _FakeClient(
          onGenerate: (messages, {jsonOutput}) async {
            sawJsonOutput = jsonOutput;
            return ModelMessage(textOutput: '{"ok":true}', model: 'fake');
          },
        ),
        modelConfig: ModelConfig(model: config.modelId),
      ),
    );

    expect(sawJsonOutput, isTrue);
    expect(result.success, isTrue);
    expect(result.verdict, CapabilityVerdict.yes);
  });

  test('json probe marks a prose reply as a missing capability', () async {
    final result = await ModelTestService.testConfig(
      config,
      testType: ModelCapability.json,
      resourcesBuilder: (_) async => (
        client: _FakeClient(
          onGenerate: (messages, {jsonOutput}) async =>
              ModelMessage(textOutput: 'ok', model: 'fake'),
        ),
        modelConfig: ModelConfig(model: config.modelId),
      ),
    );

    expect(result.success, isFalse);
    expect(result.verdict, CapabilityVerdict.no);
    expect(result.error, 'Response was not a JSON object');
  });

  test('streaming probe reads text chunks', () async {
    var streamed = false;
    final result = await ModelTestService.testConfig(
      config,
      testType: ModelCapability.streaming,
      resourcesBuilder: (_) async => (
        client: _FakeClient(
          onStream: () async {
            streamed = true;
            return Stream.fromIterable([
              StreamingMessage(
                modelMessage: ModelMessage(textOutput: 'o', model: 'fake'),
              ),
              StreamingMessage(
                modelMessage: ModelMessage(textOutput: 'k', model: 'fake'),
              ),
            ]);
          },
        ),
        modelConfig: ModelConfig(model: config.modelId),
      ),
    );

    expect(streamed, isTrue);
    expect(result.success, isTrue);
    expect(result.responseText, 'ok');
    expect(result.verdict, CapabilityVerdict.yes);
  });

  test('audio probe sends a wav and vision sends the image', () async {
    List<UserContentPart>? audioContents;
    List<UserContentPart>? visionContents;
    final client = _FakeClient(
      onGenerate: (messages, {jsonOutput}) async {
        final user = messages.whereType<UserMessage>().single;
        if (user.contents.any((part) => part is AudioPart)) {
          audioContents = user.contents;
        }
        if (user.contents.any((part) => part is ImagePart)) {
          visionContents = user.contents;
        }
        return ModelMessage(textOutput: 'ok', model: 'fake');
      },
    );

    final audio = await ModelTestService.testConfig(
      config,
      testType: ModelCapability.audio,
      resourcesBuilder: (_) async => (
        client: client,
        modelConfig: ModelConfig(model: config.modelId),
      ),
    );
    final vision = await ModelTestService.testConfig(
      config,
      testType: ModelCapability.vision,
      resourcesBuilder: (_) async => (
        client: client,
        modelConfig: ModelConfig(model: config.modelId),
      ),
    );

    expect(audio.verdict, CapabilityVerdict.yes);
    expect(vision.verdict, CapabilityVerdict.yes);
    final audioPart =
        audioContents!.whereType<AudioPart>().single;
    expect(audioPart.mimeType, 'audio/wav');
    final wav = base64Decode(audioPart.base64Data);
    expect(String.fromCharCodes(wav.take(4)), 'RIFF');
    expect(String.fromCharCodes(wav.skip(8).take(4)), 'WAVE');
    expect(visionContents!.whereType<ImagePart>(), isNotEmpty);
  });

  test('a timeout does not mark the capability missing', () async {
    final result = await ModelTestService.testConfig(
      config,
      testType: ModelCapability.text,
      resourcesBuilder: (_) async => (
        client: _FakeClient(
          onGenerate: (messages, {jsonOutput}) async {
            throw TimeoutException('slow');
          },
        ),
        modelConfig: ModelConfig(model: config.modelId),
      ),
    );

    expect(result.success, isFalse);
    expect(result.verdict, CapabilityVerdict.unknown);
  });
}

typedef _Generate = Future<ModelMessage> Function(
  List<LLMMessage> messages, {
  bool? jsonOutput,
});

class _FakeClient extends LLMClient {
  _FakeClient({this.onGenerate, this.onStream});

  final _Generate? onGenerate;
  final Future<Stream<StreamingMessage>> Function()? onStream;

  @override
  Future<ModelMessage> generate(
    List<LLMMessage> messages, {
    List<Tool>? tools,
    ToolChoice? toolChoice,
    required ModelConfig modelConfig,
    bool? jsonOutput,
    CancelToken? cancelToken,
  }) {
    return onGenerate!(messages, jsonOutput: jsonOutput);
  }

  @override
  Future<Stream<StreamingMessage>> stream(
    List<LLMMessage> messages, {
    List<Tool>? tools,
    ToolChoice? toolChoice,
    required ModelConfig modelConfig,
    bool? jsonOutput,
    CancelToken? cancelToken,
  }) {
    return onStream!();
  }
}
