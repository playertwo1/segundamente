import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Back button using btn_back.svg from Figma design.
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
      // 48dp touch target around the 36dp icon.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: action,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: SvgPicture.asset(
              'assets/icons/btn_back.svg',
              width: 36,
              height: 36,
            ),
          ),
        ),
      ),
    );
  }
}
