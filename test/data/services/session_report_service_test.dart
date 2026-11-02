import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memex/data/repositories/chat.dart';
import 'package:memex/data/services/chat_session_storage.dart';
import 'package:memex/data/services/file_system_service.dart';
import 'package:memex/data/services/local_asset_server.dart';
import 'package:memex/data/services/session_report_export_service.dart';
import 'package:memex/data/services/session_report_service.dart';
import 'package:memex/domain/models/session_report_export.dart';
import 'package:memex/data/services/transcript_import_service.dart';
import 'package:memex/domain/models/report_memory.dart';
import 'package:memex/domain/models/session_report.dart';
import 'package:memex/domain/models/transcript_import.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const userId = 'session-report-user';
  const sessionId = 'txt_report';
  late Directory tempDir;
  late SessionReportService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserStorage.initL10n();
    await UserStorage.saveUser(userId);
    tempDir = await Directory.systemTemp.createTemp('memex_session_report_');
    await FileSystemService.init(tempDir.path);
    service = SessionReportService();
  });

  tearDown(() async {
    await LocalAssetServer.stopServer();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<File> storeTranscript() async {
    const raw = '00:01\nfechar o escopo\n00:02\nmandar o resumo\n';
    final bytes = utf8.encode(raw);
    await TranscriptImportService().saveIfConfirmed(
      userId: userId,
      sessionId: sessionId,
      sources: [TranscriptImport.parse(bytes)],
      confirmed: true,
    );
    return File(
      p.join(
        FileSystemService.instance.getTranscriptImportsPath(userId),
        sessionId,
        '0',
        'original.bin',
      ),
    );
  }

  test('draft, edit and model json keep the original bytes', () async {
    final original = await storeTranscript();
    final bytes = await original.readAsBytes();

    final meeting = await service.draft(
      userId: userId,
      sessionId: sessionId,
      kind: ReportKind.reuniao,
      customTitle: null,
    );
    final study = await service.draft(
      userId: userId,
      sessionId: sessionId,
      kind: ReportKind.estudo,
      customTitle: null,
    );

    expect(meeting.title, isNot(study.title));
    expect(study.items[1].kind, ReportItemKind.question);
    expect(await original.readAsBytes(), bytes);

    final edited = await service.editItem(
      userId: userId,
      sessionId: sessionId,
      itemId: 'item_2',
      text: 'enviar depois',
      assignee: 'Rafael',
      due: 'sexta',
    );
    expect(edited.items[1].text, 'enviar depois');
    expect(edited.items[1].source.excerpt, 'mandar o resumo');
    expect(await original.readAsBytes(), bytes);

    final applied = await service.applyModelJson(
      userId: userId,
      sessionId: sessionId,
      kind: ReportKind.reuniao,
      customTitle: null,
      json: {
        'schema_version': 1,
        'items': [
          {
            'kind': 'task',
            'text': 'mandar o resumo',
            'segment_id': 'seg_1',
            'excerpt': 'resumo',
            'clock': '00:00:02',
            'status': 'approved',
            'assignee': 'Ana',
            'due': 'amanhã',
          },
        ],
      },
    );
    expect(applied.items.single.status, ReportItemStatus.unconfirmed);
    expect(applied.items.single.assignee, reportAssigneeUnknown);
    expect(applied.items.single.due, reportDueUnknown);
    expect(await original.readAsBytes(), bytes);
  });

  test('an approved item blocks a new draft', () async {
    await storeTranscript();
    await service.draft(
      userId: userId,
      sessionId: sessionId,
      kind: ReportKind.reuniao,
      customTitle: null,
    );
    await service.setStatus(
      userId: userId,
      sessionId: sessionId,
      itemId: 'item_1',
      status: ReportItemStatus.approved,
    );

    expect(
      () => service.draft(
        userId: userId,
        sessionId: sessionId,
        kind: ReportKind.estudo,
        customTitle: null,
      ),
      throwsStateError,
    );
    final kept = await service.load(userId: userId, sessionId: sessionId);
    expect(kept!.kind, ReportKind.reuniao);
  });

  test('version 0 on disk migrates to version 1', () async {
    final file = File(
      p.join(
        FileSystemService.instance.getSessionReportsPath(userId),
        sessionId,
        'report.json',
      ),
    );
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({
        'schema_version': 0,
        'session_id': sessionId,
        'type': 'study',
        'entries': [
          {
            'type': 'question',
            'body': 'qual o prazo',
            'segment_id': 'seg_0',
            'quote': 'qual o prazo',
          },
        ],
      }),
    );

    final loaded = await service.load(userId: userId, sessionId: sessionId);
    expect(loaded!.schemaVersion, sessionReportSchemaVersion);
    expect(loaded.kind, ReportKind.estudo);
    final stored = jsonDecode(await file.readAsString()) as Map;
    expect(stored['schema_version'], sessionReportSchemaVersion);
  });

  test('deleting the session removes the report and keeps the original',
      () async {
    final original = await storeTranscript();
    final bytes = await original.readAsBytes();
    await service.draft(
      userId: userId,
      sessionId: sessionId,
      kind: ReportKind.livre,
      customTitle: null,
    );

    final removed = await deleteChatSessionEndpoint(sessionId);
    expect(removed, isTrue);
    expect(
      await service.load(userId: userId, sessionId: sessionId),
      isNull,
    );
    expect(await original.readAsBytes(), bytes);
    expect(
      await ChatSessionStorage.instance.sessionExists(userId, sessionId),
      isFalse,
    );
  });

  test('export writes the three files and delete removes them', () async {
    final original = await storeTranscript();
    final bytes = await original.readAsBytes();
    await service.draft(
      userId: userId,
      sessionId: sessionId,
      kind: ReportKind.reuniao,
      customTitle: null,
    );
    final exporter = SessionReportExportService();
    final exportedAt = DateTime(2026, 11, 2, 15, 4);
    final written = <String>[];
    for (final format in ReportExportFormat.values) {
      final file = await exporter.write(
        userId: userId,
        sessionId: sessionId,
        format: format,
        exportedAt: exportedAt,
      );
      written.add(file.path);
      expect(await file.exists(), isTrue);
      expect(file.path, endsWith(reportExportFileName(format)));
    }
    expect(await original.readAsBytes(), bytes);

    final removed = await deleteChatSessionEndpoint(sessionId);
    expect(removed, isTrue);
    for (final path in written) {
      expect(await File(path).exists(), isFalse);
    }
    expect(await original.readAsBytes(), bytes);
  });

  test('follow-ups, text search and revisions stay beside the report', () async {
    final original = await storeTranscript();
    final bytes = await original.readAsBytes();
    const otherId = 'txt_other';
    await TranscriptImportService().saveIfConfirmed(
      userId: userId,
      sessionId: otherId,
      sources: [
        TranscriptImport.parse(utf8.encode('00:01\noutro assunto\n')),
      ],
      confirmed: true,
    );

    final meeting = await service.draft(
      userId: userId,
      sessionId: sessionId,
      kind: ReportKind.reuniao,
      customTitle: null,
    );
    await service.draft(
      userId: userId,
      sessionId: otherId,
      kind: ReportKind.reuniao,
      customTitle: null,
    );
    final followUp = meeting.items[1];
    expect(followUp.kind, ReportItemKind.followUp);

    await service.setStatus(
      userId: userId,
      sessionId: sessionId,
      itemId: followUp.id,
      status: ReportItemStatus.approved,
      at: '2026-11-02T15:04:00',
    );
    final panel = await service.approvedFollowUps(userId: userId);
    expect(panel, hasLength(1));
    expect(panel.single.sessionId, sessionId);
    expect(panel.single.item.text, 'mandar o resumo');

    final found = await service.search(userId: userId, query: 'escopo');
    expect(found.single.sessionId, sessionId);
    expect(await service.search(userId: userId, query: 'assunto'), hasLength(1));

    await service.editItem(
      userId: userId,
      sessionId: sessionId,
      itemId: meeting.items.first.id,
      text: 'fechar depois',
      assignee: reportAssigneeUnknown,
      due: reportDueUnknown,
      at: '2026-11-02T15:05:00',
    );
    await service.editItem(
      userId: userId,
      sessionId: sessionId,
      itemId: meeting.items.first.id,
      text: 'fechar depois',
      assignee: 'Ana',
      due: reportDueUnknown,
      at: '2026-11-02T15:06:00',
    );
    final changes = await service.latestTextChanges(userId: userId);
    final change = changes[reportHitKey(sessionId, meeting.items.first.id)];
    expect(change, isNotNull);
    expect(change!.before, 'fechar o escopo');
    expect(change.after, 'fechar depois');

    final revisions = File(
      p.join(
        FileSystemService.instance.getSessionReportsPath(userId),
        sessionId,
        'revisions.json',
      ),
    );
    expect(await revisions.exists(), isTrue);
    await service.deleteDerivatives(userId: userId, sessionId: sessionId);
    expect(await revisions.exists(), isFalse);
    expect(await original.readAsBytes(), bytes);
  });
}
