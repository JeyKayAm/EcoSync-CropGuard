import 'dart:io';
import 'package:flutter/material.dart';
import '../models/crop.dart';
import '../models/disease.dart';
import '../services/photo_match_service.dart';
import '../utils/constants.dart';
import '../widgets/disease_card.dart';
import 'disease_detail_screen.dart';

/// Ranked results for [PhotoLookupScreen]: diseases sorted by perceptual
/// visual similarity to the captured/picked photo, via
/// [PhotoMatchService]. Mirrors [SymptomCheckerResultsScreen]'s structure —
/// same [DiseaseCard] list, just a similarity percentage instead of a
/// symptom match count. Below [_confidenceThreshold] the top match is
/// shown with an explicit "not confident" banner rather than presented as
/// a likely diagnosis.
///
/// [_confidenceThreshold] is calibrated from measured data, not guessed:
/// pairwise aHash similarity was computed across every reference image in
/// the DB, split into same-disease pairs (different photos of one disease)
/// vs different-disease pairs. The two distributions almost fully overlap
/// (same-disease median 0.50, different-disease median 0.50; same-disease
/// max 0.72 vs different-disease p99 0.73) — aHash on this dataset mostly
/// only fires confidently on near-duplicates of a reference photo, not on
/// "another photo of the same disease." 0.75 sits just above both
/// distributions' upper range, so it reserves "confident" for genuinely
/// close matches and otherwise defaults honestly to the low-confidence
/// banner.
class PhotoLookupResultsScreen extends StatefulWidget {
  final Crop crop;
  final File photo;

  const PhotoLookupResultsScreen({
    super.key,
    required this.crop,
    required this.photo,
  });

  @override
  State<PhotoLookupResultsScreen> createState() =>
      _PhotoLookupResultsScreenState();
}

class _PhotoLookupResultsScreenState extends State<PhotoLookupResultsScreen> {
  static const double _confidenceThreshold = 0.75;

  final PhotoMatchService _svc = PhotoMatchService();
  late Future<List<(Disease, double)>> _future;

  @override
  void initState() {
    super.initState();
    _future = _svc.matchPhoto(cropId: widget.crop.id, photo: widget.photo);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: const Text('Closest Matches', style: TextStyle(fontSize: 16)),
      ),
      body: FutureBuilder<List<(Disease, double)>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final results = snap.data ?? [];
          final bestSimilarity = results.isEmpty ? 0.0 : results.first.$2;
          final lowConfidence = bestSimilarity < _confidenceThreshold;

          if (results.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No reference photos available for this crop yet.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: SizedBox(
                  height: 140,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(widget.photo,
                        width: double.infinity, fit: BoxFit.cover),
                  ),
                ),
              ),
              if (lowConfidence)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kWarningAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kWarningAmber),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: kWarningAmber),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No confident match. This disease may not be in '
                          'our reference set yet, or try a clearer, '
                          'closer photo. The closest candidates are shown '
                          'below.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Text(
                  'Ranked by visual similarity to your photo. Tap a disease '
                  'for full details.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, i) {
                    final (disease, similarity) = results[i];
                    return DiseaseCard(
                      disease: disease,
                      matchLabel: '${(similarity * 100).round()}% match',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DiseaseDetailScreen(
                            disease: disease,
                            cropName: widget.crop.name,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
