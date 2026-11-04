import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:memex/ui/core/widgets/editorial_scaffold.dart';
import 'package:memex/ui/core/themes/app_colors.dart';
import 'package:memex/utils/user_storage.dart';

class SharePreviewDialog extends StatelessWidget {
  final Uint8List imageBytes;
  final VoidCallback onShare;
  final VoidCallback onCancel;

  /// Callback to toggle between card style and detail style.
  /// If null, the toggle button is hidden.
  final VoidCallback? onToggleStyle;

  /// Whether the current preview is in detail (long image) style.
  final bool isDetailStyle;

  /// Callback to toggle branding (Memex watermark).
  final VoidCallback? onToggleBranding;

  /// Whether branding is currently shown.
  final bool showBranding;

  const SharePreviewDialog({
    super.key,
    required this.imageBytes,
    required this.onShare,
    required this.onCancel,
    this.onToggleStyle,
    this.isDetailStyle = false,
    this.onToggleBranding,
    this.showBranding = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = UserStorage.l10n;

    return Dialog.fullscreen(
      backgroundColor: AppColors.background,
      child: EditorialScaffold(
        title: l10n.sharePreviewTitle,
        onBack: onCancel,
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Image.memory(
            imageBytes,
            fit: BoxFit.contain,
            semanticLabel: l10n.sharePreviewTitle,
          ),
        ),
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onToggleStyle != null)
              EditorialRow(
                title: l10n.sharePosterFormat(
                  isDetailStyle ? l10n.shareDetailStyle : l10n.shareCardStyle,
                ),
                subtitle:
                    isDetailStyle ? l10n.shareCardStyle : l10n.shareDetailStyle,
                leading: const Icon(Icons.article_outlined),
                trailing: const Icon(Icons.swap_horiz_outlined),
                selected: isDetailStyle,
                onTap: onToggleStyle,
              ),
            if (onToggleBranding != null)
              EditorialRow(
                title: l10n.sharePosterBranding(
                  showBranding
                      ? l10n.sharePosterVisible
                      : l10n.sharePosterHidden,
                ),
                subtitle: showBranding
                    ? l10n.shareHideBranding
                    : l10n.shareShowBranding,
                leading: const Icon(Icons.branding_watermark_outlined),
                trailing: const Icon(Icons.swap_horiz_outlined),
                selected: showBranding,
                onTap: onToggleBranding,
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: onShare,
                      icon: const Icon(Icons.ios_share_outlined),
                      label: Text(l10n.shareNow),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
