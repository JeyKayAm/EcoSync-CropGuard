/// A single observable symptom of a [Disease], used by [DiagnosticService]
/// to match user-selected symptoms back to candidate diseases.
class Symptom {
  final int id;
  final int diseaseId;
  final String description;
  final String stage; // early | mid | late

  const Symptom({
    required this.id,
    required this.diseaseId,
    required this.description,
    required this.stage,
  });

  factory Symptom.fromMap(Map<String, dynamic> map) => Symptom(
        id: map['id'] as int,
        diseaseId: map['disease_id'] as int,
        description: map['description'] as String,
        stage: map['stage'] as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'disease_id': diseaseId,
        'description': description,
        'stage': stage,
      };
}
