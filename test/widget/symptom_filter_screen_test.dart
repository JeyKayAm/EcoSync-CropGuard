// Widget test (Section 3.7.2): the Symptom Filter — SymptomFilterScreen's
// non-data-dependent loading state, plus DiseaseCard (the list item it
// renders per disease) tested in isolation with directly-supplied data.
//
// SymptomFilterScreen's populated/empty list states are data-driven through
// a live DiagnosticService query in initState(), which (like the rest of
// the app's real sqflite/path_provider calls) cannot resolve inside plain
// `flutter test`'s FakeAsync zone. That query's actual results — a
// populated 4-disease leaf list and an empty result for a plant part with
// no matches — are already verified directly against the database in
// test/unit/diagnostic_service_test.dart, and the full screen is exercised
// end-to-end by the integration test (Section 3.7.3) on a real device.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecosync_cropguard/models/crop.dart';
import 'package:ecosync_cropguard/models/disease.dart';
import 'package:ecosync_cropguard/screens/symptom_filter_screen.dart';
import 'package:ecosync_cropguard/widgets/disease_card.dart';

void main() {
  const maize = Crop(
    id: 1,
    name: 'Maize',
    localName: 'Chibage',
    description: 'desc',
    imagePath: 'assets/images/maize/crop.jpg',
  );

  const greyLeafSpot = Disease(
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

  testWidgets('SymptomFilterScreen shows a loading indicator immediately',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: SymptomFilterScreen(crop: maize, plantPart: 'leaf'),
    ));
    await tester.pump(); // one frame only — do not wait for the live DB query

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('SymptomFilterScreen titles "All <Crop> Diseases" when no plant part is set',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: SymptomFilterScreen(crop: maize, plantPart: null),
    ));
    await tester.pump();

    expect(find.text('All Maize Diseases'), findsOneWidget);
  });

  group('DiseaseCard (the list item Symptom Filter renders per disease)', () {
    testWidgets('renders name, pathogen, plant part and severity', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: DiseaseCard(disease: greyLeafSpot, onTap: () {})),
      ));
      await tester.pump();

      expect(find.text('Grey Leaf Spot'), findsOneWidget);
      expect(find.text('Cercospora zeae-maydis'), findsOneWidget);
      expect(find.text('Leaf'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
    });

    testWidgets('tapping the card fires onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DiseaseCard(disease: greyLeafSpot, onTap: () => tapped = true),
        ),
      ));
      await tester.pump();

      await tester.tap(find.text('Grey Leaf Spot'));
      expect(tapped, isTrue);
    });

    testWidgets('shows a placeholder icon, not a crash, when a disease has no images',
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
        home: Scaffold(body: DiseaseCard(disease: noImageDisease, onTap: () {})),
      ));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.image_not_supported), findsOneWidget);
    });
  });
}
