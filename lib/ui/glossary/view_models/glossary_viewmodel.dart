import 'package:flutter/foundation.dart';
import 'package:memex/data/repositories/memex_router.dart';
import 'package:memex/domain/models/glossary.dart';
import 'package:memex/utils/result.dart';

/// The user's terms (names, acronyms, products) sent along with report prompts.
class GlossaryViewModel extends ChangeNotifier {
  GlossaryViewModel({required MemexRouter router}) : _router = router;

  final MemexRouter _router;

  List<String> terms = const [];
  bool isLoading = false;
  String? errorMessage;

  /// Exactly the text appended to the model request; empty without terms.
  String get preview => glossaryPromptBlock(terms);

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    (await _router.loadGlossary()).when(
      onOk: (list) => terms = list,
      onError: (error, _) => errorMessage = error.toString(),
    );
    isLoading = false;
    notifyListeners();
  }

  /// False when the term is refused (see [addGlossaryTerm]).
  Future<bool> add(String term) => _apply(
        (t) => addGlossaryTerm(t, term),
        accepted: (t) => t.length > terms.length,
      );

  Future<void> remove(String term) =>
      _apply((t) => removeGlossaryTerm(t, term));

  Future<bool> _apply(
    List<String> Function(List<String>) change, {
    bool Function(List<String>)? accepted,
  }) async {
    var ok = true;
    (await _router.updateGlossary(change)).when(
      onOk: (list) {
        ok = accepted?.call(list) ?? true;
        terms = list;
      },
      onError: (error, _) {
        errorMessage = error.toString();
        ok = false;
      },
    );
    notifyListeners();
    return ok;
  }
}
