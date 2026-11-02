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

  const segments = [
    ReportSegment(
      id: 'seg_0',
      text: 'fechar o escopo',
      clock: '00:00:01',
    ),
    ReportSegment(
      id: 'seg_1',
      text: 'mandar o resumo',
      clock: '00:00:02',
    ),
  ];

  Future<void> pump(
    WidgetTester tester,
    SessionReport? report, {
    required Future<void> Function(ReportKind kind, String? customTitle)
        onDraft,
    required Future<void> Function({
      required String itemId,
      required String text,
      required String assignee,
      required String due,
    }) onEdit,
    required Future<void> Function({
      required String itemId,
      required ReportItemStatus status,
    }) onSetStatus,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SessionReportView(
            report: report,
            onDraft: onDraft,
            onEdit: onEdit,
            onSetStatus: onSetStatus,
          ),
        ),
      ),
    );
  }

  testWidgets('a meeting and a study report show different sections',
      (tester) async {
    final meeting = draftSessionReport(
      sessionId: 's',
      kind: ReportKind.reuniao,
      customTitle: null,
      segments: segments,
    );
    await pump(
      tester,
      meeting,
      onDraft: (_, __) async {},
      onEdit: ({
        required itemId,
        required text,
        required assignee,
        required due,
      }) async {},
      onSetStatus: ({required itemId, required status}) async {},
    );

    expect(
        find.byKey(const ValueKey('report_section_decision')), findsOneWidget);
    expect(find.byKey(const ValueKey('report_section_question')), findsNothing);
    expect(find.text('Relatório de reunião'), findsOneWidget);

    final study = draftSessionReport(
      sessionId: 's',
      kind: ReportKind.estudo,
      customTitle: null,
      segments: segments,
    );
    await pump(
      tester,
      study,
      onDraft: (_, __) async {},
      onEdit: ({
        required itemId,
        required text,
        required assignee,
        required due,
      }) async {},
      onSetStatus: ({required itemId, required status}) async {},
    );
    expect(
        find.byKey(const ValueKey('report_section_question')), findsOneWidget);
    expect(find.byKey(const ValueKey('report_section_decision')), findsNothing);
    expect(find.text('Relatório de estudo'), findsOneWidget);
  });

  testWidgets('tapping a decision shows the exact source excerpt', (tester) async {
    final report = sessionReportFromModelJson(
      sessionId: 's',
      kind: ReportKind.reuniao,
      customTitle: null,
      segments: segments,
      json: {
        'schema_version': 1,
        'items': [
          {
            'kind': 'decision',
            'text': 'fechar o escopo',
            'segment_id': 'seg_0',
            'excerpt': 'fechar o escopo',
            'clock': '00:00:01',
          },
        ],
      },
    );
    await pump(
      tester,
      report,
      onDraft: (_, __) async {},
      onEdit: ({
        required itemId,
        required text,
        required assignee,
        required due,
      }) async {},
      onSetStatus: ({required itemId, required status}) async {},
    );

    await tester.tap(find.byKey(const ValueKey('report_item_item_1')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('report_source_excerpt_item_1')),
      findsOneWidget,
    );
    expect(find.text('fechar o escopo'), findsWidgets);
    expect(find.text('00:00:01'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('report_definitive_item_1')), findsNothing);
  });

  testWidgets('a task becomes definitive only after approval', (tester) async {
    var report = sessionReportFromModelJson(
      sessionId: 's',
      kind: ReportKind.reuniao,
      customTitle: null,
      segments: segments,
      json: {
        'schema_version': 1,
        'items': [
          {
            'kind': 'task',
            'text': 'mandar o resumo',
            'segment_id': 'seg_1',
            'excerpt': 'mandar o resumo',
            'clock': '00:00:02',
            'status': 'approved',
            'assignee': 'Ana',
            'due': 'amanhã',
          },
        ],
      },
    );
    final host = _Host(initial: report);
    await tester.pumpWidget(host.wrap());
    expect(find.text(reportAssigneeUnknown), findsOneWidget);
    expect(find.text(reportDueUnknown), findsOneWidget);
    expect(
        find.byKey(const ValueKey('report_definitive_item_1')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('report_approve_item_1')));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('report_definitive_item_1')), findsOneWidget);
  });

  testWidgets('search hides other items and edit keeps the callback text',
      (tester) async {
    final report = draftSessionReport(
      sessionId: 's',
      kind: ReportKind.reuniao,
      customTitle: null,
      segments: segments,
    );
    String? edited;
    await pump(
      tester,
      report,
      onDraft: (_, __) async {},
      onEdit: ({
        required itemId,
        required text,
        required assignee,
        required due,
      }) async {
        edited = text;
      },
      onSetStatus: ({required itemId, required status}) async {},
    );

    await tester.enterText(
        find.byKey(const ValueKey('report_search')), 'fechar');
    await tester.pump();
    expect(find.byKey(const ValueKey('report_item_item_2')), findsNothing);
    expect(find.byKey(const ValueKey('report_item_item_1')), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('report_search')), '');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('report_edit_item_1')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('report_edit_text_item_1')),
      'escopo fechado',
    );
    await tester.tap(find.byKey(const ValueKey('report_edit_save_item_1')));
    await tester.pumpAndSettle();
    expect(edited, 'escopo fechado');
  });

  testWidgets('generate uses the selected kind', (tester) async {
    ReportKind? selected;
    await pump(
      tester,
      null,
      onDraft: (kind, _) async {
        selected = kind;
      },
      onEdit: ({
        required itemId,
        required text,
        required assignee,
        required due,
      }) async {},
      onSetStatus: ({required itemId, required status}) async {},
    );

    await tester.tap(find.byKey(const ValueKey('report_kind')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('report_kind_estudo')).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('report_generate')));
    await tester.pump();

    expect(selected, ReportKind.estudo);
  });
}

class _Host extends StatefulWidget {
  const _Host({required this.initial});

  final SessionReport initial;

  Widget wrap() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: this),
    );
  }

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late SessionReport report = widget.initial;

  @override
  Widget build(BuildContext context) {
    return SessionReportView(
      report: report,
      onDraft: (_, __) async {},
      onEdit: ({
        required itemId,
        required text,
        required assignee,
        required due,
      }) async {},
      onSetStatus: ({required itemId, required status}) async {
        setState(() {
          report = setReportItemStatus(
            report,
            itemId: itemId,
            status: status,
          );
        });
      },
    );
  }
}
