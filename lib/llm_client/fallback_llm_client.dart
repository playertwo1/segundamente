import 'dart:async';

import 'package:dart_agent_core/dart_agent_core.dart';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:memex/data/services/event_bus_service.dart';

/// Represents a candidate client in the fallback sequence.
class FallbackCandidate {
  final String key;
  final String name;
  final LLMClient client;
  final ModelConfig modelConfig;

  const FallbackCandidate({
    required this.key,
    required this.name,
    required this.client,
    required this.modelConfig,
  });
}

/// An [LLMClient] wrapper that executes requests against candidates sequentially.
/// If candidate N fails (network error, 429 rate limit, 500, timeout), it automatically
/// fails over to candidate N+1.
class FallbackLLMClient extends LLMClient {
  final List<FallbackCandidate> candidates;
  final Logger _logger = Logger('FallbackLLMClient');

  FallbackLLMClient({required this.candidates}) {
    if (candidates.isEmpty) {
      throw ArgumentError('FallbackLLMClient requires at least one candidate.');
    }
  }

  @override
  Future<ModelMessage> generate(
    List<LLMMessage> messages, {
    List<Tool>? tools,
    ToolChoice? toolChoice,
    required ModelConfig modelConfig,
    bool? jsonOutput,
    CancelToken? cancelToken,
  }) async {
    Object? lastError;
    StackTrace? lastStackTrace;

    for (int i = 0; i < candidates.length; i++) {
      final candidate = candidates[i];
      try {
        if (i > 0) {
          _logger.info(
            'Fallback attempt ($i/${candidates.length - 1}): trying ${candidate.name} (${candidate.modelConfig.model})',
          );
        }
        return await candidate.client.generate(
          messages,
          tools: tools,
          toolChoice: toolChoice,
          modelConfig: candidate.modelConfig,
          jsonOutput: jsonOutput,
          cancelToken: cancelToken,
        );
      } catch (e, st) {
        lastError = e;
        lastStackTrace = st;
        _logger.warning(
          'Model candidate ${candidate.name} (${candidate.modelConfig.model}) failed: $e',
        );
        if (i < candidates.length - 1) {
          _emitFallbackNotice(
            fromCandidate: candidate,
            toCandidate: candidates[i + 1],
            error: e.toString(),
          );
        }
      }
    }

    Error.throwWithStackTrace(
      lastError ?? Exception('All fallback models failed'),
      lastStackTrace ?? StackTrace.current,
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
    Object? lastError;
    StackTrace? lastStackTrace;

    for (int i = 0; i < candidates.length; i++) {
      final candidate = candidates[i];
      try {
        if (i > 0) {
          _logger.info(
            'Stream fallback attempt ($i/${candidates.length - 1}): trying ${candidate.name} (${candidate.modelConfig.model})',
          );
        }
        final rawStream = await candidate.client.stream(
          messages,
          tools: tools,
          toolChoice: toolChoice,
          modelConfig: candidate.modelConfig,
          jsonOutput: jsonOutput,
          cancelToken: cancelToken,
        );

        if (i == candidates.length - 1) {
          return rawStream;
        }

        return _wrapResilientStream(
          initialStream: rawStream,
          currentIndex: i,
          messages: messages,
          tools: tools,
          toolChoice: toolChoice,
          jsonOutput: jsonOutput,
          cancelToken: cancelToken,
        );
      } catch (e, st) {
        lastError = e;
        lastStackTrace = st;
        _logger.warning(
          'Stream candidate ${candidate.name} (${candidate.modelConfig.model}) failed: $e',
        );
        if (i < candidates.length - 1) {
          _emitFallbackNotice(
            fromCandidate: candidate,
            toCandidate: candidates[i + 1],
            error: e.toString(),
          );
        }
      }
    }

    Error.throwWithStackTrace(
      lastError ?? Exception('All fallback models failed'),
      lastStackTrace ?? StackTrace.current,
    );
  }

  Stream<StreamingMessage> _wrapResilientStream({
    required Stream<StreamingMessage> initialStream,
    required int currentIndex,
    required List<LLMMessage> messages,
    List<Tool>? tools,
    ToolChoice? toolChoice,
    bool? jsonOutput,
    CancelToken? cancelToken,
  }) {
    final controller = StreamController<StreamingMessage>();
    StreamSubscription<StreamingMessage>? sub;
    bool hasEmittedData = false;

    void listenToStream(Stream<StreamingMessage> currentStream, int index) {
      sub = currentStream.listen(
        (data) {
          hasEmittedData = true;
          controller.add(data);
        },
        onError: (e, st) async {
          _logger.warning('Stream error from ${candidates[index].name}: $e');
          if (!hasEmittedData && index < candidates.length - 1) {
            _emitFallbackNotice(
              fromCandidate: candidates[index],
              toCandidate: candidates[index + 1],
              error: e.toString(),
            );
            try {
              final nextStream = await candidates[index + 1].client.stream(
                messages,
                tools: tools,
                toolChoice: toolChoice,
                modelConfig: candidates[index + 1].modelConfig,
                jsonOutput: jsonOutput,
                cancelToken: cancelToken,
              );
              listenToStream(nextStream, index + 1);
              return;
            } catch (nextErr, nextSt) {
              controller.addError(nextErr, nextSt);
              controller.close();
              return;
            }
          }
          controller.addError(e, st);
        },
        onDone: () => controller.close(),
        cancelOnError: false,
      );
    }

    controller.onCancel = () => sub?.cancel();
    listenToStream(initialStream, currentIndex);
    return controller.stream;
  }

  void _emitFallbackNotice({
    required FallbackCandidate fromCandidate,
    required FallbackCandidate toCandidate,
    required String error,
  }) {
    EventBusService.instance.emitEvent(
      ErrorNotificationMessage(
        errorCategory: 'llm_fallback',
        errorMessage:
            '${fromCandidate.name} indisponível. Alternando para ${toCandidate.name}...',
      ),
    );
  }
}
