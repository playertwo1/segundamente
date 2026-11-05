import 'dart:convert';

const sessionReportSchemaVersion = 1;

const reportAssigneeUnknown = 'não identificado';
const reportDueUnknown = 'não informado';

enum ReportKind { livre, reuniao, brainstorm, diario, estudo, custom }

enum ReportItemKind {
  summary,
  idea,
  opportunity,
  decision,
  task,
  followUp,
  question,
}

enum ReportItemStatus { unconfirmed, approved, discarded }

class ReportSegment {
  const ReportSegment({
    required this.id,
    required this.text,
    this.clock,
  });

  final String id;
  final String text;
  final String? clock;
}

class ReportSource {
  const ReportSource({
    required this.segmentId,
    required this.excerpt,
    this.clock,
  });

  final String segmentId;
  final String excerpt;
  final String? clock;
}

class ReportItem {
  const ReportItem({
    required this.id,
    required this.kind,
    required this.text,
    required this.status,
    required this.assignee,
    required this.due,
    required this.source,
  });

  final String id;
  final ReportItemKind kind;
  final String text;
  final ReportItemStatus status;
  final String assignee;
  final String due;
  final ReportSource source;

  ReportItem copyWith({
    String? text,
    ReportItemStatus? status,
    String? assignee,
    String? due,
  }) {
    return ReportItem(
      id: id,
      kind: kind,
      text: text ?? this.text,
      status: status ?? this.status,
      assignee: assignee ?? this.assignee,
      due: due ?? this.due,
      source: source,
    );
  }
}

class SessionReport {
  const SessionReport({
    required this.schemaVersion,
    required this.sessionId,
    required this.kind,
    required this.title,
    required this.sections,
    required this.items,
    this.customTitle,
  });

  final int schemaVersion;
  final String sessionId;
  final ReportKind kind;
  final String title;
  final String? customTitle;
  final List<ReportItemKind> sections;
  final List<ReportItem> items;

  SessionReport copyWith({List<ReportItem>? items}) {
    return SessionReport(
      schemaVersion: schemaVersion,
      sessionId: sessionId,
      kind: kind,
      title: title,
      customTitle: customTitle,
      sections: sections,
      items: items ?? this.items,
    );
  }
}

bool isDefinitiveTask(ReportItem item) {
  return item.kind == ReportItemKind.task &&
      item.status == ReportItemStatus.approved;
}

List<ReportItemKind> sectionsFor(ReportKind kind) {
  switch (kind) {
    case ReportKind.livre:
    case ReportKind.custom:
      return ReportItemKind.values;
    case ReportKind.reuniao:
      return const [
        ReportItemKind.summary,
        ReportItemKind.decision,
        ReportItemKind.task,
        ReportItemKind.followUp,
      ];
    case ReportKind.brainstorm:
      return const [
        ReportItemKind.summary,
        ReportItemKind.idea,
        ReportItemKind.opportunity,
      ];
    case ReportKind.diario:
      return const [
        ReportItemKind.summary,
        ReportItemKind.idea,
        ReportItemKind.question,
      ];
    case ReportKind.estudo:
      return const [
        ReportItemKind.summary,
        ReportItemKind.question,
        ReportItemKind.idea,
      ];
  }
}

String titleFor(ReportKind kind, String? customTitle) {
  switch (kind) {
    case ReportKind.livre:
      return 'Relatório livre';
    case ReportKind.reuniao:
      return 'Relatório de reunião';
    case ReportKind.brainstorm:
      return 'Relatório de brainstorm';
    case ReportKind.diario:
      return 'Relatório de diário';
    case ReportKind.estudo:
      return 'Relatório de estudo';
    case ReportKind.custom:
      final name = customTitle?.trim() ?? '';
      if (name.isEmpty) {
        throw ArgumentError.value(customTitle, 'customTitle', 'empty');
      }
      return name;
  }
}

SessionReport draftSessionReport({
  required String sessionId,
  required ReportKind kind,
  required String? customTitle,
  required List<ReportSegment> segments,
}) {
  final usable = segments.where((segment) => segment.text.trim().isNotEmpty);
  final source = usable.toList(growable: false);
  if (source.isEmpty) {
    throw StateError('nothing to report');
  }
  final sections = sectionsFor(kind);
  final items = <ReportItem>[
    _item(
      id: 'item_1',
      kind: ReportItemKind.summary,
      segment: source.first,
    ),
  ];
  if (source.length > 1) {
    items.add(
      _item(
        id: 'item_2',
        kind: _bodyKind(kind),
        segment: source[1],
      ),
    );
  }
  for (final item in items) {
    if (!sections.contains(item.kind)) {
      throw StateError('section missing for ${item.kind.name}');
    }
  }
  return SessionReport(
    schemaVersion: sessionReportSchemaVersion,
    sessionId: sessionId,
    kind: kind,
    title: titleFor(kind, customTitle),
    customTitle: kind == ReportKind.custom ? customTitle!.trim() : null,
    sections: sections,
    items: items,
  );
}

/// A model reply may suggest a person, a date, or a confirmed status.
/// Those fields are discarded. The stored item stays unconfirmed, with the
/// fixed literals for an absent assignee and due date.
SessionReport sessionReportFromModelJson({
  required String sessionId,
  required ReportKind kind,
  required String? customTitle,
  required List<ReportSegment> segments,
  required Map<String, dynamic> json,
}) {
  final migrated = _migrate(json);
  final rawItems = migrated['items'];
  if (rawItems is! List) {
    throw FormatException('items missing');
  }
  final byId = {for (final segment in segments) segment.id: segment};
  final sections = sectionsFor(kind);
  final items = <ReportItem>[];
  final seen = <String>{};
  for (var i = 0; i < rawItems.length; i++) {
    final raw = rawItems[i];
    if (raw is! Map) throw FormatException('item $i is not an object');
    final map = raw.cast<String, dynamic>();
    final itemKind = _itemKind(map['kind']);
    if (!sections.contains(itemKind)) {
      throw FormatException('${itemKind.name} is outside $kind');
    }
    final text = _requiredText(map['text']);
    final segmentId = _requiredText(map['segment_id']);
    final segment = byId[segmentId];
    if (segment == null) {
      throw FormatException('unknown segment $segmentId');
    }
    final excerpt = _requiredText(map['excerpt']);
    if (!segment.text.contains(excerpt)) {
      throw FormatException('excerpt is not in $segmentId');
    }
    final clock = map['clock']?.toString();
    if (clock != null && clock.isNotEmpty && clock != segment.clock) {
      throw FormatException('clock does not match $segmentId');
    }
    final finalKind = _kindAfterTaskGuard(itemKind, '$text $excerpt');
    if (!sections.contains(finalKind)) continue;
    final duplicate = '${_normalizedKey(text)}|${finalKind.name}';
    final sameSource =
        '$segmentId|${_normalizedKey(excerpt)}|${finalKind.name}';
    if (!seen.add(duplicate) || !seen.add(sameSource)) continue;
    items.add(
      ReportItem(
        id: 'item_${items.length + 1}',
        kind: finalKind,
        text: text,
        status: ReportItemStatus.unconfirmed,
        assignee: reportAssigneeUnknown,
        due: reportDueUnknown,
        source: ReportSource(
          segmentId: segmentId,
          excerpt: excerpt,
          clock: segment.clock,
        ),
      ),
    );
  }
  if (items.isEmpty) throw FormatException('items empty');
  return SessionReport(
    schemaVersion: sessionReportSchemaVersion,
    sessionId: sessionId,
    kind: kind,
    title: titleFor(kind, customTitle),
    customTitle: kind == ReportKind.custom ? customTitle!.trim() : null,
    sections: sections,
    items: items,
  );
}

const _letterBefore = r'(?<![\p{L}])';
const _letterAfter = r'(?![\p{L}])';

// shortcut: pt-BR cue words only. A task phrased without any of them still
// reaches the user's review; widen the lists when a real sample needs it.
final _pastFact = RegExp(
  '$_letterBefore(?:ontem|anteontem|semana passada|mês passado|'
  'já (?:fiz|fez|enviei|mandei|resolvi|terminei|concluí|foi|foram)|'
  'foi (?:enviad|feit|conclu|resolvid|entregue)\\p{L}*|'
  'fiz|enviei|mandei|terminei|resolvi|combinamos|fomos)$_letterAfter',
  caseSensitive: false,
  unicode: true,
);
final _opinion = RegExp(
  '$_letterBefore(?:acho que|eu acho|na minha opinião|talvez|quem sabe|'
  'seria (?:bom|legal|interessante|melhor)|parece que|gosto d[eoa]|'
  'não gosto)$_letterAfter',
  caseSensitive: false,
  unicode: true,
);
final _obligation = RegExp(
  '$_letterBefore(?:preciso|precisa|precisamos|dev[eoi]|devemos|vai|vamos|'
  'tem que|temos que|fica responsável|lembrar de|não esquecer|até|amanhã|'
  'próxim[oa]|enviar|mandar|ligar|marcar|agendar)$_letterAfter',
  caseSensitive: false,
  unicode: true,
);

/// A task that is only a past fact or an opinion is not a commitment: it
/// becomes a summary or an idea, and an explicit obligation keeps it a task.
ReportItemKind _kindAfterTaskGuard(ReportItemKind kind, String evidence) {
  if (kind != ReportItemKind.task || _obligation.hasMatch(evidence)) {
    return kind;
  }
  if (_pastFact.hasMatch(evidence)) return ReportItemKind.summary;
  if (_opinion.hasMatch(evidence)) return ReportItemKind.idea;
  return kind;
}

String _normalizedKey(String value) {
  const from = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const to = 'aaaaaeeeeiiiiooooouuuuc';
  final buffer = StringBuffer();
  for (final rune in value.toLowerCase().runes) {
    final ch = String.fromCharCode(rune);
    final at = from.indexOf(ch);
    buffer.write(at >= 0 ? to[at] : ch);
  }
  return buffer.toString().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}

// shortcut: sends the whole text in one request, no chunking; split by time
// when a real 50 min transcript exceeds the model context.
const reportModelInputLimit = 60000;

String reportExtractionSystemPrompt(ReportKind kind) {
  final kinds = sectionsFor(kind).map((k) => k.name).join(', ');
  return 'You organize a transcript into report items. Reply with ONLY a '
      'JSON object {"items":[{"kind","text","segment_id","excerpt"}]}. '
      'kind is one of: $kinds. '
      'text is a short statement in the transcript language. '
      'segment_id is copied from the segment label. '
      'excerpt is an exact, verbatim substring of that segment. '
      'Never invent facts, people or dates. Do not output assignees, '
      'due dates or status. Use summary for the main point and decision, '
      'task, followUp, idea, opportunity or question only when the '
      'transcript clearly says so. A task is a future commitment someone '
      'accepts or is asked to do. Narration, opinions, hypotheses and facts '
      'already done are never tasks. Emit each item once; do not repeat an '
      'item with different words. When the transcript is in Portuguese, '
      'write every text in Brazilian Portuguese, keep names, numbers, '
      'amounts and dates exactly as spoken, never translate or correct the '
      'speaker, and keep each summary to at most two sentences. Notes the '
      'user typed are source text: quote them in excerpt, never rewrite '
      'them. Skip anything unclear.';
}

String reportExtractionUserPrompt(List<ReportSegment> segments) {
  final buffer = StringBuffer();
  for (final segment in segments) {
    final clock = segment.clock == null ? '' : ' ${segment.clock}';
    buffer.writeln('[${segment.id}$clock] ${segment.text}');
  }
  if (buffer.length > reportModelInputLimit) {
    throw FormatException('transcript too long for one request');
  }
  return buffer.toString();
}

/// Models often wrap JSON in a Markdown fence; accept that and nothing else.
Map<String, dynamic> reportModelReplyJson(String reply) {
  var text = reply.trim();
  final fence = RegExp(r'^```[a-zA-Z]*\s*([\s\S]*?)\s*```$').firstMatch(text);
  if (fence != null) text = fence.group(1)!;
  final decoded = jsonDecode(text);
  if (decoded is! Map) throw FormatException('reply is not an object');
  // The schema version is ours, not the model's to state.
  return {
    ...decoded.cast<String, dynamic>(),
    'schema_version': sessionReportSchemaVersion
  };
}

SessionReport sessionReportFromStorage(Map<String, dynamic> json) {
  final migrated = _migrate(json);
  final version = migrated['schema_version'];
  if (version != sessionReportSchemaVersion) {
    throw FormatException('unsupported report schema $version');
  }
  final sessionId = _requiredText(migrated['session_id']);
  final kind = _reportKind(migrated['kind']);
  final title = _requiredText(migrated['title']);
  final custom = migrated['custom_title']?.toString();
  final sections = _sections(migrated['sections']);
  final rawItems = migrated['items'];
  if (rawItems is! List || rawItems.isEmpty) {
    throw FormatException('items missing');
  }
  final items = <ReportItem>[];
  for (final raw in rawItems) {
    if (raw is! Map) throw FormatException('item is not an object');
    final map = raw.cast<String, dynamic>();
    final itemKind = _itemKind(map['kind']);
    if (!sections.contains(itemKind)) {
      throw FormatException('${itemKind.name} is outside the report');
    }
    final source = map['source'];
    if (source is! Map) throw FormatException('source missing');
    final sourceMap = source.cast<String, dynamic>();
    items.add(
      ReportItem(
        id: _requiredText(map['id']),
        kind: itemKind,
        text: _requiredText(map['text']),
        status: _status(map['status']),
        assignee: _person(map['assignee']),
        due: _due(map['due']),
        source: ReportSource(
          segmentId: _requiredText(sourceMap['segment_id']),
          excerpt: _requiredText(sourceMap['excerpt']),
          clock: sourceMap['clock']?.toString(),
        ),
      ),
    );
  }
  return SessionReport(
    schemaVersion: sessionReportSchemaVersion,
    sessionId: sessionId,
    kind: kind,
    title: title,
    customTitle: custom,
    sections: sections,
    items: items,
  );
}

Map<String, dynamic> sessionReportToJson(SessionReport report) {
  return {
    'schema_version': report.schemaVersion,
    'session_id': report.sessionId,
    'kind': report.kind.name,
    'title': report.title,
    'custom_title': report.customTitle,
    'sections': report.sections.map((section) => section.name).toList(),
    'items': [
      for (final item in report.items)
        {
          'id': item.id,
          'kind': item.kind.name,
          'text': item.text,
          'status': item.status.name,
          'assignee': item.assignee,
          'due': item.due,
          'source': {
            'segment_id': item.source.segmentId,
            'excerpt': item.source.excerpt,
            'clock': item.source.clock,
          },
        },
    ],
  };
}

SessionReport editReportItem(
  SessionReport report, {
  required String itemId,
  required String text,
  required String assignee,
  required String due,
}) {
  final nextText = text.trim();
  if (nextText.isEmpty) throw ArgumentError.value(text, 'text', 'empty');
  final nextAssignee =
      assignee.trim().isEmpty ? reportAssigneeUnknown : assignee.trim();
  final nextDue = due.trim().isEmpty ? reportDueUnknown : due.trim();
  var found = false;
  final items = [
    for (final item in report.items)
      if (item.id == itemId)
        () {
          found = true;
          return item.copyWith(
            text: nextText,
            assignee: nextAssignee,
            due: nextDue,
          );
        }()
      else
        item,
  ];
  if (!found) throw StateError('item missing');
  return report.copyWith(items: items);
}

SessionReport setReportItemStatus(
  SessionReport report, {
  required String itemId,
  required ReportItemStatus status,
}) {
  var found = false;
  final items = [
    for (final item in report.items)
      if (item.id == itemId)
        () {
          found = true;
          return item.copyWith(status: status);
        }()
      else
        item,
  ];
  if (!found) throw StateError('item missing');
  return report.copyWith(items: items);
}

List<ReportItem> searchSessionReport(SessionReport report, String query) {
  final active = report.items
      .where((item) => item.status != ReportItemStatus.discarded)
      .toList(growable: false);
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return active;
  if (report.title.toLowerCase().contains(needle)) return active;
  return active
      .where(
        (item) =>
            item.text.toLowerCase().contains(needle) ||
            item.source.excerpt.toLowerCase().contains(needle),
      )
      .toList(growable: false);
}

bool reportHasApprovedItem(SessionReport report) {
  return report.items.any(
    (item) => item.status == ReportItemStatus.approved,
  );
}

ReportItem _item({
  required String id,
  required ReportItemKind kind,
  required ReportSegment segment,
}) {
  final text = segment.text.trim();
  return ReportItem(
    id: id,
    kind: kind,
    text: text,
    status: ReportItemStatus.unconfirmed,
    assignee: reportAssigneeUnknown,
    due: reportDueUnknown,
    source: ReportSource(
      segmentId: segment.id,
      excerpt: text,
      clock: segment.clock,
    ),
  );
}

ReportItemKind _bodyKind(ReportKind kind) {
  switch (kind) {
    case ReportKind.estudo:
      return ReportItemKind.question;
    case ReportKind.reuniao:
      return ReportItemKind.followUp;
    case ReportKind.brainstorm:
      return ReportItemKind.opportunity;
    case ReportKind.livre:
    case ReportKind.diario:
    case ReportKind.custom:
      return ReportItemKind.idea;
  }
}

Map<String, dynamic> _migrate(Map<String, dynamic> json) {
  final version = json['schema_version'];
  if (version == sessionReportSchemaVersion && json['items'] is List) {
    return json;
  }
  if (version != null && version != 0) {
    throw FormatException('unsupported report schema $version');
  }
  final entries = json['entries'];
  if (entries is! List) {
    throw FormatException('unsupported report schema $version');
  }
  final legacyKind = json['type']?.toString();
  return {
    'schema_version': sessionReportSchemaVersion,
    'session_id': json['session_id'],
    'kind': _legacyKind(legacyKind).name,
    'title':
        titleFor(_legacyKind(legacyKind), json['custom_title']?.toString()),
    'custom_title': json['custom_title'],
    'sections':
        sectionsFor(_legacyKind(legacyKind)).map((s) => s.name).toList(),
    'items': [
      for (var i = 0; i < entries.length; i++)
        if (entries[i] is Map)
          {
            'id': 'item_${i + 1}',
            'kind': _legacyItemKind(
              (entries[i] as Map)['type']?.toString(),
            ).name,
            'text': (entries[i] as Map)['body'],
            'status': ReportItemStatus.unconfirmed.name,
            'assignee': reportAssigneeUnknown,
            'due': reportDueUnknown,
            'source': {
              'segment_id': (entries[i] as Map)['segment_id'],
              'excerpt': (entries[i] as Map)['quote'],
              'clock': (entries[i] as Map)['clock'],
            },
          }
        else
          throw FormatException('legacy entry is not an object'),
    ],
  };
}

String _requiredText(Object? value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) throw FormatException('empty text');
  return text;
}

String _person(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? reportAssigneeUnknown : text;
}

String _due(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? reportDueUnknown : text;
}

ReportKind _reportKind(Object? value) {
  final name = value?.toString();
  for (final kind in ReportKind.values) {
    if (kind.name == name) return kind;
  }
  throw FormatException('unknown report kind $name');
}

ReportItemKind _itemKind(Object? value) {
  final name = value?.toString();
  for (final kind in ReportItemKind.values) {
    if (kind.name == name) return kind;
  }
  throw FormatException('unknown item kind $name');
}

ReportItemStatus _status(Object? value) {
  final name = value?.toString();
  for (final status in ReportItemStatus.values) {
    if (status.name == name) return status;
  }
  throw FormatException('unknown status $name');
}

List<ReportItemKind> _sections(Object? value) {
  if (value is! List || value.isEmpty) {
    throw FormatException('sections missing');
  }
  return [for (final name in value) _itemKind(name)];
}

ReportKind _legacyKind(String? type) {
  switch (type) {
    case 'free':
      return ReportKind.livre;
    case 'meeting':
      return ReportKind.reuniao;
    case 'brainstorm':
      return ReportKind.brainstorm;
    case 'journal':
      return ReportKind.diario;
    case 'study':
      return ReportKind.estudo;
    case 'custom':
      return ReportKind.custom;
    default:
      throw FormatException('unknown legacy kind $type');
  }
}

ReportItemKind _legacyItemKind(String? type) {
  switch (type) {
    case 'summary':
      return ReportItemKind.summary;
    case 'idea':
      return ReportItemKind.idea;
    case 'opportunity':
      return ReportItemKind.opportunity;
    case 'decision':
      return ReportItemKind.decision;
    case 'task':
      return ReportItemKind.task;
    case 'follow_up':
      return ReportItemKind.followUp;
    case 'question':
      return ReportItemKind.question;
    default:
      throw FormatException('unknown legacy item $type');
  }
}
