import 'dart:io';
import '../models/disease.dart';
import '../utils/phash.dart';
import 'diagnostic_service.dart';

/// Ranks a crop's diseases by visual similarity to a captured/picked photo,
/// using perceptual-hash (aHash) comparison against each disease's
/// precomputed reference-image hashes — not a trained classifier. With only
/// a few dozen reference photos in the whole dataset, there isn't enough
/// data to train one; see CLAUDE.md and [kPhotoLookupDisclaimer]. Mirrors
/// [DiagnosticService.getDiseasesBySymptomTags]'s shape: a ranked list of
/// (Disease, score) tuples for a results screen to render.
class PhotoMatchService {
  final DiagnosticService _diagnosticService = DiagnosticService();

  /// Returns every disease for [cropId] that has at least one reference
  /// photo, sorted by descending similarity (0.0–1.0) to [photo]. Diseases
  /// with no reference images (e.g. GRAV, which is often asymptomatic) are
  /// excluded rather than shown with a meaningless 0% score.
  Future<List<(Disease, double)>> matchPhoto({
    required int cropId,
    required File photo,
  }) async {
    final diseases = await _diagnosticService.getDiseases(cropId: cropId);
    final photoHash = computeAverageHash(await photo.readAsBytes());

    final results = <(Disease, double)>[];
    for (final disease in diseases) {
      if (disease.imagePhashes.isEmpty) continue;
      final bestDistance = disease.imagePhashes
          .map((refHash) => hammingDistance(photoHash, refHash))
          .reduce((a, b) => a < b ? a : b);
      results.add((disease, similarityFromDistance(bestDistance)));
    }

    results.sort((a, b) => b.$2.compareTo(a.$2));
    return results;
  }
}
