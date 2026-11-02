import 'package:flutter/foundation.dart';
import 'package:memex/data/repositories/memex_router.dart';
import 'package:memex/utils/result.dart';
import 'package:memex/domain/models/session_report.dart';
import 'package:memex/domain/models/session_report_export.dart';

class SessionReportViewModel extends ChangeNotifier {
  SessionReportViewModel({
    required MemexRouter router,
    required this.sessionId,
  }) : _router = router;

  final MemexRouter _router;
  final String sessionId;

  SessionReport? report;
  bool loading = false;
  String? errorMessage;

  Future<void> load() async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    final result = await _router.loadSessionReport(sessionId);
    result.when(
      onOk: (value) => report = value,
      onError: (error, _) => errorMessage = '$error',
    );
    loading = false;
    notifyListeners();
  }

  Future<void> draft(ReportKind kind, String? customTitle) async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    final result = await _router.draftSessionReport(
      sessionId: sessionId,
      kind: kind,
      customTitle: customTitle,
    );
    result.when(
      onOk: (value) => report = value,
      onError: (error, _) => errorMessage = '$error',
    );
    loading = false;
    notifyListeners();
  }

  Future<void> edit({
    required String itemId,
    required String text,
    required String assignee,
    required String due,
  }) async {
    final result = await _router.editSessionReportItem(
      sessionId: sessionId,
      itemId: itemId,
      text: text,
      assignee: assignee,
      due: due,
    );
    result.when(
      onOk: (value) {
        report = value;
        errorMessage = null;
      },
      onError: (error, _) => errorMessage = '$error',
    );
    notifyListeners();
  }

  Future<void> setStatus({
    required String itemId,
    required ReportItemStatus status,
  }) async {
    final result = await _router.setSessionReportItemStatus(
      sessionId: sessionId,
      itemId: itemId,
      status: status,
    );
    result.when(
      onOk: (value) {
        report = value;
        errorMessage = null;
      },
      onError: (error, _) => errorMessage = '$error',
    );
    notifyListeners();
  }

  Future<Result<String>> export({
    required ReportExportFormat format,
    required Set<String> itemIds,
    DateTime? exportedAt,
  }) async {
    errorMessage = null;
    final result = await _router.exportSessionReport(
      sessionId: sessionId,
      format: format,
      exportedAt: exportedAt ?? DateTime.now(),
      itemIds: itemIds,
    );
    result.when(
      onOk: (_) {},
      onError: (error, _) => errorMessage = '$error',
    );
    notifyListeners();
    return result;
  }

  void showError(Object error) {
    errorMessage = '$error';
    notifyListeners();
  }
}
