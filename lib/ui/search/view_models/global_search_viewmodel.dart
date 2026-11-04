import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:memex/data/repositories/memex_router.dart';
import 'package:memex/domain/models/timeline_card_model.dart';
import 'package:memex/utils/logger.dart';
import 'package:memex/utils/result.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Search across timeline cards and knowledge files (reference 16), with a
/// short list of recent searches kept on the device.
class GlobalSearchViewModel extends ChangeNotifier {
  GlobalSearchViewModel({
    required MemexRouter router,
    this.debounce = const Duration(milliseconds: 350),
  }) : _router = router;

  static const _keyRecent = 'global_search_recent';
  static const maxRecent = 8;

  final MemexRouter _router;
  final Duration debounce;
  final _log = getLogger('GlobalSearchViewModel');

  String query = '';
  List<String> recents = const [];
  List<TimelineCardModel> cards = const [];
  List<Map<String, dynamic>> files = const [];
  bool searching = false;
  bool searched = false;

  Timer? _timer;
  int _token = 0;
  bool _disposed = false;

  bool get hasQuery => query.trim().isNotEmpty;
  int get resultCount => cards.length + files.length;
  bool get noResults => searched && !searching && resultCount == 0;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    recents = prefs.getStringList(_keyRecent) ?? const [];
    _notify();
  }

  void onQueryChanged(String value) {
    query = value;
    _timer?.cancel();
    if (!hasQuery) {
      _token++;
      cards = const [];
      files = const [];
      searching = false;
      searched = false;
      _notify();
      return;
    }
    _timer = Timer(debounce, () => search(value.trim()));
    _notify();
  }

  Future<void> search(String q) async {
    final token = ++_token;
    searching = true;
    _notify();
    try {
      final cardsRequest = _router.searchCards(q);
      final filesRequest = _router.searchPkmFiles(q);
      final cardsResult = await cardsRequest;
      final filesResult = await filesRequest;
      if (token != _token) return; // a newer query took over
      cards = cardsResult.isOk ? cardsResult.valueOrThrow : const [];
      files = filesResult.isOk ? filesResult.valueOrThrow : const [];
      searched = true;
    } catch (e, st) {
      _log.warning('Search failed', e, st);
      if (token != _token) return;
      cards = const [];
      files = const [];
      searched = true;
    } finally {
      if (token == _token) {
        searching = false;
        _notify();
      }
    }
  }

  /// Runs the query now (keyboard "search" or a recent item) and remembers it.
  Future<void> submit(String value) async {
    final q = value.trim();
    if (q.isEmpty) return;
    _timer?.cancel();
    query = q;
    await remember(q);
    await search(q);
  }

  Future<void> remember(String value) async {
    final q = value.trim();
    if (q.isEmpty) return;
    final next = [q, ...recents.where((r) => r != q)].take(maxRecent).toList();
    recents = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyRecent, next);
    _notify();
  }

  Future<void> clearRecents() async {
    recents = const [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRecent);
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
