import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../utils/constants.dart';
import 'glossary_screen.dart';
import 'help_screen.dart';

/// Lets the user pick a Material 3 theme seed colour, persisted via
/// [AppStateProvider.setThemeSeed]. Disease severity colours
/// (see [severityColor]) are semantic and intentionally don't change here.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _showCreateProfileDialog(
    BuildContext context,
    AppStateProvider state,
  ) async {
    final controller = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Profile'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 24,
          decoration: const InputDecoration(
            hintText: 'e.g. Tariro, Nyasha, Shared',
            labelText: 'Profile name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (message == null) return;
    final error = await state.createProfile(message);
    if (!context.mounted || error == null) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error)));
  }

  Future<void> _showRenameProfileDialog(
    BuildContext context,
    AppStateProvider state,
    int profileId,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename Profile'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 24,
          decoration: const InputDecoration(labelText: 'Profile name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName == null) return;
    final error = await state.renameProfile(
      profileId: profileId,
      newName: newName,
    );
    if (!context.mounted || error == null) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error)));
  }

  Future<void> _confirmDeleteProfile(
    BuildContext context,
    AppStateProvider state,
    int profileId,
    String profileName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Profile?'),
        content: Text(
          'Delete "$profileName" and its saved diagnoses from this device?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final error = await state.deleteProfile(profileId);
    if (!context.mounted || error == null) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error)));
  }

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
              Text('Local Profiles',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700, color: colorScheme.primary)),
              const SizedBox(height: 4),
              Text(
                'Each profile keeps a separate Saved Diagnoses list on this device.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              ...state.profiles.map((profile) {
                final active = profile.id == state.activeProfileId;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: active ? colorScheme.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ListTile(
                    onTap: () => state.switchProfile(profile.id),
                    leading: Icon(
                      Icons.person_outline,
                      color: active ? colorScheme.primary : Colors.grey[700],
                    ),
                    title: Text(
                      profile.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle:
                        profile.isDefault ? const Text('Shared fallback profile') : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (active)
                          Icon(Icons.check_circle, color: colorScheme.primary),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'rename') {
                              _showRenameProfileDialog(
                                context,
                                state,
                                profile.id,
                                profile.name,
                              );
                              return;
                            }
                            if (value == 'delete') {
                              _confirmDeleteProfile(
                                context,
                                state,
                                profile.id,
                                profile.name,
                              );
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'rename',
                              child: Text('Rename'),
                            ),
                            if (!profile.isDefault)
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _showCreateProfileDialog(context, state),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Add Profile'),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
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
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HelpScreen()),
                  ),
                  leading: Icon(Icons.help_outline, color: colorScheme.primary),
                  title: const Text('Help & How to Use',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Instructions for using the app\'s features'),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
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
              Text('Photo Lookup (Beta)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700, color: colorScheme.primary)),
              const SizedBox(height: 4),
              Text(
                kPhotoLookupDisclaimer,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600]),
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
