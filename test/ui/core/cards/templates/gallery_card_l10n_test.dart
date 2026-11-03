import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memex/l10n/app_localizations.dart';
import 'package:memex/ui/core/cards/templates/textual/conversation_card.dart';
import 'package:memex/ui/core/cards/templates/visual/canvas_card.dart';
import 'package:memex/ui/core/cards/templates/visual/gallery_card.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> initLocale(String languageCode) async {
    SharedPreferences.setMockInitialValues({'language': languageCode});
    await UserStorage.initL10n();
  }

  Future<void> pumpCard(WidgetTester tester, Widget card) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: card),
      ),
    );
  }

  setUp(() async {
    await initLocale('en');
  });

  testWidgets('GalleryCard with empty image_urls shows noImages', (
    tester,
  ) async {
    await pumpCard(
      tester,
      const GalleryCard(data: {'image_urls': <String>[]}),
    );

    expect(find.text(UserStorage.l10n.noImages), findsOneWidget);
  });

  testWidgets('ConversationCard with empty messages shows noMessages', (
    tester,
  ) async {
    await pumpCard(
      tester,
      const ConversationCard(data: {'messages': <dynamic>[]}),
    );

    expect(find.text(UserStorage.l10n.noMessages), findsOneWidget);
  });

  testWidgets('CanvasCard with no image_url shows sketchContent', (
    tester,
  ) async {
    await pumpCard(
      tester,
      const CanvasCard(data: {}),
    );

    expect(find.text(UserStorage.l10n.sketchContent), findsOneWidget);
  });

  test('Portuguese template gallery uses localized labels', () async {
    await initLocale('pt');
    final sections = UserStorage.l10n.timelineTemplateGallerySections;
    expect(sections.first.title, 'Em geral');
    expect(sections.first.items.first.label, contains('Cartão Clássico'));
    expect(sections.first.items.first.label, isNot(contains('Classic Card')));
    final items = UserStorage.l10n.insightTemplateGalleryItems;
    expect(items.first.data['title'], 'Linha do tempo de hoje');
  });

  test('localized multiline gallery content contains real newlines', () async {
    await initLocale('pt');
    final textual = UserStorage.l10n.timelineTemplateGallerySections[1];
    final snippet = textual.items.first.data['text'] as String;
    final article = textual.items[1].data['body'] as String;

    expect(snippet, contains('\n\n'));
    expect(snippet, isNot(contains(r'\n')));
    expect(article, contains('\n\n'));
    expect(article, isNot(contains(r'\n')));
  });
}
