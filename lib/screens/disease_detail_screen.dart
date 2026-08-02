import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/disease.dart';
import '../models/symptom.dart';
import '../providers/app_state_provider.dart';
import '../services/diagnostic_service.dart';
import '../utils/constants.dart';
import 'image_gallery_screen.dart';
import 'treatment_guide_screen.dart';

class DiseaseDetailScreen extends StatefulWidget {
  final Disease disease;
  final String cropName;

  const DiseaseDetailScreen({
    super.key,
    required this.disease,
    required this.cropName,
  });

  @override
  State<DiseaseDetailScreen> createState() => _DiseaseDetailScreenState();
}

class _DiseaseDetailScreenState extends State<DiseaseDetailScreen> {
  static const _autoRotateInterval = Duration(seconds: 15);

  final DiagnosticService _svc = DiagnosticService();
  late Future<List<Symptom>> _symptomFuture;
  late final PageController _imageController;
  int _imageIndex = 0;
  Timer? _autoRotateTimer;

  @override
  void initState() {
    super.initState();
    _symptomFuture = _svc.getSymptoms(widget.disease.id);
    _imageController = PageController();
    _startAutoRotate();
  }

  @override
  void dispose() {
    _autoRotateTimer?.cancel();
    _imageController.dispose();
    super.dispose();
  }

  void _startAutoRotate() {
    _autoRotateTimer?.cancel();
    final images = widget.disease.imagePaths;
    if (images.length <= 1) return;
    _autoRotateTimer = Timer.periodic(_autoRotateInterval, (_) {
      if (!mounted) return;
      final next = (_imageIndex + 1) % images.length;
      _imageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  /// Called when the farmer swipes manually — resets the 15s countdown
  /// instead of fighting the auto-rotate for control of the page.
  void _onManualInteraction() => _startAutoRotate();

  @override
  Widget build(BuildContext context) {
    final disease = widget.disease;
    final severityColor_ = severityColor(disease.severity);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: Text(disease.name, style: const TextStyle(fontSize: 16)),
        actions: [
          Consumer<AppStateProvider>(
            builder: (context, state, _) {
              final saved = state.isBookmarked(disease.id);
              return IconButton(
                icon: Icon(
                    saved ? Icons.bookmark : Icons.bookmark_border),
                tooltip: saved ? 'Remove bookmark' : 'Save diagnosis',
                onPressed: () => state.toggleBookmark(
                  diseaseId: disease.id,
                  diseaseName: disease.name,
                  cropName: widget.cropName,
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Image gallery
          if (disease.imagePaths.isNotEmpty) ...[
            _buildImageGallery(disease),
            const SizedBox(height: 16),
          ],

          // Meta chips
          Wrap(
            spacing: 8,
            children: [
              _chip('🧫 ${disease.pathogen}', Colors.blueGrey.shade50,
                  Colors.blueGrey.shade700),
              _chip(disease.severity,
                  severityColor_.withValues(alpha: 0.12), severityColor_),
              _chip(
                  disease.plantPart[0].toUpperCase() +
                      disease.plantPart.substring(1),
                  colorScheme.primary.withValues(alpha: 0.1),
                  colorScheme.primary),
            ],
          ),
          const SizedBox(height: 16),

          // Description
          _section(context, 'About This Disease', disease.description),
          const SizedBox(height: 12),

          // Prevention
          _section(context, '🛡 Prevention', disease.prevention),
          const SizedBox(height: 12),

          // Symptoms
          _symptomsSection(context),
          const SizedBox(height: 24),

          // Treatment CTA
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    TreatmentGuideScreen(disease: disease),
              ),
            ),
            icon: const Icon(Icons.medical_services_outlined),
            label: const Text('View Treatment Guide'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery(Disease disease) {
    final images = disease.imagePaths;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ImageGalleryScreen(
                  title: disease.name,
                  imagePaths: images,
                  initialIndex: _imageIndex,
                ),
              ),
            ),
            child: SizedBox(
              height: 320,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollStartNotification &&
                          notification.dragDetails != null) {
                        _onManualInteraction();
                      }
                      return false;
                    },
                    child: PageView.builder(
                      controller: _imageController,
                      itemCount: images.length,
                      onPageChanged: (i) => setState(() => _imageIndex = i),
                      itemBuilder: (_, i) => Image.asset(
                        images[i],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.image_not_supported,
                                    size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Reference image not yet added',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.zoom_in,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              images.length,
              (i) => GestureDetector(
                onTap: () {
                  _imageController.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                  _onManualInteraction();
                },
                child: Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _imageIndex == i
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _section(BuildContext context, String title, String body) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 6),
          Text(body,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[800], height: 1.5)),
        ],
      );

  Widget _symptomsSection(BuildContext context) {
    return FutureBuilder<List<Symptom>>(
      future: _symptomFuture,
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.isEmpty) return const SizedBox.shrink();
        final symptoms = snap.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📋 Symptoms by Stage',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 8),
            ...symptoms.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _stageColor(s.stage).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        s.stage[0].toUpperCase() + s.stage.substring(1),
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _stageColor(s.stage)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(s.description,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(height: 1.5)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _stageColor(String stage) => switch (stage) {
        'early' => Colors.green,
        'mid'   => Colors.orange,
        _       => Colors.red,
      };

  Widget _chip(String label, Color bg, Color fg) => Chip(
        label: Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
        backgroundColor: bg,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.zero,
      );
}
