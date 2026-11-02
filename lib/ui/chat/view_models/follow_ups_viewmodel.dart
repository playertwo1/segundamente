import 'package:flutter/foundation.dart';
import 'package:memex/data/repositories/memex_router.dart';
import 'package:memex/domain/models/report_memory.dart';
import 'package:memex/utils/result.dart';

class FollowUpsViewModel extends ChangeNotifier {
  FollowUpsViewModel({required MemexRouter router}) : _router = router;

  final MemexRouter _router;

  List<ReportHit> hits = const [];
  Map<String, ReportRevision> textChanges = const {};
  bool loading = false;
  String? errorMessage;

  Future<void> load() {
    return _load(search: null);
  }

  Future<void> search(String query) {
    return _load(search: query);
  }

  Future<void> _load({required String? search}) async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    final hitsResult = search == null || search.trim().isEmpty
        ? await _router.loadApprovedFollowUps()
        : await _router.searchSessionReports(search);
    final changesResult = await _router.loadReportTextChanges();
    hitsResult.when(
      onOk: (value) => hits = value,
      onError: (error, _) => errorMessage = '$error',
    );
    changesResult.when(
      onOk: (value) => textChanges = value,
      onError: (error, _) => errorMessage ??= '$error',
    );
    loading = false;
    notifyListeners();
  }
}
