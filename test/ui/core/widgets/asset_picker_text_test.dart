import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/ui/core/widgets/asset_picker_text.dart';
import 'package:memex/ui/core/widgets/reliable_asset_picker.dart';

void main() {
  test('Portuguese gets Portuguese strings, never the Chinese default', () {
    final text = assetPickerTextFor(const Locale('pt', 'BR'));
    expect(text.confirm, 'Confirmar');
    expect(text.cancel, 'Cancelar');
    expect(text.emptyList, 'Lista vazia');
  });

  test('English stays English; unknown languages fall back to English', () {
    expect(assetPickerTextFor(const Locale('en')).confirm, 'Confirm');
    expect(assetPickerTextFor(const Locale('es')).confirm, 'Confirm');
    expect(assetPickerTextFor(null).confirm, 'Confirm');
  });

  test('the picker config carries the locale strings', () {
    final config = buildPlatformDefaultImagePickerConfig(
      maxAssets: 1,
      locale: const Locale('pt'),
    );
    expect(config.textDelegate?.confirm, 'Confirmar');
  });
}
