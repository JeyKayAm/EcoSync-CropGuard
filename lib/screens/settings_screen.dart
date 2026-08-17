import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../utils/constants.dart';
import 'glossary_screen.dart';

/// Lets the user pick a Material 3 theme seed colour, persisted via
/// [AppStateProvider.setThemeSeed]. Disease severity colours
/// (see [severityColor]) are semantic and intentionally don't change here.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: const Text('Settings'),
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, state, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('App Colour',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700, color: colorScheme.primary)),
              const SizedBox(height: 4),
              Text(
                'Changes the app bar, buttons and highlights. '
                'Disease severity colours always stay red/amber/green.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ...kThemeSeedOptions.map((option) {
                final color = option['color'] as Color;
                final label = option['label'] as String;
                final selected = color.toARGB32() == state.themeSeed.toARGB32();
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: selected ? color : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ListTile(
                    onTap: () => state.setThemeSeed(color),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    title: Text(label,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: selected
                        ? Icon(Icons.check_circle, color: color)
                        : const Icon(Icons.circle_outlined, color: Colors.grey),
                  ),
                );
              }),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GlossaryScreen()),
                  ),
                  leading: Icon(Icons.menu_book_outlined, color: colorScheme.primary),
                  title: const Text('Farming Terms Glossary',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Plain-language definitions for technical terms'),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              Text('About',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700, color: colorScheme.primary)),
              const SizedBox(height: 4),
              Text('$kAppName — Version $kAppVersion',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey[600])),
            ],
          );
        },
      ),
    );
  }
}
