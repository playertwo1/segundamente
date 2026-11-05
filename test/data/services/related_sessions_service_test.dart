import 'package:flutter_test/flutter_test.dart';
import 'package:memex/data/services/chat_session_storage.dart';
import 'package:memex/data/services/related_sessions_service.dart';
import 'package:memex/data/services/session_report_service.dart';
import 'package:memex/data/services/topic_service.dart';
import 'package:memex/domain/models/report_memory.dart';
import 'package:memex/domain/models/session_report.dart';
import 'package:memex/domain/models/topic.dart';

class _Reports extends Fake implements SessionReportService {
  _Reports(this.report);

  final SessionReport report;

  @override
  Future<List<ReportHit>> search({
    required String userId,
    required String query,
  }) async =>
      searchReports([report], query);

  @override
  Future<List<SessionReport>> loadAll(String userId) async => [report];
}

class _BrokenTopics extends Fake implements TopicService {
  @override
  Future<List<Topic>> load(String userId) async =>
      throw const FormatException('topic schema');
}

class _Sessions extends Fake implements ChatSessionStorage {
  @override
  Future<List<Map<String, dynamic>>> listSessionMetadata(String userId) async =>
      const [];
}

void main() {
  test('unreadable topics file still returns the text matches', () async {
    const report = SessionReport(
      schemaVersion: sessionReportSchemaVersion,
      sessionId: 's1',
      kind: ReportKind.reuniao,
      title: 'Reunião',
      sections: [ReportItemKind.followUp],
      items: [
        ReportItem(
          id: 'i1',
          kind: ReportItemKind.followUp,
          text: 'comprar cimento',
          status: ReportItemStatus.approved,
          assignee: reportAssigneeUnknown,
          due: reportDueUnknown,
          source: ReportSource(segmentId: 's', excerpt: 'cimento'),
        ),
      ],
    );
    final service = RelatedSessionsService(
      reports: _Reports(report),
      topics: _BrokenTopics(),
      sessions: _Sessions(),
    );

    final found = await service.find('u', 'cimento');

    expect(found.map((r) => r.sessionId), ['s1']);
    expect(found.single.isSeed, isTrue);
  });
}
