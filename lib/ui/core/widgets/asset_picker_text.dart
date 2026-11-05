import 'package:flutter/widgets.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

/// Portuguese strings for the photo picker; the package has none and falls
/// back to Chinese for any language it does not know.
class PortugueseAssetPickerTextDelegate extends AssetPickerTextDelegate {
  const PortugueseAssetPickerTextDelegate();

  @override
  String get languageCode => 'pt';

  @override
  String? get scriptCode => null;

  @override
  String get confirm => 'Confirmar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get edit => 'Editar';

  @override
  String get livePhotoIndicator => 'AO VIVO';

  @override
  String get loadFailed => 'Falha ao carregar';

  @override
  String get original => 'Original';

  @override
  String get preview => 'Prévia';

  @override
  String get select => 'Selecionar';

  @override
  String get emptyList => 'Lista vazia';

  @override
  String get unSupportedAssetType => 'Tipo de arquivo não suportado';

  @override
  String get unableToAccessAll => 'Não foi possível acessar todos os arquivos';

  @override
  String get viewingLimitedAssetsTip =>
      'O app só acessa parte dos arquivos e álbuns';

  @override
  String get changeAccessibleLimitedAssets =>
      'Toque para escolher o que o app pode acessar';

  @override
  String get accessAllTip =>
      'Você deixou o app acessar só parte dos arquivos do aparelho. '
      'Recomendamos permitir o acesso a "todos os arquivos".';

  @override
  String get goToSystemSettings => 'Abrir configurações do sistema';

  @override
  String get accessLimitedAssets => 'Continuar com acesso parcial';

  @override
  String get accessiblePathName => 'Arquivos acessíveis';

  @override
  String get sTypeAudioLabel => 'Áudio';

  @override
  String get sTypeImageLabel => 'Imagem';

  @override
  String get sTypeVideoLabel => 'Vídeo';

  @override
  String get sTypeOtherLabel => 'Outro arquivo';

  @override
  String get sActionPlayHint => 'tocar';

  @override
  String get sActionPreviewHint => 'ver prévia';

  @override
  String get sActionSelectHint => 'selecionar';

  @override
  String get sActionSwitchPathLabel => 'trocar álbum';

  @override
  String get sActionUseCameraHint => 'usar a câmera';

  @override
  String get sNameDurationLabel => 'duração';

  @override
  String get sUnitAssetCountLabel => 'quantidade';
}

/// Picker strings for [locale]: Portuguese for `pt`, the package's own for the
/// languages it knows, and English (not Chinese) for anything else.
AssetPickerTextDelegate assetPickerTextFor(Locale? locale) {
  if (locale?.languageCode == 'pt') {
    return const PortugueseAssetPickerTextDelegate();
  }
  return assetPickerTextDelegateFromLocale(
    locale,
    fallback: const EnglishAssetPickerTextDelegate(),
  );
}

/// Album name shown in the picker: the system's "Recent" album in Portuguese.
String Function(AssetPathEntity)? assetPathNameFor(Locale? locale) {
  if (locale?.languageCode != 'pt') return null;
  return (path) => path.isAll ? 'Recentes' : path.name;
}
