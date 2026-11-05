import 'package:flutter_test/flutter_test.dart';
import 'package:memex/domain/models/card_model.dart';
import 'package:memex/domain/models/card_props.dart';

CardData card({
  String? fact,
  String? title,
  List<UiConfig> ui = const [],
}) =>
    CardData(
      factId: '2026/11/05.md#ts_1',
      timestamp: 1,
      status: 'completed',
      tags: const [],
      uiConfigs: ui,
      fact: fact,
      title: title,
    );

UiConfig task(Map<String, dynamic> data) =>
    UiConfig(templateId: 'task', data: data);

void main() {
  test('a plain note has no property', () {
    expect(deriveCardProps(card(fact: 'comprei pão')), isEmpty);
  });

  test('link: template or an address in the text', () {
    expect(
      deriveCardProps(card(ui: [const UiConfig(templateId: 'link', data: {})])),
      {propLink},
    );
    expect(deriveCardProps(card(fact: 'veja https://exemplo.com/a ok')),
        {propLink});
    expect(
      deriveCardProps(card(ui: [
        const UiConfig(
          templateId: 'snippet',
          data: {'text': 'ver http://x.org'},
        ),
      ])),
      {propLink},
    );
    expect(
        deriveCardProps(card(fact: 'site exemplo.com sem protocolo')), isEmpty);
  });

  test('task is open until marked done or every subtask is done', () {
    expect(
        deriveCardProps(card(ui: [
          task({'title': 'a'})
        ])),
        {propTask, propOpenTask});
    expect(
        deriveCardProps(card(ui: [
          task({'is_completed': true})
        ])),
        {propTask});
    expect(
        deriveCardProps(card(ui: [
          task({'is_completed': 'done'})
        ])),
        {propTask});
    expect(
      deriveCardProps(card(ui: [
        task({
          'subtasks': [
            {'completed': true},
            {'completed': false},
          ],
        }),
      ])),
      {propTask, propOpenTask},
    );
    expect(
      deriveCardProps(card(ui: [
        task({
          'subtasks': [
            {'completed': true},
            {'completed': 1},
          ],
        }),
      ])),
      {propTask},
    );
  });

  test('code: a fenced block, not an inline backtick', () {
    expect(deriveCardProps(card(fact: 'rode:\n```dart\nprint(1);\n```')),
        {propCode});
    expect(deriveCardProps(card(fact: 'use `ls` aqui')), isEmpty);
  });

  test('cache form is sorted, delimited and empty for none', () {
    expect(encodeCardProps({}), '');
    expect(encodeCardProps({propTask, propLink}), '|link|task|');
    expect(propOfTag(propTag(propCode)), propCode);
    expect(propOfTag('trabalho'), isNull);
  });
}
