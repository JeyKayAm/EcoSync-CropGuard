import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Pure-Dart 64-bit average-hash (aHash): resize to 8x8 grayscale, threshold
/// each pixel against the mean brightness, pack the bits into an int. Must
/// stay algorithmically in sync with `scripts/generate_phashes.py`'s
/// `average_hash`, which precomputes the same hash for every reference
/// photo at DB-build time — this is what lets [PhotoMatchService] compare a
/// freshly captured photo against those precomputed hashes with a single
/// cheap Hamming-distance calculation instead of decoding reference images
/// on-device.
///
/// This is a coarse visual-similarity signal, not object recognition — it's
/// fooled by things like different framing/lighting/background. That
/// limitation is intentional and surfaced to the user rather than hidden;
/// see [kPhotoLookupDisclaimer].
int computeAverageHash(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('Could not decode photo for hashing');
  }
  final small = img.copyResize(
    decoded,
    width: 8,
    height: 8,
    interpolation: img.Interpolation.average,
  );
  final gray = img.grayscale(small);

  final pixels = <int>[];
  for (var y = 0; y < 8; y++) {
    for (var x = 0; x < 8; x++) {
      pixels.add(gray.getPixel(x, y).r.toInt());
    }
  }
  final mean = pixels.reduce((a, b) => a + b) / pixels.length;

  var hash = 0;
  for (final p in pixels) {
    hash = (hash << 1) | (p >= mean ? 1 : 0);
  }
  return hash;
}

/// Number of differing bits between two 64-bit hashes — lower means more
/// visually similar. Range 0 (identical) to 64 (inverted).
///
/// Iterates a fixed 64 times using the unsigned right shift (`>>>`) rather
/// than looping `while (x != 0) x >>= 1`: hashes with the top bit set are
/// negative in Dart's two's-complement `int`, and the ordinary `>>`
/// operator sign-extends, so that loop never terminates once `x` reaches
/// `-1`.
int hammingDistance(int a, int b) {
  final x = a ^ b;
  var count = 0;
  for (var i = 0; i < 64; i++) {
    count += (x >>> i) & 1;
  }
  return count;
}

/// Converts a Hamming distance (0–64) to a 0.0–1.0 similarity score.
double similarityFromDistance(int distance) => 1 - (distance / 64);
