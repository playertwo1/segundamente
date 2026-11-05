import 'dart:convert';

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'card_dao.g.dart';

@DriftAccessor(tables: [CardCache])
class CardDao extends DatabaseAccessor<AppDatabase> with _$CardDaoMixin {
  CardDao(super.db);

  /// Check if the cache is empty
  Future<bool> isCacheEmpty() async {
    // Use limit(1) to check existence without scanning the full table
    final query = selectOnly(cardCache)
      ..addColumns([cardCache.factId])
      ..limit(1);
    final result = await query.get();
    return result.isEmpty;
  }

  /// Clear the entire cache
  Future<void> clearCache() async {
    await delete(cardCache).go();
  }

  /// Insert or update a card in the cache
  Future<void> upsertCard(CardCacheCompanion card) async {
    await into(cardCache).insertOnConflictUpdate(card);
  }

  /// Delete a card from cache by factId
  Future<void> deleteCard(String factId) async {
    await (delete(cardCache)..where((tbl) => tbl.factId.equals(factId))).go();
  }

  /// Tag list of every cached card, one entry per card.
  Future<List<List<String>>> getAllTagLists() async {
    final query = selectOnly(cardCache)..addColumns([cardCache.tags]);
    final rows = await query.get();
    return [
      for (final row in rows) _decodeTags(row.read(cardCache.tags)),
    ];
  }

  /// Query cards with filters and pagination
  Future<List<CardCacheData>> getCards({
    int page = 1,
    int limit = 20,
    List<String>? tags,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final query = select(cardCache);

    // Date Filters
    if (dateFrom != null) {
      final fromTs = DateTime(dateFrom.year, dateFrom.month, dateFrom.day)
              .millisecondsSinceEpoch ~/
          1000;
      query.where((tbl) => tbl.timestamp.isBiggerOrEqualValue(fromTs));
    }
    if (dateTo != null) {
      // End of dateTo day
      final toDate = DateTime(dateTo.year, dateTo.month, dateTo.day)
          .add(const Duration(days: 1))
          .subtract(const Duration(seconds: 1));
      final toTs = toDate.millisecondsSinceEpoch ~/ 1000;
      query.where((tbl) => tbl.timestamp.isSmallerOrEqualValue(toTs));
    }

    // Tag Filters (JSON list string 'contains' logic via LIKE)
    if (tags != null && tags.isNotEmpty) {
      // A parent tag also matches the tags under it: area -> area/projeto.
      final tagConditions = tags.expand((t) => [
            cardCache.tags.like('%"$t"%'),
            cardCache.tags.like('%"$t/%'),
          ]);
      var combinedCondition = tagConditions.first;
      for (var i = 1; i < tagConditions.length; i++) {
        combinedCondition = combinedCondition | tagConditions.elementAt(i);
      }
      query.where((tbl) => combinedCondition);
    }

    // Sorting: Timestamp DESC, then FactId DESC
    query.orderBy([
      (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
      (t) => OrderingTerm(expression: t.factId, mode: OrderingMode.desc)
    ]);

    // Pagination
    final offset = (page - 1) * limit;
    query.limit(limit, offset: offset);

    return await query.get();
  }
}

List<String> _decodeTags(String? raw) {
  if (raw == null || raw.isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) return decoded.map((e) => e.toString()).toList();
  } on FormatException {
    // A malformed row counts as untagged instead of breaking the whole list.
  }
  return const [];
}
