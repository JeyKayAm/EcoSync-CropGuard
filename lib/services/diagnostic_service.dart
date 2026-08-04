import '../models/disease.dart';
import '../models/symptom.dart';
import 'database_helper.dart';

/// Read-only queries backing the symptom-based diagnosis flow: narrowing
/// diseases by crop/plant-part, then listing a chosen disease's symptoms.
/// This is a lookup/filter tool, not image-based ML detection.
class DiagnosticService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Returns all diseases for a given crop, optionally filtered by plant part.
  Future<List<Disease>> getDiseases({
    required int cropId,
    String? plantPart,
  }) async {
    final rows = await _db.query(
      'diseases',
      where: plantPart != null
          ? 'crop_id = ? AND plant_part = ?'
          : 'crop_id = ?',
      whereArgs: plantPart != null ? [cropId, plantPart] : [cropId],
      orderBy: 'severity DESC, name ASC',
      limit: 10,
    );
    return rows.map(Disease.fromMap).toList();
  }

  /// Returns the distinct plant parts that actually have diseases recorded
  /// for this crop (e.g. Tobacco never returns 'cob'), in the same fixed
  /// leaf/stem/root/cob/whole order used everywhere else in the UI.
  Future<List<String>> getAvailablePlantParts(int cropId) async {
    final rows = await _db.rawQuery(
      'SELECT DISTINCT plant_part FROM diseases WHERE crop_id = ?',
      [cropId],
    );
    final present = rows.map((r) => r['plant_part'] as String).toSet();
    const order = ['leaf', 'stem', 'root', 'cob', 'whole'];
    return order.where(present.contains).toList();
  }

  /// Returns symptoms for a given disease, ordered by stage.
  Future<List<Symptom>> getSymptoms(int diseaseId) async {
    const stageOrder = "CASE stage WHEN 'early' THEN 1 WHEN 'mid' THEN 2 ELSE 3 END";
    final rows = await _db.rawQuery(
      'SELECT * FROM symptoms WHERE disease_id = ? ORDER BY $stageOrder',
      [diseaseId],
    );
    return rows.map(Symptom.fromMap).toList();
  }

  /// Returns a single disease by ID.
  Future<Disease?> getDiseaseById(int id) async {
    final rows = await _db.query('diseases', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Disease.fromMap(rows.first);
  }
}
