const topicSchemaVersion = 1;

/// A topic or project that groups sessions. It is its own entity: a report
/// section (task, idea, ...) is never a topic.
class Topic {
  const Topic({
    required this.id,
    required this.name,
    required this.isProject,
    this.sessionIds = const [],
  });

  final String id;
  final String name;
  final bool isProject;
  final List<String> sessionIds;

  Topic copyWith({String? name, List<String>? sessionIds}) => Topic(
        id: id,
        name: name ?? this.name,
        isProject: isProject,
        sessionIds: sessionIds ?? this.sessionIds,
      );
}

/// Adds a topic. A blank name, or one already used (ignoring case and
/// accents), leaves the list unchanged.
List<Topic> addTopic(
  List<Topic> topics, {
  required String id,
  required String name,
  bool isProject = false,
}) {
  final clean = name.trim();
  if (clean.isEmpty || _nameTaken(topics, clean, exceptId: id)) return topics;
  return [...topics, Topic(id: id, name: clean, isProject: isProject)];
}

List<Topic> renameTopic(List<Topic> topics, String id, String name) {
  final clean = name.trim();
  if (clean.isEmpty || _nameTaken(topics, clean, exceptId: id)) return topics;
  return [
    for (final topic in topics)
      topic.id == id ? topic.copyWith(name: clean) : topic,
  ];
}

List<Topic> removeTopic(List<Topic> topics, String id) => [
      for (final topic in topics)
        if (topic.id != id) topic
    ];

List<Topic> linkSession(List<Topic> topics, String id, String sessionId) => [
      for (final topic in topics)
        topic.id == id && !topic.sessionIds.contains(sessionId)
            ? topic.copyWith(sessionIds: [...topic.sessionIds, sessionId])
            : topic,
    ];

List<Topic> unlinkSession(List<Topic> topics, String id, String sessionId) => [
      for (final topic in topics)
        topic.id == id
            ? topic.copyWith(
                sessionIds: [
                  for (final s in topic.sessionIds)
                    if (s != sessionId) s,
                ],
              )
            : topic,
    ];

/// Drops a deleted session from every topic.
List<Topic> forgetSession(List<Topic> topics, String sessionId) => [
      for (final topic in topics)
        topic.sessionIds.contains(sessionId)
            ? topic.copyWith(
                sessionIds: [
                  for (final s in topic.sessionIds)
                    if (s != sessionId) s,
                ],
              )
            : topic,
    ];

bool _nameTaken(List<Topic> topics, String name, {required String exceptId}) {
  final key = _key(name);
  return topics.any((t) => t.id != exceptId && _key(t.name) == key);
}

const _accents = {
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ã': 'a',
  'é': 'e',
  'ê': 'e',
  'í': 'i',
  'ó': 'o',
  'ô': 'o',
  'õ': 'o',
  'ú': 'u',
  'ç': 'c',
};

String _key(String text) {
  final lower = text.trim().toLowerCase();
  return [
    for (final r in lower.runes)
      _accents[String.fromCharCode(r)] ?? String.fromCharCode(r)
  ].join();
}

Map<String, dynamic> topicsToJson(List<Topic> topics) => {
      'schema_version': topicSchemaVersion,
      'topics': [
        for (final t in topics)
          {
            'id': t.id,
            'name': t.name,
            'is_project': t.isProject,
            'session_ids': t.sessionIds,
          },
      ],
    };

List<Topic> topicsFromJson(Map<String, dynamic> json) {
  if (json['schema_version'] != topicSchemaVersion) {
    throw const FormatException('topic schema');
  }
  final raw = json['topics'];
  if (raw is! List) throw const FormatException('topic list');
  return [
    for (final row in raw)
      if (row is Map)
        Topic(
          id: row['id'] as String,
          name: row['name'] as String,
          isProject: row['is_project'] as bool? ?? false,
          sessionIds: [
            for (final s in (row['session_ids'] as List? ?? const []))
              s as String,
          ],
        )
      else
        throw const FormatException('topic row'),
  ];
}
