import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:memex/domain/models/card_model.dart';
import 'package:memex/domain/models/timeline_card_model.dart';
import 'package:memex/ui/core/themes/app_colors.dart';
import 'package:memex/ui/timeline/widgets/timeline_screen.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'language': 'pt'});
    await UserStorage.initL10n();
    await initializeDateFormatting('pt');
  });

  testWidgets('timeline entry: time column left, content right, divider below',
      (tester) async {
    final now = DateTime.now();
    final at = DateTime(now.year, now.month, now.day, 9, 30);
    var taps = 0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TimelineEntryItem(
          card: TimelineCardModel(
            id: 'c1',
            timestamp: at,
            tags: const [],
            status: 'completed',
            uiConfigs: [
              UiConfig(
                templateId: 'classic_card',
                data: const {'content': 'Caminhada cedo'},
              ),
            ],
          ),
          attachments: const [],
          onTap: () => taps++,
        ),
      ),
    ));
    await tester.pump();

    final time = find.text(DateFormat.Hm('pt').format(at));
    final content = find.textContaining('Caminhada cedo');
    expect(time, findsOneWidget);
    expect(content, findsOneWidget);
    expect(tester.getTopLeft(time).dx, lessThan(tester.getTopLeft(content).dx));

    final row = tester.widget<DecoratedBox>(
        find.ancestor(of: time, matching: find.byType(DecoratedBox)).last);
    final border = (row.decoration as BoxDecoration).border! as Border;
    expect(border.bottom.color, AppColors.divider);

    await tester.tap(content);
    expect(taps, 1);
  });
}
