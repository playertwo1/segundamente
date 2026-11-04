import 'package:flutter_test/flutter_test.dart';
import 'package:memex/config/app_flavor.dart';
import 'package:memex/domain/models/llm_config.dart';

void main() {
  group('LLMConfig.duplicate', () {
    const baseConfig = LLMConfig(
      key: 'my-config',
      type: LLMConfig.typeChatCompletion,
      modelId: 'gpt-5.4',
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1',
      proxyUrl: 'http://127.0.0.1:7890',
      extra: {'reasoning_effort': 'medium'},
      temperature: 0.7,
      maxTokens: 4096,
      topP: 0.9,
    );

    test('creates copy with "_copy" suffix when no conflict', () {
      final duplicated = baseConfig.duplicate(existingKeys: ['other-config']);

      expect(duplicated.key, 'my-config_copy');
      expect(duplicated.type, baseConfig.type);
      expect(duplicated.modelId, baseConfig.modelId);
      expect(duplicated.apiKey, baseConfig.apiKey);
      expect(duplicated.baseUrl, baseConfig.baseUrl);
      expect(duplicated.proxyUrl, baseConfig.proxyUrl);
      expect(duplicated.extra, baseConfig.extra);
      expect(duplicated.temperature, baseConfig.temperature);
      expect(duplicated.maxTokens, baseConfig.maxTokens);
      expect(duplicated.topP, baseConfig.topP);
    });

    test('appends _copy_2 when "_copy" already exists', () {
      final duplicated = baseConfig.duplicate(
        existingKeys: ['my-config_copy'],
      );
      expect(duplicated.key, 'my-config_copy_2');
    });

    test('increments counter until unique key is found', () {
      final duplicated = baseConfig.duplicate(
        existingKeys: [
          'my-config_copy',
          'my-config_copy_2',
          'my-config_copy_3',
        ],
      );
      expect(duplicated.key, 'my-config_copy_4');
    });

    test('does not modify the original config', () {
      final duplicated = baseConfig.duplicate(existingKeys: []);
      expect(baseConfig.key, 'my-config');
      expect(duplicated.key, isNot(baseConfig.key));
    });

    test('handles keys with special characters gracefully', () {
      const config = LLMConfig(
        key: 'config-v1.2_test',
        type: LLMConfig.typeChatCompletion,
        modelId: 'gpt-5.6-sol',
        apiKey: 'key',
        baseUrl: 'https://api.openai.com/v1',
      );
      final duplicated = config.duplicate(existingKeys: []);
      expect(duplicated.key, 'config-v1.2_test_copy');
    });
  });

  group('removed Chinese providers (D-024)', () {
    test('are listed so stored configs can be dropped', () {
      expect(LLMConfig.removedTypes, contains('deepseek'));
      expect(LLMConfig.removedTypes, contains('kimi'));
      expect(LLMConfig.removedTypes, hasLength(7));
    });

    test('OpenRouter and Ollama lists carry no Chinese model', () {
      final all = [
        ...LLMConfig.recommendedModels(LLMConfig.typeOpenRouter),
        ...LLMConfig.recommendedModels(LLMConfig.typeOllama),
      ].join(' ');
      expect(all, isNot(matches(RegExp('qwen|deepseek|minimax|glm|mimo|kimi'))));
    });
  });

  group('current model recommendations', () {
    test('uses the canonical GPT-5.6 Sol ID for new global configurations', () {
      AppFlavor.init('global');

      expect(LLMConfig.createDefaultClientConfig().modelId, 'gpt-5.6-sol');
      expect(
        LLMConfig.recommendedModels(LLMConfig.typeChatCompletion).take(3),
        ['gpt-5.6-sol', 'gpt-5.6-terra', 'gpt-5.6-luna'],
      );
      expect(
        LLMConfig.featuredModels(LLMConfig.typeResponses),
        containsAll(['gpt-5.6-sol', 'gpt-5.6-terra', 'gpt-5.6-luna']),
      );
    });

    test('keeps OpenAI recommendations current and endpoint-specific', () {
      final chatModels = LLMConfig.recommendedModels(
        LLMConfig.typeChatCompletion,
      );
      final responseModels = LLMConfig.recommendedModels(
        LLMConfig.typeResponses,
      );

      expect(chatModels, [
        'gpt-5.6-sol',
        'gpt-5.6-terra',
        'gpt-5.6-luna',
        'gpt-5.5',
      ]);
      expect(responseModels, [...chatModels, 'gpt-5.5-pro']);
      expect(chatModels, isNot(contains('gpt-5.5-pro')));
      expect(
        [...chatModels, ...responseModels],
        isNot(contains(startsWith('gpt-5.4'))),
      );
    });

    test('includes the latest frontier models for hosted providers', () {
      final expectedFirstModel = <String, String>{
        LLMConfig.typeClaude: 'claude-fable-5',
        LLMConfig.typeBedrockClaude: 'anthropic.claude-fable-5',
        LLMConfig.typeGemini: 'gemini-3.6-flash',
        LLMConfig.typeOpenRouter: 'anthropic/claude-fable-5',
        LLMConfig.typeOllama: 'gemma4:12b',
      };

      for (final entry in expectedFirstModel.entries) {
        expect(
          LLMConfig.recommendedModels(entry.key).first,
          entry.value,
          reason: '${entry.key} should lead with its current recommendation',
        );
        expect(
          LLMConfig.featuredModels(entry.key),
          contains(entry.value),
          reason: '${entry.key} should badge its current recommendation',
        );
      }
    });

    test('recognizes multimodal models added to the recommendations', () {
      const multimodalModels = <(String, String)>[
        (LLMConfig.typeClaude, 'claude-fable-5'),
        (LLMConfig.typeOllama, 'gemma4:12b'),
      ];

      for (final (provider, model) in multimodalModels) {
        expect(
          LLMConfig.isKnownMultimodal(provider, model),
          isTrue,
          reason: '$model should be marked as multimodal',
        );
      }
    });
  });
}
