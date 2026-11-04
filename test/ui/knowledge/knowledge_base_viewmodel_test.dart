import 'package:flutter_test/flutter_test.dart';
import 'package:memex/data/repositories/memex_router.dart';
import 'package:memex/ui/knowledge/view_models/knowledge_base_viewmodel.dart';
import 'package:memex/utils/result.dart';

void main() {
  test('loads guide candidates from the existing Resources listing', () async {
    final router = _FakeRouter();
    final viewModel = KnowledgeBaseViewModel(router: router);
    addTearDown(viewModel.dispose);

    await viewModel.fetchData();

    expect(router.listedPaths, [null, 'Resources']);
    expect(viewModel.resourcesFiles.single['path'], 'Resources/Guia.md');
  });
}

class _FakeRouter implements MemexRouter {
  final listedPaths = <String?>[];

  @override
  Future<Result<Map<String, dynamic>>> listPkmDirectory({String? path}) async {
    listedPaths.add(path);
    return Ok({
      'items': path == null
          ? [
              {'name': 'Resources', 'path': 'Resources', 'is_directory': true},
            ]
          : [
              {
                'name': 'Guia.md',
                'path': 'Resources/Guia.md',
                'is_directory': false,
              },
            ],
    });
  }

  @override
  Future<Result<Map<String, int>>> countPkmItems(List<String> paths) async =>
      const Ok({});

  @override
  Future<Result<List<Map<String, dynamic>>>> getRecentPkmFiles({
    int limit = 10,
  }) async =>
      const Ok([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
