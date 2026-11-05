import 'dart:convert';
import 'dart:io';

import 'package:memex/data/services/chat_session_storage.dart';
import 'package:memex/data/services/file_system_service.dart';
import 'package:memex/data/services/glossary_service.dart';
import 'package:memex/data/services/transcript_correction_service.dart';
import 'package:memex/domain/models/report_memory.dart';
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
  final _glossary = GlossaryService();
  final _logger = getLogger('SessionReportService');

  Future<SessionReport?> load({
    required String userId,
    required String sessionId,
  }) async {
    checkSessionId(sessionId);
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
    await _archivePrevious(userId, sessionId);
    await _write(_reportFile(userId, sessionId), report);
    _logger.info('Drafted session report $sessionId');
    return report;
  }

  /// Asks the model for the items; if it fails or answers something the
  /// report validation refuses, falls back to the local draft and says so.
  Future<({SessionReport report, Object? modelError})> draftWithModel({
    required String userId,
    required String sessionId,
    required ReportKind kind,
    required String? customTitle,
    required Future<String> Function(String system, String user) ask,
  }) async {
    try {
      final reply = await ask(
        reportExtractionSystemPrompt(
          kind,
          glossary: await _glossary.load(userId),
        ),
        reportExtractionUserPrompt(await _segments(userId, sessionId)),
      );
      final report = await applyModelJson(
        userId: userId,
        sessionId: sessionId,
        kind: kind,
        customTitle: customTitle,
        json: reportModelReplyJson(reply),
      );
      return (report: report, modelError: null);
    } on StateError {
      rethrow; // approved items or nothing to report: not a model failure
    } catch (error) {
      _logger.warning('Model report failed, using local draft: $error');
      final report = await draft(
        userId: userId,
        sessionId: sessionId,
        kind: kind,
        customTitle: customTitle,
      );
      return (report: report, modelError: error);
    }
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
    await _archivePrevious(userId, sessionId);
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
    String? at,
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
    await _appendRevisions(
      userId: userId,
      sessionId: sessionId,
      before: current,
      after: next,
      at: at ?? DateTime.now().toIso8601String(),
    );
    return next;
  }

  Future<SessionReport> setStatus({
    required String userId,
    required String sessionId,
    required String itemId,
    required ReportItemStatus status,
    String? at,
  }) async {
    final current = await _required(userId, sessionId);
    final next = setReportItemStatus(
      current,
      itemId: itemId,
      status: status,
    );
    await _write(_reportFile(userId, sessionId), next);
    await _appendRevisions(
      userId: userId,
      sessionId: sessionId,
      before: current,
      after: next,
      at: at ?? DateTime.now().toIso8601String(),
    );
    return next;
  }

  Future<List<ReportHit>> search({
    required String userId,
    required String query,
  }) async {
    return searchReports(await loadAll(userId), query);
  }

  Future<List<ReportHit>> approvedFollowUps({
    required String userId,
  }) async {
    return approvedFollowUpHits(await loadAll(userId));
  }

  Future<Map<String, ReportRevision>> latestTextChanges({
    required String userId,
  }) async {
    final reports = await loadAll(userId);
    final changes = <String, ReportRevision>{};
    for (final report in reports) {
      final history = await _readRevisions(
        _revisionsFile(userId, report.sessionId),
      );
      for (final item in report.items) {
        final change = latestTextChange(history, item.id);
        if (change == null) continue;
        changes[reportHitKey(report.sessionId, item.id)] = change;
      }
    }
    return changes;
  }

  Future<void> deleteDerivatives({
    required String userId,
    required String sessionId,
  }) async {
    checkSessionId(sessionId);
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

  /// Regenerating replaces report.json, so the previous version is kept next
  /// to it as report.v1.json, report.v2.json, ... and goes away with the
  /// other derivatives when the session is deleted.
  Future<void> _archivePrevious(String userId, String sessionId) async {
    final current = _reportFile(userId, sessionId);
    if (!await current.exists()) return;
    final names = await current.parent
        .list()
        .map((entity) => p.basename(entity.path))
        .toList();
    final next = names.where(_isArchivedReport).length + 1;
    await current.copy(p.join(current.parent.path, 'report.v$next.json'));
  }

  File _revisionsFile(String userId, String sessionId) {
    return File(
      p.join(
        _files.getSessionReportsPath(userId),
        sessionId,
        'revisions.json',
      ),
    );
  }

  Future<void> _appendRevisions({
    required String userId,
    required String sessionId,
    required SessionReport before,
    required SessionReport after,
    required String at,
  }) async {
    final previous = {
      for (final item in before.items) item.id: item,
    };
    final added = <ReportRevision>[];
    for (final item in after.items) {
      final old = previous[item.id];
      if (old == null) continue;
      added.addAll(
        revisionsForChange(before: old, after: item, at: at),
      );
    }
    if (added.isEmpty) return;
    final file = _revisionsFile(userId, sessionId);
    final history = await _readRevisions(file);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(
        revisionsToJson([...history, ...added]),
      ),
      flush: true,
    );
  }

  Future<List<ReportRevision>> _readRevisions(File file) async {
    if (!await file.exists()) return const [];
    final raw = jsonDecode(await file.readAsString());
    if (raw is! Map) throw FormatException('revisions are not an object');
    return revisionsFromJson(raw.cast<String, dynamic>());
  }

  Future<List<SessionReport>> loadAll(String userId) async {
    final root = Directory(_files.getSessionReportsPath(userId));
    if (!await root.exists()) return const [];
    final dirs = <Directory>[];
    await for (final entity in root.list()) {
      if (entity is Directory) dirs.add(entity);
    }
    dirs.sort(
      (a, b) => p.basename(a.path).compareTo(p.basename(b.path)),
    );
    final reports = <SessionReport>[];
    for (final dir in dirs) {
      final report = await load(
        userId: userId,
        sessionId: p.basename(dir.path),
      );
      if (report != null) reports.add(report);
    }
    return reports;
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
    checkSessionId(sessionId);
    final imported = await importedSegments(userId, sessionId);
    if (imported.isNotEmpty) {
      // Reports read the corrected text; the original file is never changed.
      return TranscriptCorrectionService(reports: this)
          .correctedSegments(userId, sessionId);
    }
    final text = await _chatText(userId, sessionId);
    if (text.trim().isEmpty) throw StateError('nothing to report');
    return [
      ReportSegment(id: 'seg_0', text: text.trim()),
    ];
  }

  Future<List<ReportSegment>> importedSegments(
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

bool _isArchivedReport(String name) =>
    RegExp(r'^report\.v\d+\.json$').hasMatch(name);

void checkSessionId(String sessionId) {
  if (sessionId.isEmpty ||
      sessionId.contains('/') ||
      sessionId.contains('\\') ||
      sessionId == '.' ||
      sessionId == '..') {
    throw ArgumentError.value(sessionId, 'sessionId', 'invalid session id');
  }
}
