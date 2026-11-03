# Decisões (ADR leve)

Só escolhas caras de desfazer ou que outro agente poderia contestar. Nova decisão = próximo número. Decisão substituída não é apagada: marcar `SUPERSEDED` e apontar a nova. Registro completo das perguntas: [questionario/2026-11-02-segunda-memoria.md](questionario/2026-11-02-segunda-memoria.md).

| ID | Data | Assunto | Estado |
|---|---|---|---|
| D-001 | 2026-11-02 | Base: fork do Memex (Flutter) com F0 como portão | ACCEPTED |
| D-002 | 2026-11-02 | MVP = escopo "Prioridade atual"; full duplex, NotebookLM, grafo, ponte CLI fora | ACCEPTED |
| D-003 | 2026-11-02 | Fases F0–F5 (MVP) e F6–F8 (futuro bloqueado) | ACCEPTED |
| D-004 | 2026-11-02 | Provedores: OpenAI e Gemini via OAuth existente; Claude por chave de API opcional | ACCEPTED |
| D-005 | 2026-11-02 | Sem login Claude.ai por assinatura (termos da Anthropic); só via Claude Code oficial no PC (F7) | ACCEPTED |
| D-006 | 2026-11-02 | Nome do app e applicationId: "Segunda Mente" | ACCEPTED |
| D-007 | 2026-11-02 | Voz do MVP: STT na nuvem pelo modelo configurado; TTS do Android na F2; SenseVoice não cobre pt-BR | ACCEPTED |
| D-008 | 2026-11-02 | Docs de planejamento vivem na `main` do fork; só os arquivos úteis do kit ideias_standard | ACCEPTED |
| D-009 | 2026-11-02 | Até o S25 Ultra estar conectado, o emulador é o aparelho de prova da F0 | ACCEPTED |
| D-010 | 2026-11-02 | A F6 pode começar com os portões da F0 à F5 ainda abertos | ACCEPTED |
| D-011 | 2026-11-03 | Áudio: transcrição pelo endpoint do ChatGPT; o canal de chat nunca recebe áudio | ACCEPTED |
| D-012 | 2026-11-03 | O app tem só inglês e português | ACCEPTED |
| D-013 | 2026-11-03 | Gemini por OAuth bloqueado pelo Google; não usar credenciais nem identidade de outro produto | ACCEPTED |
| D-014 | 2026-11-03 | Ideias do Memos: quatro entram na F6 (F6-05 a F6-08); o resto fica fora | ACCEPTED |
| D-015 | 2026-11-03 | Login OAuth do Claude entrou no código e conflita com D-005 | PROPOSED |
| D-016 | 2026-11-03 | Ideias do Daedalus Echo: Whisper local multilíngue, extrator de tarefas robusto, recuperação por tópicos, agenda; o resto fica fora | ACCEPTED |

## D-001 — Base: fork do Memex
- Contexto: Memex já traz diário/chat, banco local (Drift/SQLite), provedores e OAuth. Licença GPL-3.0.
- Decisão e motivo: usar o fork; app pessoal, então a GPL só pesa se distribuir o APK. Se build, licença ou teste no S25 falharem, reavaliar.
- Descartado: comparar 3 bases antes; app novo do zero.

## D-004 / D-005 — Autenticação
- Contexto: o usuário não usa chave de API. O fork reaproveita o `client_id` dos CLIs oficiais (Codex e Gemini) para OAuth.
- Decisão e motivo: manter esses dois logins no MVP, com risco registrado (podem quebrar ou violar termos; testar na F1-04). A Anthropic não permite login Claude.ai em apps de terceiros (code.claude.com/docs/en/legal-and-compliance, lido em 2026-11-02), então Claude fica com chave de API opcional.
- Descartado: fluxo próprio de login Claude.ai.
- Risco de termos, registrado na F1-04 em 2026-11-02: o login da OpenAI é PKCE com o client_id público do Codex CLI (`app_EMoamEEZ73f0CkXaXp7hrann`), emissor `https://auth.openai.com` e redirect `http://localhost:1455/auth/callback`. O do Gemini usa o client do Gemini CLI e o redirect `http://localhost:8085/oauth2callback`. Esses clientes pertencem aos CLIs oficiais. A OpenAI e o Google podem revogar o fluxo, trocar o client ou tratar o uso fora do CLI como fora dos termos. A Segunda Mente não tem um client OAuth próprio. Se o login quebrar, a alternativa do MVP é chave de API.
- `gemini_auth_service.dart` também traz um client secret. Esse valor não entra em documento, log, estado nem chat.
- O login em si não foi executado, nem no emulador nem no S25. Esta nota não prova que o login funciona.

## D-007 — Voz do MVP
- Contexto: o fork tem STT local por sherpa-onnx (SenseVoice zh/en/ja/ko/yue) e STT na nuvem, que envia o áudio ao modelo configurado. Não há TTS.
- Decisão e motivo: no MVP, a fala em português usa a transcrição na nuvem (`SpeechTranscriptionService`), no modelo que o usuário já escolheu. A resposta em áudio, opcional, usa o TTS do Android na F2-02. O modelo local SenseVoice fica disponível, mas não é o caminho do pt-BR.
- Descartado: trocar o SenseVoice por outro modelo nesta fase; voz full duplex (continua na F7).

## D-006 — Identidade de instalação
- Decisão e motivo: o app se chama Segunda Mente. Os `applicationId` passam a ser `app.segundamente`, `app.segundamente.cn`, `app.segundamente.early`, `app.segundamente.cn.early`, `app.segundamente.dev` e `app.segundamente.cn.dev`.
- O namespace Kotlin e os method channels continuam `com.memexlab.memex`. Eles identificam código nativo, não o pacote instalado. Renomeá-los fica fora da F0-03.
- Assinatura de debug usa o keystore de debug do Android SDK, fora do repositório. `android/key-*.properties`, `*.jks` e `*.keystore` já estão no `.gitignore` e não há nenhum desses arquivos versionado. Keystore de release não foi criado.

## D-009 — Emulador até o S25
- Contexto: a F0-02 pedia execução no Galaxy S25 Ultra. Em 2026-11-02 o dono pediu para usar só o emulador por enquanto.
- Decisão e motivo: enquanto o S25 não estiver conectado, `emulator-5554` é o aparelho de prova das subfases da F0. A execução no S25 fica `NOT_RUN`. Os critérios de aceite do MVP continuam no S25. A fase F0 não se declara concluída sem essa execução, ou sem uma decisão nova.
- Descartado: parar a F0 até o telefone aparecer.

## D-010 — Abrir a F6 antes do MVP
- Contexto: D-003 deixa a F6 bloqueada até o MVP. Em 2026-11-02 o dono pediu para avançar depois dos commits da F4 e da F5.
- Decisão e motivo: a F6 pode começar. O MVP não fecha. D-003 continua valendo para o que é o MVP e para manter a F7 e a F8 bloqueadas. Busca semântica, tópicos e o "por quê" não entram sem um modelo. A busca deste passo é texto local nos relatórios.
- Descartado: marcar o MVP como pronto para desbloquear a fase.


## D-011 — Áudio pelo ChatGPT
- Contexto: em 2026-11-03, no S25, o canal `chatgpt.com/backend-api/codex` respondeu `400 Audio input is not available` com `gpt-5.6-sol` e com `gpt-6-luna`. Um áudio gravado no histórico da conversa repetia o erro em todas as chamadas seguintes.
- Decisão e motivo: o canal de chat nunca recebe áudio (`CodexResponsesClient` troca por uma nota de texto). A transcrição usa `POST chatgpt.com/backend-api/transcribe` com o mesmo token do OAuth, e só o texto vai ao modelo. Testado em 2026-11-03 com um áudio pt-BR sintético: devolveu a frase correta. Isso cumpre D-007 (STT na nuvem pelo modelo configurado) sem depender do SenseVoice.
- Risco: o endpoint não é documentado e pode mudar ou ser bloqueado. Duração e tamanho máximos não foram medidos; a gravação de ~50 min é `NOT_RUN`.
- Descartado: enviar o áudio no canal de chat; chave de API do Gemini só para áudio (fica como reserva se o endpoint cair).

## D-012 — Idiomas
- Decisão e motivo: o app tem só inglês (`en`) e português (`pt`). As outras 16 línguas, incluindo o chinês, saíram do código, das galerias de cartão e dos testes (commit `73feb20`). Texto em outro idioma cai no inglês. Pedido do dono, que usa só pt-BR.
- As buscas de local pedem nomes no idioma do app, e não mais em chinês.
- Descartado: manter as demais línguas como reserva.

## D-013 — Gemini por OAuth
- Contexto: `loadCodeAssist` devolveu `UNSUPPORTED_CLIENT` para o client_id do Gemini CLI e só oferece `standard-tier`, que exige projeto GCP próprio. A conta é Google AI Pro, sem projeto.
- Decisão e motivo: Gemini por OAuth fica `BLOCKED`. Não usar o Client ID e o Secret do Antigravity nem se identificar como `ideType=ANTIGRAVITY`: é credencial de outro produto num repositório público e contorna um bloqueio deliberado do Google. O GitHub também barrou o push por proteção de segredos. Esse trabalho está só na branch local `wip-gemini-antigravity`.
- Alternativa não testada: chave de API do AI Studio.

## D-014 — Ideias do Memos
- Contexto: `usememos/memos` (MIT, Go e React, self-hosted, 64 mil estrelas) foi comparado com o app em 2026-11-03. Só o README, o CONTEXT.md e os arquivos `.proto` foram lidos.
- Decisão e motivo: entram na F6 quatro ideias que cabem no produto local de uma pessoa: tags hierárquicas (F6-05), filtros por propriedade e visões salvas (F6-06), prévia de links (F6-07) e mapa de atividade (F6-08). Só as ideias são aproveitadas, nenhum código.
- Fora: espaços e colaboração, comentários, reações, links públicos, vários usuários, servidor/Docker/API/webhooks/MCP, Web Clipper e bot do Telegram (o Compartilhar do Android cobre o mesmo uso). Biblioteca de anexos fica em Ideias futuras.

## D-015 — Login OAuth do Claude (pendente)
- Contexto: o commit `67389b4` trouxe `claude_auth_service.dart` e `typeClaudeOauth`, feitos por outro processo. D-005 diz que não haverá login Claude.ai por assinatura em app de terceiros, por causa dos termos da Anthropic.
- Decisão necessária do dono: remover o login, ou revogar D-005 com a leitura atual dos termos. Enquanto isso ele não faz parte do MVP e não deve ser usado.

## D-016 — Ideias do Daedalus Echo
- Contexto: `DaedalusApps/daedalus-echo` (MIT, Kotlin e Compose, 12 estrelas, último push em 2026-08-25) é um gravador 100% local: Whisper por sherpa-onnx, Gemma 3 1B por MediaPipe, embeddings com Universal Sentence Encoder, busca por significado, tarefas extraídas e mapa de tópicos. Foram lidos o README, o CHANGELOG, `ModelConfig.kt`, `TranscriptionService.kt`, `EmbeddingService.kt`, `GraphRetrieval.kt`, `TodoExtraction.kt` e `CalendarIntegration.kt`. Nada foi executado.
- Decisão e motivo: entram só ideias, nenhum código (outra linguagem e outra arquitetura). Entram: Whisper multilíngue local (F2-11), extrator de tarefas robusto com deduplicação (F3-07), recuperação por tópicos com piso de relevância (F6-09) e "adicionar à agenda" (F6-11). Os embeddings no aparelho ficam como F6-10 `BACKLOG`.
- Cuidado que o Echo mostra: o Whisper dele é `base.en`, só inglês, com o idioma fixo em `en`, e o Universal Sentence Encoder é centrado em inglês. Para português é preciso um modelo Whisper multilíngue e um embedder que cubra português. Nenhum dos dois foi medido.
- Fora do MVP: Gemma 3 1B local (555 MB, qualidade em pt-BR desconhecida; fica na F7 com Ollama), conversa por voz mãos-livres (F7), mapa global de tópicos (Ideias futuras).
- Descartado: copiar a arquitetura offline total. O nosso produto usa o modelo que o dono escolheu (D-002, D-004).