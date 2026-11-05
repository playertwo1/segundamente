// Teste do F6-10 com notas reais. Tudo roda no aparelho; o resultado salvo tem só números.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yaml/yaml.dart';

import 'embedder.dart';

class Note {
  Note(this.text) : folded = fold(text);
  final String text;
  final String folded;
}

const _acc = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', 'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ç': 'c',
};
String fold(String s) => s.toLowerCase().split('').map((c) => _acc[c] ?? c).join();

const _stop = {'que', 'com', 'para', 'uma', 'dos', 'das', 'por', 'nos', 'nas', 'mais', 'como', 'sobre', 'meu', 'minha', 'meus', 'minhas'};

/// Aproximação da busca por texto: notas que contêm alguma palavra da consulta, mais palavras primeiro.
List<int> textRank(String query, List<Note> notes) {
  final toks = fold(query).split(RegExp(r'[^a-z0-9]+')).where((t) => t.length >= 3 && !_stop.contains(t)).toSet();
  final scored = <(int, int)>[];
  for (var i = 0; i < notes.length; i++) {
    final c = toks.where(notes[i].folded.contains).length;
    if (c > 0) scored.add((i, c));
  }
  scored.sort((a, b) => b.$2.compareTo(a.$2));
  return [for (final s in scored) s.$1];
}

List<Note> notesFromBackup(String zipPath) {
  final input = InputFileStream(zipPath);
  final zip = ZipDecoder().decodeStream(input);
  final cardRe = RegExp(r'^workspace/(?:[^/]+/)?Cards/.*\.ya?ml$');
  final notes = <Note>[];
  for (final f in zip) {
    if (!f.isFile || !cardRe.hasMatch(f.name)) continue;
    try {
      final y = loadYaml(utf8.decode(f.content as List<int>, allowMalformed: true));
      if (y is! YamlMap || y['deleted'] == true) continue;
      final tags = (y['tags'] is YamlList) ? (y['tags'] as YamlList).map((e) => '$e') : const <String>[];
      final ui = [
        if (y['ui_configs'] is YamlList) ...(y['ui_configs'] as YamlList),
        if (y['ui_config'] is YamlMap) y['ui_config'],
      ];
      final isInsight = tags.contains('insight') || ui.any((u) => u is YamlMap && u['template_id'] == 'insight_summary');
      if (isInsight) continue;
      final text = [y['title'], y['fact']].whereType<String>().where((s) => s.trim().isNotEmpty).join('\n').trim();
      if (text.length >= 20) notes.add(Note(text));
    } catch (_) {}
  }
  input.closeSync();
  return notes;
}

class RealTestPage extends StatefulWidget {
  const RealTestPage({super.key});
  @override
  State<RealTestPage> createState() => _RealTestPageState();
}

class _Cand {
  _Cand(this.note);
  final int note;
  bool relevant = false;
}

class _RealTestPageState extends State<RealTestPage> {
  int step = 0;
  String status = '';
  List<Note> notes = [];
  String model = 'e5_int8';
  Embedder? emb;
  final vecs = <Float32List>[];
  int indexMs = 0, loadMs = 0;
  final queriesCtl = TextEditingController();
  List<String> queries = [];
  final judged = <Map<String, dynamic>>[];
  int qi = 0;
  List<_Cand> cands = [];
  bool offTopic = false;
  List<int> curText = [];
  List<int> curEmb = [];
  List<double> curScores = [];
  final qMs = <int>[];
  Map<String, dynamic>? result;

  Future<void> pick() async {
    final r = await FilePicker.pickFiles();
    final path = r.isEmpty ? null : r.first.path;
    if (path == null) return;
    setState(() => status = 'Lendo o backup...');
    try {
      final n = await Future(() => notesFromBackup(path));
      setState(() {
        notes = n;
        status = '${n.length} notas com texto encontradas.';
      });
    } catch (e) {
      setState(() => status = 'Erro ao ler: $e');
    }
  }

  Future<void> index() async {
    final dir = (await getExternalStorageDirectory())!.path;
    final sw = Stopwatch()..start();
    setState(() => status = 'Carregando o modelo...');
    try {
      emb = await Embedder.load('$dir/$model.onnx', '$dir/tokenizer.json', e5: model.startsWith('e5'));
    } catch (e) {
      setState(() => status = 'Erro ao carregar o modelo: $e');
      return;
    }
    loadMs = sw.elapsedMilliseconds;
    sw.reset();
    vecs.clear();
    for (var i = 0; i < notes.length; i++) {
      vecs.add(await emb!.embed(notes[i].text, query: false));
      if (i % 20 == 0) setState(() => status = 'Indexando ${i + 1}/${notes.length}');
    }
    indexMs = sw.elapsedMilliseconds;
    setState(() {
      status = 'Indexadas ${notes.length} notas em ${indexMs ~/ 1000} s.';
      step = 1;
    });
  }

  List<String> parseQueries() => queriesCtl.text.split(RegExp(r'[\r\n]+')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  Future<void> startJudging() async {
    queries = parseQueries();
    if (queries.isEmpty) return;
    qi = 0;
    await prepare();
    setState(() => step = 2);
  }

  Future<void> prepare() async {
    final sw = Stopwatch()..start();
    final qv = await emb!.embed(queries[qi], query: true);
    final scores = [for (final v in vecs) dot(qv, v)];
    final order = List<int>.generate(notes.length, (i) => i)..sort((a, b) => scores[b].compareTo(scores[a]));
    qMs.add(sw.elapsedMilliseconds);
    curScores = scores;
    curEmb = order.take(10).toList();
    curText = textRank(queries[qi], notes);
    // Ordem fixa que não revela qual método achou a nota.
    final pool = <int>{...curEmb.take(5), ...curText.take(5)}.toList()
      ..sort((a, b) => (a * 7919 % 101).compareTo(b * 7919 % 101));
    cands = [for (final n in pool) _Cand(n)];
    offTopic = false;
  }

  Future<void> next() async {
    judged.add({
      'text3': curText.take(3).toList(),
      'emb3': curEmb.take(3).toList(),
      'textCount': curText.length,
      'top1': curScores[curEmb.first],
      'off': offTopic,
      'rel': [for (final c in cands) if (c.relevant) c.note],
    });
    if (qi + 1 < queries.length) {
      qi++;
      await prepare();
      setState(() {});
    } else {
      await finish();
    }
  }

  Future<void> finish() async {
    int hit(List<int> top, List rel) => top.any(rel.contains) ? 1 : 0;
    final on = judged.where((j) => j['off'] != true && (j['rel'] as List).isNotEmpty).toList();
    final off = judged.where((j) => j['off'] == true).toList();
    final noRel = judged.where((j) => j['off'] != true && (j['rel'] as List).isEmpty).length;
    double p3(String k) => on.isEmpty
        ? 0
        : on.map((j) => (j[k] as List).where((n) => (j['rel'] as List).contains(n)).length / 3).reduce((a, b) => a + b) / on.length;
    final hitText = on.fold<int>(0, (s, j) => s + hit((j['text3'] as List).cast<int>(), j['rel']));
    final hitEmb = on.fold<int>(0, (s, j) => s + hit((j['emb3'] as List).cast<int>(), j['rel']));
    final hitHybrid = on.fold<int>(0, (s, j) {
      final t = (j['text3'] as List).cast<int>();
      return s + hit(t.isNotEmpty ? t : (j['emb3'] as List).cast<int>(), j['rel']);
    });
    final offTop1 = off.map((j) => j['top1'] as double).toList()..sort();
    final onTop1 = on.map((j) => j['top1'] as double).toList()..sort();
    final maxOff = offTop1.isEmpty ? null : offTop1.last;
    final aboveCut = (maxOff == null || on.isEmpty) ? null : onTop1.where((s) => s > maxOff).length;
    final r = {
      'modelo': model,
      'notas': notes.length,
      'consultas': queries.length,
      'com_resposta': on.length,
      'fora_do_tema': off.length,
      'sem_relevante_marcada': noRel,
      'acerto3_texto': '$hitText/${on.length}',
      'acerto3_embedding': '$hitEmb/${on.length}',
      'acerto3_texto_depois_embedding': '$hitHybrid/${on.length}',
      'precisao3_texto': double.parse(p3('text3').toStringAsFixed(3)),
      'precisao3_embedding': double.parse(p3('emb3').toStringAsFixed(3)),
      'fora_do_tema_com_resultado_no_texto': off.where((j) => (j['textCount'] as int) > 0).length,
      'fora_do_tema_nota_maior': maxOff == null ? null : double.parse(maxOff.toStringAsFixed(3)),
      'com_resposta_acima_do_corte': aboveCut,
      'carregar_ms': loadMs,
      'indexar_ms_por_nota': notes.isEmpty ? 0 : double.parse((indexMs / notes.length).toStringAsFixed(1)),
      'consulta_ms_media': qMs.isEmpty ? 0 : qMs.reduce((a, b) => a + b) / qMs.length,
      'rss_pico_mb': (ProcessInfo.maxRss / 1e6).round(),
    };
    final dir = (await getExternalStorageDirectory())!.path;
    File('$dir/resultado_real_$model.json').writeAsStringSync(jsonEncode(r));
    debugPrint('F610 REAL ${jsonEncode(r)}');
    setState(() {
      result = r;
      step = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(step == 2 ? 'Consulta ${qi + 1}/${queries.length}' : 'Notas reais')),
      body: Padding(padding: const EdgeInsets.all(12), child: _body()),
    );
  }

  String _snippet(String t) {
    final one = t.replaceAll('\n', ' ');
    return one.length > 220 ? '${one.substring(0, 220)}…' : one;
  }

  Widget _body() {
    switch (step) {
      case 0:
        return ListView(children: [
          const Text('Os dados ficam só neste aparelho. Escolha um backup (.memex ou .zip) feito pelo app.'),
          const SizedBox(height: 8),
          FilledButton(onPressed: pick, child: const Text('Escolher backup')),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: model,
            items: const [
              DropdownMenuItem(value: 'e5_int8', child: Text('e5-small int8')),
              DropdownMenuItem(value: 'minilm_int8', child: Text('MiniLM int8')),
            ],
            onChanged: (v) => setState(() => model = v!),
          ),
          FilledButton(onPressed: notes.isEmpty ? null : index, child: const Text('Indexar as notas')),
          const SizedBox(height: 8),
          Text(status),
        ]);
      case 1:
        return ListView(children: [
          Text(status),
          const SizedBox(height: 8),
          const Text('Escreva de 10 a 20 perguntas ou buscas, uma por linha. Misture: com palavras que estão na nota, '
              'com outras palavras para a mesma ideia, e 3 ou 4 sobre o que você NÃO anotou.'),
          TextField(controller: queriesCtl, minLines: 8, maxLines: 14, onChanged: (_) => setState(() {})),
          const SizedBox(height: 8),
          Text('${parseQueries().length} consultas lidas (use de 10 a 20, uma por linha)'),
          FilledButton(onPressed: parseQueries().isEmpty ? null : startJudging, child: const Text('Começar a avaliar')),
        ]);
      case 2:
        return Column(children: [
          Text(queries[qi], style: Theme.of(context).textTheme.titleMedium),
          const Text('Marque as notas que ajudam a responder.', style: TextStyle(fontSize: 12)),
          Expanded(
            child: ListView(children: [
              for (final c in cands)
                CheckboxListTile(
                  value: c.relevant,
                  onChanged: offTopic ? null : (v) => setState(() => c.relevant = v!),
                  title: Text(_snippet(notes[c.note].text)),
                ),
            ]),
          ),
          SwitchListTile(
            value: offTopic,
            onChanged: (v) => setState(() {
              offTopic = v;
              if (v) {
                for (final c in cands) {
                  c.relevant = false;
                }
              }
            }),
            title: const Text('Fora do tema: não tenho nota sobre isso'),
          ),
          FilledButton(onPressed: next, child: Text(qi + 1 < queries.length ? 'Próxima' : 'Terminar')),
        ]);
      default:
        return ListView(children: [
          const Text('Resultado (só números, salvo no aparelho):'),
          SelectableText(const JsonEncoder.withIndent('  ').convert(result)),
        ]);
    }
  }
}
