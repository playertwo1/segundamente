import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/l10n/app_localizations.dart';
import 'package:memex/l10n/app_localizations_ext.dart';
import 'package:memex/l10n/supported_languages.dart';

void main() {
  test('every supported language tag resolves and loads l10n', () {
    for (final language in supportedLanguages) {
      final l10n = lookupAppLocalizations(language.locale);
      final ext = lookupAppLocalizationsExt(language.locale);

      expect(l10n.localeName, isNotEmpty);
      expect(ext.defaultCharacters, isNotEmpty);
      expect(ext.oauthHintTitle, isNotEmpty);
    }
  });

  test('pt locale exposes the simplified AI setup copy', () {
    const expectedCopy = <String, List<String>>{
      'pt': [
        'Usando o serviço oficial Memex',
        'Entre no Memex para usar o serviço oficial de IA.',
        'Adicione seu próprio provedor e sua chave de API.',
      ],
    };

    for (final entry in expectedCopy.entries) {
      final l10n = lookupAppLocalizations(Locale(entry.key));
      expect(l10n.aiSetupStatusMemexTitle, entry.value[0]);
      expect(l10n.aiSetupOfficialRouteDescription, entry.value[1]);
      expect(l10n.aiSetupCustomRouteDescription, entry.value[2]);
      expect(l10n.aiSetupStatusMemexDescription, isNot(contains('MemeX')));
    }
  });
}
