import 'package:flutter_test/flutter_test.dart';
import 'package:memex/domain/models/tag_model.dart';
import 'package:memex/ui/card_attachments/card_attachment_data.dart';
import 'package:memex/ui/timeline/view_models/timeline_viewmodel.dart';
import 'package:memex/utils/result.dart';

void main() {
  late List<List<String>?> asked;
  late TimelineViewModel vm;

  setUp(() {
    asked = [];
    vm = TimelineViewModel.forTest(
      autoLoad: false,
      fetchTimelineCards: ({
        int page = 1,
        int limit = TimelineViewModel.pageLimit,
        List<String>? tags,
        DateTime? dateFrom,
        DateTime? dateTo,
      }) async {
        asked.add(tags);
        return const Ok([]);
      },
      fetchTags: () async => const Ok(<TagModel>[]),
      fetchAttachmentForCard: (_) async => const <CardAttachmentData>[],
      fetchPendingAttachments: () async => const <CardAttachmentData>[],
    );
  });

  test('a saved view asks for every tag, a single tag stays single', () async {
    vm.setTagFilters(['obra', 'tarefa']);
    await vm.loadCards(refresh: true);
    expect(asked.last, ['obra', 'tarefa']);

    vm.setActiveFilter('obra');
    await vm.loadCards(refresh: true);
    expect(asked.last, ['obra']);
    expect(vm.extraTags, isEmpty);
  });

  test('same first tag with other extras is a different filter', () async {
    vm.setTagFilters(['obra', 'tarefa']);
    vm.setTagFilters(['obra', 'ideia']);
    await vm.loadCards(refresh: true);
    expect(asked.last, ['obra', 'ideia']);
  });

  test('an empty view clears the filter', () async {
    vm.setTagFilters(['obra', 'tarefa']);
    vm.setTagFilters(const []);
    await vm.loadCards(refresh: true);
    expect(asked.last, isNull);
    expect(vm.activeFilter, 'all');
  });
}
