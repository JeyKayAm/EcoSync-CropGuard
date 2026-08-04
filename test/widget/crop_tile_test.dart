// Widget test (Section 3.7.2): CropTile — the row entry in the Crop
// Selector on the home screen. Verifies it renders the crop's name and
// local name, and that tapping it fires the supplied callback.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecosync_cropguard/models/crop.dart';
import 'package:ecosync_cropguard/widgets/crop_tile.dart';

void main() {
  const crop = Crop(
    id: 1,
    name: 'Maize',
    localName: 'Chibage',
    description: 'Staple cereal crop grown widely across Zimbabwe.',
    imagePath: 'assets/images/maize/crop.jpg',
  );

  testWidgets('renders the crop name and local name', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: CropTile(crop: crop, onTap: () {})),
    ));
    await tester.pump();

    expect(find.text('Maize'), findsOneWidget);
    expect(find.text('Chibage'), findsOneWidget);
  });

  testWidgets('falls back to a default icon when the crop SVG icon is missing',
      (tester) async {
    // "Chibage" the crop's own name maps to a real icon asset; a crop name
    // with no matching SVG (there is no 'unknown_crop.svg') must not crash
    // the tile — SvgPicture.asset's placeholderBuilder should take over.
    const unknownCrop = Crop(
      id: 99,
      name: 'Unknown Crop',
      localName: 'N/A',
      description: 'desc',
      imagePath: 'assets/images/unknown/crop.jpg',
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: CropTile(crop: unknownCrop, onTap: () {})),
    ));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Unknown Crop'), findsOneWidget);
  });

  testWidgets('tapping the tile fires onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CropTile(crop: crop, onTap: () => tapped = true),
      ),
    ));
    await tester.pump();

    await tester.tap(find.byType(InkWell));
    expect(tapped, isTrue);
  });
}
