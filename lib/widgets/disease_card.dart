import 'package:flutter/material.dart';
import '../models/disease.dart';
import '../screens/image_gallery_screen.dart';
import '../utils/constants.dart';

/// A photo-forward card: the reference image is the first thing a farmer
/// sees, large enough to recognise before reading a single word — this
/// list of cards IS the "browse pictures and pick the one that matches"
/// gallery. Tapping the image opens a full-size pinch-zoom view; tapping
/// anywhere else opens the full disease detail.
class DiseaseCard extends StatelessWidget {
  final Disease disease;
  final VoidCallback onTap;

  const DiseaseCard({super.key, required this.disease, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = severityColor(disease.severity);
    final hasImage = disease.imagePaths.isNotEmpty;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              _ZoomableThumbnail(disease: disease)
            else
              Container(
                height: 96,
                width: double.infinity,
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(Icons.image_not_supported,
                      size: 32, color: Colors.grey),
                ),
              ),

            // Severity accent line directly under the image.
            Container(height: 3, width: double.infinity, color: color),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(disease.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text(disease.pathogen,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _chip(
                              disease.plantPart[0].toUpperCase() +
                                  disease.plantPart.substring(1),
                              Colors.blueGrey.shade100,
                              Colors.blueGrey.shade700,
                            ),
                            const SizedBox(width: 8),
                            _chip(
                              disease.severity,
                              color.withValues(alpha: 0.12),
                              color,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
      );
}

class _ZoomableThumbnail extends StatelessWidget {
  final Disease disease;

  const _ZoomableThumbnail({required this.disease});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.asset(
          disease.imagePaths.first,
          height: 210,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 210,
            color: Colors.grey.shade200,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image_not_supported, size: 32, color: Colors.grey),
                  SizedBox(height: 6),
                  Text('Reference image not yet added',
                      style: TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 8,
          bottom: 8,
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ImageGalleryScreen(
                  title: disease.name,
                  imagePaths: disease.imagePaths,
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.zoom_in, color: Colors.white, size: 18),
            ),
          ),
        ),
        if (disease.imagePaths.length > 1)
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '1/${disease.imagePaths.length}',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
      ],
    );
  }
}
