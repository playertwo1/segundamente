import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memex/domain/models/character_model.dart';
import 'package:memex/domain/models/character_emoji.dart';
import 'package:memex/ui/character/widgets/persona_chat_screen.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({'language': 'pt'});
    await UserStorage.initL10n();
  });

  test('loading older chat does not request an automatic bottom scroll', () {
    expect(
      shouldAutoScrollPersonaChat(
        previousCharacterId: 'yaoyao',
        currentCharacterId: 'yaoyao',
        previousNewestMessageId: 9,
        currentNewestMessageId: 9,
      ),
      isFalse,
    );
    expect(
      shouldAutoScrollPersonaChat(
        previousCharacterId: 'yaoyao',
        currentCharacterId: 'yaoyao',
        previousNewestMessageId: 9,
        currentNewestMessageId: 10,
      ),
      isTrue,
    );
  });

  Widget buildSubject({
    required TextEditingController controller,
    required FocusNode focusNode,
    required VoidCallback onSend,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: PersonaChatInputBar(
          controller: controller,
          focusNode: focusNode,
          onSend: onSend,
          hintText: 'Message...',
        ),
      ),
    );
  }

  testWidgets('send button is disabled until the user enters text',
      (tester) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    var sends = 0;
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(buildSubject(
      controller: controller,
      focusNode: focusNode,
      onSend: () => sends++,
    ));

    await tester.tap(find.bySemanticsLabel(UserStorage.l10n.sendLabel));
    await tester.pump();
    expect(sends, 0);

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();

    await tester.tap(find.bySemanticsLabel(UserStorage.l10n.sendLabel));
    await tester.pump();
    expect(sends, 1);
  });

  testWidgets('input remains enabled for consecutive sends', (tester) async {
    final controller = TextEditingController(text: 'hello');
    final focusNode = FocusNode();
    var sends = 0;
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(buildSubject(
      controller: controller,
      focusNode: focusNode,
      onSend: () => sends++,
    ));

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.enabled, isNot(false));

    await tester.tap(find.bySemanticsLabel(UserStorage.l10n.sendLabel));
    await tester.pump();
    expect(sends, 1);

    await tester.enterText(find.byType(TextField), 'another message');
    await tester.tap(find.bySemanticsLabel(UserStorage.l10n.sendLabel));
    await tester.pump();
    expect(sends, 2);
  });

  testWidgets('sending keeps the input focused for the next message',
      (tester) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    var sends = 0;
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(buildSubject(
      controller: controller,
      focusNode: focusNode,
      onSend: () {
        sends++;
        controller.clear();
      },
    ));

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.tap(find.bySemanticsLabel(UserStorage.l10n.sendLabel));
    await tester.pump();

    expect(sends, 1);
    expect(controller.text, isEmpty);
    expect(focusNode.hasFocus, isTrue);
  });

  testWidgets('tapping the message area dismisses the input focus',
      (tester) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextField(
                controller: controller,
                focusNode: focusNode,
              ),
              Expanded(
                child: PersonaChatKeyboardDismissRegion(
                  focusNode: focusNode,
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.tap(find.byType(PersonaChatKeyboardDismissRegion));
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);
  });

  testWidgets('supported emoji uses the Fluent 3D asset', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PersonaChatEmojiGlyph(emoji: '😊'),
        ),
      ),
    );

    final image = tester.widget<Image>(
      find.descendant(
        of: find.byType(PersonaChatEmojiGlyph),
        matching: find.byType(Image),
      ),
    );
    expect(
      (image.image as AssetImage).assetName,
      'assets/fluent_emoji/smiling_face_with_smiling_eyes_3d.png',
    );
    expect(image.width, 36);
    expect(image.height, 36);
    final semantics = tester.widget<Semantics>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Emoji message: 😊',
      ),
    );
    expect(semantics.properties.label, 'Emoji message: 😊');
    expect(semantics.properties.image, isTrue);
  });

  testWidgets('unsupported emoji falls back to a smaller system glyph',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PersonaChatEmojiGlyph(emoji: '🙂🙂'),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('🙂🙂'));
    expect(text.style?.fontSize, 32);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('every protocol emoji has a bundled Fluent asset',
      (tester) async {
    for (final emoji in CharacterEmoji.values) {
      final data = await rootBundle.load(
        'assets/fluent_emoji/${emoji.assetFileName}',
      );
      expect(data.lengthInBytes, greaterThan(0), reason: emoji.agentId);
    }
  });

  test('reversed chat list reserves index zero for the typing indicator', () {
    expect(
      personaChatMessageIndexForReversedList(
        listIndex: 1,
        extraItems: 1,
      ),
      0,
    );
    expect(
      personaChatMessageIndexForReversedList(
        listIndex: 0,
        extraItems: 0,
      ),
      0,
    );
  });

  test('marks chat read after open even without a scroll client', () async {
    final events = <String>[];

    await markPersonaChatReadAfterOpen(
      hasScrollClients: false,
      scrollToLatest: () async => events.add('scroll'),
      markRead: () async => events.add('read'),
    );

    expect(events, ['read']);
  });

  test('scrolls to latest then marks chat read when a client is attached',
      () async {
    final events = <String>[];

    await markPersonaChatReadAfterOpen(
      hasScrollClients: true,
      scrollToLatest: () async => events.add('scroll'),
      markRead: () async => events.add('read'),
    );

    expect(events, ['scroll', 'read']);
  });

  testWidgets('the empty chat style uses each profile greeting and portrait',
      (tester) async {
    CharacterModel profile({
      required String id,
      required String name,
      required String avatar,
      required String greeting,
    }) =>
        CharacterModel(
          id: id,
          name: name,
          tags: const ['foco', 'próximo passo'],
          persona: 'perfil de teste',
          enabled: true,
          avatar: avatar,
          firstMessage: greeting,
        );

    final firstProfile = profile(
      id: 'parceiro_foco',
      name: 'Parceiro de foco',
      avatar: 'asset://characters/parceiro_foco.png',
      greeting: 'Qual é a próxima coisa que precisa andar?',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PersonaChatEmptyState(character: firstProfile)),
      ),
    );

    expect(find.text(UserStorage.l10n.personaChatWelcomeTitle), findsOneWidget);
    expect(find.text(firstProfile.firstMessage!), findsOneWidget);
    expect(find.text('foco · próximo passo'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/characters/parceiro_foco.png',
      ),
      findsOneWidget,
    );

    final secondProfile = profile(
      id: 'calmo_crise',
      name: 'Calmo na crise',
      avatar: 'asset://characters/calmo_crise.png',
      greeting: 'Primeiro, o que ainda está salvo?',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PersonaChatEmptyState(character: secondProfile)),
      ),
    );

    expect(find.text(UserStorage.l10n.personaChatWelcomeTitle), findsOneWidget);
    expect(find.text(secondProfile.firstMessage!), findsOneWidget);
    expect(find.text(firstProfile.firstMessage!), findsNothing);
  });

  testWidgets('messages use the same amber and graphite chat bubbles',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              PersonaChatMessageBubble(
                text: 'Minha mensagem',
                isCharacter: false,
                time: '10:32',
                characterAvatar: null,
                characterName: '',
                showCharacterAvatar: false,
              ),
              PersonaChatMessageBubble(
                text: 'Resposta do perfil',
                isCharacter: true,
                time: '10:33',
                characterAvatar: 'asset://characters/curador.png',
                characterName: 'Curador',
                showCharacterAvatar: true,
              ),
            ],
          ),
        ),
      ),
    );

    bool hasBubbleColor(Widget widget, Color color) =>
        widget is Container &&
        widget.decoration is BoxDecoration &&
        (widget.decoration! as BoxDecoration).color == color;

    expect(
      find.byWidgetPredicate(
        (widget) => hasBubbleColor(widget, const Color(0xFFFF8A3D)),
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => hasBubbleColor(widget, const Color(0xFF1C1C1E)),
      ),
      findsOneWidget,
    );
    expect(find.text('10:32'), findsOneWidget);
    expect(find.text('10:33'), findsOneWidget);
  });
}
