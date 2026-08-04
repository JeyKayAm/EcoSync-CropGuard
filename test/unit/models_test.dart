// Unit tests (Section 3.7.1): model fromMap/toMap round-trips, including
// the edge cases fromMap must handle safely — an empty comma-joined
// image_paths column and a bookmark row that has not yet been inserted
// (no id).
import 'package:flutter_test/flutter_test.dart';
import 'package:ecosync_cropguard/models/bookmark.dart';
import 'package:ecosync_cropguard/models/crop.dart';
import 'package:ecosync_cropguard/models/disease.dart';
import 'package:ecosync_cropguard/models/symptom.dart';
import 'package:ecosync_cropguard/models/treatment.dart';

void main() {
  group('Crop', () {
    test('fromMap/toMap round-trip', () {
      final map = {
        'id': 1,
        'name': 'Maize',
        'local_name': 'Chibage',
        'description': 'Staple cereal crop.',
        'image_path': 'assets/images/maize/crop.jpg',
      };
      final crop = Crop.fromMap(map);
      expect(crop.id, 1);
      expect(crop.name, 'Maize');
      expect(crop.localName, 'Chibage');
      expect(crop.toMap(), map);
    });
  });

  group('Disease', () {
    test('fromMap splits comma-joined image_paths and trims whitespace', () {
      final disease = Disease.fromMap({
        'id': 1,
        'crop_id': 1,
        'name': 'Grey Leaf Spot',
        'pathogen': 'Cercospora zeae-maydis',
        'plant_part': 'leaf',
        'severity': 'High',
        'description': 'desc',
        'prevention': 'prevention',
        'image_paths':
            'assets/images/maize/gls_1.jpg, assets/images/maize/gls_2.jpg,assets/images/maize/gls_3.jpg',
      });
      expect(disease.imagePaths, [
        'assets/images/maize/gls_1.jpg',
        'assets/images/maize/gls_2.jpg',
        'assets/images/maize/gls_3.jpg',
      ]);
    });

    test('fromMap yields an empty list for an empty image_paths column', () {
      final disease = Disease.fromMap({
        'id': 6,
        'crop_id': 2,
        'name': 'Placeholder Disease',
        'pathogen': 'Unknown',
        'plant_part': 'leaf',
        'severity': 'Low',
        'description': 'desc',
        'prevention': 'prevention',
        'image_paths': '',
      });
      expect(disease.imagePaths, isEmpty);
    });

    test('toMap re-joins imagePaths with commas', () {
      const disease = Disease(
        id: 1,
        cropId: 1,
        name: 'Grey Leaf Spot',
        pathogen: 'Cercospora zeae-maydis',
        plantPart: 'leaf',
        severity: 'High',
        description: 'desc',
        prevention: 'prevention',
        imagePaths: ['a.jpg', 'b.jpg'],
      );
      expect(disease.toMap()['image_paths'], 'a.jpg,b.jpg');
    });
  });

  group('Symptom', () {
    test('fromMap/toMap round-trip', () {
      final map = {
        'id': 1,
        'disease_id': 1,
        'description': 'Rectangular grey-tan lesions',
        'stage': 'mid',
      };
      expect(Symptom.fromMap(map).toMap(), map);
    });
  });

  group('Treatment', () {
    test('fromMap/toMap round-trip preserves the traceability source field',
        () {
      final map = {
        'id': 1,
        'disease_id': 1,
        'type': 'organic',
        'product_name': 'Crop Rotation + Debris Removal',
        'active_ingredient': 'N/A',
        'dosage': 'N/A',
        'application_method': 'Cultural practice',
        'estimated_cost_usd': r'$0',
        'availability': 'N/A',
        'source': 'CIMMYT Maize Disease Guide',
      };
      final treatment = Treatment.fromMap(map);
      expect(treatment.source, 'CIMMYT Maize Disease Guide');
      expect(treatment.toMap(), map);
    });
  });

  group('Bookmark', () {
    test('toMap omits id when null (pre-insert)', () {
      const bookmark = Bookmark(
        diseaseId: 1,
        diseaseName: 'Grey Leaf Spot',
        cropName: 'Maize',
        savedAt: '2026-01-01T00:00:00.000',
      );
      expect(bookmark.toMap().containsKey('id'), isFalse);
    });

    test('toMap includes id once assigned (post-insert)', () {
      const bookmark = Bookmark(
        id: 7,
        diseaseId: 1,
        diseaseName: 'Grey Leaf Spot',
        cropName: 'Maize',
        savedAt: '2026-01-01T00:00:00.000',
      );
      expect(bookmark.toMap()['id'], 7);
    });

    test('fromMap/toMap round-trip', () {
      final map = {
        'id': 7,
        'disease_id': 1,
        'disease_name': 'Grey Leaf Spot',
        'crop_name': 'Maize',
        'saved_at': '2026-01-01T00:00:00.000',
      };
      expect(Bookmark.fromMap(map).toMap(), map);
    });
  });
}
