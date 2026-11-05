import 'package:memex/domain/models/llm_config.dart';

/// Who receives a kind of data and where it goes.
class DataRoute {
  const DataRoute({
    required this.provider,
    required this.model,
    required this.host,
  });

  /// Provider name as shown in the model list, e.g. `ChatGPT (OAuth)`.
  final String provider;

  /// Empty when the provider manages the model and the app does not name it.
  final String model;

  /// Destination host the app contacts, e.g. `chatgpt.com`.
  final String host;
}

/// Where audio and text go for the selected model. Null when no valid model
/// is configured, in which case nothing is sent.
class DataRoutes {
  const DataRoutes({required this.transcription, required this.chat});

  final DataRoute transcription;
  final DataRoute chat;
}

const _chatGptHost = 'chatgpt.com';

// Hosts of the providers whose base URL is built into the client.
const _knownHosts = {
  LLMConfig.typeGemini: 'generativelanguage.googleapis.com',
  LLMConfig.typeGeminiOauth: 'generativelanguage.googleapis.com',
  LLMConfig.typeClaude: 'api.anthropic.com',
  LLMConfig.typeClaudeOauth: 'api.anthropic.com',
  LLMConfig.typeBedrockClaude: 'bedrock-runtime.amazonaws.com',
};

/// Describes the routes for [config], mirroring what the app really does:
/// with ChatGPT (OAuth) audio goes to the ChatGPT transcription endpoint and
/// only the text reaches the model; with any other model the audio is sent
/// inside the request to that same provider.
DataRoutes? describeDataRoutes(LLMConfig? config) {
  if (config == null || !config.isValid) return null;
  final provider = LLMConfig.providerDisplayName(config.type);
  if (config.type == LLMConfig.typeOpenAiOauth) {
    return DataRoutes(
      transcription: DataRoute(
        provider: provider,
        model: 'chatgpt-transcribe',
        host: _chatGptHost,
      ),
      chat: DataRoute(
        provider: provider,
        model: config.modelId,
        host: _chatGptHost,
      ),
    );
  }
  final host = _hostOf(config);
  final route = DataRoute(
    provider: provider,
    // The official service manages its models; the app never names them.
    model: config.type == LLMConfig.typeMemex ? '' : config.modelId,
    host: host,
  );
  return DataRoutes(transcription: route, chat: route);
}

String _hostOf(LLMConfig config) {
  final fromUrl = Uri.tryParse(config.baseUrl.trim())?.host ?? '';
  if (fromUrl.isNotEmpty) return fromUrl;
  return _knownHosts[config.type] ?? LLMConfig.providerDisplayName(config.type);
}
