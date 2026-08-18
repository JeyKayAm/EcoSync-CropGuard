import 'package:flutter/material.dart';

/// One topic in the [HelpScreen] accordion — a plain-language walkthrough
/// of a single app feature.
class _HelpTopic {
  final IconData icon;
  final String title;
  final String body;

  const _HelpTopic({required this.icon, required this.title, required this.body});
}

const List<_HelpTopic> _kHelpTopics = [
  _HelpTopic(
    icon: Icons.grass_outlined,
    title: 'Getting started',
    body:
        'On the home screen, tap the crop you\'re growing (maize, tobacco, '
        'groundnuts, sorghum or sweet potatoes) to open its diagnosis page. '
        'From there you can browse photos, scan a photo, check symptoms, or '
        'narrow down by plant part.',
  ),
  _HelpTopic(
    icon: Icons.photo_library_outlined,
    title: 'Browse Photos to Find a Match',
    body:
        'Shows reference photos of known diseases for the crop, grouped so '
        'you can compare them against what you see in your field. Tap a '
        'photo to open its disease page with symptoms and treatment '
        'guidance.',
  ),
  _HelpTopic(
    icon: Icons.camera_alt_outlined,
    title: 'Scan a Photo (Beta)',
    body:
        'Take or pick a photo of the affected plant and the app ranks it '
        'against the reference photo set by visual similarity, entirely on '
        'your device — this is a beta feature, not a trained AI model, so '
        'it works best when your photo has similar framing and lighting to '
        'the app\'s reference photos. Treat results as a starting point, '
        'not a confirmed diagnosis.',
  ),
  _HelpTopic(
    icon: Icons.checklist_outlined,
    title: 'Check Symptoms',
    body:
        'Pick the symptoms you\'re observing (spots, wilting, discolouration '
        'and so on) and the app lists diseases that match. This is the most '
        'reliable path when you can\'t get a clear photo.',
  ),
  _HelpTopic(
    icon: Icons.spa_outlined,
    title: 'Narrow down by plant part',
    body:
        'On a crop\'s page, tap a plant part (leaves, stem, roots, etc.) to '
        'see only the diseases known to affect that part, or tap "Show All '
        'Diseases for This Crop" to browse everything at once.',
  ),
  _HelpTopic(
    icon: Icons.bookmark_outline,
    title: 'Saved Diagnoses',
    body:
        'Tap the bookmark icon on a disease page to save it for later. Find '
        'everything you\'ve saved from the bookmark icon in the top-right '
        'of the home screen — handy for revisiting a diagnosis without a '
        'signal.',
  ),
  _HelpTopic(
    icon: Icons.medical_services_outlined,
    title: 'Treatment guidance',
    body:
        'Each disease page links to recommended treatments, including '
        'organic and chemical options where available. Every entry cites '
        'its source for traceability.',
  ),
  _HelpTopic(
    icon: Icons.menu_book_outlined,
    title: 'Farming Terms Glossary',
    body:
        'Unfamiliar word on a disease or treatment page? Look it up from '
        'the "Explain terms" button on that page, or browse the full list '
        'from Settings.',
  ),
  _HelpTopic(
    icon: Icons.wifi_off_outlined,
    title: 'Works offline',
    body:
        'All crop, disease and treatment information is stored on your '
        'device, so the app works fully offline — no signal or data needed '
        'once installed.',
  ),
  _HelpTopic(
    icon: Icons.info_outline,
    title: 'A decision-support tool',
    body:
        'This app helps narrow down likely diseases and treatments — it is '
        'not a substitute for expert diagnosis. Where you\'re unsure, '
        'consult your AGRITEX extension officer before applying treatments.',
  ),
];

/// Plain-language "how to use this app" reference, reached from Settings.
/// Mirrors [GlossaryScreen]'s structure but as an accordion so a first-time
/// user can scan topic titles without a wall of text.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: const Text('Help & How to Use'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _kHelpTopics.length,
        itemBuilder: (context, i) {
          final topic = _kHelpTopics[i];
          return ExpansionTile(
            leading: Icon(topic.icon, color: colorScheme.primary),
            title: Text(topic.title,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            childrenPadding:
                const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(topic.body,
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
