import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LockMode { biometric, pin }

/// State of the unlock screen: biometric/PIN mode, PIN entry, failed attempts
/// and the temporary lockout that follows too many wrong PINs.
///
/// Attempts and lockout survive an app restart (SharedPreferences), so killing
/// the app does not reset the counter.
class LockScreenViewModel extends ChangeNotifier {
  LockScreenViewModel({
    required this.authenticate,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const int codeLength = 4;
  static const int maxAttempts = 3;
  static const Duration lockoutDuration = Duration(seconds: 30);

  static const _keyBiometrics = 'app_lock_biometrics_enabled';
  static const _keyPassword = 'app_lock_password';
  static const _keyFailed = 'app_lock_failed_attempts';
  static const _keyLockedUntil = 'app_lock_locked_until';

  /// Asks the platform for a biometric check; true when it succeeded.
  final Future<bool> Function() authenticate;
  final DateTime Function() _now;

  LockMode mode = LockMode.pin;
  bool biometricsEnabled = false;
  String input = '';

  /// Attempts left, shown only after a wrong PIN.
  int? attemptsLeft;
  Duration? lockedRemaining;
  bool unlocked = false;

  Timer? _timer;
  bool _disposed = false;

  bool get isLocked => lockedRemaining != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    biometricsEnabled = prefs.getBool(_keyBiometrics) ?? false;
    mode = biometricsEnabled ? LockMode.biometric : LockMode.pin;
    _startLockoutIfActive(prefs);
    _notify();
    if (biometricsEnabled && !isLocked) await tryBiometric();
  }

  Future<void> tryBiometric() async {
    if (isLocked) return;
    final ok = await authenticate();
    if (ok) _unlock();
  }

  void showPin() {
    mode = LockMode.pin;
    _notify();
  }

  void showBiometric() {
    mode = LockMode.biometric;
    _notify();
  }

  Future<void> pressKey(String digit) async {
    if (isLocked || input.length >= codeLength) return;
    input += digit;
    _notify();
    if (input.length == codeLength) await _check();
  }

  void deleteKey() {
    if (input.isEmpty) return;
    input = input.substring(0, input.length - 1);
    _notify();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_keyPassword) ?? '';
    if (stored.isEmpty || input == stored) {
      await prefs.remove(_keyFailed);
      await prefs.remove(_keyLockedUntil);
      input = '';
      _unlock();
      return;
    }
    final failed = (prefs.getInt(_keyFailed) ?? 0) + 1;
    input = '';
    if (failed >= maxAttempts) {
      await prefs.setInt(_keyFailed, 0);
      await prefs.setInt(
        _keyLockedUntil,
        _now().add(lockoutDuration).millisecondsSinceEpoch,
      );
      attemptsLeft = null;
      _startLockoutIfActive(prefs);
    } else {
      await prefs.setInt(_keyFailed, failed);
      attemptsLeft = maxAttempts - failed;
    }
    _notify();
  }

  void _startLockoutIfActive(SharedPreferences prefs) {
    final until = prefs.getInt(_keyLockedUntil);
    _timer?.cancel();
    if (until == null) return;
    final remaining = DateTime.fromMillisecondsSinceEpoch(until)
        .difference(_now());
    if (remaining <= Duration.zero) {
      prefs.remove(_keyLockedUntil);
      lockedRemaining = null;
      return;
    }
    lockedRemaining = remaining;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = DateTime.fromMillisecondsSinceEpoch(until)
          .difference(_now());
      if (left <= Duration.zero) {
        _timer?.cancel();
        lockedRemaining = null;
        prefs.remove(_keyLockedUntil);
        attemptsLeft = null;
        mode = biometricsEnabled ? LockMode.biometric : LockMode.pin;
      } else {
        lockedRemaining = left;
      }
      _notify();
    });
  }

  void _unlock() {
    unlocked = true;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
