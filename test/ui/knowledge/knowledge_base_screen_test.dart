import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/data/repositories/memex_router.dart';
import 'package:memex/ui/knowledge/view_models/knowledge_base_viewmodel.dart';
import 'package:memex/ui/knowledge/widgets/knowledge_base_screen.dart';
import 'package:memex/utils/user_storage.dart';

void main() {
  setUpAll(() async {
    await UserStorage.initL10n();
  });

  test('root listing helpers keep non-PARA folders and root files', () {
    final folders = additionalRootFoldersFromListing({
      'items': [
        {
          'name': 'Projects',
          'path': 'Projects',
          'is_directory': true,
        },
        {
          'name': 'Projects (Projekte)',
          'path': 'Projects (Projekte)',
          'is_directory': true,
        },
        {
          'name': 'Inbox',
          'path': 'Inbox',
          'is_directory': true,
        },
        {
          'name': 'Loose note.md',
          'path': 'Loose note.md',
          'is_directory': false,
        },
      ],
    });

    expect(
      folders.map((folder) => folder['path']),
      ['Inbox', 'Projects (Projekte)'],
    );

    final files = rootFilesFromListing({
      'items': [
        {
          'name': 'Projects',
          'path': 'Projects',
          'is_directory': true,
        },
        {
          'name': 'Loose note.md',
          'path': 'Loose note.md',
          'is_directory': false,
        },
      ],
    });

    expect(
      files.map((file) => file['path']),
      ['Loose note.md'],
    );
  });

  testWidgets(
      'renders additional root folders and files below fixed PARA cards',
      (tester) async {
    final viewModel = KnowledgeBaseViewModel(router: MemexRouter())
      ..categoryCounts = {
        'Projects': 0,
        'Areas': 0,
        'Resources': 0,
        'Archives': 0,
        'Projects (Projekte)': 2,
      }
      ..additionalRootFolders = [
        {
          'name': 'Projects (Projekte)',
          'path': 'Projects (Projekte)',
          'is_directory': true,
          'item_count': 2,
        },
      ]
      ..rootLevelFiles = [
        {
          'name': 'Loose note.md',
          'path': 'Loose note.md',
          'is_directory': false,
          'is_ai_generated': false,
        },
      ];

    var menuTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: KnowledgeBaseScreen(
          viewModel: viewModel,
          onMenuTap: () => menuTaps++,
        ),
      ),
    );

    // P.A.R.A. is a grouped list (D-017): one labeled row per category.
    for (final label in [
      UserStorage.l10n.pkmCategoryProject,
      UserStorage.l10n.pkmCategoryArea,
      UserStorage.l10n.pkmCategoryResource,
      UserStorage.l10n.pkmCategoryArchive,
    ]) {
      expect(
        find.ancestor(of: find.text(label), matching: find.byType(ListTile)),
        findsOneWidget,
      );
    }
    expect(find.byType(GridView), findsNothing);

    // Extra root folders keep their name and item count as a row.
    final folderRow = find.ancestor(
      of: find.text('Projects (Projekte)'),
      matching: find.byType(ListTile),
    );
    expect(folderRow, findsOneWidget);
    expect(
      find.descendant(of: folderRow, matching: find.text('2')),
      findsOneWidget,
    );
    expect(find.text('Loose note.md'), findsOneWidget);

    await tester.tap(find.byTooltip(UserStorage.l10n.navMenu));
    expect(menuTaps, 1);
  });
}
