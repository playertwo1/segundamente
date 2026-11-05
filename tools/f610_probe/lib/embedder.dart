import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

import 'unigram_tokenizer.dart';

/// Modelo de embeddings ONNX com tokenizador próprio. [queryPrefix]/[passagePrefix] são os do e5.
class Embedder {
  Embedder(this._session, this._inputs, this._tok, this.queryPrefix, this.passagePrefix);

  final OrtSession _session;
  final List<String> _inputs;
  final UnigramTokenizer _tok;
  final String queryPrefix;
  final String passagePrefix;

  static Future<Embedder> load(String model, String tokenizer, {required bool e5}) async {
    final s = await OnnxRuntime().createSession(model);
    final inputs = [for (final i in await s.getInputInfo()) i['name'] as String];
    return Embedder(s, inputs, UnigramTokenizer.fromFile(tokenizer), e5 ? 'query: ' : '', e5 ? 'passage: ' : '');
  }

  Future<Float32List> embed(String text, {required bool query}) =>
      embedIds(_tok.encode((query ? queryPrefix : passagePrefix) + text));

  Future<Float32List> embedIds(List<int> ids) async {
    final n = ids.length;
    final feeds = <String, OrtValue>{
      'input_ids': await OrtValue.fromList(Int64List.fromList(ids), [1, n]),
      'attention_mask': await OrtValue.fromList(Int64List.fromList(List.filled(n, 1)), [1, n]),
      if (_inputs.contains('token_type_ids')) 'token_type_ids': await OrtValue.fromList(Int64List(n), [1, n]),
    };
    final out = await _session.run(feeds);
    final hidden = await out.values.first.asFlattenedList();
    for (final v in [...feeds.values, ...out.values]) {
      await v.dispose();
    }
    final dim = hidden.length ~/ n;
    final v = Float32List(dim);
    for (var i = 0; i < n; i++) {
      for (var d = 0; d < dim; d++) {
        v[d] += (hidden[i * dim + d] as num).toDouble() / n;
      }
    }
    var norm = 0.0;
    for (final x in v) {
      norm += x * x;
    }
    norm = math.sqrt(norm);
    for (var d = 0; d < dim; d++) {
      v[d] /= norm;
    }
    return v;
  }

  Future<void> close() => _session.close();
}

double dot(List<num> a, List<num> b) {
  var s = 0.0;
  for (var i = 0; i < a.length; i++) {
    s += a[i] * b[i];
  }
  return s;
}
