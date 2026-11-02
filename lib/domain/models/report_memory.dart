import 'package:memex/domain/models/session_report.dart';

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
  });

  final String itemId;
  final String field;
  final String before;
  final String after;
  final String at;
}

String reportHitKey(String sessionId, String itemId) {
  return '$sessionId/$itemId';
}

List<ReportHit> searchReports(List<SessionReport> reports, String query) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return const [];
  final hits = <ReportHit>[];
  for (final report in reports) {
    for (final item in report.items) {
      if (item.status == ReportItemStatus.discarded) continue;
      final text = item.text.toLowerCase();
      final excerpt = item.source.excerpt.toLowerCase();
      if (text.contains(needle) || excerpt.contains(needle)) {
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
}) {
  if (before.id != after.id) {
    throw StateError('item mismatch');
  }
  final rows = <ReportRevision>[];
  if (before.text != after.text) {
    rows.add(
      ReportRevision(
        itemId: before.id,
        field: 'text',
        before: before.text,
        after: after.text,
        at: at,
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
        },
    ],
  };
}

List<ReportRevision> revisionsFromJson(Map<String, dynamic> json) {
  final version = json['schema_version'];
  if (version != reportRevisionSchemaVersion) {
    throw FormatException('revision schema');
  }
  final rawItems = json['items'];
  if (rawItems is! List) throw FormatException('revision items');
  return [
    for (final raw in rawItems)
      if (raw is Map)
        ReportRevision(
          itemId: raw['item_id'] as String,
          field: raw['field'] as String,
          before: raw['before'] as String,
          after: raw['after'] as String,
          at: raw['at'] as String,
        )
      else
        throw FormatException('revision item'),
  ];
}
