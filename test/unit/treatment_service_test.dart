// Unit tests (Section 3.7.1): TreatmentService against the bundled fixture,
// including the null-field edge case (a disease with no treatment records).
import 'package:flutter_test/flutter_test.dart';
import 'package:ecosync_cropguard/services/treatment_service.dart';

import '../support/db_test_setup.dart';

void main() {
  setUpAll(initTestDatabaseEnvironment);

  final svc = TreatmentService();

  test('returns organic treatments before chemical ones', () async {
    final treatments = await svc.getTreatments(1);
    expect(treatments, hasLength(2));
    expect(treatments[0].type, 'organic');
    expect(treatments[1].type, 'chemical');
  });

  test('every treatment carries a non-empty bibliographic source', () async {
    final treatments = await svc.getTreatments(1);
    for (final t in treatments) {
      expect(t.source, isNotEmpty);
    }
  });

  test('edge case: disease with no treatment records returns an empty list',
      () async {
    final treatments = await svc.getTreatments(9999);
    expect(treatments, isEmpty);
  });
}
