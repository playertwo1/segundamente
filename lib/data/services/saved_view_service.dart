import 'dart:convert';
import 'dart:io';

import 'package:memex/data/services/file_system_service.dart';
import 'package:memex/domain/models/saved_view.dart';
import 'package:path/path.dart' as p;

/// Saved timeline views live in one local file in the user's workspace.
class SavedViewService {
  SavedViewService({FileSystemService? fileService})
      : _files = fileService ?? FileSystemService.instance;

  final FileSystemService _files;

  Future<List<SavedView>> load(String userId) async {
    final file = _file(userId);
    if (!await file.exists()) return const [];
    final raw = jsonDecode(await file.readAsString());
    if (raw is! Map) throw const FormatException('views is not an object');
    return savedViewsFromJson(raw.cast<String, dynamic>());
  }

  Future<List<SavedView>> update(
    String userId,
    List<SavedView> Function(List<SavedView>) change,
  ) async {
    final next = change(await load(userId));
    final file = _file(userId);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(savedViewsToJson(next)),
      flush: true,
    );
    return next;
  }

  File _file(String userId) =>
      File(p.join(_files.getWorkspacePath(userId), 'saved_views.json'));
}
