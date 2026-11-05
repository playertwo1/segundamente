import 'package:flutter_test/flutter_test.dart';
import 'package:memex/domain/models/glossary.dart';
import 'package:memex/domain/models/session_report.dart';

void main() {
  test('terms are trimmed, unique ignoring case and accents, one line', () {
    var terms = addGlossaryTerm(const [], '  Marília Souza ');
    expect(terms, ['Marília Souza']);
    expect(addGlossaryTerm(terms, 'marilia souza'), terms);
    expect(addGlossaryTerm(terms, ''), terms);
    expect(addGlossaryTerm(terms, 'duas\nlinhas'), terms);
    expect(addGlossaryTerm(terms, 'x' * (glossaryMaxTermLength + 1)), terms);
    terms = addGlossaryTerm(terms, 'x' * glossaryMaxTermLength);
    expect(terms, hasLength(2));
  });

  test('the list stops at the documented limit', () {
    var terms = <String>[];
    for (var i = 0; i < glossaryMaxTerms + 5; i++) {
      terms = addGlossaryTerm(terms, 'termo $i');
    }
    expect(terms, hasLength(glossaryMaxTerms));
    expect(
        removeGlossaryTerm(terms, 'termo 0'), hasLength(glossaryMaxTerms - 1));
  });

  test('the prompt block lists the terms and is empty without any', () {
    expect(glossaryPromptBlock(const []), isEmpty);
    final block = glossaryPromptBlock(['Memex', 'Sra. Alvarenga']);
    expect(block, contains('Memex; Sra. Alvarenga'));
  });

  test('the report prompt carries the block only when there are terms', () {
    final plain = reportExtractionSystemPrompt(ReportKind.reuniao);
    final withTerms = reportExtractionSystemPrompt(
      ReportKind.reuniao,
      glossary: ['Alvarenga'],
    );
    expect(plain, isNot(contains('Alvarenga')));
    expect(withTerms, startsWith(plain));
    expect(withTerms, endsWith(glossaryPromptBlock(['Alvarenga'])));
  });

  test('round trips through JSON and rejects another schema', () {
    expect(glossaryFromJson(glossaryToJson(['a', 'b'])), ['a', 'b']);
    expect(
      () => glossaryFromJson({'schema_version': 9, 'terms': []}),
      throwsFormatException,
    );
  });
}
