import 'dart:convert';
import 'dart:io';

import 'package:dart_agent_core/dart_agent_core.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/agent/super_agent/subagent/super_agent_child.dart';
import 'package:memex/data/services/file_system_service.dart';
import 'package:memex/data/services/global_event_bus.dart';
import 'package:memex/data/services/knowledge_insight_trigger_service.dart';
import 'package:memex/data/services/local_task_executor.dart';
import 'package:memex/data/services/task_handlers/knowledge_insight_handler.dart';
import 'package:memex/db/app_database.dart';
import 'package:memex/domain/models/card_model.dart';
import 'package:memex/domain/models/insight_trigger.dart';
import 'package:memex/domain/models/system_event.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final originalResources = KnowledgeInsightTaskDeps.resources;
  late AppDatabase db;
  late Directory tempRoot;
  late String userId;
  late LocalTaskExecutor executor;
  late KnowledgeInsightTriggerService trigger;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    AppDatabase.setTestInstance(db);
    SharedPreferences.setMockInitialValues({});
    await UserStorage.initL10n();
    userId = 'insight_trigger_${DateTime.now().microsecondsSinceEpoch}';
    await UserStorage.saveUser(userId);
    tempRoot = await Directory.systemTemp.createTemp('memex_insight_trigger_');
    await FileSystemService.init(tempRoot.path);
    executor = LocalTaskExecutor.forTesting(db: db);
    trigger = KnowledgeInsightTriggerService(
      executor: executor,
      debounce: Duration.zero,
    );
  });

  tearDown(() async {
    KnowledgeInsightTaskDeps.runChild = runSuperAgentChild;
    KnowledgeInsightTaskDeps.resources = originalResources;
    await executor.stop();
    for (var attempt = 0; await tempRoot.exists(); attempt++) {
      try {
        await tempRoot.delete(recursive: true);
      } on PathAccessException {
        if (attempt >= 20) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
    await db.close();
  });

  var counter = 0;
  Future<String> saveRecord(
    String text, {
    List<UiConfig> ui = const [],
    List<String> tags = const ['obra'],
  }) async {
    final factId = '2026/11/05.md#ts_${++counter}';
    await FileSystemService.instance.safeWriteCardFile(
      userId,
      factId,
      CardData(
        factId: factId,
        timestamp: 1762300000 + counter,
        status: 'completed',
        tags: tags,
        uiConfigs: ui,
        fact: text,
      ),
    );
    return factId;
  }

  SystemEvent<UserInputSubmittedPayload> saved(String factId) => SystemEvent(
        type: SystemEventTypes.userInputSubmitted,
        source: 'test',
        payload: UserInputSubmittedPayload(
          factId: factId,
          assetPaths: const [],
          combinedText: '',
          markdownEntry: '',
          createdAtTs: 1762300000,
          pkmCreatedAtTs: 1762300000,
        ),
      );

  Future<List<Task>> insightTasks() =>
      (db.select(db.tasks)..where((t) => t.type.equals(insightTaskType))).get();

  List<String> idsOf(Task task) =>
      ((jsonDecode(task.payload!) as Map)['fact_ids'] as List).cast<String>();

  group('trigger after a confirmed save', () {
    test('a saved record queues one analysis and does no model work itself',
        () async {
      var ran = false;
      KnowledgeInsightTaskDeps.runChild = ({
        required config,
        required client,
        required modelConfig,
        required userId,
      }) async {
        ran = true;
        throw StateError('must not run while queueing');
      };
      final id = await saveRecord('concreto da laje, 3 sacos');

      expect(await trigger.onRecordSaved(userId, saved(id)), isTrue);

      final tasks = await insightTasks();
      expect(tasks, hasLength(1));
      expect(tasks.single.status, 'pending');
      expect(idsOf(tasks.single), [id]);
      expect(ran, isFalse);
    });

    test('publishing the capture event on the bus queues the analysis',
        () async {
      final bus = GlobalEventBus.forTesting(executor);
      registerKnowledgeInsightTrigger(bus, service: trigger);
      final id = await saveRecord('cimento e areia para o reboco');
      final summary = await saveRecord(
        '',
        ui: const [UiConfig(templateId: 'insight_summary', data: {})],
        tags: const ['insight'],
      );

      await bus.publish(userId: userId, event: saved(id));
      await bus.publish(userId: userId, event: saved(summary));

      final tasks = await insightTasks();
      expect(tasks, hasLength(1));
      expect(idsOf(tasks.single), [id]);
    });

    test('a record that is not on disk queues nothing', () async {
      expect(
        await trigger.onRecordSaved(userId, saved('2026/11/05.md#ts_404')),
        isFalse,
      );
      expect(await insightTasks(), isEmpty);
    });

    test('a burst of records shares one task, each id once', () async {
      final a = await saveRecord('primeira parte da conversa');
      final b = await saveRecord('segunda parte da conversa');
      final c = await saveRecord('terceira parte da conversa');

      for (final id in [a, b, c, b]) {
        await trigger.onRecordSaved(userId, saved(id));
      }

      final tasks = await insightTasks();
      expect(tasks, hasLength(1));
      expect(idsOf(tasks.single), [a, b, c]);
    });

    test('a record is handed to an analysis at most once, even after it ran',
        () async {
      final id = await saveRecord('orcamento do pedreiro');
      await trigger.onRecordSaved(userId, saved(id));
      await (db.update(db.tasks)).write(
        const TasksCompanion(status: Value('completed')),
      );

      expect(await trigger.onRecordSaved(userId, saved(id)), isFalse);
      expect(await insightTasks(), hasLength(1));
    });

    test(
        'insight summaries, empty records and insight-tagged cards are ignored',
        () async {
      final summary = await saveRecord(
        '',
        ui: const [
          UiConfig(templateId: 'insight_summary', data: {'added': []}),
        ],
        tags: const ['insight'],
      );
      final tagged =
          await saveRecord('texto qualquer', tags: const ['insight']);
      final templated = await saveRecord(
        'resumo',
        ui: const [UiConfig(templateId: 'insight_summary', data: {})],
      );
      final empty = await saveRecord('   ');

      for (final id in [summary, tagged, templated, empty]) {
        expect(await trigger.onRecordSaved(userId, saved(id)), isFalse,
            reason: id);
      }
      expect(await insightTasks(), isEmpty);
    });
  });

  group('analysis task', () {
    SuperAgentChildResult result(SuperAgentChildStatus status) =>
        SuperAgentChildResult(
          childName: 'knowledge_insight_auto',
          status: status,
          summary: status.name,
          error: status == SuperAgentChildStatus.failed ? 'model down' : null,
        );

    void fakeModel() {
      KnowledgeInsightTaskDeps.resources = () async =>
          (client: _ToolCallClient.none(), model: ModelConfig(model: 'fake'));
    }

    test('with too few saved records the model is never called', () async {
      fakeModel();
      var calls = 0;
      KnowledgeInsightTaskDeps.runChild = ({
        required config,
        required client,
        required modelConfig,
        required userId,
      }) async {
        calls++;
        return result(SuperAgentChildStatus.completed);
      };
      final one = await saveRecord('so um registro');
      final two = await saveRecord('outro registro');

      await handleKnowledgeInsightImpl(
        userId,
        {
          'fact_ids': [one, two]
        },
        TaskContext(taskId: 't', taskType: insightTaskType),
      );

      expect(calls, 0);
    });

    test(
        'with enough records it runs the insight skill read-only on the new ids',
        () async {
      fakeModel();
      SuperAgentChildConfig? seen;
      KnowledgeInsightTaskDeps.runChild = ({
        required config,
        required client,
        required modelConfig,
        required userId,
      }) async {
        seen = config;
        return result(SuperAgentChildStatus.noOp);
      };
      await saveRecord('registro 1');
      await saveRecord('registro 2');
      final fresh = await saveRecord('registro 3');

      await handleKnowledgeInsightImpl(
        userId,
        {
          'fact_ids': [fresh]
        },
        TaskContext(taskId: 't', taskType: insightTaskType),
      );

      expect(seen, isNotNull);
      expect(seen!.toolProfile, ChildToolProfile.read);
      expect(seen!.skills.map((s) => s.name), ['update_knowledge_insight']);
      expect(seen!.taskBrief, contains(fresh));
      expect(seen!.taskBrief, contains('no_op'));
      expect(seen!.contextPacket['new_fact_ids'], [fresh]);
    });

    test('a failed run throws so the queue retries it', () async {
      fakeModel();
      KnowledgeInsightTaskDeps.runChild = ({
        required config,
        required client,
        required modelConfig,
        required userId,
      }) async =>
          result(SuperAgentChildStatus.failed);
      await saveRecord('registro 1');
      await saveRecord('registro 2');
      final fresh = await saveRecord('registro 3');

      executor.registerHandler(insightTaskType, handleKnowledgeInsightImpl);
      await trigger.onRecordSaved(userId, saved(fresh));
      await executor.drainAvailableTasks(
        userId: userId,
        maxDuration: const Duration(seconds: 5),
      );

      final task = (await insightTasks()).single;
      expect(task.status, 'retrying');
      expect(task.retryCount, 1);
      expect(task.error, contains('model down'));
    });
  });

  group('capture to insight', () {
    test('a saved record becomes an insight backed by its records, once',
        () async {
      final first = await saveRecord('concreto da laje: 12 sacos, R\$ 480');
      final second = await saveRecord('pedreiro cobrou R\$ 900 pela laje');
      final third = await saveRecord('ferragem da laje: R\$ 1.200');
      final scripted = _ToolCallClient(
        toolName: 'save_knowledge_insight_cards',
        arguments: {
          'cards': [
            {
              'id': 'custo_da_laje',
              'template_id': 'summary_card_v1',
              'title': 'Custo da laje',
              'insight': 'Três registros somam os gastos com a laje.',
              'type': 'add',
              'data': {'insight_title': 'Custo da laje'},
              'related_facts': [first, second, third],
              'tags': ['obra'],
            },
          ],
        },
      );
      KnowledgeInsightTaskDeps.resources =
          () async => (client: scripted, model: ModelConfig(model: 'fake'));
      executor.registerHandler(
        insightTaskType,
        handleKnowledgeInsightImpl,
        concurrencyPolicy: TaskConcurrencyPolicy.byUser(),
      );

      // Capture finishes: three records saved, each announced.
      for (final id in [first, second, third]) {
        await trigger.onRecordSaved(userId, saved(id));
      }
      expect(await insightTasks(), hasLength(1));

      await executor.drainAvailableTasks(
        userId: userId,
        maxDuration: const Duration(seconds: 20),
      );

      final task = (await insightTasks()).single;
      expect(task.status, 'completed');

      final insight = await FileSystemService.instance
          .readKnowledgeInsightCard(userId, 'custo_da_laje');
      expect(insight, isNotNull);
      expect(insight!['related_facts'], [first, second, third]);

      // The announcement card was written, and it does not start anything.
      final timeline = await db.cardDao.getCards(tags: ['insight'], limit: 10);
      expect(timeline, hasLength(1));
      expect(
        await trigger.onRecordSaved(userId, saved(timeline.single.factId)),
        isFalse,
      );

      // The same records, announced again, are not analysed again.
      for (final id in [first, second, third]) {
        expect(await trigger.onRecordSaved(userId, saved(id)), isFalse);
      }
      expect(await insightTasks(), hasLength(1));
      expect(scripted.calls, 2); // one tool call + the closing message
    });

    test('with no evidence the run saves nothing and writes no summary',
        () async {
      await saveRecord('registro A');
      await saveRecord('registro B');
      final fresh = await saveRecord('registro C');
      final scripted = _ToolCallClient.none(finalText: 'no_op: nothing links');
      KnowledgeInsightTaskDeps.resources =
          () async => (client: scripted, model: ModelConfig(model: 'fake'));
      executor.registerHandler(insightTaskType, handleKnowledgeInsightImpl);
      await trigger.onRecordSaved(userId, saved(fresh));

      await executor.drainAvailableTasks(
        userId: userId,
        maxDuration: const Duration(seconds: 20),
      );

      expect((await insightTasks()).single.status, 'completed');
      expect(await FileSystemService.instance.listKnowledgeInsightCards(userId),
          isEmpty);
      expect(await db.cardDao.getCards(tags: ['insight'], limit: 10), isEmpty);
    });
  });
}

/// Scripted model: optionally calls one tool, then answers [finalText].
class _ToolCallClient extends LLMClient {
  _ToolCallClient({required this.toolName, required this.arguments})
      : finalText = 'done';

  _ToolCallClient.none({this.finalText = 'done'})
      : toolName = null,
        arguments = const {};

  final String? toolName;
  final Map<String, dynamic> arguments;
  final String finalText;
  var calls = 0;

  @override
  Future<ModelMessage> generate(
    List<LLMMessage> messages, {
    List<Tool>? tools,
    ToolChoice? toolChoice,
    required ModelConfig modelConfig,
    bool? jsonOutput,
    CancelToken? cancelToken,
  }) async {
    calls++;
    if (toolName != null && calls == 1) {
      return ModelMessage(
        model: modelConfig.model,
        stopReason: 'tool_calls',
        functionCalls: [
          FunctionCall(
            id: 'call_1',
            name: toolName!,
            arguments: jsonEncode(arguments),
          ),
        ],
      );
    }
    return ModelMessage(
      model: modelConfig.model,
      stopReason: 'stop',
      textOutput: finalText,
    );
  }

  @override
  Future<Stream<StreamingMessage>> stream(
    List<LLMMessage> messages, {
    List<Tool>? tools,
    ToolChoice? toolChoice,
    required ModelConfig modelConfig,
    bool? jsonOutput,
    CancelToken? cancelToken,
  }) async {
    throw UnsupportedError('Streaming is not used by this test client.');
  }
}
