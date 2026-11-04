import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/data/repositories/get_knowledge_insight_detail.dart';
import 'package:memex/domain/models/insight_detail_model.dart';
import 'package:memex/l10n/app_localizations.dart';
import 'package:memex/ui/insight/widgets/insight_detail_page.dart';
import 'package:memex/ui/insight/widgets/insight_cards/bubble_chart_card.dart';
import 'package:memex/ui/insight/widgets/insight_cards/route_map_card.dart';
import 'package:memex/ui/insight/widgets/insight_cards/timeline_card.dart';
import 'package:memex/ui/insight/widgets/insight_cards/trend_chart_card.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserStorage.initL10n();
  });

  testWidgets('shows friendly message for missing insight links',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: InsightDetailPage(
          id: 'missing-insight',
          detailLoader: (_) async {
            throw KnowledgeInsightNotFoundException('missing-insight');
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text(
        'This insight is still being generated or was updated. Refresh insights and try again later.',
      ),
      findsWidgets,
    );
    expect(
        find.textContaining('Knowledge insight card not found'), findsNothing);
  });

  testWidgets('detail uses existing chart, route, timeline, and narrative data',
      (tester) async {
    final variants = <({String? template, Map<String, dynamic>? data})>[
      (
        template: 'trend_chart_card_v1',
        data: {
          'title': 'Registros por semana',
          'points': [
            {'label': 'Seg', 'value': 2},
            {'label': 'Ter', 'value': 4},
          ],
        },
      ),
      (
        template: 'bubble_chart_card_v1',
        data: {
          'title': 'Temas recorrentes',
          'bubbles': [
            {'label': 'Sono', 'value': 5, 'is_highlight': true},
            {'label': 'Rotina', 'value': 3},
          ],
        },
      ),
      (
        template: 'route_map_card_v1',
        data: {
          'title': 'Percurso registrado',
          'locations': [
            {'name': 'Início', 'lat': -23.5, 'lng': -46.6},
            {'name': 'Fim', 'lat': -23.6, 'lng': -46.7},
          ],
        },
      ),
      (
        template: 'timeline_card_v1',
        data: {
          'title': 'Ordem dos eventos',
          'items': [
            {'time': '09:00', 'title': 'Primeiro registro'},
            {'time': '10:00', 'title': 'Segundo registro'},
          ],
        },
      ),
      (template: null, data: null),
    ];

    for (final variant in variants) {
      final expectedContent = variant.template == null
          ? 'Narrativa baseada nos registros existentes.'
          : variant.data!['title'] as String;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: InsightDetailPage(
            key: ValueKey(variant.template ?? 'narrative'),
            id: 'insight-${variant.template ?? 'narrative'}',
            detailLoader: (_) async => InsightDetailModel(
              insight: InsightMetadataModel(
                id: 'insight',
                title: 'Visão dos registros',
                icon: '',
                type: 'default',
              ),
              content: 'Narrativa baseada nos registros existentes.',
              analysis: '',
              relatedCards: const [],
              widgetType: variant.template == null ? null : 'native',
              widgetTemplate: variant.template,
              widgetData: variant.data,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Visão dos registros'), findsOneWidget);
      expect(find.text(expectedContent), findsWidgets);
      if (variant.template == 'trend_chart_card_v1') {
        expect(find.byType(TrendChartCard), findsOneWidget);
      } else if (variant.template == 'bubble_chart_card_v1') {
        expect(find.byType(BubbleChartCard), findsOneWidget);
      } else if (variant.template == 'route_map_card_v1') {
        expect(find.byType(RouteMapCard), findsOneWidget);
      } else if (variant.template == 'timeline_card_v1') {
        expect(find.byType(TimelineCard), findsOneWidget);
      }
    }
  });
}
