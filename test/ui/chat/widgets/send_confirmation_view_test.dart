import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/config/app_flavor.dart';
import 'package:memex/l10n/app_localizations.dart';
import 'package:memex/ui/chat/widgets/send_confirmation_view.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    AppFlavor.init('global');
    SharedPreferences.setMockInitialValues({});
    await UserStorage.initL10n();
  });

  Future<void> pump(
    WidgetTester tester, {
    required String outgoingText,
    required bool timestampsFound,
    required bool pdfUnsupported,
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 400,
            child: SendConfirmationView(
              outgoingText: outgoingText,
              timestampsFound: timestampsFound,
              pdfUnsupported: pdfUnsupported,
              onConfirm: onConfirm,
              onCancel: onCancel,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the exact outgoing text and cancel writes nothing',
      (tester) async {
    var confirmed = 0;
    var cancelled = 0;
    const outgoing = '  sai agora  ';

    await pump(
      tester,
      outgoingText: outgoing,
      timestampsFound: false,
      pdfUnsupported: false,
      onConfirm: () => confirmed += 1,
      onCancel: () => cancelled += 1,
    );

    final shown = tester.widget<Text>(
      find.byKey(const ValueKey('send_outgoing_text')),
    );
    expect(shown.data, outgoing);
    expect(find.byKey(const ValueKey('send_no_timestamps')), findsOneWidget);
    expect(
      find.text(UserStorage.l10n.sendLeavesDeviceTitle),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('send_confirmation_cancel')));
    await tester.pump();

    expect(cancelled, 1);
    expect(confirmed, 0);
  });

  testWidgets('confirm is unavailable when there is nothing to send',
      (tester) async {
    var confirmed = 0;

    await pump(
      tester,
      outgoingText: '',
      timestampsFound: false,
      pdfUnsupported: true,
      onConfirm: () => confirmed += 1,
      onCancel: () {},
    );

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('send_confirmation_confirm')),
    );
    expect(button.onPressed, isNull);
    expect(find.byKey(const ValueKey('send_pdf_unsupported')), findsOneWidget);
    expect(confirmed, 0);
  });

  testWidgets('full-screen review shows the notes and sends only on Enviar',
      (tester) async {
    SharedPreferences.setMockInitialValues({'language': 'pt'});
    await UserStorage.initL10n();
    bool? answer;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => answer = await showSendConfirmationDialog(
              context: context,
              outgoingText: 'Planejamento de novembro',
              timestampsFound: true,
              pdfUnsupported: false,
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Revisar antes de enviar'), findsOneWidget);
    expect(find.text('Planejamento de novembro'), findsOneWidget);
    expect(find.text('Nada será enviado sem sua confirmação.'), findsOneWidget);

    await tester.tap(find.text('Voltar').last);
    await tester.pumpAndSettle();
    expect(answer, isFalse);

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar agora'));
    await tester.pumpAndSettle();
    expect(answer, isTrue);
  });
}
