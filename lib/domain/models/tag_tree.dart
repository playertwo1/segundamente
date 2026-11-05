/// A node of the hierarchical tag tree. A tag such as `area/projeto` lives
/// under `area`; a tag without `/` sits at the root.
class TagTreeNode {
  TagTreeNode(this.name, this.path);

  /// Last segment, shown in the tree.
  final String name;

  /// Full tag, also the value used to filter cards.
  final String path;

  /// Distinct cards at this node or below it.
  int count = 0;

  final List<TagTreeNode> children = [];
}

/// Splits a tag into its non-empty, trimmed segments: `a//b/` -> [a, b].
List<String> tagSegments(String tag) => tag
    .split('/')
    .map((segment) => segment.trim())
    .where((segment) => segment.isNotEmpty)
    .toList();

/// Builds the tree from one tag list per card. A card counts once for every
/// ancestor of its tags, so a parent is the number of distinct cards under it
/// and never double counts a card tagged both `area` and `area/projeto`.
List<TagTreeNode> buildTagTree(Iterable<Iterable<String>> cardTags) {
  final roots = <TagTreeNode>[];
  final byPath = <String, TagTreeNode>{};

  TagTreeNode nodeFor(List<String> segments) {
    final path = segments.join('/');
    final existing = byPath[path];
    if (existing != null) return existing;
    final node = TagTreeNode(segments.last, path);
    byPath[path] = node;
    if (segments.length == 1) {
      roots.add(node);
    } else {
      nodeFor(segments.sublist(0, segments.length - 1)).children.add(node);
    }
    return node;
  }

  for (final tags in cardTags) {
    final counted = <String>{};
    for (final tag in tags) {
      final segments = tagSegments(tag);
      for (var depth = 1; depth <= segments.length; depth++) {
        final node = nodeFor(segments.sublist(0, depth));
        if (counted.add(node.path)) node.count++;
      }
    }
  }

  void sort(List<TagTreeNode> nodes) {
    nodes.sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      if (byCount != 0) return byCount;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    for (final node in nodes) {
      sort(node.children);
    }
  }

  sort(roots);
  return roots;
}
