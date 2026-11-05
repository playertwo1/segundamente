import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/data/repositories/memex_router.dart';
import 'package:memex/domain/models/saved_view.dart';
import 'package:memex/domain/models/tag_model.dart';
import 'package:memex/l10n/app_localizations.dart';
import 'package:memex/ui/saved_views/view_models/saved_views_viewmodel.dart';
import 'package:memex/ui/saved_views/widgets/saved_views_screen.dart';
import 'package:memex/utils/result.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'language': 'pt'});
    await UserStorage.initL10n();
  });

  /// Opens the screen from a button, as the menu does, and records its result.
  Future<List<List<String>?>> pump(
    WidgetTester tester,
    _FakeRouter router,
  ) async {
    final popped = <List<String>?>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              popped.add(await Navigator.of(context).push<List<String>>(
                MaterialPageRoute(
                  builder: (_) => SavedViewsScreen(
                    viewModel: SavedViewsViewModel(router: router),
                  ),
                ),
              ));
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return popped;
  }

  testWidgets('no view shows an explanation', (tester) async {
    await pump(tester, _FakeRouter());
    expect(find.text(UserStorage.l10n.savedViewsEmpty), findsOneWidget);
  });

  testWidgets('creates a view from marked tags, then tapping applies it',
      (tester) async {
    final router = _FakeRouter();
    final popped = await pump(tester, router);

    await tester.tap(find.byKey(const ValueKey('view_new')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('view_name_field')), 'Obra aberta');
    await tester.tap(find.byKey(const ValueKey('view_tag_obra')));
    await tester.tap(find.byKey(const ValueKey('view_tag_tarefa')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('view_save')));
    await tester.pumpAndSettle();

    expect(router.views.single.tags, ['obra', 'tarefa']);
    expect(find.text('obra + tarefa'), findsOneWidget);

    await tester.tap(find.text('Obra aberta'));
    await tester.pumpAndSettle();
    expect(popped.single, ['obra', 'tarefa']);
  });

  testWidgets('a view without tags is refused with a message', (tester) async {
    final router = _FakeRouter();
    await pump(tester, router);
    await tester.tap(find.byKey(const ValueKey('view_new')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('view_name_field')), 'Vazia');
    await tester.tap(find.byKey(const ValueKey('view_save')));
    await tester.pumpAndSettle();
    expect(router.views, isEmpty);
    expect(find.text(UserStorage.l10n.savedViewInvalid), findsOneWidget);
  });

  testWidgets('rename and delete persist', (tester) async {
    final router = _FakeRouter(
      views: addSavedView(const [], id: 'v1', name: 'Casa', tags: ['casa']),
    );
    await pump(tester, router);

    await tester.tap(find.byKey(const ValueKey('view_rename_v1')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('view_name_field')), 'Apartamento');
    await tester.tap(find.byKey(const ValueKey('view_name_save')));
    await tester.pumpAndSettle();
    expect(router.views.single.name, 'Apartamento');

    await tester.tap(find.byKey(const ValueKey('view_delete_v1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('view_delete_confirm')));
    await tester.pumpAndSettle();
    expect(router.views, isEmpty);
  });
}

class _FakeRouter implements MemexRouter {
  _FakeRouter({this.views = const []});

  List<SavedView> views;

  @override
  Future<Result<List<SavedView>>> loadSavedViews() async => Ok(views);

  @override
  Future<Result<List<SavedView>>> updateSavedViews(
    List<SavedView> Function(List<SavedView>) change,
  ) async {
    views = change(views);
    return Ok(views);
  }

  @override
  Future<Result<List<TagModel>>> fetchTags() async =>
      Ok([TagModel(name: 'obra'), TagModel(name: 'tarefa')]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
