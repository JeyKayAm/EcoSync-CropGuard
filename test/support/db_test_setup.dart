import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Test-only [PathProviderPlatform] that points the app's documents
/// directory at a throwaway temp folder, so [DatabaseHelper] can copy and
/// open `cropguard.db` on the host machine exactly as it would on-device.
class FakePathProviderPlatform extends PathProviderPlatform {
  final Directory _dir;

  FakePathProviderPlatform(this._dir);

  @override
  Future<String?> getApplicationDocumentsPath() async => _dir.path;
}

/// Wires [DatabaseHelper] up to a real SQLite engine (via FFI, so no
/// platform channel / device is required) and a temp "documents"
/// directory. Call once from `setUpAll` in any test that touches the
/// database — unit or widget.
///
/// Every call gets its own temp directory, so `cropguard.db` is re-copied
/// from assets fresh for each test file (test files run in separate
/// isolates, so [DatabaseHelper.instance]'s cached connection never leaks
/// between them).
Directory initTestDatabaseEnvironment() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final tempDir = Directory.systemTemp.createTempSync('cropguard_test_');
  PathProviderPlatform.instance = FakePathProviderPlatform(tempDir);
  return tempDir;
}
