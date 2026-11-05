import 'package:flutter/foundation.dart';
import 'package:memex/data/repositories/memex_router.dart';
import 'package:memex/domain/models/tag_tree.dart';
import 'package:memex/utils/result.dart';

/// Loads the tag tree and remembers which branches are open.
class TagTreeViewModel extends ChangeNotifier {
  TagTreeViewModel({required MemexRouter router}) : _router = router;

  final MemexRouter _router;

  List<TagTreeNode> roots = const [];
  final Set<String> expanded = {};
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    final result = await _router.fetchCardTagLists();
    result.when(
      onOk: (lists) => roots = buildTagTree(lists),
      onError: (error, _) => errorMessage = error.toString(),
    );
    isLoading = false;
    notifyListeners();
  }

  void toggle(String path) {
    if (!expanded.remove(path)) expanded.add(path);
    notifyListeners();
  }
}
