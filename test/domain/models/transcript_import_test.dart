import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:memex/domain/models/transcript_import.dart';

void main() {
  sameLineTextTests();

  test('shared audio and PDF become chat attachments, other files do not', () {
    final files = chatAttachmentsFromPaths(
      ['/x/Voz 260914_170715.m4a', '/docs/a.PDF'],
    );
    expect(files, [
      {
        'path': '/x/Voz 260914_170715.m4a',
        'name': 'Voz 260914_170715.m4a',
        'mime': 'audio/mp4'
      },
      {'path': '/docs/a.PDF', 'name': 'a.PDF', 'mime': 'application/pdf'},
    ]);
    expect(chatAttachmentsFromPaths(['/x/backup.zip']), isNull);
    expect(chatAttachmentsFromPaths(['/x/a.m4a', '/x/b.zip']), isNull);
  });

  test('decodes UTF-16 with BOM and keeps the original bytes', () {
    const raw = 'Conteúdo\n00:01 olá';
    final be = <int>[
      0xFE,
      0xFF,
      for (final u in raw.codeUnits) ...[u >> 8, u & 255]
    ];
    final le = <int>[
      0xFF,
      0xFE,
      for (final u in raw.codeUnits) ...[u & 255, u >> 8]
    ];
    for (final bytes in [be, le]) {
      final parsed = TranscriptImport.parse(bytes);
      expect(parsed.kind, TranscriptKind.text);
      expect(parsed.outgoingText, contains('Conteúdo'));
      expect(parsed.originalBytes, bytes);
    }
  });

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

  test('SRT keeps clocks and text, drops numbering and markup', () {
    final raw = [
      '1',
      '00:00:01,000 --> 00:00:03,500',
      '<i>Bom dia</i> a todos.',
      '',
      '2',
      '00:01:05,250 --> 00:01:08,000',
      'Primeira linha',
      'segunda linha',
      '',
    ].join('\n');
    final parsed = TranscriptImport.fromText(raw);

    expect(parsed.timestampsFound, isTrue);
    expect(parsed.title, isNull);
    expect(parsed.segments.map((s) => s.clock), ['00:00:01', '00:01:05']);
    expect(parsed.segments[0].text, 'Bom dia a todos.');
    expect(parsed.segments[1].text, 'Primeira linha\nsegunda linha');
    expect(parsed.normalizedText, isNot(contains('<i>')));
    expect(
        parsed.normalizedText, isNot(matches(RegExp(r'^2$', multiLine: true))));
    expect(parsed.originalBytes, utf8.encode(raw));
  });

  test('VTT skips header, NOTE and cue ids, reads voice tags and settings', () {
    final raw = [
      'WEBVTT - reuniao',
      '',
      'NOTE comentario do editor',
      '',
      'intro',
      '00:00:02.000 --> 00:00:04.000 align:start position:0%',
      '<v Marina>Vamos começar.</v>',
      '',
      '01:02:03.400 --> 01:02:05.000',
      '<v.loud Carlos>Concordo.</v>',
      '',
    ].join('\n');
    final parsed = TranscriptImport.fromText(raw);

    expect(parsed.title, isNull);
    expect(parsed.segments.map((s) => s.clock), ['00:00:02', '01:02:03']);
    expect(parsed.segments.map((s) => s.speaker), ['Marina', 'Carlos']);
    expect(parsed.segments.map((s) => s.text), ['Vamos começar.', 'Concordo.']);
    expect(parsed.normalizedText, isNot(contains('WEBVTT')));
    expect(parsed.normalizedText, isNot(contains('NOTE')));
    expect(
        parsed.normalizedText, contains('[00:00:02] Marina\nVamos começar.'));
  });

  test('a Nome: label is a speaker only when it repeats', () {
    final raw = [
      '1',
      '00:00:01,000 --> 00:00:02,000',
      'Ana: oi',
      '',
      '2',
      '00:00:03,000 --> 00:00:04,000',
      'Ana: tudo bem?',
      '',
      '3',
      '00:00:05,000 --> 00:00:06,000',
      'Atenção: prazo na sexta',
      '',
    ].join('\n');
    final parsed = TranscriptImport.fromText(raw);

    expect(parsed.segments.map((s) => s.speaker), ['Ana', 'Ana', null]);
    expect(parsed.segments.map((s) => s.text),
        ['oi', 'tudo bem?', 'Atenção: prazo na sexta']);
  });

  test('a subtitle file with no readable cue stays plain text', () {
    final parsed = TranscriptImport.fromText('WEBVTT\n\nNOTE nada aqui');
    expect(parsed.kind, TranscriptKind.text);
    expect(parsed.timestampsFound, isFalse);
    expect(parsed.normalizedText, contains('NOTE nada aqui'));
  });

  test('TXT ranges without milliseconds keep the old behaviour', () {
    final parsed = TranscriptImport.fromText(
      'Reuniao\n00:00:01 --> 00:00:03\nfala um\n00:00:04 --> 00:00:06\nfala dois',
    );
    expect(parsed.title, 'Reuniao');
    expect(parsed.segments.map((s) => s.text), ['fala um', 'fala dois']);
  });

  test('shared SRT and VTT files use the transcript preview', () {
    expect(sharedPathsArePlainText(['/x/legenda.SRT']), isTrue);
    expect(sharedPathsArePlainText(['/x/a.vtt', '/x/b.txt']), isTrue);
    expect(sharedPathsArePlainText(['/x/a.vtt', '/x/b.docx']), isFalse);
  });
}

void sameLineTextTests() {
  group('text on the same line as the clock', () {
    test('a long line after the clock is the text, not a speaker', () {
      final parsed = TranscriptImport.parse(utf8.encode(
        '[00:00:05] Bom dia a todos.\n\n[00:00:20] Marena fica responsavel.\n',
      ));
      expect(parsed.segments.map((s) => s.text),
          ['Bom dia a todos.', 'Marena fica responsavel.']);
      expect(parsed.segments.every((s) => s.speaker == null), isTrue);
      expect(parsed.segments.first.clock, '00:00:05');
    });

    test('a short name with text below stays a speaker', () {
      final parsed = TranscriptImport.parse(
          utf8.encode('[00:00:05] Ana\nBom dia a todos.\n'));
      expect(parsed.segments.single.speaker, 'Ana');
      expect(parsed.segments.single.text, 'Bom dia a todos.');
    });
  });
}
