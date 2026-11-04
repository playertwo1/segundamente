import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/data/repositories/memex_router.dart';
import 'package:memex/db/app_database.dart';
import 'package:memex/ui/agent_activity/view_models/agent_activity_viewmodel.dart';
import 'package:memex/ui/agent_activity/widgets/agent_activity_screen.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRouter implements MemexRouter {
  _FakeRouter(this.tasks, {this.error});

  final List<Task> tasks;
  final Object? error;

  @override
  Future<List<Task>> getTasks({int limit = 10, int offset = 0}) async {
    if (error != null) throw error!;
    return tasks;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Task _task(String id, String status, {String type = 'add_task', int? at}) =>
    Task(
      id: id,
      type: type,
      status: status,
      priority: 0,
      createdAt: at,
      scheduledAt: at,
      retryCount: status == 'retrying' ? 1 : 0,
      maxRetries: 3,
    );

void main() {
  final fixedNow = DateTime(2026, 11, 4, 10, 0, 12);
  final startSeconds =
      DateTime(2026, 11, 4, 10).millisecondsSinceEpoch ~/ 1000;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'language': 'pt'});
    await UserStorage.initL10n();
  });

  Future<void> pump(
    WidgetTester tester,
    List<Task> tasks, {
    Object? error,
    VoidCallback? onBack,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AgentActivityScreen(
          viewModel: AgentActivityViewModel(
            router: _FakeRouter(tasks, error: error),
            now: () => fixedNow,
          ),
          onBackToTimeline: onBack,
        ),
      ),
    );
    // Spinners never settle; one pump after the load is enough.
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('mostra tarefa em execução e tarefa com erro', (tester) async {
    await pump(tester, [
      _task('a', 'processing', at: startSeconds),
      _task('b', 'failed', type: 'comment_agent_task'),
      _task('c', 'completed'),
    ]);

    expect(find.text('Atividade em segundo plano'), findsOneWidget);
    expect(find.text('Atualizada agora'), findsOneWidget);
    expect(find.text('EM EXECUÇÃO'), findsOneWidget);
    expect(find.text('Organizar registro'), findsOneWidget);
    expect(find.text('iniciado há 12 s'), findsOneWidget);
    expect(find.text('COM ERRO'), findsOneWidget);
    expect(find.text('Gerar comentário'), findsOneWidget);
    expect(find.text('Não foi possível concluir.'), findsOneWidget);
    // tarefa concluída não é atividade
    expect(find.text('Tarefa em segundo plano'), findsNothing);
  });

  testWidgets('tarefa em nova tentativa mostra a tentativa atual',
      (tester) async {
    await pump(tester, [_task('a', 'retrying', at: startSeconds)]);
    expect(find.textContaining('Tentativa 1 de 3'), findsOneWidget);
  });

  testWidgets('sem tarefas mostra o estado vazio e volta à linha do tempo',
      (tester) async {
    var back = false;
    await pump(tester, [_task('c', 'completed')], onBack: () => back = true);

    expect(find.text('Nenhuma atividade recente'), findsOneWidget);
    expect(find.text('Atividade'), findsOneWidget);
    await tester.tap(find.text('Voltar à linha do tempo'));
    expect(back, isTrue);
  });

  testWidgets('falha ao carregar oferece tentar de novo', (tester) async {
    await pump(tester, const [], error: StateError('db'));
    expect(find.text('Não foi possível carregar a atividade.'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });
}
