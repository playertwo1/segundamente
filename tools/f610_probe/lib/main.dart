// Sonda do F6-10: mede embeddings multilíngues no aparelho. App separado, fora do app principal.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(const MaterialApp(home: Probe()));

class Probe extends StatefulWidget {
  const Probe({super.key});
  @override
  State<Probe> createState() => _ProbeState();
}

class _ProbeState extends State<Probe> {
  final _log = StringBuffer();

  @override
  void initState() {
    super.initState();
    _run();
  }

  void _say(String s) {
    debugPrint('F610 $s');
    setState(() => _log.writeln(s));
  }

  Future<void> _run() async {
    try {
      final data = jsonDecode(await rootBundle.loadString('assets/probe_data.json')) as Map<String, dynamic>;
      final dir = (await getExternalStorageDirectory())!;
      final results = <String, dynamic>{};
      for (final key in (data['models'] as Map<String, dynamic>).keys) {
        final file = File('${dir.path}/$key.onnx');
        if (!file.existsSync()) {
          _say('$key: modelo ausente em ${file.path}');
          continue;
        }
        results[key] = await _measure(key, file, data, data['models'][key] as Map<String, dynamic>);
      }
      final out = File('${dir.path}/resultado.json')..writeAsStringSync(jsonEncode(results));
      _say('F610_DONE ${out.path}');
    } catch (e, st) {
      _say('F610_ERRO $e\n$st');
    }
  }

  Future<Float32List> _embed(OrtSession s, List<dynamic> tokens, List<String> inputs) async {
    final n = tokens.length;
    final ids = Int64List.fromList([for (final t in tokens) (t as num).toInt()]);
    final feeds = <String, OrtValue>{
      'input_ids': await OrtValue.fromList(ids, [1, n]),
      'attention_mask': await OrtValue.fromList(Int64List.fromList(List.filled(n, 1)), [1, n]),
      if (inputs.contains('token_type_ids')) 'token_type_ids': await OrtValue.fromList(Int64List(n), [1, n]),
    };
    final out = await s.run(feeds);
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

  double _dot(List<num> a, List<num> b) {
    var s = 0.0;
    for (var i = 0; i < a.length; i++) {
      s += a[i] * b[i];
    }
    return s;
  }

  Future<Map<String, dynamic>> _measure(String key, File file, Map<String, dynamic> data, Map<String, dynamic> m) async {
    final inputs = (m['inputs'] as List).cast<String>();
    final rssBefore = ProcessInfo.currentRss;
    final sw = Stopwatch()..start();
    final s = await OnnxRuntime().createSession(file.path);
    final loadMs = sw.elapsedMilliseconds;
    final noteTok = m['note_tokens'] as List;
    final queryTok = m['query_tokens'] as List;
    final noteTimes = <int>[];
    final noteVecs = <Float32List>[];
    for (final t in noteTok) {
      sw.reset();
      sw.start();
      noteVecs.add(await _embed(s, t as List, inputs));
      noteTimes.add(sw.elapsedMicroseconds);
    }
    final queryTimes = <int>[];
    final queryVecs = <Float32List>[];
    for (final t in queryTok) {
      sw.reset();
      sw.start();
      queryVecs.add(await _embed(s, t as List, inputs));
      queryTimes.add(sw.elapsedMicroseconds);
    }
    final rssAfter = ProcessInfo.currentRss;
    final maxRss = ProcessInfo.maxRss;
    // Fidelidade: cosseno entre o vetor do aparelho e o vetor de referência do PC.
    final noteRef = m['note_ref'] as List;
    final queryRef = m['query_ref'] as List;
    var minCos = 1.0;
    for (var i = 0; i < noteVecs.length; i++) {
      minCos = math.min(minCos, _dot(noteVecs[i], (noteRef[i] as List).cast<num>()));
    }
    for (var i = 0; i < queryVecs.length; i++) {
      minCos = math.min(minCos, _dot(queryVecs[i], (queryRef[i] as List).cast<num>()));
    }
    // Acerto com os vetores calculados no aparelho.
    final ids = (data['note_ids'] as List).cast<String>();
    final queries = (data['queries'] as List).cast<Map<String, dynamic>>();
    final hit3 = {'lex': [0, 0], 'par': [0, 0]};
    for (var qi = 0; qi < queries.length; qi++) {
      final gold = queries[qi]['gold'] as String?;
      final kind = queries[qi]['kind'] as String;
      if (gold == null) continue;
      final scores = [for (var ni = 0; ni < ids.length; ni++) (ni, _dot(queryVecs[qi], noteVecs[ni]))]
        ..sort((a, b) => b.$2.compareTo(a.$2));
      final top3 = scores.take(3).map((e) => ids[e.$1]).toList();
      hit3[kind]![1]++;
      if (top3.contains(gold)) hit3[kind]![0]++;
    }
    double avg(List<int> v) => v.reduce((a, b) => a + b) / v.length / 1000;
    final sortedNote = [...noteTimes]..sort();
    final r = {
      'modelo_mb': (file.lengthSync() / 1e6).round(),
      'carregar_ms': loadMs,
      'ms_por_nota_media': avg(noteTimes),
      'ms_por_nota_p95': sortedNote[(sortedNote.length * 0.95).floor()] / 1000,
      'ms_por_consulta_media': avg(queryTimes),
      'rss_antes_mb': (rssBefore / 1e6).round(),
      'rss_depois_mb': (rssAfter / 1e6).round(),
      'rss_pico_mb': (maxRss / 1e6).round(),
      'cosseno_minimo_vs_pc': double.parse(minCos.toStringAsFixed(4)),
      'acerto3_lex': '${hit3['lex']![0]}/${hit3['lex']![1]}',
      'acerto3_par': '${hit3['par']![0]}/${hit3['par']![1]}',
    };
    _say('$key ${jsonEncode(r)}');
    await s.close();
    return r;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('F6-10 sonda')),
        body: SingleChildScrollView(padding: const EdgeInsets.all(12), child: SelectableText(_log.toString())),
      );
}
