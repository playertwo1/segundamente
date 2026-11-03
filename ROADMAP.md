# ROADMAP — Segunda Mente

**Visão e escopo:** [PROJECT.md](PROJECT.md) · **Design aprovado:** [DESIGN.md](DESIGN.md) · **Índice e pranchas:** [docs/INDEX.md](docs/INDEX.md) · **Onde paramos:** [STATE.md](STATE.md) · **Decisões:** [docs/DECISIONS.md](docs/DECISIONS.md) · **Regras de execução:** [docs/WATCHDOG.md](docs/WATCHDOG.md) · **Auditoria:** [docs/AUDIT.md](docs/AUDIT.md)

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
| F0 — Fundação | Fork roda no emulador e no Galaxy S25 Ultra (Android 17), licenças e módulos auditados, identidade própria | DONE | Build `globalDev` + instalação no S25 Ultra (SM-S938B) + auditoria registrada |
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
| F0-02 | Build limpo e execução `flutter run` / `adb install` no emulador e no S25 Ultra | P0 | F0-01 | DONE | App abre no emulador e no Galaxy S25 Ultra (SM-S938B, Android 17); `flutter test` rodados |
| F0-03 | Identidade própria: nome "Segunda Mente", `applicationId`, assinatura/keystore (fora do repo), ícone provisório | P0 | F0-02 | DONE | APK `app.segundamente.dev` instala ao lado de `com.memexlab.memex.dev` |
| F0-04 | Auditoria de licença: GPL-3.0, dependências, atribuições obrigatórias | P1 | F0-01 | DONE | Tabela de dependências + licenças em `docs/F0-04-licencas.md` |
| F0-05 | Auditoria de módulos reutilizáveis: provedores/LLM, OAuth, voz (STT/TTS), anexos, banco (Drift), exportação | P1 | F0-02 | DONE | Nota em `docs/F0-05-modulos.md`; voz decidida em D-007 |
| F0-06 | Rotina de atualização do upstream (merge/rebase seguro) | P2 | F0-01 | DONE | Procedimento em `docs/F0-06-upstream.md`, merge real executado |

**Portão F0:** F0-01 a F0-06 `DONE`. Execução no Samsung Galaxy S25 Ultra (SM-S938B, RQCY10934YV, Android 17) confirmada em 2026-11-03 com o pacote `app.segundamente.dev` (screenshot em `docs/s25_screenshot.png`). Portão da F0 FECHADO.

## F1 — Registro de modelos
| ID | Tarefa | Prio | Depende de | Estado | Evidência exigida |
|---|---|---|---|---|---|
| F1-01 | Model Registry: catálogo por provedor, cache/versionamento, status (suportado / acessível pela conta / não testado) | P0 | F0 | DONE | Testes unitários + tela de seleção |
| F1-02 | Model ID personalizado e base URL customizável | P0 | F1-01 | IN_PROGRESS | Modelo fora da lista padrão selecionado por ID manual e respondendo |
| F1-03 | Teste de conexão e matriz de capacidades por adaptador (texto, streaming, JSON, visão, áudio) | P0 | F1-01 | IN_PROGRESS | Resposta real de OpenAI e Gemini; aviso quando falta capacidade |
| F1-04 | Verificar OAuth OpenAI/Gemini (client_id dos CLIs oficiais) e registrar risco de termos | P1 | F0-05 | DONE (OpenAI; Gemini BLOCKED) | Login funcionando no S25 + nota de risco em `docs/DECISIONS.md` |
| F1-05 | Claude por chave de API (opcional) e endpoint compatível/local | P2 | F1-02 | NOT_RUN | Uma chamada real de cada, ou `NOT_RUN` justificado |
| F1-06 | Troca de provedor sem perder histórico | P0 | F1-01 | DONE | Conversa mantida após trocar de modelo |
| F1-07 | Modelos `gpt-6-luna`, `gpt-6.1-sol`, `gpt-6.1-terra` sempre na lista do OAuth da OpenAI | P1 | F1-03 | IN_PROGRESS | Resposta real de cada ID no S25; se o ID não existir, o erro aparece claro e o ID manual (F1-02) resolve |
| F1-08 | Decidir o login OAuth do Claude (D-015) | P1 | F1-04 | BLOCKED | Decisão do dono registrada; código removido ou D-005 revisada |

**Portão F1:** F1-01, F1-02, F1-03, F1-06 `DONE`; dois provedores respondendo.

## F2 — Chat, voz e importação
| ID | Tarefa | Prio | Depende de | Estado | Evidência exigida |
|---|---|---|---|---|---|
| F2-01 | Chat de texto com histórico persistente | P0 | F1 | DONE | Conversa sobrevive a reiniciar o app |
| F2-02 | Voz em turnos: microfone → transcrição → resposta → áudio opcional (pt-BR) | P0 | F0-05, F2-01 | IN_PROGRESS | Fala pt-BR transcrita no S25 (feito, via D-011); falta a resposta em áudio (TTS do Android) e a nota de qualidade |
| F2-03 | Importar TXT do Samsung via Compartilhar (ACTION_SEND) e seleção de arquivo, com pré-visualização | P0 | F2-01 | IN_PROGRESS | TXT real de ~50 min aberto sem copiar/colar; timestamps preservados |
| F2-04 | Normalização reversível do texto (original imutável, versão normalizada separada) | P1 | F2-03 | DONE | Teste: original idêntico bit a bit após normalizar |
| F2-05 | Anexar fotos/imagens (JPG/PNG; HEIC avaliado) e analisar em provedor com visão | P0 | F1-03, F2-01 | NOT_RUN | Foto analisada em um provedor; aviso nos sem visão |
| F2-06 | Texto digitado/colado como sessão; PDF de entrada se couber | P2 | F2-01 | DONE | Colar texto cria sessão; PDF `NOT_RUN` aceito se cortado |
| F2-07 | Tela de envio: mostrar o conteúdo que sai do aparelho e pedir confirmação | P0 | F2-03 | DONE | Nada é enviado sem passar por ela |
| F2-08 | Menu único "+" no chat: câmera, galeria, TXT, PDF e áudio; sem faixa de fotos recentes | P1 | F2-01 | DONE | Menu no S25; PDF anexado foi lido pelo ChatGPT; TXT importado chegou ao agente |
| F2-09 | Áudio anexado ou compartilhado vira texto pt-BR (D-011) e só o texto vai ao modelo | P0 | F2-08 | IN_PROGRESS | `.m4a` real de 1 a 2 min transcrito no S25; depois ~50 min. Anotar limite de tamanho e duração |
| F2-10 | Compartilhar TXT, PDF e áudio com o app abre o chat com o anexo | P1 | F2-08 | IN_PROGRESS | TXT validado no S25; PDF e áudio compartilhados `NOT_RUN` |
| F2-11 | Transcrição local com Whisper multilíngue (`pt`) pelo `sherpa_onnx` que o app já tem, como caminho offline e reserva do D-011 | P1 | F2-09 | READY | Mesmo áudio transcrito pelo endpoint e pelo Whisper local; tempo e pico de memória de 50 min no S25; escolha entre `base` e `small` registrada com a taxa de erro anotada |

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
| F3-07 | Extrator de tarefas robusto: exemplos negativos no prompt, deduplicação contra o histórico, saída inválida sem nota em branco | P1 | F3-02 | READY | Testes por caso (ver F3-07 abaixo); em sessão real, nenhuma tarefa repetida nem narração virou tarefa |

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
| F5-04 | Aplicar a direção AMOLED aprovada em `DESIGN.md`: conteúdo editorial, navegação no topo, sem barra inferior persistente e conversa com acesso explícito | P2 | F4 | NOT_RUN | Widget tests dos comportamentos visíveis; capturas antes/depois no S25; checagem de menu/rotas, rolagem, texto ampliado e leitor de tela |
| F5-05 | Auditoria final (`docs/AUDIT.md`) e atribuições GPL | P0 | F5-01 | IN_PROGRESS | Relatório de auditoria sem item crítico aberto |

**Portão F5 = MVP pronto.** Aberto em 2026-11-02 com os portões da F0, da F1, da F2, da F3 e da F4 ainda abertos. `docs/reviews/F5.md` registra `AUDIT RESULT: FAIL`. O MVP não está pronto.

### F5-04 — direção aprovada, implementação pendente
- Direção e dez pranchas aprovadas: [`DESIGN.md`](DESIGN.md) e [`docs/INDEX.md`](docs/INDEX.md#design-móvel).
- A aprovação é de design. As telas ainda não foram implementadas; F5-04 permanece `NOT_RUN` e depende de F4.
- Ordem sugerida quando F5-04 estiver liberada: tokens/tema e navegação; timeline, conhecimento e memórias; entrada e conversa; calendário, detalhes e relatórios; configurações, modelos, agentes e backup; estados vazios/erro e validação de acessibilidade.
- Aplicar os componentes e abstrações existentes em `lib/ui/core/themes/`; conferir `DESIGN.md` e as rotas antes de alterar cada família. Toda interação visual nova precisa do widget test exigido por `AGENTS.md`.

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
| F6-05 | Tags hierárquicas (`#area/projeto`) com árvore e contagem | P1 | F5 | READY | Testes do cálculo da árvore e da lista; no S25, `#trabalho/reuniao` aparece sob `trabalho` com contagem somada |
| F6-06 | Filtros por propriedade e visões salvas | P1 | F6-01 | READY | Testes do extrator e do filtro; no S25, uma visão salva "tarefas abertas" reaplica e lista só os itens certos |
| F6-07 | Prévia de links (título, descrição, imagem), desligada por padrão | P2 | F5-02 | BACKLOG | Testes do parser e do bloqueio de endereços privados; no S25, com a opção ligada, uma URL colada mostra a prévia |
| F6-08 | Mapa de atividade no calendário (intensidade por dia) | P2 | F5 | READY | Teste dos níveis; captura do S25 com dias de intensidades diferentes |
| F6-09 | Recuperação para perguntas sobre sessões: sementes por busca de texto, mais sessões irmãs por tópico, com orçamento de caracteres e piso de relevância | P1 | F6-01, F6-05 | BACKLOG | Testes da expansão; no S25, uma pergunta fora do assunto não traz nenhuma sessão |
| F6-10 | Embeddings no aparelho para busca por significado em português | P2 | F6-09 | BACKLOG | Modelo multilíngue medido em pt-BR contra a busca de texto; tamanho, tempo e memória no S25. Sem medida, continua `BACKLOG` |
| F6-11 | "Adicionar à agenda" nos encaminhamentos com data | P2 | F6-02 | READY | Intent `ACTION_INSERT` do calendário, sem permissão nova; no S25, o evento chega pré-preenchido |

**Portão F6:** busca semântica entre sessões, tópicos, "o que mudou e por quê?", painel de encaminhamentos e histórico de versões. Aberto em 2026-11-02 (D-010) com os portões da F0 à F5 ainda abertos. A busca feita é texto local. Semântica, tópicos e o "por quê" continuam `NOT_RUN`. O MVP não está pronto.

### Definição das tarefas F6-05 a F6-08 (D-014)
Regras comuns: cada uma entra com testes (`AGENTS.md`), em commit próprio; texto em `en` e `pt`; nada muda dados já gravados sem migração testada. Ordem sugerida: F6-08, F6-05, F6-06, F6-07.

**F6-05 — Tags hierárquicas**
- Faz: o separador `/` define níveis (`trabalho/reuniao`). A árvore mostra cada nó com a contagem dos cartões do nó mais a dos filhos. Tocar num nó filtra a lista. Tags sem `/` continuam raízes, sem migração.
- Não faz: renomear ou mover tags em lote, nem ligar a árvore ao P.A.R.A. (isso é da F6-04).
- Pronto quando: pai soma filhos; tag sem `/` fica na raiz; nó sem cartões some; a árvore abre e fecha na tela.

**F6-06 — Filtros por propriedade e visões salvas**
- Faz: propriedades derivadas do texto do cartão ou relatório: tem link, tem tarefa, tem tarefa aberta (`- [ ]`), tem código. Filtro combinável com texto, tag e data. Visão salva = nome + filtro, guardada em arquivo JSON local no workspace, com renomear e apagar.
- Não faz: linguagem de consulta aberta (como o CEL do Memos) e sincronização entre aparelhos.
- Pronto quando: o extrator acerta nos casos de borda (link dentro de código, tarefa marcada vs aberta); o filtro combina as condições com E; a visão persiste ao reiniciar o app.

**F6-07 — Prévia de links**
- Faz: ao ligar a opção (padrão desligada, critério 7), busca `title`, `og:description` e `og:image` da URL, com cache local e limite de tempo e tamanho.
- Segurança: só `http` e `https`; recusar `localhost`, endereços privados e redirecionamentos para eles; sem cookies nem cabeçalhos do usuário. A busca revela ao site que o aparelho abriu a URL, e isso precisa estar escrito na opção.
- Não faz: busca automática de todas as URLs antigas, nem imagem de prévia salva sem pedido.

**F6-08 — Mapa de atividade**
- Faz: no calendário mensal, o fundo de cada dia usa 5 níveis pela contagem de cartões (0, 1, 2, 3 a 4, 5 ou mais). A contagem já existe (`CalendarDay.total`).
- Não faz: visão anual nem sequência de dias (streak), que ficam para depois.
- Pronto quando: a função de nível tem teste por faixa; o dia selecionado e o de hoje continuam legíveis; o texto do dia tem contraste nos níveis altos.

### Definição das tarefas vindas do Daedalus Echo (D-016)
Mesmas regras comuns de cima. Ordem sugerida: F3-07, F2-11, F6-11, F6-09. A F6-10 só depois de medir.

**F2-11 — Whisper multilíngue local**
- Faz: troca ou soma ao `WhisperService` um modelo Whisper multilíngue em int8 (`language = "pt"`, `task = "transcribe"`), com download explícito e tamanho mostrado. Áudio longo vai em janelas de 30 s, decodificado em pedaços para não carregar 50 min de PCM de uma vez (~190 MB em float a 16 kHz). Cada janela guarda o tempo de início, para os timestamps da F3-04 (aproximados, de 30 s).
- Não faz: tradução, separação de falantes (diarização) e timestamps por palavra.
- Pronto quando: o pt-BR sai com acentos; o áudio de 50 min não estoura a memória; o resultado entra no mesmo caminho do TXT importado (prévia e confirmação antes de enviar ao modelo).

**F3-07 — Extrator de tarefas robusto**
- Faz: o prompt (em pt) pede só compromissos de quem fala, com exemplos do que NÃO é tarefa (narração do que está fazendo, comentário sobre o app, fato passado, opinião). Limite de 10 por sessão, 15 palavras cada, "nenhuma" quando não houver. Remove cercas ```json da resposta. Deduplicação contra o histórico: texto normalizado igual; um contido no outro só se o menor tiver 8 ou mais caracteres; mesmas palavras úteis após tirar palavras vazias do português. "ligar para o pai" não é duplicata de "ligar para a mãe e o pai".
- Saída que não dá para interpretar nunca vira nota em branco: o título e a prévia vêm da primeira linha com texto do próprio conteúdo.
- Pronto quando: há um teste por regra acima, mais os casos pt-BR; nada vira tarefa definitiva sem confirmação (F3-05 continua valendo).

**F6-09 — Recuperação por tópicos**
- Faz: a busca de texto dá as sementes; sessões que compartilham tópico ou tag com elas entram em seguida, ordenadas por tópicos em comum e depois pela data, até o orçamento de caracteres. As sementes nunca saem. Pergunta sem nenhuma semente acima do piso não traz sessão nenhuma, para uma conversa sobre outro assunto não receber nota alheia.
- Não faz: embeddings (F6-10) nem grafo visual.

**F6-11 — Adicionar à agenda**
- Faz: botão no encaminhamento aprovado que abre o app de calendário do Android com título e descrição preenchidos e 1 hora de duração, pelo intent `ACTION_INSERT`. Não pede permissão de agenda e não grava nada sozinho.
- Não faz: ler a agenda nem sincronizar.

## Fases futuras (bloqueadas até o MVP)
- **F7:** voz contínua full duplex; ponte opcional com Claude Code/Codex CLI oficiais no PC (única via aceita para assinatura Claude); modelos locais (Ollama).
- **F8:** NotebookLM — Via A (exportar para Google Docs), depois B (conector comunitário, opt-in), C (API empresarial só se justificar).

## Ideias futuras (não autorizadas)
| Ideia | Quando reavaliar |
|---|---|
| Referências de UX/relatórios: AnythingLLM Mobile, Meet2Notes, Open Notebook, Memos (revisado em D-014), Khoj, Daedalus Echo (revisado em D-016) | Ao iniciar F2/F3, copiando só padrões ou módulos de licença compatível |
| Graphiti/Omi (memória temporal) | Só se F6 provar necessidade |
| Mapa global de tópicos (grafo visual das sessões), do Daedalus Echo | Depois da F6-05 e da F6-09, se tópicos ficarem difíceis de navegar em lista |
| Gemma 3 1B local (MediaPipe) e conversa por voz mãos-livres com resposta falada | F7, junto de Ollama; medir antes a qualidade em pt-BR |
| Backup versionado automático que inclui as configurações padrão | Ao revisar o backup do app; o Echo corrigiu esse furo na v1.2.2 |
| Biblioteca de anexos (tela com todas as fotos, PDFs e áudios importados), do Memos | Depois da F2-09 e da F6-05, se achar arquivos ficar difícil |
| Chave de API do Gemini (AI Studio) como reserva da transcrição de áudio | Se o endpoint do ChatGPT (D-011) cair ou limitar o tamanho |

## Mudanças de escopo
- 2026-11-02 — escopo do MVP, fases e Claude por chave de API: ver [docs/DECISIONS.md](docs/DECISIONS.md).
- 2026-11-02 — a F6 começa com o MVP aberto: D-010. A F7 e a F8 continuam bloqueadas.
- 2026-11-03 — D-011 (áudio pelo endpoint de transcrição), D-012 (só en e pt), D-013 (Gemini OAuth bloqueado), D-014 (ideias do Memos na F6) e D-015 (login Claude pendente).
- 2026-11-03 — D-016 (ideias do Daedalus Echo: F2-11, F3-07, F6-09 a F6-11).
- 2026-11-03 — D-017: direção visual móvel AMOLED aprovada; aplicação permanece em F5-04 `NOT_RUN`.
