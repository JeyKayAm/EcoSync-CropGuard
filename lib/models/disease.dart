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
      };
}
