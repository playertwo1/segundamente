import 'dart:convert';
import 'dart:io';

import 'package:memex/data/services/chat_session_storage.dart';
import 'package:memex/data/services/file_system_service.dart';
import 'package:memex/domain/models/session_report.dart';
import 'package:memex/domain/models/transcript_import.dart';
import 'package:memex/utils/logger.dart';
import 'package:path/path.dart' as p;

class SessionReportService {
  SessionReportService({
    FileSystemService? fileService,
    ChatSessionStorage? sessions,
  })  : _files = fileService ?? FileSystemService.instance,
        _sessions = sessions ?? ChatSessionStorage.instance;

  final FileSystemService _files;
  final ChatSessionStorage _sessions;
  final _logger = getLogger('SessionReportService');

  Future<SessionReport?> load({
    required String userId,
    required String sessionId,
  }) async {
    _checkId(sessionId);
    final file = _reportFile(userId, sessionId);
    if (!await file.exists()) return null;
    final raw = jsonDecode(await file.readAsString());
    if (raw is! Map) throw FormatException('report is not an object');
    final report = sessionReportFromStorage(raw.cast<String, dynamic>());
    if (report.schemaVersion != raw['schema_version']) {
      await _write(file, report);
    }
    return report;
  }

  Future<SessionReport> draft({
    required String userId,
    required String sessionId,
    required ReportKind kind,
    required String? customTitle,
  }) async {
    final existing = await load(userId: userId, sessionId: sessionId);
    if (existing != null && reportHasApprovedItem(existing)) {
      throw StateError('approved items keep this report');
    }
    final report = draftSessionReport(
      sessionId: sessionId,
      kind: kind,
      customTitle: customTitle,
      segments: await _segments(userId, sessionId),
    );
    await _write(_reportFile(userId, sessionId), report);
    _logger.info('Drafted session report $sessionId');
    return report;
  }

  Future<SessionReport> applyModelJson({
    required String userId,
    required String sessionId,
    required ReportKind kind,
    required String? customTitle,
    required Map<String, dynamic> json,
  }) async {
    final existing = await load(userId: userId, sessionId: sessionId);
    if (existing != null && reportHasApprovedItem(existing)) {
      throw StateError('approved items keep this report');
    }
    final report = sessionReportFromModelJson(
      sessionId: sessionId,
      kind: kind,
      customTitle: customTitle,
      segments: await _segments(userId, sessionId),
      json: json,
    );
    await _write(_reportFile(userId, sessionId), report);
    return report;
  }

  Future<SessionReport> editItem({
    required String userId,
    required String sessionId,
    required String itemId,
    required String text,
    required String assignee,
    required String due,
  }) async {
    final current = await _required(userId, sessionId);
    final next = editReportItem(
      current,
      itemId: itemId,
      text: text,
      assignee: assignee,
      due: due,
    );
    await _write(_reportFile(userId, sessionId), next);
    return next;
  }

  Future<SessionReport> setStatus({
    required String userId,
    required String sessionId,
    required String itemId,
    required ReportItemStatus status,
  }) async {
    final current = await _required(userId, sessionId);
    final next = setReportItemStatus(
      current,
      itemId: itemId,
      status: status,
    );
    await _write(_reportFile(userId, sessionId), next);
    return next;
  }

  Future<void> deleteDerivatives({
    required String userId,
    required String sessionId,
  }) async {
    _checkId(sessionId);
    final dir = Directory(
      p.join(_files.getSessionReportsPath(userId), sessionId),
    );
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  File _reportFile(String userId, String sessionId) {
    return File(
      p.join(
        _files.getSessionReportsPath(userId),
        sessionId,
        'report.json',
      ),
    );
  }

  Future<SessionReport> _required(String userId, String sessionId) async {
    final current = await load(userId: userId, sessionId: sessionId);
    if (current == null) throw StateError('report missing');
    return current;
  }

  Future<void> _write(File file, SessionReport report) async {
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(sessionReportToJson(report)),
      flush: true,
    );
  }

  Future<List<ReportSegment>> _segments(String userId, String sessionId) async {
    _checkId(sessionId);
    final imported = await _importedSegments(userId, sessionId);
    if (imported.isNotEmpty) return imported;
    final text = await _chatText(userId, sessionId);
    if (text.trim().isEmpty) throw StateError('nothing to report');
    return [
      ReportSegment(id: 'seg_0', text: text.trim()),
    ];
  }

  Future<List<ReportSegment>> _importedSegments(
    String userId,
    String sessionId,
  ) async {
    final root = Directory(
      p.join(_files.getTranscriptImportsPath(userId), sessionId),
    );
    if (!await root.exists()) return const [];
    final dirs = <Directory>[];
    await for (final entity in root.list()) {
      if (entity is Directory) dirs.add(entity);
    }
    dirs.sort((a, b) {
      final aIndex = int.tryParse(p.basename(a.path)) ?? 0;
      final bIndex = int.tryParse(p.basename(b.path)) ?? 0;
      return aIndex.compareTo(bIndex);
    });
    final segments = <ReportSegment>[];
    for (final dir in dirs) {
      final file = File(p.join(dir.path, 'original.bin'));
      if (!await file.exists()) continue;
      final parsed = TranscriptImport.parse(await file.readAsBytes());
      if (parsed.kind != TranscriptKind.text) continue;
      for (final segment in parsed.segments) {
        if (segment.text.trim().isEmpty) continue;
        segments.add(
          ReportSegment(
            id: 'seg_${segments.length}',
            text: segment.text,
            clock: segment.clock,
          ),
        );
      }
    }
    return segments;
  }

  Future<String> _chatText(String userId, String sessionId) async {
    final messages = await _sessions.loadMessages(userId, sessionId);
    final buffer = StringBuffer();
    for (final message in messages) {
      if (message['role'] != 'user') continue;
      final content = message['content'];
      if (content is! List) continue;
      for (final block in content) {
        if (block is Map && block['type'] == 'text') {
          buffer.writeln(block['text']);
        }
      }
    }
    return buffer.toString();
  }
}

void _checkId(String sessionId) {
  if (sessionId.isEmpty ||
      sessionId.contains('/') ||
      sessionId.contains('\\') ||
      sessionId == '.' ||
      sessionId == '..') {
    throw ArgumentError.value(sessionId, 'sessionId', 'invalid session id');
  }
}
