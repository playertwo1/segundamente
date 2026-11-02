import 'dart:io';

import 'package:memex/data/services/file_system_service.dart';
import 'package:memex/data/services/session_report_service.dart';
import 'package:memex/domain/models/session_report_export.dart';
import 'package:path/path.dart' as p;

class SessionReportExportService {
  SessionReportExportService({
    FileSystemService? fileService,
    SessionReportService? reports,
  })  : _files = fileService ?? FileSystemService.instance,
        _reports = reports ?? SessionReportService();

  final FileSystemService _files;
  final SessionReportService _reports;

  Future<File> write({
    required String userId,
    required String sessionId,
    required ReportExportFormat format,
    required DateTime exportedAt,
    Set<String>? itemIds,
  }) async {
    final report = await _reports.load(userId: userId, sessionId: sessionId);
    if (report == null) throw StateError('report missing');
    final bytes = exportSessionReportBytes(
      report: report,
      exportedAt: exportedAt,
      format: format,
      itemIds: itemIds,
    );
    final file = File(
      p.join(
        _files.getSessionReportsPath(userId),
        sessionId,
        reportExportFileName(format),
      ),
    );
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
