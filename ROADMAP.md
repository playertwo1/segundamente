# ROADMAP — Segunda Mente

**Visão e escopo:** [PROJECT.md](PROJECT.md) · **Design aprovado:** [DESIGN.md](DESIGN.md) · **Índice e pranchas:** [docs/INDEX.md](docs/INDEX.md) · **Estado e próxima ação:** [STATE.md](STATE.md) · **Decisões:** [docs/DECISIONS.md](docs/DECISIONS.md) · **Regras de execução:** [docs/WATCHDOG.md](docs/WATCHDOG.md) · **Auditoria:** [docs/AUDIT.md](docs/AUDIT.md)

**Atualização deste mapa:** 2026-11-04. Para evidência posterior, use a entrada datada mais recente de STATE.md e o estado atual do repositório. Se o resumo inicial de STATE.md divergir de uma evidência posterior, prevalece a evidência datada mais recente; atualize o resumo quando STATE.md for revisado.

## Como ler e executar este roadmap

1. Leia STATE.md antes de trabalhar. Ele registra o estado observado, a evidência disponível, os bloqueios e a próxima ação.
2. Use este arquivo para entender o escopo, as fases, as dependências e os critérios de aceite. Não trate uma linha planejada como funcionalidade já implementada.
3. Faça apenas subfases READY da fase ativa. Fases BLOCKED só podem ser abertas quando todas as condições de desbloqueio forem atendidas e a decisão correspondente estiver registrada em docs/DECISIONS.md.
4. Uma subfase só fica DONE depois que a evidência indicada é registrada em STATE.md. Implementação sem validação não fecha a subfase. Verificação não executada é NOT_RUN, nunca PASS.
5. Estado da fase descreve o trabalho agregado; estado do portão descreve se os critérios de aceite foram provados. Uma fase pode ter tarefas opcionais abertas depois de seu portão ter sido cumprido.
6. Dependências indicam os dados, decisões ou resultados necessários para começar ou aceitar a tarefa. Exceções de execução paralela têm de ser explícitas e não fecham os portões anteriores.
7. Siga PROJECT.md, AGENTS.md, docs/WATCHDOG.md e docs/AUDIT.md. Toda mudança de comportamento precisa dos testes exigidos em AGENTS.md.

### Estados

| Estado | Significado |
|---|---|
| BACKLOG | Ideia aprovada para planejamento futuro, ainda sem início previsto |
| BLOCKED | Não pode começar até cumprir a dependência ou obter decisão indicada |
| READY | Pré-requisitos necessários estão disponíveis e a tarefa pode começar |
| IN_PROGRESS | Implementação ou validação já começou |
| REVIEW | Aguarda revisão ou validação de aceite |
| DONE | Entrega e evidência de aceite registradas em STATE.md |
| NOT_RUN | Estado explícito de uma checagem ou tarefa ainda não executada; não é aprovação |

### Prioridades

| Prioridade | Significado |
|---|---|
| P0 | Bloqueia o fluxo principal ou o portão de aceite |
| P1 | Necessária para completar a fase ou sustentar o uso esperado |
| P2 | Melhoria útil, sem bloquear o portão principal |
| P3 | Ideia futura sem compromisso de execução |

## Mapa das fases

| Fase | Resultado esperado | Dependência e exceção | Estado atual | Portão |
|---|---|---|---|---|
| F0 — Fundação | Fork, identidade, licença e ambiente verificados | Nenhuma | DONE | Fechado |
| F1 — Registro de modelos | Catálogo, seleção, provedores e troca de modelo confiáveis | F0; o catálogo e os provedores foram validados antes dos demais portões | IN_PROGRESS; critério MVP cumprido | Critério 4 do MVP cumprido pelo catálogo e por múltiplos provedores; há tarefas adicionais abertas |
| F2 — Chat, voz e importação | Conversa persistente, entrada de voz e arquivos autorizados | F1; aberta antecipadamente por decisão do dono | IN_PROGRESS | Critérios 1, 2, 3 e consentimento de envio comprovados |
| F3 — Extração e relatório | Relatório editável, fiel às fontes e com itens não confirmados por padrão | F2; aberta antecipadamente por decisão do dono | IN_PROGRESS | Critério 6, extração real do modelo e amostra longa comprovados |
| F4 — Exportação | O mesmo relatório em Markdown, PDF e DOCX | F3 | DONE | Critério 5 e compartilhamento verificados no fixture e no S25 |
| F5 — Fechamento do MVP | Aceite integral, privacidade, desempenho e auditoria | F0–F4 | IN_PROGRESS | Sete critérios no S25 e auditoria sem bloqueios |
| F5V — Redesign visual | Aplicação da direção AMOLED aprovada nas telas existentes | D-022 permite execução em paralelo à F5 | IN_PROGRESS; fase ativa | Interações, acessibilidade e validação visual comprovadas |
| F6 — Memória longitudinal | Busca, encaminhamentos, histórico de mudanças, tópicos e agenda | D-010 permite avançar antes do fechamento do MVP | IN_PROGRESS | Busca semântica, tópicos, justificativas e encaminhamentos verificados |
| F7 — Voz contínua e ponte CLI | Voz full duplex opcional, modelo local e integração controlada com CLIs oficiais | MVP fechado e decisões de plataforma, termos e segurança aprovadas | BLOCKED | Portão F7 |
| F8 — NotebookLM | Exportação opt-in e integração somente se suportada e aprovada | MVP e exportação estáveis; termos e destino aprovados | BLOCKED | Portão F8 |
| F9 — Meeting Decoder | Conversas e PDFs viram relatórios revisáveis, Todo e encaminhamentos | MVP fechado; decisões da F9-01 aprovadas | BLOCKED | Portão F9 |

**Exceções vigentes:** D-010 permite avançar F6 enquanto o MVP está aberto. D-022 permite executar F5V em paralelo à F5. Nenhuma delas declara pronto o MVP nem libera F7, F8 ou F9.

## Ordem de trabalho vigente

1. **F5V:** concluir o detalhe de cartão e a comparação visual da F5V-02; depois, terminar os itens pendentes de conversa/personagem e F5V-04. F5V-05 continua NOT_RUN até completar a revisão de acessibilidade e a validação indicada em STATE.md.
2. **Em paralelo, quando o S25 estiver disponível:** seguir F5-01/02/03 e provar as pendências de F2-03, F2-09, F2-10 e F1-07. Não substituir amostras reais por fixtures sintéticas.
3. **Depois da F5V:** retomar os itens READY de F6 e a ordem das tarefas adicionais descrita ao fim das fases F2, F3 e F6.
4. F7, F8 e F9 continuam bloqueadas até seus critérios de abertura. A ordem entre elas deve ser revista depois do MVP.

## F0 — Fundação

| ID | Entrega verificável | Prio | Depende de | Estado | Evidência de aceite |
|---|---|---:|---|---|---|
| F0-01 | Configurar upstream memex-lab/memex, branch de trabalho e commit base | P0 | — | DONE | Remotes e hash base registrados em STATE.md |
| F0-02 | Build limpo e execução no emulador e no Galaxy S25 Ultra | P0 | F0-01 | DONE | App aberto nos dois ambientes; build, instalação e testes registrados |
| F0-03 | Identidade Segunda Mente, applicationId próprio, ícone provisório e assinatura fora do repositório | P0 | F0-02 | DONE | APK app.segundamente.dev instalado ao lado do original |
| F0-04 | Revisar licença GPL-3.0, dependências e atribuições | P1 | F0-01 | DONE | Tabela de licenças em docs/F0-04-licencas.md |
| F0-05 | Mapear componentes reutilizáveis: provedores, OAuth, voz, anexos, Drift e exportação | P1 | F0-02 | DONE | Nota em docs/F0-05-modulos.md e decisão D-007 |
| F0-06 | Documentar e executar atualização segura do upstream | P2 | F0-01 | DONE | Procedimento em docs/F0-06-upstream.md e merge registrado |

**Portão F0:** F0-01 a F0-06 estão DONE. Execução no Galaxy S25 Ultra (SM-S938B, Android 17) confirmada em 2026-11-03; captura em docs/s25_screenshot.png. Portão fechado.

## F1 — Registro de modelos

| ID | Entrega verificável | Prio | Depende de | Estado | Evidência de aceite |
|---|---|---:|---|---|---|
| F1-01 | Catálogo de modelos por provedor, com versão/cache e estado recomendado, acessível ou não testado | P0 | F0 | DONE | Testes unitários e tela de seleção; status não afirma disponibilidade sem prova |
| F1-02 | Permitir ID de modelo e base URL personalizados | P1 | F1-01 | IN_PROGRESS | ID fora da lista selecionado e respondendo em chamada real |
| F1-03 | Teste de conexão e matriz de texto, streaming, JSON, visão e áudio | P0 | F1-01 | DONE | Respostas reais de OpenAI, Gemini e Claude registradas no S25; capacidades descritas sem extrapolar os testes |
| F1-04 | Validar OAuth OpenAI/Gemini e documentar riscos de termos | P1 | F0-05 | DONE | Login de ambos no S25; endpoint e ressalvas registrados |
| F1-05 | Validar Claude por chave de API e endpoint compatível/local, se disponíveis | P2 | F1-02 | NOT_RUN | Uma resposta real por configuração; indisponibilidade deve ser registrada como NOT_RUN |
| F1-06 | Trocar provedor/modelo sem perder o histórico | P0 | F1-01 | DONE | Conteúdo da conversa permanece após troca |
| F1-07 | Manter os IDs gpt-6-luna, gpt-6.1-sol e gpt-6.1-terra selecionáveis no OAuth OpenAI | P1 | F1-03 | IN_PROGRESS | Chamada real de cada ID; erro claro para ID indisponível e opção manual por F1-02 |
| F1-08 | OAuth Claude e modelos Claude previstos em D-015 | P1 | F1-04 | DONE | Login PKCE e respostas reais registradas em STATE.md |
| F1-09 | Mostrar, nas configurações, qual provedor/modelo transcreve e qual resume/conversa, além dos dados enviados | P1 | F1-03, F2-09 | READY | Widget test e validação S25 para OAuth, chave de API e modelo local; endpoint de transcrição claramente identificado |
| F1-10 | Failover configurável entre provedores, com ordem visível e reordenável | P1 | F1-03, F1-04 | DONE | Testes do FallbackLLMClient e prioridade drag-and-drop registrados |

**Portão F1:** cumprido segundo STATE.md. O critério 4 do MVP aceita seleção por catálogo atualizado ou por ID; F1-01 e respostas de múltiplos provedores provam a opção por catálogo. F1-02, F1-05 e F1-07 permanecem tarefas adicionais e não invalidam esse portão.

## F2 — Chat, voz e importação

| ID | Entrega verificável | Prio | Depende de | Estado | Evidência de aceite |
|---|---|---:|---|---|---|
| F2-01 | Chat de texto com histórico persistente | P0 | F1 | DONE | Sessão relida após reinicialização do armazenamento |
| F2-02 | Conversa em turnos: fala pt-BR, transcrição e resposta; áudio de resposta é opcional no MVP | P0 | F0-05, F2-01 | IN_PROGRESS | Microfone transcreveu fala real para o campo no S25; falta concluir um turno após revisão/envio e registrar qualidade; TTS não bloqueia o MVP |
| F2-03 | Importar TXT real do Gravador Samsung por Compartilhar ou seletor, sem copiar/colar | P0 | F2-01 | IN_PROGRESS | TXT real de aproximadamente 50 min aberto no S25, relógios preservados e fluxo até o relatório conferido |
| F2-04 | Manter original imutável e guardar separadamente o texto normalizado | P1 | F2-03 | DONE | Teste confirma bytes originais inalterados |
| F2-05 | Anexar JPG/PNG e analisar com provedor com visão; avisar quando o modelo não tem visão | P0 | F1-03, F2-01 | NOT_RUN | Foto real analisada em um provedor e aviso observado em provedor sem visão |
| F2-06 | Criar sessão por texto digitado ou colado | P1 | F2-01 | DONE | Texto colado persiste como sessão; leitura de PDF para gerar relatório pertence à F9; o anexo de chat existente permanece em F2-08 |
| F2-07 | Antes de qualquer envio remoto, mostrar o conteúdo e destino e pedir confirmação explícita | P0 | F2-03, F2-08 | IN_PROGRESS | Prévia e confirmação cobrindo texto, TXT, áudio/transcrição, imagem e outros anexos enviados; cancelar não envia |
| F2-08 | Menu único de anexos no chat: câmera, galeria, TXT, PDF e áudio, sem faixa de fotos recentes | P1 | F2-01 | DONE | Menu validado no S25; TXT chega ao agente; limites de PDF são descritos separadamente |
| F2-09 | Transcrever áudio anexado/compartilhado em pt-BR; enviar ao modelo somente o texto após ação do usuário (D-011) | P0 | F2-08 | IN_PROGRESS | Áudios sintéticos de 8 s, 100 s e aproximadamente 50 min processados no S25; falta validar amostra real e limites/qualidade do serviço |
| F2-10 | Abrir chat com o anexo ao compartilhar TXT, PDF ou áudio com o app | P1 | F2-08 | IN_PROGRESS | TXT validado no S25; PDF e áudio compartilhados ainda precisam de prova |
| F2-11 | Transcrição local multilíngue, em português, com sherpa_onnx e Whisper como alternativa offline ao caminho D-011 | P1 | F2-09 | READY | Comparar o mesmo áudio nos dois caminhos; medir tempo, memória e qualidade em áudio de aproximadamente 50 min no S25; registrar modelo escolhido |
| F2-12 | Importar legendas SRT/VTT preservando relógios e texto | P2 | F2-03 | IN_PROGRESS | Testes de parser para cabeçalho, numeração, intervalos e etiquetas de locutor; prévia validada no S25; parser, seletor e compartilhamento feitos, falta a prévia no aparelho |
| F2-13 | Dicionário local editável de nomes, siglas e produtos para prompts | P1 | F3-08 | BLOCKED | Limite documentado e testado; termos aparecem na prévia de envio; nome próprio corrigido em resumo real |

**Definição do F2-11:** usar modelo Whisper multilíngue com idioma pt e tarefa de transcrição. Processar o áudio em blocos para limitar memória e preservar o tempo aproximado de cada bloco. Não inclui tradução, diarização nem timestamps por palavra. A transcrição local deve entrar na mesma prévia e confirmação do caminho remoto.

**Definição do F2-12:** aceitar SRT e VTT no seletor e no Compartilhar; remover numeração, cabeçalho WEBVTT e marcação de locutor sem apagar timestamps. Não gerar nem separar falantes.

**Portão F2:** comprovar os critérios MVP 1–3 e o consentimento para envio. O caminho de TXT e a prévia de um TXT sintético foram observados; falta o TXT real de aproximadamente 50 min, a análise real de foto, as verificações restantes de voz e os formatos de compartilhamento ainda marcados NOT_RUN. Não tratar o PDF lido pelo ChatGPT como aceite do relatório PDF da F9.

## F3 — Extração e relatório

| ID | Entrega verificável | Prio | Depende de | Estado | Evidência de aceite |
|---|---|---:|---|---|---|
| F3-01 | Esquema versionado de sessão, segmentos, itens e fontes, independente do provedor | P0 | F2 | DONE | Migração e testes; o esquema atual não possui entidade Topic |
| F3-02 | Extrair JSON validado com resumo, ideias, oportunidades, decisões, tarefas, follow-ups e dúvidas | P0 | F3-01 | IN_PROGRESS | S25 validou saída de modelo em reunião sintética; falta amostra real de 53 min e avaliação da cobertura/comportamento em sessão longa |
| F3-03 | Tipos de relatório: livre, reunião, brainstorm, diário, estudo e título personalizado | P1 | F3-02 | DONE | Testes demonstram seções e título por tipo |
| F3-04 | Vincular cada item ao segmento/relógio de origem e permitir abrir a fonte | P0 | F3-02 | DONE | Fixture de teste abre o segmento e relógio corretos; original permanece acessível |
| F3-05 | Deixar sugestões não confirmadas até decisão humana; não inventar responsável ou prazo | P0 | F3-02 | DONE | Fixture prova estado inicial pendente e valores “não identificado”/“não informado” |
| F3-06 | Editar, confirmar, descartar, buscar e excluir relatório e derivados sem alterar o original | P1 | F3-05 | DONE | Fixtures provam edição, estados, busca e exclusão com original preservado |
| F3-07 | Reduzir falsos positivos e duplicatas na extração de tarefas | P1 | F3-02 | IN_PROGRESS | Casos positivos/negativos pt-BR; narração, opinião e fato passado não viram tarefa; duplicata não entra duas vezes |
| F3-08 | Regras de resumo em português, preservação das notas do usuário e regeneração sem apagar a versão anterior | P1 | F3-02 | IN_PROGRESS | Teste por regra e validação no S25; título vazio não vira relatório em branco |
| F3-09 | Correção conservadora da transcrição em arquivo separado, sem reescrever nem traduzir o original | P2 | F2-04, F3-08 | BACKLOG | Só substituições autorizadas de palavras/trechos existentes; teste recusa índices/operações inválidos e compara original byte a byte |

**Estado específico de F3-02:** em 2026-11-04, a tela do relatório enviou a reunião sintética ao modelo após confirmação explícita e recebeu resumo, decisão, tarefa e ideia como itens não confirmados. A validação recusou evidência inventada; responsável, prazo e status enviados pelo modelo não foram aceitos. Testes de serviço, parsing, prompt e diálogo foram registrados. A amostra real de 53 min continua NOT_RUN. O limite atual é 60000 caracteres em uma chamada; acima dele o fluxo usa o rascunho local, sem divisão por tempo.

**Regras da extração de tarefas (F3-07):** extrair somente compromissos claros; ignorar narração, opinião, fatos passados e comentários sobre o app. Limitar a quantidade/tamanho segundo a implementação validada. Deduplicar sem confundir ações diferentes, como “ligar para o pai” e “ligar para a mãe e o pai”. Resposta inválida nunca gera nota vazia. Nenhum item vira tarefa definitiva sem confirmação.

**Regras do resumo (F3-08):** preservar detalhes concretos e marcas do usuário; não iniciar com texto genérico; separar conteúdo anterior e conteúdo da sessão quando aplicável; próximos passos só incluem responsável e prazo ditos explicitamente; devolver conteúdo no formato pedido sem comentário extra. Regenerar conserva o relatório anterior até o usuário aceitar o novo.

**Portão F3:** os critérios do relatório do MVP e a extração com modelo foram demonstrados em reunião sintética no S25. Falta processar uma amostra real de aproximadamente 53 min e comprovar que pontos relevantes e relógios não se perdem. O portão permanece aberto.

## F4 — Exportação

| ID | Entrega verificável | Prio | Depende de | Estado | Evidência de aceite |
|---|---|---:|---|---|---|
| F4-01 | Exportar Markdown com título, data, seções, itens e fontes | P0 | F3 | DONE | Fixture gerado e conferido |
| F4-02 | Exportar PDF legível com acentos pt-BR e hierarquia de títulos | P0 | F4-01 | DONE | PDF aberto no Adobe Acrobat do S25; acentos e hierarquia conferidos; exportação mantém fontes e relógios do relatório |
| F4-03 | Exportar DOCX legível e editável | P0 | F4-01 | DONE | DOCX aberto no Word do S25; acentos, títulos e conteúdo exportado conferidos |
| F4-04 | Compartilhar ou salvar relatório inteiro/selecionado sem enviar a serviço remoto sem consentimento | P1 | F4-01 | DONE | Teste comprova exportação de seleção; folha nativa Android abriu para PDF e DOCX no S25 sem envio automático |

**Portão F4:** cumprido em 2026-11-04. Markdown foi conferido no fixture; o PDF foi aberto no Acrobat e o DOCX no Word do S25, ambos com acentos e títulos corretos. O teste de exportação também cobre relatório completo e seleção de itens. A integração externa escolhida pelo usuário continua sujeita ao consentimento normal do sistema.

## F5 — Fechamento do MVP

| ID | Entrega verificável | Prio | Depende de | Estado | Evidência de aceite |
|---|---|---:|---|---|---|
| F5-01 | Executar e registrar os sete critérios de aceite em fluxo ponta a ponta no S25 Ultra | P0 | F1–F4 | IN_PROGRESS | Checklist completo em docs/F5-01-checklist.md, com resultado e evidência de cada critério |
| F5-02 | Revisar consentimento, dados enviados, armazenamento de chaves/tokens e logs | P0 | F1–F4 | IN_PROGRESS | Migração do cofre no S25 ainda NOT_RUN; revisar também exceções OAuth ainda registradas; relatório em docs/F5-02-privacidade.md |
| F5-03 | Medir sessão longa, geração/exportação e lista de histórico; corrigir regressões relevantes | P1 | F2–F4 | IN_PROGRESS | Medições reproduzíveis no dispositivo com entrada, tempo e memória; números de fixture não substituem medida real; registrar em docs/F5-03-medicoes.md |
| F5-04 | Definir e documentar direção visual móvel AMOLED | P2 | D-017 | DONE | DESIGN.md, D-017 e dez pranchas aprovadas em docs/INDEX.md |
| F5-05 | Fazer auditoria final e conferir atribuições GPL | P0 | F5-01, F5-02, F5-03 | IN_PROGRESS | docs/reviews/F5.md sem CRITICAL/HIGH aberto e resultado da auditoria registrado |

**Portão F5 = MVP pronto.** Os sete critérios abaixo precisam de prova, assim como privacidade, desempenho e auditoria. docs/reviews/F5.md registra AUDIT RESULT: FAIL; o MVP não está pronto. F5V e F6 não substituem este portão.

### Sete critérios de aceite do MVP

1. Conversar por texto e falar com o app em turnos; resposta em áudio é opcional.
2. Compartilhar um TXT real do Samsung e produzir relatório rastreável a trechos e relógios.
3. Analisar uma foto em ao menos um provedor com visão e avisar quando o provedor escolhido não oferece essa capacidade.
4. Selecionar modelo por ID ou por catálogo atualizado sem instalar outro APK.
5. Exportar o mesmo relatório em PDF, DOCX e Markdown com acentuação correta.
6. Editar e confirmar decisões, ideias, tarefas e follow-ups, sem alterar a fonte original; manter histórico ao trocar o modelo.
7. Mostrar o que será enviado, pedir escolha explícita antes do envio remoto e exigir confirmação humana antes de tornar decisão ou tarefa definitiva.

## F5V — Redesign visual

| ID | Entrega verificável | Prio | Depende de | Estado | Evidência de aceite |
|---|---|---:|---|---|---|
| F5V-01 | Aplicar tokens AMOLED e navegação superior sem barra inferior persistente | P1 | D-017, D-022 | DONE | Testes de widget e capturas no AVD; navegação superior e ausência da barra inferior conferidas; validação global no S25 fica em F5V-05 |
| F5V-02 | Aplicar direção visual à timeline, cartões, conhecimento, insights e memórias | P1 | F5V-01 | IN_PROGRESS | Estados principais e famílias de cartão cobertos por testes; comparação com pranchas; discrepâncias registradas |
| F5V-03 | Atualizar entrada, conversa, anexos, importação TXT e acesso explícito a Conversar | P1 | F5V-01 | IN_PROGRESS | Fluxos de abrir, revisar, cancelar, importar e erro cobertos por teste e evidência visual |
| F5V-04 | Atualizar calendário, detalhes, compartilhar, relatórios, configurações, modelos, agentes e backup | P1 | F5V-01 | IN_PROGRESS | Testes de interação e capturas das famílias de tela; sem remoção de funções suportadas |
| F5V-05 | Revisar estados vazios/erro, escala, contraste, leitor de tela e aparelho | P1 | F5V-02, F5V-03, F5V-04 | NOT_RUN | Checklist de acessibilidade, capturas comparadas e validação final no S25 registradas |

**Direção aprovada:** DESIGN.md e as pranchas em docs/INDEX.md. Usar temas/componentes existentes e mapear rotas antes de alterar navegação. Mudança de interação precisa de teste de widget conforme AGENTS.md. F5V não fecha F0–F5.

**Distribuição das pranchas:** 12/13, 14 e 17 em F5V-02; 20 também em F5V-02; 22 em F5V-03; 19 em F5V-04. A 17 usa fábricas de insight existentes; mapas só mostram coordenadas disponíveis, sem inventar grafo. A 20 reaproveita o tour e não edita Memex Guide.md. A 19 usa ShareService e folha nativa. A 22 mantém a importação em TXT; DOCX fica fora por F2-03. O bloqueio por PIN da prancha 15 permanece desativado conforme D-027.

## F6 — Memória longitudinal

| ID | Entrega verificável | Prio | Depende de | Estado | Evidência de aceite |
|---|---|---:|---|---|---|
| F6-01 | Buscar sessões e itens entre registros, começando por texto e avançando para semântica | P0 | D-010, F3 | IN_PROGRESS | Busca semântica em pt-BR avaliada contra busca textual, com evidência dos resultados e teste de consulta fora do tema |
| F6-02 | Listar encaminhamentos aprovados sem incluir sugestões pendentes ou tarefas internas dos agentes | P0 | F3-05 | IN_PROGRESS | Painel no S25 exibe apenas item confirmado; validar estado vazio, busca e acesso pelo fluxo normal |
| F6-03 | Mostrar o que mudou e preservar histórico de versões e motivo | P0 | F3-06 | IN_PROGRESS | Alteração cria revisão; exclusão remove derivados e preserva original; “por quê” tem origem explícita ou aparece como não informado |
| F6-04 | Criar tópicos/projetos como entidade própria e relacioná-los a sessões | P1 | F6-01 | NOT_RUN | Modelo, migração e UI ligados a sessões; não confundir seção de relatório com tópico |
| F6-05 | Organizar tags hierárquicas como area/projeto, com árvore e contagens | P1 | D-014 | IN_PROGRESS | Pai soma filhos; tag simples fica na raiz; tocar filtra; testes e prova visual no S25 |
| F6-06 | Combinar filtros de propriedade e salvar visões locais | P1 | F6-01 | READY | Filtros combinam por E; visão persiste entre reinícios e pode ser renomeada/apagada |
| F6-07 | Mostrar prévia opcional de URL, desligada por padrão | P2 | F5-02 | BACKLOG | Somente HTTP/HTTPS; recusar localhost, IP privado e redirecionamento para privado; sem cookies; aviso de que abrir URL contata o site |
| F6-08 | Mostrar intensidade de atividade por dia no calendário mensal | P2 | D-014 | IN_PROGRESS | Cinco níveis: 0, 1, 2, 3–4, 5+; contraste e leitura de hoje/seleção permanecem corretos |
| F6-09 | Recuperar sessões relacionadas a perguntas com sementes, tópico e limite de relevância | P1 | F6-01, F6-04 | BACKLOG | Sementes de texto permanecem; irmãs por tópico respeitam relevância/orçamento; pergunta fora de tema não recebe sessão alheia |
| F6-10 | Medir embeddings locais multilíngues para busca em português antes de decidir implementação | P2 | F6-09 | BACKLOG | Comparação com busca textual em pt-BR, tamanho do modelo, tempo e memória no S25; sem benefício medido, não implementar |
| F6-11 | Oferecer “Adicionar à agenda” em encaminhamento aprovado com data explícita | P2 | F6-02 | READY | ACTION_INSERT abre calendário com título e descrição; não pede permissão de leitura nem grava evento sem confirmação |

**Definições de F6-05 a F6-08:**

- **F6-05:** a barra / define níveis, por exemplo trabalho/reuniao. A contagem do nó inclui os cartões de seus descendentes. Não renomear/mover tags em lote nem adicionar integração P.A.R.A. sem decisão.
- **F6-06:** propriedades derivadas incluem presença de link, tarefa, tarefa aberta e código. Filtro pode combinar texto, tag e data. Visão salva contém nome e filtro em arquivo local; sem linguagem de consulta aberta e sem sincronização.
- **F6-07:** busca de metadados com cache, limite de tamanho/tempo e sem cabeçalhos/cookies do usuário. A proteção contra requisição a endereços privados é obrigatória antes de ligar a função.
- **F6-08:** usar a contagem existente de cartões por dia. Não acrescentar visão anual nem sequência/streak nesta tarefa.

**Definições adicionais:**

- **F6-09:** a busca textual escolhe as sessões-semente; sessões com tópicos em comum vêm depois por relevância e data, dentro de orçamento de caracteres. Nenhuma semente acima do piso significa nenhuma sessão retornada.
- **F6-10:** só avançar após medida que demonstre vantagem sobre busca textual. O modelo precisa cobrir português; tamanho, memória e tempo no S25 são critérios de produto.
- **F6-11:** abrir o aplicativo de calendário Android com os campos preenchidos via ACTION_INSERT. Não ler a agenda, não sincronizar e não salvar automaticamente.

**Portão F6:** busca semântica, tópico/projeto como entidade própria, histórico com motivo, painel de encaminhamentos e integração de agenda conforme escopo. F6 foi aberta sob D-010 enquanto F0–F5 estavam abertas. Hoje a busca provada é textual; não há entidade de tópico/projeto; o motivo da alteração e a busca semântica continuam NOT_RUN. O MVP continua aberto.

### Ordem das tarefas adicionais F1/F2/F3/F6

1. Provar pendências no S25: F2-09, F2-10, F2-03 e F1-07, em paralelo à F5 quando o aparelho estiver disponível.
2. Implementar F1-09, F3-08 e F3-07 em sequência conforme dependências e prioridade do uso diário.
3. Depois: F2-13, F2-11 e F2-12, respeitando os respectivos estados e dependências.
4. F6: F6-11, F6-08, F6-05, F6-09 e F6-06; F6-04 precisa existir antes da expansão por tópico em F6-09.
5. F3-09, F6-10 e F6-07 só avançam após cumprir seus critérios de medição, segurança ou dependência. F1-05 também depende de chave/endpoint disponível.

## F7 — Voz contínua e ponte para CLIs oficiais

**Objetivo:** avaliar voz mãos-livres com interrupção natural, inferência local opcional e encaminhamento explícito para Claude Code/Codex CLI oficiais no desktop. Esta fase não autoriza captura contínua silenciosa nem uso de credenciais fora dos fluxos oficiais.

| ID | Entrega verificável | Prio | Depende de | Estado | Evidência de aceite |
|---|---|---:|---|---|---|
| F7-01 | Comparar viabilidade, sistemas desktop, licenças, termos, autenticação e limites de dados; decidir escopo antes de código | P0 | F5 fechado | BLOCKED | Matriz de opções, riscos e decisão aceita em docs/DECISIONS.md |
| F7-02 | Medir Ollama/modelos locais para qualidade em pt-BR, requisitos de hardware e privacidade | P1 | F7-01 | BLOCKED | Tabela de qualidade, latência, RAM/VRAM, tamanho e plataforma; modelo escolhido ou caminho descartado com motivo |
| F7-03 | Implementar voz full duplex opcional com controle explícito, interrupção, pausa, cancelar e estado de microfone visível | P0 | F7-01, F7-02 | BLOCKED | Testes de início, interrupção, cancelamento, erro, permissão e liberação do microfone; nenhuma gravação sem ação visível |
| F7-04 | Criar ponte desktop opcional para Claude Code e Codex CLI oficiais, com escopo e prévia de cada solicitação | P0 | F7-01 | BLOCKED | Teste com cada CLI instalada; destino/comando visíveis, confirmação antes de enviar ou executar, cancelamento sem efeito e falha sem perda de contexto |
| F7-05 | Decidir se uma interface MCP é necessária e, se aprovada, restringir ferramentas e permissões | P2 | F7-01, F7-04 | BLOCKED | Decisão explícita; se implementada, teste de acesso somente aos recursos autorizados e ausência de escrita em Quick Query |
| F7-06 | Validar privacidade, acessibilidade, segurança, termos e funcionamento nos sistemas escolhidos | P0 | F7-02 a F7-05 | BLOCKED | Auditoria sem bloqueios, resultados de testes e execução real registrados em STATE.md |

**Portão F7:** requisitos de plataforma e termos decididos; voz e ponte funcionam nos sistemas aprovados; toda captura e todo encaminhamento são iniciados pelo usuário; testes e auditoria sem bloqueios. A ponte não pode contornar autenticação nem termos do fornecedor.

## F8 — NotebookLM

**Objetivo:** permitir levar material selecionado ao NotebookLM por um fluxo opt-in, começando por uma exportação controlada para Google Docs. Não presumir que API, importação direta ou integração comunitária sejam suportadas.

| ID | Entrega verificável | Prio | Depende de | Estado | Evidência de aceite |
|---|---|---:|---|---|---|
| F8-01 | Verificar capacidades atuais, requisitos, termos, autenticação e fluxo suportado pelo NotebookLM | P0 | F5 fechado, F4 estável | BLOCKED | Pesquisa em fontes oficiais e decisão de escopo registrada, incluindo dados que deixam o aparelho |
| F8-02 | Exportar apenas conteúdo selecionado para Google Docs, com destino e conteúdo visíveis antes de autorizar | P0 | F8-01 | BLOCKED | Documento criado na conta escolhida; cancelar não cria/exporta; origem e conteúdo conferidos |
| F8-03 | Avaliar conector comunitário opt-in, licença, segurança, manutenção e compatibilidade | P1 | F8-01, F8-02 | BLOCKED | Avaliação registrada; integrar somente após aprovação e sem tornar caminho comunitário requisito do MVP |
| F8-04 | Avaliar eventual API empresarial apenas se existir caso de uso e benefício comprovados | P2 | F8-01 | BLOCKED | API, custo, termos e necessidade verificados em fonte oficial; decisão aceita antes de qualquer integração |
| F8-05 | Validar consentimento, revogação, segurança, exportação e comportamento quando o serviço está indisponível | P0 | F8-02; F8-03/F8-04 se aprovados | BLOCKED | Testes e revisão demonstram operação opt-in, cancelamento e ausência de upload/sincronização automática |

**Ordem prevista:** Via A, Google Docs; Via B, conector comunitário somente se aprovado; Via C, API empresarial somente se existir e justificar. Cada via depende da conclusão da anterior ou de uma decisão documentada para descartá-la.

**Portão F8:** apenas capacidades confirmadas e autorizadas foram integradas; o usuário escolhe conteúdo, conta e destino; nenhuma sincronização bidirecional ou envio automático ocorre.

## F9 — Meeting Decoder

**Estado:** BLOCKED e fora do MVP. D-029/D-030 autorizam detalhar esta fase, não iniciar implementação.

**Objetivo:** transformar uma conversa, nota própria, transcrição importada ou PDF suportado em um relatório visualmente organizado com resumo, decisões, ideias possíveis, oportunidades, dúvidas, tarefas e follow-ups. Cada sugestão deve apontar para um trecho, relógio ou página. O usuário revisa, edita, confirma ou descarta cada item. A fase inclui Todo pessoal e encaminhamento escolhido para agenda/lembretes.

**Reuso obrigatório:** aproveitar os relatórios, evidências e confirmação da F3; Markdown/PDF/DOCX da F4; busca e encaminhamentos da F6; ações nativas existentes em SystemActionService quando compatíveis. TaskCard não é uma Todo agregada. AsyncTaskListPage é fila interna de agentes e não pode ser reaproveitada como lista pessoal.

**Limites:** PDF com texto selecionável é a entrada inicial prevista. F9-01 decide OCR, outros formatos e suporte “etc.”. Não gravar terceiros silenciosamente, não transcrever conversa corporativa na nuvem sem escolha, não inferir responsável/data, não enviar mensagens e não encaminhar item sem confirmação individual. IA é opcional; sem IA não inventar síntese semântica. Imagens externas exigem origem, licença, proveniência e consentimento. A prioridade de F9 em relação a F7/F8 será decidida após o MVP.

| ID | Entrega verificável | Prio | Depende de | Estado | Evidência de aceite |
|---|---|---:|---|---|---|
| F9-01 | Mapear F3/F4/F6, SystemActionService, TaskCard e destinos; decidir PDF/OCR/outros formatos, Todo/agenda/lembretes, imagens, IA e sistema desktop | P0 | F5 fechado; F3-02/04/05, F4-01/02/03, F6-02/11 | BLOCKED | Matriz requisito → recurso existente/lacuna, fluxo de dados e decisões aceitas antes do código; fila de agentes separada da Todo |
| F9-02 | Criar corpus de 40 exemplos fictícios e fixtures de PDF com saída esperada e fontes | P0 | F9-01 | BLOCKED | Casos positivos/negativos cobrem tarefa clara, hipótese, fato passado, duplicata, dono ausente, data ambígua, PDF selecionável e evidência por página; sem dados pessoais reais |
| F9-03 | Gerar relatório editorial organizado e incluir imagens relacionadas quando houver fonte aprovada, reutilizando categorias existentes e provedor autorizado | P0 | F3-01 a F3-05, F9-02 | BLOCKED | Itens apontam para timestamp ou página; confiança avaliada no corpus; imagens têm proveniência e são ilustrativas, nunca evidência; sem IA não há síntese inventada; hipótese fica separada de decisão |
| F9-04 | Revisar cada sugestão individualmente: editar, confirmar, descartar e resolver ambiguidade/duplicata | P0 | F9-03 | BLOCKED | Evidência e confiança visíveis; data ambígua exige confirmação; descarte não chega aos destinos; duplicata é sinalizada, nunca removida em silêncio |
| F9-05 | Definir origem das imagens e produzir prancha de referência para relatório e Todo antes da UI | P1 | F9-01 | BLOCKED | Prancha alinhada a DESIGN.md e listada em docs/INDEX.md; cada imagem tem origem/licença; imagem existente 04-report-followups.png é reutilizada como referência quando suficiente |
| F9-06 | Criar página Todo pessoal no menu existente, com itens aprovados, estado, prazo, busca e vínculo à fonte; encaminhar sob escolha para calendário/lembrete | P0 | F9-04, F6-02, F6-11 | BLOCKED | Criar/editar/concluir/reabrir/buscar; manter ligação ao relatório; encaminhamento individual confirmado; permissões solicitadas no momento adequado; sem tarefas internas de agentes ou barra inferior persistente |
| F9-07 | Exportar relatório organizado em Markdown/PDF/DOCX e acrescentar JSON/ICS apenas se F9-01 confirmar a necessidade | P1 | F9-03 a F9-06, F4-01 a F4-04 | BLOCKED | Hierarquia, acentos, fontes e imagens preservadas; JSON conserva proveniência; ICS válido usa America/Sao_Paulo e inclui apenas ações confirmadas |
| F9-08 | Entregar os fluxos local-first no Android e no sistema desktop escolhido | P1 | F9-01, F9-05 a F9-07 | BLOCKED | Build e fluxos de captura, revisão, Todo, exclusão e exportação validados nas duas plataformas; sem sincronização externa implícita |
| F9-09 | Fechar qualidade, privacidade, acessibilidade e auditoria da fase | P0 | F9-02 a F9-08 | BLOCKED | Checklist abaixo concluído; provas em STATE.md; auditoria em docs/AUDIT.md sem bloqueios |

### Checklist de aceite da F9

- [ ] Cada tipo de entrada aprovado em F9-01 gera relatório organizado com resumo, decisões, ideias, oportunidades, dúvidas, follow-ups e tarefas aplicáveis.
- [ ] Cada item indica trecho e relógio ou número da página correspondente.
- [ ] IA desligada não produz síntese semântica inventada; IA ligada usa modelo configurado e consentimento de envio.
- [ ] Hipótese não se transforma em decisão/tarefa; pessoa e prazo ausentes ficam como não informados.
- [ ] Confiança é explicada em linguagem compreensível e aparece junto da evidência.
- [ ] Relatórios incluem imagens relacionadas quando houver origem segura e autorizada; cada imagem mostra sua proveniência e não é apresentada como fato da conversa.
- [ ] Prazo como “quinta” sem semana definida fica pendente até confirmação explícita.
- [ ] Cada sugestão pode ser editada, confirmada ou descartada sem alterar o texto original.
- [ ] Ação descartada não chega a Todo, agenda ou lembrete; cada encaminhamento exige confirmação individual.
- [ ] Todo mostra itens abertos/concluídos, permite busca/conclusão/reabertura e mantém vínculo à fonte.
- [ ] A lista Todo não mostra filas nem tarefas internas dos agentes.
- [ ] Possíveis duplicatas são sinalizadas; nada é removido automaticamente.
- [ ] Exclusão permanente remove relatório e derivados associados, sem deixar cópia inesperada.
- [ ] Markdown, PDF e DOCX preservam estrutura, acentos, fontes e imagens; JSON mantém proveniência; ICS respeita America/Sao_Paulo.
- [ ] Imagens externas só entram após escolha/consentimento e têm origem e licença registradas; sem fonte aprovada, o relatório informa que não há imagem relacionada disponível.
- [ ] Android e sistema desktop escolhido passam pelo fluxo completo local-first e pela revisão de acessibilidade.
- [ ] Os 40 exemplos e PDFs sintéticos cobrem positivos, falsos positivos, ambiguidades e evidência; testes unitários, de widget e integração cobrem extração, revisão, destinos, armazenamento, exclusão e exportação.

**Portão F9:** MVP fechado; decisões F9-01 aceitas; todos os itens confirmados seguem pelo fluxo revisável; exclusão, exportação e acessibilidade comprovadas; auditoria sem bloqueios. O que não foi executado continua NOT_RUN em STATE.md.

## Ideias futuras — sem autorização de implementação

| Ideia | Condição para reavaliar |
|---|---|
| Grafo temporal Graphiti ou mapa visual global de tópicos | Depois de F6-04/F6-09 demonstrarem que listas não bastam |
| Gemma local e voz mãos-livres | Dentro de F7, após medir qualidade pt-BR, hardware e privacidade |
| Backup automático versionado que inclua configurações padrão | Revisão futura do backup; definir retenção e restauração antes |
| Separação de falantes/voiceprint | Se as transcrições reais não preservarem identificação suficiente; medir no S25 |
| Interface MCP para agentes externos | Decisão da F7-05 e limites de permissão aprovados |
| Escolher idioma do resumo pelo idioma predominante | Só se o produto voltar a suportar mais de en e pt |
| Biblioteca agregada de fotos, PDFs e áudios | Depois de F2/F6, se a busca atual não bastar |
| Chave Gemini como reserva de transcrição | Se o caminho D-011 falhar ou se os limites medidos forem insuficientes |

Ideias já avaliadas e distribuídas em tarefas ficam nas decisões D-014, D-016 e D-018; não reabrir essas pesquisas sem uma lacuna concreta.

## Histórico de mudanças de escopo

- 2026-11-02 — escopo do MVP e fases: docs/DECISIONS.md.
- 2026-11-02 — D-010 permite F6 em paralelo ao MVP; F7/F8 continuam bloqueadas.
- 2026-11-03 — D-011 transcrição de áudio, D-012 idiomas en/pt, D-013 Gemini OAuth, D-014 ideias do Memos e D-015 Claude OAuth.
- 2026-11-03 — D-016 ideias do Daedalus Echo; D-017 design móvel AMOLED; D-018 ideias do anarlog.
- 2026-11-03/04 — D-020 fallback de modelos; D-021 substituída por D-022, que inicia F5V em paralelo à F5.
- 2026-11-04 — D-023 retirada do espelho chinês e D-024 remoção dos componentes chineses do produto.
- 2026-11-04 — D-025 a D-028: pranchas visuais, microfone explícito e limites de execução; ver docs/DECISIONS.md.
- 2026-11-04 — D-029/D-030: planejar Meeting Decoder na F9 com PDFs, Todo pessoal, encaminhamentos e relatórios PDF/DOCX. F9 permanece bloqueada.
