import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/data/repositories/memex_router.dart';
import 'package:memex/ui/knowledge/widgets/knowledge_file_page.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRouter implements MemexRouter {
  _FakeRouter(this.content);

  final String content;

  @override
  Future<Map<String, dynamic>> readPkmFile(String filePath) async {
    return {'content': content};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'language': 'pt'});
    await UserStorage.initL10n();
  });

  Future<void> pump(WidgetTester tester, _FakeRouter router) async {
    await tester.pumpWidget(
      MaterialApp(
        home: KnowledgeFilePage(
          filePath: 'Guias/primeiros-passos.md',
          router: router,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('leitor mostra título, metadados, corpo e ação de compartilhar',
      (tester) async {
    await pump(
      tester,
      _FakeRouter(
        '# Guia de primeiros passos\n\n## Comece pelo que importa\n\n'
        'Registre uma ideia.\n\n- Anote com suas palavras\n- Revise antes de compartilhar\n',
      ),
    );

    expect(find.text('Guia de primeiros passos'), findsOneWidget);
    expect(find.text('Conhecimento · Markdown · 1 min'), findsOneWidget);
    expect(find.text('Comece pelo que importa'), findsOneWidget);
    expect(find.textContaining('Registre uma ideia.'), findsOneWidget);
    expect(find.textContaining('Anote com suas palavras'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('knowledge_file_download_button')),
      findsOneWidget,
    );
    expect(find.text('Compartilhar'), findsOneWidget);
  });

  testWidgets('sem título no texto usa o nome do arquivo', (tester) async {
    await pump(tester, _FakeRouter('Só um parágrafo.'));
    expect(find.text('primeiros-passos'), findsOneWidget);
  });

  testWidgets('mostra o guia legado sem alterar o nome nem o conteúdo salvo',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: KnowledgeFilePage(
          filePath: 'Resources/Memex Guide.md',
          router: _FakeRouter('# Memex Guide\n\nTexto original.'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text(UserStorage.l10n.userGuideTitle), findsOneWidget);
    expect(find.text('Memex Guide'), findsNothing);
    expect(find.textContaining('Texto original.'), findsOneWidget);
  });
}
