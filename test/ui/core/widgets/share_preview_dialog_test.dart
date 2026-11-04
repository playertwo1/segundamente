import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/l10n/app_localizations.dart';
import 'package:memex/ui/core/widgets/share_preview_dialog.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserStorage.initL10n();
  });

  testWidgets('poster preview keeps supported format and branding controls',
      (tester) async {
    var formatChanges = 0;
    var brandingChanges = 0;
    var shares = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SharePreviewDialog(
          imageBytes: base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
          ),
          onCancel: () {},
          onShare: () => shares++,
          onToggleStyle: () => formatChanges++,
          isDetailStyle: false,
          onToggleBranding: () => brandingChanges++,
          showBranding: true,
        ),
      ),
    );
    await tester.pump();

    expect(find.text(UserStorage.l10n.sharePreviewTitle), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Image && widget.image is MemoryImage,
      ),
      findsOneWidget,
    );
    expect(
      find.text(UserStorage.l10n.sharePosterFormat(
        UserStorage.l10n.shareCardStyle,
      )),
      findsOneWidget,
    );
    expect(
      find.text(UserStorage.l10n.sharePosterBranding(
        UserStorage.l10n.sharePosterVisible,
      )),
      findsOneWidget,
    );

    await tester.tap(find.text(UserStorage.l10n.sharePosterFormat(
      UserStorage.l10n.shareCardStyle,
    )));
    await tester.tap(find.text(UserStorage.l10n.sharePosterBranding(
      UserStorage.l10n.sharePosterVisible,
    )));
    await tester.tap(find.text(UserStorage.l10n.shareNow));

    expect(formatChanges, 1);
    expect(brandingChanges, 1);
    expect(shares, 1);
  });
}
