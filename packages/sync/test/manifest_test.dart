import 'package:sync/sync.dart';
import 'package:test/test.dart';

void main() {
  test('JSON round trip keeps all fields', () {
    final m = Manifest(
      databaseId: 'db-1',
      schemaVersion: 10,
      size: 12345,
      sha256: 'ab' * 32,
      createdAt: DateTime.utc(2026, 11, 8, 12, 30, 5),
    );
    final json = m.toJson();
    expect(json['createdAt'], '2026-11-08T12:30:05.000Z');
    final back = Manifest.fromJson(json);
    expect(back.databaseId, 'db-1');
    expect(back.schemaVersion, 10);
    expect(back.size, 12345);
    expect(back.sha256, 'ab' * 32);
    expect(back.createdAt, DateTime.utc(2026, 11, 8, 12, 30, 5));
    expect(back.createdAt.isUtc, isTrue);
  });
  test('local date is serialized as UTC', () {
    final m = Manifest(
      databaseId: 'd',
      schemaVersion: 1,
      size: 1,
      sha256: 'ab' * 32,
      createdAt: DateTime(2026, 1, 1, 8),
    );
    expect((m.toJson()['createdAt'] as String).endsWith('Z'), isTrue);
  });
  test('bad fields throw FormatException', () {
    final good = Manifest(
      databaseId: 'd',
      schemaVersion: 1,
      size: 1,
      sha256: 'ab' * 32,
      createdAt: DateTime.utc(2026),
    ).toJson();
    expect(() => Manifest.fromJson({...good, 'size': -1}), throwsFormatException);
    expect(() => Manifest.fromJson({...good, 'sha256': 'XYZ'}), throwsFormatException);
    expect(() => Manifest.fromJson({...good, 'size': 'a'}), throwsFormatException);
    expect(() => Manifest.fromJson({...good, 'createdAt': 'nope'}), throwsFormatException);
    expect(() => Manifest.fromJson({}), throwsFormatException);
  });
}
