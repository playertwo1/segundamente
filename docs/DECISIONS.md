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
| D-007 | 2026-11-02 | Voz (STT/TTS): decidir na F0-05 após auditar o fork | PROPOSED |
| D-008 | 2026-11-02 | Docs de planejamento vivem na `main` do fork; só os arquivos úteis do kit ideias_standard | ACCEPTED |
| D-009 | 2026-11-02 | Até o S25 Ultra estar conectado, o emulador é o aparelho de prova da F0 | ACCEPTED |

## D-001 — Base: fork do Memex
- Contexto: Memex já traz diário/chat, banco local (Drift/SQLite), provedores e OAuth. Licença GPL-3.0.
- Decisão e motivo: usar o fork; app pessoal, então a GPL só pesa se distribuir o APK. Se build, licença ou teste no S25 falharem, reavaliar.
- Descartado: comparar 3 bases antes; app novo do zero.

## D-004 / D-005 — Autenticação
- Contexto: o usuário não usa chave de API. O fork reaproveita o `client_id` dos CLIs oficiais (Codex e Gemini) para OAuth.
- Decisão e motivo: manter esses dois logins no MVP, com risco registrado (podem quebrar ou violar termos; testar na F1-04). A Anthropic não permite login Claude.ai em apps de terceiros (code.claude.com/docs/en/legal-and-compliance, lido em 2026-11-02), então Claude fica com chave de API opcional.
- Descartado: fluxo próprio de login Claude.ai.

## D-006 — Identidade de instalação
- Decisão e motivo: o app se chama Segunda Mente. Os `applicationId` passam a ser `app.segundamente`, `app.segundamente.cn`, `app.segundamente.early`, `app.segundamente.cn.early`, `app.segundamente.dev` e `app.segundamente.cn.dev`.
- O namespace Kotlin e os method channels continuam `com.memexlab.memex`. Eles identificam código nativo, não o pacote instalado. Renomeá-los fica fora da F0-03.
- Assinatura de debug usa o keystore de debug do Android SDK, fora do repositório. `android/key-*.properties`, `*.jks` e `*.keystore` já estão no `.gitignore` e não há nenhum desses arquivos versionado. Keystore de release não foi criado.

## D-009 — Emulador até o S25
- Contexto: a F0-02 pedia execução no Galaxy S25 Ultra. Em 2026-11-02 o dono pediu para usar só o emulador por enquanto.
- Decisão e motivo: enquanto o S25 não estiver conectado, `emulator-5554` é o aparelho de prova das subfases da F0. A execução no S25 fica `NOT_RUN`. Os critérios de aceite do MVP continuam no S25. A fase F0 não se declara concluída sem essa execução, ou sem uma decisão nova.
- Descartado: parar a F0 até o telefone aparecer.
