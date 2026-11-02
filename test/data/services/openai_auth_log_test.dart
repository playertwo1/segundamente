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
}
