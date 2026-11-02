import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/domain/models/session_report.dart';
import 'package:memex/domain/models/session_report_export.dart';

void main() {
  const segments = [
    ReportSegment(id: 'seg_0', text: 'fechar o escopo', clock: '00:00:01'),
    ReportSegment(id: 'seg_1', text: 'mandar o resumo', clock: '00:00:02'),
  ];
  final exportedAt = DateTime(2026, 11, 2, 15, 4);

  SessionReport sample() {
    return sessionReportFromModelJson(
      sessionId: 's',
      kind: ReportKind.reuniao,
      customTitle: null,
      segments: segments,
      json: {
        'schema_version': 1,
        'items': [
          {
            'kind': 'decision',
            'text': 'fechar o escopo',
            'segment_id': 'seg_0',
            'excerpt': 'fechar o escopo',
            'clock': '00:00:01',
          },
          {
            'kind': 'task',
            'text': 'mandar o resumo',
            'segment_id': 'seg_1',
            'excerpt': 'resumo',
            'clock': '00:00:02',
          },
        ],
      },
    );
  }

  test('markdown, pdf and docx carry the same report text', () {
    final report = sample();
    final markdown = utf8.decode(
      exportSessionReportBytes(
        report: report,
        exportedAt: exportedAt,
        format: ReportExportFormat.markdown,
      ),
    );
    final pdf = latin1.decode(
      exportSessionReportBytes(
        report: report,
        exportedAt: exportedAt,
        format: ReportExportFormat.pdf,
      ),
    );
    final docx = _docxText(
      exportSessionReportBytes(
        report: report,
        exportedAt: exportedAt,
        format: ReportExportFormat.docx,
      ),
    );

    for (final text in [markdown, pdf, docx]) {
      expect(text, contains('Relatório de reunião'));
      expect(text, contains('Data: 2026-11-02 15:04'));
      expect(text, contains('Decisões'));
      expect(text, contains('Tarefas'));
      expect(text, contains('não identificado'));
      expect(text, contains('não informado'));
      expect(text, contains('Fonte: fechar o escopo'));
      expect(text, contains('Relógio: 00:00:01'));
      expect(text, contains('Fonte: resumo'));
      expect(text, contains('Não confirmado'));
    }
    expect(pdf, startsWith('%PDF-1.4'));
    expect(pdf, contains('/Encoding /WinAnsiEncoding'));
  });

  test('a discarded item stays out of the full export', () {
    final report = setReportItemStatus(
      sample(),
      itemId: 'item_2',
      status: ReportItemStatus.discarded,
    );
    final markdown = utf8.decode(
      exportSessionReportBytes(
        report: report,
        exportedAt: exportedAt,
        format: ReportExportFormat.markdown,
      ),
    );
    expect(markdown, contains('fechar o escopo'));
    expect(markdown, isNot(contains('mandar o resumo')));
  });

  test('a selected item is the only body that is exported', () {
    final markdown = utf8.decode(
      exportSessionReportBytes(
        report: sample(),
        exportedAt: exportedAt,
        format: ReportExportFormat.markdown,
        itemIds: {'item_1'},
      ),
    );
    expect(markdown, contains('fechar o escopo'));
    expect(markdown, isNot(contains('mandar o resumo')));
    expect(markdown, isNot(contains('Tarefas')));
  });

  test('a long report uses a second pdf page', () {
    final report = SessionReport(
      schemaVersion: sessionReportSchemaVersion,
      sessionId: 's',
      kind: ReportKind.livre,
      title: 'Relatório livre',
      sections: sectionsFor(ReportKind.livre),
      items: [
        ReportItem(
          id: 'item_1',
          kind: ReportItemKind.summary,
          text: List.filled(50, 'linha com ação').join('\n'),
          status: ReportItemStatus.unconfirmed,
          assignee: reportAssigneeUnknown,
          due: reportDueUnknown,
          source: const ReportSource(
            segmentId: 'seg_0',
            excerpt: 'ação',
            clock: null,
          ),
        ),
      ],
    );
    final pdf = latin1.decode(
      exportSessionReportBytes(
        report: report,
        exportedAt: exportedAt,
        format: ReportExportFormat.pdf,
      ),
    );
    expect('/Type /Page /Parent'.allMatches(pdf).length, 2);
    expect(pdf, contains('ação'));
  });
}

String _docxText(List<int> bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final file = archive.findFile('word/document.xml');
  expect(file, isNotNull);
  return utf8.decode(file!.content as List<int>);
}
