import 'package:flutter/material.dart';

/// Centralized color constants (AMOLED v3, see DESIGN.md).
/// All UI code should reference these instead of hardcoding hex values.
class AppColors {
  const AppColors._();

  // AMOLED v3 palette (DESIGN.md, D-017). Blue stays only in the app icon.

  // Brand: amber/copper for selection, confirmation and key actions.
  static const Color primary = Color(0xFFE99A3D);

  /// Text and icons drawn on top of [primary].
  static const Color onPrimary = Color(0xFF000000);

  // Backgrounds: pure black with few, quiet surfaces.
  static const Color background = Color(0xFF000000);
  static const Color cardBackground = Color(0xFF000000);

  /// Raised surface for sheets, dialogs, inputs and own chat bubbles.
  static const Color surface = Color(0xFF161412);
  static const Color iconBgLight = Color(0xFF241D15);

  /// Thin dividers and outlines.
  static const Color divider = Color(0xFF33312E);

  // Text
  static const Color textPrimary = Color(0xFFF3EEE6);
  static const Color textSecondary = Color(0xFFAAA6A0);
  static const Color textTertiary = Color(0xFF85817B);

  // Navigation
  static const Color tabActive = Color(0xFFF3EEE6);
  static const Color tabInactive = Color(0xFFAAA6A0);
  static const Color tagActiveBg = Color(0xFF241D15);

  // Semantic (lightened to keep contrast on black)
  static const Color success = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFFB7185);

  // No shadows on AMOLED; kept so existing BoxShadows render nothing.
  static const Color shadowLight = Color(0x00000000);
  static const Color shadowCard = Color(0x00000000);

  // Avatar gradient
  static const List<Color> avatarGradient = [
    Color(0xFFE99A3D),
    Color(0xFFE6943A),
    Color(0xFFE28E37),
    Color(0xFFDF8834),
    Color(0xFFDB8231),
    Color(0xFFD87C2E),
    Color(0xFFD4762B),
    Color(0xFFD17028),
    Color(0xFFCD6A25),
    Color(0xFFCA6422),
    Color(0xFFC65E1F),
    Color(0xFFC3581C),
  ];

  static const List<double> avatarGradientStops = [
    0.0,
    0.0909,
    0.1818,
    0.2727,
    0.3636,
    0.4545,
    0.5455,
    0.6364,
    0.7273,
    0.8182,
    0.9091,
    1.0,
  ];
}
