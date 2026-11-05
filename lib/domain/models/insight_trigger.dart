import 'package:memex/domain/models/card_model.dart';

/// Task that analyses newly saved records and, only with evidence across
/// records, creates or updates Knowledge Insights.
const insightTaskType = 'knowledge_insight_task';

/// One waiting task per user; every record saved while it waits joins it, so a
/// chat, a transcript or a batch import costs one analysis, not one per card.
String insightBatchKey(String userId) => 'knowledge_insight:$userId';

/// How long a batch waits for more records before it runs.
const insightDebounce = Duration(minutes: 2);

/// Fewer saved records than this cannot show a pattern across records, so the
/// analysis ends without calling the model.
const minRecordsForInsights = 3;

const _insightSummaryTemplate = 'insight_summary';
const _insightTag = 'insight';

/// True for the timeline card the insight skill writes to announce its own
/// work. It must never start another analysis.
bool isInsightSummaryCard(CardData card) =>
    card.uiConfigs.any((ui) => ui.templateId == _insightSummaryTemplate) ||
    card.tags.contains(_insightTag);

/// Whether a saved record may start an analysis: it holds text or a title the
/// analysis can read, and is not an insight summary.
bool startsInsightAnalysis(CardData card) {
  if (isInsightSummaryCard(card)) return false;
  final text = '${card.fact ?? ''}${card.title ?? ''}'.trim();
  return text.isNotEmpty;
}

/// [existing] followed by the ids of [added] that are not in it yet.
List<String> mergeFactIds(Iterable<String> existing, Iterable<String> added) {
  final merged = <String>[...existing];
  for (final id in added) {
    if (id.isNotEmpty && !merged.contains(id)) merged.add(id);
  }
  return merged;
}
