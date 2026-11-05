import 'package:flutter/foundation.dart';
import 'package:memex/data/repositories/memex_router.dart';
import 'package:memex/domain/models/transcript_correction.dart';
import 'package:memex/utils/result.dart';

/// Fixes for one imported transcript: the stored ones start marked, the
/// proposals from the term dictionary start unmarked.
class CorrectionsViewModel extends ChangeNotifier {
  CorrectionsViewModel({required MemexRouter router, required this.sessionId})
      : _router = router;

  final MemexRouter _router;
  final String sessionId;

  List<TextFix> rows = const [];
  final Set<int> marked = {};
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    (await _router.loadTranscriptFixes(sessionId)).when(
      onOk: (value) {
        rows = [
          ...value.stored,
          ...value.proposed.where((p) => !_has(value.stored, p)),
        ];
        marked
          ..clear()
          ..addAll([for (var i = 0; i < value.stored.length; i++) i]);
      },
      onError: (error, _) => errorMessage = error.toString(),
    );
    isLoading = false;
    notifyListeners();
  }

  static bool _has(List<TextFix> list, TextFix fix) => list.any(
        (f) =>
            f.segmentId == fix.segmentId &&
            f.from == fix.from &&
            f.to == fix.to,
      );

  void toggle(int index) {
    if (!marked.remove(index)) marked.add(index);
    notifyListeners();
  }

  /// True when stored; false when a fix no longer applies.
  Future<bool> save() async {
    final chosen = [
      for (var i = 0; i < rows.length; i++)
        if (marked.contains(i)) rows[i],
    ];
    var ok = true;
    (await _router.saveTranscriptFixes(sessionId, chosen)).when(
      onOk: (_) {},
      onError: (error, _) {
        errorMessage = error.toString();
        ok = false;
      },
    );
    notifyListeners();
    return ok;
  }
}
