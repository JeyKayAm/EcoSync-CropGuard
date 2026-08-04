// Widget test (Section 3.7.2): the Crop Selector on the home screen —
// a ListView of CropTile rows driven by AppStateProvider.
//
// Note on scope: `flutter test` runs widget tests inside a FakeAsync test
// zone that real plugin channels (sqflite, path_provider) can't complete
// in, so [AppStateProvider.init]'s real database read is driven via
// `tester.runAsync` (which briefly steps outside that zone) rather than
// awaited directly. Once `init()` has resolved, HomeScreen only reads the
// already-loaded provider state, so no further live-plugin calls happen
// during pumping. Navigating on from here into a second live-data screen
// is exercised by the integration test (Section 3.7.3) instead, since that
// runs on a real engine/device where this restriction doesn't apply.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecosync_cropguard/providers/app_state_provider.dart';
import 'package:ecosync_cropguard/screens/home_screen.dart';

import '../support/db_test_setup.dart';

void main() {
  setUpAll(initTestDatabaseEnvironment);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('lists all 5 seeded crops once loading completes', (tester) async {
    final state = AppStateProvider();
    await tester.runAsync(() => state.init());

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();

    for (final name in [
      'Maize',
      'Tobacco',
      'Groundnuts',
      'Sorghum',
      'Sweet Potatoes',
    ]) {
      expect(find.text(name), findsOneWidget);
    }
  });

  testWidgets('shows a loading indicator before crops have loaded', (tester) async {
    final state = AppStateProvider(); // init() deliberately not called

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
