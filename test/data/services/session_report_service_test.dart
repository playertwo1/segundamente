import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memex/data/repositories/chat.dart';
import 'package:memex/data/services/chat_session_storage.dart';
import 'package:memex/data/services/file_system_service.dart';
import 'package:memex/data/services/local_asset_server.dart';
import 'package:memex/data/services/session_report_service.dart';
import 'package:memex/data/services/transcript_import_service.dart';
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
}
