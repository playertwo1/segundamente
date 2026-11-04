import 'package:flutter/material.dart';
import 'package:memex/ui/core/cards/ui/glass_card.dart';
import 'package:memex/ui/core/themes/app_colors.dart';
import 'package:memex/ui/core/widgets/local_image.dart';
import 'package:memex/utils/user_storage.dart';

class GalleryCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  const GalleryCard({super.key, required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final List<String> imageUrls =
        (data['image_urls'] as List<dynamic>?)?.cast<String>() ?? [];
    final String? title =
        data['title'] is String && (data['title'] as String).isNotEmpty
            ? data['title'] as String
            : null;

    if (imageUrls.isEmpty) {
      return GlassCard(
        onTap: onTap,
        child: Text(UserStorage.l10n.noImages),
      );
    }

    return GlassCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: imageUrls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) => SizedBox(
                width: 72,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _buildImage(imageUrls[index]),
                ),
              ),
            ),
          ),
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage(String url) {
    return ColoredBox(
      color: AppColors.background,
      child: LocalImage(
        url: url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => const Center(
          child:
              Icon(Icons.broken_image_outlined, color: AppColors.textTertiary),
        ),
      ),
    );
  }
}
