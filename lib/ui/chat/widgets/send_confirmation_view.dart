import 'package:flutter/material.dart';
import 'package:memex/ui/core/themes/app_colors.dart';
import 'package:memex/ui/core/widgets/editorial_scaffold.dart';
import 'package:memex/utils/user_storage.dart';

/// "Revisar antes de enviar" (reference 22): the exact text that will leave
/// the phone, the privacy notes, and an explicit back / send choice.
class SendConfirmationView extends StatelessWidget {
  const SendConfirmationView({
    super.key,
    required this.outgoingText,
    required this.timestampsFound,
    required this.pdfUnsupported,
    this.sourceFileNames = const [],
    required this.onConfirm,
    required this.onCancel,
  });

  final String outgoingText;
  final bool timestampsFound;
  final bool pdfUnsupported;
  final List<String> sourceFileNames;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = UserStorage.l10n;
    final canConfirm = outgoingText.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1, color: AppColors.divider),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (sourceFileNames.isNotEmpty) ...[
                  EditorialSectionLabel(l10n.selectedFiles),
                  ...sourceFileNames.map(
                    (name) => EditorialRow(
                      title: name,
                      subtitle: l10n.plainTextFile,
                      leading: const Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    outgoingText,
                    key: const ValueKey('send_outgoing_text'),
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: AppColors.divider),
        _Note(
          icon: Icons.cloud_upload_outlined,
          text: l10n.sendLeavesDeviceTitle,
          textKey: const ValueKey('send_leaves_device_title'),
        ),
        if (!timestampsFound)
          _Note(
            icon: Icons.schedule_outlined,
            text: l10n.noTimestampsFound,
            textKey: const ValueKey('send_no_timestamps'),
          ),
        if (pdfUnsupported)
          _Note(
            icon: Icons.picture_as_pdf_outlined,
            text: l10n.pdfImportUnsupported,
            textKey: const ValueKey('send_pdf_unsupported'),
          ),
        _Note(
          icon: Icons.shield_outlined,
          text: l10n.sendNothingWithoutConfirm,
        ),
        const Divider(height: 1, color: AppColors.divider),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              TextButton(
                key: const ValueKey('send_confirmation_cancel'),
                onPressed: onCancel,
                style: TextButton.styleFrom(minimumSize: const Size(96, 52)),
                child: Text(
                  l10n.sendBack,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    key: const ValueKey('send_confirmation_confirm'),
                    onPressed: canConfirm ? onConfirm : null,
                    child: Text(l10n.sendNow),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text, this.textKey});

  final IconData icon;
  final String text;
  final Key? textKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppColors.textPrimary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              key: textKey,
              style: const TextStyle(
                fontSize: 14,
                height: 1.35,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> showSendConfirmationDialog({
  required BuildContext context,
  required String outgoingText,
  required bool timestampsFound,
  required bool pdfUnsupported,
  List<String> sourceFileNames = const [],
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return Dialog.fullscreen(
        backgroundColor: AppColors.background,
        child: EditorialScaffold(
          title: UserStorage.l10n.sendReviewTitle,
          onBack: () => Navigator.pop(dialogContext, false),
          body: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SendConfirmationView(
              outgoingText: outgoingText,
              timestampsFound: timestampsFound,
              pdfUnsupported: pdfUnsupported,
              sourceFileNames: sourceFileNames,
              onCancel: () => Navigator.pop(dialogContext, false),
              onConfirm: () => Navigator.pop(dialogContext, true),
            ),
          ),
        ),
      );
    },
  ).then((value) => value ?? false);
}
