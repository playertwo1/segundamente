import 'dart:convert';
import 'dart:io';

import 'package:memex/data/services/file_system_service.dart';
import 'package:memex/domain/models/glossary.dart';
import 'package:path/path.dart' as p;

/// The glossary lives in one local file in the user's workspace.
class GlossaryService {
  GlossaryService({FileSystemService? fileService})
      : _files = fileService ?? FileSystemService.instance;

  final FileSystemService _files;

  Future<List<String>> load(String userId) async {
    final file = _file(userId);
    if (!await file.exists()) return const [];
    final raw = jsonDecode(await file.readAsString());
    if (raw is! Map) throw const FormatException('glossary is not an object');
    return glossaryFromJson(raw.cast<String, dynamic>());
  }

  Future<List<String>> update(
    String userId,
    List<String> Function(List<String>) change,
  ) async {
    final next = change(await load(userId));
    final file = _file(userId);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(glossaryToJson(next)),
      flush: true,
    );
    return next;
  }

  File _file(String userId) =>
      File(p.join(_files.getWorkspacePath(userId), 'glossary.json'));
}
