import 'package:flutter/material.dart';
import 'package:memex/ui/core/cards/ui/glass_card.dart';
import 'package:memex/ui/core/themes/app_colors.dart';

class RatingCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  const RatingCard({super.key, required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final String subject = data['subject'] ?? data['title'] ?? '';
    final double score = (data['score'] as num?)?.toDouble() ?? 0.0;
    final double maxScore = (data['max_score'] as num?)?.toDouble() ?? 5.0;
    final String? comment = data['comment'];
    final normalizedScore =
        maxScore > 0 ? ((score / maxScore) * 5).clamp(0.0, 5.0) : 0.0;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  subject,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$score / $maxScore',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Star rating visualization
          Row(
            children: List.generate(5, (index) {
              if (index < normalizedScore.floor()) {
                return const Icon(
                  Icons.star,
                  color: AppColors.primary,
                  size: 20,
                );
              } else if (index < normalizedScore &&
                  (normalizedScore - index) >= 0.5) {
                return const Icon(
                  Icons.star_half,
                  color: AppColors.primary,
                  size: 20,
                );
              } else {
                return const Icon(
                  Icons.star_border,
                  color: AppColors.primary,
                  size: 20,
                );
              }
            }),
          ),
          if (comment != null) ...[
            const SizedBox(height: 12),
            Text(
              comment,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
