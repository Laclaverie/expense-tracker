import 'dart:io';

/// Private IPv4 addresses, without loopback and link-local (169.254.*).
List<String> privateIPv4(Iterable<InternetAddress> addresses) {
  final result = <String>[];
  for (final a in addresses) {
    if (a.type != InternetAddressType.IPv4 || a.isLoopback || a.isLinkLocal) continue;
    final b = a.rawAddress;
    final private = b[0] == 10 || (b[0] == 172 && b[1] >= 16 && b[1] <= 31) || (b[0] == 192 && b[1] == 168);
    if (private) result.add(a.address);
  }
  return result;
}

/// Private IPv4 addresses of this machine's network interfaces.
Future<List<String>> lanAddresses() async {
  final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
  return privateIPv4(interfaces.expand((i) => i.addresses));
}
