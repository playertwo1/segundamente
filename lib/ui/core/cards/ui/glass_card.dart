import 'package:memex/ui/core/themes/app_colors.dart';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? backgroundColor;

  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 20,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // AMOLED editorial row: no box or shadow unless a template asks for a
    // fill; zero-padding (image) cards keep a quiet rounded clip.
    final edgeToEdge = padding == EdgeInsets.zero;
    final radius = BorderRadius.circular(edgeToEdge ? 12 : 0);
    final p = padding.resolve(TextDirection.ltr);
    final effectivePadding = edgeToEdge || backgroundColor != null
        ? padding
        : EdgeInsets.only(top: p.top.clamp(0, 8), bottom: p.bottom.clamp(0, 8));
    return Container(
      width: double.infinity,
      margin: EdgeInsets.zero,
      clipBehavior: edgeToEdge ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: backgroundColor == AppColors.cardBackground
            ? null
            : backgroundColor,
        borderRadius: radius,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: effectivePadding,
            child: child,
          ),
        ),
      ),
    );
  }
}
