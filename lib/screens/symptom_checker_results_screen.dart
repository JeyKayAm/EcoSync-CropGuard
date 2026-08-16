import 'package:flutter/material.dart';
import '../models/crop.dart';
import '../models/disease.dart';
import '../services/diagnostic_service.dart';
import '../widgets/disease_card.dart';
import 'disease_detail_screen.dart';

/// Ranked results for [SymptomCheckerScreen]: diseases sorted by how many
/// of the selected symptom tags each one matches, with the match count
/// shown as a badge on each [DiseaseCard].
class SymptomCheckerResultsScreen extends StatefulWidget {
  final Crop crop;
  final List<int> selectedTagIds;

  const SymptomCheckerResultsScreen({
    super.key,
    required this.crop,
    required this.selectedTagIds,
  });

  @override
  State<SymptomCheckerResultsScreen> createState() =>
      _SymptomCheckerResultsScreenState();
}

class _SymptomCheckerResultsScreenState
    extends State<SymptomCheckerResultsScreen> {
  final DiagnosticService _svc = DiagnosticService();
  late Future<List<(Disease, int)>> _future;

  @override
  void initState() {
    super.initState();
    _future = _svc.getDiseasesBySymptomTags(
      widget.crop.id,
      widget.selectedTagIds,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalSelected = widget.selectedTagIds.length;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: const Text('Possible Matches', style: TextStyle(fontSize: 16)),
      ),
      body: FutureBuilder<List<(Disease, int)>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final results = snap.data ?? [];
          if (results.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No diseases match those symptoms.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Text(
                  'Ranked by how many of your selected symptoms match. '
                  'Tap a disease for full details.',
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
                    final (disease, matchCount) = results[i];
                    return DiseaseCard(
                      disease: disease,
                      matchLabel: '$matchCount/$totalSelected matched',
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
