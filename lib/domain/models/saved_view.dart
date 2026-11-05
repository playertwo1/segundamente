import 'package:memex/domain/models/topic.dart';

const savedViewSchemaVersion = 1;

/// A named timeline filter kept on the device: cards must carry every tag.
class SavedView {
  const SavedView({required this.id, required this.name, required this.tags});

  final String id;
  final String name;
  final List<String> tags;
}

bool _nameTaken(List<SavedView> views, String name, String exceptId) {
  final key = nameKey(name);
  return views.any((v) => v.id != exceptId && nameKey(v.name) == key);
}

/// Adds a view. A blank or repeated name, or no tag, leaves the list as is.
List<SavedView> addSavedView(
  List<SavedView> views, {
  required String id,
  required String name,
  required List<String> tags,
}) {
  final clean = name.trim();
  final picked = {for (final t in tags) t.trim()}..remove('');
  if (clean.isEmpty || picked.isEmpty || _nameTaken(views, clean, id)) {
    return views;
  }
  return [
    ...views,
    SavedView(id: id, name: clean, tags: picked.toList()),
  ];
}

List<SavedView> renameSavedView(
  List<SavedView> views,
  String id,
  String name,
) {
  final clean = name.trim();
  if (clean.isEmpty || _nameTaken(views, clean, id)) return views;
  return [
    for (final v in views)
      v.id == id ? SavedView(id: v.id, name: clean, tags: v.tags) : v,
  ];
}

List<SavedView> removeSavedView(List<SavedView> views, String id) => [
      for (final v in views)
        if (v.id != id) v
    ];

Map<String, dynamic> savedViewsToJson(List<SavedView> views) => {
      'schema_version': savedViewSchemaVersion,
      'views': [
        for (final v in views) {'id': v.id, 'name': v.name, 'tags': v.tags},
      ],
    };

List<SavedView> savedViewsFromJson(Map<String, dynamic> json) {
  if (json['schema_version'] != savedViewSchemaVersion) {
    throw const FormatException('saved view schema');
  }
  final raw = json['views'];
  if (raw is! List) throw const FormatException('saved view list');
  return [
    for (final row in raw)
      if (row is Map)
        SavedView(
          id: row['id'] as String,
          name: row['name'] as String,
          tags: [for (final t in row['tags'] as List) t as String],
        )
      else
        throw const FormatException('saved view row'),
  ];
}
