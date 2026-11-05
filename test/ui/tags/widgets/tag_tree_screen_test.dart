import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/data/repositories/memex_router.dart';
import 'package:memex/l10n/app_localizations.dart';
import 'package:memex/ui/tags/view_models/tag_tree_viewmodel.dart';
import 'package:memex/ui/tags/widgets/tag_tree_screen.dart';
import 'package:memex/utils/result.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'language': 'pt'});
    await UserStorage.initL10n();
  });

  /// Opens the tree from a button, as the menu does, and returns what it pops.
  Future<List<String?>> pumpTree(
    WidgetTester tester,
    List<List<String>> cards,
  ) async {
    final popped = <String?>[];
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
              popped.add(await Navigator.of(context).push<String>(
                MaterialPageRoute(
                  builder: (_) => TagTreeScreen(
                    viewModel: TagTreeViewModel(router: _FakeRouter(cards)),
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

  testWidgets('shows roots with counts, children appear when opened',
      (tester) async {
    await pumpTree(tester, [
      ['trabalho/alfa'],
      ['trabalho/alfa'],
      ['trabalho/beta'],
      ['casa'],
    ]);

    expect(find.text('trabalho'), findsOneWidget);
    expect(find.text('casa'), findsOneWidget);
    expect(find.text('alfa'), findsNothing);
    final row = find.byKey(const ValueKey('tag_row_trabalho'));
    expect(find.descendant(of: row, matching: find.text('3')), findsOneWidget);
    expect(find.byKey(const ValueKey('tag_toggle_casa')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('tag_toggle_trabalho')));
    await tester.pumpAndSettle();
    expect(find.text('alfa'), findsOneWidget);
    expect(find.text('beta'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('tag_row_trabalho/alfa')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('tag_toggle_trabalho')));
    await tester.pumpAndSettle();
    expect(find.text('alfa'), findsNothing);
  });

  testWidgets('tapping a row returns its full tag, the chevron does not',
      (tester) async {
    final popped = await pumpTree(tester, [
      ['trabalho/alfa'],
      ['casa'],
    ]);

    await tester.tap(find.byKey(const ValueKey('tag_toggle_trabalho')));
    await tester.pumpAndSettle();
    expect(find.byType(TagTreeScreen), findsOneWidget);
    expect(popped, isEmpty);

    await tester.tap(find.text('alfa'));
    await tester.pumpAndSettle();
    expect(popped, ['trabalho/alfa']);
    expect(find.byType(TagTreeScreen), findsNothing);
  });

  testWidgets('rows are 56dp buttons with a label and a 48dp chevron',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpTree(tester, [
      ['trabalho/alfa'],
    ]);

    final row = find.byKey(const ValueKey('tag_row_trabalho'));
    expect(tester.getSize(row).height, greaterThanOrEqualTo(56));
    final toggle =
        tester.getSize(find.byKey(const ValueKey('tag_toggle_trabalho')));
    expect(toggle.width, greaterThanOrEqualTo(48));
    expect(toggle.height, greaterThanOrEqualTo(48));
    expect(
      find.bySemanticsLabel(RegExp('^trabalho, ')),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('no tags shows an explanation', (tester) async {
    await pumpTree(tester, const []);
    expect(find.text(UserStorage.l10n.tagTreeEmpty), findsOneWidget);
  });
}

class _FakeRouter implements MemexRouter {
  _FakeRouter(this.cards);

  final List<List<String>> cards;

  @override
  Future<Result<List<List<String>>>> fetchCardTagLists() async => Ok(cards);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
