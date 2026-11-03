import 'package:flutter_test/flutter_test.dart';
import 'package:memex/data/repositories/card.dart';
import 'package:memex/domain/models/card_detail_model.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'language': 'pt'});
    await UserStorage.initL10n();
  });

  test('comment author labels resolve from l10n', () {
    expect(UserStorage.l10n.commentAuthorUser, 'Usuário');
    expect(UserStorage.l10n.commentAuthorAi, 'IA');
    expect(UserStorage.l10n.authorizationCancelled, 'Autorização cancelada');
    expect(UserStorage.l10n.timelineWeekNumberLabel('12'), 'Semana 12');
    expect(UserStorage.l10n.eventCardDefaultTitle, 'Evento');
    expect(UserStorage.l10n.memoryNoLongTermYet, 'Ainda não há memórias de longo prazo.');
  });

  test('replyDisplayNameFor falls back to localized AI label', () {
    final comment = Comment(
      id: 'c1',
      content: 'hello',
      timestamp: 1,
      isAi: true,
    );

    expect(
      replyDisplayNameFor(comment, UserStorage.l10n.commentAuthorUser),
      UserStorage.l10n.commentAuthorAi,
    );
  });
}
