import 'package:flutter/foundation.dart';
import 'package:memex/data/repositories/memex_router.dart';
import 'package:memex/data/services/native_action_service.dart';
import 'package:memex/domain/models/explicit_due.dart';
import 'package:memex/domain/models/report_memory.dart';
import 'package:memex/utils/result.dart';

class FollowUpsViewModel extends ChangeNotifier {
  FollowUpsViewModel({
    required MemexRouter router,
    Future<bool> Function({
      required String title,
      required DateTime start,
      required DateTime end,
      String? description,
      bool allDay,
    })? openCalendar,
  })  : _router = router,
        _openCalendar = openCalendar ?? NativeActionService.openCalendarInsert;

  final MemexRouter _router;
  final Future<bool> Function({
    required String title,
    required DateTime start,
    required DateTime end,
    String? description,
    bool allDay,
  }) _openCalendar;

  /// The date the user wrote for this item, or null: only an explicit date
  /// gets an "add to calendar" action.
  static ExplicitDue? explicitDue(ReportHit hit) =>
      parseExplicitDue(hit.item.due);

  /// Opens the calendar app's new-event screen with this item. The user
  /// saves it there; nothing is written from here.
  Future<bool> addToCalendar(ReportHit hit) async {
    final due = explicitDue(hit);
    if (due == null) return false;
    // All-day events are expressed in UTC midnight, as calendars expect.
    final start = due.hasTime
        ? due.date
        : DateTime.utc(due.date.year, due.date.month, due.date.day);
    final end = due.hasTime
        ? start.add(const Duration(hours: 1))
        : start.add(const Duration(days: 1));
    return _openCalendar(
      title: hit.item.text,
      start: start,
      end: end,
      description: hit.item.source.excerpt,
      allDay: !due.hasTime,
    );
  }

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
