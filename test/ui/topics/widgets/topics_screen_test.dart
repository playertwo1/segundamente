import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/data/repositories/memex_router.dart';
import 'package:memex/domain/models/topic.dart';
import 'package:memex/l10n/app_localizations.dart';
import 'package:memex/ui/topics/view_models/topics_viewmodel.dart';
import 'package:memex/ui/topics/widgets/topics_screen.dart';
import 'package:memex/utils/result.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'language': 'pt'});
    await UserStorage.initL10n();
  });

  Future<_FakeRouter> pump(
    WidgetTester tester, {
    List<Topic> topics = const [],
  }) async {
    final router = _FakeRouter(topics);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: TopicsScreen(viewModel: TopicsViewModel(router: router)),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('no topic shows an explanation', (tester) async {
    await pump(tester);
    expect(find.text(UserStorage.l10n.topicsEmpty), findsOneWidget);
  });

  testWidgets('creates a project, shows its kind, refuses a repeated name',
      (tester) async {
    final router = await pump(tester);

    Future<void> create(String name, {bool project = false}) async {
      await tester.tap(find.byKey(const ValueKey('topic_new')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const ValueKey('topic_name_field')), name);
      if (project) {
        await tester.tap(find.byKey(const ValueKey('topic_is_project')));
        await tester.pump();
      }
      await tester.tap(find.byKey(const ValueKey('topic_name_save')));
      await tester.pumpAndSettle();
    }

    await create('Obra', project: true);
    expect(router.topics.single.isProject, isTrue);
    expect(find.text('Projeto · nenhuma sessão'), findsOneWidget);

    await create('obra');
    expect(router.topics, hasLength(1));
    expect(find.text(UserStorage.l10n.topicNameInvalid), findsOneWidget);
  });

  testWidgets('marking a session links it, unmarking removes it',
      (tester) async {
    final router = await pump(
      tester,
      topics: addTopic(const [], id: 't1', name: 'Casa'),
    );
    await tester.tap(find.byKey(const ValueKey('topic_row_t1')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('topic_session_s1')));
    await tester.pumpAndSettle();
    expect(router.topics.single.sessionIds, ['s1']);

    await tester.tap(find.byKey(const ValueKey('topic_session_s1')));
    await tester.pumpAndSettle();
    expect(router.topics.single.sessionIds, isEmpty);
  });

  testWidgets('rename and delete work from the detail', (tester) async {
    final router = await pump(
      tester,
      topics: addTopic(const [], id: 't1', name: 'Casa'),
    );
    await tester.tap(find.byKey(const ValueKey('topic_row_t1')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('topic_rename')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('topic_name_field')), 'Apartamento');
    await tester.tap(find.byKey(const ValueKey('topic_name_save')));
    await tester.pumpAndSettle();
    expect(router.topics.single.name, 'Apartamento');

    await tester.tap(find.byKey(const ValueKey('topic_delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('topic_delete_confirm')));
    await tester.pumpAndSettle();
    expect(router.topics, isEmpty);
    expect(find.text(UserStorage.l10n.topicsEmpty), findsOneWidget);
  });
}

class _FakeRouter implements MemexRouter {
  _FakeRouter(this.topics);

  List<Topic> topics;

  @override
  Future<Result<List<Topic>>> loadTopics() async => Ok(topics);

  @override
  Future<Result<List<Topic>>> updateTopics(
    List<Topic> Function(List<Topic>) change,
  ) async {
    topics = change(topics);
    return Ok(topics);
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> fetchChatSessions({
    String? agentName,
    int? limit,
  }) async =>
      const Ok([
        {'session_id': 's1', 'title': 'Reunião da obra'},
      ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
