import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Singleton that manages the SQLite database lifecycle.
/// On first launch it copies the pre-populated cropguard.db from assets
/// into the app's documents directory, where sqflite can open it.
class DatabaseHelper {
  static const _dbName = 'cropguard.db';
  static const _dbVersion = 1;

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

    // Copy from assets on first install or after an app update.
    if (!await File(dbPath).exists()) {
      await _copyDbFromAssets(dbPath);
    }

    return openDatabase(
      dbPath,
      version: _dbVersion,
      // Schema is managed by the pre-populated asset DB.
      // onCreate/onUpgrade only needed if migrating in a future version.
    );
  }

  Future<void> _copyDbFromAssets(String targetPath) async {
    final data = await rootBundle.load('assets/db/$_dbName');
    final bytes = data.buffer.asUint8List();
    await File(targetPath).writeAsBytes(bytes, flush: true);
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

  Future<int> delete(
    String table, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    final db = await database;
    return db.delete(table, where: where, whereArgs: whereArgs);
  }
}
