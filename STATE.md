# STATE — ponto de retomada

**Atualizado:** 2026-11-02 · **Fase ativa:** F1 — Registro de modelos · **Estado:** IN_PROGRESS

A F0 continua `IN_PROGRESS`: o dono pediu para usar só o emulador (D-009) e, em seguida, autorizou começar a F1 com o S25 ainda `NOT_RUN`. A fase F0 não fecha sem o telefone. O portão da F1 também não fecha: faltam resposta real de dois provedores e o login OAuth.

## O que existe hoje (confirmado)
- Fork público `playertwo1/segundamente` de `memex-lab/memex` (Flutter, GPL-3.0). `origin/main` está em `60e0ecf`, 4 commits à frente do upstream `6143923`. A F1 está no working tree, ainda sem commit.
- No código: login OAuth de OpenAI (`lib/data/services/openai_auth_service.dart`) e Gemini (`gemini_auth_service.dart`); Claude só por chave de API (`lib/domain/models/llm_config.dart`).
- Planejamento: `PROJECT.md`, `ROADMAP.md`, `docs/DECISIONS.md`, `docs/questionario/`.

## Evidência da F0 (2026-11-02; Windows 11, Flutter 3.47.9 stable, Dart 3.13.7, JDK 17)
- F0-01 `DONE`: `git remote -v` mostra `upstream=memex-lab/memex`; commit base do Memex = `6143923e7b2237520b7143f4e5aae88822788aa4`.
- F0-02 `DONE` no emulador, S25 `NOT_RUN` (D-009). `flutter build apk --debug --flavor globalDev` → `PASS` (`app-globaldev-debug.apk`, 355 MB, ~15 min no 1º build). Reaberto neste turno em `emulator-5554`, pacote `com.memexlab.memex.dev`, tela "Welcome to Memex". Na 1ª abertura do dia, com `flutter test` em paralelo, apareceu "Memex Dev isn't responding" (ANR); numa segunda abertura, sem carga, o app subiu normalmente.
- `flutter analyze`: 161 issues, 0 error, 0 warning (só `info` de estilo). O Flutter devolve exit code 1 por causa dos infos.
- `flutter test`: 1011 passaram, 7 ignorados, **30 falharam** (13 em `backup_service_test`, 4 em `file_operation_service_grep_test`, 3 em `share_intent_handler_test`, o resto isolado). Causas vistas: `PathAccessException` errno 32 (arquivo em uso no Windows) em 10 casos, `UNIQUE constraint failed` em 2, `MissingPluginException(path_provider)` em 1; o restante não foi investigado. O código era idêntico ao upstream quando esses testes rodaram, então são falhas da linha de base neste ambiente. Neste turno só rodei `flutter test test/l10n/welcome_name_test.dart`: 1 passou.
- F0-03 `DONE` no emulador. `aapt dump badging` do APK novo: `package: name='app.segundamente.dev'` e `application-label:'Segunda Mente Dev'`. `adb install` → `Success`. `pm path` mostrou os dois pacotes ao mesmo tempo: `com.memexlab.memex.dev` e `app.segundamente.dev`. O app novo abriu em "Welcome to Segunda Mente" (Maestro, `emulator-5554`). Assinatura: certificado de debug `CN=Android Debug`; nenhum `.jks`, `.keystore` ou `key-*.properties` versionado. Ícone provisório: adaptive icon em `mipmap-anydpi-v26/launcher_icon.xml`.
- F0-04 `DONE`: 288 pacotes do `pubspec.lock` classificados. Diretas em MIT, BSD-3-Clause, Apache-2.0 ou na GPL-3.0 do próprio app. Três transitivas de desktop (`dbus`, `geoclue`, `gsettings`) são MPL-2.0. Nenhuma GPL-2.0-only nem AGPL no APK. Tabela em `docs/F0-04-licencas.md`.
- F0-05 `DONE`: nota em `docs/F0-05-modulos.md`. Voz do MVP decidida (D-007): transcrição pt-BR pela nuvem, no modelo configurado; TTS do Android fica para a F2; SenseVoice não cobre português. OAuth continua `NOT_RUN`.
- F0-06 `DONE`: `git fetch upstream` e `git merge upstream/main` → `Already up to date`. Contagem `HEAD...upstream/main` = `3	0`. Procedimento em `docs/F0-06-upstream.md`.
- **Ainda `NOT_RUN` na F0:** execução no **S25 Ultra**; logins OAuth.

## Evidência da F1 (2026-11-02)
- F1-01 `DONE`. Catálogo em `lib/domain/models/model_catalog.dart` (versão 1, um cache por provedor e base URL). Status derivado: recomendado = suportado, devolvido pela conta = acessível, id digitado = não testado. A tela de edição mostra esse status (`model_catalog_status`).
- F1-02 `IN_PROGRESS`. O teste de widget gravou o id `my-manual-model`, fora de `LLMConfig.recommendedModels`, com a base URL `https://llm.example.test/v1`. Resposta real desse modelo: `NOT_RUN`.
- F1-03 `IN_PROGRESS`. A matriz cobre texto, stream, JSON, visão e áudio. O aviso aparece quando a sonda marca uma capacidade como ausente. Sondas de texto/JSON/stream/visão/áudio passaram com um cliente falso, sem rede. Resposta real de OpenAI e de Gemini: `NOT_RUN`.
- F1-04 `IN_PROGRESS`. A nota de risco está em `docs/DECISIONS.md` (D-004). Login no S25 e no emulador: `NOT_RUN`.
- F1-05 `NOT_RUN`. Não há chave de API Claude nem um endpoint local em execução. O tipo `claude` já exige chave e aceita base URL; um endpoint compatível usa chat completion com base URL própria. Nenhuma chamada foi feita.
- F1-06 `DONE`. `ChatSessionStorage` manteve os bytes da conversa `conversa antes da troca` depois de trocar o modelo ativo de `openai-switch` para `gemini-switch`. O metadado da sessão não guarda provedor nem model id.
- Comando: `flutter test --reporter compact` nos cinco arquivos abaixo. Saída: `00:08 +35: All tests passed!`
  - `test/domain/models/model_catalog_test.dart`
  - `test/data/services/model_test_service_test.dart`
  - `test/ui/settings/widgets/model_capability_matrix_view_test.dart`
  - `test/ui/settings/widgets/model_config_edit_page_test.dart`
  - `test/data/services/chat_session_storage_test.dart`
- `flutter analyze` e a suíte inteira não foram reexecutados. A linha de base continua 161 infos e 30 falhas no Windows.

## Toolchain (ambiente local, fora do repo)
- Flutter em `C:\Users\notefael\tools\flutter`, fora do PATH: usar `C:\Users\notefael\tools\flutter\bin\flutter`. `flutter config --jdk-dir` aponta para `C:\Users\notefael\AppData\Local\Programs\jdk-17` (o Java 25 padrão quebra o Gradle 8.14).
- O Flutter 3.47 reescreve `analysis_options.yaml` e `android/gradle.properties` ao rodar `pub get`/build; reverter com `git checkout` antes de commitar. Usar `flutter pub get --enforce-lockfile`.
- O Gradle instalou sozinho o Android SDK Platform 34. As demais licenças do SDK seguem não aceitas.

## Última atividade
- 2026-11-02: F0-04 a F0-06 publicadas em `60e0ecf`. F1 implementada no working tree: catálogo, id manual, matriz de capacidades e histórico independente do modelo. Sem chamada real de provedor e sem login OAuth.

## Próxima ação
- O portão da F1 continua aberto. Para fechar F1-02 e F1-03 falta uma resposta real de OpenAI e de Gemini. F1-04 espera o login no S25. F1-05 espera uma chave Claude ou um endpoint local. A F0 continua aberta pelo S25 (D-009). O commit desta F1 espera aprovação do dono.

## Bloqueios e aprovações humanas
- S25 Ultra adiado pelo dono (D-009). Sem chave de API e sem endpoint local neste ambiente. Commit e push da F1 esperam aprovação.

## Divergências entre roadmap e implementação
- A F1 começou com a F0 ainda aberta, por pedido do dono. O S25 segue `NOT_RUN` e não foi tratado como `PASS`.
