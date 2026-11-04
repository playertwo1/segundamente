import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:memex/ui/app_lock/view_models/lock_screen_viewmodel.dart';
import 'package:memex/ui/core/themes/app_colors.dart';
import 'package:memex/ui/core/widgets/memex_brand_title.dart';
import 'package:memex/utils/user_storage.dart';

/// Unlock screen (reference 15): biometric prompt, PIN entry with attempt
/// counter and a temporary lockout. The rules live in [LockScreenViewModel].
class LockScreen extends StatefulWidget {
  final VoidCallback onUnlock;

  /// Replaces the platform biometric check (tests).
  final Future<bool> Function()? authenticateOverride;

  const LockScreen({
    super.key,
    required this.onUnlock,
    this.authenticateOverride,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  late final LockScreenViewModel _vm;
  final LocalAuthentication _auth = LocalAuthentication();
  bool _notified = false;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _vm = LockScreenViewModel(
      authenticate: widget.authenticateOverride ?? _authenticate,
    )..addListener(_onChanged);
    _vm.init();
  }

  @override
  void dispose() {
    _vm.removeListener(_onChanged);
    _vm.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (_vm.unlocked && !_notified) {
      _notified = true;
      widget.onUnlock();
    }
  }

  Future<bool> _authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: UserStorage.l10n.useFingerprintToUnlock,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
        authMessages: <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: UserStorage.l10n.locked,
            biometricHint: '',
            cancelButton: UserStorage.l10n.cancel,
          ),
        ],
      );
    } on PlatformException catch (_) {
      return false; // cancelled or unavailable: stay on the lock screen
    }
  }

  Future<void> _showForgotPin() {
    final l10n = UserStorage.l10n;
    return showDialog<void>(
      context: _navigatorKey.currentContext ?? context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.lockForgotPinTitle),
        content: Text(l10n.lockForgotPinBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  /// The lock is stacked above the app's Navigator in `main.dart`, so it brings
  /// its own Navigator (dialogs and tooltips need a Navigator/Overlay).
  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _navigatorKey,
      onGenerateRoute: (_) => MaterialPageRoute<void>(builder: _buildLock),
    );
  }

  Widget _buildLock(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _vm,
          builder: (context, _) {
            return Column(
              children: [
                SizedBox(
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_vm.mode == LockMode.pin &&
                          _vm.biometricsEnabled &&
                          !_vm.isLocked)
                        Align(
                          alignment: Alignment.centerLeft,
                          // No tooltip: the lock sits above the Navigator, so
                          // there is no Overlay for it.
                          child: Semantics(
                            label: UserStorage.l10n.lockBack,
                            button: true,
                            excludeSemantics: true,
                            child: IconButton(
                              icon: const Icon(
                                Icons.chevron_left,
                                color: AppColors.textPrimary,
                                size: 28,
                              ),
                              onPressed: _vm.showBiometric,
                            ),
                          ),
                        ),
                      const MemexBrandTitle(),
                    ],
                  ),
                ),
                Expanded(
                  child: _vm.isLocked
                      ? _LockedView(remaining: _vm.lockedRemaining!)
                      : _vm.mode == LockMode.biometric
                          ? _BiometricView(
                              onBiometric: _vm.tryBiometric,
                              onPin: _vm.showPin,
                            )
                          : _PinView(vm: _vm, onForgot: _showForgotPin),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

final ButtonStyle _linkStyle = TextButton.styleFrom(
  minimumSize: const Size(160, 48),
);

class _BiometricView extends StatelessWidget {
  const _BiometricView({required this.onBiometric, required this.onPin});

  final VoidCallback onBiometric;
  final VoidCallback onPin;

  @override
  Widget build(BuildContext context) {
    final l10n = UserStorage.l10n;
    return Column(
      children: [
        const Spacer(flex: 2),
        Text(
          l10n.lockUnlockTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        ExcludeSemantics(
          child: InkResponse(
            onTap: onBiometric,
            radius: 56,
            child: const Icon(
              Icons.fingerprint,
              size: 96,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            l10n.lockConfirmIdentity,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onBiometric,
          style: _linkStyle,
          child: Text(
            l10n.lockUseBiometrics,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
        ),
        TextButton(
          onPressed: onPin,
          style: _linkStyle,
          child: Text(
            l10n.lockUsePin,
            style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

class _PinView extends StatelessWidget {
  const _PinView({required this.vm, required this.onForgot});

  final LockScreenViewModel vm;
  final VoidCallback onForgot;

  @override
  Widget build(BuildContext context) {
    final l10n = UserStorage.l10n;
    final left = vm.attemptsLeft;
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          l10n.lockEnterPin,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(LockScreenViewModel.codeLength, (i) {
            final filled = i < vm.input.length;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? AppColors.textPrimary : Colors.transparent,
                border: Border.all(color: AppColors.textPrimary, width: 1.5),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 24,
          child: left == null
              ? null
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 18,
                      color: AppColors.textPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.lockWrongPin(left),
                      key: const ValueKey('lock-wrong-pin'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
        ),
        const Spacer(),
        _Keypad(vm: vm),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onForgot,
          style: _linkStyle,
          child: Text(
            l10n.lockForgotPin,
            style: const TextStyle(fontSize: 16, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.vm});

  final LockScreenViewModel vm;

  @override
  Widget build(BuildContext context) {
    Widget row(List<String> keys) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: keys.map((k) => _Key(label: k, vm: vm)).toList(),
          ),
        );
    return Column(
      children: [
        row(['1', '2', '3']),
        row(['4', '5', '6']),
        row(['7', '8', '9']),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 88, height: 72),
            _Key(label: '0', vm: vm),
            SizedBox(
              width: 88,
              height: 72,
              child: Semantics(
                label: UserStorage.l10n.lockDeleteDigit,
                button: true,
                excludeSemantics: true,
                child: IconButton(
                  icon: const Icon(
                    Icons.backspace_outlined,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: vm.deleteKey,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.vm});

  final String label;
  final LockScreenViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkResponse(
        onTap: () {
          HapticFeedback.lightImpact();
          vm.pressKey(label);
        },
        radius: 40,
        child: Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.textSecondary, width: 1),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _LockedView extends StatelessWidget {
  const _LockedView({required this.remaining});

  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final l10n = UserStorage.l10n;
    final seconds = remaining.inSeconds.clamp(0, 3600);
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return Column(
      children: [
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            l10n.lockTempBlockedTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Icon(
          Icons.lock_clock_outlined,
          size: 96,
          color: AppColors.textPrimary,
        ),
        const SizedBox(height: 16),
        Text(
          '$mm:$ss',
          key: const ValueKey('lock-countdown'),
          style: const TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.lockTempBlockedBody,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.lockAvailableIn(seconds),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 64,
              color: AppColors.textPrimary,
            ),
            const SizedBox(height: 24),
            Text(
              UserStorage.l10n.memexLocked,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
