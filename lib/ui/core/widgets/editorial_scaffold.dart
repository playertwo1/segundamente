import 'package:flutter/material.dart';
import 'package:memex/ui/core/themes/app_colors.dart';
import 'package:memex/ui/core/widgets/memex_brand_title.dart';
import 'package:memex/utils/user_storage.dart';

/// Page frame of the AMOLED v3 references (15–23): back arrow, brand title,
/// optional trailing actions, a large editorial title with an optional
/// subtitle, the body and an optional fixed bottom bar for the main action.
class EditorialScaffold extends StatelessWidget {
  const EditorialScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions = const [],
    this.bottom,
    this.showBack = true,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget> actions;

  /// Fixed area under the body (primary action, secondary links).
  final Widget? bottom;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (showBack)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: UserStorage.l10n.lockBack,
                        icon: const Icon(
                          Icons.chevron_left,
                          size: 28,
                          color: AppColors.textPrimary,
                        ),
                        onPressed:
                            onBack ?? () => Navigator.of(context).maybePop(),
                      ),
                    ),
                  const MemexBrandTitle(),
                  if (actions.isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.15,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(child: body),
            if (bottom != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: bottom,
              ),
          ],
        ),
      ),
    );
  }
}

/// Small uppercase label that opens a group of rows (GRANULARIDADE, GUIAS…).
class EditorialSectionLabel extends StatelessWidget {
  const EditorialSectionLabel(
    this.text, {
    super.key,
    this.horizontalPadding = 20,
  });

  final String text;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 20, horizontalPadding, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          letterSpacing: 1,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Open list row with a thin divider below: leading icon, title, optional
/// subtitle and a trailing widget. At least 48 dp tall.
class EditorialRow extends StatelessWidget {
  const EditorialRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.selected = false,
    this.titleColor,
    this.divider = true,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;
  final Color? titleColor;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            border: divider
                ? const Border(
                    bottom: BorderSide(color: AppColors.divider, width: 1),
                  )
                : null,
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                IconTheme(
                  data: const IconThemeData(
                    color: AppColors.textPrimary,
                    size: 24,
                  ),
                  child: leading!,
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: titleColor ?? AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check, color: AppColors.primary, size: 24)
              else if (trailing != null)
                trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
