import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/config/app_flavor.dart';
import 'package:memex/domain/models/report_memory.dart';
import 'package:memex/domain/models/session_report.dart';
import 'package:memex/l10n/app_localizations.dart';
import 'package:memex/ui/chat/widgets/follow_ups_view.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    AppFlavor.init('global');
    SharedPreferences.setMockInitialValues({});
    await UserStorage.initL10n();
  });

  ReportHit hit(String text) {
    return ReportHit(
      sessionId: 'txt_report',
      item: ReportItem(
        id: 'item_1',
        kind: ReportItemKind.followUp,
        text: text,
        status: ReportItemStatus.approved,
        assignee: reportAssigneeUnknown,
        due: reportDueUnknown,
        source: ReportSource(segmentId: 'seg_1', excerpt: text),
      ),
    );
  }

  Future<void> pump(
    WidgetTester tester, {
    required List<ReportHit> hits,
    required Map<String, ReportRevision> changes,
    required ValueChanged<String> onSearch,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: FollowUpsView(
            hits: hits,
            textChanges: changes,
            onSearch: onSearch,
          ),
        ),
      ),
    );
  }

  testWidgets('an approved follow-up shows its text change and reason', (tester) async {
    await pump(
      tester,
      hits: [hit('mandar o resumo')],
      changes: {
        reportHitKey('txt_report', 'item_1'): const ReportRevision(
          itemId: 'item_1',
          field: 'text',
          before: 'mandar o resumo',
          after: 'mandar amanhã',
          at: '2026-11-02T15:04:00',
        ),
      },
      onSearch: (_) {},
    );

    expect(find.text('mandar o resumo'), findsWidgets);
    expect(find.text('mandar o resumo → mandar amanhã'), findsOneWidget);
    expect(find.byKey(const ValueKey('follow_ups_empty')), findsNothing);

    await pump(
      tester,
      hits: [hit('mandar o resumo')],
      changes: {
        reportHitKey('txt_report', 'item_1'): const ReportRevision(
          itemId: 'item_1',
          field: 'text',
          before: 'mandar o resumo',
          after: 'mandar amanhã',
          at: '2026-11-02T15:04:00',
          reason: 'pedido do cliente',
        ),
      },
      onSearch: (_) {},
    );
    expect(
      find.text('mandar o resumo → mandar amanhã (pedido do cliente)'),
      findsOneWidget,
    );
  });

  testWidgets('search submits the typed query', (tester) async {
    String? submitted;
    await pump(
      tester,
      hits: const [],
      changes: const {},
      onSearch: (value) => submitted = value,
    );

    expect(find.byKey(const ValueKey('follow_ups_empty')), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('follow_up_search')), 'escopo');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(submitted, 'escopo');
  });
}
