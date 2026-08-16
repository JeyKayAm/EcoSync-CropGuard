/// A canonical, checklist-friendly symptom label, mirroring the
/// `symptom_tags` table. Used by [DiagnosticService] as multi-select input
/// for the Symptom Checker, distinct from [Symptom]'s free-text per-disease
/// descriptions.
class SymptomTag {
  final int id;
  final String label;

  const SymptomTag({required this.id, required this.label});

  factory SymptomTag.fromMap(Map<String, dynamic> map) => SymptomTag(
        id: map['id'] as int,
        label: map['label'] as String,
      );
}
