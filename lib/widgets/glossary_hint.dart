import 'package:flutter/material.dart';
import '../utils/glossary_terms.dart';

/// Scans [text] for known jargon/abbreviations (see [kGlossaryTerms]) and,
/// if any are found, shows a small "Explain these terms" button that opens
/// a bottom sheet with plain-language definitions. Renders nothing when
/// [text] contains no recognised terms, so plain-language content stays
/// uncluttered.
class GlossaryHint extends StatelessWidget {
  final String text;

  const GlossaryHint({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final matches = findGlossaryMatches(text);
    if (matches.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: TextButton.icon(
        onPressed: () => _showSheet(context, matches),
        icon: const Icon(Icons.info_outline, size: 16),
        label: Text(matches.length == 1
            ? 'Explain this term'
            : 'Explain these terms (${matches.length})'),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }

  void _showSheet(BuildContext context, List<GlossaryTerm> matches) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.25,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            for (final m in matches)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.term,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary)),
                    const SizedBox(height: 3),
                    Text(m.definition,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(height: 1.4)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
