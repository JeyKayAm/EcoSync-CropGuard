/// A crop disease record, mirroring the `diseases` table. [imagePaths] is
/// stored in SQLite as a single comma-joined column (`image_paths`), so
/// [fromMap] splits it back into a list here rather than using a join table.
/// [imagePhashes] mirrors it 1:1 — the perceptual hash (see
/// `lib/utils/phash.dart`) of each image at the same index, precomputed by
/// `scripts/generate_phashes.py` so [PhotoMatchService] never has to decode
/// the reference images at runtime.
class Disease {
  final int id;
  final int cropId;
  final String name;
  final String pathogen;        // Causal organism
  final String plantPart;       // leaf | stem | root | cob | whole
  final String severity;        // Low | Medium | High
  final String description;
  final String prevention;
  final List<String> imagePaths;
  final List<int> imagePhashes;

  const Disease({
    required this.id,
    required this.cropId,
    required this.name,
    required this.pathogen,
    required this.plantPart,
    required this.severity,
    required this.description,
    required this.prevention,
    required this.imagePaths,
    this.imagePhashes = const [],
  });

  factory Disease.fromMap(Map<String, dynamic> map) => Disease(
        id: map['id'] as int,
        cropId: map['crop_id'] as int,
        name: map['name'] as String,
        pathogen: map['pathogen'] as String,
        plantPart: map['plant_part'] as String,
        severity: map['severity'] as String,
        description: map['description'] as String,
        prevention: map['prevention'] as String,
        imagePaths: (map['image_paths'] as String)
            .split(',')
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)
            .toList(),
        imagePhashes: ((map['image_phashes'] as String?) ?? '')
            .split(',')
            .map((h) => h.trim())
            .where((h) => h.isNotEmpty)
            // A 64-bit hash can have its top bit set, which overflows
            // int.parse's signed range — go through BigInt to get the
            // correct two's-complement bit pattern instead.
            .map((h) => BigInt.parse(h, radix: 16).toSigned(64).toInt())
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'crop_id': cropId,
        'name': name,
        'pathogen': pathogen,
        'plant_part': plantPart,
        'severity': severity,
        'description': description,
        'prevention': prevention,
        'image_paths': imagePaths.join(','),
        'image_phashes': imagePhashes
            .map((h) => BigInt.from(h)
                .toUnsigned(64)
                .toRadixString(16)
                .padLeft(16, '0'))
            .join(','),
      };
}
