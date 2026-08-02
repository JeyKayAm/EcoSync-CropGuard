import 'package:flutter/material.dart';
import '../models/disease.dart';
import '../models/treatment.dart';
import '../services/treatment_service.dart';
import '../utils/constants.dart';
import '../widgets/treatment_card.dart';

class TreatmentGuideScreen extends StatefulWidget {
  final Disease disease;

  const TreatmentGuideScreen({super.key, required this.disease});

  @override
  State<TreatmentGuideScreen> createState() => _TreatmentGuideScreenState();
}

class _TreatmentGuideScreenState extends State<TreatmentGuideScreen> {
  final TreatmentService _svc = TreatmentService();
  late Future<List<Treatment>> _future;

  @override
  void initState() {
    super.initState();
    _future = _svc.getTreatments(widget.disease.id);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: const Text('Treatment Guide'),
      ),
      body: FutureBuilder<List<Treatment>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final treatments = snap.data ?? [];
          if (treatments.isEmpty) {
            return const Center(child: Text('No treatment data available.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(widget.disease.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700, color: colorScheme.primary)),
              const SizedBox(height: 4),
              Text(
                'Organic options are listed first. Always follow product '
                'label instructions and wear appropriate protective equipment.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ...treatments.map((t) => TreatmentCard(treatment: t)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Colors.amber),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(kDisclaimer,
                          style: TextStyle(
                              fontSize: 11, color: Colors.black54)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
