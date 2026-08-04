// Unit tests (Section 3.7.1): BookmarkService CRUD behaviour — add, look up
// by disease (not bookmark id), list ordering, and remove — plus the edge
// case of checking/removing a disease that was never bookmarked.
import 'package:flutter_test/flutter_test.dart';
import 'package:ecosync_cropguard/models/bookmark.dart';
import 'package:ecosync_cropguard/services/bookmark_service.dart';
import 'package:ecosync_cropguard/services/database_helper.dart';

import '../support/db_test_setup.dart';

void main() {
  setUpAll(initTestDatabaseEnvironment);

  final svc = BookmarkService();

  tearDown(() async {
    // Bookmarks are test-local state; leave the table as we found it.
    final db = DatabaseHelper.instance;
    await db.delete('bookmarks', where: '1 = ?', whereArgs: [1]);
  });

  test('edge case: isBookmarked is false for a disease never bookmarked',
      () async {
    expect(await svc.isBookmarked(1), isFalse);
  });

  test('add() persists a bookmark that isBookmarked() and getAll() can see',
      () async {
    await svc.add(const Bookmark(
      diseaseId: 1,
      diseaseName: 'Grey Leaf Spot',
      cropName: 'Maize',
      savedAt: '2026-01-01T00:00:00.000',
    ));

    expect(await svc.isBookmarked(1), isTrue);
    final all = await svc.getAll();
    expect(all, hasLength(1));
    expect(all.first.diseaseName, 'Grey Leaf Spot');
  });

  test('getAll() orders most-recently-saved first', () async {
    await svc.add(const Bookmark(
      diseaseId: 1,
      diseaseName: 'Grey Leaf Spot',
      cropName: 'Maize',
      savedAt: '2026-01-01T00:00:00.000',
    ));
    await svc.add(const Bookmark(
      diseaseId: 2,
      diseaseName: 'Northern Corn Leaf Blight',
      cropName: 'Maize',
      savedAt: '2026-01-02T00:00:00.000',
    ));

    final all = await svc.getAll();
    expect(all.map((b) => b.diseaseId).toList(), [2, 1]);
  });

  test('remove() deletes by disease id, not bookmark id', () async {
    await svc.add(const Bookmark(
      diseaseId: 1,
      diseaseName: 'Grey Leaf Spot',
      cropName: 'Maize',
      savedAt: '2026-01-01T00:00:00.000',
    ));

    await svc.remove(1);

    expect(await svc.isBookmarked(1), isFalse);
    expect(await svc.getAll(), isEmpty);
  });

  test('edge case: remove() on a disease that was never bookmarked is a no-op',
      () async {
    await svc.remove(1);
    expect(await svc.getAll(), isEmpty);
  });
}
