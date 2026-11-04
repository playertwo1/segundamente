import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:memex/domain/models/location_context_config.dart';
import 'package:memex/utils/logger.dart';
import 'package:memex/utils/user_storage.dart';

class GeocodingService {
  static final GeocodingService instance = GeocodingService._internal();
  GeocodingService._internal();

  static const int _maxCacheEntries = 100;
  static const int _maxTransientAttempts = 1;
  static const List<Duration> _transientRetryDelays = <Duration>[];
  final _logger = getLogger('GeocodingService');
  final Map<String, GeocodedAddress> _memoryCache = {};

  Future<GeocodedAddress?> reverseGeocode(
    double latitude,
    double longitude, {
    LocationContextConfig? config,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final result = await reverseGeocodeWithStatus(
      latitude,
      longitude,
      config: config,
      timeout: timeout,
    );
    return result.address;
  }

  Future<ReverseGeocodeResult> reverseGeocodeWithStatus(
    double latitude,
    double longitude, {
    LocationContextConfig? config,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final effectiveConfig =
        config ?? await UserStorage.getLocationContextConfig();
    final provider = effectiveConfig.provider;
    final cacheKey = _cacheKey(provider, latitude, longitude);

    final cached =
        _memoryCache[cacheKey] ?? await _readPersistentCache(cacheKey);
    if (cached != null) {
      return ReverseGeocodeResult(
        address: cached,
        provider: provider,
        status: 'cached',
      );
    }

    final result = await _reverseProviderWithTransientRetry(
      provider: provider,
      latitude: latitude,
      longitude: longitude,
      timeout: timeout,
    );
    final address = result.address;

    if (address != null) {
      _memoryCache[cacheKey] = address;
      await _writePersistentCache(cacheKey, address);
      return ReverseGeocodeResult(
        address: address,
        provider: provider,
        status: 'fresh',
      );
    }

    return ReverseGeocodeResult(
      address: null,
      provider: provider,
      status: 'unavailable',
      reason: result.reason ?? 'reverse geocoding returned no address',
    );
  }

  Future<ReverseGeocodeResult> _reverseProviderWithTransientRetry({
    required GeocodingProvider provider,
    required double latitude,
    required double longitude,
    required Duration timeout,
  }) async {
    late ReverseGeocodeResult result;
    for (var attempt = 1; attempt <= _maxTransientAttempts; attempt++) {
      switch (provider) {
        case GeocodingProvider.openStreetMap:
          result = await _reverseWithOpenStreetMap(
            latitude,
            longitude,
            timeout,
          );
          break;
      }

      if (result.isSuccess ||
          !_shouldRetryTransientFailure(result) ||
          attempt == _maxTransientAttempts) {
        return result;
      }

      final delay = _retryDelay(attempt);
      _logger.info(
        'Retrying ${provider.name} reverse geocode after transient failure '
        '(attempt $attempt/$_maxTransientAttempts): ${result.reason}',
      );
      await Future<void>.delayed(delay);
    }
    return result;
  }

  Duration _retryDelay(int attempt) {
    if (attempt <= _transientRetryDelays.length) {
      return _transientRetryDelays[attempt - 1];
    }
    return _transientRetryDelays.last;
  }

  bool _shouldRetryTransientFailure(ReverseGeocodeResult result) {
    if (result.isSuccess) return false;
    final reason = result.reason?.toLowerCase() ?? '';
    if (reason.isEmpty) return false;
    if (reason.contains('api key') ||
        reason.contains('invalid_user_key') ||
        reason.contains('invalid user key')) {
      return false;
    }

    final statusMatch = RegExp(r'failed: (\d{3})').firstMatch(reason);
    final statusCode = int.tryParse(statusMatch?.group(1) ?? '');
    if (statusCode != null) {
      return statusCode == 429 || statusCode >= 500;
    }

    return reason.contains('timeout') ||
        reason.contains('socketexception') ||
        reason.contains('clientexception') ||
        reason.contains('connection') ||
        reason.contains('failed host lookup') ||
        reason.contains('network') ||
        reason.contains('temporar') ||
        reason.contains('unknown_error') ||
        reason.contains('service_not_available') ||
        reason.contains('engine_response_data_error');
  }

  Future<ReverseGeocodeResult> _reverseWithOpenStreetMap(
    double latitude,
    double longitude,
    Duration timeout,
  ) async {
    try {
      final uri =
          Uri.parse('https://nominatim.openstreetmap.org/reverse').replace(
        queryParameters: {
          'lat': latitude.toString(),
          'lon': longitude.toString(),
          'format': 'json',
          'accept-language': UserStorage.localeNotifier.value.languageCode,
          'addressdetails': '1',
        },
      );

      final response = await http
          .get(uri, headers: {'User-Agent': 'memex_app'}).timeout(timeout);

      if (response.statusCode != 200) {
        final reason = 'OSM reverse geocode failed: ${response.statusCode}';
        _logger.warning(reason);
        return ReverseGeocodeResult(
          address: null,
          provider: GeocodingProvider.openStreetMap,
          status: 'unavailable',
          reason: reason,
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final address = data['address'] is Map
          ? Map<String, dynamic>.from(data['address'] as Map)
          : <String, dynamic>{};

      String? pick(List<String> keys) {
        for (final key in keys) {
          final value = address[key];
          if (value is String && value.trim().isNotEmpty) {
            return value.trim();
          }
        }
        return null;
      }

      final city = pick(['city', 'town', 'village', 'municipality']);
      final county = pick(['county']);

      return ReverseGeocodeResult(
        address: GeocodedAddress(
          country: pick(['country']),
          province: pick(['state', 'province', 'region']),
          city: city ?? county,
          district: pick([
            'city_district',
            'district',
            'county',
            'borough',
            'suburb',
          ]),
          neighborhood: pick(['neighbourhood', 'quarter', 'residential']),
          street: pick(['road', 'pedestrian', 'footway']),
          fullAddress: _stringOrNull(data['display_name']),
          provider: 'open_street_map',
          updatedAt: DateTime.now(),
          confidence: 'medium',
        ),
        provider: GeocodingProvider.openStreetMap,
        status: 'fresh',
      );
    } catch (e) {
      final reason = 'OSM reverse geocode error: $e';
      _logger.warning(reason);
      return ReverseGeocodeResult(
        address: null,
        provider: GeocodingProvider.openStreetMap,
        status: 'unavailable',
        reason: reason,
      );
    }
  }

  String? _stringOrNull(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is String && first.trim().isNotEmpty) {
        return first.trim();
      }
    }
    return null;
  }

  String _cacheKey(
    GeocodingProvider provider,
    double latitude,
    double longitude,
  ) {
    return '${provider.name}:${latitude.toStringAsFixed(5)},${longitude.toStringAsFixed(5)}';
  }

  Future<GeocodedAddress?> _readPersistentCache(String key) async {
    final cache = await UserStorage.getGeocodingCache();
    final raw = cache[key];
    if (raw is! Map) return null;
    try {
      final address = GeocodedAddress.fromJson(Map<String, dynamic>.from(raw));
      _memoryCache[key] = address;
      return address;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writePersistentCache(
    String key,
    GeocodedAddress address,
  ) async {
    final cache = await UserStorage.getGeocodingCache();
    cache[key] = {
      ...address.toJson(),
      '_cachedAt': DateTime.now().millisecondsSinceEpoch,
    };

    if (cache.length > _maxCacheEntries) {
      final keys = cache.keys.toList();
      keys.sort((a, b) {
        final itemA = cache[a];
        final itemB = cache[b];
        final tsA = itemA is Map ? itemA['_cachedAt'] as int? ?? 0 : 0;
        final tsB = itemB is Map ? itemB['_cachedAt'] as int? ?? 0 : 0;
        return tsA.compareTo(tsB);
      });
      while (cache.length > _maxCacheEntries && keys.isNotEmpty) {
        cache.remove(keys.removeAt(0));
      }
    }

    await UserStorage.saveGeocodingCache(cache);
  }
}
