import 'package:flutter/material.dart';
import '../models/crop.dart';
import '../models/symptom_tag.dart';
import '../services/diagnostic_service.dart';
import 'symptom_checker_results_screen.dart';

/// Lets the user pick observed symptoms as input — the real symptom-based
/// diagnosis entry point, as opposed to [SymptomFilterScreen]'s crop/
/// plant-part browsing. Selected tags are handed to
/// [SymptomCheckerResultsScreen], which ranks candidate diseases by match
/// count.
class SymptomCheckerScreen extends StatefulWidget {
  final Crop crop;

  const SymptomCheckerScreen({super.key, required this.crop});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  final DiagnosticService _svc = DiagnosticService();
  late Future<List<SymptomTag>> _tagsFuture;
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    _tagsFuture = _svc.getSymptomTags(widget.crop.id);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: Text('${widget.crop.name} — Symptom Checker',
            style: const TextStyle(fontSize: 16)),
      ),
      body: FutureBuilder<List<SymptomTag>>(
        future: _tagsFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final tags = snap.data ?? [];
          if (tags.isEmpty) {
            return const Center(
              child: Text('No symptom data available for this crop.'),
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Text(
                  'Select everything you observe on the plant. '
                  'The more you select, the more precise the match.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: tags.length,
                  itemBuilder: (context, i) {
                    final tag = tags[i];
                    return CheckboxListTile(
                      value: _selected.contains(tag.id),
                      title: Text(tag.label),
                      activeColor: colorScheme.primary,
                      onChanged: (checked) {
                        setState(() {
                          if (checked ?? false) {
                            _selected.add(tag.id);
                          } else {
                            _selected.remove(tag.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _selected.isEmpty
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SymptomCheckerResultsScreen(
                                crop: widget.crop,
                                selectedTagIds: _selected.toList(),
                              ),
                            ),
                          ),
                  icon: const Icon(Icons.search),
                  label: Text(_selected.isEmpty
                      ? 'Select at least one symptom'
                      : 'Find Matches (${_selected.length} selected)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    disabledBackgroundColor: Colors.grey.shade300,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
