import '../models/bookmark.dart';
import 'database_helper.dart';

/// CRUD access to the `bookmarks` table, keyed by `disease_id` rather than
/// the bookmark's own id — a disease can only be bookmarked once per profile,
/// so [isBookmarked]/[remove] look up by (profile, disease).
class BookmarkService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<List<Bookmark>> getAll({required int profileId}) async {
    final rows = await _db.rawQuery(
      '''
      SELECT
        b.id,
        b.profile_id,
        b.disease_id,
        b.saved_at,
        d.name AS disease_name,
        c.name AS crop_name
      FROM bookmarks b
      JOIN diseases d ON d.id = b.disease_id
      JOIN crops c ON c.id = d.crop_id
      WHERE b.profile_id = ?
      ORDER BY b.saved_at DESC
      ''',
      [profileId],
    );
    return rows.map(Bookmark.fromMap).toList();
  }

  Future<bool> isBookmarked({
    required int profileId,
    required int diseaseId,
  }) async {
    final rows = await _db.query(
      'bookmarks',
      where: 'profile_id = ? AND disease_id = ?',
      whereArgs: [profileId, diseaseId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> add(Bookmark bookmark) async {
    await _db.insert('bookmarks', bookmark.toMap());
  }

  Future<void> remove({
    required int profileId,
    required int diseaseId,
  }) async {
    await _db.delete(
      'bookmarks',
      where: 'profile_id = ? AND disease_id = ?',
      whereArgs: [profileId, diseaseId],
    );
  }
}
