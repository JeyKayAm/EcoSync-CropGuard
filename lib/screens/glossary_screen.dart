import 'package:flutter/material.dart';
import '../utils/glossary_terms.dart';

/// Full browsable list of [kGlossaryTerms], reached from Settings. The
/// contextual "Explain terms" buttons on disease/treatment screens cover
/// the same data in-place; this is the standalone reference for browsing
/// everything at once.
class GlossaryScreen extends StatelessWidget {
  const GlossaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: const Text('Farming Terms Glossary'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: kGlossaryTerms.length,
        separatorBuilder: (_, __) => const Divider(height: 20),
        itemBuilder: (context, i) {
          final term = kGlossaryTerms[i];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(term.term,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700, color: colorScheme.primary)),
              const SizedBox(height: 3),
              Text(term.definition,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(height: 1.4)),
            ],
          );
        },
      ),
    );
  }
}
