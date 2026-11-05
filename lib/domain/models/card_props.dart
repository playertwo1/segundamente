import 'package:memex/domain/models/card_model.dart';

/// Properties worked out from a card, kept in the card cache so the timeline
/// can filter on them. The filter asks for them as tags with this prefix.
const cardPropPrefix = '@prop:';

const propLink = 'link';
const propTask = 'task';
const propOpenTask = 'open_task';
const propCode = 'code';

const cardPropNames = [propLink, propTask, propOpenTask, propCode];

String propTag(String prop) => '$cardPropPrefix$prop';

/// The property name in [tag], or null when it is an ordinary tag.
String? propOfTag(String tag) => tag.startsWith(cardPropPrefix)
    ? tag.substring(cardPropPrefix.length)
    : null;

final _url = RegExp(r'https?://[^\s)>\]]+', caseSensitive: false);
final _fence = RegExp(r'^\s*(```|~~~)', multiLine: true);

/// Cached form: `|link|task|`, so one LIKE per property is exact. Empty when
/// the card has none.
String encodeCardProps(Set<String> props) =>
    props.isEmpty ? '' : '|${(props.toList()..sort()).join('|')}|';

/// Properties of a card:
/// - `link`: a link template, or an http(s) address in its text;
/// - `task`: a task template;
/// - `open_task`: a task template that is not completed (a task is complete
///   when marked so, or when it has subtasks and all are done);
/// - `code`: a fenced code block in its text.
Set<String> deriveCardProps(CardData card) {
  final props = <String>{};
  final texts = <String>[
    if (card.fact != null) card.fact!,
    if (card.title != null) card.title!,
  ];
  for (final ui in card.uiConfigs) {
    for (final value in ui.data.values) {
      if (value is String) texts.add(value);
    }
    if (ui.templateId == 'link') props.add(propLink);
    if (ui.templateId == 'task') {
      props.add(propTask);
      if (!_taskCompleted(ui.data)) props.add(propOpenTask);
    }
  }
  for (final text in texts) {
    if (_url.hasMatch(text)) props.add(propLink);
    if (_fence.hasMatch(text)) props.add(propCode);
  }
  return props;
}

bool _taskCompleted(Map<String, dynamic> data) {
  if (_truthy(data['is_completed'])) return true;
  final subtasks = data['subtasks'];
  return subtasks is List &&
      subtasks.isNotEmpty &&
      subtasks.every((s) => s is Map && _truthy(s['completed']));
}

bool _truthy(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    return const {'true', 'yes', 'y', '1', 'done', 'completed'}
        .contains(value.toLowerCase().trim());
  }
  return false;
}
