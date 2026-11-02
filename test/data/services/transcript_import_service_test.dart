import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memex/data/services/chat_session_storage.dart';
import 'package:memex/data/services/file_system_service.dart';
import 'package:memex/data/services/local_asset_server.dart';
import 'package:memex/data/services/transcript_import_service.dart';
import 'package:memex/domain/models/transcript_import.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const userId = 'transcript-import-user';
  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserStorage.initL10n();
    await UserStorage.saveUser(userId);
    tempDir = await Directory.systemTemp.createTemp('memex_transcript_import_');
    await FileSystemService.init(tempDir.path);
  });

  tearDown(() async {
    await LocalAssetServer.stopServer();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('stores nothing until confirm, then keeps the original bytes', () async {
    const raw = '00:01\r\n  olá  \r\n';
    final bytes = utf8.encode(raw);
    final parsed = TranscriptImport.parse(bytes);
    final service = TranscriptImportService();

    final declined = await service.saveIfConfirmed(
      userId: userId,
      sessionId: 'txt_declined',
      sources: [parsed],
      confirmed: false,
    );

    expect(declined, isFalse);
    expect(
      await Directory(
        FileSystemService.instance.getTranscriptImportsPath(userId),
      ).exists(),
      isFalse,
    );
    expect(
      await Directory(
        FileSystemService.instance.getChatSessionsPath(userId),
      ).exists(),
      isFalse,
    );

    final saved = await service.saveIfConfirmed(
      userId: userId,
      sessionId: 'txt_kept',
      sources: [parsed],
      confirmed: true,
    );
    expect(saved, isTrue);

    final original = File(
      p.join(
        FileSystemService.instance.getTranscriptImportsPath(userId),
        'txt_kept',
        '0',
        'original.bin',
      ),
    );
    expect(await original.readAsBytes(), bytes);

    final normalized = await File(
      p.join(original.parent.path, 'normalized.txt'),
    ).readAsString();
    expect(normalized, parsed.normalizedText);
    expect(normalized, '[00:00:01]\nolá');
    expect(normalized, isNot(raw));

    final messages = await ChatSessionStorage.instance.loadMessages(
      userId,
      'txt_kept',
    );
    final content = messages.single['content'] as List;
    expect(content.single['text'], parsed.outgoingText);

    await expectLater(
      service.saveIfConfirmed(
        userId: userId,
        sessionId: 'txt_kept',
        sources: [TranscriptImport.parse(utf8.encode('outro'))],
        confirmed: true,
      ),
      throwsStateError,
    );
    expect(await original.readAsBytes(), bytes);
  });

  test('a pasted text becomes a session only after confirm', () async {
    const pasted = 'nota colada sem relógio';
    final source = TranscriptImport.fromText(pasted);
    final service = TranscriptImportService();

    expect(
      await service.saveIfConfirmed(
        userId: userId,
        sessionId: 'paste_no',
        sources: [source],
        confirmed: false,
      ),
      isFalse,
    );

    expect(
      await service.saveIfConfirmed(
        userId: userId,
        sessionId: 'paste_yes',
        sources: [source],
        confirmed: true,
      ),
      isTrue,
    );
    final messages = await ChatSessionStorage.instance.loadMessages(
      userId,
      'paste_yes',
    );
    final content = messages.single['content'] as List;
    expect(content.single['text'], pasted);
  });

  test('PDF bytes are not stored', () async {
    final source = TranscriptImport.parse(
      <int>[0x25, 0x50, 0x44, 0x46, 0x2D, 0x31],
    );
    final saved = await TranscriptImportService().saveIfConfirmed(
      userId: userId,
      sessionId: 'pdf_no',
      sources: [source],
      confirmed: true,
    );

    expect(saved, isFalse);
    expect(
      await File(
        p.join(
          FileSystemService.instance.getTranscriptImportsPath(userId),
          'pdf_no',
          '0',
          'original.bin',
        ),
      ).exists(),
      isFalse,
    );
  });
}
