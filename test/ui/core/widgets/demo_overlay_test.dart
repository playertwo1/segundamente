import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memex/data/services/demo_service.dart';
import 'package:memex/ui/core/widgets/demo_overlay.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'language': 'en'});
    await initializeDateFormatting('en');
    await UserStorage.initL10n();
  });

  tearDown(() {
    DemoService.instance.resetForTesting();
  });

  testWidgets('recovers the spotlight when the target appears later', (
    tester,
  ) async {
    final demo = DemoService.instance;
    demo.setStepForTesting(DemoStep.tapAddButton);

    var showTarget = false;

    Widget buildApp() {
      return MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              if (showTarget)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    key: demo.addButtonKey,
                    width: 64,
                    height: 64,
                  ),
                ),
              const DemoOverlay(),
            ],
          ),
        ),
      );
    }

    await tester.pumpWidget(buildApp());
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text(UserStorage.l10n.demoTapAdd), findsNothing);
    expect(find.text(UserStorage.l10n.demoStepProgress(2)), findsOneWidget);
    expect(find.text(UserStorage.l10n.demoSkip), findsOneWidget);
    expect(find.text(UserStorage.l10n.demoContinue), findsOneWidget);

    showTarget = true;
    await tester.pumpWidget(buildApp());
    expect(demo.addButtonKey.currentContext, isNotNull);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text(UserStorage.l10n.demoTapAdd).evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.text(UserStorage.l10n.demoTapAdd), findsOneWidget);
  });

  testWidgets('tour progress groups the existing walkthrough into three steps',
      (tester) async {
    final demo = DemoService.instance;
    demo.setStepForTesting(DemoStep.welcome);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  key: demo.addButtonKey,
                  width: 64,
                  height: 64,
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  key: demo.knowledgeTabKey,
                  width: 64,
                  height: 64,
                ),
              ),
              const DemoOverlay(),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(find.text('Start tour'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    await tester.tap(find.text('Start tour'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(demo.currentStep, DemoStep.tapAddButton);
    expect(find.text('Step 2 of 3'), findsOneWidget);
    expect(find.text(UserStorage.l10n.demoContinue), findsOneWidget);

    await tester.tap(find.text(UserStorage.l10n.demoContinue));
    await tester.pump();
    expect(demo.currentStep, DemoStep.tapSend);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(UserStorage.l10n.demoContinue), findsOneWidget);

    demo.setStepForTesting(DemoStep.tapKnowledgeTab);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Step 3 of 3'), findsOneWidget);
  });
}
