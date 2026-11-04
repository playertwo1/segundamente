import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/ui/settings/widgets/personal_center_screen.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'language': 'pt'});
    await UserStorage.initL10n();
  });

  testWidgets('Licenças opens the license page with the GPL notice',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: PersonalCenterScreen()));
    await tester.pump();

    await tester.tap(find.text('Licenças'));
    // The license list keeps a spinner while it loads, so it never settles.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(LicensePage), findsOneWidget);
    expect(find.textContaining('GPL-3.0'), findsOneWidget);
  });
}
