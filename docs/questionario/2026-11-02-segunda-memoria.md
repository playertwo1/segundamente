# Segunda Memória — escopo e roadmap
Status: concluído (aguardando confirmação do usuário) · Início: 2026-11-02
Objetivo: decidir escopo, base técnica e estrutura de fases/subfases do fork Android do Memex, usando o kit ideias_standard como esqueleto.

Fonte: documento "Segunda Memória — Visão, GitHub e Roadmap" (02/11/2026). Seção "Prioridade atual — MVP do fork Memex" prevalece sobre o resto.

## Decisões
### D1 - Pasta do projeto
- Pergunta: onde criar o projeto e guardar o registro?
- Decisão: `C:\Users\notefael\projetos\segunda-memoria`, esqueleto criado com `scripts/init.py` do ideias_standard.
- Por quê: junto dos demais projetos; o kit já entrega PROJECT/ROADMAP/STATE/AGENTS.
- Descartado: outra pasta.
- Difícil de reverter: não

### D2 - Base técnica
- Pergunta: fork do Memex (Flutter) com Fase 0 como portão?
- Decisão: sim. Fase 0 = build limpo, auditoria de licença (GPL-3.0) e módulos, teste no S25 Ultra; falhou → reavaliar.
- Por quê: Seção 14 do doc; app pessoal, GPL só pesa se distribuir o APK.
- Descartado: comparar 3 bases antes (lento); app novo do zero.
- Difícil de reverter: sim

### D3 - Escopo do MVP
- Pergunta: MVP = "Prioridade atual" do doc?
- Decisão: sim. Dentro: chat texto, voz em turnos (falar → transcrever → IA → áudio opcional), TXT Samsung + fotos, registro de modelos, relatórios por sessão, exportação PDF/DOCX/MD, histórico local. Fora: voz full duplex, NotebookLM, grafo temporal (Graphiti), ponte Claude Code/Codex CLI, memória longitudinal avançada.
- Por quê: app realmente usável primeiro; regra do doc de não acrescentar integrações antes do ponta a ponta.
- Descartado: reduzir ou ampliar o escopo.
- Difícil de reverter: não

### D4 - Estrutura de fases
- Pergunta: roadmap segue as 6 etapas do doc?
- Decisão: F0 Fundação (fork, build, auditoria) · F1 Registro de modelos · F2 Chat, voz e importação · F3 Extração e relatório · F4 Exportação · F5 Testes no S25, privacidade e polimento. Futuro (bloqueadas): F6 memória longitudinal · F7 voz contínua e ponte CLI · F8 NotebookLM. Cada fase tem subfases com ID, estado e evidência exigida (formato do kit).
- Por quê: espelha a ordem de execução do doc; sem overengineering.
- Descartado: reordenar/juntar fases.
- Difícil de reverter: não

### D5 - Repositório do fork
- Decisão: fork já criado pelo usuário: https://github.com/playertwo1/segundamente (público, GPL-3.0, parent memex-lab/memex, branch main). O esqueleto do kit (ideias_standard) vive no repo de planejamento local `projetos/segunda-memoria`; ainda a decidir se os docs do kit vão para dentro do fork (ver Em aberto).
- Difícil de reverter: não

### D6 - Autenticação dos provedores
- Pergunta: com quais provedores testar?
- Decisão: sem chave de API; usar OAuth (login na conta). Fato verificado no fork: `openai_auth_service.dart` (fluxo do Codex CLI, login ChatGPT) e `gemini_auth_service.dart` (fluxo do Gemini CLI) já existem; Claude só tem "API Key" (`llm_config.dart`).
- Riscos: ambos reutilizam o client_id de CLIs de terceiros (podem quebrar ou violar termos); o doc alerta para não tratar assinatura de chat como chave de API.
- Fato verificado (code.claude.com/docs/en/legal-and-compliance, 2026-11-02): a Anthropic não permite que apps de terceiros ofereçam login Claude.ai nem roteiem requisições por credenciais de assinatura Free/Pro/Max; desenvolvedores devem usar chave de API. Usuário pediu "Claude por assinatura"; conflita com os termos → ver D7.
- Difícil de reverter: não

### D7 - Claude no MVP
- Decisão: MVP testa com OpenAI e Gemini via OAuth (já existentes no fork). Claude = chave de API opcional. Uso por assinatura só na F7, via Claude Code oficial não modificado no PC.
- Por quê: termos da Anthropic proíbem login de assinatura em apps de terceiros.
- Descartado: fluxo próprio de login Claude.ai; Claude fora por completo.
- Risco aceito: OAuth OpenAI/Gemini reutiliza client_id dos CLIs oficiais; F1 deve testar se segue funcionando e registrar o risco.
- Difícil de reverter: não

### D8 - Onde vivem os docs do kit
- Decisão: dentro do fork `segundamente`, na `main`. Só o que for útil do kit (curadoria minha, a confirmar); o resto do kit não entra. A pasta `projetos/segunda-memoria` (kit completo do init.py) passa a ser só rascunho do questionário.
- Nota: não achei clone local do fork em `C:\Users\notefael\projetos` (só um clone temporário meu). Ao executar, clonar em `projetos/segundamente`, salvo se o usuário indicar onde já está.
- Difícil de reverter: não

### D9 - Voz (STT/TTS)
- Decisão: decidir na F0 depois de auditar o que o fork já faz (código de voz do Memex); sem escolha prévia.
- Difícil de reverter: não

### D10 - Privacidade (herdada do doc, sem pergunta)
- Local-first; envio a provedor remoto só com escolha explícita e prévia do conteúdo; nada de conteúdo corporativo confidencial sem autorização; nada de tarefa/decisão automática sem confirmação.

### D11 - Nome
- Decisão: app e applicationId = "Segunda Mente" (ex.: `app.segundamente`), sem colidir com o Memex. "Segunda Memória" fica como nome do projeto no doc.
- Difícil de reverter: não

## Em aberto
- Voz (STT/TTS): decidir na F0 após auditar o fork.
- Claude: chave de API opcional; ponte por assinatura só na F7.
- Risco do OAuth reaproveitado dos CLIs (OpenAI/Gemini): testar e registrar na F1.
- Assinatura/applicationId/keystore próprios: gerar na F0.
- Memória longitudinal, NotebookLM, voz full duplex: fora do MVP (F6–F8).

## Próximos passos (após confirmação do usuário)
1. Clonar o fork em `projetos/segundamente` (ou usar o clone que o usuário indicar).
2. Levar para a `main` do fork só: `PROJECT.md`, `ROADMAP.md` (F0–F8 em subfases com ID, estado e evidência), `STATE.md`, `docs/DECISIONS.md` (D1–D11), `docs/WATCHDOG.md`, `docs/AUDIT.md`, `docs/questionario/`. Não levar: DESIGN.md, templates, release checklist, CHANGELOG, README, .editorconfig. `AGENTS.md`/`CLAUDE.md` do Memex: acrescentar seção curta apontando para STATE/ROADMAP, sem substituir.
3. Commit na `main` do fork (só mediante ok do usuário para commitar/push).
4. Apagar o rascunho `projetos/segunda-memoria` depois de migrado (com ok).
