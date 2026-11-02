import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/config/app_flavor.dart';
import 'package:memex/domain/models/model_catalog.dart';
import 'package:memex/l10n/app_localizations.dart';
import 'package:memex/ui/settings/widgets/model_capability_matrix_view.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    AppFlavor.init('global');
    SharedPreferences.setMockInitialValues({});
    await UserStorage.initL10n();
  });

  Widget host(ModelCapabilityMatrix matrix) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: ModelCapabilityMatrixView(matrix: matrix)),
    );
  }

  testWidgets('warns when a probed capability is missing', (tester) async {
    final matrix = ModelCapabilityMatrix({
      ModelCapability.text: CapabilityVerdict.yes,
      ModelCapability.streaming: CapabilityVerdict.yes,
      ModelCapability.json: CapabilityVerdict.yes,
      ModelCapability.vision: CapabilityVerdict.no,
      ModelCapability.audio: CapabilityVerdict.no,
    });

    await tester.pumpWidget(host(matrix));

    expect(find.byKey(const ValueKey('model_capability_warning')), findsOneWidget);
    expect(
      find.text(UserStorage.l10n.capabilityMissingWarning('Vision, Audio')),
      findsOneWidget,
    );
  });

  testWidgets('stays quiet while every capability is still unknown', (
    tester,
  ) async {
    await tester.pumpWidget(host(ModelCapabilityMatrix.unknown()));

    expect(find.byKey(const ValueKey('model_capability_warning')), findsNothing);
    expect(find.textContaining('Text · Not tested'), findsOneWidget);
  });
}
