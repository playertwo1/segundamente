import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memex/domain/models/url_guard.dart';

void main() {
  UrlRefusal? check(String url) => refusalFor(Uri.parse(url));

  test('public http and https addresses pass', () {
    expect(check('https://example.com/a?b=1'), isNull);
    expect(check('http://sub.example.org:8080/'), isNull);
    expect(check('https://93.184.216.34/'), isNull);
    expect(check('https://[2606:4700:4700::1111]/'), isNull);
  });

  test('other schemes, missing host and credentials are refused', () {
    expect(check('ftp://example.com/'), UrlRefusal.notHttp);
    expect(check('file:///etc/passwd'), UrlRefusal.notHttp);
    expect(check('javascript:alert(1)'), UrlRefusal.notHttp);
    expect(check('https:///path'), UrlRefusal.noHost);
    expect(check('https://user:pw@example.com/'), UrlRefusal.hasCredentials);
  });

  test('local names are refused', () {
    for (final url in [
      'http://localhost/',
      'http://LOCALHOST:3000/',
      'http://app.localhost/',
      'http://printer.local/',
      'http://nas.lan/',
      'http://intranet/',
      'http://service.internal/',
    ]) {
      expect(check(url), UrlRefusal.localName, reason: url);
    }
  });

  test('private IPv4 literals are refused', () {
    for (final url in [
      'http://127.0.0.1/',
      'http://127.1.2.3/',
      'http://10.0.0.5/',
      'http://172.16.0.1/',
      'http://172.31.255.255/',
      'http://192.168.1.1/',
      'http://169.254.169.254/latest/meta-data',
      'http://100.64.0.1/',
      'http://0.0.0.0/',
      'http://224.0.0.1/',
      'http://255.255.255.255/',
    ]) {
      expect(check(url), UrlRefusal.privateAddress, reason: url);
    }
    expect(check('http://172.32.0.1/'), isNull);
    expect(check('http://100.128.0.1/'), isNull);
  });

  test('private and wrapped IPv6 literals are refused', () {
    for (final url in [
      'http://[::1]/',
      'http://[::]/',
      'http://[fe80::1]/',
      'http://[fc00::1]/',
      'http://[fd12:3456::1]/',
      'http://[ff02::1]/',
      'http://[::ffff:127.0.0.1]/',
      'http://[::ffff:10.0.0.1]/',
      'http://[64:ff9b::7f00:1]/',
    ]) {
      expect(check(url), UrlRefusal.privateAddress, reason: url);
    }
  });

  test('isPrivateAddress works on resolved addresses', () {
    expect(isPrivateAddress(InternetAddress('192.168.0.9')), isTrue);
    expect(isPrivateAddress(InternetAddress('8.8.8.8')), isFalse);
    expect(isPrivateAddress(InternetAddress('::ffff:8.8.8.8')), isFalse);
  });
}
