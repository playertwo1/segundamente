import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('openai auth logs do not include token values', () {
    final source = File(
      'lib/data/services/openai_auth_service.dart',
    ).readAsStringSync();
    expect(source, isNot(contains('Access Token:')));
    expect(source, isNot(contains('Refresh Token:')));
    expect(source, isNot(contains('ID Token:')));
    expect(source, isNot(contains(r'${tokenResponse.body}')));
    expect(source, isNot(contains(r'${response.body}')));
    expect(source, contains('jsonDecode(tokenResponse.body)'));
    expect(source, contains('OpenAI auth tokens stored'));
  });

  test('gemini auth errors do not include the token response body', () {
    final source = File(
      'lib/data/services/gemini_auth_service.dart',
    ).readAsStringSync();
    expect(source, isNot(contains(r'${tokenResponse.body}')));
    expect(source, isNot(contains(r'${response.body}')));
    expect(source, contains('jsonDecode(tokenResponse.body)'));
    expect(source, contains('Token exchange failed:'));
  });

  test('model list and Gemini project errors log only the status', () {
    for (final path in [
      'lib/data/services/model_list_service.dart',
      'lib/llm_client/gemini_oauth_project.dart',
      'lib/data/services/claude_auth_service.dart',
    ]) {
      expect(File(path).readAsStringSync(),
          isNot(contains(r'${response.body}')), reason: path);
    }
  });
}
