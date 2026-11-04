import 'package:flutter/material.dart';
import 'package:memex/ui/core/cards/ui/glass_card.dart';
import 'package:memex/ui/core/themes/app_colors.dart';

class QuoteCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  const QuoteCard({super.key, required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final String content = data['content'] ?? '';
    final String? author = data['author'];
    final String? source = data['source'];

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: const BoxDecoration(
          border: BorderDirectional(
            start: BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        padding: const EdgeInsetsDirectional.only(start: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.45,
                color: AppColors.textPrimary,
              ),
            ),
            if (author != null || source != null) ...[
              const SizedBox(height: 8),
              if (author != null)
                Text(
                  author,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              if (source != null)
                Text(
                  source,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
