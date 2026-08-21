import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// Singleton that manages the SQLite database lifecycle.
/// On first launch it copies the pre-populated cropguard.db from assets
/// into the app's documents directory, where sqflite can open it.
class DatabaseHelper {
  static const _dbName = 'cropguard.db';
  static const _dbVersion = 1;

  /// Bump this whenever `assets/db/cropguard.db` is regenerated with new or
  /// changed content (new disease/treatment rows, a new column such as
  /// `image_phashes`, etc). The database file itself has no version stamp
  /// sqflite can read before opening it, so this is the only signal that
  /// tells [_initDb] the copy already sitting in the app's documents
  /// directory (from a previous install) is stale and must be replaced —
  /// without it, an existing install silently keeps its old data forever
  /// after an app update, since `openDatabase`'s `version` only drives
  /// onUpgrade for schema changes made through sqflite itself, not for a
  /// wholesale asset swap.
  static const _contentVersion = 3;
  static const _contentVersionKey = 'cropguard_db_content_version';
  static const _defaultProfileName = 'Shared Bookmarks';

  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(docsDir.path, _dbName);
    final dbExists = await File(dbPath).exists();
    final prefs = await SharedPreferences.getInstance();
    final installedVersion = prefs.getInt(_contentVersionKey);
    _UserDataSnapshot? snapshot;

    // Copy from assets on first install, or re-copy (overwriting whatever
    // is there) whenever the bundled content is newer than what this
    // install last copied — see _contentVersion above.
    if (!dbExists || installedVersion != _contentVersion) {
      if (dbExists) {
        snapshot = await _snapshotUserData(dbPath);
      }
      await _copyDbFromAssets(dbPath);
      await prefs.setInt(_contentVersionKey, _contentVersion);
    }

    final db = await openDatabase(
      dbPath,
      version: _dbVersion,
      // Schema is managed by the pre-populated asset DB.
      // onCreate/onUpgrade only needed if migrating in a future version.
    );

    await _migrateUserTables(db);
    if (snapshot != null) {
      await _restoreUserDataSnapshot(db, snapshot);
    }

    return db;
  }

  Future<void> _copyDbFromAssets(String targetPath) async {
    final data = await rootBundle.load('assets/db/$_dbName');
    final bytes = data.buffer.asUint8List();
    await File(targetPath).writeAsBytes(bytes, flush: true);
  }

  Future<_UserDataSnapshot> _snapshotUserData(String dbPath) async {
    final oldDb = await openDatabase(dbPath, singleInstance: false);
    try {
      final profiles = <Map<String, dynamic>>[];
      final bookmarks = <Map<String, dynamic>>[];

      if (await _tableExists(oldDb, 'profiles')) {
        final rows = await oldDb.query('profiles');
        profiles.addAll(rows);
      }

      if (await _tableExists(oldDb, 'bookmarks')) {
        final hasProfileId = await _columnExists(oldDb, 'bookmarks', 'profile_id');
        if (hasProfileId && await _tableExists(oldDb, 'profiles')) {
          final rows = await oldDb.rawQuery(
            '''
            SELECT
              b.profile_id,
              p.name AS profile_name,
              b.disease_id,
              b.saved_at
            FROM bookmarks b
            LEFT JOIN profiles p ON p.id = b.profile_id
            ''',
          );
          bookmarks.addAll(rows);
        } else {
          final rows = await oldDb.query('bookmarks');
          for (final row in rows) {
            bookmarks.add({
              'profile_id': null,
              'profile_name': null,
              'disease_id': row['disease_id'],
              'saved_at': row['saved_at'],
            });
          }
        }
      }

      return _UserDataSnapshot(profiles: profiles, bookmarks: bookmarks);
    } finally {
      await oldDb.close();
    }
  }

  Future<void> _migrateUserTables(Database db) async {
    await db.transaction((txn) async {
      await txn.execute('PRAGMA foreign_keys = OFF');

      await txn.execute('''
        CREATE TABLE IF NOT EXISTS profiles (
          id          INTEGER PRIMARY KEY AUTOINCREMENT,
          name        TEXT    NOT NULL UNIQUE,
          is_default  INTEGER NOT NULL DEFAULT 0 CHECK(is_default IN (0, 1)),
          created_at  TEXT    NOT NULL,
          updated_at  TEXT    NOT NULL
        )
      ''');

      final now = DateTime.now().toIso8601String();
      await txn.rawInsert(
        '''
        INSERT OR IGNORE INTO profiles (id, name, is_default, created_at, updated_at)
        VALUES (1, ?, 1, ?, ?)
        ''',
        [_defaultProfileName, now, now],
      );

      final hasBookmarksTable = await _tableExists(txn, 'bookmarks');
      final hasProfileId =
          hasBookmarksTable && await _columnExists(txn, 'bookmarks', 'profile_id');
      final hasDiseaseName =
          hasBookmarksTable && await _columnExists(txn, 'bookmarks', 'disease_name');
      final hasCropName =
          hasBookmarksTable && await _columnExists(txn, 'bookmarks', 'crop_name');

      final needsBookmarksRebuild =
          !hasBookmarksTable || !hasProfileId || hasDiseaseName || hasCropName;

      if (needsBookmarksRebuild) {
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS bookmarks_new (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            profile_id  INTEGER NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
            disease_id  INTEGER NOT NULL REFERENCES diseases(id),
            saved_at    TEXT    NOT NULL,
            UNIQUE(profile_id, disease_id)
          )
        ''');

        if (hasBookmarksTable) {
          if (hasProfileId) {
            await txn.rawInsert('''
              INSERT OR IGNORE INTO bookmarks_new (profile_id, disease_id, saved_at)
              SELECT
                COALESCE(profile_id, 1) AS profile_id,
                disease_id,
                MAX(saved_at) AS saved_at
              FROM bookmarks
              GROUP BY COALESCE(profile_id, 1), disease_id
            ''');
          } else {
            await txn.rawInsert('''
              INSERT OR IGNORE INTO bookmarks_new (profile_id, disease_id, saved_at)
              SELECT
                1 AS profile_id,
                disease_id,
                MAX(saved_at) AS saved_at
              FROM bookmarks
              GROUP BY disease_id
            ''');
          }

          await txn.execute('DROP TABLE bookmarks');
        }

        await txn.execute('ALTER TABLE bookmarks_new RENAME TO bookmarks');
      } else {
        await txn.execute('''
          DELETE FROM bookmarks
          WHERE id NOT IN (
            SELECT MAX(id)
            FROM bookmarks
            GROUP BY profile_id, disease_id
          )
        ''');
      }

      await txn.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_bookmarks_profile_disease ON bookmarks(profile_id, disease_id)',
      );
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_bookmarks_profile_saved ON bookmarks(profile_id, saved_at DESC)',
      );

      await txn.execute('PRAGMA foreign_keys = ON');
    });
  }

  Future<void> _restoreUserDataSnapshot(
    Database db,
    _UserDataSnapshot snapshot,
  ) async {
    if (snapshot.profiles.isEmpty && snapshot.bookmarks.isEmpty) return;

    await db.transaction((txn) async {
      final profileNameToId = <String, int>{};

      final existingProfiles = await txn.query('profiles');
      for (final row in existingProfiles) {
        final name = row['name'] as String;
        profileNameToId[name] = row['id'] as int;
      }

      for (final row in snapshot.profiles) {
        final name = row['name'] as String?;
        if (name == null || name.isEmpty || profileNameToId.containsKey(name)) {
          continue;
        }

        final isDefault = (row['is_default'] as int?) ?? 0;
        final createdAt = (row['created_at'] as String?) ?? DateTime.now().toIso8601String();
        final updatedAt = (row['updated_at'] as String?) ?? createdAt;
        final id = await txn.rawInsert(
          '''
          INSERT INTO profiles (name, is_default, created_at, updated_at)
          VALUES (?, ?, ?, ?)
          ''',
          [name, isDefault == 1 ? 1 : 0, createdAt, updatedAt],
        );
        profileNameToId[name] = id;
      }

      final sharedProfileId = profileNameToId[_defaultProfileName] ?? 1;
      for (final row in snapshot.bookmarks) {
        final diseaseId = row['disease_id'] as int?;
        if (diseaseId == null) continue;

        final savedAt =
            (row['saved_at'] as String?) ?? DateTime.now().toIso8601String();
        final profileName = row['profile_name'] as String?;
        final profileId =
            profileName != null ? profileNameToId[profileName] : null;

        await txn.rawInsert(
          '''
          INSERT INTO bookmarks (profile_id, disease_id, saved_at)
          VALUES (?, ?, ?)
          ON CONFLICT(profile_id, disease_id)
          DO UPDATE SET saved_at = excluded.saved_at
          WHERE excluded.saved_at > bookmarks.saved_at
          ''',
          [profileId ?? sharedProfileId, diseaseId, savedAt],
        );
      }
    });
  }

  Future<bool> _tableExists(DatabaseExecutor db, String table) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      [table],
    );
    return rows.isNotEmpty;
  }

  Future<bool> _columnExists(
    DatabaseExecutor db,
    String table,
    String column,
  ) async {
    final rows = await db.rawQuery('PRAGMA table_info($table)');
    for (final row in rows) {
      if (row['name'] == column) return true;
    }
    return false;
  }

  // ─── Generic query helpers ───────────────────────────────────

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;
    return db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? args,
  ]) async {
    final db = await database;
    return db.rawQuery(sql, args);
  }

  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    return db.insert(table, values,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    final db = await database;
    return db.update(table, values, where: where, whereArgs: whereArgs);
  }

  Future<void> execute(String sql, [List<Object?>? args]) async {
    final db = await database;
    if (args == null || args.isEmpty) {
      await db.execute(sql);
      return;
    }

    await db.rawUpdate(sql, args);
  }

  Future<int> delete(
    String table, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    final db = await database;
    return db.delete(table, where: where, whereArgs: whereArgs);
  }
}

class _UserDataSnapshot {
  final List<Map<String, dynamic>> profiles;
  final List<Map<String, dynamic>> bookmarks;

  const _UserDataSnapshot({
    required this.profiles,
    required this.bookmarks,
  });
}
