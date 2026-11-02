import 'package:flutter/material.dart';
import 'package:memex/utils/user_storage.dart';

class SendConfirmationView extends StatelessWidget {
  const SendConfirmationView({
    super.key,
    required this.outgoingText,
    required this.timestampsFound,
    required this.pdfUnsupported,
    required this.onConfirm,
    required this.onCancel,
  });

  final String outgoingText;
  final bool timestampsFound;
  final bool pdfUnsupported;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = UserStorage.l10n;
    final canConfirm = outgoingText.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.sendLeavesDeviceTitle,
          key: const ValueKey('send_leaves_device_title'),
        ),
        if (!timestampsFound)
          Text(
            l10n.noTimestampsFound,
            key: const ValueKey('send_no_timestamps'),
          ),
        if (pdfUnsupported)
          Text(
            l10n.pdfImportUnsupported,
            key: const ValueKey('send_pdf_unsupported'),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            child: Text(
              outgoingText,
              key: const ValueKey('send_outgoing_text'),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              key: const ValueKey('send_confirmation_cancel'),
              onPressed: onCancel,
              child: Text(l10n.cancel),
            ),
            const SizedBox(width: 8),
            FilledButton(
              key: const ValueKey('send_confirmation_confirm'),
              onPressed: canConfirm ? onConfirm : null,
              child: Text(l10n.confirm),
            ),
          ],
        ),
      ],
    );
  }
}

Future<bool> showSendConfirmationDialog({
  required BuildContext context,
  required String outgoingText,
  required bool timestampsFound,
  required bool pdfUnsupported,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: Colors.white,
        content: SizedBox(
          width: double.maxFinite,
          height: 320,
          child: SendConfirmationView(
            outgoingText: outgoingText,
            timestampsFound: timestampsFound,
            pdfUnsupported: pdfUnsupported,
            onCancel: () => Navigator.pop(dialogContext, false),
            onConfirm: () => Navigator.pop(dialogContext, true),
          ),
        ),
      );
    },
  ).then((value) => value ?? false);
}
