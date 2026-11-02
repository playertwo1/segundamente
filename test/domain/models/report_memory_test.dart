import 'package:flutter_test/flutter_test.dart';
import 'package:memex/domain/models/report_memory.dart';
import 'package:memex/domain/models/session_report.dart';

void main() {
  ReportItem item({
    required String id,
    required String text,
    ReportItemKind kind = ReportItemKind.idea,
    ReportItemStatus status = ReportItemStatus.unconfirmed,
  }) {
    return ReportItem(
      id: id,
      kind: kind,
      text: text,
      status: status,
      assignee: reportAssigneeUnknown,
      due: reportDueUnknown,
      source: ReportSource(segmentId: 'seg_0', excerpt: text),
    );
  }

  SessionReport report(String sessionId, List<ReportItem> items) {
    return SessionReport(
      schemaVersion: sessionReportSchemaVersion,
      sessionId: sessionId,
      kind: ReportKind.reuniao,
      title: 'Relatório de reunião',
      sections: sectionsFor(ReportKind.reuniao),
      items: items,
    );
  }

  test('text search skips discarded items and other sessions', () {
    final hits = searchReports(
      [
        report('a', [
          item(id: '1', text: 'fechar o escopo'),
          item(
            id: '2',
            text: 'escopo descartado',
            status: ReportItemStatus.discarded,
          ),
        ]),
        report('b', [item(id: '3', text: 'outro assunto')]),
      ],
      'Escopo',
    );

    expect(hits, hasLength(1));
    expect(hits.single.sessionId, 'a');
    expect(hits.single.item.id, '1');
    expect(searchReports([report('a', [])], '   '), isEmpty);
  });

  test('only an approved follow-up enters the panel', () {
    final hits = approvedFollowUpHits([
      report('a', [
        item(
          id: '1',
          text: 'mandar o resumo',
          kind: ReportItemKind.followUp,
          status: ReportItemStatus.approved,
        ),
        item(
          id: '2',
          text: 'ainda aberto',
          kind: ReportItemKind.followUp,
        ),
      ]),
      report('b', [
        item(
          id: '3',
          text: 'decisão',
          kind: ReportItemKind.decision,
          status: ReportItemStatus.approved,
        ),
      ]),
    ]);

    expect(hits, hasLength(1));
    expect(hits.single.item.text, 'mandar o resumo');
  });

  test('a text or status change is a revision and assignee is not', () {
    final before = item(id: '1', text: 'fechar o escopo');
    final renamed = before.copyWith(text: 'fechar depois');
    final rows = revisionsForChange(
      before: before,
      after: renamed,
      at: '2026-11-02T15:04:00',
    );
    expect(rows, hasLength(1));
    expect(rows.single.field, 'text');
    expect(rows.single.before, 'fechar o escopo');
    expect(rows.single.after, 'fechar depois');

    final approved = revisionsForChange(
      before: renamed,
      after: renamed.copyWith(status: ReportItemStatus.approved),
      at: '2026-11-02T15:05:00',
    );
    expect(approved.single.field, 'status');
    expect(approved.single.before, 'unconfirmed');
    expect(approved.single.after, 'approved');

    expect(
      revisionsForChange(
        before: before,
        after: before.copyWith(assignee: 'Ana'),
        at: '2026-11-02T15:06:00',
      ),
      isEmpty,
    );
    expect(latestTextChange([...rows, ...approved], '1')!.after, 'fechar depois');

    final stored = revisionsFromJson(revisionsToJson(rows));
    expect(stored.single.before, 'fechar o escopo');
    expect(
      () => revisionsFromJson({'schema_version': 2, 'items': []}),
      throwsFormatException,
    );
  });
}
