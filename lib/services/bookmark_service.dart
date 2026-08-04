import '../models/bookmark.dart';
import 'database_helper.dart';

/// CRUD access to the `bookmarks` table, keyed by `disease_id` rather than
/// the bookmark's own id — a disease can only be bookmarked once, so
/// [isBookmarked]/[remove] look up by disease, not by bookmark id.
class BookmarkService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<List<Bookmark>> getAll() async {
    final rows = await _db.query(
      'bookmarks',
      orderBy: 'saved_at DESC',
    );
    return rows.map(Bookmark.fromMap).toList();
  }

  Future<bool> isBookmarked(int diseaseId) async {
    final rows = await _db.query(
      'bookmarks',
      where: 'disease_id = ?',
      whereArgs: [diseaseId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> add(Bookmark bookmark) async {
    await _db.insert('bookmarks', bookmark.toMap());
  }

  Future<void> remove(int diseaseId) async {
    await _db.delete(
      'bookmarks',
      where: 'disease_id = ?',
      whereArgs: [diseaseId],
    );
  }
}
