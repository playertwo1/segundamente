import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:memex/data/services/speech_transcription_service.dart';
import 'package:memex/llm_client/codex_responses_client.dart';

void main() {
  final client = CodexResponsesClient(accessToken: 'tok', accountId: 'acc');

  test('transcribes through the ChatGPT endpoint with the OAuth headers',
      () async {
    http.BaseRequest? seen;
    final result = await http.runWithClient(
      () => SpeechTranscriptionService.instance
          .transcribeViaChatGpt(client, [1, 2, 3], mimeType: 'audio/mp4'),
      () => MockClient.streaming((request, body) async {
        seen = request;
        return http.StreamedResponse(
          Stream.value(utf8.encode('{"text":" Olá, mundo "}')),
          200,
        );
      }),
    );

    expect(result.text, 'Olá, mundo');
    expect(seen!.url.toString(), 'https://chatgpt.com/backend-api/transcribe');
    expect(seen!.headers['Authorization'], 'Bearer tok');
    expect(seen!.headers['ChatGPT-Account-Id'], 'acc');
  });

  test('throws when the endpoint rejects the request', () async {
    await expectLater(
      http.runWithClient(
        () => SpeechTranscriptionService.instance
            .transcribeViaChatGpt(client, [1], mimeType: 'audio/wav'),
        () => MockClient.streaming((request, body) async =>
            http.StreamedResponse(Stream.value(utf8.encode('{}')), 403)),
      ),
      throwsException,
    );
  });
}
