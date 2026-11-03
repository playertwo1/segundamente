import 'package:flutter/widgets.dart';

class SupportedLanguage {
  const SupportedLanguage({
    required this.locale,
    required this.localeTag,
    required this.nativeName,
    required this.englishName,
    required this.shortLabel,
  });

  final Locale locale;
  final String localeTag;
  final String nativeName;
  final String englishName;
  final String shortLabel;
}

const List<SupportedLanguage> supportedLanguages = <SupportedLanguage>[
  SupportedLanguage(
    locale: Locale('en'),
    localeTag: 'en',
    nativeName: 'English',
    englishName: 'English',
    shortLabel: 'EN',
  ),
  SupportedLanguage(
    locale: Locale('pt'),
    localeTag: 'pt',
    nativeName: 'Português',
    englishName: 'Portuguese',
    shortLabel: 'PT',
  ),
];

const List<Locale> supportedLanguageLocales = <Locale>[
  Locale('en'),
  Locale('pt'),
];

const List<String> supportedLanguageTags = <String>[
  'en',
  'pt',
];

SupportedLanguage supportedLanguageByTag(String localeTag) {
  return supportedLanguages.firstWhere(
    (language) => language.localeTag == localeTag,
    orElse: () => supportedLanguages.first,
  );
}
