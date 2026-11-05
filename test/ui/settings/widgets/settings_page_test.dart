import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/ui/core/themes/app_colors.dart';
import 'package:memex/ui/settings/widgets/settings_page.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'language': 'pt'});
    await UserStorage.initL10n();
  });

  testWidgets('settings are open rows with hairline dividers, no shadows',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
    await tester.pump();

    expect(find.text(UserStorage.l10n.languageSettings), findsOneWidget);
    expect(find.text(UserStorage.l10n.showInsightTextTitle), findsOneWidget);

    final decorations = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>();
    expect(decorations.where((d) => d.boxShadow?.isNotEmpty ?? false), isEmpty);
    expect(
      decorations.where((d) =>
          d.border is Border &&
          (d.border! as Border).bottom.color == AppColors.divider),
      isNotEmpty,
    );
  });

  testWidgets('link previews start off and the switch is remembered',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
    await tester.pump();
    final tile = find.byKey(const ValueKey('link-preview-switch'));
    await tester.ensureVisible(tile);
    expect(tester.widget<SwitchListTile>(tile).value, isFalse);
    expect(await UserStorage.isLinkPreviewEnabled(), isFalse);

    await tester.tap(tile);
    await tester.pump();
    expect(tester.widget<SwitchListTile>(tile).value, isTrue);
    expect(await UserStorage.isLinkPreviewEnabled(), isTrue);
    expect(find.text(UserStorage.l10n.linkPreviewDesc), findsOneWidget);
  });
}
