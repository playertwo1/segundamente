import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:f610_probe/real_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lê só notas com texto e ignora insight, apagadas e curtas', () {
    final dir = Directory.systemTemp.createTempSync('f610');
    final enc = ZipEncoder();
    final a = Archive()
      ..addFile(ArchiveFile.bytes('workspace/_u/Cards/2025/11/05_ts_1.yaml', utf8.encode('title: Reunião\nfact: Falei com o João sobre o orçamento da obra.\n')))
      ..addFile(ArchiveFile.bytes('workspace/_u/Cards/2025/11/05_ts_2.yaml', utf8.encode('title: Resumo\nfact: Padrão de gastos nos últimos dias da semana.\ntags: [insight]\n')))
      ..addFile(ArchiveFile.bytes('workspace/_u/Cards/2025/11/05_ts_3.yaml', utf8.encode('title: Outro\nfact: Texto longo o bastante para entrar na lista.\nui_configs:\n  - template_id: insight_summary\n    data: {}\n')))
      ..addFile(ArchiveFile.bytes('workspace/_u/Cards/2025/11/05_ts_4.yaml', utf8.encode('fact: Nota apagada que não deve entrar na lista.\ndeleted: true\n')))
      ..addFile(ArchiveFile.bytes('workspace/_u/Cards/2025/11/05_ts_5.yaml', utf8.encode('fact: curta\n')))
      ..addFile(ArchiveFile.bytes('workspace/_u/Facts/2025/11/05.md', utf8.encode('não é cartão e não entra na lista de notas')));
    final path = '${dir.path}/b.zip';
    File(path).writeAsBytesSync(enc.encode(a));
    final notes = notesFromBackup(path);
    expect(notes.length, 1);
    expect(notes.single.text, contains('orçamento da obra'));
    dir.deleteSync(recursive: true);
  });

  test('busca por texto ignora acento e caixa', () {
    final notes = [Note('Reunião com o João'), Note('Receita de bolo')];
    expect(textRank('reuniao', notes), [0]);
    expect(textRank('futebol', notes), isEmpty);
  });
}
