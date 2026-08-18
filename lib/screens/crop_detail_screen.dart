import 'package:flutter/material.dart';
import '../models/crop.dart';
import '../services/diagnostic_service.dart';
import '../utils/constants.dart';
import '../widgets/plant_part_card.dart';
import 'crop_gallery_screen.dart';
import 'photo_lookup_screen.dart';
import 'symptom_checker_screen.dart';
import 'symptom_filter_screen.dart';

/// A crop's landing page: four diagnosis paths branch from here — a visual
/// photo comparison ([CropGalleryScreen]), an automated camera-based lookup
/// ([PhotoLookupScreen]), picking observed symptoms
/// ([SymptomCheckerScreen]), or narrowing down by plant part
/// ([SymptomFilterScreen]). Plant-part options shown are only the ones that
/// actually have diseases recorded for this crop (see
/// [DiagnosticService.getAvailablePlantParts]).
class CropDetailScreen extends StatefulWidget {
  final Crop crop;

  const CropDetailScreen({super.key, required this.crop});

  @override
  State<CropDetailScreen> createState() => _CropDetailScreenState();
}

class _CropDetailScreenState extends State<CropDetailScreen> {
  final DiagnosticService _svc = DiagnosticService();
  late Future<List<String>> _partsFuture;

  @override
  void initState() {
    super.initState();
    _partsFuture = _svc.getAvailablePlantParts(widget.crop.id);
  }

  @override
  Widget build(BuildContext context) {
    final crop = widget.crop;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: Text(crop.name),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Crop description banner
          Container(
            width: double.infinity,
            color: colorScheme.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(crop.localName,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                        fontSize: 13)),
                const SizedBox(height: 8),
                Text(crop.description,
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CropGalleryScreen(crop: crop),
                ),
              ),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Browse Photos to Find a Match'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PhotoLookupScreen(crop: crop),
                ),
              ),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Scan a Photo (Beta)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(color: colorScheme.primary),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SymptomCheckerScreen(crop: crop),
                ),
              ),
              icon: const Icon(Icons.checklist_outlined),
              label: const Text('Check Symptoms'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(color: colorScheme.primary),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Or narrow it down by plant part:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700, color: colorScheme.primary)),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<String>>(
              future: _partsFuture,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final availableValues = snap.data!;
                final parts = kPlantParts
                    .where((p) => availableValues.contains(p['value']))
                    .toList();
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.15,
                      children: parts
                          .map((part) => PlantPartCard(
                                icon: part['icon']!,
                                label: part['label']!,
                                onTap: () => _navigate(context, part['value']),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _navigate(context, null),
                      icon: const Icon(Icons.list_alt),
                      label: const Text('Show All Diseases for This Crop'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(color: colorScheme.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, String? plantPart) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SymptomFilterScreen(crop: widget.crop, plantPart: plantPart),
      ),
    );
  }
}
