import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/db/app_database.dart';
import 'package:memex/l10n/app_localizations.dart';
import 'package:memex/ui/core/themes/app_colors.dart';
import 'package:memex/ui/core/themes/app_theme.dart';
import 'package:memex/ui/main_screen/widgets/action_center_sheet.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'language': 'en'});
    await UserStorage.initL10n();
  });

  testWidgets('ActionCenterSheet fills the screen with the AMOLED surface', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    AppDatabase.setTestInstance(database);
    addTearDown(database.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.amoledTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ActionCenterSheet(loadPendingAttachments: () async => []),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(UserStorage.l10n.actionCenterTitle), findsOneWidget);
    expect(find.text(UserStorage.l10n.noPendingActions), findsOneWidget);

    final sheet = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(ActionCenterSheet),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = sheet.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.background);
    expect(decoration.borderRadius, isNull);
    expect(decoration.boxShadow, isNull);
  });
}
