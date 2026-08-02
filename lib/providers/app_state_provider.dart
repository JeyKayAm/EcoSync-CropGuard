import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bookmark.dart';
import '../models/crop.dart';
import '../services/bookmark_service.dart';
import '../services/database_helper.dart';
import '../utils/constants.dart';

class AppStateProvider extends ChangeNotifier {
  static const _themeSeedPrefKey = 'theme_seed_argb';

  final BookmarkService _bookmarkService = BookmarkService();

  List<Crop> _crops = [];
  List<Bookmark> _bookmarks = [];
  bool _loading = true;
  Color _themeSeed = kPrimaryGreen;

  List<Crop> get crops => _crops;
  List<Bookmark> get bookmarks => _bookmarks;
  bool get loading => _loading;
  Color get themeSeed => _themeSeed;

  /// Called once at app startup to pre-load crops, bookmarks and the
  /// user's saved theme colour.
  Future<void> init() async {
    final db = DatabaseHelper.instance;
    final rows = await db.query('crops', orderBy: 'name ASC');
    _crops = rows.map((r) => Crop.fromMap(r)).toList();
    _bookmarks = await _bookmarkService.getAll();

    final prefs = await SharedPreferences.getInstance();
    final savedArgb = prefs.getInt(_themeSeedPrefKey);
    if (savedArgb != null) _themeSeed = Color(savedArgb);

    _loading = false;
    notifyListeners();
  }

  Future<void> setThemeSeed(Color color) async {
    _themeSeed = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeSeedPrefKey, color.toARGB32());
  }

  bool isBookmarked(int diseaseId) =>
      _bookmarks.any((b) => b.diseaseId == diseaseId);

  Future<void> toggleBookmark({
    required int diseaseId,
    required String diseaseName,
    required String cropName,
  }) async {
    if (isBookmarked(diseaseId)) {
      await _bookmarkService.remove(diseaseId);
      _bookmarks.removeWhere((b) => b.diseaseId == diseaseId);
    } else {
      final bookmark = Bookmark(
        diseaseId: diseaseId,
        diseaseName: diseaseName,
        cropName: cropName,
        savedAt: DateTime.now().toIso8601String(),
      );
      await _bookmarkService.add(bookmark);
      _bookmarks.insert(0, bookmark);
    }
    notifyListeners();
  }

  Future<void> refreshBookmarks() async {
    _bookmarks = await _bookmarkService.getAll();
    notifyListeners();
  }
}
