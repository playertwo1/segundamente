import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/config/app_flavor.dart';
import 'package:memex/domain/models/session_report.dart';
import 'package:memex/l10n/app_localizations.dart';
import 'package:memex/ui/chat/widgets/session_report_view.dart';
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
    required List<ReportKind> sent,
    bool fallback = false,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SessionReportView(
            report: null,
            onDraft: (_, __) async {},
            onDraftWithModel: (kind, _) async => sent.add(kind),
            usedLocalFallback: fallback,
            onEdit: ({
              required itemId,
              required text,
              required assignee,
              required due,
              String? reason,
            }) async {},
            onSetStatus: (
                {required itemId, required status, String? reason}) async {},
          ),
        ),
      ),
    );
  }

  testWidgets('the model draft sends nothing until the dialog is confirmed',
      (tester) async {
    final sent = <ReportKind>[];
    await pump(tester, sent: sent);

    await tester.tap(find.byKey(const ValueKey('report_generate_model')));
    await tester.pumpAndSettle();
    expect(find.text(UserStorage.l10n.sendLeavesDeviceTitle), findsOneWidget);
    expect(find.text(UserStorage.l10n.reportModelConfirmBody), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('report_model_cancel')));
    await tester.pumpAndSettle();
    expect(sent, isEmpty);

    await tester.tap(find.byKey(const ValueKey('report_generate_model')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('report_model_confirm')));
    await tester.pumpAndSettle();
    expect(sent, [ReportKind.livre]);
  });

  testWidgets('the local fallback is announced', (tester) async {
    await pump(tester, sent: [], fallback: true);
    expect(find.byKey(const ValueKey('report_model_fallback')), findsOneWidget);
  });
}
