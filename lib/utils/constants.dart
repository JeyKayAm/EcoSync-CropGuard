import 'package:flutter/material.dart';

/// Shared, static values referenced across screens/widgets: brand colours,
/// the fixed plant-part list/ordering used by diagnosis and filtering, theme
/// options for Settings, and the standing decision-support disclaimer text.

// ─── App Identity ──────────────────────────────────────────────
const String kAppName = 'EcoSync-CropGuard';
const String kAppVersion = '1.0.0';

// ─── Colour Palette ────────────────────────────────────────────
const Color kPrimaryGreen    = Color(0xFF2E7D32); // Deep agricultural green
const Color kAccentGreen     = Color(0xFF66BB6A); // Light leaf green
const Color kSoilBrown       = Color(0xFF5D4037); // Earthy brown
const Color kWarningAmber    = Color(0xFFFFB300); // Medium severity
const Color kDangerRed       = Color(0xFFC62828); // High severity
const Color kLowGreen        = Color(0xFF388E3C); // Low severity
const Color kSurface         = Color(0xFFF1F8E9); // Light green-tinted surface
const Color kOnPrimary       = Colors.white;

// ─── Plant Parts ───────────────────────────────────────────────
const List<Map<String, String>> kPlantParts = [
  {'value': 'leaf',  'label': 'Leaf',       'icon': '🍃'},
  {'value': 'stem',  'label': 'Stem',       'icon': '🌿'},
  {'value': 'root',  'label': 'Root',       'icon': '🌱'},
  {'value': 'cob',   'label': 'Cob / Head', 'icon': '🌽'},
  {'value': 'whole', 'label': 'Whole Plant','icon': '🪴'},
];

// ─── Severity ─────────────────────────────────────────────────
Color severityColor(String severity) {
  return switch (severity) {
    'High'   => kDangerRed,
    'Medium' => kWarningAmber,
    _        => kLowGreen,
  };
}

// ─── Theme colour options (Settings screen) ───────────────────
// The seed the user picks re-derives the whole Material 3 colour scheme
// (app bars, buttons, selection highlights). Severity colours above are
// semantic (High/Medium/Low) and intentionally do NOT change with this.
const List<Map<String, dynamic>> kThemeSeedOptions = [
  {'label': 'Green (default)', 'color': kPrimaryGreen},
  {'label': 'Earth Brown', 'color': kSoilBrown},
  {'label': 'Harvest Red', 'color': Color(0xFFC62828)},
  {'label': 'Sky Blue', 'color': Color(0xFF1565C0)},
];

// ─── Disclaimer ───────────────────────────────────────────────
const String kDisclaimer =
    'This app is a decision-support tool. Where a diagnosis is uncertain, '
    'consult your AGRITEX extension officer before applying treatments.';

// Photo Lookup compares a photo against a small set of reference images
// using visual-similarity matching (not a trained model) — see
// PhotoMatchService. Shown both as a low-confidence banner on the results
// screen and as a standing note in Settings.
const String kPhotoLookupDisclaimer =
    'Photo Lookup is experimental. It compares your photo against a small '
    'reference set (a few images per disease, and not every disease has '
    'one yet) using visual similarity — it does not "recognise" diseases '
    'the way a trained expert would. It works best when your photo closely '
    'resembles one of our reference photos (similar framing, lighting and '
    'close-up angle); a typical field photo of a real disease often won\'t '
    'score as a confident match even when correct, so a "no confident '
    'match" result does not mean the disease isn\'t present. Always treat '
    'results as a starting point, not a diagnosis, and consult your '
    'AGRITEX extension officer when unsure.';
