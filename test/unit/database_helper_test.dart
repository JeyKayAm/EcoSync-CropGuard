// Unit tests (Section 3.7.1): DatabaseHelper's generic query/insert/delete
// wrappers, run against the real, bundled cropguard.db via sqflite_common_ffi
// (see test/support/db_test_setup.dart) rather than against a mock — this
// exercises the same SQL the app issues on-device, just through a host
// SQLite engine instead of a platform channel.
import 'package:flutter_test/flutter_test.dart';
import 'package:ecosync_cropguard/services/database_helper.dart';

import '../support/db_test_setup.dart';

void main() {
  setUpAll(initTestDatabaseEnvironment);

  final db = DatabaseHelper.instance;

  test('first access copies cropguard.db from assets and opens it', () async {
    final database = await db.database;
    expect(database.isOpen, isTrue);
  });

  group('query()', () {
    test('returns all rows for a table with no filter', () async {
      final crops = await db.query('crops');
      expect(crops.length, 5);
    });

    test('applies where/whereArgs', () async {
      final rows = await db.query('crops', where: 'name = ?', whereArgs: ['Maize']);
      expect(rows, hasLength(1));
      expect(rows.first['id'], 1);
    });

    test('applies orderBy', () async {
      final rows = await db.query('crops', orderBy: 'name ASC');
      final names = rows.map((r) => r['name']).toList();
      expect(names, [
        'Groundnuts',
        'Maize',
        'Sorghum',
        'Sweet Potatoes',
        'Tobacco',
      ]);
    });

    test('applies limit', () async {
      final rows = await db.query('crops', limit: 2);
      expect(rows, hasLength(2));
    });

    test('edge case: where clause matching nothing returns an empty list',
        () async {
      final rows =
          await db.query('crops', where: 'name = ?', whereArgs: ['Not A Crop']);
      expect(rows, isEmpty);
    });
  });

  group('rawQuery()', () {
    test('runs a parameterised SQL statement', () async {
      final rows = await db.rawQuery(
        'SELECT COUNT(*) as n FROM diseases WHERE crop_id = ?',
        [1],
      );
      expect(rows.first['n'], 5);
    });
  });

  group('insert()/delete()', () {
    test('insert() writes a row and delete() removes it by where clause',
        () async {
      final id = await db.insert('bookmarks', {
        'disease_id': 999,
        'disease_name': 'Test Disease',
        'crop_name': 'Test Crop',
        'saved_at': '2026-01-01T00:00:00.000',
      });
      expect(id, greaterThan(0));

      final inserted =
          await db.query('bookmarks', where: 'disease_id = ?', whereArgs: [999]);
      expect(inserted, hasLength(1));

      final deletedCount = await db.delete(
        'bookmarks',
        where: 'disease_id = ?',
        whereArgs: [999],
      );
      expect(deletedCount, 1);

      final remaining =
          await db.query('bookmarks', where: 'disease_id = ?', whereArgs: [999]);
      expect(remaining, isEmpty);
    });

    test('insert() with ConflictAlgorithm.replace overwrites a matching row',
        () async {
      final firstId = await db.insert('bookmarks', {
        'id': 500,
        'disease_id': 998,
        'disease_name': 'Original Name',
        'crop_name': 'Test Crop',
        'saved_at': '2026-01-01T00:00:00.000',
      });
      final secondId = await db.insert('bookmarks', {
        'id': 500,
        'disease_id': 998,
        'disease_name': 'Replaced Name',
        'crop_name': 'Test Crop',
        'saved_at': '2026-01-02T00:00:00.000',
      });
      expect(secondId, firstId);

      final rows =
          await db.query('bookmarks', where: 'id = ?', whereArgs: [500]);
      expect(rows, hasLength(1));
      expect(rows.first['disease_name'], 'Replaced Name');

      await db.delete('bookmarks', where: 'id = ?', whereArgs: [500]);
    });

    test('edge case: delete() with a non-matching where clause deletes nothing',
        () async {
      final deletedCount = await db.delete(
        'bookmarks',
        where: 'disease_id = ?',
        whereArgs: [-1],
      );
      expect(deletedCount, 0);
    });
  });
}
