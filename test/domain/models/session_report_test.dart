import 'package:flutter_test/flutter_test.dart';
import 'package:memex/domain/models/session_report.dart';

void main() {
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

  test('each report kind has its own title and sections', () {
    final meeting = draftSessionReport(
      sessionId: 's',
      kind: ReportKind.reuniao,
      customTitle: null,
      segments: segments,
    );
    final study = draftSessionReport(
      sessionId: 's',
      kind: ReportKind.estudo,
      customTitle: null,
      segments: segments,
    );
    final custom = draftSessionReport(
      sessionId: 's',
      kind: ReportKind.custom,
      customTitle: 'Conversa com o Rafael',
      segments: segments,
    );
    final free = draftSessionReport(
      sessionId: 's',
      kind: ReportKind.livre,
      customTitle: null,
      segments: segments,
    );
    final brainstorm = draftSessionReport(
      sessionId: 's',
      kind: ReportKind.brainstorm,
      customTitle: null,
      segments: segments,
    );
    final journal = draftSessionReport(
      sessionId: 's',
      kind: ReportKind.diario,
      customTitle: null,
      segments: segments,
    );

    expect(meeting.title, 'Relatório de reunião');
    expect(study.title, 'Relatório de estudo');
    expect(custom.title, 'Conversa com o Rafael');
    expect(free.title, 'Relatório livre');
    expect(brainstorm.title, 'Relatório de brainstorm');
    expect(journal.title, 'Relatório de diário');
    expect(brainstorm.items[1].kind, ReportItemKind.opportunity);
    expect(journal.items[1].kind, ReportItemKind.idea);
    expect(free.items[1].kind, ReportItemKind.idea);
    expect(brainstorm.sections, isNot(contains(ReportItemKind.decision)));
    expect(meeting.sections, contains(ReportItemKind.decision));
    expect(meeting.sections, isNot(contains(ReportItemKind.question)));
    expect(study.sections, contains(ReportItemKind.question));
    expect(study.sections, isNot(contains(ReportItemKind.decision)));
    expect(meeting.items[1].kind, ReportItemKind.followUp);
    expect(study.items[1].kind, ReportItemKind.question);
    expect(meeting.items.every((item) => !isDefinitiveTask(item)), isTrue);
  });

  test('model json cannot confirm a task or invent assignee and due date', () {
    final report = sessionReportFromModelJson(
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

    final task = report.items.single;
    expect(task.status, ReportItemStatus.unconfirmed);
    expect(task.assignee, reportAssigneeUnknown);
    expect(task.due, reportDueUnknown);
    expect(isDefinitiveTask(task), isFalse);

    final approved = setReportItemStatus(
      report,
      itemId: task.id,
      status: ReportItemStatus.approved,
    );
    expect(isDefinitiveTask(approved.items.single), isTrue);
  });

  test('an excerpt outside the source segment is rejected', () {
    expect(
      () => sessionReportFromModelJson(
        sessionId: 's',
        kind: ReportKind.reuniao,
        customTitle: null,
        segments: segments,
        json: {
          'schema_version': 1,
          'items': [
            {
              'kind': 'decision',
              'text': 'inventado',
              'segment_id': 'seg_0',
              'excerpt': 'inventado',
              'clock': '00:00:01',
            },
          ],
        },
      ),
      throwsFormatException,
    );
  });

  test('a decision is rejected in a brainstorm report', () {
    expect(
      () => sessionReportFromModelJson(
        sessionId: 's',
        kind: ReportKind.brainstorm,
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
            },
          ],
        },
      ),
      throwsFormatException,
    );
  });

  test('version 0 migrates and version 2 is rejected', () {
    final migrated = sessionReportFromStorage({
      'schema_version': 0,
      'session_id': 's',
      'type': 'meeting',
      'entries': [
        {
          'type': 'decision',
          'body': 'fechar o escopo',
          'segment_id': 'seg_0',
          'quote': 'fechar o escopo',
          'clock': '00:00:01',
        },
      ],
    });

    expect(migrated.schemaVersion, sessionReportSchemaVersion);
    expect(migrated.kind, ReportKind.reuniao);
    expect(migrated.items.single.status, ReportItemStatus.unconfirmed);
    expect(migrated.items.single.assignee, reportAssigneeUnknown);
    expect(migrated.items.single.source.excerpt, 'fechar o escopo');

    expect(
      () => sessionReportFromStorage({
        'schema_version': 2,
        'session_id': 's',
      }),
      throwsFormatException,
    );
  });

  test('editing keeps the source excerpt and search skips discarded items', () {
    final report = draftSessionReport(
      sessionId: 's',
      kind: ReportKind.reuniao,
      customTitle: null,
      segments: segments,
    );
    final edited = editReportItem(
      report,
      itemId: 'item_2',
      text: '  enviar depois  ',
      assignee: ' ',
      due: '',
    );
    final item = edited.items[1];
    expect(item.text, 'enviar depois');
    expect(item.assignee, reportAssigneeUnknown);
    expect(item.due, reportDueUnknown);
    expect(item.source.excerpt, 'mandar o resumo');
    expect(item.source.clock, '00:00:02');

    final discarded = setReportItemStatus(
      edited,
      itemId: 'item_2',
      status: ReportItemStatus.discarded,
    );
    expect(
      searchSessionReport(discarded, 'enviar'),
      isEmpty,
    );
    expect(
      searchSessionReport(edited, 'MANDAR').single.id,
      'item_2',
    );
  });

  test('model reply parsing accepts a fence and refuses other text', () {
    expect(reportModelReplyJson('```json\n{"items":[]}\n```'),
        {'items': [], 'schema_version': 1});
    expect(reportModelReplyJson(' {"items":[]} '),
        {'items': [], 'schema_version': 1});
    expect(() => reportModelReplyJson('Claro! {"items":[]}'),
        throwsFormatException);
    expect(() => reportModelReplyJson('[1]'), throwsFormatException);
  });

  test('extraction prompt lists segment ids and refuses oversized text', () {
    final prompt = reportExtractionUserPrompt(const [
      ReportSegment(id: 'seg_0', text: 'olá', clock: '00:00:01'),
    ]);
    expect(prompt, '[seg_0 00:00:01] olá\n');
    expect(
      () => reportExtractionUserPrompt([
        ReportSegment(id: 'seg_0', text: 'a' * reportModelInputLimit),
      ]),
      throwsFormatException,
    );
    expect(reportExtractionSystemPrompt(ReportKind.brainstorm),
        contains('idea, opportunity'));
  });

  group('task extraction guard (pt-BR)', () {
    SessionReport extract(
      ReportKind kind,
      List<(String kind, String text)> raw,
    ) {
      final segs = [
        for (var i = 0; i < raw.length; i++)
          ReportSegment(id: 'seg_$i', text: raw[i].$2, clock: '00:00:0$i'),
      ];
      return sessionReportFromModelJson(
        sessionId: 's',
        kind: kind,
        customTitle: null,
        segments: segs,
        json: {
          'schema_version': 1,
          'items': [
            for (var i = 0; i < raw.length; i++)
              {
                'kind': raw[i].$1,
                'text': raw[i].$2,
                'segment_id': 'seg_$i',
                'excerpt': raw[i].$2,
              },
          ],
        },
      );
    }

    test('real commitments stay tasks', () {
      final report = extract(ReportKind.reuniao, [
        ('task', 'Carlos deve enviar o resumo à equipe amanhã.'),
        (
          'task',
          'Marina fica responsável por concluir os testes até o dia 20.'
        ),
        ('task', 'Preciso enviar o relatório que fiz ontem.'),
        ('task', 'Vamos atualizar a página de preços.'),
      ]);
      expect(
          report.items.map((i) => i.kind), everyElement(ReportItemKind.task));
      expect(report.items, hasLength(4));
    });

    test('a past fact is not a task', () {
      final report = extract(ReportKind.reuniao, [
        ('task', 'Ontem o time enviou o relatório ao cliente.'),
        ('task', 'Eu já resolvi o problema do login.'),
        ('task', 'O contrato foi assinado na semana passada.'),
      ]);
      expect(report.items.map((i) => i.kind),
          everyElement(ReportItemKind.summary));
    });

    test('an opinion is an idea where the report has ideas, else dropped', () {
      final free = extract(ReportKind.livre, [
        ('task', 'Acho que seria melhor mudar o layout.'),
        ('task', 'Talvez a gente devesse testar outro fornecedor.'),
      ]);
      expect(free.items.map((i) => i.kind), everyElement(ReportItemKind.idea));

      final meeting = extract(ReportKind.reuniao, [
        ('task', 'Acho que seria melhor mudar o layout.'),
        ('task', 'Carlos deve enviar o resumo amanhã.'),
      ]);
      expect(meeting.items.single.text, 'Carlos deve enviar o resumo amanhã.');
    });

    test('the same item is not listed twice', () {
      final segs = [
        const ReportSegment(
            id: 'seg_0',
            text: 'Carlos deve enviar o resumo.',
            clock: '00:00:01'),
      ];
      final report = sessionReportFromModelJson(
        sessionId: 's',
        kind: ReportKind.reuniao,
        customTitle: null,
        segments: segs,
        json: {
          'schema_version': 1,
          'items': [
            {
              'kind': 'task',
              'text': 'Carlos deve enviar o resumo.',
              'segment_id': 'seg_0',
              'excerpt': 'Carlos deve enviar o resumo.'
            },
            {
              'kind': 'task',
              'text': 'carlos deve enviar o RESUMO',
              'segment_id': 'seg_0',
              'excerpt': 'Carlos deve enviar'
            },
            {
              'kind': 'task',
              'text': 'Enviar o resumo (Carlos)',
              'segment_id': 'seg_0',
              'excerpt': 'Carlos deve enviar o resumo.'
            },
            {
              'kind': 'followUp',
              'text': 'Carlos deve enviar o resumo.',
              'segment_id': 'seg_0',
              'excerpt': 'Carlos deve enviar o resumo.'
            },
          ],
        },
      );
      expect(report.items.map((i) => (i.kind, i.id)), [
        (ReportItemKind.task, 'item_1'),
        (ReportItemKind.followUp, 'item_2'),
      ]);
    });

    test('the prompt states what a task is', () {
      final prompt = reportExtractionSystemPrompt(ReportKind.reuniao);
      expect(prompt, contains('future commitment'));
      expect(prompt, contains('never tasks'));
    });

    test('the prompt carries the Portuguese summary rules', () {
      final prompt = reportExtractionSystemPrompt(ReportKind.reuniao);
      expect(prompt, contains('Brazilian Portuguese'));
      expect(prompt, contains('never translate or correct'));
      expect(prompt, contains('at most two sentences'));
      expect(prompt, contains('never rewrite'));
    });
  });
}
