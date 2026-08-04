/// One of the app's 5 supported crops (maize, tobacco, groundnuts, sorghum,
/// sweet potatoes). Mirrors the `crops` table seeded by `scripts/populate_db.py`.
class Crop {
  final int id;
  final String name;
  final String localName; // Shona/Ndebele common name
  final String description;
  final String imagePath;

  const Crop({
    required this.id,
    required this.name,
    required this.localName,
    required this.description,
    required this.imagePath,
  });

  factory Crop.fromMap(Map<String, dynamic> map) => Crop(
        id: map['id'] as int,
        name: map['name'] as String,
        localName: map['local_name'] as String,
        description: map['description'] as String,
        imagePath: map['image_path'] as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'local_name': localName,
        'description': description,
        'image_path': imagePath,
      };
}
