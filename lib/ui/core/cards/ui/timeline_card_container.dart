import 'package:flutter/material.dart';
import 'package:memex/ui/core/cards/style/timeline_theme.dart';
import 'package:memex/ui/core/themes/app_colors.dart';

enum TimelineCardVariant {
  glass,
  immersive,
  canvas,
  receipt,
  outline,
}

class TimelineCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final TimelineCardVariant variant;
  final EdgeInsetsGeometry padding;
  final Color? customBackgroundColor;

  const TimelineCard({
    super.key,
    required this.child,
    this.onTap,
    this.variant = TimelineCardVariant.glass,
    this.padding = const EdgeInsets.all(20),
    this.customBackgroundColor,
  });

  /// AMOLED editorial rows (DESIGN.md, D-017): no box, shadow or fill; the
  /// timeline row draws the divider. Only [TimelineCardVariant.immersive]
  /// keeps a quiet raised surface for emphasis.
  bool get _isEditorial => variant != TimelineCardVariant.immersive;

  @override
  Widget build(BuildContext context) {
    final edgeToEdge = padding == EdgeInsets.zero;
    return Container(
      margin: EdgeInsets.zero,
      decoration: _isEditorial
          ? BoxDecoration(
              color: customBackgroundColor,
              borderRadius: edgeToEdge ? BorderRadius.circular(12) : null,
            )
          : BoxDecoration(
              color: customBackgroundColor ?? AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
      clipBehavior: edgeToEdge || !_isEditorial ? Clip.antiAlias : Clip.none,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: _buildContent(),
        ),
      ),
    );
  }

  /// Editorial rows align with the timeline text column: keep vertical
  /// rhythm, drop the side inset the old box needed.
  EdgeInsetsGeometry get _effectivePadding {
    if (!_isEditorial || padding == EdgeInsets.zero) return padding;
    final p = padding.resolve(TextDirection.ltr);
    return EdgeInsets.only(
        top: p.top.clamp(0, 8), bottom: p.bottom.clamp(0, 8));
  }

  Widget _buildContent() {
    final content = Padding(padding: _effectivePadding, child: child);

    if (variant == TimelineCardVariant.canvas) {
      return Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
          content,
        ],
      );
    }

    return content;
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = TimelineTheme.colors.textTertiary.withValues(alpha: 0.15);
    const spacing = 20.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      for (var y = 0.0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
