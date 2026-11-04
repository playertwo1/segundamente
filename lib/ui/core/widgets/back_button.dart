import 'package:flutter/material.dart';
import 'package:memex/ui/core/themes/app_colors.dart';

/// Outline back arrow on the AMOLED background (DESIGN.md), 48dp target.
class AppBackButton extends StatelessWidget {
  final VoidCallback? onTap;

  const AppBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    void action() => (onTap ?? () => Navigator.pop(context))();
    return Semantics(
      button: true,
      label: MaterialLocalizations.of(context).backButtonTooltip,
      excludeSemantics: true,
      onTap: action,
      // 48dp touch target around the 24dp icon.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: action,
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Icon(
              Icons.arrow_back,
              size: 24,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
