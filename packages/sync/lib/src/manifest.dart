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

  static Manifest fromJson(Map<String, Object?> json) {
    try {
      final size = json['size'] as int;
      final sha = json['sha256'] as String;
      if (size < 0) throw const FormatException('Bad size');
      if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(sha)) throw const FormatException('Bad sha256');
      return Manifest(
        databaseId: json['databaseId'] as String,
        schemaVersion: json['schemaVersion'] as int,
        size: size,
        sha256: sha,
        createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      );
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException('Bad manifest: $e');
    }
  }
}
