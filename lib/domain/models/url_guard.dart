import 'dart:io';

/// Why a link may not be previewed; null from [refusalFor] means it may.
enum UrlRefusal {
  notHttp,
  noHost,
  hasCredentials,
  localName,
  privateAddress,
}

const _localSuffixes = ['.local', '.localdomain', '.internal', '.lan', '.home'];

/// Checks the address text itself, before any network call: only http and
/// https, a host, no user:password, no local names, no private IP literals.
UrlRefusal? refusalFor(Uri uri) {
  if (uri.scheme != 'http' && uri.scheme != 'https') return UrlRefusal.notHttp;
  final host = uri.host.toLowerCase();
  if (host.isEmpty) return UrlRefusal.noHost;
  if (uri.userInfo.isNotEmpty) return UrlRefusal.hasCredentials;
  if (host == 'localhost' ||
      host.endsWith('.localhost') ||
      !host.contains('.') && InternetAddress.tryParse(host) == null) {
    return UrlRefusal.localName;
  }
  if (_localSuffixes.any(host.endsWith)) return UrlRefusal.localName;
  final literal = InternetAddress.tryParse(host);
  if (literal != null && isPrivateAddress(literal)) {
    return UrlRefusal.privateAddress;
  }
  return null;
}

/// True for loopback, private, link-local, carrier-grade NAT, unspecified,
/// multicast, reserved and unique-local addresses, and for IPv6 addresses
/// that wrap one of those IPv4 ranges.
bool isPrivateAddress(InternetAddress address) {
  final bytes = address.rawAddress;
  if (address.type == InternetAddressType.IPv4) return _privateV4(bytes);
  if (bytes.length != 16) return true;
  final allZero = bytes.every((b) => b == 0);
  final loopback = bytes.sublist(0, 15).every((b) => b == 0) && bytes[15] == 1;
  if (allZero || loopback) return true;
  if (bytes[0] == 0xfc || bytes[0] == 0xfd) return true; // unique local
  if (bytes[0] == 0xfe && (bytes[1] & 0xc0) == 0x80) return true; // link-local
  if (bytes[0] == 0xff) return true; // multicast
  final first10Zero = bytes.sublist(0, 10).every((b) => b == 0);
  // ::ffff:a.b.c.d (mapped) and ::a.b.c.d (compatible) wrap an IPv4 address.
  if (first10Zero && bytes[10] == 0xff && bytes[11] == 0xff) {
    return _privateV4(bytes.sublist(12));
  }
  if (bytes.sublist(0, 12).every((b) => b == 0)) {
    return _privateV4(bytes.sublist(12));
  }
  // 64:ff9b::/96 (NAT64) wraps an IPv4 address too.
  if (bytes[0] == 0x00 &&
      bytes[1] == 0x64 &&
      bytes[2] == 0xff &&
      bytes[3] == 0x9b &&
      bytes.sublist(4, 12).every((b) => b == 0)) {
    return _privateV4(bytes.sublist(12));
  }
  return false;
}

bool _privateV4(List<int> b) {
  final a = b[0];
  final c = b[1];
  if (a == 0 || a == 10 || a == 127) return true;
  if (a == 169 && c == 254) return true;
  if (a == 172 && c >= 16 && c <= 31) return true;
  if (a == 192 && c == 168) return true;
  if (a == 100 && c >= 64 && c <= 127) return true; // carrier-grade NAT
  if (a == 192 && c == 0 && b[2] == 0) return true; // IETF protocol block
  if (a == 198 && (c == 18 || c == 19)) return true; // benchmarking
  if (a >= 224) return true; // multicast and reserved
  return false;
}
