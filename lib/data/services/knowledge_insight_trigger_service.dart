import 'package:memex/data/services/file_system_service.dart';
import 'package:memex/data/services/global_event_bus.dart';
import 'package:memex/data/services/local_task_executor.dart';
import 'package:memex/domain/models/insight_trigger.dart';
import 'package:memex/domain/models/system_event.dart';
import 'package:memex/utils/logger.dart';

final _logger = getLogger('KnowledgeInsightTrigger');

/// Starts the automatic Knowledge Insight analysis once a record is saved.
///
/// It listens to `userInputSubmitted`, which is published only after a new
/// card has been written, so a message that never became a record never
/// starts anything. The work itself runs later, in the persistent task queue
/// (with retry); here we only queue it, so capture and chat never wait on the
/// model.
class KnowledgeInsightTriggerService {
  KnowledgeInsightTriggerService({
    LocalTaskExecutor? executor,
    FileSystemService? files,
    this.debounce = insightDebounce,
  })  : _executor = executor ?? LocalTaskExecutor.instance,
        _files = files ?? FileSystemService.instance;

  final LocalTaskExecutor _executor;
  final FileSystemService _files;
  final Duration debounce;

  /// Queues the record for analysis. Returns false, and queues nothing, when
  /// the record is gone, is an insight summary, has no readable text, or was
  /// already handed to an analysis (a record is analysed at most once).
  Future<bool> onRecordSaved(
    String userId,
    SystemEvent<UserInputSubmittedPayload> event,
  ) async {
    final factId = event.payload.factId;
    if (factId.isEmpty) return false;

    final card = await _files.readCardFile(userId, factId);
    if (card == null || !startsInsightAnalysis(card)) return false;

    if (await _executor.hasTaskForFact(
      taskType: insightTaskType,
      factId: factId,
    )) {
      return false;
    }

    final runAt = DateTime.now().add(debounce).millisecondsSinceEpoch ~/ 1000;
    await _executor.enqueueOrRescheduleTask(
      userId: userId,
      taskType: insightTaskType,
      bizId: insightBatchKey(userId),
      payload: {
        'fact_ids': [factId],
      },
      scheduledAt: runAt,
      maxRetries: 3,
      mergePayload: (waiting) => {
        'fact_ids': mergeFactIds(
          (waiting?['fact_ids'] as List?)?.cast<String>() ?? const [],
          [factId],
        ),
      },
    );
    _logger.info('Queued insight analysis for $factId');
    return true;
  }
}

/// Subscribes the trigger to saved records on [bus]. A sync subscriber, because
/// the record has to merge into the user's waiting task instead of adding a
/// task per record; the bus logs and swallows a failure, so a broken trigger
/// never breaks capture.
void registerKnowledgeInsightTrigger(
  GlobalEventBus bus, {
  KnowledgeInsightTriggerService? service,
}) {
  bus.subscribeSync<UserInputSubmittedPayload>(
    eventType: SystemEventTypes.userInputSubmitted,
    subscription: EventSyncSubscription<UserInputSubmittedPayload>(
      subscriptionId: 'knowledge_insight_trigger',
      handler: (userId, event) async {
        await (service ?? KnowledgeInsightTriggerService())
            .onRecordSaved(userId, event);
      },
    ),
  );
}
