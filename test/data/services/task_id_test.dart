import 'package:flutter_test/flutter_test.dart';
import 'package:memex/data/services/local_task_executor.dart';

void main() {
  test('task ids never repeat, even when created back to back', () {
    final ids = [for (var i = 0; i < 20000; i++) nextTaskId()];
    expect(ids.toSet(), hasLength(ids.length));
    final numeric = ids.map(int.parse).toList();
    for (var i = 1; i < numeric.length; i++) {
      expect(numeric[i], greaterThan(numeric[i - 1]));
    }
  });
}
