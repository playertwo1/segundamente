import 'package:flutter_test/flutter_test.dart';
import 'package:memex/l10n/app_localizations_en.dart';
import 'package:memex/l10n/app_localizations_pt.dart';

void main() {
  test('attachedFilesMessage names files, not images, in en and pt', () {
    expect(AppLocalizationsEn().attachedFilesMessage(1), 'Sent 1 file(s)');
    expect(
      AppLocalizationsPt().attachedFilesMessage(2),
      '2 arquivo(s) enviado(s)',
    );
    expect(
        AppLocalizationsEn().attachedFilesMessage(1), isNot(contains('image')));
  });
}
