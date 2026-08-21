/// Local, offline profile used to separate saved diagnoses between people
/// sharing the same device.
class Profile {
  final int id;
  final String name;
  final bool isDefault;
  final String createdAt;
  final String updatedAt;

  const Profile({
    required this.id,
    required this.name,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
        id: map['id'] as int,
        name: map['name'] as String,
        isDefault: (map['is_default'] as int? ?? 0) == 1,
        createdAt: (map['created_at'] as String?) ?? '',
        updatedAt: (map['updated_at'] as String?) ?? '',
      );
}
