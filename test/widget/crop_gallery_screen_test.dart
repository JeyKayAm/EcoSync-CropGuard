// Widget test (Section 3.7.2): the Image Gallery that underpins the IVC
// (Iterative Visual Comparison) diagnostic method — GalleryPhotoTile tested
// in isolation with directly-supplied Disease data, including the
// missing-image and no-image edge cases that motivate the asset-integrity
// audit in Chapter 5. CropGalleryScreen's live-DB-backed grid is exercised
// end-to-end by the integration test (Section 3.7.3); see the note in
// symptom_filter_screen_test.dart for why widget tests avoid driving real
// sqflite/path_provider calls directly.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecosync_cropguard/models/disease.dart';
import 'package:ecosync_cropguard/widgets/gallery_photo_tile.dart';

void main() {
  const grayLeafSpot = Disease(
    id: 1,
    cropId: 1,
    name: 'Grey Leaf Spot',
    pathogen: 'Cercospora zeae-maydis',
    plantPart: 'leaf',
    severity: 'High',
    description: 'desc',
    prevention: 'prevention',
    imagePaths: [
      'assets/images/maize/gls_1.jpg',
      'assets/images/maize/gls_2.jpg',
      'assets/images/maize/gls_3.jpg',
    ],
  );

  testWidgets('renders the disease name, plant part and a multi-photo badge',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: GalleryPhotoTile(disease: grayLeafSpot, onTap: () {})),
    ));
    await tester.pumpAndSettle(); // Image.asset decode only, no live plugins

    expect(tester.takeException(), isNull);
    expect(find.text('Grey Leaf Spot'), findsOneWidget);
    expect(find.text('Leaf'), findsOneWidget);
    expect(find.text('3'), findsOneWidget); // photo-count badge
  });

  testWidgets('tapping a tile fires onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GalleryPhotoTile(disease: grayLeafSpot, onTap: () => tapped = true),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(GalleryPhotoTile));
    expect(tapped, isTrue);
  });

  testWidgets(
      'a tile for a disease whose image file is missing falls back to the '
      'placeholder icon instead of crashing', (tester) async {
    const brokenImageDisease = Disease(
      id: 1,
      cropId: 1,
      name: 'Test Disease With Missing Photo',
      pathogen: 'Test pathogen',
      plantPart: 'leaf',
      severity: 'High',
      description: 'desc',
      prevention: 'prevention',
      imagePaths: ['assets/images/maize/does_not_exist.jpg'],
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GalleryPhotoTile(disease: brokenImageDisease, onTap: () {}),
      ),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.image_not_supported), findsOneWidget);
    expect(find.text('Test Disease With Missing Photo'), findsOneWidget);
  });

  testWidgets('a disease with no recorded images at all also uses the placeholder',
      (tester) async {
    const noImageDisease = Disease(
      id: 6,
      cropId: 3,
      name: 'Groundnut Rosette Assistor Virus (GRAV)',
      pathogen: 'Groundnut rosette assistor virus',
      plantPart: 'leaf',
      severity: 'High',
      description: 'desc',
      prevention: 'prevention',
      imagePaths: [],
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: GalleryPhotoTile(disease: noImageDisease, onTap: () {})),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.image_not_supported), findsOneWidget);
    // No multi-photo badge and no severity mismatch when there are 0 photos.
    expect(find.text('0'), findsNothing);
  });

  testWidgets('a grid of tiles (as CropGalleryScreen lays them out) renders one '
      'tile per disease and routes taps to the right one', (tester) async {
    const diseases = [
      grayLeafSpot,
      Disease(
        id: 4,
        cropId: 1,
        name: 'Common Rust',
        pathogen: 'Puccinia sorghi',
        plantPart: 'leaf',
        severity: 'Medium',
        description: 'desc',
        prevention: 'prevention',
        imagePaths: ['assets/images/maize/rust_1.jpg'],
      ),
    ];
    Disease? tappedDisease;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GridView.count(
          crossAxisCount: 2,
          children: diseases
              .map((d) => GalleryPhotoTile(
                    disease: d,
                    onTap: () => tappedDisease = d,
                  ))
              .toList(),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(GalleryPhotoTile), findsNWidgets(2));

    await tester.tap(find.text('Common Rust'));
    expect(tappedDisease?.name, 'Common Rust');
  });
}
