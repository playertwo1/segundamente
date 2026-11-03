import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:memex/data/services/transcript_import_service.dart';
import 'package:memex/domain/models/transcript_import.dart';
import 'package:memex/ui/chat/widgets/send_confirmation_view.dart';
import 'package:memex/utils/logger.dart';
import 'package:memex/utils/toast_helper.dart';
import 'package:memex/utils/user_storage.dart';

final _logger = getLogger('TranscriptFileImportButton');

/// Opens the system file picker for one `.txt`. Returns null when the person
/// dismisses the picker or the chosen file has no readable bytes.
Future<List<int>?> pickTranscriptTxtBytes() async {
  final result = await FilePicker.platform.pickFiles(
    allowMultiple: false,
    type: FileType.custom,
    allowedExtensions: const ['txt'],
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;
  final file = result.files.single;
  final memory = file.bytes;
  if (memory != null) return memory;
  final path = file.path;
  if (path == null || path.trim().isEmpty) return null;
  return File(path).readAsBytes();
}

Future<bool> storeConfirmedTranscript(TranscriptImport source) async {
  final userId = await UserStorage.getUserId();
  if (userId == null || userId.isEmpty) {
    throw StateError('user missing');
  }
  return TranscriptImportService().saveIfConfirmed(
    userId: userId,
    sessionId: 'file_${DateTime.now().millisecondsSinceEpoch}',
    sources: [source],
    confirmed: true,
  );
}

/// Picks one `.txt`, asks for confirmation, stores the original and reports
/// the confirmed text through [onConfirmed].
Future<void> importTranscriptFile(
  BuildContext context, {
  Future<List<int>?> Function() pickBytes = pickTranscriptTxtBytes,
  Future<bool> Function(TranscriptImport source) store =
      storeConfirmedTranscript,
  Future<void> Function()? onStored,
  void Function(String text)? onConfirmed,
}) async {
  try {
    final bytes = await pickBytes();
    if (bytes == null || !context.mounted) return;
    final source = TranscriptImport.parse(bytes);
    final batch = TranscriptBatch([source]);
    final accepted = await showSendConfirmationDialog(
      context: context,
      outgoingText: batch.outgoingText,
      timestampsFound: batch.timestampsFound,
      pdfUnsupported: batch.pdfUnsupported,
    );
    if (!accepted || !context.mounted) return;
    final saved = await store(source);
    if (!context.mounted || !saved) return;
    ToastHelper.showSuccess(context, UserStorage.l10n.dataImportSuccess);
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
    this.pickBytes = pickTranscriptTxtBytes,
    this.store = storeConfirmedTranscript,
    this.onStored,
    this.onConfirmed,
  });

  final Future<List<int>?> Function() pickBytes;
  final Future<bool> Function(TranscriptImport source) store;
  final Future<void> Function()? onStored;

  /// Receives the confirmed text, e.g. to send it into the open chat.
  final void Function(String text)? onConfirmed;

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
    await importTranscriptFile(
      context,
      pickBytes: widget.pickBytes,
      store: widget.store,
      onStored: widget.onStored,
      onConfirmed: widget.onConfirmed,
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const ValueKey('import_transcript_file'),
      tooltip: UserStorage.l10n.importTranscriptFile,
      onPressed: _busy ? null : _import,
      icon: const Icon(Icons.upload_file),
    );
  }
}
