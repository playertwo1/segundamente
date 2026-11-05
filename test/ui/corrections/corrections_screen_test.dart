import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/data/repositories/memex_router.dart';
import 'package:memex/domain/models/transcript_correction.dart';
import 'package:memex/l10n/app_localizations.dart';
import 'package:memex/ui/corrections/view_models/corrections_viewmodel.dart';
import 'package:memex/ui/corrections/widgets/corrections_screen.dart';
import 'package:memex/utils/result.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'language': 'pt'});
    await UserStorage.initL10n();
  });

  Future<_FakeRouter> pump(WidgetTester tester, _FakeRouter router) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: CorrectionsScreen(
          viewModel: CorrectionsViewModel(router: router, sessionId: 's'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  const stored = TextFix(segmentId: 'seg_0', from: 'Memix', to: 'Memex');
  const proposed = TextFix(segmentId: 'seg_1', from: 'marilia', to: 'Marília');

  bool marked(WidgetTester tester, int i) => tester
      .widget<CheckboxListTile>(find.byKey(ValueKey('correction_$i')))
      .value!;

  testWidgets('nothing to propose shows an explanation', (tester) async {
    await pump(tester, _FakeRouter());
    expect(find.text(UserStorage.l10n.correctionsEmpty), findsOneWidget);
  });

  testWidgets(
      'stored fixes start marked, proposals unmarked; save sends marked',
      (tester) async {
    final router = await pump(
      tester,
      _FakeRouter(stored: [stored], proposed: [stored, proposed]),
    );
    expect(find.text('Memix → Memex'), findsOneWidget);
    expect(marked(tester, 0), isTrue);
    expect(marked(tester, 1), isFalse);

    await tester.tap(find.byKey(const ValueKey('correction_1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('corrections_save')));
    await tester.pumpAndSettle();
    expect(router.saved.map((f) => f.to), ['Memex', 'Marília']);
    expect(find.text(UserStorage.l10n.correctionsSaved), findsOneWidget);
  });

  testWidgets('a fix that no longer applies is reported, not hidden',
      (tester) async {
    final router = await pump(
      tester,
      _FakeRouter(proposed: [proposed], refuse: true),
    );
    await tester.tap(find.byKey(const ValueKey('correction_0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('corrections_save')));
    await tester.pumpAndSettle();
    expect(router.saved, isEmpty);
    expect(find.text(UserStorage.l10n.correctionsRefused), findsOneWidget);
  });
}

class _FakeRouter implements MemexRouter {
  _FakeRouter({
    this.stored = const [],
    this.proposed = const [],
    this.refuse = false,
  });

  final List<TextFix> stored;
  final List<TextFix> proposed;
  final bool refuse;
  List<TextFix> saved = [];

  @override
  Future<Result<({List<TextFix> proposed, List<TextFix> stored})>>
      loadTranscriptFixes(String sessionId) async =>
          Ok((proposed: proposed, stored: stored));

  @override
  Future<Result<void>> saveTranscriptFixes(
    String sessionId,
    List<TextFix> fixes,
  ) async {
    if (refuse) return Error(const CorrectionRefused('from not found'));
    saved = fixes;
    return const Ok.v();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
