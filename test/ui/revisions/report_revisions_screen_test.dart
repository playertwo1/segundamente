import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/data/repositories/memex_router.dart';
import 'package:memex/domain/models/report_memory.dart';
import 'package:memex/domain/models/session_report.dart';
import 'package:memex/l10n/app_localizations.dart';
import 'package:memex/ui/revisions/view_models/report_revisions_viewmodel.dart';
import 'package:memex/ui/revisions/widgets/report_revisions_screen.dart';
import 'package:memex/utils/result.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'language': 'pt'});
    await UserStorage.initL10n();
  });

  Future<void> pump(
    WidgetTester tester, {
    required _FakeRouter router,
    String? itemId,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: ReportRevisionsScreen(
          viewModel: ReportRevisionsViewModel(
            router: router,
            sessionId: 'test_session',
            itemId: itemId,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const rev1 = ReportRevision(
    itemId: 'item_1',
    field: 'text',
    before: 'fechar o escopo',
    after: 'fechar depois',
    at: '2026-11-02T15:05:00',
    reason: 'alinhamento com liderança',
  );

  const rev2 = ReportRevision(
    itemId: 'item_2',
    field: 'status',
    before: 'unconfirmed',
    after: 'approved',
    at: '2026-11-02T15:10:00',
  );

  testWidgets('shows empty message when no revisions exist', (tester) async {
    final router = _FakeRouter(revisions: const []);
    await pump(tester, router: router);

    expect(find.byKey(const ValueKey('report_revisions_empty')), findsOneWidget);
    expect(find.text(UserStorage.l10n.reportRevisionsEmpty), findsOneWidget);
  });

  testWidgets('displays revision details with field, before, after and reason',
      (tester) async {
    final router = _FakeRouter(
      revisions: const [rev1, rev2],
      report: const SessionReport(
        schemaVersion: 1,
        sessionId: 'test_session',
        title: 'Reunião',
        kind: ReportKind.reuniao,
        sections: [ReportItemKind.decision],
        items: [
          ReportItem(
            id: 'item_1',
            kind: ReportItemKind.decision,
            text: 'fechar depois',
            assignee: 'não identificado',
            due: 'não informado',
            status: ReportItemStatus.approved,
            source: ReportSource(
              segmentId: 'seg_0',
              excerpt: 'fechar o escopo',
              clock: '00:00:01',
            ),
          ),
        ],
      ),
    );

    await pump(tester, router: router);

    expect(find.byKey(const ValueKey('report_revisions_empty')), findsNothing);
    expect(find.text('Texto modificado'), findsOneWidget);
    expect(find.text('Status modificado'), findsOneWidget);
    expect(find.text('fechar o escopo', skipOffstage: false), findsWidgets);
    expect(find.text('fechar depois', skipOffstage: false), findsWidgets);
    expect(find.byKey(const ValueKey('revision_reason_item_1_0')), findsOneWidget);
    expect(find.text('alinhamento com liderança'), findsOneWidget);
  });

  testWidgets('filtering by itemId only returns the specified item revisions',
      (tester) async {
    final router = _FakeRouter(revisions: const [rev1, rev2]);
    await pump(tester, router: router, itemId: 'item_2');

    expect(find.text('Status modificado'), findsOneWidget);
    expect(find.text('Texto modificado'), findsNothing);
  });
}

class _FakeRouter implements MemexRouter {
  _FakeRouter({
    this.revisions = const [],
    this.report,
  });

  final List<ReportRevision> revisions;
  final SessionReport? report;

  @override
  Future<Result<List<ReportRevision>>> loadSessionRevisions({
    required String sessionId,
    String? itemId,
  }) async {
    if (itemId == null) return Ok(revisions);
    return Ok(revisions.where((r) => r.itemId == itemId).toList());
  }

  @override
  Future<Result<SessionReport?>> loadSessionReport(String sessionId) async {
    return Ok(report);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
