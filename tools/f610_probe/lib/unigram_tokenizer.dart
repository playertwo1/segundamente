// Tokenizador Unigram (SentencePiece) do XLM-R, lido do tokenizer.json do Hugging Face.
// shortcut: sem o charsmap Precompiled (NFKC); texto com formas decompostas ou compatibilidade
// (ex.: "ﬁ", "²") pode tokenizar diferente do Python. Conferido contra o PC em bin/check_tokenizer.dart.
import 'dart:convert';
import 'dart:io';

class UnigramTokenizer {
  UnigramTokenizer._(this._pieces, this._scores, this._unkId, this._maxLen);

  final Map<String, int> _pieces;
  final List<double> _scores;
  final int _unkId;
  final int _maxLen;
  static const bos = 0, eos = 2;

  factory UnigramTokenizer.fromFile(String path) {
    final j = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
    final model = j['model'] as Map<String, dynamic>;
    final vocab = model['vocab'] as List;
    final pieces = <String, int>{};
    final scores = <double>[];
    var maxLen = 1;
    for (var i = 0; i < vocab.length; i++) {
      final p = vocab[i][0] as String;
      scores.add((vocab[i][1] as num).toDouble());
      pieces[p] = i;
      if (p.runes.length > maxLen) maxLen = p.runes.length;
    }
    return UnigramTokenizer._(pieces, scores, model['unk_id'] as int, maxLen);
  }

  /// `<s>` + peças + `</s>`, cortado em [maxTokens] no total.
  List<int> encode(String text, {int maxTokens = 128}) {
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final ids = <int>[];
    for (final w in words) {
      ids.addAll(_viterbi('\u2581$w'));
    }
    final body = ids.length > maxTokens - 2 ? ids.sublist(0, maxTokens - 2) : ids;
    return [bos, ...body, eos];
  }

  List<int> _viterbi(String word) {
    final r = word.runes.toList();
    final n = r.length;
    final best = List<double>.filled(n + 1, double.negativeInfinity)..[0] = 0;
    final from = List<int>.filled(n + 1, -1);
    final pid = List<int>.filled(n + 1, -1);
    for (var i = 0; i < n; i++) {
      if (best[i] == double.negativeInfinity) continue;
      var found = false;
      final sb = StringBuffer();
      for (var l = 1; l <= _maxLen && i + l <= n; l++) {
        sb.writeCharCode(r[i + l - 1]);
        final id = _pieces[sb.toString()];
        if (id == null || id == _unkId) continue;
        found = true;
        final s = best[i] + _scores[id];
        if (s > best[i + l]) {
          best[i + l] = s;
          from[i + l] = i;
          pid[i + l] = id;
        }
      }
      if (!found) {
        // Sem peça que comece aqui: um <unk> para este caractere.
        final s = best[i] - 10;
        if (s > best[i + 1]) {
          best[i + 1] = s;
          from[i + 1] = i;
          pid[i + 1] = _unkId;
        }
      }
    }
    final out = <int>[];
    for (var p = n; p > 0; p = from[p]) {
      out.add(pid[p]);
    }
    return out.reversed.toList();
  }
}
