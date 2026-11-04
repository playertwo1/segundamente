import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memex/ui/core/themes/app_colors.dart';

class ProgressItem {
  final String label;
  final double value;
  final String color;

  ProgressItem({
    required this.label,
    required this.value,
    required this.color,
  });

  factory ProgressItem.fromJson(Map<String, dynamic> json) {
    return ProgressItem(
      label: json['label'] as String? ?? '',
      value: (json['value'] as num? ?? 0).toDouble(),
      color: json['color'] as String? ?? '#E2E8F0',
    );
  }
}

class ProgressChartCard extends StatelessWidget {
  static const _chartPalette = [
    AppColors.textPrimary,
    AppColors.textSecondary,
    AppColors.textTertiary,
    AppColors.divider,
  ];

  final String title;
  final String? subtitle;
  final double current;
  final double target;
  final String? centerText;
  final List<ProgressItem> items;
  final String? insight;
  final VoidCallback? onTap;

  const ProgressChartCard({
    super.key,
    required this.title,
    this.subtitle,
    this.current = 0,
    this.target = 100,
    this.centerText,
    this.items = const [],
    this.insight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 24, 24, 24),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: Ring chart (100×100, offset left by -8)
                Transform.translate(
                  offset: const Offset(-8, 0),
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: Stack(
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 0,
                            centerSpaceRadius: 32,
                            startDegreeOffset: -90,
                            sections: _buildSections(),
                          ),
                        ),
                        Center(
                          child: Text(
                            centerText ??
                                '${((current / target) * 100).toInt()}%',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              height: 36 / 24,
                              letterSpacing: 0.4,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Right: Title + subtitle + legend
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 24 / 16,
                          letterSpacing: -0.31,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Subtitle
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 20 / 14,
                            letterSpacing: -0.15,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      // Legend items
                      if (items.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ...items.asMap().entries.map((entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _chartColor(entry.key),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${entry.value.label} (${entry.value.value.toInt()})',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        height: 16 / 12,
                                        letterSpacing: 0,
                                        color: AppColors.textTertiary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
              ], // end Row children
            ), // end Row
          ], // end Column children
        ), // end Column
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    if (items.isNotEmpty) {
      return items.asMap().entries.map((entry) {
        final item = entry.value;
        return PieChartSectionData(
          color: _chartColor(entry.key),
          value: item.value,
          title: '',
          radius: 10,
          showTitle: false,
        );
      }).toList();
    }

    final remainder = target - current;
    return [
      PieChartSectionData(
        color: AppColors.textPrimary,
        value: current,
        title: '',
        radius: 10,
        showTitle: false,
      ),
      if (remainder > 0)
        PieChartSectionData(
          color: AppColors.divider,
          value: remainder,
          title: '',
          radius: 10,
          showTitle: false,
        ),
    ];
  }

  Color _chartColor(int index) => _chartPalette[index % _chartPalette.length];
}
