import 'package:flutter/foundation.dart';
import 'package:memex/data/repositories/memex_router.dart';
import 'package:memex/domain/models/report_memory.dart';
import 'package:memex/utils/result.dart';

class ReportRevisionsViewModel extends ChangeNotifier {
  ReportRevisionsViewModel({
    required MemexRouter router,
    required this.sessionId,
    this.itemId,
  }) : _router = router;

  final MemexRouter _router;
  final String sessionId;
  final String? itemId;

  bool isLoading = false;
  String? errorMessage;
  List<ReportRevision> revisions = const [];
  Map<String, String> itemLabels = const {};

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await _router.loadSessionRevisions(
      sessionId: sessionId,
      itemId: itemId,
    );

    result.when(
      onOk: (data) {
        revisions = data;
        errorMessage = null;
      },
      onError: (err, _) {
        errorMessage = err.toString();
        revisions = const [];
      },
    );

    final reportResult = await _router.loadSessionReport(sessionId);
    reportResult.when(
      onOk: (report) {
        if (report != null) {
          itemLabels = {
            for (final item in report.items) item.id: item.text,
          };
        }
      },
      onError: (_, __) {},
    );

    isLoading = false;
    notifyListeners();
  }
}
