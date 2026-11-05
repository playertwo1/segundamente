import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/db/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    var i = 0;
    Future<void> add(String tags) => db.cardDao.upsertCard(
          CardCacheCompanion.insert(
            factId: 'f${i++}',
            cardPath: 'p',
            timestamp: 1000 + i,
            tags: tags,
          ),
        );
    await add('["area"]');
    await add('["area/alfa","ideia"]');
    await add('["areas"]');
    await add('["outra/area"]');
    await add('["ideia"]');
    await add('not json');
  });

  tearDown(() => db.close());

  Future<Set<String>> ids(List<String> tags) async =>
      (await db.cardDao.getCards(tags: tags, limit: 50))
          .map((c) => c.factId)
          .toSet();

  test('a parent tag also returns the cards under it', () async {
    expect(await ids(['area']), {'f0', 'f1'});
  });

  test('a child tag does not return its parent or siblings', () async {
    expect(await ids(['area/alfa']), {'f1'});
    expect(await ids(['ideia']), {'f1', 'f4'});
  });

  test('similar names and other branches do not match', () async {
    final result = await ids(['area']);
    expect(result, isNot(contains('f2'))); // areas
    expect(result, isNot(contains('f3'))); // outra/area
  });

  test('several tags need every one of them, parents included', () async {
    expect(await ids(['area', 'ideia']), {'f1'});
    expect(await ids(['area/alfa', 'ideia']), {'f1'});
    expect(await ids(['area', 'areas']), isEmpty);
  });

  test('every card gives its tag list and a malformed row counts as untagged',
      () async {
    final lists = await db.cardDao.getAllTagLists();
    expect(lists, hasLength(6));
    expect(
        lists,
        containsAll([
          ['area'],
          ['area/alfa', 'ideia'],
          ['areas'],
          ['outra/area'],
          ['ideia'],
          <String>[],
        ]));
  });
}
