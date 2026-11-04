import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/domain/models/location_context_config.dart';
import 'package:memex/ui/settings/widgets/location_context_settings_page.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pumpLocationSettingsPage(
    WidgetTester tester, {
    String language = 'en',
    LocationContextConfig config = const LocationContextConfig(),
    CurrentLocationContextLoader? loadCurrentContext,
    LocationPermissionRequester? requestLocationPermission,
    LocationSettingsOpener? openAppSettings,
    LocationSettingsOpener? openLocationSettings,
  }) async {
    SharedPreferences.setMockInitialValues({
      'language': language,
      'location_context_config': jsonEncode(config.toJson()),
    });
    await UserStorage.initL10n();

    await tester.pumpWidget(
      MaterialApp(
        home: LocationContextSettingsPage(
          loadCurrentContext: loadCurrentContext,
          requestLocationPermission: requestLocationPermission,
          openAppSettings: openAppSettings,
          openLocationSettings: openLocationSettings,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> scrollToTestButton(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('Test current location'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpPageFromLauncher(
    WidgetTester tester, {
    LocationContextConfig config = const LocationContextConfig(),
  }) async {
    SharedPreferences.setMockInitialValues({
      'language': 'en',
      'location_context_config': jsonEncode(config.toJson()),
    });
    await UserStorage.initL10n();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LocationContextSettingsPage(),
                    ),
                  );
                },
                child: const Text('Open settings'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
  }

  testWidgets('updates location context settings from the page', (
    WidgetTester tester,
  ) async {
    await pumpLocationSettingsPage(
      tester,
      config: const LocationContextConfig(
        enabled: false,
        provider: GeocodingProvider.openStreetMap,
        granularity: LocationContextGranularity.neighborhood,
        ttlMinutes: 15,
      ),
    );

    expect(find.text('Location Context'), findsOneWidget);
    expect(find.text('Attach current location to chat'), findsOneWidget);
    expect(find.text('OpenStreetMap / Nominatim'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    var config = await UserStorage.getLocationContextConfig();
    expect(config.enabled, isFalse);
    expect(find.text('Save'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    config = await UserStorage.getLocationContextConfig();
    expect(config.enabled, isTrue);
    expect(find.text('Saved'), findsOneWidget);

    await tester.tap(find.text('Neighborhood'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Street').last);
    await tester.pumpAndSettle();

    config = await UserStorage.getLocationContextConfig();
    expect(config.granularity, LocationContextGranularity.neighborhood);

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    config = await UserStorage.getLocationContextConfig();
    expect(config.granularity, LocationContextGranularity.street);

    await tester.scrollUntilVisible(
      find.text('Location freshness'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('15 minutes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('30 minutes').last);
    await tester.pumpAndSettle();

    config = await UserStorage.getLocationContextConfig();
    expect(config.ttlMinutes, 15);

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    config = await UserStorage.getLocationContextConfig();
    expect(config.ttlMinutes, 30);
  });

  testWidgets('complex edits stay draft until explicit save', (
    WidgetTester tester,
  ) async {
    const savedConfig = LocationContextConfig(
      enabled: true,
      provider: GeocodingProvider.openStreetMap,
      granularity: LocationContextGranularity.city,
      ttlMinutes: 5,
    );
    await pumpLocationSettingsPage(
      tester,
      config: savedConfig,
      loadCurrentContext: ({bool forceRefresh = false}) async {
        return CurrentLocationContext(
          status: 'fresh',
          source: 'device_gps',
          updatedAt: DateTime.utc(2026, 5, 15, 10),
          granularity: LocationContextGranularity.city,
          reason: 'mock unsaved settings check',
        );
      },
    );

    await tester.tap(find.text('City'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Full address candidate').last);
    await tester.pumpAndSettle();

    var config = await UserStorage.getLocationContextConfig();
    expect(config.provider, GeocodingProvider.openStreetMap);
    expect(config.granularity, LocationContextGranularity.city);
    expect(find.text('Save'), findsOneWidget);

    await scrollToTestButton(tester);
    await tester.tap(find.text('Test current location'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Provider: OpenStreetMap / Nominatim'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Reason: mock unsaved settings check'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    config = await UserStorage.getLocationContextConfig();
    expect(config.provider, GeocodingProvider.openStreetMap);
    expect(config.granularity, LocationContextGranularity.full);
    expect(find.text('Saved'), findsOneWidget);
  });

  testWidgets('unsaved changes can be canceled or discarded on back', (
    WidgetTester tester,
  ) async {
    await pumpPageFromLauncher(
      tester,
      config: const LocationContextConfig(
        enabled: false,
        provider: GeocodingProvider.openStreetMap,
      ),
    );

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(find.text('Save'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Leave this page?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Location Context'), findsOneWidget);

    var config = await UserStorage.getLocationContextConfig();
    expect(config.enabled, isFalse);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.text('Open settings'), findsOneWidget);
    config = await UserStorage.getLocationContextConfig();
    expect(config.enabled, isFalse);
  });

  testWidgets('renders localized Portuguese labels',
      (WidgetTester tester) async {
    await pumpLocationSettingsPage(tester, language: 'pt');

    expect(find.text('Contexto de localização'), findsOneWidget);
    expect(find.text('Anexar localização atual ao chat'), findsOneWidget);
    expect(find.text(UserStorage.l10n.reverseGeocodingProvider), findsOneWidget);
    expect(find.text(UserStorage.l10n.contextGranularity), findsOneWidget);
    expect(find.text(UserStorage.l10n.saved), findsOneWidget);
  });

  testWidgets('enabling location context does not request permission', (
    WidgetTester tester,
  ) async {
    var requestCount = 0;
    await pumpLocationSettingsPage(
      tester,
      requestLocationPermission: () async {
        requestCount += 1;
      },
    );

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(find.text('Save'), findsOneWidget);
    expect(requestCount, 0);
  });

  testWidgets('test button displays a fresh reverse-geocoded location', (
    WidgetTester tester,
  ) async {
    var receivedForceRefresh = false;
    final now = DateTime.utc(2026, 5, 15, 10);
    await pumpLocationSettingsPage(
      tester,
      config: const LocationContextConfig(
        granularity: LocationContextGranularity.neighborhood,
      ),
      loadCurrentContext: ({bool forceRefresh = false}) async {
        receivedForceRefresh = forceRefresh;
        return CurrentLocationContext(
          status: 'fresh',
          latitude: 31.230416,
          longitude: 121.473701,
          accuracyMeters: 8.5,
          source: 'device_gps + reverse_geocode',
          updatedAt: now,
          granularity: LocationContextGranularity.neighborhood,
          address: GeocodedAddress(
            city: 'Shanghai',
            district: 'Huangpu',
            neighborhood: 'People Square',
            street: 'Xizang Middle Road',
            fullAddress: 'People Square, Huangpu, Shanghai',
            provider: 'osm',
            updatedAt: now,
            confidence: 'high',
          ),
        );
      },
    );

    await scrollToTestButton(tester);
    await tester.tap(find.text('Test current location'));
    await tester.pumpAndSettle();

    expect(receivedForceRefresh, isTrue);
    expect(find.text('Current location is ready'), findsOneWidget);
    expect(find.textContaining('Updated: 2026-05-15'), findsOneWidget);
    expect(find.textContaining('GPS: fresh'), findsOneWidget);
    expect(find.textContaining('Reverse geocode: OK'), findsOneWidget);
    expect(find.textContaining('Agent context: injected'), findsOneWidget);
    expect(
      find.text('Address summary: Shanghai · Huangpu · People Square'),
      findsOneWidget,
    );
    expect(
      find.textContaining('People Square, Huangpu, Shanghai'),
      findsOneWidget,
    );
    expect(find.textContaining('31.230416, 121.473701'), findsOneWidget);
  });

  testWidgets('test button displays unavailable status without crashing', (
    WidgetTester tester,
  ) async {
    await pumpLocationSettingsPage(
      tester,
      loadCurrentContext: ({bool forceRefresh = false}) async {
        return CurrentLocationContext(
          status: 'unavailable',
          source: 'device_gps',
          updatedAt: DateTime.utc(2026, 5, 15, 10),
          granularity: LocationContextGranularity.neighborhood,
          reason: 'location permission denied',
        );
      },
    );

    await scrollToTestButton(tester);
    await tester.tap(find.text('Test current location'));
    await tester.pumpAndSettle();

    expect(find.textContaining('GPS: unavailable'), findsOneWidget);
    expect(find.text('Location permission is needed'), findsOneWidget);
    expect(find.text('Allow location permission'), findsOneWidget);
    expect(find.textContaining('Reverse geocode: unavailable'), findsOneWidget);
    expect(
      find.textContaining('Reason: location permission denied'),
      findsOneWidget,
    );
  });

  testWidgets('permission guidance can request permission and retest', (
    WidgetTester tester,
  ) async {
    var requestCount = 0;
    var loadCount = 0;
    await pumpLocationSettingsPage(
      tester,
      loadCurrentContext: ({bool forceRefresh = false}) async {
        loadCount += 1;
        if (loadCount == 1) {
          return CurrentLocationContext(
            status: 'unavailable',
            source: 'device_gps',
            updatedAt: DateTime.utc(2026, 5, 15, 10),
            granularity: LocationContextGranularity.neighborhood,
            reason: 'location permission denied',
          );
        }
        return CurrentLocationContext(
          status: 'fresh',
          latitude: 31.230416,
          longitude: 121.473701,
          accuracyMeters: 8.5,
          source: 'device_gps + reverse_geocode',
          updatedAt: DateTime.utc(2026, 5, 15, 10),
          granularity: LocationContextGranularity.neighborhood,
          address: GeocodedAddress(
            city: 'Shanghai',
            district: 'Huangpu',
            neighborhood: 'People Square',
            provider: 'osm',
            updatedAt: DateTime.utc(2026, 5, 15, 10),
            confidence: 'high',
          ),
        );
      },
      requestLocationPermission: () async {
        requestCount += 1;
      },
    );

    await scrollToTestButton(tester);
    await tester.tap(find.text('Test current location'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Allow location permission'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Allow location permission'));
    await tester.pumpAndSettle();

    expect(requestCount, 1);
    expect(loadCount, 2);
    expect(find.text('Current location is ready'), findsOneWidget);
  });

  testWidgets('service disabled guidance opens location settings', (
    WidgetTester tester,
  ) async {
    var opened = false;
    await pumpLocationSettingsPage(
      tester,
      loadCurrentContext: ({bool forceRefresh = false}) async {
        return CurrentLocationContext(
          status: 'unavailable',
          source: 'device_gps',
          updatedAt: DateTime.utc(2026, 5, 15, 10),
          granularity: LocationContextGranularity.neighborhood,
          reason: 'location service is disabled',
        );
      },
      openLocationSettings: () async {
        opened = true;
        return true;
      },
    );

    await scrollToTestButton(tester);
    await tester.tap(find.text('Test current location'));
    await tester.pumpAndSettle();

    expect(find.text('System location is off'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Open location settings'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open location settings'));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
  });

  testWidgets('blocked and approximate states point to app settings', (
    WidgetTester tester,
  ) async {
    var appSettingsOpenCount = 0;
    await pumpLocationSettingsPage(
      tester,
      loadCurrentContext: ({bool forceRefresh = false}) async {
        return CurrentLocationContext(
          status: 'unavailable',
          source: 'device_gps',
          updatedAt: DateTime.utc(2026, 5, 15, 10),
          granularity: LocationContextGranularity.neighborhood,
          reason: 'location permission permanently denied',
        );
      },
      openAppSettings: () async {
        appSettingsOpenCount += 1;
        return true;
      },
    );

    await scrollToTestButton(tester);
    await tester.tap(find.text('Test current location'));
    await tester.pumpAndSettle();

    expect(find.text('Location permission is blocked'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Open app settings'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open app settings'));
    await tester.pumpAndSettle();
    expect(appSettingsOpenCount, 1);

    await pumpLocationSettingsPage(
      tester,
      loadCurrentContext: ({bool forceRefresh = false}) async {
        return CurrentLocationContext(
          status: 'fresh',
          latitude: 31.230416,
          longitude: 121.473701,
          accuracyMeters: 1200,
          source: 'device_gps + reverse_geocode',
          updatedAt: DateTime.utc(2026, 5, 15, 10),
          granularity: LocationContextGranularity.city,
          address: GeocodedAddress(
            city: 'Shanghai',
            provider: 'osm',
            updatedAt: DateTime.utc(2026, 5, 15, 10),
            confidence: 'low',
          ),
        );
      },
      openAppSettings: () async {
        appSettingsOpenCount += 1;
        return true;
      },
    );

    await scrollToTestButton(tester);
    await tester.tap(find.text('Test current location'));
    await tester.pumpAndSettle();

    expect(find.text('Approximate location only'), findsOneWidget);
    expect(find.text('Open app settings'), findsOneWidget);
  });

  testWidgets('test button explains GPS-only reverse geocode failure', (
    WidgetTester tester,
  ) async {
    await pumpLocationSettingsPage(
      tester,
      config: const LocationContextConfig(
        enabled: true,
        provider: GeocodingProvider.openStreetMap,
        granularity: LocationContextGranularity.neighborhood,
      ),
      loadCurrentContext: ({bool forceRefresh = false}) async {
        return CurrentLocationContext(
          status: 'fresh',
          latitude: 31.230416,
          longitude: 121.473701,
          accuracyMeters: 8.5,
          source: 'device_gps',
          updatedAt: DateTime.utc(2026, 5, 15, 10),
          granularity: LocationContextGranularity.neighborhood,
          reason: 'reverse geocode unavailable (osm): no address',
        );
      },
    );

    await scrollToTestButton(tester);
    await tester.tap(find.text('Test current location'));
    await tester.pumpAndSettle();

    expect(find.textContaining('GPS: fresh'), findsOneWidget);
    expect(find.textContaining('Provider: OpenStreetMap / Nominatim'), findsOneWidget);
    expect(find.textContaining('Reverse geocode: unavailable'), findsOneWidget);
    expect(find.textContaining('Agent context: not injected'), findsOneWidget);
    expect(
      find.textContaining('Coordinates: 31.230416, 121.473701'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Reason: reverse geocode unavailable (osm)'),
      findsOneWidget,
    );
  });

  testWidgets('test button displays a localized failure message', (
    WidgetTester tester,
  ) async {
    await pumpLocationSettingsPage(
      tester,
      loadCurrentContext: ({bool forceRefresh = false}) async {
        throw StateError('mock location failure');
      },
    );

    await scrollToTestButton(tester);
    await tester.tap(find.text('Test current location'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Failed: Bad state: mock location failure'),
      findsOneWidget,
    );
  });
}
