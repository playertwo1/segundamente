import 'package:flutter_test/flutter_test.dart';
import 'package:memex/domain/models/tag_tree.dart';

void main() {
  List<String> names(List<TagTreeNode> nodes) =>
      nodes.map((n) => '${n.path}:${n.count}').toList();

  test('a simple tag stays at the root', () {
    final tree = buildTagTree([
      ['ideia'],
      ['ideia'],
      ['viagem'],
    ]);
    expect(names(tree), ['ideia:2', 'viagem:1']);
    expect(tree.every((n) => n.children.isEmpty), isTrue);
  });

  test('area/projeto nests under its parent and the parent sums its children',
      () {
    final tree = buildTagTree([
      ['trabalho/alfa'],
      ['trabalho/alfa'],
      ['trabalho/beta'],
      ['casa'],
    ]);
    expect(names(tree), ['trabalho:3', 'casa:1']);
    expect(names(tree.first.children), ['trabalho/alfa:2', 'trabalho/beta:1']);
    expect(tree.first.children.first.name, 'alfa');
  });

  test('a card counts once per node, even with several tags in one branch', () {
    final tree = buildTagTree([
      ['trabalho', 'trabalho/alfa', 'trabalho/beta'],
    ]);
    expect(names(tree), ['trabalho:1']);
    expect(names(tree.single.children), ['trabalho/alfa:1', 'trabalho/beta:1']);
  });

  test('deeper levels, stray slashes and blank tags are handled', () {
    final tree = buildTagTree([
      ['a/b/c'],
      [' a // b / d ', '', '/'],
    ]);
    expect(names(tree), ['a:2']);
    final b = tree.single.children.single;
    expect(b.path, 'a/b');
    expect(b.count, 2);
    expect(names(b.children), ['a/b/c:1', 'a/b/d:1']);
  });

  test('ties are ordered by name, ignoring case', () {
    final tree = buildTagTree([
      ['banana'],
      ['Abacate'],
    ]);
    expect(names(tree), ['Abacate:1', 'banana:1']);
  });

  test('no cards give an empty tree', () {
    expect(buildTagTree(const []), isEmpty);
    expect(buildTagTree([const <String>[]]), isEmpty);
  });
}
