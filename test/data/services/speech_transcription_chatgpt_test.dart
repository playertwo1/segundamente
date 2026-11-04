import 'dart:convert';
import 'dart:typed_data';

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

  group('splitWavForUpload', () {
    Uint8List wavOf(int pcmBytes) =>
        Uint8List.fromList([...List.filled(44, 0), ...List.filled(pcmBytes, 7)]);

    test('keeps a recording under the chunk size whole', () {
      final wav = wavOf(32000 * 5);
      expect(SpeechTranscriptionService.splitWavForUpload(wav), [wav]);
    });

    test('splits a long recording into valid WAVs that cover all the audio', () {
      // 25 s with 10 s chunks -> 10 s, 10 s, 5 s.
      final chunks = SpeechTranscriptionService.splitWavForUpload(
        wavOf(32000 * 25),
        chunkSeconds: 10,
      );
      expect(chunks.map((c) => c.length - 44), [320000, 320000, 160000]);
      for (final c in chunks) {
        final data = ByteData.sublistView(Uint8List.fromList(c));
        expect(String.fromCharCodes(c.sublist(0, 4)), 'RIFF');
        expect(data.getUint32(40, Endian.little), c.length - 44);
      }
    });
  });
}
