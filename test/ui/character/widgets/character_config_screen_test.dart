import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/data/repositories/memex_router.dart';
import 'package:memex/domain/models/character_model.dart';
import 'package:memex/l10n/app_localizations.dart';
import 'package:memex/ui/character/view_models/character_viewmodel.dart';
import 'package:memex/ui/character/widgets/character_config_screen.dart';
import 'package:memex/ui/core/themes/app_colors.dart';
import 'package:memex/ui/core/widgets/back_button.dart';
import 'package:memex/utils/result.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'language': 'pt'});
    await UserStorage.initL10n();
  });

  final curador = CharacterModel(
    id: 'curador',
    name: 'Curador',
    tags: const ['leitura', 'link'],
    persona: 'x',
    enabled: true,
    avatar: 'asset://characters/curador.png',
  );
  final tradutor = CharacterModel(
    id: 'tradutor',
    name: 'Tradutor',
    tags: const [],
    persona: 'x',
    enabled: false,
    avatar: 'asset://characters/tradutor.png',
  );

  Future<_FakeRouter> pump(WidgetTester tester) async {
    final router = _FakeRouter([curador, tradutor]);
    final viewModel = CharacterViewModel(router: router);
    await viewModel.loadCharacters();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: CharacterConfigScreen(viewModel: viewModel),
      ),
    );
    await tester.pump();
    return router;
  }

  testWidgets('loads a replacement ViewModel, as after the route rebuilds',
      (tester) async {
    final router = _FakeRouter([curador, tradutor]);
    Widget app(CharacterViewModel vm) => MaterialApp(
          locale: const Locale('pt'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: CharacterConfigScreen(viewModel: vm),
        );

    await tester.pumpWidget(app(CharacterViewModel(router: router)));
    await tester.pump();
    expect(find.text('Curador'), findsOneWidget);

    await tester.pumpWidget(app(CharacterViewModel(router: router)));
    await tester.pump();
    await tester.pump();
    expect(find.text('Curador'), findsOneWidget);
    expect(find.text(UserStorage.l10n.noCharacters), findsNothing);
  });

  testWidgets('lists characters as open rows with a labelled back arrow',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);

    expect(find.text('Curador'), findsOneWidget);
    expect(find.text('Tradutor'), findsOneWidget);
    expect(find.text('leitura  ·  link'), findsOneWidget);
    expect(find.text(UserStorage.l10n.noTags), findsOneWidget);

    // Open list: no repeated panel with a shadow behind each character.
    final shadowed = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .where((d) => d.boxShadow != null && d.boxShadow!.isNotEmpty);
    expect(shadowed, isEmpty);

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(AppBackButton)),
      isSemantics(label: 'Voltar', isButton: true, hasTapAction: true),
    );
    handle.dispose();
  });

  testWidgets('delete is a 48dp neutral action, not a red one', (tester) async {
    await pump(tester);

    final button = find.byKey(const ValueKey('character_delete_curador'));
    expect(button, findsOneWidget);
    final size = tester.getSize(button);
    expect(size.height, greaterThanOrEqualTo(48));
    expect(size.width, greaterThanOrEqualTo(48));

    final text = tester.widget<Text>(
      find.descendant(of: button, matching: find.text('Excluir')),
    );
    final color =
        DefaultTextStyle.of(tester.element(find.text('Excluir').first))
            .style
            .color;
    expect(text.style?.color, isNot(Colors.red[300]));
    expect(color, isNot(Colors.red[300]));
    expect(AppColors.textSecondary, isNot(Colors.red[300]));
  });

  testWidgets('the switch toggles a character and delete asks first',
      (tester) async {
    final router = await pump(tester);

    await tester.tap(find.byType(Switch).last);
    await tester.pump();
    expect(router.enabledCalls, [('tradutor', true)]);

    await tester.tap(find.byKey(const ValueKey('character_delete_curador')));
    await tester.pumpAndSettle();
    expect(find.text(UserStorage.l10n.confirmDelete), findsOneWidget);

    await tester.tap(find.text(UserStorage.l10n.cancel));
    await tester.pumpAndSettle();
    expect(router.deleted, isEmpty);

    await tester.tap(find.byKey(const ValueKey('character_delete_curador')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Excluir').last);
    await tester.pumpAndSettle();
    expect(router.deleted, ['curador']);
    expect(find.text('Curador'), findsNothing);
  });
}

class _FakeRouter implements MemexRouter {
  _FakeRouter(this.characters);

  final List<CharacterModel> characters;
  final enabledCalls = <(String, bool)>[];
  final deleted = <String>[];

  @override
  Future<Result<List<CharacterModel>>> fetchCharacters() async =>
      Ok(List.of(characters));

  @override
  Future<Result<bool>> setCharacterEnabled(String id, bool enabled) async {
    enabledCalls.add((id, enabled));
    return const Ok(true);
  }

  @override
  Future<Result<bool>> deleteCharacter(String id) async {
    deleted.add(id);
    return const Ok(true);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
