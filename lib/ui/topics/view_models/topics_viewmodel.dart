import 'package:flutter/foundation.dart';
import 'package:memex/data/repositories/memex_router.dart';
import 'package:memex/domain/models/topic.dart';
import 'package:memex/utils/result.dart';

class TopicSession {
  const TopicSession({required this.id, required this.title});

  final String id;
  final String title;
}

/// Topics and projects, and which sessions each one holds.
class TopicsViewModel extends ChangeNotifier {
  TopicsViewModel({required MemexRouter router}) : _router = router;

  final MemexRouter _router;

  List<Topic> topics = const [];
  List<TopicSession> sessions = const [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    final stored = await _router.loadTopics();
    stored.when(
      onOk: (list) => topics = list,
      onError: (error, _) => errorMessage = error.toString(),
    );
    final found = await _router.fetchChatSessions();
    found.when(
      onOk: (rows) => sessions = [
        for (final row in rows)
          if ('${row['session_id'] ?? ''}'.isNotEmpty)
            TopicSession(
              id: '${row['session_id']}',
              title: '${row['title'] ?? ''}'.trim().isEmpty
                  ? '${row['session_id']}'
                  : '${row['title']}'.trim(),
            ),
      ],
      onError: (error, _) => errorMessage = error.toString(),
    );
    isLoading = false;
    notifyListeners();
  }

  /// False when the name is blank or already used.
  Future<bool> create(String name, {required bool isProject}) async {
    final id = 'topic_${DateTime.now().microsecondsSinceEpoch}';
    return _apply(
      (t) => addTopic(t, id: id, name: name, isProject: isProject),
      accepted: (t) => t.any((x) => x.id == id),
    );
  }

  Future<bool> rename(String id, String name) => _apply(
        (t) => renameTopic(t, id, name),
        accepted: (t) => t.any((x) => x.id == id && x.name == name.trim()),
      );

  Future<void> delete(String id) => _apply((t) => removeTopic(t, id));

  Future<void> setLinked(String id, String sessionId, bool linked) => _apply(
        (t) => linked
            ? linkSession(t, id, sessionId)
            : unlinkSession(t, id, sessionId),
      );

  Future<bool> _apply(
    List<Topic> Function(List<Topic>) change, {
    bool Function(List<Topic>)? accepted,
  }) async {
    final result = await _router.updateTopics(change);
    var ok = true;
    result.when(
      onOk: (list) {
        topics = list;
        ok = accepted?.call(list) ?? true;
      },
      onError: (error, _) {
        errorMessage = error.toString();
        ok = false;
      },
    );
    notifyListeners();
    return ok;
  }
}
