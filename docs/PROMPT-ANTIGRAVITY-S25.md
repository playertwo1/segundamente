# Prompt para o Antigravity: continuar os testes no S25

Cole o texto abaixo no Antigravity.

---

Você continua a validação no celular do projeto **Segunda Mente** (fork do Memex, Flutter), em `C:\Users\notefael\projetos\segundamente`. Leia primeiro `AGENTS.md` (seção "Segunda Mente (fork)"), `STATE.md`, `ROADMAP.md` e `docs/TESTE-NO-S25-2026-11-04.md` (o roteiro e os resultados já registrados). Responda ao dono em português.

## Ambiente

- Aparelho: Galaxy S25 Ultra, serial `RQCY10934YV`, pacote `app.segundamente.dev`, flavor `globalDev`. Use só o aparelho. O emulador fica desligado.
- adb: `C:\Users\notefael\AppData\Local\Android\Sdk\platform-tools` (no Git Bash: `export MSYS_NO_PATHCONV=1` antes de usar caminhos `/sdcard`).
- Flutter: `C:\Users\notefael\tools\flutter\bin` (não está no PATH; ponha na frente do PATH).
- Build e instalação: `flutter build apk --debug --flavor globalDev`, depois `adb -s RQCY10934YV install -r build/app/outputs/flutter-apk/app-globaldev-debug.apk`. O build reescreve `analysis_options.yaml` e `android/gradle.properties`: desfaça com `git checkout -- analysis_options.yaml android/gradle.properties`.
- O APK instalado já tem as correções até o commit `28380eb`.

## Como dirigir a tela, gastando pouco

- Prefira texto a imagem: `adb shell uiautomator dump /sdcard/ui.xml`, leia por `adb exec-out cat` e extraia `text`/`content-desc` e `bounds`. Os `bounds` do dump já são pixels reais e servem direto no `adb shell input tap X Y`.
- Em screenshot, a imagem exibida é menor que a real: multiplique por 1,21. Use screenshot só para conferir visual.
- A busca do seletor de arquivos do Android demora uns 10 s para filtrar. Espere e confira com dump antes de tocar.
- Para ler ou escrever arquivos do app: `adb shell run-as app.segundamente.dev ...`.
- No chat principal (card "Conversar com a Segunda Mente" na tela inicial), o "+" tem descrição "Anexar": abre Câmera, Galeria, Importar transcrição, PDF, Áudio. O botão "Conversar" da barra de cima abre o chat do "Advogado do diabo", que é outro agente.

## Regras

- Commits só locais. Nunca `git push`.
- Não use `git add lib test` nem `git add .`: o dono tem arquivos modificados que não são seus (por exemplo `lib/domain/models/event_bus_message.dart`, `llm_config.dart`, `model_catalog.dart`, `voice_dictation_viewmodel.dart`, `memex_router.dart`, `session_report_service.dart`, `report_memory.dart` e a pasta `mako/`). Adicione só os arquivos que você mudou.
- Texto enviado a modelo (ChatGPT por OAuth, já configurado no aparelho) só com texto inventado. Cada turno de chat que dispara a pesquisa pesada custou ~1,5 milhão de tokens de entrada: evite repetir e prefira passos que não enviam nada ao modelo (pare na tela de revisão e toque em Voltar).
- Não peça PIN nem senha de entrada ao app: o dono não quer bloqueio.
- Mudança de comportamento leva teste na mesma entrega (unitário, de widget ou de cadeia, conforme o `AGENTS.md`). Escreva o código no estilo do entorno.
- Pare e avise o dono só quando faltar uma ação humana de verdade (login real, amostra real, aprovação).

## O que falta testar (nesta ordem)

1. **Seção 6, "Adicionar à agenda"**: num relatório com item aprovado em Encaminhamentos, editar a data de vencimento para algo como `20/11/2026`, confirmar o item, ver o ícone de calendário e a intent de inserir no calendário do sistema (cancele a inserção, não salve evento).
2. **Seção 12, prévia de link**: ligar e desligar a opção com um cartão que tenha link e conferir o comportamento.
3. **Seção 9, visões salvas**: concluir uma tarefa e reabrir a visão; conferir as visões "Tem link" e "Tem código".
4. **Seções 8.4 e 8.5, tópicos**: renomear e apagar um tópico; apagar uma sessão e conferir que ela sai do tópico.
5. **F6-09, expansão por tópico**: duas sessões ligadas ao mesmo tópico; perguntar no chat por algo que só está na sessão irmã. Só faça isso se aceitar o custo de um turno de chat.
6. **Seção 1, telas redesenhadas**: passada visual curta.

Os dados de teste que já estão no aparelho (cartão "Reunião do projeto Clientes", documento `PKM/Projects/Clientes/Decisões e acompanhamentos.md`, a sessão importada, o tópico "Clientes", a visão "Pendencias", o termo "Marina", arquivos `teste_legenda.srt/.vtt` em Download) podem ser reaproveitados.

## Entrega

- Para cada item: faça, confira na tela, e se achar defeito, ache a causa, corrija com teste e confirme de novo no aparelho.
- Registre o resultado de cada item no fim de `docs/TESTE-NO-S25-2026-11-04.md` (tabela "Resultado", com o que você viu, não o que esperava) e atualize `ROADMAP.md`/`STATE.md` só se o status de uma tarefa mudar de verdade.
- Um commit local por correção e um por rodada de registro.
- No fim, diga ao dono: o que passou, o que falhou, o que ficou sem testar e por quê, e os commits criados. Não marque `DONE` o que você não viu funcionando.
