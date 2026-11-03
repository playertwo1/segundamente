import 'dart:io';
import 'package:logging/logging.dart';
import 'package:memex/utils/user_storage.dart';

String oauthMissingCodePage() => UserStorage.l10n.unknownError;

class LocalServerService {
  static final Logger _logger = Logger('LocalServerService');
  static HttpServer? _server;
  static String? Function(Uri)? _authCallback;

  /// Server on 8085 for Gemini OAuth (redirect_uri must match Google's registered client).
  static HttpServer? _server8085;
  static String? Function(Uri)? _geminiAuthCallback;

  static void setAuthCallback(String? Function(Uri) callback) {
    _authCallback = callback;
  }

  static void clearAuthCallback() {
    _authCallback = null;
  }

  static void setGeminiAuthCallback(String? Function(Uri) callback) {
    _geminiAuthCallback = callback;
  }

  static void clearGeminiAuthCallback() {
    _geminiAuthCallback = null;
  }

  /// Dispatches an OAuth callback URI received via HTTP or Android Intent.
  static bool handleCallbackUri(Uri uri) {
    if (uri.path == '/oauth2callback' || uri.port == 8085) {
      if (_geminiAuthCallback != null) {
        _geminiAuthCallback!(uri);
        return true;
      }
    }
    if (uri.path == '/auth/callback' ||
        uri.path == '/callback' ||
        uri.path == '/cancel' ||
        uri.port == 1455) {
      if (_authCallback != null) {
        _authCallback!(uri);
        return true;
      }
    }
    return false;
  }

  static Future<HttpServer> _bindLoopback(int port) async {
    return await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      port,
    );
  }

  static Future<void> start() async {
    if (_server != null) return;
    try {
      _server = await _bindLoopback(1455);
      _logger.info('Local server running on localhost:1455');

      _server!.listen((HttpRequest request) {
        final uri = request.uri;
        _logger.info('Local server received request: ${uri.path}');

        if (_authCallback != null) {
          final htmlResponse = _authCallback!(uri);
          if (htmlResponse != null) {
            request.response
              ..statusCode = HttpStatus.ok
              ..headers.contentType = ContentType.html
              ..write(htmlResponse)
              ..close();
            return;
          }
        }

        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.text
          ..write('hello world')
          ..close();
      });
    } catch (e) {
      _logger.severe('Failed to start local server: $e');
    }
  }

  /// Ensures the server on port 8085 is running (for Gemini OAuth redirect_uri).
  static Future<void> ensureGeminiPort() async {
    if (_server8085 != null) return;
    try {
      _server8085 = await _bindLoopback(8085);
      _logger.info('Local server (Gemini OAuth) running on localhost:8085');

      _server8085!.listen((HttpRequest request) {
        final uri = request.uri;
        _logger.info('Local server 8085 received request: ${uri.path}');

        if (_geminiAuthCallback != null) {
          final htmlResponse = _geminiAuthCallback!(uri);
          if (htmlResponse != null) {
            request.response
              ..statusCode = HttpStatus.ok
              ..headers.contentType = ContentType.html
              ..write(htmlResponse)
              ..close();
            return;
          }
        }

        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.text
          ..write('OK')
          ..close();
      });
    } catch (e) {
      _logger.severe('Failed to start local server on 8085: $e');
      rethrow;
    }
  }

  static Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    await _server8085?.close(force: true);
    _server8085 = null;
  }
}
