import '../models/disease.dart';
import '../models/symptom.dart';
import '../models/symptom_tag.dart';
import 'database_helper.dart';

/// Read-only queries backing the symptom-based diagnosis flow: narrowing
/// diseases by crop/plant-part, then listing a chosen disease's symptoms —
/// plus the Symptom Checker's reverse lookup, ranking diseases by how many
/// user-selected symptom tags they match. This is a lookup/filter tool, not
/// image-based ML detection.
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

  /// Symptom tags relevant to a crop — only tags actually used by that
  /// crop's diseases — for the Symptom Checker's checklist.
  Future<List<SymptomTag>> getSymptomTags(int cropId) async {
    final rows = await _db.rawQuery('''
      SELECT DISTINCT t.* FROM symptom_tags t
      JOIN disease_symptom_tags dst ON dst.tag_id = t.id
      JOIN diseases d ON d.id = dst.disease_id
      WHERE d.crop_id = ?
      ORDER BY t.label ASC
    ''', [cropId]);
    return rows.map(SymptomTag.fromMap).toList();
  }

  /// Diseases for [cropId] ranked by how many of [tagIds] they match
  /// (highest match count first). Pure on-device SQL match-count ranking,
  /// no ML.
  Future<List<(Disease, int)>> getDiseasesBySymptomTags(
    int cropId,
    List<int> tagIds,
  ) async {
    if (tagIds.isEmpty) return [];
    final placeholders = List.filled(tagIds.length, '?').join(',');
    final rows = await _db.rawQuery('''
      SELECT d.*, COUNT(*) as match_count
      FROM diseases d
      JOIN disease_symptom_tags dst ON dst.disease_id = d.id
      WHERE dst.tag_id IN ($placeholders) AND d.crop_id = ?
      GROUP BY d.id
      ORDER BY match_count DESC, d.severity DESC, d.name ASC
    ''', [...tagIds, cropId]);
    return rows
        .map((r) => (Disease.fromMap(r), r['match_count'] as int))
        .toList();
  }
}
