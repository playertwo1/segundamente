import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/ui/core/themes/app_colors.dart';
import 'package:memex/ui/main_screen/widgets/radial_menu.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'language': 'pt'});
    await UserStorage.initL10n();
  });

  testWidgets(
      'quick record: dark veil, amber mic hub, live transcript and cancel',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            RadialMenu(
              items: const [],
              center: const Offset(300, 600),
              visible: true,
              onItemSelected: (_) {},
              onCancel: () {},
              transcriptText: 'Amanhã quero caminhar cedo',
            ),
          ],
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 400));

    final hub = tester.widget<Container>(find
        .ancestor(
            of: find.byIcon(Icons.mic_none), matching: find.byType(Container))
        .first);
    final deco = hub.decoration! as BoxDecoration;
    expect(deco.color, AppColors.primary);
    expect(deco.boxShadow, isNull);
    expect(tester.widget<Icon>(find.byIcon(Icons.mic_none)).color,
        AppColors.onPrimary);

    expect(find.textContaining('Amanhã quero caminhar cedo'), findsOneWidget);
    expect(find.text(UserStorage.l10n.cancel), findsOneWidget);

    // The veil darkens the screen instead of washing it white.
    final veils = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) => c.color != null && c.color!.a > 0.5);
    expect(veils.every((c) => c.color!.r < 0.1), isTrue);
    expect(veils, isNotEmpty);
  });
}
