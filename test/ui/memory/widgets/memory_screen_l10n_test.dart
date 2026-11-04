import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/data/repositories/memex_router.dart';
import 'package:memex/ui/core/widgets/editorial_scaffold.dart';
import 'package:memex/ui/memory/view_models/memory_viewmodel.dart';
import 'package:memex/ui/memory/widgets/memory_screen.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeMemoryViewModel extends MemoryViewModel {
  _FakeMemoryViewModel({
    this.data = const {
      'archived_memory': '',
      'recent_buffer': <Map<String, dynamic>>[],
    },
  }) : super(router: MemexRouter());

  final Map<String, dynamic> data;

  @override
  Future<void> loadMemory() async {
    isLoading = false;
    memoryData = data;
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'language': 'en'});
    await UserStorage.initL10n();
  });

  testWidgets('MemoryScreen shows localized title and empty states', (
    tester,
  ) async {
    final vm = _FakeMemoryViewModel();

    await tester.pumpWidget(
      MaterialApp(
        home: MemoryScreen(viewModel: vm),
      ),
    );
    await tester.pump();

    expect(find.text(UserStorage.l10n.memoryTitle), findsOneWidget);
    expect(find.text(UserStorage.l10n.longTermProfile), findsOneWidget);
    expect(find.text(UserStorage.l10n.recentBuffer), findsOneWidget);
    expect(find.text(UserStorage.l10n.memoryNoLongTermYet), findsOneWidget);
    expect(find.byType(EditorialScaffold), findsOneWidget);
  });

  testWidgets('MemoryScreen renders recent memories as open editorial rows', (
    tester,
  ) async {
    final vm = _FakeMemoryViewModel(
      data: {
        'archived_memory': '',
        'recent_buffer': [
          {
            'subject': 'Project',
            'content': 'Reviewed the project plan.',
            'created_at': '2026-01-02T15:04:00.000Z',
          },
        ],
      },
    );

    await tester.pumpWidget(MaterialApp(home: MemoryScreen(viewModel: vm)));
    await tester.pump();
    await tester.tap(find.text(UserStorage.l10n.recentBuffer));
    await tester.pumpAndSettle();

    expect(find.text('Project'), findsOneWidget);
    expect(find.text('Reviewed the project plan.'), findsOneWidget);
    expect(find.byType(EditorialRow), findsOneWidget);
    expect(find.byType(Card), findsNothing);
  });
}
