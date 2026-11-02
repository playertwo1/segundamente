import 'dart:io';

import 'package:memex/data/services/chat_session_storage.dart';
import 'package:memex/data/services/file_system_service.dart';
import 'package:memex/domain/models/transcript_import.dart';
import 'package:memex/utils/logger.dart';
import 'package:path/path.dart' as p;

class TranscriptImportService {
  TranscriptImportService({
    FileSystemService? fileService,
    ChatSessionStorage? sessions,
  })  : _files = fileService ?? FileSystemService.instance,
        _sessions = sessions ?? ChatSessionStorage.instance;

  final FileSystemService _files;
  final ChatSessionStorage _sessions;
  final _logger = getLogger('TranscriptImportService');

  /// Writes the original bytes and a separate normalized text, then creates
  /// the chat session. A false confirmation writes nothing.
  Future<bool> saveIfConfirmed({
    required String userId,
    required String sessionId,
    required List<TranscriptImport> sources,
    required bool confirmed,
  }) async {
    if (sources.isEmpty) return false;
    _checkId(sessionId);
    final batch = TranscriptBatch(sources);
    final send = confirmSend(
      outgoingText: batch.outgoingText,
      confirmed: confirmed,
    );
    if (send == null) return false;

    final root = Directory(
      p.join(_files.getTranscriptImportsPath(userId), sessionId),
    );
    if (await root.exists()) {
      throw StateError('transcript import already stored');
    }
    await root.create(recursive: true);

    for (var i = 0; i < sources.length; i++) {
      final dir = Directory(p.join(root.path, '$i'));
      await dir.create();
      final original = File(p.join(dir.path, 'original.bin'));
      if (await original.exists()) {
        throw StateError('original already stored');
      }
      final bytes = sources[i].originalBytes;
      await original.writeAsBytes(bytes, flush: true);
      final stored = await original.readAsBytes();
      if (!_sameBytes(stored, bytes)) {
        throw StateError('original bytes changed while storing');
      }
      await File(p.join(dir.path, 'normalized.txt')).writeAsString(
        sources[i].normalizedText,
        flush: true,
      );
    }

    final now = DateTime.now().toIso8601String();
    await _sessions.createSession(
      userId: userId,
      sessionId: sessionId,
      metadata: {
        'session_id': sessionId,
        'agent_name': 'memex_agent',
        'title': _title(send.outgoingText),
        'created_at': now,
        'updated_at': now,
      },
      messages: [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': send.outgoingText},
          ],
          'timestamp': now,
        },
      ],
    );
    _logger.info('Stored transcript import $sessionId');
    return true;
  }
}

void _checkId(String sessionId) {
  if (sessionId.isEmpty ||
      sessionId.contains('/') ||
      sessionId.contains('\\') ||
      sessionId == '.' ||
      sessionId == '..') {
    throw ArgumentError.value(sessionId, 'sessionId', 'invalid session id');
  }
}

String _title(String text) {
  final line = text.split('\n').first.trim();
  if (line.isEmpty) return 'Import';
  return line.length > 50 ? line.substring(0, 50) : line;
}

bool _sameBytes(List<int> stored, List<int> original) {
  if (stored.length != original.length) return false;
  for (var i = 0; i < stored.length; i++) {
    if (stored[i] != original[i]) return false;
  }
  return true;
}
