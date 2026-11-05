import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memex/data/repositories/memex_router.dart';
import 'package:memex/domain/models/calendar_model.dart';
import 'package:memex/l10n/app_localizations.dart';
import 'package:memex/ui/calendar/view_models/calendar_viewmodel.dart';
import 'package:memex/ui/calendar/widgets/calendar_screen.dart';
import 'package:memex/ui/core/themes/app_colors.dart';
import 'package:memex/utils/result.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'language': 'pt'});
    await UserStorage.initL10n();
    await initializeDateFormatting('pt');
  });

  test('activity levels are 0, 1, 2, 3-4 and 5+', () {
    expect(
      [0, 1, 2, 3, 4, 5, 12].map(activityLevel),
      [0, 1, 2, 3, 3, 4, 4],
    );
    expect(activityLevel(-1), 0);
  });

  testWidgets('month grid shades each day by activity and keeps selection',
      (tester) async {
    final initial = DateTime(2026, 11, 15);
    final counts = {4: 1, 5: 2, 6: 3, 7: 4, 8: 5, 9: 9};
    final router = _FakeRouter([
      for (final e in counts.entries)
        CalendarDay(
          timestamp:
              DateTime(2026, 11, e.key, 12).millisecondsSinceEpoch ~/ 1000,
          total: e.value,
          cards: const [],
        ),
    ]);
    final vm = CalendarViewModel(router: router, initialDate: initial);
    await vm.fetchMonthData(initial);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: CalendarScreen(initialDate: initial, viewModel: vm),
      ),
    );
    await tester.pump();

    BoxDecoration circle(int day) => tester
        .widgetList<Container>(find.byType(Container))
        .where((c) => c.child is Text && (c.child! as Text).data == '$day')
        .single
        .decoration! as BoxDecoration;
    Color? fill(int day) => circle(day).color;

    expect(fill(3), isNull);
    final alphas = [4, 5, 6, 8].map((d) => fill(d)!.a).toList();
    expect(alphas, [...alphas]..sort());
    expect(alphas.toSet(), hasLength(4));
    expect(fill(6)!.a, fill(7)!.a); // 3 and 4 cards share a level
    expect(fill(8)!.a, fill(9)!.a); // 5 and 9 cards share a level

    // The selected day is solid amber with dark text.
    expect(fill(15), AppColors.primary);
    final selectedText = tester.widget<Text>(find.text('15'));
    expect(selectedText.style?.color, AppColors.background);

    // Activity text no longer uses the off-palette indigo.
    final style = tester.widget<Text>(find.text('8').first).style;
    expect(style?.color, isNot(const Color(0xFF4338CA)));

    // Each day is a labelled button with its count.
    final handle = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.byWidgetPredicate(
        (w) => w is Semantics && (w.properties.label ?? '').endsWith(', 5'),
      )),
      isSemantics(isButton: true, hasTapAction: true),
    );
    handle.dispose();
  });
}

class _FakeRouter implements MemexRouter {
  _FakeRouter(this.days);

  final List<CalendarDay> days;

  @override
  Future<Result<List<CalendarDay>>> fetchCalendarData(
    int startTimestamp,
    int endTimestamp,
  ) async =>
      Ok(days);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
