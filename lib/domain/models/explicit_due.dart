/// A date the user wrote in full, with or without a time of day.
class ExplicitDue {
  const ExplicitDue(this.date, {required this.hasTime});

  /// Local date and time; midnight when [hasTime] is false.
  final DateTime date;
  final bool hasTime;
}

final _isoDate = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})');
final _brDate = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})');
final _time = RegExp(r'^(?:T|\s+(?:às|as)?\s*)(\d{1,2}):(\d{2})$');

/// Reads `2026-11-20`, `20/11/2026` and either one followed by `14:30`.
/// Words such as "amanhã" or "sexta" and impossible dates give null: a
/// calendar entry is offered only for a date the user stated explicitly.
ExplicitDue? parseExplicitDue(String raw) {
  final text = raw.trim();
  int year;
  int month;
  int day;
  String rest;

  final iso = _isoDate.firstMatch(text);
  final br = _brDate.firstMatch(text);
  if (iso != null) {
    year = int.parse(iso.group(1)!);
    month = int.parse(iso.group(2)!);
    day = int.parse(iso.group(3)!);
    rest = text.substring(iso.end);
  } else if (br != null) {
    day = int.parse(br.group(1)!);
    month = int.parse(br.group(2)!);
    year = int.parse(br.group(3)!);
    rest = text.substring(br.end);
  } else {
    return null;
  }

  var hour = 0;
  var minute = 0;
  var hasTime = false;
  if (rest.isNotEmpty) {
    final time = _time.firstMatch(rest);
    if (time == null) return null;
    hour = int.parse(time.group(1)!);
    minute = int.parse(time.group(2)!);
    hasTime = true;
  }

  final date = DateTime(year, month, day, hour, minute);
  // DateTime rolls impossible values over (31/02 becomes 03/03); refuse those.
  if (date.year != year ||
      date.month != month ||
      date.day != day ||
      date.hour != hour ||
      date.minute != minute) {
    return null;
  }
  return ExplicitDue(date, hasTime: hasTime);
}
