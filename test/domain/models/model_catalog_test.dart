import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:memex/domain/models/llm_config.dart';
import 'package:memex/domain/models/model_catalog.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ModelCatalog', () {
    test('marks recommended, account and manual ids', () {
      const recommended = ['gpt-5.6-sol', 'gpt-5.6-terra'];
      final catalog = ModelCatalog.empty(
        providerType: LLMConfig.typeChatCompletion,
        baseUrl: 'https://api.openai.com/v1/',
      ).rememberFetch(
        const ['gpt-5.6-sol', 'account-only-model'],
        DateTime.utc(2026, 11, 2),
      ).rememberManual('my-manual-model');

      expect(catalog.baseUrl, 'https://api.openai.com/v1');
      expect(
        catalog.statusOf('gpt-5.6-sol', recommended),
        ModelAvailability.accessible,
      );
      expect(
        catalog.statusOf('gpt-5.6-terra', recommended),
        ModelAvailability.supported,
      );
      expect(
        catalog.statusOf('account-only-model', recommended),
        ModelAvailability.accessible,
      );
      expect(
        catalog.statusOf('my-manual-model', recommended),
        ModelAvailability.untested,
      );
      expect(catalog.manualIdsOutside(const ['gpt-5.6-sol']), [
        'my-manual-model',
      ]);
    });

    test('keeps a manual id and its verdict when the account list changes', () {
      final firstFetch = DateTime.utc(2026, 11, 2, 1);
      final catalog = ModelCatalog.empty(
        providerType: LLMConfig.typeChatCompletion,
        baseUrl: 'https://llm.example.test/v1',
      )
          .rememberManual('my-manual-model')
          .rememberVerdict(
            'my-manual-model',
            ModelCapability.vision,
            CapabilityVerdict.no,
          )
          .rememberFetch(const ['gpt-5.6-sol'], firstFetch);

      final sameFetch = catalog.rememberFetch(
        const ['gpt-5.6-sol'],
        DateTime.utc(2026, 11, 2, 2),
      );
      expect(sameFetch.fetchedAt, firstFetch);

      final next = catalog.rememberFetch(
        const ['gpt-5.6-terra'],
        DateTime.utc(2026, 11, 2, 3),
      );
      expect(next.manualIds, contains('my-manual-model'));
      expect(
        next.matrixFor('my-manual-model').verdicts[ModelCapability.vision],
        CapabilityVerdict.no,
      );
      expect(
        next.matrixFor('my-manual-model').missing,
        [ModelCapability.vision],
      );
    });

    test('does not let an unknown verdict erase a previous probe', () {
      final catalog = ModelCatalog.empty(
        providerType: LLMConfig.typeGemini,
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
      ).rememberVerdict(
        'gemini-3.6-flash',
        ModelCapability.text,
        CapabilityVerdict.yes,
      );

      final again = catalog.rememberVerdict(
        'gemini-3.6-flash',
        ModelCapability.text,
        CapabilityVerdict.unknown,
      );

      expect(
        again.matrixFor('gemini-3.6-flash').verdicts[ModelCapability.text],
        CapabilityVerdict.yes,
      );
    });

    test('round-trips json and drops a different schema version', () {
      final catalog = ModelCatalog.empty(
        providerType: LLMConfig.typeOllama,
        baseUrl: 'http://127.0.0.1:11434/v1',
      ).rememberManual('llama-local');
      final restored = ModelCatalog.fromJson(catalog.toJson());
      expect(restored?.manualIds, ['llama-local']);
      expect(restored?.version, ModelCatalog.schemaVersion);

      final stale = catalog.toJson()..['version'] = 99;
      expect(ModelCatalog.fromJson(stale), isNull);
    });

    test('persists one bucket per provider and base URL', () async {
      SharedPreferences.setMockInitialValues({});
      final openai = ModelCatalog.empty(
        providerType: LLMConfig.typeChatCompletion,
        baseUrl: 'https://api.openai.com/v1',
      ).rememberManual('my-manual-model');
      final local = ModelCatalog.empty(
        providerType: LLMConfig.typeChatCompletion,
        baseUrl: 'http://127.0.0.1:11434/v1',
      ).rememberFetch(const ['qwen3.5:9b'], DateTime.utc(2026, 11, 2));

      await UserStorage.saveModelCatalog(openai);
      await UserStorage.saveModelCatalog(local);

      final loadedOpenAi = await UserStorage.loadModelCatalog(
        LLMConfig.typeChatCompletion,
        'https://api.openai.com/v1/',
      );
      final loadedLocal = await UserStorage.loadModelCatalog(
        LLMConfig.typeChatCompletion,
        'http://127.0.0.1:11434/v1',
      );

      expect(loadedOpenAi?.manualIds, ['my-manual-model']);
      expect(loadedLocal?.fetchedIds, ['qwen3.5:9b']);
      expect(loadedLocal?.fetchedAt, DateTime.utc(2026, 11, 2));
    });

    test('drops a cache written with an older store version', () async {
      SharedPreferences.setMockInitialValues({
        'model_catalog_v1': jsonEncode({
          'version': 0,
          'buckets': {
            'chat_completion|https://api.openai.com/v1': {
              'version': 1,
              'providerType': 'chat_completion',
              'baseUrl': 'https://api.openai.com/v1',
              'manualIds': ['should-not-load'],
            },
          },
        }),
      });

      expect(
        await UserStorage.loadModelCatalog(
          LLMConfig.typeChatCompletion,
          'https://api.openai.com/v1',
        ),
        isNull,
      );
    });
  });

  group('ModelCapabilityJudge', () {
    test('accepts a JSON object and rejects prose', () {
      expect(
        ModelCapabilityJudge.judge(
          capability: ModelCapability.json,
          transportOk: true,
          text: '```json\n{"ok":true}\n```',
        ),
        CapabilityVerdict.yes,
      );
      expect(
        ModelCapabilityJudge.judge(
          capability: ModelCapability.json,
          transportOk: true,
          text: 'ok',
        ),
        CapabilityVerdict.no,
      );
    });

    test('streaming needs at least one text chunk', () {
      expect(
        ModelCapabilityJudge.judge(
          capability: ModelCapability.streaming,
          transportOk: true,
          text: 'ok',
          textChunks: 2,
        ),
        CapabilityVerdict.yes,
      );
      expect(
        ModelCapabilityJudge.judge(
          capability: ModelCapability.streaming,
          transportOk: true,
          text: '',
          textChunks: 0,
        ),
        CapabilityVerdict.no,
      );
    });

    test('a timeout stays unknown and a named miss is no', () {
      expect(
        ModelCapabilityJudge.fromError(
          ModelCapability.vision,
          'Request timed out (30s)',
        ),
        CapabilityVerdict.unknown,
      );
      expect(
        ModelCapabilityJudge.fromError(
          ModelCapability.audio,
          'unsupported audio input',
        ),
        CapabilityVerdict.no,
      );
      expect(
        ModelCapabilityJudge.fromError(
          ModelCapability.text,
          'unsupported audio input',
        ),
        CapabilityVerdict.unknown,
      );
    });
  });
}
