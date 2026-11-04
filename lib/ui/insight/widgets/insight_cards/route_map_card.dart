import 'package:memex/ui/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:memex/utils/user_storage.dart';
import 'map_card.dart'; // For MapLocation

class RouteMapCard extends StatelessWidget {
  final String title;
  final List<MapLocation> locations;
  final bool isDetail;
  final String? insight;

  const RouteMapCard({
    super.key,
    required this.title,
    required this.locations,
    this.isDetail = false,
    this.insight,
  });

  @override
  Widget build(BuildContext context) {
    if (locations.isEmpty) {
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
    if (isDetail) {
      return _buildDetailCard(context);
    }
    return _buildListCard(context);
  }

  Widget _buildDetailCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Detailed Route View
        _buildContent(context, height: 300), // Taller for detail view
      ],
    );
  }

  Widget _buildListCard(BuildContext context) {
    return _buildContent(context, height: 240);
  }

  Widget _buildContent(BuildContext context, {required double height}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        border: const Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.near_me_outlined,
                color: AppColors.textSecondary,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: AppColors.divider,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Route Visualization
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border.all(color: AppColors.divider),
              ),
              child: CustomPaint(
                painter: _RoutePainter(locations),
                size: Size.infinite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  final List<MapLocation> locations;

  _RoutePainter(this.locations);

  @override
  void paint(Canvas canvas, Size size) {
    if (locations.isEmpty) return;

    final paint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.fill;

    final whitePaint = Paint()
      ..color = AppColors.background
      ..style = PaintingStyle.fill;

    final latitudes = locations.map((location) => location.point.latitude);
    final longitudes = locations.map((location) => location.point.longitude);
    final minLatitude = latitudes.reduce((a, b) => a < b ? a : b);
    final maxLatitude = latitudes.reduce((a, b) => a > b ? a : b);
    final minLongitude = longitudes.reduce((a, b) => a < b ? a : b);
    final maxLongitude = longitudes.reduce((a, b) => a > b ? a : b);
    const padding = 24.0;
    final mapWidth =
        (size.width - padding * 2).clamp(0.0, double.infinity).toDouble();
    final mapHeight =
        (size.height - padding * 2).clamp(0.0, double.infinity).toDouble();
    final latitudeRange = maxLatitude - minLatitude;
    final longitudeRange = maxLongitude - minLongitude;
    final points = locations.map((location) {
      final x = longitudeRange == 0
          ? size.width / 2
          : padding +
              (location.point.longitude - minLongitude) /
                  longitudeRange *
                  mapWidth;
      final y = latitudeRange == 0
          ? size.height / 2
          : padding +
              (maxLatitude - location.point.latitude) /
                  latitudeRange *
                  mapHeight;
      return Offset(x, y);
    }).toList();

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    _drawDashedPath(canvas, path, paint);

    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      canvas.drawCircle(point, index == points.length - 1 ? 7 : 6, dotPaint);
      if (index == 0) canvas.drawCircle(point, 3, whitePaint);
    }
    _drawLabel(
      canvas,
      locations.first.name ?? UserStorage.l10n.startPoint,
      points.first,
    );
    if (locations.length > 1) {
      _drawBubbleLabel(
        canvas,
        locations.last.name ?? UserStorage.l10n.endPoint,
        points.last,
      );
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 6.0;
    const dashSpace = 6.0;
    double distance = 0.0;

    final pathMetrics = path.computeMetrics();
    for (var metric in pathMetrics) {
      while (distance < metric.length) {
        final extractPath = metric.extractPath(
          distance,
          distance + dashWidth,
        );
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset offset) {
    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final x = offset.dx - (textPainter.width / 2);
    final y = offset.dy + 12; // Below the dot

    // Draw background pill
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
          x - 8, y - 4, textPainter.width + 16, textPainter.height + 8),
      const Radius.circular(12),
    );

    final bgPaint = Paint()..color = AppColors.surface;
    canvas.drawRRect(bgRect, bgPaint);

    textPainter.paint(canvas, Offset(x, y));
  }

  void _drawBubbleLabel(Canvas canvas, String text, Offset offset) {
    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Position: Top Left relative to the point?
    // Image shows it to the left of the point

    final x = offset.dx - textPainter.width - 24;
    final y = offset.dy - 12;

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y - 6, textPainter.width + 24, textPainter.height + 12),
      const Radius.circular(8),
    );

    final bgPaint = Paint()..color = AppColors.surface;

    canvas.drawRRect(bgRect, bgPaint);

    // Draw little arrow
    final path = Path();
    path.moveTo(bgRect.right - 4,
        bgRect.bottom - 4); // Start near bottom right of bubble
    path.lineTo(
        bgRect.right + 4, bgRect.bottom + 4); // Point towards the connect node
    path.lineTo(bgRect.right - 8, bgRect.bottom + 4);
    path.close();
    // Simplified arrow just separate triangle?

    textPainter.paint(canvas, Offset(x + 12, y));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
