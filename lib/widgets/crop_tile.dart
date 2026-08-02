import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/crop.dart';

class CropTile extends StatelessWidget {
  final Crop crop;
  final VoidCallback onTap;

  const CropTile({super.key, required this.crop, required this.onTap});

  /// Crop name slugified to match the icon file, e.g. "Sweet Potatoes" ->
  /// assets/branding/crop_icons/sweet_potatoes.svg. Data-driven so every
  /// crop in the DB resolves to its own icon instead of a generic fallback.
  String get _iconAsset =>
      'assets/branding/crop_icons/${crop.name.toLowerCase().replaceAll(' ', '_')}.svg';

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  _iconAsset,
                  fit: BoxFit.contain,
                  placeholderBuilder: (_) =>
                      Icon(Icons.eco, color: primary, size: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(crop.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(crop.localName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: primary,
                            fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
