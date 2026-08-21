import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../utils/constants.dart';
import '../widgets/crop_tile.dart';
import 'bookmarks_screen.dart';
import 'crop_detail_screen.dart';
import 'settings_screen.dart';

/// Landing screen: pick a crop to start diagnosis, or jump to bookmarks/
/// settings. Crop list comes from [AppStateProvider], loaded once at startup.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        titleSpacing: 16,
        title: Row(
          children: [
            SvgPicture.asset(
              'assets/branding/logo_mark.svg',
              width: 30,
              height: 30,
            ),
            const SizedBox(width: 10),
            const Text(kAppName,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            tooltip: 'Saved Diagnoses',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BookmarksScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, state, _) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header banner
              Container(
                width: double.infinity,
                color: colorScheme.primary,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select the affected crop to begin diagnosis.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Active profile: ${state.activeProfileName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: state.crops.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, i) {
                    final crop = state.crops[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: CropTile(
                        crop: crop,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CropDetailScreen(crop: crop),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Disclaimer footer
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.amber.shade50,
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
