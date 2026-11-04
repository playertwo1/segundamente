import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:memex/llm_client/codex_responses_client.dart'
    show configureProxy;
import 'package:memex/utils/secret_storage.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'local_server_service.dart';

const _clientId = '9d1c250a-e61b-44d9-88ed-5944d1962f5e';
const _authorizeUrl = 'https://claude.com/cai/oauth/authorize';
const _tokenUrl = 'https://platform.claude.com/v1/oauth/token';
const _redirectUri = 'http://localhost:1455/callback';
const _scopes =
    'org:create_api_key user:profile user:inference user:sessions:claude_code user:mcp_servers user:file_upload';

class ClaudeAuthService {
  static final Logger _logger = Logger('ClaudeAuthService');

  static String _generateRandomString(int length) {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  static String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  static Future<void> startAuthFlow({
    required void Function() onStart,
    required void Function(String accountLabel) onSuccess,
    required void Function(String error) onError,
  }) async {
    try {
      onStart();

      final state = _generateRandomString(32);
      final codeVerifier = _generateRandomString(64);
      final codeChallenge = _generateCodeChallenge(codeVerifier);

      final authUrl = Uri.parse(_authorizeUrl).replace(
        queryParameters: {
          'code': 'true',
          'client_id': _clientId,
          'response_type': 'code',
          'redirect_uri': _redirectUri,
          'scope': _scopes,
          'code_challenge': codeChallenge,
          'code_challenge_method': 'S256',
          'state': state,
        },
      );

      final completer = Completer<Map<String, String>?>();
      await LocalServerService.start();

      LocalServerService.setAuthCallback((Uri uri) {
        if (uri.path == '/cancel') {
          if (!completer.isCompleted) completer.complete(null);
          return 'Flow cancelled. You can close this window.';
        }
        if (uri.path != '/callback' && uri.path != '/auth/callback') {
          return null;
        }

        if (uri.queryParameters.containsKey('error')) {
          if (!completer.isCompleted) {
            completer.completeError(
              uri.queryParameters['error_description'] ??
                  uri.queryParameters['error'] ??
                  'Unknown error',
            );
          }
          return 'Authorization failed. You can close this window.';
        }

        final rawCode = uri.queryParameters['code'];
        final cleanCode = rawCode?.split('#').first;
        final receivedState = uri.queryParameters['state'] ??
            (rawCode != null && rawCode.contains('#')
                ? rawCode.split('#').last
                : null);

        if (receivedState != null && receivedState != state) {
          if (!completer.isCompleted) {
            completer.completeError('Invalid state received from callback');
          }
          return 'Invalid state. Please try again.';
        }

        if (cleanCode != null && cleanCode.isNotEmpty) {
          if (!completer.isCompleted) {
            completer.complete({'code': cleanCode});
          }
          final l10n = UserStorage.l10n;
          final title = l10n.oauthSuccessTitle;
          final msg = l10n.oauthSuccessMessage;
          return '''
            <!DOCTYPE html>
            <html>
              <head>
                <meta charset="utf-8" />
                <meta name="viewport" content="width=device-width, initial-scale=1" />
                <title>$title</title>
                <style>
                  body {
                    margin: 0;
                    height: 100vh;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    background: #0f172a;
                    color: #f8fafc;
                  }
                  .card {
                    background: #1e293b;
                    border-radius: 20px;
                    padding: 32px 24px;
                    box-shadow: 0 20px 40px rgba(0,0,0,0.4);
                    max-width: 320px;
                    text-align: center;
                    border: 1px solid rgba(255,255,255,0.1);
                  }
                  .icon { font-size: 44px; margin-bottom: 12px; }
                  h2 { margin: 0 0 8px; font-size: 20px; color: #f8fafc; }
                  p { margin: 6px 0 20px; font-size: 14px; color: #94a3b8; line-height: 1.4; }
                  .btn {
                    display: inline-block;
                    background: #d97706;
                    color: #ffffff;
                    font-weight: 600;
                    padding: 12px 20px;
                    border-radius: 12px;
                    text-decoration: none;
                    font-size: 15px;
                  }
                </style>
              </head>
              <body>
                <div class="card">
                  <div class="icon">✅</div>
                  <h2>$title</h2>
                  <p>$msg</p>
                  <a class="btn" href="memex://">Voltar ao Segunda Mente</a>
                </div>
              </body>
            </html>
          ''';
        }

        if (!completer.isCompleted) {
          completer.completeError('No code found in callback');
        }
        return oauthMissingCodePage();
      });

      if (!await launchUrl(authUrl, mode: LaunchMode.inAppBrowserView)) {
        throw Exception(UserStorage.l10n.oauthCouldNotLaunchBrowser);
      }

      final result = await completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () =>
            throw TimeoutException(UserStorage.l10n.authorizationTimedOut),
      );

      LocalServerService.clearAuthCallback();
      try {
        await closeInAppWebView();
      } catch (_) {}

      if (result == null) {
        onError(UserStorage.l10n.authorizationCancelled);
        return;
      }

      final code = result['code']!;
      _logger.info('Exchanging Claude OAuth code for tokens...');
      final tokenResponse = await http.post(
        Uri.parse(_tokenUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': _redirectUri,
          'client_id': _clientId,
          'code_verifier': codeVerifier,
          'state': state,
        }),
      );

      if (tokenResponse.statusCode != 200) {
        _logger.severe(
            'Claude token exchange failed: ${tokenResponse.statusCode}');
        throw Exception('Failed to get token: ${tokenResponse.statusCode}');
      }

      final data = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
      final accessToken = data['access_token'] as String?;
      final refreshToken = data['refresh_token'] as String?;
      final expiresIn = (data['expires_in'] as num?)?.toInt() ?? 3600;
      final expiresAt =
          DateTime.now().millisecondsSinceEpoch + expiresIn * 1000;

      if (accessToken == null || refreshToken == null) {
        throw Exception('Missing tokens in response');
      }

      final account = data['account'] as Map<String, dynamic>?;
      final email = (account?['email_address'] as String?) ??
          (account?['uuid'] as String?) ??
          'Claude Account';

      await _saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        email: email,
        expiresAt: expiresAt,
      );

      onSuccess(email);
    } catch (e) {
      try {
        await closeInAppWebView();
      } catch (_) {}
      LocalServerService.clearAuthCallback();
      _logger.severe('Claude OAuth error: $e');
      onError(e.toString());
    }
  }

  static Future<void> _saveTokens({
    required String accessToken,
    required String refreshToken,
    required String email,
    required int expiresAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await SecretStorage.write('claude_access_token', accessToken);
    await SecretStorage.write('claude_refresh_token', refreshToken);
    await prefs.setString('claude_email', email);
    await prefs.setInt('claude_expires_at', expiresAt);
  }

  static Future<Map<String, dynamic>?> getSavedTokens() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken =
        await SecretStorage.readMigrating(prefs, 'claude_access_token');
    final refreshToken =
        await SecretStorage.readMigrating(prefs, 'claude_refresh_token');
    final email = prefs.getString('claude_email');
    final expiresAt = prefs.getInt('claude_expires_at');

    if (accessToken == null || refreshToken == null) return null;

    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'email': email ?? '',
      'expiresAt': expiresAt,
    };
  }

  static Future<String?> getValidAccessToken() async {
    final tokens = await getSavedTokens();
    if (tokens == null) return null;

    final expiresAt = tokens['expiresAt'] as int?;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (expiresAt != null && expiresAt > now + 60000) {
      return tokens['accessToken'] as String;
    }

    return await _refreshAccessToken(tokens['refreshToken'] as String);
  }

  static Future<String?> _refreshAccessToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse(_tokenUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': _clientId,
          'scope': _scopes,
        }),
      );

      if (response.statusCode != 200) {
        _logger.warning('Claude token refresh failed: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final newAccessToken = data['access_token'] as String?;
      final expiresIn = (data['expires_in'] as num?)?.toInt() ?? 3600;
      final expiresAt =
          DateTime.now().millisecondsSinceEpoch + expiresIn * 1000;

      if (newAccessToken == null) return null;

      final prefs = await SharedPreferences.getInstance();
      await SecretStorage.write('claude_access_token', newAccessToken);
      await prefs.setInt('claude_expires_at', expiresAt);
      if (data['refresh_token'] != null) {
        await SecretStorage.write(
          'claude_refresh_token',
          data['refresh_token'] as String,
        );
      }

      return newAccessToken;
    } catch (e) {
      _logger.severe('Failed to refresh Claude token: $e');
      return null;
    }
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('claude_access_token');
    await prefs.remove('claude_refresh_token');
    await SecretStorage.delete('claude_access_token');
    await SecretStorage.delete('claude_refresh_token');
    await prefs.remove('claude_email');
    await prefs.remove('claude_expires_at');
  }

  /// Creates a [Dio] client that injects Claude OAuth Bearer + beta headers
  /// into standard `ClaudeClient` requests.
  static Dio createOAuthDio(String? proxyUrl) {
    final dio = Dio();
    configureProxy(dio, proxyUrl);
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getValidAccessToken();
          if (token == null) {
            return handler.reject(
              DioException(
                requestOptions: options,
                error: 'Claude OAuth not authorized.',
              ),
            );
          }
          options.headers.remove('x-api-key');
          options.headers.remove('X-Api-Key');
          options.headers['Authorization'] = 'Bearer $token';
          options.headers['anthropic-beta'] =
              'claude-code-20250219,oauth-2025-04-20,interleaved-thinking-2025-05-14';
          options.headers['User-Agent'] = 'claude-cli/2.1.296 (external, cli)';
          final promptId = DateTime.now().millisecondsSinceEpoch.toString();
          options.headers['x-anthropic-billing-header'] =
              'cc_version=2.1.296.406; cc_entrypoint=sdk-cli; cch=00000; cc_prompt_id=$promptId; cc_turn_origin=sdk; cc_prompt_index=0; cc_turn_index=1;';

          if (options.data is Map) {
            final dataMap = options.data as Map;
            if (dataMap['model'] is String) {
              var m = dataMap['model'] as String;
              m = m.replaceAll('-5.5', '-5-5').replaceAll('-4.5', '-4-5');
              dataMap['model'] = m;
            }
          }

          return handler.next(options);
        },
      ),
    );
    return dio;
  }
}
