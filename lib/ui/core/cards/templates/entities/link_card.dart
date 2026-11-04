import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:memex/ui/core/cards/ui/glass_card.dart';
import 'package:memex/ui/core/themes/app_colors.dart';

class LinkCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  const LinkCard({super.key, required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final String url = data['url'] ?? '';
    final String domain = data['domain'] ?? Uri.tryParse(url)?.host ?? '';
    final String? title = data['title'];

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && title.isNotEmpty) ...[
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
          ],
          GestureDetector(
            onTap: url.isNotEmpty ? () => _openUrl(url) : null,
            child: Row(
              children: [
                const Icon(Icons.link, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  domain,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
