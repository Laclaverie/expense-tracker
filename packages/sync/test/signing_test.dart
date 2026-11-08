import 'package:sync/sync.dart';
import 'package:test/test.dart';

void main() {
  final secret = List<int>.generate(32, (i) => i + 1);
  final now = DateTime.utc(2026, 11, 8, 12);

  String sign({String path = '/manifest', DateTime? at, String nonce = 'n1', List<int>? key}) =>
      signRequest(key ?? secret, 'GET', path, at: at ?? now, nonce: nonce);

  test('valid request passes', () {
    final v = RequestVerifier(secret, clock: () => now);
    expect(v.verify('GET', '/manifest', sign()), isTrue);
  });
  test('altered path fails', () {
    final v = RequestVerifier(secret, clock: () => now);
    expect(v.verify('GET', '/database', sign()), isFalse);
  });
  test('other secret fails', () {
    final v = RequestVerifier(secret, clock: () => now);
    expect(v.verify('GET', '/manifest', sign(key: List.filled(32, 9))), isFalse);
  });
  test('6-minute-old fails, 4-minute passes', () {
    final v = RequestVerifier(secret, clock: () => now);
    expect(v.verify('GET', '/manifest', sign(at: now.subtract(const Duration(minutes: 6)))), isFalse);
    expect(v.verify('GET', '/manifest', sign(at: now.subtract(const Duration(minutes: 4)), nonce: 'n2')), isTrue);
  });
  test('same header twice: second fails', () {
    final v = RequestVerifier(secret, clock: () => now);
    final h = sign();
    expect(v.verify('GET', '/manifest', h), isTrue);
    expect(v.verify('GET', '/manifest', h), isFalse);
  });
  test('nonce forgotten after 10 minutes', () {
    var t = now;
    final v = RequestVerifier(secret, clock: () => t);
    expect(v.verify('GET', '/manifest', sign(at: t)), isTrue);
    t = t.add(const Duration(minutes: 11));
    expect(v.verify('GET', '/manifest', sign(at: t)), isTrue);
  });
  test('malformed or missing header fails', () {
    final v = RequestVerifier(secret, clock: () => now);
    expect(v.verify('GET', '/manifest', null), isFalse);
    expect(v.verify('GET', '/manifest', ''), isFalse);
    expect(v.verify('GET', '/manifest', 'a.b'), isFalse);
    expect(v.verify('GET', '/manifest', 'x.n.abc'), isFalse);
  });
  test('newNonce is 32 hex chars and unique', () {
    expect(newNonce(), matches(RegExp(r'^[0-9a-f]{32}$')));
    expect(newNonce(), isNot(newNonce()));
  });
  test('body signature round trip and flipped byte', () {
    final body = List<int>.generate(100, (i) => i);
    final sig = signBody(secret, body);
    expect(verifyBody(secret, body, sig), isTrue);
    final bad = [...body]..[5] ^= 1;
    expect(verifyBody(secret, bad, sig), isFalse);
    expect(verifyBody(secret, body, null), isFalse);
    expect(verifyBody(secret, body, 'zz'), isFalse);
  });
}
