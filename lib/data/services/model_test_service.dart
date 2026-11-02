import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_agent_core/dart_agent_core.dart';
import 'package:memex/domain/models/llm_config.dart';
import 'package:memex/domain/models/model_catalog.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:memex/utils/logger.dart';

final _log = getLogger('ModelTestService');

typedef ModelTestResourcesBuilder = Future<
        ({LLMClient client, ModelConfig modelConfig})>
    Function(LLMConfig config);

/// Result of a model connectivity test.
class ModelTestResult {
  final bool success;
  final ModelCapability testType;
  final Duration responseTime;
  final String? responseText;
  final String? error;
  final String? model;
  final CapabilityVerdict verdict;

  const ModelTestResult({
    required this.success,
    required this.testType,
    required this.responseTime,
    this.responseText,
    this.error,
    this.model,
    this.verdict = CapabilityVerdict.unknown,
  });
}

/// Service for testing LLM model connectivity and functionality.
class ModelTestService {
  /// A minimal 64x64 PNG image: red circle on white background.
  /// Used as the test image for vision capability verification.
  /// 64x64 is safely above any provider's minimum size threshold while
  /// keeping the base64 payload tiny (~400 chars). The red circle is
  /// simple enough for any vision model to describe correctly.
  static const _testImageBase64 =
      'iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAIAAAAlC+aJAAAA90lEQVR4nO3aOxKDUAxDU'
      'fa/6SRdJkVA8k+Phzy02PcMLcfr5nOoA7JjgHoMUI8B6ukHHL0nqrd/cpGn8GDRGqy7QZ'
      'JeEU4vYiReLklPM6KA8vqoIQRoqg8ZeEBrPW8gAQP1pIEBjNUzBhgwXA8bMICkHjM8AS'
      'CsBwzbA+T1VwYDlgbIuwGDAQYYsC1AXowZNv4CBhhggD46C1jHcBJowOKAFQzndQ8AaA'
      '2Xac8AqAxIFwqYN4BRBGDSgBdxgBkDlUMDug1sSwTQZwiEBAEdhlhFHFDIyNzPApKM/OX'
      '8it99Q93fg4W7/ly41/9C42OAegxQjwHqeQNx8d3ytD3rzgAAAABJRU5ErkJggg==';

  /// Test an LLM configuration by sending a minimal request.
  ///
  /// [testType] controls whether to test basic text or vision capability.
  /// Uses [UserStorage.buildLLMResources] to construct the client — same path
  /// as production agent calls — so the test validates real-world behavior.
  static Future<ModelTestResult> testConfig(
    LLMConfig config, {
    ModelCapability testType = ModelCapability.text,
    ModelTestResourcesBuilder? resourcesBuilder,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      if (!config.isValid) {
        stopwatch.stop();
        return ModelTestResult(
          success: false,
          testType: testType,
          responseTime: stopwatch.elapsed,
          error: UserStorage.l10n.invalidConfigurationWarning,
        );
      }

      final resources = resourcesBuilder != null
          ? await resourcesBuilder(config)
          : await UserStorage.buildLLMResources(config);
      final messages = _buildTestMessages(testType);
      final observed = testType == ModelCapability.streaming
          ? await _collectStream(resources, messages)
          : await _collectGenerate(resources, messages, testType);

      stopwatch.stop();
      return _resultFromObservation(
        config: config,
        testType: testType,
        elapsed: stopwatch.elapsed,
        text: observed.text,
        textChunks: observed.chunks,
        model: observed.model,
      );
    } on TimeoutException {
      stopwatch.stop();
      return ModelTestResult(
        success: false,
        testType: testType,
        responseTime: stopwatch.elapsed,
        error: 'Request timed out (30s)',
        verdict: CapabilityVerdict.unknown,
      );
    } catch (e) {
      stopwatch.stop();
      _log.warning(
          'Model test ($testType) failed: ${config.type}/${config.modelId}: $e');

      String errorMsg = e.toString();
      errorMsg = errorMsg
          .replaceFirst('Exception: ', '')
          .replaceFirst('FormatException: ', '');
      if (errorMsg.length > 200) {
        errorMsg = '${errorMsg.substring(0, 200)}...';
      }

      return ModelTestResult(
        success: false,
        testType: testType,
        responseTime: stopwatch.elapsed,
        error: errorMsg,
        verdict: ModelCapabilityJudge.fromError(testType, errorMsg),
      );
    }
  }

  static Future<({String text, int chunks, String? model})> _collectGenerate(
    ({LLMClient client, ModelConfig modelConfig}) resources,
    List<LLMMessage> messages,
    ModelCapability testType,
  ) async {
    final response = await resources.client
        .generate(
          messages,
          modelConfig: resources.modelConfig,
          jsonOutput: testType == ModelCapability.json ? true : null,
        )
        .timeout(const Duration(seconds: 30));
    final text = response.textOutput?.trim() ?? '';
    return (text: text, chunks: text.isEmpty ? 0 : 1, model: response.model);
  }

  static Future<({String text, int chunks, String? model})> _collectStream(
    ({LLMClient client, ModelConfig modelConfig}) resources,
    List<LLMMessage> messages,
  ) async {
    final stream = await resources.client
        .stream(messages, modelConfig: resources.modelConfig)
        .timeout(const Duration(seconds: 30));
    final buffer = StringBuffer();
    var chunks = 0;
    String? model;
    await for (final message in stream.timeout(const Duration(seconds: 30))) {
      final piece = message.modelMessage?.textOutput ?? '';
      model ??= message.modelMessage?.model;
      if (piece.isEmpty) continue;
      chunks++;
      buffer.write(piece);
    }
    return (text: buffer.toString().trim(), chunks: chunks, model: model);
  }

  static ModelTestResult _resultFromObservation({
    required LLMConfig config,
    required ModelCapability testType,
    required Duration elapsed,
    required String text,
    required int textChunks,
    required String? model,
  }) {
    final verdict = ModelCapabilityJudge.judge(
      capability: testType,
      transportOk: true,
      text: text,
      textChunks: textChunks,
    );
    if (verdict != CapabilityVerdict.yes) {
      final error = testType == ModelCapability.json && text.isNotEmpty
          ? 'Response was not a JSON object'
          : 'Empty response from model';
      return ModelTestResult(
        success: false,
        testType: testType,
        responseTime: elapsed,
        error: error,
        model: model,
        verdict: verdict,
      );
    }

    _log.info(
      'Model test ($testType) success: ${config.type}/${config.modelId} '
      'in ${elapsed.inMilliseconds}ms',
    );

    return ModelTestResult(
      success: true,
      testType: testType,
      responseTime: elapsed,
      responseText: text.length > 150 ? '${text.substring(0, 150)}...' : text,
      model: model,
      verdict: verdict,
    );
  }

  /// Build the message list for the given test type.
  static List<LLMMessage> _buildTestMessages(ModelCapability testType) {
    switch (testType) {
      case ModelCapability.text:
      case ModelCapability.streaming:
        return [
          SystemMessage(
              'You are a helpful assistant. Follow instructions precisely.'),
          UserMessage([TextPart('Reply with "ok" only.')]),
        ];
      case ModelCapability.json:
        return [
          SystemMessage(
              'You are a helpful assistant. Follow instructions precisely.'),
          UserMessage([
            TextPart('Reply with a JSON object {"ok":true} and no other text.'),
          ]),
        ];
      case ModelCapability.vision:
        return [
          SystemMessage(
              'You are a vision assistant. Describe images concisely.'),
          UserMessage([
            TextPart(
                'Describe this image in one short sentence (10 words max).'),
            ImagePart(_testImageBase64, 'image/png'),
          ]),
        ];
      case ModelCapability.audio:
        return [
          SystemMessage(
              'You are a helpful assistant. Follow instructions precisely.'),
          UserMessage([
            TextPart('Reply with "ok" only.'),
            AudioPart(_silentWavBase64, 'audio/wav'),
          ]),
        ];
    }
  }

  /// 0.1s of 8 kHz mono silence. Small enough to probe audio input.
  static final String _silentWavBase64 = base64Encode(_silentWavBytes());

  static Uint8List _silentWavBytes() {
    const sampleRate = 8000;
    const channels = 1;
    const bitsPerSample = 16;
    const samples = 800;
    final dataSize = samples * channels * (bitsPerSample ~/ 8);
    final bytes = BytesBuilder(copy: false);

    void addString(String value) => bytes.add(value.codeUnits);
    void add16(int value) =>
        bytes.add([value & 0xff, (value >> 8) & 0xff]);
    void add32(int value) => bytes.add([
          value & 0xff,
          (value >> 8) & 0xff,
          (value >> 16) & 0xff,
          (value >> 24) & 0xff,
        ]);

    addString('RIFF');
    add32(36 + dataSize);
    addString('WAVE');
    addString('fmt ');
    add32(16);
    add16(1);
    add16(channels);
    add32(sampleRate);
    add32(sampleRate * channels * bitsPerSample ~/ 8);
    add16(channels * bitsPerSample ~/ 8);
    add16(bitsPerSample);
    addString('data');
    add32(dataSize);
    bytes.add(Uint8List(dataSize));
    return bytes.toBytes();
  }
}
