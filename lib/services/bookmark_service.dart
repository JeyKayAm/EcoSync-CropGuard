import '../models/bookmark.dart';
import 'database_helper.dart';

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
