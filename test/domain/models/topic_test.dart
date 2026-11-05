import 'package:flutter_test/flutter_test.dart';
import 'package:memex/domain/models/topic.dart';

void main() {
  test('a topic is its own entity linked to sessions, once each', () {
    var topics = addTopic(const [], id: 't1', name: ' Casa ');
    topics = linkSession(topics, 't1', 's1');
    topics = linkSession(topics, 't1', 's1');
    topics = linkSession(topics, 't1', 's2');
    expect(topics.single.name, 'Casa');
    expect(topics.single.sessionIds, ['s1', 's2']);
    topics = unlinkSession(topics, 't1', 's1');
    expect(topics.single.sessionIds, ['s2']);
  });

  test('blank and repeated names are refused, ignoring case and accents', () {
    final topics = addTopic(const [], id: 't1', name: 'Reunião');
    expect(addTopic(topics, id: 't2', name: '  '), topics);
    expect(addTopic(topics, id: 't2', name: 'REUNIAO'), topics);
    expect(renameTopic(topics, 't1', 'reunião').single.name, 'reunião');
    final two = addTopic(topics, id: 't2', name: 'Obra');
    expect(renameTopic(two, 't2', 'reuniao'), two);
  });

  test('deleting a session removes it from every topic', () {
    var topics = addTopic(const [], id: 't1', name: 'A');
    topics = addTopic(topics, id: 't2', name: 'B', isProject: true);
    topics = linkSession(linkSession(topics, 't1', 's1'), 't2', 's1');
    topics = forgetSession(topics, 's1');
    expect(topics.every((t) => t.sessionIds.isEmpty), isTrue);
    expect(removeTopic(topics, 't1').single.id, 't2');
  });

  test('round trips through JSON and rejects another schema', () {
    final topics = linkSession(
      addTopic(const [], id: 't1', name: 'Obra', isProject: true),
      't1',
      's1',
    );
    final back = topicsFromJson(topicsToJson(topics));
    expect(back.single.isProject, isTrue);
    expect(back.single.sessionIds, ['s1']);
    expect(
      () => topicsFromJson({'schema_version': 99, 'topics': []}),
      throwsFormatException,
    );
  });
}
