// Copyright 2024 The Memex team. All rights reserved.
// Compass-aligned: ui/core/themes/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memex/ui/core/themes/app_colors.dart';

/// Application theme (Compass-aligned: centralised in ui/core/themes).
abstract final class AppTheme {
  AppTheme._();

  /// App background — delegates to AppColors
  static const Color scaffoldBackground = AppColors.background;

  static TextTheme _buildTextTheme(Brightness brightness) {
    final base = GoogleFonts.interTextTheme(
      brightness == Brightness.light
          ? ThemeData.light().textTheme
          : ThemeData.dark().textTheme,
    );
    return base.copyWith(
      // Display — hero / splash
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.3,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      // Headline — section headers
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.2,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      // Title — card titles, AppBar
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: -0.1,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      // Body — content text
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      // Label — buttons, chips, metadata
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.1,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.5,
      ),
    );
  }

  /// The only theme: AMOLED black, ivory text, amber accent (D-017).
  static ThemeData get amoledTheme {
    final textTheme = _buildTextTheme(Brightness.dark).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );
    const colorScheme = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.primary,
      onSecondary: AppColors.onPrimary,
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceContainerLowest: AppColors.background,
      surfaceContainerLow: AppColors.surface,
      surfaceContainer: AppColors.surface,
      surfaceContainerHigh: AppColors.surface,
      surfaceContainerHighest: AppColors.iconBgLight,
      outline: AppColors.divider,
      outlineVariant: AppColors.divider,
      error: AppColors.danger,
      onError: AppColors.onPrimary,
    );
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scaffoldBackground,
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: textTheme,
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 0.5,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: textTheme.headlineMedium,
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: 22,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.background,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.divider, width: 0.5),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surface,
        contentTextStyle: TextStyle(color: AppColors.textPrimary),
        actionTextColor: AppColors.primary,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: AppColors.textTertiary),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        minVerticalPadding: 12,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.onPrimary
                : AppColors.textSecondary),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.surface),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
    );
  }
}
