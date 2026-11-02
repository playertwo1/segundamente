# ROADMAP — Segunda Mente

**Visão e escopo:** [PROJECT.md](PROJECT.md) · **Onde paramos:** [STATE.md](STATE.md) · **Decisões:** [docs/DECISIONS.md](docs/DECISIONS.md) · **Regras de execução:** [docs/WATCHDOG.md](docs/WATCHDOG.md) · **Auditoria:** [docs/AUDIT.md](docs/AUDIT.md)

## Como uma IA usa este arquivo
1. Leia `STATE.md` para a próxima ação e o roadmap abaixo para o contexto.
2. Trabalhe só em subfases `READY` da fase ativa, na ordem das dependências. Não pule o portão da fase.
3. Subfase só vira `DONE` com a evidência exigida colada em `STATE.md` (comando e saída, ou demonstração no aparelho). Não executado é `NOT_RUN`, nunca `PASS`.
4. Ideia nova vai para "Ideias futuras", não para código. Mudança de escopo exige decisão em `docs/DECISIONS.md`.
5. Antes de mudança média ou grande: leia `docs/WATCHDOG.md`. Antes de fechar uma fase: aplique `docs/AUDIT.md`.
6. Regras de código, camadas e testes do Memex: `AGENTS.md` (ele vence em conflito).

Estados: `BACKLOG` · `READY` · `IN_PROGRESS` · `BLOCKED` · `REVIEW` · `DONE`. Prioridade: P0 bloqueia o fluxo principal · P1 sustenta o MVP · P2 melhoria · P3 futuro.

## Fases
| Fase | Resultado verificável | Estado | Portão de saída |
|---|---|---|---|
| F0 — Fundação | Fork roda no emulador (S25 adiado, D-009), licenças e módulos auditados, identidade própria | IN_PROGRESS | Build `globalDev` no emulador + auditoria registrada; o S25 continua `NOT_RUN` e a fase não fecha sem ele |
| F1 — Registro de modelos | Escolher e testar modelos sem lista estática | IN_PROGRESS | Critérios 4 e (parte do) 6 abaixo |
| F2 — Chat, voz e importação | Conversar por texto/voz; importar TXT Samsung e fotos | IN_PROGRESS | Critérios 1, 2 e 3 abaixo |
| F3 — Extração e relatório | Relatório por sessão com evidências e confirmação | IN_PROGRESS | Critério 6 abaixo |
| F4 — Exportação | Mesmo relatório em PDF, DOCX e MD | IN_PROGRESS | Critério 5 abaixo |
| F5 — Fechamento do MVP | Testes no S25, privacidade, desempenho, visual | IN_PROGRESS | Critério 7 abaixo + `docs/AUDIT.md` |
| F6 — Memória longitudinal | Busca semântica, tópicos, "o que mudou?" | IN_PROGRESS | MVP concluído |
| F7 — Voz contínua e ponte CLI | Full duplex; Claude Code/Codex CLI no PC | BLOCKED | MVP concluído + termos verificados |
| F8 — NotebookLM | Via Drive/Docs, depois conectores | BLOCKED | MVP e exportação estáveis; consentimento por envio |

## F0 — Fundação (ativa)
| ID | Tarefa | Prio | Depende de | Estado | Evidência exigida |
|---|---|---|---|---|---|
| F0-01 | Configurar `upstream=memex-lab/memex`; branch de trabalho; registrar commit base do Memex | P0 | — | DONE | `git remote -v` e hash base em STATE.md |
| F0-02 | Build limpo e execução `flutter run --flavor globalDev` no emulador; S25 adiado (D-009) | P0 | F0-01 | DONE | App abre no emulador; `flutter analyze` e `flutter test` rodados. S25 Ultra: `NOT_RUN` |
| F0-03 | Identidade própria: nome "Segunda Mente", `applicationId`, assinatura/keystore (fora do repo), ícone provisório | P0 | F0-02 | DONE | APK `app.segundamente.dev` instala ao lado de `com.memexlab.memex.dev` |
| F0-04 | Auditoria de licença: GPL-3.0, dependências, atribuições obrigatórias | P1 | F0-01 | DONE | Tabela de dependências + licenças em `docs/F0-04-licencas.md` |
| F0-05 | Auditoria de módulos reutilizáveis: provedores/LLM, OAuth, voz (STT/TTS), anexos, banco (Drift), exportação | P1 | F0-02 | DONE | Nota em `docs/F0-05-modulos.md`; voz decidida em D-007 |
| F0-06 | Rotina de atualização do upstream (merge/rebase seguro) | P2 | F0-01 | DONE | Procedimento em `docs/F0-06-upstream.md`, merge real executado |

**Portão F0:** F0-01 a F0-05 `DONE`. A execução no S25 Ultra está adiada (D-009): é `NOT_RUN`, não `PASS`, e não bloqueia F0-04 a F0-06 no emulador. A fase só fecha depois dessa execução, ou de uma decisão nova. Se build, licença ou teste no aparelho de prova falharem, parar e registrar decisão em `docs/DECISIONS.md` antes de seguir.

## F1 — Registro de modelos
| ID | Tarefa | Prio | Depende de | Estado | Evidência exigida |
|---|---|---|---|---|---|
| F1-01 | Model Registry: catálogo por provedor, cache/versionamento, status (suportado / acessível pela conta / não testado) | P0 | F0 | DONE | Testes unitários + tela de seleção |
| F1-02 | Model ID personalizado e base URL customizável | P0 | F1-01 | IN_PROGRESS | Modelo fora da lista padrão selecionado por ID manual e respondendo |
| F1-03 | Teste de conexão e matriz de capacidades por adaptador (texto, streaming, JSON, visão, áudio) | P0 | F1-01 | IN_PROGRESS | Resposta real de OpenAI e Gemini; aviso quando falta capacidade |
| F1-04 | Verificar OAuth OpenAI/Gemini (client_id dos CLIs oficiais) e registrar risco de termos | P1 | F0-05 | IN_PROGRESS | Login funcionando no S25 + nota de risco em `docs/DECISIONS.md` |
| F1-05 | Claude por chave de API (opcional) e endpoint compatível/local | P2 | F1-02 | NOT_RUN | Uma chamada real de cada, ou `NOT_RUN` justificado |
| F1-06 | Troca de provedor sem perder histórico | P0 | F1-01 | DONE | Conversa mantida após trocar de modelo |

**Portão F1:** F1-01, F1-02, F1-03, F1-06 `DONE`; dois provedores respondendo.

## F2 — Chat, voz e importação
| ID | Tarefa | Prio | Depende de | Estado | Evidência exigida |
|---|---|---|---|---|---|
| F2-01 | Chat de texto com histórico persistente | P0 | F1 | DONE | Conversa sobrevive a reiniciar o app |
| F2-02 | Voz em turnos: microfone → transcrição → resposta → áudio opcional (pt-BR) | P0 | F0-05, F2-01 | NOT_RUN | Demonstração no S25; qualidade de pt-BR anotada |
| F2-03 | Importar TXT do Samsung via Compartilhar (ACTION_SEND) e seleção de arquivo, com pré-visualização | P0 | F2-01 | IN_PROGRESS | TXT real de ~50 min aberto sem copiar/colar; timestamps preservados |
| F2-04 | Normalização reversível do texto (original imutável, versão normalizada separada) | P1 | F2-03 | DONE | Teste: original idêntico bit a bit após normalizar |
| F2-05 | Anexar fotos/imagens (JPG/PNG; HEIC avaliado) e analisar em provedor com visão | P0 | F1-03, F2-01 | NOT_RUN | Foto analisada em um provedor; aviso nos sem visão |
| F2-06 | Texto digitado/colado como sessão; PDF de entrada se couber | P2 | F2-01 | DONE | Colar texto cria sessão; PDF `NOT_RUN` aceito se cortado |
| F2-07 | Tela de envio: mostrar o conteúdo que sai do aparelho e pedir confirmação | P0 | F2-03 | DONE | Nada é enviado sem passar por ela |

**Portão F2:** critérios 1, 2 e 3 verificados no S25 Ultra. A escolha de um `.txt` está no commit `db7bc1d`, em `origin/main`, e não fecha a F2-03: falta o TXT real de ~50 min.

## F3 — Extração e relatório
| ID | Tarefa | Prio | Depende de | Estado | Evidência exigida |
|---|---|---|---|---|---|
| F3-01 | Esquema versionado (Session, Segment, Insight, Task, Topic) independente de provedor | P0 | F2 | DONE | Esquema + migração testada |
| F3-02 | Extrator estruturado (JSON validado): resumo, ideias, oportunidades, decisões, tarefas, follow-ups, dúvidas | P0 | F3-01 | IN_PROGRESS | Saída validada contra o esquema em sessão real |
| F3-03 | Tipos de relatório (livre, reunião, brainstorm, diário, estudo) e relatório customizado | P1 | F3-02 | DONE | Cada tipo gera relatório distinto |
| F3-04 | Rastreabilidade: cada item aponta para trecho e timestamp; abrir o trecho-fonte | P0 | F3-02 | DONE | Clicar numa decisão abre o trecho original |
| F3-05 | Confirmação humana: itens `não confirmado` até aprovar; "não identificado/não informado" para responsável e prazo ausentes | P0 | F3-02 | DONE | Teste: nada vira tarefa definitiva sem confirmação |
| F3-06 | Editar/aprovar/descartar itens sem perder o texto original; busca simples e exclusão com derivados | P1 | F3-05 | DONE | Edição preserva original; excluir sessão remove derivados |

**Portão F3:** critério 6 + a amostra de 53 min não perde pontos centrais nem timestamps. O esquema e a tela entram no commit do botão de TXT e da F3. A amostra de 53 min e uma resposta real de modelo continuam `NOT_RUN`, então o portão não fecha. A F3 foi aberta com os portões da F0, da F1 e da F2 ainda abertos.

## F4 — Exportação
| ID | Tarefa | Prio | Depende de | Estado | Evidência exigida |
|---|---|---|---|---|---|
| F4-01 | Exportar Markdown (título, data, seções, fontes) | P0 | F3 | DONE | Arquivo gerado e conferido |
| F4-02 | Exportar PDF com acentuação pt-BR | P0 | F4-01 | IN_PROGRESS | PDF aberto no aparelho, acentos corretos |
| F4-03 | Exportar DOCX | P0 | F4-01 | IN_PROGRESS | Aberto no Word/Docs, conteúdo igual |
| F4-04 | Exportar relatório completo ou partes selecionadas; compartilhar/salvar pelo Android; sem serviço externo sem consentimento | P1 | F4-01 | IN_PROGRESS | Compartilhamento testado |

**Portão F4:** o mesmo relatório sai em PDF, DOCX e MD com conteúdo conferido (critério 5). O Markdown foi conferido num fixture. O PDF e o DOCX levam o mesmo texto, mas não foram abertos no aparelho nem no Word. A F4 foi aberta com os portões da F0, da F1, da F2 e da F3 ainda abertos.

## F5 — Fechamento do MVP
| ID | Tarefa | Prio | Depende de | Estado | Evidência exigida |
|---|---|---|---|---|---|
| F5-01 | Teste ponta a ponta dos 7 critérios no S25 Ultra | P0 | F4 | IN_PROGRESS | Checklist preenchido com evidência |
| F5-02 | Revisão de privacidade: chaves e tokens protegidos, sem segredo em log, política de envio compreensível | P0 | F4 | IN_PROGRESS | Revisão registrada |
| F5-03 | Desempenho (sessão longa, lista de histórico) e correções | P1 | F4 | IN_PROGRESS | Medições registradas |
| F5-04 | Refinamento visual (Material 3, uso com uma mão) | P2 | F4 | NOT_RUN | Capturas antes/depois |
| F5-05 | Auditoria final (`docs/AUDIT.md`) e atribuições GPL | P0 | F5-01 | IN_PROGRESS | Relatório de auditoria sem item crítico aberto |

**Portão F5 = MVP pronto.** Aberto em 2026-11-02 com os portões da F0, da F1, da F2, da F3 e da F4 ainda abertos. `docs/reviews/F5.md` registra `AUDIT RESULT: FAIL`. O MVP não está pronto.

## Critérios de aceite do MVP (no Galaxy S25 Ultra, sem NotebookLM, PC ligado, Hermes ou serviço pago próprio)
1. Conversar por texto e falar com o app com resposta opcional em áudio.
2. Compartilhar um TXT real do Samsung e obter relatório rastreável a trechos/timestamps.
3. Analisar fotos em ao menos um provedor com visão, com aviso nos demais.
4. Selecionar modelo por ID ou catálogo atualizado, sem novo APK.
5. Gerar o MESMO relatório em PDF, DOCX e MD, com acentuação correta.
6. Editar/confirmar decisões, ideias, tarefas e follow-ups sem perder o original; histórico persiste ao trocar de modelo.
7. Nada é enviado sem escolha explícita; nada vira tarefa/decisão sem confirmação.

## F6 — Memória longitudinal
| ID | Tarefa | Prio | Depende de | Estado | Evidência exigida |
|---|---|---|---|---|---|
| F6-01 | Busca entre sessões | P0 | F5 | IN_PROGRESS | Busca semântica com evidência; texto local não substitui |
| F6-02 | Painel de encaminhamentos aprovados | P0 | F3 | IN_PROGRESS | Lista conferida no aparelho |
| F6-03 | O que mudou e por quê, com histórico de versões | P0 | F3 | IN_PROGRESS | Diferença e motivo registrados |
| F6-04 | Tópicos e projetos | P1 | F6-01 | NOT_RUN | Entidade própria, ligada às sessões |

**Portão F6:** busca semântica entre sessões, tópicos, "o que mudou e por quê?", painel de encaminhamentos e histórico de versões. Aberto em 2026-11-02 (D-010) com os portões da F0 à F5 ainda abertos. A busca feita é texto local. Semântica, tópicos e o "por quê" continuam `NOT_RUN`. O MVP não está pronto.

## Fases futuras (bloqueadas até o MVP)
- **F7:** voz contínua full duplex; ponte opcional com Claude Code/Codex CLI oficiais no PC (única via aceita para assinatura Claude); modelos locais (Ollama).
- **F8:** NotebookLM — Via A (exportar para Google Docs), depois B (conector comunitário, opt-in), C (API empresarial só se justificar).

## Ideias futuras (não autorizadas)
| Ideia | Quando reavaliar |
|---|---|
| Referências de UX/relatórios: AnythingLLM Mobile, Meet2Notes, Open Notebook, Memos, Khoj, Daedalus Echo | Ao iniciar F2/F3, copiando só padrões ou módulos de licença compatível |
| Graphiti/Omi (memória temporal) | Só se F6 provar necessidade |

## Mudanças de escopo
- 2026-11-02 — escopo do MVP, fases e Claude por chave de API: ver [docs/DECISIONS.md](docs/DECISIONS.md).
- 2026-11-02 — a F6 começa com o MVP aberto: D-010. A F7 e a F8 continuam bloqueadas.
