import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/data/repositories/memex_router.dart';
import 'package:memex/domain/models/timeline_card_model.dart';
import 'package:memex/ui/search/view_models/global_search_viewmodel.dart';
import 'package:memex/ui/search/widgets/global_search_screen.dart';
import 'package:memex/utils/result.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRouter implements MemexRouter {
  List<TimelineCardModel> cards = [];
  List<Map<String, dynamic>> files = [];
  final queries = <String>[];

  @override
  Future<Result<List<TimelineCardModel>>> searchCards(
    String query, {
    int limit = 50,
  }) async {
    queries.add(query);
    return Ok(cards);
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> searchPkmFiles(
    String query,
  ) async =>
      Ok(files);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TimelineCardModel _card(String id, String title) => TimelineCardModel(
      id: id,
      timestamp: DateTime(2026, 11, 4, 7, 32),
      tags: const [],
      status: 'completed',
      title: title,
      uiConfigs: const [],
    );

void main() {
  late _FakeRouter router;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'language': 'pt'});
    await UserStorage.initL10n();
    router = _FakeRouter();
  });

  Future<GlobalSearchViewModel> pump(
    WidgetTester tester, {
    void Function(TimelineCardModel)? onCard,
    void Function(String)? onFile,
  }) async {
    final vm = GlobalSearchViewModel(
      router: router,
      debounce: const Duration(milliseconds: 10),
    );
    addTearDown(vm.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: GlobalSearchScreen(
          viewModel: vm,
          onOpenCard: onCard ?? (_) {},
          onOpenFile: onFile ?? (_) {},
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    return vm;
  }

  testWidgets('sem busca mostra as recentes e limpa a lista', (tester) async {
    SharedPreferences.setMockInitialValues({
      'language': 'pt',
      'global_search_recent': ['caminhada', 'ideias do projeto'],
    });
    await pump(tester);

    expect(find.text('Buscar em tudo'), findsOneWidget);
    expect(find.text('Buscas recentes'), findsOneWidget);
    expect(find.text('caminhada'), findsOneWidget);

    await tester.tap(find.text('Limpar recentes'));
    await tester.pump();
    expect(find.text('Buscas recentes'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('global_search_recent'), isNull);
  });

  testWidgets('resultados agrupados por tipo, com contagem', (tester) async {
    router.cards = [_card('c1', 'Caminhada na serra')];
    router.files = [
      {'name': 'Rotina de caminhada.md', 'path': 'Resources/rotina.md'},
    ];
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'caminhada');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.text('Resultados'), findsOneWidget);
    expect(find.text('2 registros'), findsOneWidget);
    expect(find.text('Cartões'), findsOneWidget);
    expect(find.text('Conhecimento'), findsOneWidget);
    expect(find.byKey(const ValueKey('search-card-c1')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('search-file-Resources/rotina.md')),
      findsOneWidget,
    );
  });

  testWidgets('tocar num resultado abre o item e guarda a busca',
      (tester) async {
    router.cards = [_card('c1', 'Caminhada na serra')];
    TimelineCardModel? opened;
    await pump(tester, onCard: (c) => opened = c);

    await tester.enterText(find.byType(TextField), 'caminhada');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('search-card-c1')));
    await tester.pump();

    expect(opened?.id, 'c1');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('global_search_recent'), ['caminhada']);
  });

  testWidgets('sem resultados mostra o estado vazio e limpa a busca',
      (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'astronomia');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.text('Nenhum registro encontrado'), findsOneWidget);
    await tester.tap(find.text('Limpar busca'));
    await tester.pump();
    expect(find.text('Nenhum registro encontrado'), findsNothing);
  });

  test('uma busca nova descarta a resposta da anterior', () async {
    final vm = GlobalSearchViewModel(
      router: router,
      debounce: const Duration(milliseconds: 1),
    );
    router.cards = [_card('c1', 'A')];
    final first = vm.search('a');
    final second = vm.search('ab');
    await Future.wait([first, second]);
    expect(router.queries, ['a', 'ab']);
    expect(vm.searching, isFalse);
    vm.dispose();
  });

  test('recentes guardam no máximo oito, sem repetir', () async {
    final vm = GlobalSearchViewModel(router: router);
    for (var i = 0; i < 10; i++) {
      await vm.remember('q$i');
    }
    await vm.remember('q5');
    expect(vm.recents.length, GlobalSearchViewModel.maxRecent);
    expect(vm.recents.first, 'q5');
    expect(vm.recents.where((r) => r == 'q5').length, 1);
    vm.dispose();
  });
}
