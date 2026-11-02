# STATE — ponto de retomada

**Atualizado:** 2026-11-02 · **Fase ativa:** F3 — Extração e relatório · **Estado:** IN_PROGRESS

A F0 continua `IN_PROGRESS`: o S25 Ultra está `NOT_RUN` (D-009). A F1 continua `IN_PROGRESS`: faltam resposta real de dois provedores e o login OAuth. A F2 continua `IN_PROGRESS`: faltam o TXT real de ~50 min, o S25 e a voz. O dono autorizou abrir a F3 em 2026-11-02 com esses três portões abertos. O portão da F3 não fecha: a amostra de 53 min e uma resposta real de modelo estão `NOT_RUN`.

## O que existe hoje (confirmado)
- Fork público `playertwo1/segundamente` de `memex-lab/memex` (Flutter, GPL-3.0). `origin/main` estava em `e8b30b1`, sobre a F1 `790e8b8`. A primeira leva da F2 está publicada. O botão de escolher um TXT e o relatório local da F3 entram neste commit. O portão da F3 continua aberto.
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
- Publicada em `790e8b8` (`feat(models): catálogo versionado, capacidades e histórico na troca`). O commit não espera mais aprovação.

## Evidência da F2 (2026-11-02)
- F2-01 `DONE` com limite explícito. Uma segunda instância `ChatSessionStorage.forTesting` leu `conversa que sobrevive` nos mesmos arquivos. Não foi morte do processo do app nem o emulador.
- F2-02 `NOT_RUN`. Sem demonstração no S25 e sem TTS novo. SenseVoice não foi trocado.
- F2-03 `IN_PROGRESS`. O parser cobre relógio sozinho, `Locutor 1 00:01:02`, `화자 1 (1:05)`, `[00:02:03] Locutor 2` e intervalo `00:00:10,000 --> 00:00:14,120` (usa o início). O cabeçalho vira título. A lista de conversas tem o botão de escolher um `.txt`: a prévia mostra o texto normalizado, cancelar não grava e confirmar passa os bytes originais. O teste usou o texto curto `00:01` / `olá`. Não há um TXT real de ~50 min neste ambiente, nem execução no S25.
- F2-04 `DONE`. Depois de normalizar `00:01\r\n  olá  \r\n`, `original.bin` continua igual aos bytes de entrada. O texto normalizado é outro arquivo: `[00:00:01]\nolá`.
- F2-05 `NOT_RUN`. Nenhuma foto foi analisada num provedor.
- F2-06 `DONE` para colar; PDF `NOT_RUN`. O texto `nota colada sem relógio` só virou sessão com confirmação. Bytes que começam com `%PDF` não são lidos nem gravados. Nenhum PDF real foi aberto.
- F2-07 `DONE` no caminho de texto. A tela mostra o texto exato, inclusive espaços. Cancelar não confirma e não grava. Compartilhar só `.txt` e colar da área de transferência passam por essa tela. Outros tipos de arquivo continuam no diálogo genérico, que não mostra o conteúdo.
- Comando: `flutter test --reporter compact` nos quatro arquivos abaixo. Saída: `00:50 +22: All tests passed!`
  - `test/domain/models/transcript_import_test.dart`
  - `test/data/services/transcript_import_service_test.dart`
  - `test/ui/chat/widgets/send_confirmation_view_test.dart`
  - `test/data/services/chat_session_storage_test.dart`
- `flutter analyze` e a suíte inteira não foram reexecutados.
- Publicada em `e8b30b1` (`feat(import): prévia de envio, parser de TXT e original imutável`). Esse commit não inclui o botão de escolher arquivo.
- Botão de arquivo, neste commit. Comando: `flutter test --reporter compact` nos quatro arquivos abaixo. Saída: `00:35 +14: All tests passed!`
  - `test/ui/chat/widgets/transcript_file_import_button_test.dart`
  - `test/ui/chat/widgets/send_confirmation_view_test.dart`
  - `test/domain/models/transcript_import_test.dart`
  - `test/data/services/transcript_import_service_test.dart`
- O `flutter test` reescreveu `analysis_options.yaml`. A alteração foi revertida com `git checkout` e não entra no próximo commit. `android/gradle.properties` não mudou.

## Evidência da F3 (2026-11-02)
- Aberta por pedido do dono, com a F0, o portão da F1 e o portão da F2 ainda abertos. A fase fica `IN_PROGRESS`. O dono aprovou o commit em 2026-11-02. O portão não fecha.
- F3-01 `DONE` no arquivo local. Esquema versão 1 em `lib/domain/models/session_report.dart`. O relatório fica em `SessionReports/<sessionId>/report.json`, fora do SQLite. A versão 0 migra; a versão 2 lança `FormatException`. Não há um objeto separado chamado Topic: sessão, trechos e itens (resumo, ideia, oportunidade, decisão, tarefa, encaminhamento, dúvida) cobrem o extrator.
- F3-02 `IN_PROGRESS`. O JSON do modelo é validado no fixture curto `00:01` / `fechar o escopo` e `00:02` / `mandar o resumo`. Trecho fora do segmento, relógio diferente e decisão dentro de brainstorm são recusados. O modelo não grava responsável, prazo nem status confirmado. Chamada real de modelo: `NOT_RUN`. Sessão real e amostra de 53 min: `NOT_RUN`.
- F3-03 `DONE` no mesmo fixture. Os seis tipos geram títulos distintos: livre, reunião, brainstorm, diário, estudo e o nome customizado `Conversa com o Rafael`. Reunião traz decisão e não traz dúvida; estudo é o inverso. O segundo item de brainstorm é oportunidade; o de reunião é encaminhamento.
- F3-04 `DONE` no fixture. Tocar a decisão `fechar o escopo` abre o trecho exato e o relógio `00:00:01`.
- F3-05 `DONE` no fixture. A tarefa chega `não confirmado`, com `não identificado` e `não informado`, mesmo se o JSON do modelo manda `approved`, `Ana` e `amanhã`. A marca de tarefa definitiva só aparece depois do toque em aprovar.
- F3-06 `DONE` no fixture. Editar o item para `enviar depois` mantém o trecho `mandar o resumo` e os bytes de `original.bin`. A busca por `fechar` esconde o outro item. Item descartado sai da busca. Item aprovado impede um rascunho novo (`StateError`) e o tipo continua `reuniao`. Excluir a sessão apaga `report.json` e a sessão, e deixa `original.bin` igual.
- Comando: `flutter test --reporter compact` nos três arquivos abaixo. Saída: `00:04 +15: All tests passed!`
  - `test/domain/models/session_report_test.dart`
  - `test/data/services/session_report_service_test.dart`
  - `test/ui/chat/widgets/session_report_view_test.dart`
- `flutter analyze` e a suíte inteira não foram reexecutados.
- Este `flutter test` reescreveu `analysis_options.yaml` de novo (`build/**`, `android/**`, `ios/**`). Revertido com `git checkout`. `android/gradle.properties` não mudou.

## Toolchain (ambiente local, fora do repo)
- Flutter em `C:\Users\notefael\tools\flutter`, fora do PATH: usar `C:\Users\notefael\tools\flutter\bin\flutter`. `flutter config --jdk-dir` aponta para `C:\Users\notefael\AppData\Local\Programs\jdk-17` (o Java 25 padrão quebra o Gradle 8.14).
- O Flutter 3.47 reescreve `analysis_options.yaml` e `android/gradle.properties` ao rodar `pub get`/build; reverter com `git checkout` antes de commitar. Usar `flutter pub get --enforce-lockfile`.
- O Gradle instalou sozinho o Android SDK Platform 34. As demais licenças do SDK seguem não aceitas.

## Última atividade
- 2026-11-02: commit do botão de TXT e da F3, aprovado pelo dono. Relatório local em arquivo, validação de JSON, tipos, trecho-fonte, confirmação, edição, busca e exclusão do derivado. Sem chamada real de modelo, sem amostra de 53 min e sem o S25.

## Próxima ação
- O portão da F3 continua aberto até o critério 6 na amostra de 53 min. F3-02 espera uma saída real de modelo. A F2 continua aberta até os critérios 1, 2 e 3 no S25; F2-03 espera um TXT real de ~50 min; F2-02 e F2-05 estão `NOT_RUN`. A F1 continua aberta por uma resposta real de OpenAI e de Gemini. A F0 continua aberta pelo S25 (D-009). O dono pediu a F4 depois deste commit. Os portões da F0, da F1, da F2 e da F3 continuam abertos.

## Bloqueios e aprovações humanas
- S25 Ultra adiado pelo dono (D-009). Sem chave de API e sem endpoint local neste ambiente. Sem TXT real de ~50 min e sem amostra de 53 min. O commit e o push de `e8b30b1` já foram feitos. O dono aprovou o commit do botão de TXT e da F3. Não emendar `e8b30b1`. O push deste commit espera um sim separado.

## Divergências entre roadmap e implementação
- A F1 começou com a F0 ainda aberta, por pedido do dono. A F2 começou com a F0 e o portão da F1 ainda abertos, também por pedido do dono. A F3 começou com a F0, a F1 e a F2 ainda abertas, pelo mesmo pedido. O S25 segue `NOT_RUN` e não foi tratado como `PASS`.
- O esquema da F3 não tem um tipo Topic separado. Os itens e as seções do relatório cobrem o extrator. O relatório é arquivo, não linha só no SQLite.
