import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('UserStorage locale resolution', () {
    test('keeps supported English and Portuguese locales', () {
      for (final code in ['en', 'pt']) {
        final locale = UserStorage.resolveToSupportedLocale(Locale(code));

        expect(locale.languageCode, code);
      }
    });

    test('parses locale tags with script codes', () {
      final locale = UserStorage.localeFromTag('sr_Latn');

      expect(locale.languageCode, 'sr');
      expect(locale.scriptCode, 'Latn');
      expect(UserStorage.localeTag(locale), 'sr_Latn');
    });

    test('falls back removed and unsupported locales to English', () {
      for (final locale in [
        const Locale('nl'),
        const Locale('de'),
        const Locale('zh'),
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      ]) {
        expect(UserStorage.resolveToSupportedLocale(locale).languageCode, 'en');
      }
    });
  });

  group('UserStorage Memex Agent notification permission marker', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('is scoped to the active user', () async {
      await UserStorage.saveUser('user-a');

      expect(
        await UserStorage.hasPromptedMemexAgentNotificationPermission(),
        isFalse,
      );

      await UserStorage.setMemexAgentNotificationPermissionPrompted();
      expect(
        await UserStorage.hasPromptedMemexAgentNotificationPermission(),
        isTrue,
      );

      await UserStorage.saveUser('user-b');
      expect(
        await UserStorage.hasPromptedMemexAgentNotificationPermission(),
        isFalse,
      );

      await UserStorage.saveUser('user-a');
      expect(
        await UserStorage.hasPromptedMemexAgentNotificationPermission(),
        isTrue,
      );
    });

    test('does not set a marker without a user', () async {
      await UserStorage.setMemexAgentNotificationPermissionPrompted();

      expect(
        await UserStorage.hasPromptedMemexAgentNotificationPermission(),
        isFalse,
      );
    });

    test('classifies the permission prompt marker as device-local', () {
      expect(
        UserStorage.isDeviceLocalPreferenceKey(
          'memex_agent_notification_permission_prompted_user-a',
        ),
        isTrue,
      );
      expect(
        UserStorage.isDeviceLocalPreferenceKey('language'),
        isFalse,
      );
    });
  });
}
