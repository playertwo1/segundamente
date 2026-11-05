import 'package:flutter_test/flutter_test.dart';
import 'package:memex/domain/models/saved_view.dart';

void main() {
  test('a view needs a name and at least one tag; tags are deduplicated', () {
    expect(addSavedView(const [], id: 'v', name: ' ', tags: ['a']), isEmpty);
    expect(
        addSavedView(const [], id: 'v', name: 'x', tags: [' ', '']), isEmpty);
    final views = addSavedView(
      const [],
      id: 'v',
      name: ' Obra aberta ',
      tags: ['obra', 'tarefa', 'obra'],
    );
    expect(views.single.name, 'Obra aberta');
    expect(views.single.tags, ['obra', 'tarefa']);
  });

  test('names are unique ignoring case and accents; rename and delete', () {
    var views = addSavedView(const [], id: 'a', name: 'Reunião', tags: ['x']);
    expect(addSavedView(views, id: 'b', name: 'REUNIAO', tags: ['y']), views);
    views = addSavedView(views, id: 'b', name: 'Casa', tags: ['y']);
    expect(renameSavedView(views, 'b', 'reuniao'), views);
    expect(renameSavedView(views, 'b', 'Apartamento')[1].name, 'Apartamento');
    expect(removeSavedView(views, 'a').single.id, 'b');
  });

  test('round trips through JSON and rejects another schema', () {
    final views = addSavedView(const [], id: 'a', name: 'N', tags: ['t/u']);
    expect(savedViewsFromJson(savedViewsToJson(views)).single.tags, ['t/u']);
    expect(
      () => savedViewsFromJson({'schema_version': 9, 'views': []}),
      throwsFormatException,
    );
  });
}
