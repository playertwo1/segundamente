import 'package:flutter_test/flutter_test.dart';
import 'package:memex/config/app_config.dart';
import 'package:memex/config/app_flavor.dart';
import 'package:memex/domain/models/llm_config.dart';

void main() {
  group('AppConfig.availableProviders', () {
    test('offers no Chinese provider (D-024)', () {
      AppFlavor.init('global');

      for (final type in LLMConfig.removedTypes) {
        expect(AppConfig.availableProviders, isNot(contains(type)));
      }
    });

    test('excludes Memex proxy service from manual providers', () {
      AppFlavor.init('global');

      expect(
          AppConfig.availableProviders, isNot(contains(LLMConfig.typeMemex)));
      expect(AppConfig.enableMemexModelService, isTrue);
    });
  });
}
