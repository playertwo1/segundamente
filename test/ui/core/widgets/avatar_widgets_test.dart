import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memex/ui/core/widgets/avatar_picker.dart';
import 'package:memex/ui/core/widgets/character_avatar.dart';
import 'package:memex/ui/core/widgets/dicebear_avatar.dart';
import 'package:memex/ui/core/widgets/local_image.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  testWidgets('avatar picker shows and returns the bundled portraits', (
    tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({'language': 'pt'});
    await UserStorage.initL10n();

    const currentAvatar = 'asset://characters/curador.png';
    late Future<String?> pickedAvatar;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () {
                  pickedAvatar = showAvatarPicker(context, currentAvatar);
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    final visibleAvatars = tester
        .widgetList<CharacterAvatar>(find.byType(CharacterAvatar))
        .map((avatar) => avatar.avatar)
        .toSet();
    expect(visibleAvatars, {
      'asset://characters/advogado_diabo.png',
      'asset://characters/amigo_bar.png',
      'asset://characters/calmo_crise.png',
      'asset://characters/cobrador_prazo.png',
      'asset://characters/curador.png',
      'asset://characters/diario_bordo.png',
      'asset://characters/financas_burocracia.png',
      'asset://characters/gerente_escopo.png',
      'asset://characters/guardiao_energia.png',
      'asset://characters/memoria_projeto.png',
      'asset://characters/parceiro_foco.png',
      'asset://characters/provocador_criativo.png',
      'asset://characters/revisor_chato.png',
      'asset://characters/socio_tecnico.png',
      'asset://characters/tradutor.png',
    });
    expect(find.byType(DiceBearAvatar), findsNothing);

    final amigoBarImage = find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName ==
              'assets/characters/amigo_bar.png',
    );
    await tester.ensureVisible(amigoBarImage);
    await tester.tap(amigoBarImage);
    await tester.pumpAndSettle();

    expect(await pickedAvatar, 'asset://characters/amigo_bar.png');
  });
}
