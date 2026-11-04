import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/data/services/openai_auth_service.dart';
import 'package:memex/domain/models/llm_config.dart';
import 'package:memex/utils/secret_storage.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('readMigrating moves a plain prefs value into the keystore', () async {
    SharedPreferences.setMockInitialValues({'k': 'segredo'});
    final prefs = await SharedPreferences.getInstance();

    expect(await SecretStorage.readMigrating(prefs, 'k'), 'segredo');
    expect(prefs.containsKey('k'), isFalse);
    expect(await SecretStorage.read('k'), 'segredo');
    expect(await SecretStorage.readMigrating(prefs, 'k'), 'segredo');
  });

  test('OAuth tokens left in prefs are migrated on read', () async {
    SharedPreferences.setMockInitialValues({
      'openai_access_token': 'acc',
      'openai_refresh_token': 'ref',
      'openai_account_id': 'conta',
      'openai_expires_at': 1,
    });

    final tokens = await OpenAiAuthService.getSavedTokens();
    final prefs = await SharedPreferences.getInstance();

    expect(tokens?['accessToken'], 'acc');
    expect(tokens?['refreshToken'], 'ref');
    expect(prefs.containsKey('openai_access_token'), isFalse);
    expect(prefs.containsKey('openai_refresh_token'), isFalse);
    expect(await SecretStorage.read('openai_refresh_token'), 'ref');
  });

  const config = LLMConfig(
    key: 'bedrock',
    type: 'bedrock',
    modelId: 'm',
    apiKey: 'sk-chave',
    baseUrl: 'https://x.test',
    extra: {
      'accessKeyId': 'AKIA',
      'secretAccessKey': 'aws-segredo',
      'region': 'us'
    },
  );

  test('saveLLMConfigs keeps secrets out of prefs and reads them back',
      () async {
    await UserStorage.saveLLMConfigs([config]);
    final prefs = await SharedPreferences.getInstance();
    final plain = prefs.getString('llm_client_configs')!;

    expect(plain, isNot(contains('sk-chave')));
    expect(plain, isNot(contains('AKIA')));
    expect(plain, isNot(contains('aws-segredo')));
    expect(plain, contains('"region":"us"'));

    final loaded = (await UserStorage.getLLMConfigs())
        .firstWhere((c) => c.key == 'bedrock');
    expect(loaded.apiKey, 'sk-chave');
    expect(loaded.extra['secretAccessKey'], 'aws-segredo');
    expect(loaded.extra['region'], 'us');
  });

  test('a plain apiKey from an old version or backup is migrated', () async {
    SharedPreferences.setMockInitialValues({
      'llm_client_configs': jsonEncode([config.toJson()]),
    });

    final loaded = (await UserStorage.getLLMConfigs())
        .firstWhere((c) => c.key == 'bedrock');
    final prefs = await SharedPreferences.getInstance();

    expect(loaded.apiKey, 'sk-chave');
    expect(prefs.getString('llm_client_configs'), isNot(contains('sk-chave')));
    expect(
        await SecretStorage.read('llm_config_secrets'), contains('sk-chave'));
  });

  test('configs of removed Chinese providers are dropped with their keys',
      () async {
    Map<String, dynamic> cfg(String key, String type) => LLMConfig(
          key: key,
          type: type,
          modelId: 'm',
          apiKey: '',
          baseUrl: 'https://x',
        ).toJson();
    SharedPreferences.setMockInitialValues({
      'llm_client_configs': jsonEncode([
        cfg('default', LLMConfig.typeChatCompletion),
        cfg('kimi-1', 'kimi'),
        cfg('deep', 'deepseek'),
      ]),
    });
    FlutterSecureStorage.setMockInitialValues({
      'llm_config_secrets': jsonEncode({
        'default': {'apiKey': 'sk-ok'},
        'kimi-1': {'apiKey': 'sk-kimi'},
        'deep': {'apiKey': 'sk-deep'},
      }),
    });

    final configs = await UserStorage.getLLMConfigs();

    expect(configs.map((c) => c.key), ['default']);
    expect(configs.single.apiKey, 'sk-ok');
    final secrets = jsonDecode((await SecretStorage.read('llm_config_secrets'))!)
        as Map<String, dynamic>;
    expect(secrets.keys, ['default']);
  });
}
