import 'package:flutter/material.dart';
import 'package:memex/data/services/link_preview_service.dart';
import 'package:memex/utils/user_storage.dart';
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
          if ((title == null || title.isEmpty) && url.isNotEmpty)
            _PreviewLine(url: url),
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

/// Shows the page title when the user turned link previews on. Off, or when
/// the address is refused or unreachable, it shows nothing and never calls
/// the network.
class _PreviewLine extends StatefulWidget {
  const _PreviewLine({required this.url});

  final String url;

  @override
  State<_PreviewLine> createState() => _PreviewLineState();
}

class _PreviewLineState extends State<_PreviewLine> {
  late final Future<String?> _title = _load();

  Future<String?> _load() async {
    if (!await UserStorage.isLinkPreviewEnabled()) return null;
    try {
      return (await LinkPreviewService.instance.fetch(widget.url)).title;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _title,
      builder: (context, snapshot) {
        final title = snapshot.data;
        if (title == null || title.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            title,
            key: const ValueKey('link-preview-title'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        );
      },
    );
  }
}
