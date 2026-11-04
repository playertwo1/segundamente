import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/ui/core/widgets/character_avatar.dart';
import 'package:memex/ui/core/widgets/dicebear_avatar.dart';
import 'package:memex/ui/core/widgets/local_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('CharacterAvatar routes HEIC media paths through LocalImage', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CharacterAvatar(
          avatar: 'workspace/_user/_System/media/avatar.heic',
          name: 'User',
        ),
      ),
    );

    expect(find.byType(LocalImage), findsOneWidget);
    expect(find.byType(DiceBearAvatar), findsNothing);
  });

  testWidgets('CharacterAvatar draws a bundled portrait from the app assets', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CharacterAvatar(
          avatar: 'asset://characters/curador.png',
          name: 'Curador',
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(
        (image.image as AssetImage).assetName, 'assets/characters/curador.png');
    expect(find.byType(LocalImage), findsNothing);
    expect(find.byType(DiceBearAvatar), findsNothing);
  });

  testWidgets('DiceBearAvatar shows a stable placeholder for empty seeds', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: DiceBearAvatar(seed: null, size: 48)),
    );

    expect(find.byIcon(Icons.person), findsOneWidget);
  });
}
