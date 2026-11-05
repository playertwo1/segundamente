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
    await add('["obra_1"]');
    await add('["obra21"]');
    await add('["100%"]');
    await add('["1000"]');
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

  test('underscore and percent in a tag are literal, not wildcards', () async {
    expect(await ids(['obra_1']), {'f6'});
    expect(await ids(['100%']), {'f8'});
  });

  test('several tags need every one of them, parents included', () async {
    expect(await ids(['area', 'ideia']), {'f1'});
    expect(await ids(['area/alfa', 'ideia']), {'f1'});
    expect(await ids(['area', 'areas']), isEmpty);
  });

  test('every card gives its tag list and a malformed row counts as untagged',
      () async {
    final lists = await db.cardDao.getAllTagLists();
    expect(lists, hasLength(10));
    expect(
        lists,
        containsAll([
          ['area'],
          ['area/alfa', 'ideia'],
          ['areas'],
          ['outra/area'],
          ['ideia'],
          <String>[],
          ['obra_1'],
          ['obra21'],
          ['100%'],
          ['1000'],
        ]));
  });

  test('a property tag filters on the derived properties, AND with tags',
      () async {
    final two = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(two.close);
    var i = 0;
    Future<void> add(String tags, String props) => two.cardDao.upsertCard(
          CardCacheCompanion.insert(
            factId: 'p${i++}',
            cardPath: 'p',
            timestamp: 2000 + i,
            tags: tags,
            props: Value(props),
          ),
        );
    await add('["obra"]', '|open_task|task|');
    await add('["obra"]', '|task|');
    await add('["casa"]', '|link|open_task|task|');
    await add('["obra"]', '');

    Future<Set<String>> ask(List<String> tags) async =>
        (await two.cardDao.getCards(tags: tags, limit: 50))
            .map((c) => c.factId)
            .toSet();

    expect(await ask(['@prop:open_task']), {'p0', 'p2'});
    expect(await ask(['@prop:task']), {'p0', 'p1', 'p2'});
    expect(await ask(['obra', '@prop:open_task']), {'p0'});
    expect(await ask(['@prop:code']), isEmpty);
    // "task" must not match inside "open_task" only.
    expect(await ask(['@prop:link', '@prop:task']), {'p2'});
  });
}
