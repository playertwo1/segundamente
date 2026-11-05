import 'package:memex/domain/models/topic.dart';

const glossarySchemaVersion = 1;
const glossaryMaxTerms = 50;
const glossaryMaxTermLength = 60;

/// Adds a name, acronym or product the model should spell exactly like this.
/// Blank, multi-line, too long or repeated terms (ignoring case and accents),
/// or a full list, leave the list unchanged.
List<String> addGlossaryTerm(List<String> terms, String raw) {
  final term = raw.trim();
  if (term.isEmpty ||
      term.length > glossaryMaxTermLength ||
      RegExp(r'[\r\n\t]').hasMatch(term) ||
      terms.length >= glossaryMaxTerms ||
      terms.any((t) => nameKey(t) == nameKey(term))) {
    return terms;
  }
  return [...terms, term];
}

List<String> removeGlossaryTerm(List<String> terms, String term) => [
      for (final t in terms)
        if (t != term) t
    ];

/// The text appended to the report prompt. This same string is what the
/// glossary screen shows as the preview of what is sent. Empty without terms.
String glossaryPromptBlock(List<String> terms) {
  if (terms.isEmpty) return '';
  return 'The user keeps these names, acronyms and products. When the '
      'speaker says something that sounds like one of them, write it exactly '
      'as listed. Never add a term that was not said: ${terms.join('; ')}.';
}

Map<String, dynamic> glossaryToJson(List<String> terms) =>
    {'schema_version': glossarySchemaVersion, 'terms': terms};

List<String> glossaryFromJson(Map<String, dynamic> json) {
  if (json['schema_version'] != glossarySchemaVersion) {
    throw const FormatException('glossary schema');
  }
  final raw = json['terms'];
  if (raw is! List) throw const FormatException('glossary terms');
  return [for (final t in raw) t as String];
}
