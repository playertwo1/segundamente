import 'dart:convert';
import 'dart:io';

import 'package:memex/data/services/file_system_service.dart';
import 'package:memex/data/services/session_report_service.dart';
import 'package:memex/domain/models/session_report.dart';
import 'package:memex/domain/models/transcript_correction.dart';
import 'package:path/path.dart' as p;

/// Keeps the fixes of an imported transcript in `corrections.json`, beside
/// the numbered import folders. `original.bin` is never touched.
class TranscriptCorrectionService {
  TranscriptCorrectionService({
    FileSystemService? fileService,
    SessionReportService? reports,
  })  : _files = fileService ?? FileSystemService.instance,
        _reports = reports ?? SessionReportService();

  final FileSystemService _files;
  final SessionReportService _reports;

  Future<List<TextFix>> load(String userId, String sessionId) async {
    final file = _file(userId, sessionId);
    if (!await file.exists()) return const [];
    final raw = jsonDecode(await file.readAsString());
    if (raw is! Map) throw const FormatException('corrections not an object');
    return correctionsFromJson(raw.cast<String, dynamic>());
  }

  /// Replaces the stored fixes. Throws [CorrectionRefused], and keeps the
  /// previous file, when any fix does not apply to the original text.
  Future<List<ReportSegment>> save(
    String userId,
    String sessionId,
    List<TextFix> fixes,
  ) async {
    checkSessionId(sessionId);
    final corrected = applyFixes(
      await _reports.importedSegments(userId, sessionId),
      fixes,
    );
    final file = _file(userId, sessionId);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(correctionsToJson(fixes)),
      flush: true,
    );
    return corrected;
  }

  /// The segments with the stored fixes applied; the original when none.
  Future<List<ReportSegment>> correctedSegments(
    String userId,
    String sessionId,
  ) async {
    checkSessionId(sessionId);
    return applyFixes(
      await _reports.importedSegments(userId, sessionId),
      await load(userId, sessionId),
    );
  }

  File _file(String userId, String sessionId) {
    checkSessionId(sessionId);
    return File(
      p.join(
        _files.getTranscriptImportsPath(userId),
        sessionId,
        'corrections.json',
      ),
    );
  }
}
