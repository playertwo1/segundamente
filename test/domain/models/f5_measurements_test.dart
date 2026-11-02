import 'package:flutter_test/flutter_test.dart';
import 'package:memex/domain/models/session_report.dart';
import 'package:memex/domain/models/session_report_export.dart';
import 'package:memex/domain/models/transcript_import.dart';

void main() {
  test('a synthetic 50-minute transcript parses and exports', () {
    final text = _syntheticTranscript(1500);
    final parseWatch = Stopwatch()..start();
    final parsed = TranscriptImport.parse(text.codeUnits);
    parseWatch.stop();
    // ignore: avoid_print
    print(
      'F5-03 parse_ms=${parseWatch.elapsedMilliseconds} segments=${parsed.segments.length}',
    );

    expect(parsed.timestampsFound, isTrue);
    expect(parsed.segments, hasLength(1500));
    expect(parseWatch.elapsedMilliseconds, lessThan(5000));

    final report = SessionReport(
      schemaVersion: sessionReportSchemaVersion,
      sessionId: 'medida',
      kind: ReportKind.reuniao,
      title: 'Relatório de reunião',
      sections: sectionsFor(ReportKind.reuniao),
      items: [
        for (var i = 0; i < 100; i++)
          ReportItem(
            id: 'item_$i',
            kind: ReportItemKind.decision,
            text: 'decisão $i',
            status: ReportItemStatus.unconfirmed,
            assignee: reportAssigneeUnknown,
            due: reportDueUnknown,
            source: ReportSource(
              segmentId: 'seg_$i',
              excerpt: 'decisão $i',
              clock: '00:00:01',
            ),
          ),
      ],
    );
    final exportWatch = Stopwatch()..start();
    for (final format in ReportExportFormat.values) {
      final bytes = exportSessionReportBytes(
        report: report,
        exportedAt: DateTime(2026, 11, 2, 15, 4),
        format: format,
      );
      expect(bytes, isNotEmpty);
    }
    exportWatch.stop();
    // ignore: avoid_print
    print(
      'F5-03 export_ms=${exportWatch.elapsedMilliseconds} items=100',
    );
    expect(exportWatch.elapsedMilliseconds, lessThan(5000));
  });
}

String _syntheticTranscript(int lines) {
  final buffer = StringBuffer();
  for (var i = 0; i < lines; i++) {
    final total = i * 2;
    final hour = total ~/ 3600;
    final minute = (total % 3600) ~/ 60;
    final second = total % 60;
    final clock = '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}:'
        '${second.toString().padLeft(2, '0')}';
    buffer
      ..writeln(clock)
      ..writeln('frase $i');
  }
  return buffer.toString();
}
