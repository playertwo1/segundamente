/// App flavor configuration.
///
/// Flavor is determined by the `--flavor` flag passed to `flutter run` / `flutter build`.
/// On Android, the flavor name comes from Gradle productFlavors.
/// On iOS, it comes from the Xcode scheme name.
///
/// Usage:
///   flutter run --flavor global
///   flutter run --flavor globalEarly
///   flutter run --flavor globalDev
enum AppFlavorType { global }

enum AppChannelType { stable, early, dev }

class AppFlavor {
  AppFlavor._();

  static AppFlavorType _current = AppFlavorType.global;
  static AppChannelType _channel = AppChannelType.stable;

  static AppFlavorType get current => _current;
  static AppChannelType get channel => _channel;

  static bool get isGlobal => _current == AppFlavorType.global;
  static bool get isStable => _channel == AppChannelType.stable;
  static bool get isEarly => _channel == AppChannelType.early;
  static bool get isDev => _channel == AppChannelType.dev;
  static String? get homeBadgeLabel => switch (_channel) {
        AppChannelType.stable => null,
        AppChannelType.early => 'EARLY',
        AppChannelType.dev => 'DEV',
      };
  static String get name => switch ((_current, _channel)) {
        (AppFlavorType.global, AppChannelType.dev) => 'globalDev',
        (AppFlavorType.global, AppChannelType.early) => 'globalEarly',
        _ => 'global',
      };

  /// Call once at app startup with the flavor string from `appFlavor`.
  static void init(String? flavor) {
    final normalized = flavor?.toLowerCase() ?? '';
    _current = AppFlavorType.global;

    if (normalized.contains('dev')) {
      _channel = AppChannelType.dev;
    } else if (normalized.contains('early')) {
      _channel = AppChannelType.early;
    } else {
      _channel = AppChannelType.stable;
    }
  }
}
