import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memex/l10n/app_localizations.dart';
import 'package:memex/ui/core/cards/templates/entities/link_card.dart';
import 'package:memex/ui/core/cards/templates/entities/person_card.dart';
import 'package:memex/ui/core/cards/templates/entities/place_card.dart';
import 'package:memex/ui/core/cards/templates/entities/transaction_card.dart';
import 'package:memex/ui/core/cards/templates/quantifiable/metric_card.dart';
import 'package:memex/ui/core/cards/templates/quantifiable/mood_card.dart';
import 'package:memex/ui/core/cards/templates/quantifiable/progress_card.dart';
import 'package:memex/ui/core/cards/templates/quantifiable/rating_card.dart';
import 'package:memex/ui/core/cards/templates/temporal/event_card.dart';
import 'package:memex/ui/core/cards/templates/temporal/routine_card.dart';
import 'package:memex/ui/core/cards/templates/textual/conversation_card.dart';
import 'package:memex/ui/core/cards/templates/textual/quote_card.dart';
import 'package:memex/ui/core/cards/templates/visual/gallery_card.dart';
import 'package:memex/ui/core/widgets/local_image.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({'language': 'en'});
    await UserStorage.initL10n();
  });

  Future<void> pumpCard(WidgetTester tester, Widget card) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: card),
      ),
    );
  }

  testWidgets('EventCard keeps the event title and location visible', (
    tester,
  ) async {
    await pumpCard(
      tester,
      const EventCard(
        data: {
          'title': 'Project review',
          'start_time': '2026-03-10T14:00:00',
          'end_time': '2026-03-10T15:00:00',
          'location': 'São Paulo',
        },
      ),
    );

    expect(find.text('Project review'), findsOneWidget);
    expect(find.text('São Paulo'), findsOneWidget);
  });

  testWidgets('MetricCard icon tiles stay dark for emerald and purple themes', (
    tester,
  ) async {
    await pumpCard(
      tester,
      const MetricCard(data: {
        'items': [
          {'title': 'A', 'value': 1, 'color': 'emerald'},
          {'title': 'B', 'value': 2, 'color': 'purple'},
        ],
      }),
    );

    final fills = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .map((d) => d.color)
        .whereType<Color>()
        .toList();
    expect(fills, contains(const Color(0xFF14241A)));
    expect(fills, contains(const Color(0xFF1F1727)));
    for (final c in fills) {
      expect(c.computeLuminance(), lessThan(0.1));
    }
  });

  testWidgets('GalleryCard lays thumbnails out in a horizontal strip', (
    tester,
  ) async {
    await pumpCard(
      tester,
      const GalleryCard(data: {
        'image_urls': ['', '']
      }),
    );

    final list = tester.widget<ListView>(find.byType(ListView));
    expect(list.scrollDirection, Axis.horizontal);
    expect(find.byType(LocalImage), findsNWidgets(2));
  });

  testWidgets('LinkCard shows its title and domain without a chip', (
    tester,
  ) async {
    await pumpCard(
      tester,
      const LinkCard(
        data: {'title': 'Saved page', 'url': 'https://example.com/article'},
      ),
    );

    expect(find.text('Saved page'), findsOneWidget);
    expect(find.text('example.com'), findsOneWidget);
  });

  testWidgets('QuoteCard keeps quote, author, and source', (tester) async {
    await pumpCard(
      tester,
      const QuoteCard(
        data: {
          'content': 'A useful quote.',
          'author': 'Ada Lovelace',
          'source': 'Notes',
        },
      ),
    );

    expect(find.text('A useful quote.'), findsOneWidget);
    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
  });

  testWidgets('TransactionCard labels the total and retains item rows', (
    tester,
  ) async {
    await pumpCard(
      tester,
      const TransactionCard(
        data: {
          'merchant': 'Café',
          'amount': 'R\$ 12,00',
          'items': [
            {'name': 'Coffee', 'amount': 'R\$ 12,00'},
          ],
        },
      ),
    );

    expect(find.text(UserStorage.l10n.total), findsOneWidget);
    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('R\$ 12,00'), findsNWidgets(2));
  });

  testWidgets('ConversationCard ignores malformed messages and localizes me', (
    tester,
  ) async {
    await pumpCard(
      tester,
      const ConversationCard(data: {
        'messages': [null, 'invalid']
      }),
    );
    expect(find.text(UserStorage.l10n.noMessages), findsOneWidget);

    await pumpCard(
      tester,
      const ConversationCard(
        data: {
          'messages': [
            {'sender': 'me', 'text': 'Hello', 'isMe': true},
          ],
        },
      ),
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText && widget.text.toPlainText() == 'You: Hello',
      ),
      findsOneWidget,
    );
  });

  testWidgets('RoutineCard uses the localized streak label', (tester) async {
    await pumpCard(
      tester,
      const RoutineCard(data: {'habit_name': 'Read', 'streak': 3}),
    );

    expect(find.text(UserStorage.l10n.routineStreakDays(3)), findsOneWidget);
  });

  testWidgets('PersonCard handles a missing name', (tester) async {
    await pumpCard(tester, const PersonCard(data: {}));

    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });

  testWidgets('RatingCard clamps its visualization when max score is zero', (
    tester,
  ) async {
    await pumpCard(
      tester,
      const RatingCard(data: {'subject': 'Book', 'score': 4, 'max_score': 0}),
    );

    expect(find.byIcon(Icons.star_border), findsNWidgets(5));
  });

  testWidgets('cards with missing labels do not add English placeholders', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ListView(
            children: const [
              MetricCard(data: {}),
              MoodCard(data: {}),
              ProgressCard(data: {}),
              PlaceCard(data: {}),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Metric'), findsNothing);
    expect(find.text('Neutral'), findsNothing);
    expect(find.text('Progress'), findsNothing);
    expect(find.text('Place'), findsNothing);
  });
}
