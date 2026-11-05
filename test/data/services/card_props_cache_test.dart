import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/data/services/file_system_service.dart';
import 'package:memex/db/app_database.dart';
import 'package:memex/domain/models/card_model.dart';
import 'package:memex/domain/models/card_props.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const userId = 'props-user';
  late Directory tempDir;
  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('memex_card_props_');
    await FileSystemService.init(tempDir.path);
    db = AppDatabase.forTesting(NativeDatabase.memory());
    AppDatabase.setTestInstance(db);
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  CardData card(String id, List<UiConfig> ui, {String? fact}) => CardData(
        factId: id,
        timestamp: 1762300000,
        status: 'completed',
        tags: const ['obra'],
        uiConfigs: ui,
        fact: fact,
      );

  Future<Set<String>> ask(List<String> tags) async =>
      (await db.cardDao.getCards(tags: tags, limit: 50))
          .map((c) => c.factId)
          .toSet();

  test('writing a card stores its properties, and rewriting updates them',
      () async {
    final files = FileSystemService.instance;
    const open = '2026/11/05.md#ts_1';
    const done = '2026/11/05.md#ts_2';
    const note = '2026/11/05.md#ts_3';
    await files.safeWriteCardFile(
      userId,
      open,
      card(open, [
        const UiConfig(templateId: 'task', data: {'title': 'a'})
      ]),
    );
    await files.safeWriteCardFile(
      userId,
      done,
      card(done, [
        const UiConfig(templateId: 'task', data: {'is_completed': true}),
      ]),
    );
    await files.safeWriteCardFile(
      userId,
      note,
      card(note, const [],
          fact: 'veja https://exemplo.com e\n```\ncodigo\n```'),
    );

    expect(await ask([propTag(propOpenTask)]), {open});
    expect(await ask([propTag(propTask)]), {open, done});
    expect(await ask([propTag(propLink), propTag(propCode)]), {note});
    expect(await ask(['obra', propTag(propOpenTask)]), {open});

    // Completing the task removes it from the open ones.
    await files.safeWriteCardFile(
      userId,
      open,
      card(open, [
        const UiConfig(templateId: 'task', data: {'is_completed': true}),
      ]),
    );
    expect(await ask([propTag(propOpenTask)]), isEmpty);
  });
}
