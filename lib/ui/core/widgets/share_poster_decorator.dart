import 'package:flutter/material.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:memex/ui/core/themes/app_colors.dart';

class SharePosterDecorator extends StatelessWidget {
  final Widget content;
  final bool showBranding;

  const SharePosterDecorator({
    super.key,
    required this.content,
    this.showBranding = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background,
            AppColors.divider,
          ],
        ),
      ),
      padding: EdgeInsets.fromLTRB(24, 40, 24, showBranding ? 32 : 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Core Content Area with floating premium shadow
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.03),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: content,
          ),

          // 2. Premium Attribution Footer (optional)
          if (showBranding) ...[
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left: Brand Section
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset('assets/icon.png',
                              width: 48, height: 48),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Gradient Text for Brand Name
                          ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                AppColors.primary,
                                Color(0xFFA855F7),
                                Color(0xFFEC4899),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: const Text(
                              'Memex',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            UserStorage.l10n.appTagline,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
