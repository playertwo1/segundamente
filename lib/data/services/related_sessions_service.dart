import 'package:memex/data/services/chat_session_storage.dart';
import 'package:memex/data/services/session_report_service.dart';
import 'package:memex/data/services/topic_service.dart';
import 'package:memex/domain/models/related_sessions.dart';

/// Joins the text search, the topics and the session dates for
/// [relatedSessions].
class RelatedSessionsService {
  RelatedSessionsService({
    SessionReportService? reports,
    TopicService? topics,
    ChatSessionStorage? sessions,
  })  : _reports = reports ?? SessionReportService(),
        _topics = topics ?? TopicService(),
        _sessions = sessions ?? ChatSessionStorage.instance;

  final SessionReportService _reports;
  final TopicService _topics;
  final ChatSessionStorage _sessions;

  Future<List<RelatedSession>> find(String userId, String query) async {
    final hits = await _reports.search(userId: userId, query: query);
    if (hits.isEmpty) return const [];
    final times = <String, DateTime>{};
    for (final meta in await _sessions.listSessionMetadata(userId)) {
      final at = DateTime.tryParse('${meta['updated_at'] ?? ''}');
      if (at != null) times['${meta['session_id']}'] = at;
    }
    return relatedSessions(
      seedHits: hits,
      topics: await _topics.load(userId),
      reports: await _reports.loadAll(userId),
      sessionTimes: times,
    );
  }
}
