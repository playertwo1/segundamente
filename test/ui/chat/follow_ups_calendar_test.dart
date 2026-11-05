import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/config/app_flavor.dart';
import 'package:memex/data/repositories/memex_router.dart';
import 'package:memex/domain/models/report_memory.dart';
import 'package:memex/domain/models/session_report.dart';
import 'package:memex/l10n/app_localizations.dart';
import 'package:memex/ui/chat/view_models/follow_ups_viewmodel.dart';
import 'package:memex/ui/chat/widgets/follow_ups_view.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    AppFlavor.init('global');
    SharedPreferences.setMockInitialValues({'language': 'pt'});
    await UserStorage.initL10n();
  });

  ReportHit hit(String id, String text, String due) => ReportHit(
        sessionId: 'sessao',
        item: ReportItem(
          id: id,
          kind: ReportItemKind.followUp,
          text: text,
          status: ReportItemStatus.approved,
          assignee: reportAssigneeUnknown,
          due: due,
          source: ReportSource(segmentId: 'seg_1', excerpt: 'trecho de $text'),
        ),
      );

  group('FollowUpsViewModel.addToCalendar', () {
    late List<Map<String, Object?>> opened;
    late FollowUpsViewModel vm;

    setUp(() {
      opened = [];
      vm = FollowUpsViewModel(
        router: _NoRouter(),
        openCalendar: ({
          required title,
          required start,
          required end,
          description,
          allDay = false,
        }) async {
          opened.add({
            'title': title,
            'start': start,
            'end': end,
            'description': description,
            'allDay': allDay,
          });
          return true;
        },
      );
    });

    test('a date with a time opens a one hour event with title and excerpt',
        () async {
      final ok = await vm.addToCalendar(
        hit('i1', 'Enviar proposta', '20/11/2026 14:30'),
      );
      expect(ok, isTrue);
      expect(opened.single, {
        'title': 'Enviar proposta',
        'start': DateTime(2026, 11, 20, 14, 30),
        'end': DateTime(2026, 11, 20, 15, 30),
        'description': 'trecho de Enviar proposta',
        'allDay': false,
      });
    });

    test('a date alone opens an all-day event at UTC midnight', () async {
      await vm.addToCalendar(hit('i2', 'Pagar boleto', '2026-11-20'));
      expect(opened.single['start'], DateTime.utc(2026, 11, 20));
      expect(opened.single['end'], DateTime.utc(2026, 11, 21));
      expect(opened.single['allDay'], isTrue);
    });

    test('without an explicit date nothing is opened', () async {
      for (final due in [reportDueUnknown, 'amanhã', 'sexta', '31/02/2026']) {
        expect(await vm.addToCalendar(hit('i3', 'x', due)), isFalse,
            reason: due);
      }
      expect(opened, isEmpty);
    });
  });

  testWidgets('the calendar action appears only for an explicit date',
      (tester) async {
    final tapped = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: FollowUpsView(
            hits: [
              hit('a', 'com data', '20/11/2026'),
              hit('b', 'sem data', reportDueUnknown),
              hit('c', 'data solta', 'amanhã'),
            ],
            textChanges: const {},
            onSearch: (_) {},
            onAddToCalendar: (h) => tapped.add(h.item.id),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('follow_up_calendar_sessao_a')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('follow_up_calendar_sessao_b')),
        findsNothing);
    expect(find.byKey(const ValueKey('follow_up_calendar_sessao_c')),
        findsNothing);
    expect(find.byTooltip('Adicionar à agenda'), findsOneWidget);
    final size = tester
        .getSize(find.byKey(const ValueKey('follow_up_calendar_sessao_a')));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));

    await tester.tap(find.byKey(const ValueKey('follow_up_calendar_sessao_a')));
    expect(tapped, ['a']);
  });
}

class _NoRouter implements MemexRouter {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
