import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bookmark.dart';
import '../models/crop.dart';
import '../models/profile.dart';
import '../services/bookmark_service.dart';
import '../services/database_helper.dart';
import '../services/profile_service.dart';
import '../utils/constants.dart';

/// App-wide state: the crop list, bookmarks, loading flag, and the user's
/// chosen theme colour — the single source of truth widgets subscribe to
/// via [Provider]/[Consumer] rather than each screen querying the DB itself.
class AppStateProvider extends ChangeNotifier {
  static const _themeSeedPrefKey = 'theme_seed_argb';
  static const _activeProfilePrefKey = 'active_profile_id';

  final BookmarkService _bookmarkService = BookmarkService();
  final ProfileService _profileService = ProfileService();

  List<Crop> _crops = [];
  List<Bookmark> _bookmarks = [];
  List<Profile> _profiles = [];
  bool _loading = true;
  Color _themeSeed = kPrimaryGreen;
  int _activeProfileId = 1;
  String _activeProfileName = ProfileService.defaultProfileName;

  List<Crop> get crops => _crops;
  List<Bookmark> get bookmarks => _bookmarks;
  List<Profile> get profiles => _profiles;
  bool get loading => _loading;
  Color get themeSeed => _themeSeed;
  int get activeProfileId => _activeProfileId;
  String get activeProfileName => _activeProfileName;

  /// Called once at app startup to pre-load crops, bookmarks and the
  /// user's saved theme colour.
  Future<void> init() async {
    final db = DatabaseHelper.instance;
    final rows = await db.query('crops', orderBy: 'name ASC');
    _crops = rows.map((r) => Crop.fromMap(r)).toList();

    final prefs = await SharedPreferences.getInstance();
    final savedArgb = prefs.getInt(_themeSeedPrefKey);
    if (savedArgb != null) _themeSeed = Color(savedArgb);

    final defaultProfile = await _profileService.ensureDefaultProfile();
    _profiles = await _profileService.getAll();

    final savedProfileId = prefs.getInt(_activeProfilePrefKey);
    final activeExists = savedProfileId != null &&
        _profiles.any((profile) => profile.id == savedProfileId);
    _activeProfileId = activeExists ? savedProfileId : defaultProfile.id;
    await prefs.setInt(_activeProfilePrefKey, _activeProfileId);

    _activeProfileName =
        _profiles.firstWhere((p) => p.id == _activeProfileId).name;
    _bookmarks = await _bookmarkService.getAll(profileId: _activeProfileId);

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
      await _bookmarkService.remove(
        profileId: _activeProfileId,
        diseaseId: diseaseId,
      );
      _bookmarks.removeWhere((b) => b.diseaseId == diseaseId);
    } else {
      final bookmark = Bookmark(
        profileId: _activeProfileId,
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
    _bookmarks = await _bookmarkService.getAll(profileId: _activeProfileId);
    notifyListeners();
  }

  Future<void> refreshProfiles() async {
    _profiles = await _profileService.getAll();
    _activeProfileName =
        _profiles.firstWhere((p) => p.id == _activeProfileId).name;
    notifyListeners();
  }

  Future<void> switchProfile(int profileId) async {
    if (_activeProfileId == profileId) return;
    _activeProfileId = profileId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_activeProfilePrefKey, _activeProfileId);
    _activeProfileName = _profiles.firstWhere((p) => p.id == profileId).name;
    _bookmarks = await _bookmarkService.getAll(profileId: _activeProfileId);
    notifyListeners();
  }

  Future<String?> createProfile(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Profile name cannot be empty.';
    final exists = _profiles.any(
      (profile) => profile.name.toLowerCase() == trimmed.toLowerCase(),
    );
    if (exists) return 'A profile with this name already exists.';

    final created = await _profileService.create(trimmed);
    _profiles = await _profileService.getAll();
    await switchProfile(created.id);
    return null;
  }

  Future<String?> renameProfile({
    required int profileId,
    required String newName,
  }) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return 'Profile name cannot be empty.';
    final conflict = _profiles.any(
      (profile) =>
          profile.id != profileId &&
          profile.name.toLowerCase() == trimmed.toLowerCase(),
    );
    if (conflict) return 'A profile with this name already exists.';

    await _profileService.rename(profileId: profileId, newName: trimmed);
    _profiles = await _profileService.getAll();
    if (_activeProfileId == profileId) {
      _activeProfileName =
          _profiles.firstWhere((profile) => profile.id == profileId).name;
    }
    notifyListeners();
    return null;
  }

  Future<String?> deleteProfile(int profileId) async {
    final profile = _profiles.firstWhere((p) => p.id == profileId);
    if (profile.isDefault) {
      return 'The shared default profile cannot be deleted.';
    }
    if (_profiles.length <= 1) {
      return 'At least one profile must remain.';
    }

    await _profileService.delete(profileId);
    _profiles = await _profileService.getAll();

    if (_activeProfileId == profileId) {
      final fallback = _profiles.firstWhere((p) => p.isDefault,
          orElse: () => _profiles.first);
      await switchProfile(fallback.id);
    } else {
      await refreshBookmarks();
    }

    notifyListeners();
    return null;
  }

  Future<void> resetToSharedProfile() async {
    final shared = _profiles.firstWhere((p) => p.isDefault,
        orElse: () => _profiles.first);
    await switchProfile(shared.id);
    notifyListeners();
  }
}
