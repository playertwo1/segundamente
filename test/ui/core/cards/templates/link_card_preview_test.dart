import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/ui/core/cards/templates/entities/link_card.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pump(WidgetTester tester, Map<String, dynamic> data) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LinkCard(data: data))),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('off by default: no network, no preview line', (tester) async {
    SharedPreferences.setMockInitialValues({});
    // A local address would be refused anyway; this checks the switch alone.
    await pump(tester, {'url': 'https://example.com/a'});
    expect(find.byKey(const ValueKey('link-preview-title')), findsNothing);
    expect(await UserStorage.isLinkPreviewEnabled(), isFalse);
  });

  testWidgets('on, a refused address still shows nothing and does not throw',
      (tester) async {
    SharedPreferences.setMockInitialValues({'link_preview_enabled': true});
    await pump(tester, {'url': 'http://192.168.0.1/admin'});
    expect(find.byKey(const ValueKey('link-preview-title')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a card that already has a title never fetches', (tester) async {
    SharedPreferences.setMockInitialValues({'link_preview_enabled': true});
    await pump(tester, {'url': 'http://192.168.0.1/', 'title': 'Já tem'});
    expect(find.text('Já tem'), findsOneWidget);
    expect(find.byKey(const ValueKey('link-preview-title')), findsNothing);
  });
}
