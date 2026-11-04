import 'package:flutter/material.dart';
import 'package:memex/ui/core/themes/app_colors.dart';

class CompositionItem {
  final String label;
  final double percentage;
  final Color color;

  CompositionItem({
    required this.label,
    required this.percentage,
    required this.color,
  });

  factory CompositionItem.fromJson(Map<String, dynamic> json) {
    return CompositionItem(
      label: json['label'] as String? ?? 'Unknown',
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      color: _parseColor(json['color']),
    );
  }

  static Color _parseColor(dynamic _) => AppColors.textSecondary;
}

class HeadlineItem {
  final String text;
  final Color? color;

  HeadlineItem({required this.text, this.color});

  factory HeadlineItem.fromJson(Map<String, dynamic> json) {
    // Support both {"text": "..."} and {"label": "...", "value": "..."}
    final text = json['text'] as String? ??
        (json['label'] != null && json['value'] != null
            ? '${json['label']}: ${json['value']}'
            : json['label'] as String? ?? '');
    return HeadlineItem(
      text: text,
      color: json['color'] != null
          ? CompositionItem._parseColor(json['color'])
          : null,
    );
  }
}

class CompositionCard extends StatelessWidget {
  final String title;
  final String? badge;
  final List<HeadlineItem> headlineItems;
  final List<CompositionItem> items;
  final String? footer;
  final String? insight;
  final VoidCallback? onTap;

  const CompositionCard({
    super.key,
    required this.title,
    this.badge,
    this.headlineItems = const [],
    this.items = const [],
    this.footer,
    this.insight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row
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
                        height: 20 / 14,
                        letterSpacing: -0.15,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (badge != null)
                    Text(
                      badge!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 20 / 14,
                        letterSpacing: -0.15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                ],
              ),
            ),

            // Headline
            if (headlineItems.isNotEmpty &&
                headlineItems.any((h) => h.text.isNotEmpty)) ...[
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                  children: headlineItems
                      .where((item) => item.text.isNotEmpty)
                      .map((item) {
                    return TextSpan(
                      text: item.text,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 6),
            ],

            // Progress Bar
            const SizedBox(height: 12),
            _buildProgressBar(),

            const SizedBox(height: 16),

            // Items Legend
            _buildLegendGrid(),

            // Footer
            if (footer != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 20,
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        footer!,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 20 / 14,
                          letterSpacing: -0.15,
                          color: AppColors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    if (items.isEmpty) return const SizedBox.shrink();
    const palette = [
      AppColors.textPrimary,
      AppColors.textSecondary,
      AppColors.textTertiary,
      AppColors.divider,
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 8,
        color: AppColors.background,
        child: Row(
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final flex = (item.percentage * 10).round();
            if (flex <= 0) return const SizedBox.shrink();
            return Flexible(
              flex: flex,
              child: Container(color: palette[index % palette.length]),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLegendGrid() {
    if (items.isEmpty) return const SizedBox.shrink();
    const palette = [
      AppColors.textPrimary,
      AppColors.textSecondary,
      AppColors.textTertiary,
      AppColors.divider,
    ];

    // Responsive 2-column layout usually works best for mobile
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        // approx 45% width for 2 columns with spacing
        return FractionallySizedBox(
          widthFactor: 0.45,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: palette[index % palette.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${item.label} (${item.percentage.toInt()}%)',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
