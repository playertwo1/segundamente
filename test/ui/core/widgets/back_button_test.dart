import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/ui/core/widgets/back_button.dart';

void main() {
  Future<void> pump(WidgetTester tester, {VoidCallback? onTap}) {
    return tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: const [Locale('pt')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          appBar: AppBar(leading: AppBackButton(onTap: onTap)),
        ),
      ),
    );
  }

  testWidgets('is a labelled button with a 48dp touch target', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);

    expect(
      tester.getSemantics(find.byType(AppBackButton)),
      isSemantics(label: 'Voltar', isButton: true, hasTapAction: true),
    );
    final size = tester.getSize(find.byType(AppBackButton));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    handle.dispose();
  });

  testWidgets('runs onTap, also from the transparent padding', (tester) async {
    var taps = 0;
    await pump(tester, onTap: () => taps++);

    final topLeft = tester.getTopLeft(find.byType(AppBackButton));
    await tester.tapAt(topLeft + const Offset(2, 2));
    expect(taps, 1);
  });
}
