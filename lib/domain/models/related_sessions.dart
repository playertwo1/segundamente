import 'package:memex/domain/models/report_memory.dart';
import 'package:memex/domain/models/session_report.dart';
import 'package:memex/domain/models/topic.dart';

class RelatedSession {
  const RelatedSession({
    required this.sessionId,
    required this.isSeed,
    required this.sharedTopics,
  });

  final String sessionId;

  /// True when the text search found it; false when it came in by topic.
  final bool isSeed;

  /// How many topics it shares with the seeds (0 for a seed with no topic).
  final int sharedTopics;
}

/// Sessions to read for a question. The text-search hits are the seeds and
/// always stay. Sessions that share a topic with a seed follow, ordered by
/// shared topics then by [sessionTimes] (newest first), until their text
/// exceeds [maxChars]. No seed means no session at all, so an off-topic
/// question never receives someone else's session.
List<RelatedSession> relatedSessions({
  required List<ReportHit> seedHits,
  required List<Topic> topics,
  required List<SessionReport> reports,
  required Map<String, DateTime> sessionTimes,
  int maxChars = 4000,
  int minSharedTopics = 1,
}) {
  final seeds = <String>[];
  for (final hit in seedHits) {
    if (!seeds.contains(hit.sessionId)) seeds.add(hit.sessionId);
  }
  if (seeds.isEmpty) return const [];

  final shared = <String, int>{};
  for (final topic in topics) {
    if (!topic.sessionIds.any(seeds.contains)) continue;
    for (final id in topic.sessionIds) {
      if (!seeds.contains(id)) shared[id] = (shared[id] ?? 0) + 1;
    }
  }
  final sizes = {for (final r in reports) r.sessionId: _chars(r)};
  final siblings = [
    for (final e in shared.entries)
      if (e.value >= minSharedTopics && sizes.containsKey(e.key)) e.key,
  ]..sort((a, b) {
      final byTopics = shared[b]!.compareTo(shared[a]!);
      if (byTopics != 0) return byTopics;
      final ta = sessionTimes[a] ?? DateTime.fromMillisecondsSinceEpoch(0);
      final tb = sessionTimes[b] ?? DateTime.fromMillisecondsSinceEpoch(0);
      return tb.compareTo(ta);
    });

  final result = [
    for (final id in seeds)
      RelatedSession(
        sessionId: id,
        isSeed: true,
        sharedTopics: topics.where((t) => t.sessionIds.contains(id)).length,
      ),
  ];
  var used = 0;
  for (final id in siblings) {
    final size = sizes[id]!;
    if (used + size > maxChars) continue;
    used += size;
    result.add(
      RelatedSession(sessionId: id, isSeed: false, sharedTopics: shared[id]!),
    );
  }
  return result;
}

int _chars(SessionReport report) {
  var total = report.title.length;
  for (final item in report.items) {
    if (item.status != ReportItemStatus.discarded) total += item.text.length;
  }
  return total;
}
