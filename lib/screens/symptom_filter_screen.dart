import 'package:flutter/material.dart';
import '../models/crop.dart';
import '../models/disease.dart';
import '../services/diagnostic_service.dart';
import '../utils/constants.dart';
import '../widgets/disease_card.dart';
import 'disease_detail_screen.dart';

/// Lists diseases for a crop, optionally narrowed to one plant part
/// (`plantPart == null` shows all of them). Reached either from a plant-part
/// tile on [CropDetailScreen] or its "Show All Diseases" fallback.
class SymptomFilterScreen extends StatefulWidget {
  final Crop crop;
  final String? plantPart;

  const SymptomFilterScreen({
    super.key,
    required this.crop,
    required this.plantPart,
  });

  @override
  State<SymptomFilterScreen> createState() => _SymptomFilterScreenState();
}

class _SymptomFilterScreenState extends State<SymptomFilterScreen> {
  final DiagnosticService _svc = DiagnosticService();
  late Future<List<Disease>> _future;

  @override
  void initState() {
    super.initState();
    _future = _svc.getDiseases(
      cropId: widget.crop.id,
      plantPart: widget.plantPart,
    );
  }

  String get _title {
    if (widget.plantPart == null) return 'All ${widget.crop.name} Diseases';
    final part = kPlantParts.firstWhere(
      (p) => p['value'] == widget.plantPart,
      orElse: () => {'label': widget.plantPart!},
    );
    return '${widget.crop.name} — ${part['label']}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: Text(_title, style: const TextStyle(fontSize: 16)),
      ),
      body: FutureBuilder<List<Disease>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final diseases = snap.data ?? [];
          if (diseases.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No diseases found for this selection.',
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
                  'Compare the images below with your field observation. '
                  'Tap a disease for full details.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: diseases.length,
                  itemBuilder: (context, i) => DiseaseCard(
                    disease: diseases[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DiseaseDetailScreen(
                          disease: diseases[i],
                          cropName: widget.crop.name,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
