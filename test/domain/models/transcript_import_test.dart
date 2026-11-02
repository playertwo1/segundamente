import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:memex/domain/models/transcript_import.dart';

void main() {
  test('keeps Samsung-style clocks and leaves the header as a title', () {
    const raw = 'Reunião\n'
        '\n'
        '00:00\n'
        'Olá\n'
        '\n'
        'Locutor 1 00:01:02\n'
        'segunda linha\n'
        '\n'
        '화자 1 (1:05)\n'
        'oi\n'
        '\n'
        '[00:02:03] Locutor 2\n'
        'texto\n'
        '\n'
        '00:00:10,000 --> 00:00:14,120\n'
        'fala\n';

    final parsed = TranscriptImport.parse(utf8.encode(raw));

    expect(parsed.kind, TranscriptKind.text);
    expect(parsed.timestampsFound, isTrue);
    expect(parsed.title, 'Reunião');
    expect(
      parsed.segments.map((segment) => segment.clock),
      ['00:00:00', '00:01:02', '00:01:05', '00:02:03', '00:00:10'],
    );
    expect(parsed.segments[1].speaker, 'Locutor 1');
    expect(parsed.segments[1].text, 'segunda linha');
    expect(parsed.segments[2].speaker, '화자 1');
    expect(parsed.segments[3].speaker, 'Locutor 2');
    expect(parsed.segments[4].text, 'fala');
    expect(
        parsed.segments.any((segment) => segment.text == 'Reunião'), isFalse);
    expect(
      parsed.normalizedText,
      'Reunião\n'
      '\n'
      '[00:00:00]\n'
      'Olá\n'
      '\n'
      '[00:01:02] Locutor 1\n'
      'segunda linha\n'
      '\n'
      '[00:01:05] 화자 1\n'
      'oi\n'
      '\n'
      '[00:02:03] Locutor 2\n'
      'texto\n'
      '\n'
      '[00:00:10]\n'
      'fala',
    );
  });

  test('does not invent a clock when the text has none', () {
    final bytes = utf8.encode('  só texto  ');
    final caller = List<int>.from(bytes);
    final parsed = TranscriptImport.parse(caller);

    caller[0] = 0;
    expect(parsed.originalBytes, bytes);
    expect(parsed.timestampsFound, isFalse);
    expect(parsed.segments.single.clock, isNull);
    expect(parsed.normalizedText, 'só texto');
    expect(parsed.normalizedText.contains('00:00'), isFalse);
  });

  test('refuses PDF bytes and keeps the caller list intact', () {
    final bytes = <int>[0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34];
    final caller = List<int>.from(bytes);
    final parsed = TranscriptImport.parse(caller);

    expect(caller, bytes);
    expect(parsed.kind, TranscriptKind.pdfUnsupported);
    expect(parsed.outgoingText, isEmpty);
    expect(parsed.normalizedText, isEmpty);
    expect(parsed.originalBytes, bytes);
  });

  test('confirmation keeps the exact text and rejects an empty send', () {
    expect(
      confirmSend(outgoingText: '  sai agora  ', confirmed: false),
      isNull,
    );
    expect(confirmSend(outgoingText: '   ', confirmed: true), isNull);
    expect(
      confirmSend(outgoingText: '  sai agora  ', confirmed: true)!.outgoingText,
      '  sai agora  ',
    );
  });

  test('only an all-txt share uses the transcript preview', () {
    expect(sharedPathsArePlainText(['C:\\share\\nota.TXT']), isTrue);
    expect(sharedPathsArePlainText(['a.txt', 'b.docx']), isFalse);
    expect(sharedPathsArePlainText(['notas.pdf']), isFalse);
    expect(sharedPathsArePlainText(const []), isFalse);
  });
}
