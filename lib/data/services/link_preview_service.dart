import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:memex/domain/models/url_guard.dart';

class LinkPreview {
  const LinkPreview({required this.url, this.title, this.description});

  final String url;
  final String? title;
  final String? description;
}

class LinkPreviewRefused implements Exception {
  const LinkPreviewRefused(this.reason);

  final String reason;

  @override
  String toString() => 'LinkPreviewRefused: $reason';
}

class RawResponse {
  const RawResponse({
    required this.status,
    required this.contentType,
    required this.body,
    this.location,
  });

  final int status;
  final String contentType;
  final List<int> body;
  final String? location;
}

typedef HostResolver = Future<List<InternetAddress>> Function(String host);
typedef PinnedGet = Future<RawResponse> Function(
  Uri uri,
  InternetAddress pinned,
);

const linkPreviewMaxBytes = 256 * 1024;
const linkPreviewMaxRedirects = 3;
const linkPreviewTimeout = Duration(seconds: 5);
const _cacheLimit = 100;

/// Reads the title and description of a page. Used only when the user turned
/// link previews on, because opening an address contacts that site.
///
/// Safeguards: http/https only; the address text is checked by
/// [refusalFor]; every host name is resolved here and refused when any
/// answer is private, and the connection is pinned to the vetted address (so
/// the name cannot resolve elsewhere afterwards); redirects are followed by
/// hand, at most [linkPreviewMaxRedirects], each one checked again; no
/// cookies and no user headers are sent; only HTML, at most
/// [linkPreviewMaxBytes], within [linkPreviewTimeout].
class LinkPreviewService {
  LinkPreviewService({HostResolver? resolve, PinnedGet? get})
      : _resolve = resolve ?? _systemResolve,
        _get = get ?? pinnedGet;

  static final LinkPreviewService instance = LinkPreviewService();

  final HostResolver _resolve;
  final PinnedGet _get;

  // shortcut: in-memory cache of 100 pages, lost on restart; persist it if
  // repeated fetches after a restart turn out to matter.
  final _cache = <String, LinkPreview>{};

  Future<LinkPreview> fetch(String url) async {
    final cached = _cache[url];
    if (cached != null) return cached;
    final preview = await _fetch(url).timeout(
      linkPreviewTimeout,
      onTimeout: () => throw const LinkPreviewRefused('timeout'),
    );
    if (_cache.length >= _cacheLimit) _cache.remove(_cache.keys.first);
    return _cache[url] = preview;
  }

  Future<LinkPreview> _fetch(String url) async {
    final first = Uri.tryParse(url.trim());
    if (first == null) throw const LinkPreviewRefused('bad url');
    var uri = first;
    for (var hop = 0; hop <= linkPreviewMaxRedirects; hop++) {
      final refusal = refusalFor(uri);
      if (refusal != null) throw LinkPreviewRefused(refusal.name);
      final answers = await _resolve(uri.host);
      if (answers.isEmpty || answers.any(isPrivateAddress)) {
        throw const LinkPreviewRefused('privateAddress');
      }
      final response = await _get(uri, answers.first);
      if (response.status >= 300 && response.status < 400) {
        final location = response.location;
        if (location == null) throw const LinkPreviewRefused('bad redirect');
        uri = uri.resolve(location);
        continue;
      }
      if (response.status != 200) {
        throw LinkPreviewRefused('status ${response.status}');
      }
      if (!response.contentType.toLowerCase().contains('text/html')) {
        throw const LinkPreviewRefused('not html');
      }
      return parsePreview(url, response.body);
    }
    throw const LinkPreviewRefused('too many redirects');
  }
}

Future<List<InternetAddress>> _systemResolve(String host) =>
    InternetAddress.lookup(host);

/// The real request: connects only to [pinned], sends no cookie or custom
/// header, never follows a redirect, and stops reading at the size limit.
Future<RawResponse> pinnedGet(Uri uri, InternetAddress pinned) async {
  final client = HttpClient()
    ..connectionTimeout = linkPreviewTimeout
    ..userAgent = 'Mozilla/5.0 (compatible; SegundaMente link preview)'
    ..autoUncompress = true
    ..connectionFactory = (target, proxyHost, proxyPort) =>
        Socket.startConnect(pinned, target.port);
  try {
    final request = await client.getUrl(uri);
    request.followRedirects = false;
    request.headers.set(HttpHeaders.acceptHeader, 'text/html');
    final response = await request.close();
    final body = <int>[];
    await for (final chunk in response) {
      body.addAll(chunk);
      if (body.length >= linkPreviewMaxBytes) break;
    }
    return RawResponse(
      status: response.statusCode,
      contentType: response.headers.contentType?.toString() ?? '',
      body: body.length > linkPreviewMaxBytes
          ? body.sublist(0, linkPreviewMaxBytes)
          : body,
      location: response.headers.value(HttpHeaders.locationHeader),
    );
  } finally {
    client.close(force: true);
  }
}

final _titleTag =
    RegExp(r'<title[^>]*>(.*?)</title>', caseSensitive: false, dotAll: true);
final _metaTag = RegExp(r'<meta\s+([^>]*?)/?>', caseSensitive: false);
final _attribute = RegExp(r'''([a-zA-Z:-]+)\s*=\s*(?:"([^"]*)"|'([^']*)')''');

LinkPreview parsePreview(String url, List<int> body) {
  final html = utf8.decode(body, allowMalformed: true);
  String? ogTitle;
  String? description;
  for (final match in _metaTag.allMatches(html)) {
    final attrs = {
      for (final a in _attribute.allMatches(match.group(1)!))
        a.group(1)!.toLowerCase(): a.group(2) ?? a.group(3) ?? '',
    };
    final key = (attrs['property'] ?? attrs['name'] ?? '').toLowerCase();
    final content = attrs['content'];
    if (content == null) continue;
    if (key == 'og:title') ogTitle ??= content;
    if (key == 'og:description' || key == 'description') {
      description ??= content;
    }
  }
  final title = ogTitle ?? _titleTag.firstMatch(html)?.group(1);
  return LinkPreview(
    url: url,
    title: _clean(title, 200),
    description: _clean(description, 300),
  );
}

String? _clean(String? text, int max) {
  if (text == null) return null;
  final plain = text
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (plain.isEmpty) return null;
  return plain.length <= max ? plain : '${plain.substring(0, max - 1)}…';
}
