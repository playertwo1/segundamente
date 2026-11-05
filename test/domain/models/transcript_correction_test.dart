import 'package:flutter_test/flutter_test.dart';
import 'package:memex/domain/models/session_report.dart';
import 'package:memex/domain/models/transcript_correction.dart';

void main() {
  suggestTests();
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

void suggestTests() {
  List<TextFix> suggest(String text, List<String> terms) => suggestFixes(
        [ReportSegment(id: 's', text: text)],
        terms,
      );
  String show(List<TextFix> f) => f.map((x) => '${x.from}>${x.to}').join('|');

  group('suggestFixes', () {
    test('case and accent only, or one letter away for longer terms', () {
      expect(show(suggest('falou com a Marilia ontem', ['Marília'])),
          'Marilia>Marília');
      expect(show(suggest('abrir o Memix agora', ['Memex'])), 'Memix>Memex');
    });

    test('a short term only matches ignoring case and accents', () {
      expect(suggest('a ata de hoje', ['ota']), isEmpty);
      expect(show(suggest('a ota de hoje', ['OTA'])), 'ota>OTA');
    });

    test('multi-word terms match a window with the same word count', () {
      expect(show(suggest('com Sra Alvarenga hoje', ['Sra. Alvarenga'])),
          'Sra Alvarenga>Sra. Alvarenga');
      expect(show(suggest('com dona alvarenga hoje', ['Dona Alvarenga'])),
          'dona alvarenga>Dona Alvarenga');
    });

    test('already right, ambiguous or another term are left alone', () {
      expect(suggest('o Memex abriu', ['Memex']), isEmpty);
      expect(suggest('Memix e Memix de novo', ['Memex']), isEmpty);
      expect(suggest('Memex e Memix', ['Memex', 'Memix']), isEmpty);
    });

    test('every proposal applies cleanly', () {
      final seg = [const ReportSegment(id: 's', text: 'a marilia viu o Memix')];
      final fixes = suggestFixes(seg, ['Marília', 'Memex']);
      expect(applyFixes(seg, fixes).single.text, 'a Marília viu o Memex');
    });
  });
}
