import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:memex/data/services/transcript_import_service.dart';
import 'package:memex/domain/models/transcript_import.dart';
import 'package:memex/ui/chat/widgets/send_confirmation_view.dart';
import 'package:memex/ui/core/widgets/editorial_scaffold.dart';
import 'package:memex/ui/core/themes/app_colors.dart';
import 'package:memex/utils/logger.dart';
import 'package:memex/utils/toast_helper.dart';
import 'package:memex/utils/user_storage.dart';

final _logger = getLogger('TranscriptFileImportButton');

/// Opens the system file picker for `.txt`, `.srt` and `.vtt` files. Returns null when dismissed
/// or if a chosen file has no readable bytes.
Future<List<({String name, List<int> bytes})>?> pickTranscriptTxtFiles() async {
  final result = await FilePicker.platform.pickFiles(
    allowMultiple: true,
    // Not FileType.custom: Android greys out files whose MIME it does not know
    // (a .vtt often shows as BIN), so the extension is checked after picking.
    type: FileType.any,
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;
  const allowed = {'txt', 'srt', 'vtt'};
  if (result.files.any((f) => !allowed.contains(f.extension?.toLowerCase()))) {
    return null;
  }
  final files = <({String name, List<int> bytes})>[];
  for (final file in result.files) {
    final bytes = file.bytes;
    if (bytes != null) {
      files.add((name: file.name, bytes: bytes));
      continue;
    }
    final path = file.path;
    if (path == null || path.trim().isEmpty) return null;
    files.add((name: file.name, bytes: await File(path).readAsBytes()));
  }
  return files;
}

Future<bool> storeConfirmedTranscripts(List<TranscriptImport> sources) async {
  final userId = await UserStorage.getUserId();
  if (userId == null || userId.isEmpty) {
    throw StateError('user missing');
  }
  return TranscriptImportService().saveIfConfirmed(
    userId: userId,
    sessionId: 'file_${DateTime.now().millisecondsSinceEpoch}',
    sources: sources,
    confirmed: true,
  );
}

/// Picks transcript files, asks for confirmation, stores the originals and reports
/// the confirmed text through [onConfirmed].
Future<void> importTranscriptFiles(
  BuildContext context, {
  Future<List<({String name, List<int> bytes})>?> Function() pickFiles =
      pickTranscriptTxtFiles,
  Future<bool> Function(List<TranscriptImport> sources) store =
      storeConfirmedTranscripts,
  Future<void> Function()? onStored,
  void Function(String text)? onConfirmed,
  VoidCallback? onViewActivity,
}) async {
  try {
    final files = await pickFiles();
    if (files == null || files.isEmpty || !context.mounted) return;
    final sources = files
        .map((file) => TranscriptImport.parse(file.bytes))
        .toList(growable: false);
    final batch = TranscriptBatch(sources);
    final accepted = await showSendConfirmationDialog(
      context: context,
      outgoingText: batch.outgoingText,
      timestampsFound: batch.timestampsFound,
      pdfUnsupported: batch.pdfUnsupported,
      sourceFileNames: files.map((file) => file.name).toList(growable: false),
    );
    if (!accepted || !context.mounted) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    final progressDialog = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Dialog.fullscreen(
          backgroundColor: AppColors.background,
          child: EditorialScaffold(
            title: UserStorage.l10n.importingTranscript,
            showBack: false,
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
    bool saved;
    try {
      saved = await store(sources);
    } finally {
      if (navigator.mounted && navigator.canPop()) navigator.pop();
      await progressDialog;
    }
    if (!context.mounted) return;
    if (!saved) {
      ToastHelper.showError(context, UserStorage.l10n.transcriptImportFailed);
      return;
    }
    if (onViewActivity != null && onConfirmed != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(UserStorage.l10n.dataImportSuccess),
          action: SnackBarAction(
            label: UserStorage.l10n.viewActivity,
            onPressed: onViewActivity,
          ),
        ),
      );
    } else {
      ToastHelper.showSuccess(context, UserStorage.l10n.dataImportSuccess);
    }
    await onStored?.call();
    onConfirmed?.call(batch.outgoingText);
  } catch (error, stackTrace) {
    _logger.severe('Transcript file was not stored: $error', error, stackTrace);
    if (context.mounted) {
      ToastHelper.showError(context, UserStorage.l10n.operationFailed(error));
    }
  }
}

class TranscriptFileImportButton extends StatefulWidget {
  const TranscriptFileImportButton({
    super.key,
    this.pickFiles = pickTranscriptTxtFiles,
    this.store = storeConfirmedTranscripts,
    this.onStored,
    this.onConfirmed,
    this.onViewActivity,
  });

  final Future<List<({String name, List<int> bytes})>?> Function() pickFiles;
  final Future<bool> Function(List<TranscriptImport> sources) store;
  final Future<void> Function()? onStored;

  /// Receives the confirmed text, e.g. to send it into the open chat.
  final void Function(String text)? onConfirmed;
  final VoidCallback? onViewActivity;

  @override
  State<TranscriptFileImportButton> createState() =>
      _TranscriptFileImportButtonState();
}

class _TranscriptFileImportButtonState
    extends State<TranscriptFileImportButton> {
  var _busy = false;

  Future<void> _import() async {
    if (_busy) return;
    setState(() => _busy = true);
    await importTranscriptFiles(
      context,
      pickFiles: widget.pickFiles,
      store: widget.store,
      onStored: widget.onStored,
      onConfirmed: widget.onConfirmed,
      onViewActivity: widget.onViewActivity,
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const ValueKey('import_transcript_file'),
      tooltip: UserStorage.l10n.importTranscriptFile,
      onPressed: _busy ? null : _import,
      icon: const Icon(Icons.upload_file_outlined),
    );
  }
}
