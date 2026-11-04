import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// The owner decided not to use Chinese mirrors: the speech model comes only
// from the GitHub release, and the download dialog offers no other source.
void main() {
  test('speech model download has no Chinese mirror path', () {
    final service =
        File('lib/data/services/whisper_service.dart').readAsStringSync();
    expect(service, isNot(contains('hf-mirror')));
    expect(service, isNot(contains('useChineseMirror')));
    expect(service, contains('github.com/k2-fsa/sherpa-onnx/releases'));

    final main = File('lib/main.dart').readAsStringSync();
    expect(main, isNot(contains('speechModelChinaMirror')));
    expect(main, isNot(contains('useChineseMirror')));
    expect(main, contains('speechModelStartDownload'));

    for (final arb in ['lib/l10n/app_en.arb', 'lib/l10n/app_pt.arb']) {
      expect(File(arb).readAsStringSync(), isNot(contains('China Mirror')),
          reason: arb);
    }
  });
}
