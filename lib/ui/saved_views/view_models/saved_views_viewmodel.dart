import 'package:flutter/foundation.dart';
import 'package:memex/data/repositories/memex_router.dart';
import 'package:memex/domain/models/saved_view.dart';
import 'package:memex/utils/result.dart';

/// Saved timeline views and the tags a new one can be built from.
class SavedViewsViewModel extends ChangeNotifier {
  SavedViewsViewModel({required MemexRouter router}) : _router = router;

  final MemexRouter _router;

  List<SavedView> views = const [];
  List<String> tagNames = const [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    (await _router.loadSavedViews()).when(
      onOk: (list) => views = list,
      onError: (error, _) => errorMessage = error.toString(),
    );
    (await _router.fetchTags()).when(
      onOk: (list) => tagNames = [for (final t in list) t.name],
      onError: (error, _) => errorMessage = error.toString(),
    );
    isLoading = false;
    notifyListeners();
  }

  /// False when the name is blank or taken, or no tag is marked.
  Future<bool> create(String name, List<String> tags) {
    final id = 'view_${DateTime.now().microsecondsSinceEpoch}';
    return _apply(
      (v) => addSavedView(v, id: id, name: name, tags: tags),
      accepted: (v) => v.any((x) => x.id == id),
    );
  }

  Future<bool> rename(String id, String name) => _apply(
        (v) => renameSavedView(v, id, name),
        accepted: (v) => v.any((x) => x.id == id && x.name == name.trim()),
      );

  Future<void> delete(String id) => _apply((v) => removeSavedView(v, id));

  Future<bool> _apply(
    List<SavedView> Function(List<SavedView>) change, {
    bool Function(List<SavedView>)? accepted,
  }) async {
    var ok = true;
    (await _router.updateSavedViews(change)).when(
      onOk: (list) {
        views = list;
        ok = accepted?.call(list) ?? true;
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
