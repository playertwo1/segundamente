import 'package:memex/domain/models/session_report.dart';
import 'package:memex/domain/models/topic.dart';

const reportRevisionSchemaVersion = 1;

class ReportHit {
  const ReportHit({
    required this.sessionId,
    required this.item,
  });

  final String sessionId;
  final ReportItem item;
}

class ReportRevision {
  const ReportRevision({
    required this.itemId,
    required this.field,
    required this.before,
    required this.after,
    required this.at,
    this.reason = 'não informado',
  });

  final String itemId;
  final String field;
  final String before;
  final String after;
  final String at;
  final String reason;
}

String reportHitKey(String sessionId, String itemId) {
  return '$sessionId/$itemId';
}

List<ReportHit> searchReports(List<SessionReport> reports, String query) {
  final needle = nameKey(query);
  if (needle.isEmpty) return const [];
  final hits = <ReportHit>[];
  for (final report in reports) {
    // A match on the session title brings in the whole session.
    final titleMatches = nameKey(report.title).contains(needle);
    for (final item in report.items) {
      if (item.status == ReportItemStatus.discarded) continue;
      final text = nameKey(item.text);
      final excerpt = nameKey(item.source.excerpt);
      if (titleMatches || text.contains(needle) || excerpt.contains(needle)) {
        hits.add(ReportHit(sessionId: report.sessionId, item: item));
      }
    }
  }
  return hits;
}

List<ReportHit> approvedFollowUpHits(List<SessionReport> reports) {
  final hits = <ReportHit>[];
  for (final report in reports) {
    for (final item in report.items) {
      if (item.kind == ReportItemKind.followUp &&
          item.status == ReportItemStatus.approved) {
        hits.add(ReportHit(sessionId: report.sessionId, item: item));
      }
    }
  }
  return hits;
}

List<ReportRevision> revisionsForChange({
  required ReportItem before,
  required ReportItem after,
  required String at,
  String? reason,
}) {
  if (before.id != after.id) {
    throw StateError('item mismatch');
  }
  final effectiveReason = (reason != null && reason.trim().isNotEmpty)
      ? reason.trim()
      : 'não informado';
  final rows = <ReportRevision>[];
  if (before.text != after.text) {
    rows.add(
      ReportRevision(
        itemId: before.id,
        field: 'text',
        before: before.text,
        after: after.text,
        at: at,
        reason: effectiveReason,
      ),
    );
  }
  if (before.status != after.status) {
    rows.add(
      ReportRevision(
        itemId: before.id,
        field: 'status',
        before: before.status.name,
        after: after.status.name,
        at: at,
        reason: effectiveReason,
      ),
    );
  }
  return rows;
}

ReportRevision? latestTextChange(
  List<ReportRevision> history,
  String itemId,
) {
  for (var i = history.length - 1; i >= 0; i--) {
    final row = history[i];
    if (row.itemId == itemId && row.field == 'text') return row;
  }
  return null;
}

Map<String, dynamic> revisionsToJson(List<ReportRevision> rows) {
  return {
    'schema_version': reportRevisionSchemaVersion,
    'items': [
      for (final row in rows)
        {
          'item_id': row.itemId,
          'field': row.field,
          'before': row.before,
          'after': row.after,
          'at': row.at,
          'reason': row.reason,
        },
    ],
  };
}

List<ReportRevision> revisionsFromJson(Map<String, dynamic> json) {
  final version = json['schema_version'];
  if (version != reportRevisionSchemaVersion) {
    throw const FormatException('revision schema');
  }
  final rawItems = json['items'];
  if (rawItems is! List) throw const FormatException('revision items');
  return [
    for (final raw in rawItems)
      if (raw is Map)
        ReportRevision(
          itemId: raw['item_id'] as String,
          field: raw['field'] as String,
          before: raw['before'] as String,
          after: raw['after'] as String,
          at: raw['at'] as String,
          reason: (raw['reason'] as String?)?.trim().isNotEmpty == true
              ? (raw['reason'] as String).trim()
              : 'não informado',
        )
      else
        throw const FormatException('revision item'),
  ];
}
