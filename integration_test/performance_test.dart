// Performance benchmarking (Section 3.7.4): database query response time,
// measured on-device (not the host) since that is what the 200ms target
// actually governs. Uses the app's real, already-initialised DatabaseHelper
// singleton — the same connection the UI queries through — rather than a
// fresh one, so the timing reflects steady-state query cost, not one-time
// database-open overhead.
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ecosync_cropguard/app.dart';
import 'package:ecosync_cropguard/services/diagnostic_service.dart';
import 'package:ecosync_cropguard/services/treatment_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('database query response time on-device', (tester) async {
    await tester.pumpWidget(const EcoSyncApp());
    await tester.pumpAndSettle(const Duration(seconds: 5));

    final diagnosticSvc = DiagnosticService();
    final treatmentSvc = TreatmentService();

    Future<void> time(String label, Future<void> Function() op) async {
      // Run each query several times; report min/avg to smooth out the
      // first-call JIT/plan-cache warm-up the later calls don't pay.
      final samples = <int>[];
      for (var i = 0; i < 20; i++) {
        final sw = Stopwatch()..start();
        await op();
        sw.stop();
        samples.add(sw.elapsedMicroseconds);
      }
      final avgMs =
          samples.reduce((a, b) => a + b) / samples.length / 1000;
      final minMs = samples.reduce((a, b) => a < b ? a : b) / 1000;
      final maxMs = samples.reduce((a, b) => a > b ? a : b) / 1000;
      debugPrint(
        'PERF $label: avg=${avgMs.toStringAsFixed(2)}ms '
        'min=${minMs.toStringAsFixed(2)}ms max=${maxMs.toStringAsFixed(2)}ms '
        '(n=${samples.length})',
      );
    }

    await time(
      'getDiseases(cropId: 1)',
      () => diagnosticSvc.getDiseases(cropId: 1),
    );
    await time(
      'getDiseases(cropId: 1, plantPart: leaf)',
      () => diagnosticSvc.getDiseases(cropId: 1, plantPart: 'leaf'),
    );
    await time(
      'getAvailablePlantParts(cropId: 1)',
      () => diagnosticSvc.getAvailablePlantParts(1),
    );
    await time('getSymptoms(diseaseId: 1)', () => diagnosticSvc.getSymptoms(1));
    await time('getDiseaseById(1)', () => diagnosticSvc.getDiseaseById(1));
    await time(
      'getTreatments(diseaseId: 1)',
      () => treatmentSvc.getTreatments(1),
    );

    // Image load/decode time: load bytes from the asset bundle and decode
    // to a ui.Image, for the largest bundled reference photo (worst case)
    // and the median-sized one, mirroring what Image.asset does per frame.
    Future<void> timeImageDecode(String label, String assetPath) async {
      final samples = <int>[];
      for (var i = 0; i < 10; i++) {
        final sw = Stopwatch()..start();
        final data = await rootBundle.load(assetPath);
        final codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(),
        );
        final frame = await codec.getNextFrame();
        frame.image.dispose();
        sw.stop();
        samples.add(sw.elapsedMicroseconds);
      }
      final avgMs = samples.reduce((a, b) => a + b) / samples.length / 1000;
      final minMs = samples.reduce((a, b) => a < b ? a : b) / 1000;
      final maxMs = samples.reduce((a, b) => a > b ? a : b) / 1000;
      debugPrint(
        'PERF image decode $label: avg=${avgMs.toStringAsFixed(2)}ms '
        'min=${minMs.toStringAsFixed(2)}ms max=${maxMs.toStringAsFixed(2)}ms '
        '(n=${samples.length})',
      );
    }

    await timeImageDecode(
      '1000x750 262KB (nclb_3.jpg, largest bundled image)',
      'assets/images/maize/nclb_3.jpg',
    );
    await timeImageDecode(
      '432x329 41.5KB (gls_2.jpg, ~median bundled image)',
      'assets/images/maize/gls_2.jpg',
    );
  });
}
