import 'package:flutter_test/flutter_test.dart';
import 'package:memex/domain/models/session_report.dart';
import 'package:memex/domain/models/transcript_correction.dart';

void main() {
  const segments = [
    ReportSegment(
        id: 'seg_0',
        text: 'falou com a dona Marilia sobre o Memix',
        clock: '00:01'),
    ReportSegment(id: 'seg_1', text: 'o prazo e dia dez, dia dez mesmo'),
  ];

  List<ReportSegment> fix(List<TextFix> fixes) => applyFixes(segments, fixes);

  void refused(List<TextFix> fixes, String reason) {
    expect(
      () => fix(fixes),
      throwsA(
          isA<CorrectionRefused>().having((e) => e.reason, 'reason', reason)),
    );
  }

  test('replaces one exact piece and keeps ids, clock and the input', () {
    final out = fix([
      const TextFix(segmentId: 'seg_0', from: 'Marilia', to: 'Marília'),
      const TextFix(segmentId: 'seg_0', from: 'Memix', to: 'Memex'),
    ]);
    expect(out[0].text, 'falou com a dona Marília sobre o Memex');
    expect(out[0].clock, '00:01');
    expect(out[1].text, segments[1].text);
    expect(segments[0].text, contains('Memix'));
  });

  test('refuses what is not a precise, small substitution', () {
    refused(
        [const TextFix(segmentId: 'x', from: 'a', to: 'b')], 'unknown segment');
    refused(
        [const TextFix(segmentId: 'seg_0', from: '', to: 'b')], 'empty from');
    refused([const TextFix(segmentId: 'seg_0', from: 'Memix', to: ' ')],
        'empty to');
    refused([const TextFix(segmentId: 'seg_0', from: 'Memix', to: 'Memix')],
        'no change');
    refused([const TextFix(segmentId: 'seg_0', from: 'Memix', to: 'a\nb')],
        'to has a line break');
    refused([TextFix(segmentId: 'seg_0', from: 'Memix', to: 'x' * 60)],
        'to is too long');
    refused([const TextFix(segmentId: 'seg_0', from: 'Zzz', to: 'Memex')],
        'from not found');
    refused([const TextFix(segmentId: 'seg_1', from: 'dia dez', to: 'dia 10')],
        'from is ambiguous');
  });

  test('a later fix sees the text left by the earlier one', () {
    refused([
      const TextFix(segmentId: 'seg_0', from: 'Memix', to: 'Memex'),
      const TextFix(segmentId: 'seg_0', from: 'Memix', to: 'Outro'),
    ], 'from not found');
  });

  test('too many fixes are refused', () {
    final many = [
      for (var i = 0; i <= correctionMaxFixes; i++)
        const TextFix(segmentId: 'seg_0', from: 'a', to: 'b'),
    ];
    refused(many, 'too many fixes');
  });

  test('round trips through JSON and rejects another schema', () {
    final fixes = [const TextFix(segmentId: 's', from: 'a', to: 'b')];
    final back = correctionsFromJson(correctionsToJson(fixes));
    expect([back.single.segmentId, back.single.from, back.single.to],
        ['s', 'a', 'b']);
    expect(
      () => correctionsFromJson({'schema_version': 9, 'fixes': []}),
      throwsFormatException,
    );
  });
}
