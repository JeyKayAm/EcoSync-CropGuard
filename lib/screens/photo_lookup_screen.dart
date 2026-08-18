import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/crop.dart';
import 'photo_lookup_results_screen.dart';

/// Entry point for the camera-driven disease lookup: capture or pick a
/// photo, then hand it to [PhotoLookupResultsScreen] for perceptual-hash
/// matching against this crop's reference images (see [PhotoMatchService]).
/// Sibling entry point to [SymptomCheckerScreen] and the manual
/// [CropGalleryScreen] browse — this is the automated version of the same
/// "compare against a reference photo" idea.
class PhotoLookupScreen extends StatefulWidget {
  final Crop crop;

  const PhotoLookupScreen({super.key, required this.crop});

  @override
  State<PhotoLookupScreen> createState() => _PhotoLookupScreenState();
}

class _PhotoLookupScreenState extends State<PhotoLookupScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _picking = false;

  Future<void> _pick(ImageSource source) async {
    setState(() => _picking = true);
    try {
      final xFile = await _picker.pickImage(source: source, maxWidth: 1024);
      if (xFile == null || !mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PhotoLookupResultsScreen(
            crop: widget.crop,
            photo: File(xFile.path),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: Text('${widget.crop.name} — Scan a Photo',
            style: const TextStyle(fontSize: 16)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined,
                size: 72, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Take or pick a clear, close-up photo of the affected part '
              'of the plant.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Beta: matches against a small reference set. See Settings '
              'for details.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _picking ? null : () => _pick(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _picking ? null : () => _pick(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Choose from Gallery'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(color: colorScheme.primary),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            if (_picking) ...[
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}
