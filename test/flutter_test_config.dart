import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Every test gets an in-memory keystore; the real one is a platform channel.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  FlutterSecureStorage.setMockInitialValues({});
  await testMain();
}
