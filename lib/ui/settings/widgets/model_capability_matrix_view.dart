import 'package:flutter/material.dart';
import 'package:memex/domain/models/model_catalog.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:memex/ui/core/themes/app_colors.dart';

/// Shows the five adapter capabilities and warns when a probe came back missing.
class ModelCapabilityMatrixView extends StatelessWidget {
  final ModelCapabilityMatrix matrix;

  const ModelCapabilityMatrixView({super.key, required this.matrix});

  @override
  Widget build(BuildContext context) {
    final l10n = UserStorage.l10n;
    final missingNames = matrix.missing.map(_label).join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final capability in ModelCapability.values)
              _CapabilityChip(
                label: _label(capability),
                verdict:
                    matrix.verdicts[capability] ?? CapabilityVerdict.unknown,
              ),
          ],
        ),
        if (matrix.hasMissing) ...[
          const SizedBox(height: 8),
          Text(
            l10n.capabilityMissingWarning(missingNames),
            key: const ValueKey('model_capability_warning'),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.warning,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }

  String _label(ModelCapability capability) {
    final l10n = UserStorage.l10n;
    return switch (capability) {
      ModelCapability.text => l10n.testTypeText,
      ModelCapability.streaming => l10n.testTypeStreaming,
      ModelCapability.json => l10n.testTypeJson,
      ModelCapability.vision => l10n.testTypeVision,
      ModelCapability.audio => l10n.testTypeAudio,
    };
  }
}

class _CapabilityChip extends StatelessWidget {
  final String label;
  final CapabilityVerdict verdict;

  const _CapabilityChip({required this.label, required this.verdict});

  @override
  Widget build(BuildContext context) {
    final l10n = UserStorage.l10n;
    final (color, verdictLabel) = switch (verdict) {
      CapabilityVerdict.yes => (AppColors.success, l10n.capabilityYes),
      CapabilityVerdict.no => (const Color(0xFFDC2626), l10n.capabilityNo),
      CapabilityVerdict.unknown => (
          AppColors.textSecondary,
          l10n.capabilityNotTested,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$label · $verdictLabel',
        style:
            TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
