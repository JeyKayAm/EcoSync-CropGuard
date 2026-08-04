// Integration test (Section 3.7.3): the full diagnostic flow described in
// Section 3.4.2's flowchart, run end to end against the real app — real
// sqflite plugin, real path_provider, real assets — on whichever device
// `flutter test integration_test` is pointed at (an emulator or a physical
// minimum-spec handset, per 3.7.3).
//
// Flow covered: launch -> select crop -> narrow by plant part -> select a
// disease from the filtered list -> view its detail -> open the treatment
// guide -> bookmark the disease -> confirm it appears on the Bookmarks
// screen -> remove the bookmark. Each back-navigation step asserts the
// screen it lands on before proceeding, rather than relying on
// `pageBack()`'s default back-button heuristic, since a stray Timer-driven
// rebuild (the disease detail auto-rotate carousel) can otherwise make the
// wrong back affordance ambiguous over a multi-second real-time test run.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ecosync_cropguard/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('end-to-end diagnostic flow: crop -> plant part -> disease -> '
      'treatment -> bookmark -> unbookmark', (tester) async {
    await tester.pumpWidget(const EcoSyncApp());
    // App startup: crop list + bookmarks load from the real on-device DB.
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // 1. Home screen shows the 5 crop tiles.
    expect(find.text('Maize'), findsOneWidget);
    expect(find.text('Tobacco'), findsOneWidget);

    // 2. Select a crop.
    await tester.tap(find.text('Maize'));
    await tester.pumpAndSettle();
    expect(find.text('Or narrow it down by plant part:'), findsOneWidget);

    // 3. Narrow down by plant part (Leaf).
    await tester.tap(find.text('Leaf'));
    await tester.pumpAndSettle();
    expect(find.text('Maize — Leaf'), findsOneWidget);

    // 4. Select a disease from the filtered list.
    await tester.tap(find.text('Grey Leaf Spot'));
    await tester.pumpAndSettle();
    expect(find.text('View Treatment Guide'), findsOneWidget);

    // 5. Open the treatment guide.
    await tester.tap(find.text('View Treatment Guide'));
    await tester.pumpAndSettle();
    expect(find.text('Treatment Guide'), findsOneWidget);
    expect(
      find.textContaining('Organic options are listed first'),
      findsOneWidget,
    );

    // Back to the disease detail screen.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('View Treatment Guide'), findsOneWidget);

    // 6. Bookmark the disease from the detail screen.
    final bookmarkButton = find.byIcon(Icons.bookmark_border);
    expect(bookmarkButton, findsOneWidget);
    await tester.tap(bookmarkButton);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.bookmark), findsOneWidget);

    // Back to the symptom-filtered disease list.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Maize — Leaf'), findsOneWidget);

    // Back to the crop detail screen.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Or narrow it down by plant part:'), findsOneWidget);

    // Back to Home.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Maize'), findsOneWidget);

    // 7. The bookmark is visible on the Bookmarks screen.
    await tester.tap(find.byIcon(Icons.bookmark_outline));
    await tester.pumpAndSettle();
    expect(find.text('Grey Leaf Spot'), findsOneWidget);

    // 8. Clean up: remove the bookmark so re-running this test is idempotent.
    await tester.tap(find.text('Grey Leaf Spot'));
    await tester.pumpAndSettle();
    final savedIcon = find.byIcon(Icons.bookmark);
    expect(savedIcon, findsOneWidget);
    await tester.tap(savedIcon);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
  });
}
