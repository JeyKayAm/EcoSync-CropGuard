import '../models/profile.dart';
import 'database_helper.dart';

/// Manages local profiles used for per-user bookmark separation on a shared
/// device. There is always at least one fallback "Shared Bookmarks" profile.
class ProfileService {
  static const defaultProfileName = 'Shared Bookmarks';

  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<List<Profile>> getAll() async {
    final rows = await _db.query(
      'profiles',
      orderBy: 'is_default DESC, name COLLATE NOCASE ASC',
    );
    return rows.map(Profile.fromMap).toList();
  }

  Future<Profile> ensureDefaultProfile() async {
    final rows = await _db.query(
      'profiles',
      where: 'is_default = 1',
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return Profile.fromMap(rows.first);
    }

    final now = DateTime.now().toIso8601String();
    final id = await _db.insert('profiles', {
      'name': defaultProfileName,
      'is_default': 1,
      'created_at': now,
      'updated_at': now,
    });

    final created = await _db.query(
      'profiles',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return Profile.fromMap(created.first);
  }

  Future<Profile> create(String name) async {
    final now = DateTime.now().toIso8601String();
    final id = await _db.insert('profiles', {
      'name': name,
      'is_default': 0,
      'created_at': now,
      'updated_at': now,
    });

    final rows = await _db.query(
      'profiles',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return Profile.fromMap(rows.first);
  }

  Future<void> rename({required int profileId, required String newName}) async {
    final now = DateTime.now().toIso8601String();
    await _db.update(
      'profiles',
      {
        'name': newName,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [profileId],
    );
  }

  Future<void> delete(int profileId) async {
    await _db.delete(
      'profiles',
      where: 'id = ? AND is_default = 0',
      whereArgs: [profileId],
    );
  }
}
