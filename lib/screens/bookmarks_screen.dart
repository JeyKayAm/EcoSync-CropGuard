import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../services/diagnostic_service.dart';
import 'disease_detail_screen.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: const Text('Saved Diagnoses'),
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, state, _) {
          final bookmarks = state.bookmarks;
          if (bookmarks.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_border, size: 56, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No saved diagnoses yet.',
                      style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 4),
                  Text('Tap the bookmark icon on any disease to save it.',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: bookmarks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, i) {
              final b = bookmarks[i];
              final date = DateTime.tryParse(b.savedAt);
              final dateStr = date != null
                  ? '${date.day}/${date.month}/${date.year}'
                  : '';
              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: Icon(Icons.bookmark, color: colorScheme.primary),
                  title: Text(b.diseaseName,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${b.cropName}  •  $dateStr'),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () async {
                    final disease = await DiagnosticService()
                        .getDiseaseById(b.diseaseId);
                    if (disease != null && context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DiseaseDetailScreen(
                            disease: disease,
                            cropName: b.cropName,
                          ),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
