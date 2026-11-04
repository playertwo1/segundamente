import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memex/ui/core/themes/app_colors.dart';

class RadarDimension {
  final String label;
  final double value;
  final double max;

  RadarDimension({
    required this.label,
    required this.value,
    this.max = 100,
  });

  factory RadarDimension.fromJson(Map<String, dynamic> json) {
    return RadarDimension(
      label: json['label'] as String? ?? '',
      value: (json['value'] as num? ?? 0).toDouble(),
      max: (json['max'] as num? ?? 100).toDouble(),
    );
  }
}

class RadarChartCard extends StatelessWidget {
  final String title;
  final String? badge;
  final String centerValue;
  final String centerLabel;
  final List<RadarDimension> dimensions;
  final String color;
  final String? insight;
  final VoidCallback? onTap;

  const RadarChartCard({
    super.key,
    required this.title,
    this.badge,
    required this.centerValue,
    required this.centerLabel,
    this.dimensions = const [],
    this.color = '#F3EEE6',
    this.insight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            SizedBox(
              height: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        height: 20 / 14,
                        letterSpacing: -0.15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      badge!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        height: 20 / 14,
                        letterSpacing: -0.15,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Radar Chart
            if (dimensions.length >= 3)
              LayoutBuilder(
                builder: (context, constraints) {
                  final size = constraints.maxWidth;
                  return SizedBox(
                    height: size,
                    child: CustomPaint(
                      size: Size(size, size),
                      painter: _RadarPainter(
                        dimensions: dimensions,
                        tickCount: 4,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              centerValue,
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              centerLabel,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<RadarDimension> dimensions;
  final int tickCount;

  _RadarPainter({required this.dimensions, this.tickCount = 4});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.34; // chart radius (leaves room for labels)
    final n = dimensions.length;
    final angleStep = 2 * pi / n;
    // Start from top (-pi/2)
    const startAngle = -pi / 2;

    final gridPaint = Paint()
      ..color = AppColors.divider
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final axisPaint = Paint()
      ..color = AppColors.divider
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Draw grid polygons
    for (int t = 1; t <= tickCount; t++) {
      final r = radius * t / tickCount;
      final path = Path();
      for (int i = 0; i <= n; i++) {
        final angle = startAngle + angleStep * (i % n);
        final x = center.dx + r * cos(angle);
        final y = center.dy + r * sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Draw axis lines
    for (int i = 0; i < n; i++) {
      final angle = startAngle + angleStep * i;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      canvas.drawLine(center, Offset(x, y), axisPaint);
    }

    // Draw data polygon
    final dataPath = Path();
    for (int i = 0; i <= n; i++) {
      final idx = i % n;
      final d = dimensions[idx];
      final ratio = d.max > 0 ? (d.value / d.max) : 0.0;
      final r = radius * ratio;
      final angle = startAngle + angleStep * idx;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();

    // Fill
    final fillPaint = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawPath(dataPath, fillPaint);

    // Border
    final borderPaint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(dataPath, borderPaint);

    // Draw labels
    const labelStyle = TextStyle(
      fontFamily: 'Inter',
      fontSize: 11,
      fontWeight: FontWeight.w400,
      color: AppColors.textTertiary,
    );

    for (int i = 0; i < n; i++) {
      final angle = startAngle + angleStep * i;
      final labelRadius = radius + 18;
      final x = center.dx + labelRadius * cos(angle);
      final y = center.dy + labelRadius * sin(angle);

      final tp = TextPainter(
        text: TextSpan(text: dimensions[i].label, style: labelStyle),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: size.width * 0.28);

      // Position label based on angle
      double dx = x - tp.width / 2;
      double dy = y - tp.height / 2;

      // Adjust horizontal alignment for left/right labels
      final normalizedAngle = angle % (2 * pi);
      if (normalizedAngle > pi * 0.1 && normalizedAngle < pi * 0.9) {
        // Right side
        dx = x - tp.width * 0.1;
      } else if (normalizedAngle > pi * 1.1 && normalizedAngle < pi * 1.9) {
        // Left side
        dx = x - tp.width * 0.9;
      }
      // Top label: center below
      if (normalizedAngle < 0.1 || normalizedAngle > pi * 1.9) {
        dx = x - tp.width / 2;
        dy = y - tp.height - 2;
      }
      // Bottom label: center above
      if (normalizedAngle > pi * 0.9 && normalizedAngle < pi * 1.1) {
        dx = x - tp.width / 2;
        dy = y + 2;
      }

      tp.paint(canvas, Offset(dx, dy));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
