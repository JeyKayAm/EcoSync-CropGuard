// Unit tests (Section 3.7.1): DiagnosticService, covering the crop_id=1
// (Maize) fixture bundled in assets/db/cropguard.db — 5 diseases, 4 'leaf'
// + 1 'stem' — plus the null/empty-result edge cases called out in 3.7.1
// (an unknown crop id, and a plant part with no matching diseases).
import 'package:flutter_test/flutter_test.dart';
import 'package:ecosync_cropguard/services/diagnostic_service.dart';

import '../support/db_test_setup.dart';

void main() {
  setUpAll(initTestDatabaseEnvironment);

  final svc = DiagnosticService();

  group('getDiseases', () {
    test('returns all diseases for a crop when plantPart is omitted', () async {
      final diseases = await svc.getDiseases(cropId: 1);
      expect(diseases, hasLength(5));
    });

    test('filters by plant part and orders by severity DESC, name ASC', () async {
      final diseases = await svc.getDiseases(cropId: 1, plantPart: 'leaf');
      expect(diseases.map((d) => d.name).toList(), [
        'Common Rust', // severity 'Medium' sorts after 'High' in DESC text order
        'Grey Leaf Spot',
        'Maize Streak Virus',
        'Northern Corn Leaf Blight',
      ]);
    });

    test('edge case: unknown crop id returns an empty list, not an error',
        () async {
      final diseases = await svc.getDiseases(cropId: 9999);
      expect(diseases, isEmpty);
    });

    test('edge case: plant part with no diseases for this crop returns empty',
        () async {
      // Maize has no recorded root diseases in the bundled fixture.
      final diseases = await svc.getDiseases(cropId: 1, plantPart: 'root');
      expect(diseases, isEmpty);
    });
  });

  group('getAvailablePlantParts', () {
    test('returns only plant parts with recorded diseases, in fixed UI order',
        () async {
      final parts = await svc.getAvailablePlantParts(1);
      expect(parts, ['leaf', 'stem']);
    });

    test('edge case: unknown crop id returns an empty list', () async {
      final parts = await svc.getAvailablePlantParts(9999);
      expect(parts, isEmpty);
    });
  });

  group('getSymptoms', () {
    test('orders symptoms early -> mid -> late regardless of storage order',
        () async {
      final symptoms = await svc.getSymptoms(1);
      expect(symptoms.map((s) => s.stage).toList(), ['early', 'mid', 'late']);
    });

    test('edge case: disease with no recorded symptoms returns an empty list',
        () async {
      final symptoms = await svc.getSymptoms(9999);
      expect(symptoms, isEmpty);
    });
  });

  group('getDiseaseById', () {
    test('returns the matching disease', () async {
      final disease = await svc.getDiseaseById(1);
      expect(disease, isNotNull);
      expect(disease!.name, 'Grey Leaf Spot');
      expect(disease.imagePaths, hasLength(3));
    });

    test('edge case: unknown id returns null rather than throwing', () async {
      final disease = await svc.getDiseaseById(9999);
      expect(disease, isNull);
    });
  });
}
