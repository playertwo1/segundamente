import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:memex/ui/core/themes/app_colors.dart';

/// Model for a location on the map
class MapLocation {
  final LatLng point;
  final String? name;

  const MapLocation({
    required this.point,
    this.name,
  });
}

class MapCard extends StatelessWidget {
  final String? title;
  final String? infoTitle;
  final String? infoDetail;
  final String? insight;
  final List<MapLocation> locations;
  final bool isDetail;

  MapCard({
    super.key,
    this.title,
    this.infoTitle,
    this.infoDetail,
    this.insight,
    this.locations = const [],
    this.isDetail = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTitle = title ?? UserStorage.l10n.footprintMap;
    if (isDetail) {
      return _buildDetailCard(context, effectiveTitle);
    }
    return _buildListCard(context, effectiveTitle);
  }

  Widget _buildListCard(BuildContext context, String effectiveTitle) {
    // Filter invalid locations
    final validLocations = locations.where((loc) {
      // Basic range check for Lat/Lng
      return loc.point.latitude.isFinite &&
          loc.point.longitude.isFinite &&
          loc.point.latitude.abs() <= 90 &&
          loc.point.longitude.abs() <= 180;
    }).toList();

    if (validLocations.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            UserStorage.l10n.insightMapNoData,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    // Use WGS-84 coordinates directly (OSM tiles use WGS-84)
    final initialCenter = validLocations.first.point;

    // Conditional info panel: show if at least one info field is present
    final showInfo = (infoTitle != null && infoTitle!.isNotEmpty) ||
        (infoDetail != null && infoDetail!.isNotEmpty);

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          IgnorePointer(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: 11,
                // Disable interaction in list view to prevent conflict with scrolling
                // Only use bounds fit if we have multiple points to avoid infinite zoom on single point
                initialCameraFit: validLocations.length > 1
                    ? CameraFit.bounds(
                        bounds: LatLngBounds.fromPoints(
                            validLocations.map((e) => e.point).toList()),
                        padding: const EdgeInsets.all(50),
                      )
                    : null,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.memexlab.memex',
                ),
                MarkerLayer(
                  markers: validLocations
                      .map((location) => Marker(
                            point: location.point,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on_outlined,
                              color: AppColors.textPrimary,
                              size: 40,
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          // Title overlay
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.map_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      effectiveTitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom info card
          if (showInfo)
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (infoTitle != null && infoTitle!.isNotEmpty)
                            Text(
                              infoTitle!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          if (infoTitle != null &&
                              infoTitle!.isNotEmpty &&
                              infoDetail != null &&
                              infoDetail!.isNotEmpty)
                            const SizedBox(height: 1),
                          if (infoDetail != null && infoDetail!.isNotEmpty)
                            Text(
                              infoDetail!,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textTertiary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context, String effectiveTitle) {
    // Filter invalid locations
    final validLocations = locations.where((loc) {
      return loc.point.latitude.isFinite &&
          loc.point.longitude.isFinite &&
          loc.point.latitude.abs() <= 90 &&
          loc.point.longitude.abs() <= 180;
    }).toList();

    if (validLocations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          UserStorage.l10n.insightMapNoData,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    // Use WGS-84 coordinates directly (OSM tiles use WGS-84)
    final initialCenter = validLocations.first.point;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rich Info Section
        if (infoTitle != null || infoDetail != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(color: AppColors.surface),
                  child: const Icon(
                    Icons.map_outlined,
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (infoTitle != null)
                        Text(
                          infoTitle!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (infoDetail != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          infoDetail!,
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Expanded Map View
        Container(
          height: 240, // Reduced height for details as requested
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.divider),
          ),
          clipBehavior: Clip.antiAlias,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 11,
              // Enable full interaction in detail view
              // Only use bounds fit if we have multiple points to avoid infinite zoom on single point
              initialCameraFit: validLocations.length > 1
                  ? CameraFit.bounds(
                      bounds: LatLngBounds.fromPoints(
                          validLocations.map((e) => e.point).toList()),
                      padding: const EdgeInsets.all(50),
                    )
                  : null,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.memexlab.memex',
              ),
              MarkerLayer(
                markers: validLocations
                    .map((location) => Marker(
                          point: location.point,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.textPrimary,
                            size: 40,
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),

        // Coordinate List
        if (validLocations.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            UserStorage.l10n.waypointPlaces,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...validLocations.asMap().entries.map((entry) {
            final index = entry.key;
            final location = entry.value;
            final name = location.name ?? UserStorage.l10n.unknownPlace;

            return Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration:
                        const BoxDecoration(color: AppColors.background),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ],
    );
  }
}
