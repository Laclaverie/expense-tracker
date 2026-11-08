// The phone pairing (one row): a database id and a 32-byte secret.
import 'package:drift/native.dart';
import 'package:storage/storage.dart';
import 'package:test/test.dart';

void main() {
  late ExpenseDatabase db;
  late PairingStore store;

  setUp(() {
    db = ExpenseDatabase(NativeDatabase.memory());
    store = PairingStore(db);
  });
  tearDown(() => db.close());

  test('pairNew makes a 32-byte secret and a uuid; a second pairNew replaces it', () async {
    expect(await store.current(), isNull);
    final first = await store.pairNew();
    expect(first.secret, hasLength(32));
    expect(first.databaseId, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
    expect(await store.current(), first);

    final second = await store.pairNew();
    expect(second.databaseId, isNot(first.databaseId));
    expect(second.secret, isNot(first.secret));
    expect(await db.select(db.pairedPhones).get(), hasLength(1));
    expect((await store.current())!.databaseId, second.databaseId);
  });

  test('forget removes the pairing', () async {
    await store.pairNew();
    await store.forget();
    expect(await store.current(), isNull);
  });

  test('recordSync stores hash and time', () async {
    await store.pairNew();
    final at = DateTime.utc(2026, 11, 8, 10);
    await store.recordSync('abc123', at);
    final row = (await store.current())!;
    expect(row.lastSyncHash, 'abc123');
    expect(row.lastSyncAt, at);
  });
}
