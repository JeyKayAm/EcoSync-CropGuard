import 'package:flutter/material.dart';
import '../models/disease.dart';
import '../utils/constants.dart';

/// A square, photo-first tile for the crop-wide gallery grid — built so a
/// farmer can scan many diseases at a glance and stop on the one that
/// visually matches their field observation, before reading a single word.
class GalleryPhotoTile extends StatelessWidget {
  final Disease disease;
  final VoidCallback onTap;

  const GalleryPhotoTile({super.key, required this.disease, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = severityColor(disease.severity);
    final hasImage = disease.imagePaths.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Material(
        color: Colors.grey.shade200,
        child: InkWell(
          onTap: onTap,
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasImage)
                  Image.asset(
                    disease.imagePaths.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _PlaceholderArt(),
                  )
                else
                  const _PlaceholderArt(),

                // Bottom gradient so white text stays legible over any photo.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                      stops: [0.55, 1.0],
                    ),
                  ),
                ),

                // Severity dot, top-right.
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),

                // Multi-photo badge, top-left.
                if (disease.imagePaths.length > 1)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_library, color: Colors.white, size: 10),
                          const SizedBox(width: 3),
                          Text('${disease.imagePaths.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),

                // Name + plant part, bottom.
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        disease.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        disease.plantPart[0].toUpperCase() + disease.plantPart.substring(1),
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceholderArt extends StatelessWidget {
  const _PlaceholderArt();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade300,
      child: const Center(
        child: Icon(Icons.image_not_supported, size: 28, color: Colors.grey),
      ),
    );
  }
}
