import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memex/ui/core/widgets/emoji_icon.dart';
import 'package:memex/ui/core/themes/app_colors.dart';

class BarItem {
  final String label;
  final double value;
  final String? icon;
  final String? color;
  final bool isHighlight;

  BarItem({
    required this.label,
    required this.value,
    this.icon,
    this.color,
    this.isHighlight = false,
  });

  factory BarItem.fromJson(Map<String, dynamic> json) {
    return BarItem(
      label: json['label'] as String? ?? '',
      value: (json['value'] as num? ?? 0).toDouble(),
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      isHighlight: json['is_highlight'] as bool? ?? false,
    );
  }
}

class BarChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String unit;
  final List<BarItem> items;
  final String? insight;
  final VoidCallback? onTap;

  const BarChartCard({
    super.key,
    required this.title,
    this.subtitle,
    this.unit = '',
    this.items = const [],
    this.insight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    double maxY = items.isNotEmpty
        ? items.map((e) => e.value).reduce((a, b) => a > b ? a : b)
        : 10;
    if (maxY == 0) maxY = 1;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            SizedBox(
              height: 28,
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 24 / 16,
                  letterSpacing: -0.44,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            // Subtitle
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 20 / 14,
                  letterSpacing: -0.15,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Items
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;
              final percent = (item.value / maxY).clamp(0.0, 1.0);
              final barColor = item.isHighlight
                  ? AppColors.textPrimary
                  : AppColors.textSecondary;

              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Content emoji stays without a repeated surface.
                    if (item.icon != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: EmojiIcon(
                          emoji: item.icon!,
                          size: 20,
                        ),
                      ),
                    ],

                    // Label + bar + value
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Label and value row
                          SizedBox(
                            height: 20,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.label,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    height: 20 / 14,
                                    letterSpacing: -0.15,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  '${item.value % 1 == 0 ? item.value.toInt() : item.value}$unit',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    height: 20 / 14,
                                    letterSpacing: -0.15,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Progress bar
                          SizedBox(
                            height: 6,
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.divider,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: percent,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: barColor,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
