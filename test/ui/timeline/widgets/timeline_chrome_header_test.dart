import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/data/repositories/memex_router.dart';
import 'package:memex/data/services/event_bus_service.dart';
import 'package:memex/ui/character/view_models/persona_avatar_viewmodel.dart';
import 'package:memex/ui/core/themes/app_colors.dart';
import 'package:memex/ui/core/widgets/character_avatar.dart';
import 'package:memex/ui/core/widgets/memex_brand_title.dart';
import 'package:memex/ui/insight/view_models/insight_viewmodel.dart';
import 'package:memex/ui/timeline/view_models/timeline_viewmodel.dart';
import 'package:memex/ui/timeline/widgets/timeline_screen.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    EventBusService.instance.clearHandlers();
    SharedPreferences.setMockInitialValues({'language': 'en'});
    await UserStorage.initL10n();
  });

  tearDown(EventBusService.instance.clearHandlers);

  testWidgets('chrome header stays mounted when the timeline list notifies',
      (tester) async {
    final timeline = TimelineViewModel.forTest(autoLoad: false);
    final insight = InsightViewModel(router: MemexRouter());
    final persona = PersonaAvatarViewModel(router: MemexRouter());
    addTearDown(timeline.dispose);
    addTearDown(insight.dispose);
    addTearDown(persona.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimelineScreen(
            viewModel: timeline,
            insightViewModel: insight,
            personaAvatarViewModel: persona,
            onInputTap: () {},
          ),
        ),
      ),
    );

    expect(find.byType(MemexBrandTitle), findsOneWidget);
    expect(find.byTooltip('Search'), findsOneWidget);
    final userAvatar = tester.widget<CharacterAvatar>(
      find.byWidgetPredicate(
        (widget) => widget is CharacterAvatar && widget.size == 32,
      ),
    );
    expect(userAvatar.backgroundColor, AppColors.textPrimary);
    timeline.notifyListeners();
    await tester.pump();
    expect(find.byType(MemexBrandTitle), findsOneWidget);
  });

  testWidgets('header menu and chat entry call their callbacks',
      (tester) async {
    final timeline = TimelineViewModel.forTest(autoLoad: false);
    final insight = InsightViewModel(router: MemexRouter());
    final persona = PersonaAvatarViewModel(router: MemexRouter());
    addTearDown(timeline.dispose);
    addTearDown(insight.dispose);
    addTearDown(persona.dispose);
    var menuTaps = 0;
    var chatTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimelineScreen(
            viewModel: timeline,
            insightViewModel: insight,
            personaAvatarViewModel: persona,
            onInputTap: () => chatTaps++,
            onMenuTap: () => menuTaps++,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip(UserStorage.l10n.navMenu));
    await tester.tap(find.text(UserStorage.l10n.chatWithSegundaMente));
    await tester.pump();

    expect(menuTaps, 1);
    expect(chatTaps, 1);
  });

  testWidgets('profile avatar is a labelled button with a 48dp touch target',
      (tester) async {
    final timeline = TimelineViewModel.forTest(autoLoad: false);
    final insight = InsightViewModel(router: MemexRouter());
    final persona = PersonaAvatarViewModel(router: MemexRouter());
    addTearDown(timeline.dispose);
    addTearDown(insight.dispose);
    addTearDown(persona.dispose);
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimelineScreen(
            viewModel: timeline,
            insightViewModel: insight,
            personaAvatarViewModel: persona,
            onInputTap: () {},
          ),
        ),
      ),
    );

    final label = find.bySemanticsLabel(UserStorage.l10n.navProfile);
    expect(label, findsOneWidget);
    expect(
      tester.getSemantics(label),
      isSemantics(isButton: true, hasTapAction: true),
    );
    final target = find.ancestor(
      of: find.byWidgetPredicate(
        (widget) => widget is CharacterAvatar && widget.size == 32,
      ),
      matching: find.byType(SizedBox),
    );
    expect(
      target.evaluate().any((e) {
        final size = tester.getSize(find.byWidget(e.widget));
        return size.width >= 48 && size.height >= 48;
      }),
      isTrue,
    );
    handle.dispose();
  });
}
