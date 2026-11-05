// Uso: dart run bin/check_tokenizer.dart <tokenizer.json> <esperado.json>
// esperado.json: [{"t": "texto", "ids": [..]}]. Imprime as diferenças.
import 'dart:convert';
import 'dart:io';

import 'package:f610_probe/unigram_tokenizer.dart';

void main(List<String> a) {
  final tok = UnigramTokenizer.fromFile(a[0]);
  final cases = jsonDecode(File(a[1]).readAsStringSync()) as List;
  var ok = 0;
  for (final c in cases) {
    final got = tok.encode(c['t'] as String);
    final want = (c['ids'] as List).cast<int>();
    if (got.length == want.length && List.generate(got.length, (i) => got[i] == want[i]).every((e) => e)) {
      ok++;
    } else {
      stdout.writeln('DIFERE: ${jsonEncode(c['t'])}\n  dart: $got\n  py:   $want');
    }
  }
  stdout.writeln('iguais: $ok/${cases.length}');
}
