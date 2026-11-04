import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/ui/core/themes/app_colors.dart';

double _ratio(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  final hi = l1 > l2 ? l1 : l2;
  final lo = l1 > l2 ? l2 : l1;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  // WCAG AA for normal text is 4.5:1; the divider is decoration, not text.
  const textTokens = {
    'textPrimary': AppColors.textPrimary,
    'textSecondary': AppColors.textSecondary,
    'textTertiary': AppColors.textTertiary,
    'primary': AppColors.primary,
    'success': AppColors.success,
    'warning': AppColors.warning,
    'danger': AppColors.danger,
  };

  for (final bg in {
    'background': AppColors.background,
    'surface': AppColors.surface,
  }.entries) {
    for (final fg in textTokens.entries) {
      test('${fg.key} on ${bg.key} has at least 4.5:1', () {
        expect(_ratio(fg.value, bg.value), greaterThanOrEqualTo(4.5));
      });
    }
  }

  test('onPrimary on primary has at least 4.5:1', () {
    expect(_ratio(AppColors.onPrimary, AppColors.primary),
        greaterThanOrEqualTo(4.5));
  });

  test('the divider is not used as a readable text color', () {
    expect(_ratio(AppColors.divider, AppColors.background), lessThan(3));
  });
}
