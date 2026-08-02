import 'package:flutter/material.dart';
import '../models/crop.dart';
import '../models/disease.dart';
import '../services/diagnostic_service.dart';
import '../widgets/gallery_photo_tile.dart';
import 'disease_detail_screen.dart';

/// Crop-wide visual picker: every known disease photo for this crop, side by
/// side, so a farmer who doesn't know any disease names can scan by eye and
/// tap the one that looks like what's in their field — then land straight on
/// that disease's full detail (which itself carries the other reference
/// photos, symptoms, and treatment guide).
class CropGalleryScreen extends StatefulWidget {
  final Crop crop;

  const CropGalleryScreen({super.key, required this.crop});

  @override
  State<CropGalleryScreen> createState() => _CropGalleryScreenState();
}

class _CropGalleryScreenState extends State<CropGalleryScreen> {
  final DiagnosticService _svc = DiagnosticService();
  late Future<List<Disease>> _future;

  @override
  void initState() {
    super.initState();
    _future = _svc.getDiseases(cropId: widget.crop.id);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: Text('${widget.crop.name} — Photo Gallery',
            style: const TextStyle(fontSize: 16)),
      ),
      body: FutureBuilder<List<Disease>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final diseases = snap.data ?? [];
          if (diseases.isEmpty) {
            return const Center(
              child: Text('No reference photos available yet.',
                  style: TextStyle(color: Colors.grey)),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Text(
                  'Tap the photo that most closely matches what you see on '
                  'your crop.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: diseases.length,
                  itemBuilder: (context, i) {
                    final disease = diseases[i];
                    return GalleryPhotoTile(
                      disease: disease,
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
