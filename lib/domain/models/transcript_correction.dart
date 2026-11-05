import 'package:memex/domain/models/session_report.dart';

const transcriptCorrectionSchemaVersion = 1;
const correctionMaxFixes = 200;
const correctionMaxGrowth = 40;

/// Replaces one exact piece of one segment: `from` becomes `to`.
class TextFix {
  const TextFix({
    required this.segmentId,
    required this.from,
    required this.to,
  });

  final String segmentId;
  final String from;
  final String to;
}

class CorrectionRefused implements Exception {
  const CorrectionRefused(this.reason);

  final String reason;

  @override
  String toString() => 'CorrectionRefused: $reason';
}

/// Returns the segments with every fix applied, or throws
/// [CorrectionRefused]. Nothing is changed in place. A fix is accepted only
/// when its segment exists, `from` is a non-empty piece that occurs exactly
/// once in the segment as it stands, and `to` is a short single-line text
/// that differs from `from` (it may grow by at most [correctionMaxGrowth]
/// characters, so a fix cannot rewrite or translate a passage).
List<ReportSegment> applyFixes(
  List<ReportSegment> segments,
  List<TextFix> fixes,
) {
  if (fixes.length > correctionMaxFixes) {
    throw const CorrectionRefused('too many fixes');
  }
  final texts = {for (final s in segments) s.id: s.text};
  for (final fix in fixes) {
    final text = texts[fix.segmentId];
    if (text == null) throw const CorrectionRefused('unknown segment');
    if (fix.from.isEmpty) throw const CorrectionRefused('empty from');
    if (fix.to.trim().isEmpty) throw const CorrectionRefused('empty to');
    if (fix.to == fix.from) throw const CorrectionRefused('no change');
    if (RegExp(r'[\r\n]').hasMatch(fix.to)) {
      throw const CorrectionRefused('to has a line break');
    }
    if (fix.to.length > fix.from.length + correctionMaxGrowth) {
      throw const CorrectionRefused('to is too long');
    }
    final first = text.indexOf(fix.from);
    if (first < 0) throw const CorrectionRefused('from not found');
    if (text.indexOf(fix.from, first + 1) >= 0) {
      throw const CorrectionRefused('from is ambiguous');
    }
    texts[fix.segmentId] = text.replaceRange(
      first,
      first + fix.from.length,
      fix.to,
    );
  }
  return [
    for (final s in segments)
      ReportSegment(id: s.id, text: texts[s.id]!, clock: s.clock),
  ];
}

Map<String, dynamic> correctionsToJson(List<TextFix> fixes) => {
      'schema_version': transcriptCorrectionSchemaVersion,
      'fixes': [
        for (final f in fixes)
          {'segment_id': f.segmentId, 'from': f.from, 'to': f.to},
      ],
    };

List<TextFix> correctionsFromJson(Map<String, dynamic> json) {
  if (json['schema_version'] != transcriptCorrectionSchemaVersion) {
    throw const FormatException('correction schema');
  }
  final raw = json['fixes'];
  if (raw is! List) throw const FormatException('correction fixes');
  return [
    for (final row in raw)
      if (row is Map)
        TextFix(
          segmentId: row['segment_id'] as String,
          from: row['from'] as String,
          to: row['to'] as String,
        )
      else
        throw const FormatException('correction row'),
  ];
}
