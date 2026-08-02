import '../models/treatment.dart';
import 'database_helper.dart';

class TreatmentService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Returns treatments for a disease — organic options first, then chemical.
  Future<List<Treatment>> getTreatments(int diseaseId) async {
    const typeOrder = "CASE type WHEN 'organic' THEN 1 ELSE 2 END";
    final rows = await _db.rawQuery(
      'SELECT * FROM treatments WHERE disease_id = ? ORDER BY $typeOrder',
      [diseaseId],
    );
    return rows.map(Treatment.fromMap).toList();
  }
}
