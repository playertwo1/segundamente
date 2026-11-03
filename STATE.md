# STATE — ponto de retomada

**Atualizado:** 2026-11-03 · **Fase ativa:** F6 — Memória longitudinal · **Estado:** IN_PROGRESS

A F0 está `DONE` e seu portão FECHADO: o Galaxy S25 Ultra (SM-S938B, Android 17, serial RQCY10934YV) executou o app `app.segundamente.dev` (PID 7991), exibindo "Boas-vindas à Segunda Mente" em português (evidência em `docs/s25_screenshot.png`). A F1 continua `IN_PROGRESS`: faltam resposta real de dois provedores e o login OAuth. A F2 continua `IN_PROGRESS`: faltam o TXT real de ~50 min, voz no S25 e fotos. A F3 continua `IN_PROGRESS`: faltam a amostra de 53 min e uma resposta real de modelo. A F4 continua `IN_PROGRESS`: faltam abrir o PDF no aparelho, o DOCX no Word e a folha de compartilhamento. A F5 continua `IN_PROGRESS`: `docs/reviews/F5.md` registra `AUDIT RESULT: FAIL`. O MVP não está pronto. O portão da F6 não fecha.

## O que existe hoje (confirmado)
- Fork público `playertwo1/segundamente` de `memex-lab/memex` (Flutter, GPL-3.0). Antes deste envio, `origin/main` está em `db7bc1d`, sobre a F2 `e8b30b1` e a F1 `790e8b8`. A F4 é `969d177`. A F5 é `e1f6c9f`. Este commit é a F6. O dono aprovou o push dos três. Os portões da F3, da F4, da F5 e da F6 continuam abertos.
- No código: login OAuth de OpenAI (`lib/data/services/openai_auth_service.dart`), Gemini (`gemini_auth_service.dart`, bloqueado pelo Google, D-013) e Claude (`claude_auth_service.dart`, `67389b4`, conflita com D-005 e espera decisão, D-015). Claude por chave de API continua em `lib/domain/models/llm_config.dart`.
- Planejamento: [índice](docs/INDEX.md), [PROJECT.md](PROJECT.md), [ROADMAP.md](ROADMAP.md), [DESIGN.md](DESIGN.md), [decisões](docs/DECISIONS.md), `docs/questionario/`.
- Design visual AMOLED v3 aprovado em 2026-11-03 (D-017), com dez pranchas em `.impeccable-mobile/references/amoled-v3-ios/`. F5-04 continua `NOT_RUN`: nenhuma tela foi implementada ou validada no aparelho.

## Evidência da F0 (2026-11-02/2026-11-03; Windows 11, Flutter 3.47.9 stable, Dart 3.13.7, JDK 17, Samsung Galaxy S25 Ultra)
- F0-01 `DONE`: `git remote -v` mostra `upstream=memex-lab/memex`; commit base do Memex = `6143923e7b2237520b7143f4e5aae88822788aa4`.
- F0-02 `DONE`: `flutter build apk --debug --flavor globalDev` → `PASS` (`app-globaldev-debug.apk`, 355 MB). Executado no emulador e no Samsung Galaxy S25 Ultra (SM-S938B, Android 17, serial RQCY10934YV). O app abriu com PID 7991 na tela "Boas-vindas à Segunda Mente" (captura de tela em `docs/s25_screenshot.png`).
- `flutter analyze`: 161 issues, 0 error, 0 warning (só `info` de estilo).
- `flutter test`: 1011 passaram, 7 ignorados, 30 falharam na linha de base Windows upstream.
- F0-03 `DONE`: `aapt dump badging` do APK: `package: name='app.segundamente.dev'` e `application-label:'Segunda Mente Dev'`. `adb install` no S25 Ultra → `Success`. Execução limpa em primeiro plano.
- F0-04 `DONE`: 288 pacotes do `pubspec.lock` classificados em `docs/F0-04-licencas.md`.
- F0-05 `DONE`: nota em `docs/F0-05-modulos.md`. Voz do MVP decidida (D-007).
- F0-06 `DONE`: upstream merge executado e documentado em `docs/F0-06-upstream.md`.
- **Portão F0 FECHADO em 2026-11-03 com execução comprovada no S25 Ultra.**

## Evidência da F1 (2026-11-02)
- F1-01 `DONE`. Catálogo em `lib/domain/models/model_catalog.dart` (versão 1, um cache por provedor e base URL). Status derivado: recomendado = suportado, devolvido pela conta = acessível, id digitado = não testado. A tela de edição mostra esse status (`model_catalog_status`).
- F1-02 `IN_PROGRESS`. O teste de widget gravou o id `my-manual-model`, fora de `LLMConfig.recommendedModels`, com a base URL `https://llm.example.test/v1`. Resposta real desse modelo: `NOT_RUN`.
- F1-03 `IN_PROGRESS`. A matriz cobre texto, stream, JSON, visão e áudio. O aviso aparece quando a sonda marca uma capacidade como ausente. Sondas de texto/JSON/stream/visão/áudio passaram com um cliente falso, sem rede. Resposta real de OpenAI e de Gemini: `NOT_RUN`. 2026-11-03, S25: OpenAI por OAuth respondeu uma mensagem real no chat. Gemini por OAuth: `BLOCKED`, o Google devolve `UNSUPPORTED_CLIENT` e só oferece `standard-tier`, que exige projeto GCP próprio. Alternativa não testada: chave de API do AI Studio.
- F1-04 `DONE` para OpenAI. A nota de risco está em `docs/DECISIONS.md` (D-004). 2026-11-03, S25 (Android 17): login OAuth do ChatGPT concluído e resposta real no chat, depois das correções `e4c80b3` (retorno por `localhost`, intent-filter e serviço em segundo plano). Gemini: login conclui, mas o uso falha por `UNSUPPORTED_CLIENT` (ver F1-03).
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
- F2-02 `IN_PROGRESS`. 2026-11-03, S25: a fala pt-BR foi transcrita no microfone do chat pelo endpoint do ChatGPT (D-011). Falta a resposta em áudio (TTS do Android) e a nota de qualidade. SenseVoice não foi trocado.
- F2-03 `IN_PROGRESS`. O parser cobre relógio sozinho, `Locutor 1 00:01:02`, `화자 1 (1:05)`, `[00:02:03] Locutor 2` e intervalo `00:00:10,000 --> 00:00:14,120` (usa o início). O cabeçalho vira título. A lista de conversas tem o botão de escolher um `.txt`: a prévia mostra o texto normalizado, cancelar não grava e confirmar passa os bytes originais. O teste usou o texto curto `00:01` / `olá`. Não há um TXT real de ~50 min neste ambiente, nem execução no S25. 2026-11-03, S25: o botão de TXT está na barra de entrada do chat (`c68bbbe`). Um `.txt` do WhatsApp em UTF-16 com BOM abriu, confirmou e chegou ao agente (`3ae7ceb`, `5515855`). Falta o TXT real de ~50 min do Gravador da Samsung; sua codificação é desconhecida.
- F2-04 `DONE`. Depois de normalizar `00:01\r\n  olá  \r\n`, `original.bin` continua igual aos bytes de entrada. O texto normalizado é outro arquivo: `[00:00:01]\nolá`.
- F2-05 `NOT_RUN`. Nenhuma foto foi analisada num provedor.
- F2-08 `DONE`. 2026-11-03, S25: o botão "+" do chat reúne câmera, galeria, TXT, PDF e áudio, sem faixa de fotos recentes (`513ee30`). PDF: o ChatGPT por OAuth leu o arquivo (`input_file`).
- F2-09 `IN_PROGRESS`. O canal de chat do ChatGPT nunca recebe áudio (`400 Audio input is not available`, D-011). O áudio anexado ou gravado é transcrito por `POST chatgpt.com/backend-api/transcribe` com o token do OAuth e só o texto vai ao modelo (`bb5b807`, `05582e5`). Testado com curl e em áudio pt-BR curto. Falta um `.m4a` real de 1 a 2 min no S25, depois ~50 min; limite de tamanho e duração desconhecido.
- F2-10 `IN_PROGRESS`. Compartilhar TXT abre o chat com o texto (validado no S25). PDF e áudio compartilhados: `NOT_RUN`.
- F1-07 `IN_PROGRESS`. `gpt-6-luna`, `gpt-6.1-sol` e `gpt-6.1-terra` entram sempre na lista do OAuth da OpenAI; `gpt-6-luna` respondeu `400` só por causa do áudio, o resto não foi confirmado. Os IDs são `NOT_RUN`.
- F1-08 `BLOCKED`. Decisão do dono sobre o login OAuth do Claude (D-015).
- O app ficou só em inglês e português (D-012, `73feb20`). O último APK instalado no S25 não é o do commit `513ee30`: o aparelho estava desconectado.
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
- Publicada no commit `db7bc1d` (`feat(report): relatório local e escolha de TXT`), enviado a `origin/main`. Não emendar `e8b30b1` nem `db7bc1d`.

## Evidência da F4 (2026-11-02)
- Aberta por pedido do dono, com a F0, a F1, a F2 e a F3 ainda abertas. A fase fica `IN_PROGRESS`. Publicada no commit local `969d177` (`feat(export): relatório em Markdown, PDF e DOCX`). Esse commit não foi enviado. O portão não fecha.
- F4-01 `DONE` no fixture. O Markdown traz título `Relatório de reunião`, data `2026-11-02 15:04`, seções `Decisões` e `Tarefas`, fonte e relógio. Item descartado fica de fora do arquivo completo.
- F4-02 `IN_PROGRESS`. O PDF começa com `%PDF-1.4`, usa WinAnsi e contém `Decisões`, `não identificado`, `Relógio` e `ação`. Um relatório longo ocupa duas páginas. Aberto no aparelho: `NOT_RUN`. Um caractere fora do Latin-1 vira `?` só no PDF.
- F4-03 `IN_PROGRESS`. O DOCX guarda o mesmo texto em `word/document.xml`. Aberto no Word ou no Docs: `NOT_RUN`.
- F4-04 `IN_PROGRESS`. Desmarcar um item exporta só o outro. Os três arquivos nascem ao lado de `report.json` e somem quando a sessão é excluída. `original.bin` não muda. O botão chama a folha de compartilhamento do Android pelo `share_plus`, sem envio para um serviço nosso. Essa folha no aparelho: `NOT_RUN`.
- Comando: `flutter test --reporter compact` nos três arquivos abaixo. Saída: `00:07 +15: All tests passed!`
  - `test/domain/models/session_report_export_test.dart`
  - `test/data/services/session_report_service_test.dart`
  - `test/ui/chat/widgets/session_report_view_test.dart`
- `flutter analyze` e a suíte inteira não foram reexecutados.
- Este `flutter test` reescreveu `analysis_options.yaml` de novo. Revertido com `git checkout`. `android/gradle.properties` não mudou.

## Evidência da F5 (2026-11-02)
- Aberta por pedido do dono, com a F0, a F1, a F2, a F3 e a F4 ainda abertas. A fase fica `IN_PROGRESS`. Publicada no commit local `e1f6c9f` (`feat(audit): log sem token e medição do fechamento`). Esse commit não foi enviado. O portão não fecha.
- F5-01 `IN_PROGRESS`. Checklist dos 7 critérios em `docs/F5-01-checklist.md`. Cada critério no S25 Ultra está `NOT_RUN`.
- F5-02 `IN_PROGRESS`. Nota em `docs/F5-02-privacidade.md`. O log de sucesso da OpenAI não imprime mais access token, refresh token nem ID token. A falha dedicada da troca de código, na OpenAI e no Gemini, registra só o status HTTP. O `catch` ainda grava a exceção. O teste `openai_auth_log_test.dart` recusa `${tokenResponse.body}` e `${response.body}` e ainda exige `jsonDecode(tokenResponse.body)`. Tokens e `apiKey` continuam em `SharedPreferences`. Uma passagem sem histórico corrigiu a frase que punha a `apiKey` do Gemini no cabeçalho: nessa lista de modelos a chave vai na query `key=`.
- F5-03 `IN_PROGRESS`. Nota em `docs/F5-03-medicoes.md`. Fixture sintético de 1500 segmentos (50 min, um a cada 2 s): parse 15 ms. Exportação de 100 itens nos três formatos: 25 ms. Não é o TXT do Samsung. A lista de histórico e o aparelho estão `NOT_RUN`. Nenhum código de desempenho foi mudado.
- F5-04 `NOT_RUN`. Direção aprovada em D-017 e `DESIGN.md`; as pranchas estão em `.impeccable-mobile/references/amoled-v3-ios/`. Sem mudança visual no app, capturas antes/depois ou validação de acessibilidade.
- F5-05 `IN_PROGRESS`. `docs/reviews/F5.md` termina em `AUDIT RESULT: FAIL` por causa do S25 e do armazenamento em claro. Atribuições de licença continuam em `docs/F0-04-licencas.md`. Não há `LicensePage` em `lib/`.
- Comando: `flutter test --reporter expanded` nos dois arquivos abaixo. Saída: `F5-03 parse_ms=15 segments=1500`, `F5-03 export_ms=25 items=100`, `00:00 +3: All tests passed!`
  - `test/data/services/openai_auth_log_test.dart`
  - `test/domain/models/f5_measurements_test.dart`
- `flutter analyze` e a suíte inteira não foram reexecutados.
- Este `flutter test` reescreveu `analysis_options.yaml` de novo. Revertido com `git checkout`. `android/gradle.properties` não mudou.

## Evidência da F6 (2026-11-02)
- Aberta por pedido do dono, com a F0, a F1, a F2, a F3, a F4 e a F5 ainda abertas (D-010). A fase fica `IN_PROGRESS`. Este é o commit da F6. O portão não fecha. A F7 não começou.
- F6-01 `IN_PROGRESS`. A busca `escopo` acha o item da sessão do relatório e não acha o item descartado nem o texto da outra sessão. É busca de texto local. Busca semântica: `NOT_RUN`.
- F6-02 `IN_PROGRESS`. O painel lista só o encaminhamento aprovado `mandar o resumo`. O botão está na lista de conversas. No aparelho: `NOT_RUN`.
- F6-03 `IN_PROGRESS`. Editar o texto grava `revisions.json` ao lado de `report.json`: de `fechar o escopo` para `fechar depois`. Trocar só o responsável não cria revisão. Excluir a sessão apaga `revisions.json` e deixa `original.bin`. O "por quê" não é gerado: `NOT_RUN`.
- F6-04 `NOT_RUN`. Não há entidade de tópico nem de projeto. As seções do relatório continuam sendo o agrupamento.
- Comando: `flutter test --reporter expanded` nos três arquivos abaixo. Saída: `00:05 +11: All tests passed!`
  - `test/domain/models/report_memory_test.dart`
  - `test/data/services/session_report_service_test.dart`
  - `test/ui/chat/widgets/follow_ups_view_test.dart`
- `flutter analyze` e a suíte inteira não foram reexecutados.
- Este `flutter test` reescreveu `analysis_options.yaml` de novo. Revertido com `git checkout`. `android/gradle.properties` não mudou.

## Toolchain (ambiente local, fora do repo)
- Flutter em `C:\Users\notefael\tools\flutter`, fora do PATH: usar `C:\Users\notefael\tools\flutter\bin\flutter`. `flutter config --jdk-dir` aponta para `C:\Users\notefael\AppData\Local\Programs\jdk-17` (o Java 25 padrão quebra o Gradle 8.14).
- O Flutter 3.47 reescreve `analysis_options.yaml` e `android/gradle.properties` ao rodar `pub get`/build; reverter com `git checkout` antes de commitar. Usar `flutter pub get --enforce-lockfile`.
- O Gradle instalou sozinho o Android SDK Platform 34. As demais licenças do SDK seguem não aceitas.

## Última atividade
- 2026-11-03: roadmap detalhado com F1-07/08, F2-08 a F2-10 e F6-05 a F6-08 (ideias do Memos, D-014); ideias do Daedalus Echo em F2-11, F3-07 e F6-09 a F6-11 (D-016, `ec80d43`). Decisões D-011 a D-016 em `docs/DECISIONS.md`. Nenhuma dessas tarefas novas tem código.
- 2026-11-02: o dono pediu commit e push da F4, da F5 e da F6 (busca de texto, painel de encaminhamentos aprovados e `revisions.json`). Semântica, tópicos e o "por quê" continuam `NOT_RUN`.

## Próxima ação
- Validar o áudio no S25 (F2-09): `.m4a` curto, depois ~50 min. Depois, o TXT real de ~50 min do Samsung (F2-03), o compartilhamento de PDF e áudio (F2-10), os IDs GPT-6 (F1-07) e a decisão D-015. Ordem sugerida das novas: F3-07, F2-11, F6-11, F6-09; F6-08, F6-05, F6-06, F6-07.
- O portão da F6 continua aberto. Semântica, tópicos e o "por quê" continuam `NOT_RUN`. A F5 continua aberta (`AUDIT RESULT: FAIL`). A F4 continua aberta até o PDF no aparelho, o DOCX no Word e a folha de compartilhamento. A F3 continua aberta até a amostra de 53 min e uma saída real de modelo. A F2 continua aberta até os critérios 1, 2 e 3 no S25; F2-03 espera um TXT real de ~50 min; F2-02 e F2-05 estão `NOT_RUN`. A F1 continua aberta por uma resposta real de OpenAI e de Gemini. A F0 continua aberta pelo S25 (D-009). Não começar a F7.

## Bloqueios e aprovações humanas
- S25 Ultra adiado pelo dono (D-009). Sem chave de API e sem endpoint local neste ambiente. Sem TXT real de ~50 min e sem amostra de 53 min. O commit e o push de `e8b30b1` e de `db7bc1d` já foram feitos. O dono aprovou o commit e o push de `969d177`, de `e1f6c9f` e deste commit da F6. Não emendar `e8b30b1`, `db7bc1d`, `969d177` nem `e1f6c9f`.

## Divergências entre roadmap e implementação
- A F1 começou com a F0 ainda aberta, por pedido do dono. A F2 começou com a F0 e o portão da F1 ainda abertos, também por pedido do dono. A F3 começou com a F0, a F1 e a F2 ainda abertas, pelo mesmo pedido. A F4 começou com esses portões e o da F3 ainda abertos. A F5 começou com esses portões e o da F4 ainda abertos. A F6 começou com esses portões e o da F5 ainda abertos (D-010). O S25 segue `NOT_RUN` e não foi tratado como `PASS`.
- O esquema da F3 não tem um tipo Topic separado. Os itens e as seções do relatório cobrem o extrator. O relatório é arquivo, não linha só no SQLite.
