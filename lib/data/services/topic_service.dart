import 'dart:convert';
import 'dart:io';

import 'package:memex/data/services/file_system_service.dart';
import 'package:memex/domain/models/topic.dart';
import 'package:path/path.dart' as p;

/// Topics and projects live in one local file next to the session reports.
/// Session ids are checked against the stored sessions by the caller.
class TopicService {
  TopicService({FileSystemService? fileService})
      : _files = fileService ?? FileSystemService.instance;

  final FileSystemService _files;

  Future<List<Topic>> load(String userId) async {
    final file = _file(userId);
    if (!await file.exists()) return const [];
    final raw = jsonDecode(await file.readAsString());
    if (raw is! Map) throw const FormatException('topics is not an object');
    return topicsFromJson(raw.cast<String, dynamic>());
  }

  Future<List<Topic>> update(
    String userId,
    List<Topic> Function(List<Topic>) change,
  ) async {
    final next = change(await load(userId));
    final file = _file(userId);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(topicsToJson(next)),
      flush: true,
    );
    return next;
  }

  File _file(String userId) =>
      File(p.join(_files.getSessionReportsPath(userId), 'topics.json'));
}
