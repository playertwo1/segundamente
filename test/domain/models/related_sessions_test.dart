import 'package:flutter_test/flutter_test.dart';
import 'package:memex/domain/models/related_sessions.dart';
import 'package:memex/domain/models/report_memory.dart';
import 'package:memex/domain/models/session_report.dart';
import 'package:memex/domain/models/topic.dart';

SessionReport report(String id, String text) => SessionReport(
      schemaVersion: sessionReportSchemaVersion,
      sessionId: id,
      kind: ReportKind.reuniao,
      title: id,
      sections: const [ReportItemKind.followUp],
      items: [
        ReportItem(
          id: 'i1',
          kind: ReportItemKind.followUp,
          text: text,
          status: ReportItemStatus.approved,
          assignee: reportAssigneeUnknown,
          due: reportDueUnknown,
          source: const ReportSource(segmentId: 's', excerpt: 'x'),
        ),
      ],
    );

ReportHit hit(String session) =>
    ReportHit(sessionId: session, item: report(session, 'a').items.single);

void main() {
  final reports = [
    for (final id in ['a', 'b', 'c', 'd', 'e']) report(id, 'texto de $id'),
  ];
  final times = {
    'b': DateTime(2026, 1, 1),
    'c': DateTime(2026, 3, 1),
    'd': DateTime(2026, 2, 1),
  };
  var topics = <Topic>[];
  topics = addTopic(topics, id: 't1', name: 'Obra');
  topics = addTopic(topics, id: 't2', name: 'Casa');
  for (final s in ['a', 'b', 'c']) {
    topics = linkSession(topics, 't1', s);
  }
  for (final s in ['a', 'd']) {
    topics = linkSession(topics, 't2', s);
  }
  topics = linkSession(topics, 't2', 'b');

  List<String> ids(List<RelatedSession> r) => [for (final s in r) s.sessionId];

  test('seeds stay and siblings follow by shared topics, then newest', () {
    final result = relatedSessions(
      seedHits: [hit('a')],
      topics: topics,
      reports: reports,
      sessionTimes: times,
    );
    // b shares Obra and Casa with a; c and d share one, c is newer.
    expect(ids(result), ['a', 'b', 'c', 'd']);
    expect(result.first.isSeed, isTrue);
    expect(result[1].sharedTopics, 2);
    expect(ids(result), isNot(contains('e')));
  });

  test('no seed means no session, even when topics exist', () {
    expect(
      relatedSessions(
        seedHits: const [],
        topics: topics,
        reports: reports,
        sessionTimes: times,
      ),
      isEmpty,
    );
  });

  test('a seed outside every topic comes back alone', () {
    expect(
      ids(relatedSessions(
        seedHits: [hit('e')],
        topics: topics,
        reports: reports,
        sessionTimes: times,
      )),
      ['e'],
    );
  });

  test('the character budget cuts siblings but never the seeds', () {
    final result = relatedSessions(
      seedHits: [hit('a')],
      topics: topics,
      reports: reports,
      sessionTimes: times,
      maxChars: 15,
    );
    expect(ids(result), ['a', 'b']);
    expect(
      ids(relatedSessions(
        seedHits: [hit('a')],
        topics: topics,
        reports: reports,
        sessionTimes: times,
        maxChars: 0,
      )),
      ['a'],
    );
  });

  test('the relevance floor drops siblings with too few shared topics', () {
    expect(
      ids(relatedSessions(
        seedHits: [hit('a')],
        topics: topics,
        reports: reports,
        sessionTimes: times,
        minSharedTopics: 2,
      )),
      ['a', 'b'],
    );
  });
}
