import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memex/data/services/link_preview_service.dart';

RawResponse html(String body) => RawResponse(
      status: 200,
      contentType: 'text/html; charset=utf-8',
      body: utf8.encode(body),
    );

void main() {
  final publicIp = InternetAddress('93.184.216.34');

  LinkPreviewService service(
    Map<String, RawResponse> pages, {
    Map<String, List<InternetAddress>> dns = const {},
    List<Uri>? asked,
  }) {
    return LinkPreviewService(
      resolve: (host) async => dns[host] ?? [publicIp],
      get: (uri, pinned) async {
        asked?.add(uri);
        final page = pages[uri.toString()];
        if (page == null) throw StateError('unexpected $uri');
        return page;
      },
    );
  }

  Matcher refusedWith(String reason) => throwsA(
        isA<LinkPreviewRefused>().having((e) => e.reason, 'reason', reason),
      );

  test('reads og:title and description, falling back to title', () async {
    final s = service({
      'https://a.example/': html(
        '<html><head><title>Fallback</title>'
        '<meta property="og:title" content="A &amp; B">'
        '<meta name="description" content="Resumo  da   página"></head>',
      ),
      'https://b.example/': html('<title> Só título </title>'),
    });
    final a = await s.fetch('https://a.example/');
    expect(a.title, 'A & B');
    expect(a.description, 'Resumo da página');
    expect((await s.fetch('https://b.example/')).title, 'Só título');
  });

  test('addresses that look private are refused without any request', () async {
    final asked = <Uri>[];
    final s = service({}, asked: asked);
    await expectLater(
        s.fetch('http://127.0.0.1/'), refusedWith('privateAddress'));
    await expectLater(s.fetch('http://localhost/'), refusedWith('localName'));
    await expectLater(s.fetch('file:///x'), refusedWith('notHttp'));
    expect(asked, isEmpty);
  });

  test('a name that resolves to a private address is refused', () async {
    final asked = <Uri>[];
    final s = service(
      {},
      dns: {
        'rebind.example': [publicIp, InternetAddress('10.0.0.8')],
      },
      asked: asked,
    );
    await expectLater(
      s.fetch('https://rebind.example/'),
      refusedWith('privateAddress'),
    );
    expect(asked, isEmpty);
  });

  test('a redirect to a private target is refused, a public one followed',
      () async {
    final asked = <Uri>[];
    final s = service({
      'https://short.example/ok': const RawResponse(
        status: 302,
        contentType: '',
        body: [],
        location: '/final',
      ),
      'https://short.example/final': html('<title>Chegou</title>'),
      'https://short.example/bad': const RawResponse(
        status: 301,
        contentType: '',
        body: [],
        location: 'http://192.168.0.1/admin',
      ),
    }, asked: asked);
    expect((await s.fetch('https://short.example/ok')).title, 'Chegou');
    await expectLater(
      s.fetch('https://short.example/bad'),
      refusedWith('privateAddress'),
    );
    expect(asked.map((u) => u.host), isNot(contains('192.168.0.1')));
  });

  test('redirect loops stop at the limit', () async {
    final s = service({
      'https://loop.example/': const RawResponse(
        status: 302,
        contentType: '',
        body: [],
        location: 'https://loop.example/',
      ),
    });
    await expectLater(
      s.fetch('https://loop.example/'),
      refusedWith('too many redirects'),
    );
  });

  test('non-html and error statuses are refused', () async {
    final s = service({
      'https://x.example/pdf': const RawResponse(
        status: 200,
        contentType: 'application/pdf',
        body: [1, 2],
      ),
      'https://x.example/404': const RawResponse(
        status: 404,
        contentType: 'text/html',
        body: [],
      ),
    });
    await expectLater(
        s.fetch('https://x.example/pdf'), refusedWith('not html'));
    await expectLater(
        s.fetch('https://x.example/404'), refusedWith('status 404'));
  });

  test('a page is fetched once; the second read comes from the cache',
      () async {
    final asked = <Uri>[];
    final s =
        service({'https://c.example/': html('<title>C</title>')}, asked: asked);
    await s.fetch('https://c.example/');
    await s.fetch('https://c.example/');
    expect(asked, hasLength(1));
  });

  group('pinnedGet against a local server', () {
    late HttpServer server;
    late List<HttpHeaders> seen;

    setUp(() async {
      seen = [];
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        seen.add(request.headers);
        if (request.uri.path == '/redirect') {
          request.response
            ..statusCode = 302
            ..headers.set(HttpHeaders.locationHeader, 'http://10.0.0.1/');
        } else if (request.uri.path == '/big') {
          request.response.headers.contentType = ContentType.html;
          request.response.write('x' * (linkPreviewMaxBytes * 2));
        } else {
          request.response.headers.contentType = ContentType.html;
          request.response.write('<title>Oi</title>');
        }
        await request.response.close();
      });
    });

    tearDown(() => server.close(force: true));

    test('sends no cookie, does not follow redirects, caps the body', () async {
      final base = 'http://example.test:${server.port}';
      final ok = await pinnedGet(
        Uri.parse('$base/'),
        InternetAddress.loopbackIPv4,
      );
      expect(ok.status, 200);
      expect(utf8.decode(ok.body), contains('Oi'));
      expect(seen.single.value(HttpHeaders.cookieHeader), isNull);
      expect(seen.single.value(HttpHeaders.authorizationHeader), isNull);

      final redirect = await pinnedGet(
        Uri.parse('$base/redirect'),
        InternetAddress.loopbackIPv4,
      );
      expect(redirect.status, 302);
      expect(redirect.location, 'http://10.0.0.1/');

      final big = await pinnedGet(
        Uri.parse('$base/big'),
        InternetAddress.loopbackIPv4,
      );
      expect(big.body.length, lessThanOrEqualTo(linkPreviewMaxBytes));
    });
  });

  test('pinnedGet gives up on a server that stalls after the headers',
      () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      request.response.headers.contentType = ContentType.html;
      request.response.write('<title>x</title>');
      await request.response.flush(); // then never closes
    });
    final started = DateTime.now();
    await expectLater(
      pinnedGet(
        Uri.parse('http://localhost:${server.port}/'),
        InternetAddress.loopbackIPv4,
      ),
      throwsA(anything),
    );
    expect(
      DateTime.now().difference(started),
      lessThan(linkPreviewTimeout + const Duration(seconds: 3)),
    );
  }, timeout: const Timeout(Duration(seconds: 20)));
}
