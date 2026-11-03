import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/l10n/app_localizations.dart';

void main() {
  test('welcome title names Segunda Mente in en and pt', () {
    expect(
      lookupAppLocalizations(const Locale('en')).welcomeToMemex,
      'Welcome to Segunda Mente',
    );
    expect(
      lookupAppLocalizations(const Locale('pt')).welcomeToMemex,
      'Boas-vindas à Segunda Mente',
    );
  });
}
