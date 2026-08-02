class Bookmark {
  final int? id; // nullable — null before first insert
  final int diseaseId;
  final String diseaseName;
  final String cropName;
  final String savedAt; // ISO 8601 string

  const Bookmark({
    this.id,
    required this.diseaseId,
    required this.diseaseName,
    required this.cropName,
    required this.savedAt,
  });

  factory Bookmark.fromMap(Map<String, dynamic> map) => Bookmark(
        id: map['id'] as int?,
        diseaseId: map['disease_id'] as int,
        diseaseName: map['disease_name'] as String,
        cropName: map['crop_name'] as String,
        savedAt: map['saved_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'disease_id': diseaseId,
        'disease_name': diseaseName,
        'crop_name': cropName,
        'saved_at': savedAt,
      };
}
