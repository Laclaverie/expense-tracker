import 'dart:io';

import 'package:sync/sync.dart';
import 'package:test/test.dart';

void main() {
  test('lanAddresses skips loopback and link-local', () {
    final addresses = [
      InternetAddress('127.0.0.1'),
      InternetAddress('169.254.3.4'),
      InternetAddress('192.168.1.20'),
      InternetAddress('10.0.0.5'),
      InternetAddress('::1'),
    ];
    expect(privateIPv4(addresses), ['192.168.1.20', '10.0.0.5']);
  });
  test('public and 172.16/12 ranges', () {
    expect(privateIPv4([InternetAddress('8.8.8.8'), InternetAddress('172.20.1.1'), InternetAddress('172.32.0.1')]), [
      '172.20.1.1',
    ]);
  });
}
