import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/ui/core/themes/app_colors.dart';
import 'package:memex/ui/main_screen/widgets/main_menu_drawer.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'language': 'pt'});
    await UserStorage.initL10n();
  });

  Future<List<String>> openAndTap(WidgetTester tester, String label) async {
    // Tall enough that the whole list is built; the menu scrolls on a phone.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final calls = <String>[];
    final key = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        key: key,
        drawer: MainMenuDrawer(
          currentTab: 0,
          onSelectTab: (tab) => calls.add('tab$tab'),
          onOpenChat: () => calls.add('chat'),
          onOpenChatHistory: () => calls.add('history'),
          onOpenCalendar: () => calls.add('calendar'),
          onOpenTags: () => calls.add('tags'),
          onOpenTopics: () => calls.add('topics'),
          onOpenSavedViews: () => calls.add('views'),
          onOpenMemory: () => calls.add('memory'),
          onOpenActivity: () => calls.add('activity'),
          onOpenProfile: () => calls.add('profile'),
        ),
      ),
    ));
    key.currentState!.openDrawer();
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
    expect(find.byType(MainMenuDrawer), findsNothing, reason: 'drawer closes');
    return calls;
  }

  testWidgets('each destination runs its action and closes the menu',
      (tester) async {
    expect(await openAndTap(tester, 'Linha do tempo'), ['tab0']);
    expect(await openAndTap(tester, 'Conhecimento'), ['tab1']);
    expect(await openAndTap(tester, 'Calendário'), ['calendar']);
    expect(await openAndTap(tester, 'Tags'), ['tags']);
    expect(await openAndTap(tester, 'Tópicos e projetos'), ['topics']);
    expect(await openAndTap(tester, 'Visões salvas'), ['views']);
    expect(await openAndTap(tester, 'Memória'), ['memory']);
    expect(await openAndTap(tester, 'Atividade'), ['activity']);
    expect(await openAndTap(tester, 'Conversar'), ['chat']);
    expect(await openAndTap(tester, 'Histórico de chat'), ['history']);
    expect(await openAndTap(tester, 'Perfil e configurações'), ['profile']);
  });

  testWidgets('current tab is marked selected, not by color alone',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MainMenuDrawer(
          currentTab: 1,
          onSelectTab: (_) {},
          onOpenChat: () {},
          onOpenChatHistory: () {},
          onOpenCalendar: () {},
          onOpenTags: () {},
          onOpenTopics: () {},
          onOpenSavedViews: () {},
          onOpenMemory: () {},
          onOpenActivity: () {},
          onOpenProfile: () {},
        ),
      ),
    ));

    final knowledge = tester.widget<ListTile>(find.ancestor(
        of: find.text('Conhecimento'), matching: find.byType(ListTile)));
    final timeline = tester.widget<ListTile>(find.ancestor(
        of: find.text('Linha do tempo'), matching: find.byType(ListTile)));
    expect(knowledge.selected, isTrue);
    expect(timeline.selected, isFalse);
    final text = tester.widget<Text>(find.text('Conhecimento'));
    expect(text.style?.color, AppColors.primary);
    expect(text.style?.fontWeight, FontWeight.w600);
  });
}
