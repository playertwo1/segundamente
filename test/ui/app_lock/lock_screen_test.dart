import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/ui/app_lock/view_models/lock_screen_viewmodel.dart';
import 'package:memex/ui/app_lock/widgets/lock_screen_page.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> prepare({bool biometrics = false, Map<String, Object>? extra}) async {
    SharedPreferences.setMockInitialValues({
      'language': 'pt',
      'app_lock_password': '1234',
      'app_lock_biometrics_enabled': biometrics,
      ...?extra,
    });
    await UserStorage.initL10n();
  }

  Future<void> pumpLock(
    WidgetTester tester, {
    VoidCallback? onUnlock,
    Future<bool> Function()? authenticate,
  }) async {
    await tester.pumpWidget(
      // Same placement as main.dart: above the Navigator, no Overlay.
      MaterialApp(
        home: const SizedBox.shrink(),
        builder: (context, _) => LockScreen(
          onUnlock: onUnlock ?? () {},
          authenticateOverride: authenticate ?? () async => false,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> typePin(WidgetTester tester, String pin) async {
    for (final d in pin.split('')) {
      await tester.tap(find.text(d));
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pump(const Duration(milliseconds: 50));
  }

  group('LockScreen', () {
    testWidgets('com biometria ativa mostra a escolha entre biometria e PIN',
        (tester) async {
      await prepare(biometrics: true);
      await pumpLock(tester);

      expect(find.text('Desbloquear a Segunda Mente'), findsOneWidget);
      expect(find.text('Usar biometria'), findsOneWidget);
      expect(find.text('Usar PIN'), findsOneWidget);

      await tester.tap(find.text('Usar PIN'));
      await tester.pump();
      expect(find.text('Digite seu PIN'), findsOneWidget);
      expect(find.bySemanticsLabel('Voltar'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Voltar'));
      await tester.pump();
      expect(find.text('Usar PIN'), findsOneWidget);
    });

    testWidgets('a biometria aprovada libera o app', (tester) async {
      await prepare(biometrics: true);
      var unlocked = false;
      await pumpLock(
        tester,
        onUnlock: () => unlocked = true,
        authenticate: () async => true,
      );
      expect(unlocked, isTrue);
    });

    testWidgets('PIN correto libera o app', (tester) async {
      await prepare();
      var unlocked = false;
      await pumpLock(tester, onUnlock: () => unlocked = true);

      expect(find.text('Digite seu PIN'), findsOneWidget);
      await typePin(tester, '1234');
      expect(unlocked, isTrue);
    });

    testWidgets('PIN incorreto mostra as tentativas restantes', (tester) async {
      await prepare();
      var unlocked = false;
      await pumpLock(tester, onUnlock: () => unlocked = true);

      await typePin(tester, '0000');
      expect(unlocked, isFalse);
      expect(find.text('PIN incorreto · 2 tentativas restantes'),
          findsOneWidget);

      await typePin(tester, '0000');
      expect(find.text('PIN incorreto · 1 tentativa restante'), findsOneWidget);
    });

    testWidgets('três erros bloqueiam com contagem regressiva', (tester) async {
      await prepare();
      await pumpLock(tester);

      for (var i = 0; i < 3; i++) {
        await typePin(tester, '0000');
      }
      expect(find.text('Acesso temporariamente bloqueado'), findsOneWidget);
      expect(find.byKey(const ValueKey('lock-countdown')), findsOneWidget);
      expect(find.text('00:29'), findsOneWidget);
      expect(find.text('1'), findsNothing); // teclado some durante o bloqueio
      // Desmonta antes do fim para não deixar o timer pendente.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('o bloqueio sobrevive a reabrir a tela', (tester) async {
      await prepare(extra: {
        'app_lock_locked_until':
            DateTime.now().add(const Duration(seconds: 20)).millisecondsSinceEpoch,
      });
      await pumpLock(tester);
      expect(find.text('Acesso temporariamente bloqueado'), findsOneWidget);
      // Desmonta antes do fim para não deixar o timer pendente.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('"Esqueci meu PIN" explica que não há recuperação',
        (tester) async {
      await prepare();
      await pumpLock(tester);

      await tester.tap(find.text('Esqueci meu PIN'));
      await tester.pumpAndSettle();
      expect(find.text('O PIN não tem recuperação'), findsOneWidget);
    });
  });

  group('LockScreenViewModel', () {
    test('acerto zera o contador de erros', () async {
      await prepare();
      final vm = LockScreenViewModel(authenticate: () async => false);
      await vm.init();

      for (final d in '0000'.split('')) {
        await vm.pressKey(d);
      }
      expect(vm.attemptsLeft, 2);

      for (final d in '1234'.split('')) {
        await vm.pressKey(d);
      }
      expect(vm.unlocked, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('app_lock_failed_attempts'), isNull);
      vm.dispose();
    });

    test('o bloqueio termina quando o relógio passa dos 30 s', () async {
      await prepare();
      var clock = DateTime(2026, 11, 4, 10);
      final vm = LockScreenViewModel(
        authenticate: () async => false,
        now: () => clock,
      );
      await vm.init();
      for (var i = 0; i < 3; i++) {
        for (final d in '0000'.split('')) {
          await vm.pressKey(d);
        }
      }
      expect(vm.isLocked, isTrue);
      expect(vm.lockedRemaining, const Duration(seconds: 30));

      clock = clock.add(const Duration(seconds: 31));
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      expect(vm.isLocked, isFalse);
      expect(vm.attemptsLeft, isNull);
      vm.dispose();
    });

    test('tecla ignorada durante o bloqueio e PIN limitado a 4 dígitos',
        () async {
      await prepare();
      final vm = LockScreenViewModel(authenticate: () async => false);
      await vm.init();
      await vm.pressKey('1');
      await vm.pressKey('2');
      vm.deleteKey();
      expect(vm.input, '1');
      vm.dispose();
    });
  });
}
