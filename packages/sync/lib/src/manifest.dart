/// Describes the database copy a desktop offers to the phone.
class Manifest {
  const Manifest({
    required this.databaseId,
    required this.schemaVersion,
    required this.size,
    required this.sha256,
    required this.createdAt,
  });

  final String databaseId;
  final int schemaVersion;
  final int size;
  final String sha256;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'databaseId': databaseId,
    'schemaVersion': schemaVersion,
    'size': size,
    'sha256': sha256,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  static Manifest fromJson(Map<String, Object?> json) => Manifest(
    databaseId: json['databaseId'] as String,
    schemaVersion: json['schemaVersion'] as int,
    size: json['size'] as int,
    sha256: json['sha256'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
  );
}
