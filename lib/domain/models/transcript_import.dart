import 'dart:convert';

enum TranscriptKind { text, pdfUnsupported, undecodable }

class TranscriptSegment {
  const TranscriptSegment({
    this.clock,
    this.speaker,
    required this.text,
  });

  /// `HH:MM:SS`, or null when the file has no timestamp.
  final String? clock;
  final String? speaker;
  final String text;
}

class TranscriptImport {
  TranscriptImport._({
    required this.kind,
    required List<int> originalBytes,
    required this.segments,
    required this.normalizedText,
    required this.timestampsFound,
    required this.title,
  }) : originalBytes = List<int>.unmodifiable(originalBytes);

  factory TranscriptImport.parse(List<int> bytes) {
    final original = List<int>.from(bytes);
    if (_startsWithPdf(original)) {
      return TranscriptImport._(
        kind: TranscriptKind.pdfUnsupported,
        originalBytes: original,
        segments: const [],
        normalizedText: '',
        timestampsFound: false,
        title: null,
      );
    }

    final String decoded;
    try {
      decoded = _decode(original);
    } on FormatException {
      return TranscriptImport._(
        kind: TranscriptKind.undecodable,
        originalBytes: original,
        segments: const [],
        normalizedText: '',
        timestampsFound: false,
        title: null,
      );
    }

    return _fromDecoded(original, decoded);
  }

  factory TranscriptImport.fromText(String text) {
    return TranscriptImport.parse(utf8.encode(text));
  }

  final TranscriptKind kind;
  final List<int> originalBytes;
  final List<TranscriptSegment> segments;
  final String normalizedText;
  final bool timestampsFound;
  final String? title;

  String get outgoingText => kind == TranscriptKind.text ? normalizedText : '';
}

class TranscriptBatch {
  TranscriptBatch(this.sources);

  final List<TranscriptImport> sources;

  String get outgoingText => sources
      .map((source) => source.outgoingText)
      .where((text) => text.isNotEmpty)
      .join('\n\n');

  bool get timestampsFound =>
      sources.isNotEmpty &&
      sources.every(
        (source) =>
            source.kind != TranscriptKind.text || source.timestampsFound,
      );

  bool get pdfUnsupported =>
      sources.any((source) => source.kind == TranscriptKind.pdfUnsupported);
}

class ConfirmedSend {
  ConfirmedSend._(this.outgoingText);

  final String outgoingText;
}

ConfirmedSend? confirmSend({
  required String outgoingText,
  required bool confirmed,
}) {
  if (!confirmed || outgoingText.trim().isEmpty) return null;
  return ConfirmedSend._(outgoingText);
}

const _transcriptExtensions = ['.txt', '.srt', '.vtt'];

bool sharedPathsArePlainText(List<String> paths) {
  if (paths.isEmpty) return false;
  for (final path in paths) {
    final name =
        path.replaceAll('\\', '/').split('/').last.trim().toLowerCase();
    if (!_transcriptExtensions.any(name.endsWith)) return false;
  }
  return true;
}

const _audioMimes = {
  'mp3': 'audio/mpeg',
  'wav': 'audio/wav',
  'm4a': 'audio/mp4',
  'aac': 'audio/aac',
  'ogg': 'audio/ogg',
  'opus': 'audio/ogg',
  'flac': 'audio/flac',
};

/// Maps shared PDF/audio paths to chat attachments ({path, name, mime}), or
/// null when any path is neither, so other shares keep their import flow.
List<Map<String, String>>? chatAttachmentsFromPaths(List<String> paths) {
  if (paths.isEmpty) return null;
  final files = <Map<String, String>>[];
  for (final path in paths) {
    final name = path.replaceAll('\\', '/').split('/').last.trim();
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    final mime = ext == 'pdf' ? 'application/pdf' : _audioMimes[ext];
    if (mime == null) return null;
    files.add({'path': path, 'name': name, 'mime': mime});
  }
  return files;
}

const _pdfSignature = [0x25, 0x50, 0x44, 0x46];

final _clock = RegExp(
  r'^(?:(\d{1,2}):)?(\d{1,2}):(\d{2})(?:[.,]\d{1,3})?$',
);
final _clockToken = r'(?:\d{1,2}:)?\d{1,2}:\d{2}(?:[.,]\d{1,3})?';
final _range = RegExp(
  '^($_clockToken)\\s*(?:-->|->|—|–)\\s*$_clockToken\\s*\$',
);
final _bracket = RegExp('^\\[($_clockToken)\\]\\s*(.*)\$');
final _paren = RegExp('^(.+?)\\s*\\(($_clockToken)\\)\\s*\$');

// shortcut: a sentence that ends with a clock is treated as a speaker cue,
// upgrade when a real Samsung sample needs the difference.
final _trailingSpeaker = RegExp('^(.+?)\\s+($_clockToken)\\s*\$');

bool _startsWithPdf(List<int> bytes) {
  if (bytes.length < _pdfSignature.length) return false;
  for (var i = 0; i < _pdfSignature.length; i++) {
    if (bytes[i] != _pdfSignature[i]) return false;
  }
  return true;
}

// shortcut: UTF-16 only with a BOM and no surrogate-pair validation, upgrade
// when a sample arrives without BOM.
String _decode(List<int> bytes) {
  if (bytes.length >= 2) {
    final bigEndian = bytes[0] == 0xFE && bytes[1] == 0xFF;
    final littleEndian = bytes[0] == 0xFF && bytes[1] == 0xFE;
    if (bigEndian || littleEndian) {
      final units = <int>[
        for (var i = 2; i + 1 < bytes.length; i += 2)
          bigEndian
              ? (bytes[i] << 8) | bytes[i + 1]
              : (bytes[i + 1] << 8) | bytes[i],
      ];
      return String.fromCharCodes(units);
    }
  }
  return utf8.decode(_withoutUtf8Bom(bytes));
}

List<int> _withoutUtf8Bom(List<int> bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xEF &&
      bytes[1] == 0xBB &&
      bytes[2] == 0xBF) {
    return bytes.sublist(3);
  }
  return bytes;
}

String? _canonicalClock(String raw) {
  final match = _clock.firstMatch(raw.trim());
  if (match == null) return null;
  final hour = match.group(1) == null ? 0 : int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  final second = int.parse(match.group(3)!);
  if (hour > 99 || minute > 59 || second > 59) return null;
  return '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}:'
      '${second.toString().padLeft(2, '0')}';
}

({String clock, String? speaker})? _cue(String line) {
  final only = _canonicalClock(line);
  if (only != null) return (clock: only, speaker: null);

  final range = _range.firstMatch(line);
  if (range != null) {
    final clock = _canonicalClock(range.group(1)!);
    if (clock != null) return (clock: clock, speaker: null);
  }

  final bracket = _bracket.firstMatch(line);
  if (bracket != null) {
    final clock = _canonicalClock(bracket.group(1)!);
    if (clock != null) {
      final speaker = bracket.group(2)!.trim();
      return (clock: clock, speaker: speaker.isEmpty ? null : speaker);
    }
  }

  final paren = _paren.firstMatch(line);
  if (paren != null) {
    final clock = _canonicalClock(paren.group(2)!);
    if (clock != null) {
      final speaker = paren.group(1)!.trim();
      return (clock: clock, speaker: speaker.isEmpty ? null : speaker);
    }
  }

  final trailing = _trailingSpeaker.firstMatch(line);
  if (trailing != null) {
    final clock = _canonicalClock(trailing.group(2)!);
    if (clock != null) {
      final speaker = trailing.group(1)!.trim();
      return (clock: clock, speaker: speaker.isEmpty ? null : speaker);
    }
  }

  return null;
}

class _SegmentBuilder {
  _SegmentBuilder(this.clock, this.speaker);

  final String? clock;
  final String? speaker;
  final lines = <String>[];

  TranscriptSegment build() {
    // `[00:00:20] texto na mesma linha`: with no lines below, a long "speaker"
    // is the text itself. shortcut: 3+ words is the cutoff, a three-word name
    // with no text below would be read as text.
    if (lines.isEmpty &&
        speaker != null &&
        speaker!.split(RegExp(r'\s+')).length >= 3) {
      return TranscriptSegment(clock: clock, text: speaker!);
    }
    return TranscriptSegment(
      clock: clock,
      speaker: speaker,
      text: lines.join('\n').trim(),
    );
  }
}

// SRT/VTT timing lines always carry milliseconds, which plain Samsung ranges
// do not.
final _subtitleRange = RegExp(
  r'^\s*(?:\d{1,2}:)?\d{1,2}:\d{2}[.,]\d{3}\s*-->\s*(?:\d{1,2}:)?\d{1,2}:\d{2}[.,]\d{3}',
);
final _subtitleStart = RegExp(r'^\s*((?:\d{1,2}:)?\d{1,2}:\d{2})[.,]\d{3}');
final _voiceTag = RegExp(r'^<v(?:\.[^\s>]+)*\s+([^>]+)>');
final _anyTag = RegExp(r'</?[^>\n]+>');
final _labelPrefix =
    RegExp(r"^(\p{Lu}[\p{L}.' -]{0,28}):\s+(.+)$", unicode: true);

// A subtitle file opens like one: a WEBVTT header, a timing line, or a cue
// number followed by a timing line. A millisecond range further down a Samsung
// TXT does not turn the whole file into SRT.
bool _isSubtitle(String decoded) {
  final lines = decoded
      .replaceFirst('\uFEFF', '')
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .take(2)
      .toList();
  if (lines.isEmpty) return false;
  if (lines.first.startsWith('WEBVTT')) return true;
  if (_subtitleRange.hasMatch(lines.first)) return true;
  return RegExp(r'^\d+$').hasMatch(lines.first) &&
      lines.length > 1 &&
      _subtitleRange.hasMatch(lines[1]);
}

TranscriptImport _fromSubtitle(List<int> original, String decoded) {
  final cues = <({String? clock, String? voice, String text})>[];
  final blocks = decoded
      .replaceFirst('\uFEFF', '')
      .replaceAll('\r', '')
      .split(RegExp(r'\n[ \t]*\n'));
  for (final block in blocks) {
    final lines = block.split('\n').map((l) => l.trimRight()).toList();
    final at = lines.indexWhere(_subtitleRange.hasMatch);
    // Header, NOTE, STYLE and REGION blocks have no timing line.
    if (at < 0) continue;
    final start = _subtitleStart.firstMatch(lines[at])!.group(1)!;
    String? voice;
    final text = <String>[];
    for (var line in lines.skip(at + 1)) {
      final tag = _voiceTag.firstMatch(line.trimLeft());
      if (tag != null) voice ??= tag.group(1)!.trim();
      line = line.replaceAll(_anyTag, '').trim();
      if (line.isNotEmpty) text.add(line);
    }
    if (text.isEmpty) continue;
    cues.add(
        (clock: _canonicalClock(start), voice: voice, text: text.join('\n')));
  }

  // shortcut: a "Nome: fala" label counts as a speaker only when the same
  // label opens two or more cues, so "Atenção: ..." stays plain text.
  final labelCounts = <String, int>{};
  for (final cue in cues) {
    final m = _labelPrefix.firstMatch(cue.text.split('\n').first);
    if (m != null) {
      labelCounts.update(m.group(1)!, (n) => n + 1, ifAbsent: () => 1);
    }
  }

  final segments = <TranscriptSegment>[];
  for (final cue in cues) {
    var speaker = cue.voice;
    var text = cue.text;
    final m = _labelPrefix.firstMatch(text.split('\n').first);
    if (speaker == null && m != null && labelCounts[m.group(1)]! >= 2) {
      speaker = m.group(1);
      text = text.replaceFirst('${m.group(1)}:', '').trimLeft();
    }
    segments
        .add(TranscriptSegment(clock: cue.clock, speaker: speaker, text: text));
  }

  if (segments.isEmpty) {
    return _fromPlainText(original, decoded);
  }
  return TranscriptImport._(
    kind: TranscriptKind.text,
    originalBytes: original,
    segments: segments,
    normalizedText: _normalized(null, segments),
    timestampsFound: true,
    title: null,
  );
}

TranscriptImport _fromPlainText(List<int> original, String decoded) {
  final text = decoded.replaceAll('\r', '').trim();
  return TranscriptImport._(
    kind: TranscriptKind.text,
    originalBytes: original,
    segments: [TranscriptSegment(text: text)],
    normalizedText: text,
    timestampsFound: false,
    title: null,
  );
}

TranscriptImport _fromDecoded(List<int> original, String decoded) {
  if (_isSubtitle(decoded)) return _fromSubtitle(original, decoded);
  final header = <String>[];
  final builders = <_SegmentBuilder>[];
  _SegmentBuilder? current;

  for (final rawLine in decoded.split('\n')) {
    final line = rawLine.replaceAll('\r', '').trim();
    if (line.isEmpty) continue;
    final cue = _cue(line);
    if (cue != null) {
      current = _SegmentBuilder(cue.clock, cue.speaker);
      builders.add(current);
      continue;
    }
    if (current == null) {
      header.add(line);
    } else {
      current.lines.add(line);
    }
  }

  if (builders.isEmpty) return _fromPlainText(original, decoded);

  final segments = builders.map((builder) => builder.build()).toList();
  final title = header.isEmpty ? null : header.join('\n');
  return TranscriptImport._(
    kind: TranscriptKind.text,
    originalBytes: original,
    segments: segments,
    normalizedText: _normalized(title, segments),
    timestampsFound: true,
    title: title,
  );
}

String _normalized(String? title, List<TranscriptSegment> segments) {
  final buffer = StringBuffer();
  if (title != null) {
    buffer.writeln(title);
    buffer.writeln();
  }
  for (var i = 0; i < segments.length; i++) {
    final segment = segments[i];
    if (segment.clock != null) {
      final speaker = segment.speaker;
      buffer.writeln(
        speaker == null ? '[${segment.clock}]' : '[${segment.clock}] $speaker',
      );
    }
    buffer.write(segment.text);
    if (i != segments.length - 1) buffer.write('\n\n');
  }
  return buffer.toString().trimRight();
}
