import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/l10n/app_localizations.dart';

void main() {
  test('en local-STT description describes cloud transcription, not raw attach',
      () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(l10n.useLocalSpeechToTextDesc, contains('transcribed by your configured cloud model'));
    expect(l10n.useLocalSpeechToTextDesc, isNot(contains('original audio is sent directly')));
  });
}
