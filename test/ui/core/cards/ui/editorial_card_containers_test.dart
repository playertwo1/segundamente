import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/ui/core/cards/ui/glass_card.dart';
import 'package:memex/ui/core/cards/ui/timeline_card_container.dart';
import 'package:memex/ui/core/themes/app_colors.dart';

// AMOLED editorial rows (D-017): card containers draw no box or shadow and
// keep content aligned with the timeline text column.
void main() {
  BoxDecoration decorationOf(WidgetTester tester, Type type) {
    final container = tester.widget<Container>(find
        .descendant(of: find.byType(type), matching: find.byType(Container))
        .first);
    return container.decoration! as BoxDecoration;
  }

  EdgeInsets paddingAround(WidgetTester tester, String text) {
    final padding = tester.widget<Padding>(
      find.ancestor(of: find.text(text), matching: find.byType(Padding)).first,
    );
    return padding.padding.resolve(TextDirection.ltr);
  }

  Future<void> pump(WidgetTester tester, Widget child) => tester
      .pumpWidget(MaterialApp(home: Scaffold(body: Center(child: child))));

  testWidgets('TimelineCard glass: no fill, shadow or side inset',
      (tester) async {
    await pump(
      tester,
      const TimelineCard(
        padding: EdgeInsets.all(20),
        child: Text('registro'),
      ),
    );

    final deco = decorationOf(tester, TimelineCard);
    expect(deco.color, isNull);
    expect(deco.boxShadow, isNull);
    expect(paddingAround(tester, 'registro'),
        const EdgeInsets.only(top: 8, bottom: 8));
  });

  testWidgets('TimelineCard immersive keeps a quiet raised surface',
      (tester) async {
    await pump(
      tester,
      const TimelineCard(
        variant: TimelineCardVariant.immersive,
        child: Text('destaque'),
      ),
    );

    final deco = decorationOf(tester, TimelineCard);
    expect(deco.color, AppColors.surface);
    expect(deco.gradient, isNull);
    expect(deco.boxShadow, isNull);
  });

  testWidgets('GlassCard: no shadow; edge-to-edge media keeps a rounded clip',
      (tester) async {
    await pump(
      tester,
      const GlassCard(child: Text('nota')),
    );
    var deco = decorationOf(tester, GlassCard);
    expect(deco.boxShadow, isNull);
    expect(deco.color, isNull);
    expect(paddingAround(tester, 'nota'),
        const EdgeInsets.only(top: 8, bottom: 8));

    await pump(
      tester,
      const GlassCard(padding: EdgeInsets.zero, child: Text('foto')),
    );
    deco = decorationOf(tester, GlassCard);
    expect(deco.borderRadius, BorderRadius.circular(12));
  });
}
