import 'package:flutter/foundation.dart';
import 'package:memex/data/repositories/memex_router.dart';
import 'package:memex/db/app_database.dart';
import 'package:memex/utils/logger.dart';

enum ActivityKind { running, failed }

/// One row of the activity list: a background task seen by the user.
class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.type,
    required this.kind,
    required this.startedAt,
    required this.retryCount,
    required this.maxRetries,
  });

  final String id;
  final String type;
  final ActivityKind kind;
  final DateTime? startedAt;
  final int retryCount;
  final int maxRetries;

  Duration? elapsed(DateTime now) =>
      startedAt == null ? null : now.difference(startedAt!);
}

/// Background-task activity (reference 18). Reads the local task queue;
/// the queue has no steps, titles or cancel, so none are shown.
class AgentActivityViewModel extends ChangeNotifier {
  AgentActivityViewModel({
    required MemexRouter router,
    DateTime Function()? now,
  })  : _router = router,
        _now = now ?? DateTime.now;

  static const int _pageSize = 30;

  final MemexRouter _router;
  final DateTime Function() _now;
  final _log = getLogger('AgentActivityViewModel');

  List<ActivityItem> running = const [];
  List<ActivityItem> failed = const [];
  bool loading = true;
  bool loadFailed = false;
  DateTime? updatedAt;

  DateTime get now => _now();
  bool get isEmpty => running.isEmpty && failed.isEmpty;

  Future<void> load() async {
    try {
      final tasks = await _router.getTasks(limit: _pageSize, offset: 0);
      final items = tasks.map(_toItem).whereType<ActivityItem>().toList();
      running = items.where((i) => i.kind == ActivityKind.running).toList();
      failed = items.where((i) => i.kind == ActivityKind.failed).toList();
      loadFailed = false;
      updatedAt = _now();
    } catch (e, st) {
      _log.warning('Failed to load task activity', e, st);
      loadFailed = true;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  ActivityItem? _toItem(Task task) {
    final ActivityKind kind;
    switch (task.status) {
      case 'pending':
      case 'processing':
      case 'retrying':
        kind = ActivityKind.running;
      case 'failed':
        kind = ActivityKind.failed;
      default:
        return null; // completed tasks are not "activity"
    }
    final seconds = task.scheduledAt ?? task.createdAt;
    return ActivityItem(
      id: task.id,
      type: task.type,
      kind: kind,
      startedAt: seconds == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(seconds * 1000),
      retryCount: task.retryCount,
      maxRetries: task.maxRetries,
    );
  }
}
