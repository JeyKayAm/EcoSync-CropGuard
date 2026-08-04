import 'package:flutter/material.dart';
import '../models/treatment.dart';
import '../utils/constants.dart';

/// One treatment record on [TreatmentGuideScreen] — organic/chemical badge,
/// product info, dosage, and its bibliographic [Treatment.source].
class TreatmentCard extends StatelessWidget {
  final Treatment treatment;

  const TreatmentCard({super.key, required this.treatment});

  @override
  Widget build(BuildContext context) {
    final isOrganic = treatment.type == 'organic';
    final accent = isOrganic ? kPrimaryGreen : kSoilBrown;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isOrganic ? '🌿 Organic' : '🧪 Chemical',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accent),
                  ),
                ),
                const Spacer(),
                Text(treatment.estimatedCostUsd,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: kSoilBrown, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 10),
            Text(treatment.productName,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(treatment.activeIngredient,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600], fontStyle: FontStyle.italic)),
            const Divider(height: 16),
            _row(context, 'Dosage', treatment.dosage),
            _row(context, 'Application', treatment.applicationMethod),
            _row(context, 'Where to buy', treatment.availability),
            const SizedBox(height: 6),
            Text('Source: ${treatment.source}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500], fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child: Text('$label:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600, color: Colors.grey[700])),
            ),
            Expanded(
              child: Text(value,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      );
}
