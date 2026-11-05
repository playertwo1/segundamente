import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/data/repositories/memex_router.dart';
import 'package:memex/l10n/app_localizations.dart';
import 'package:memex/ui/glossary/view_models/glossary_viewmodel.dart';
import 'package:memex/ui/glossary/widgets/glossary_screen.dart';
import 'package:memex/utils/result.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'language': 'pt'});
    await UserStorage.initL10n();
  });

  Future<_FakeRouter> pump(WidgetTester tester, {List<String>? terms}) async {
    final router = _FakeRouter(terms ?? []);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: GlossaryScreen(viewModel: GlossaryViewModel(router: router)),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  Finder preview() => find.byKey(const ValueKey('glossary_preview'));

  testWidgets('no term: explanation and an empty preview', (tester) async {
    await pump(tester);
    expect(find.text(UserStorage.l10n.glossaryEmpty), findsOneWidget);
    expect(
      tester.widget<Text>(preview()).data,
      UserStorage.l10n.glossaryPreviewNone,
    );
  });

  testWidgets('an added term shows in the list, the count and the preview',
      (tester) async {
    final router = await pump(tester);
    await tester.enterText(
        find.byKey(const ValueKey('glossary_field')), 'Alvarenga');
    await tester.tap(find.byKey(const ValueKey('glossary_add')));
    await tester.pumpAndSettle();

    expect(router.terms, ['Alvarenga']);
    expect(find.text('1 de 50 termos'), findsOneWidget);
    final shown = tester.widget<Text>(preview()).data!;
    expect(shown, contains('Alvarenga'));
    expect(shown, startsWith('The user keeps these names'));
  });

  testWidgets('a repeated term is refused with a message', (tester) async {
    final router = await pump(tester, terms: ['Alvarenga']);
    await tester.enterText(
        find.byKey(const ValueKey('glossary_field')), 'alvarenga');
    await tester.tap(find.byKey(const ValueKey('glossary_add')));
    await tester.pumpAndSettle();
    expect(router.terms, ['Alvarenga']);
    expect(find.text(UserStorage.l10n.glossaryRejected), findsOneWidget);
  });

  testWidgets('removing a term updates the list', (tester) async {
    final router = await pump(tester, terms: ['A', 'B']);
    await tester.tap(find.byKey(const ValueKey('glossary_remove_A')));
    await tester.pumpAndSettle();
    expect(router.terms, ['B']);
  });
}

class _FakeRouter implements MemexRouter {
  _FakeRouter(this.terms);

  List<String> terms;

  @override
  Future<Result<List<String>>> loadGlossary() async => Ok(terms);

  @override
  Future<Result<List<String>>> updateGlossary(
    List<String> Function(List<String>) change,
  ) async {
    terms = change(terms);
    return Ok(terms);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
