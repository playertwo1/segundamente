# Segunda Mente — referências AMOLED v3, inspiração iOS

Esta versão substitui as pranchas anteriores após a revisão do usuário. O conjunto foi refeito olhando capturas oficiais do Apple Journal, Day One e Things e usando-as como referência visual direta de hierarquia, densidade, espaçamento, cabeçalhos e listas. As capturas oficiais foram usadas durante a geração como inspiração, não foram copiadas para este repositório.

**Estado:** direção visual aprovada pelo dono em 2026-11-03 (D-017); aplicação inicial do tema em andamento na fase F5V. As pranchas 11–23 ampliam a cobertura de captura, registros, perfil, bloqueio, busca, insights, atividade, compartilhamento, onboarding, leitura, importação e localização.

## Direção visual

- Fundo AMOLED puro `#000000`, texto marfim, metadados em cinza discreto e âmbar/cobre em poucos estados selecionados. Azul fica restrito ao ícone do aplicativo.
- Ritmo editorial e conteúdo aberto: cronologia com prévias e datas como Journal e Day One; linhas agrupadas e ações secundárias discretas como Things.
- Poucas superfícies. Priorizar tipografia, espaçamento e divisores finos; evitar cartões repetidos, sombras, grandes painéis e ornamentação.
- Títulos próximos de 20sp, corpo 14–15sp e metadados 12sp, com escala do sistema preservada.
- **Sem barra inferior persistente do app.** Navegação proposta pelo menu compacto no cabeçalho e por ações contextuais; telas internas usam voltar. A navegação não ocupa espaço fixo durante a leitura ou rolagem.
- Chat tem acesso reconhecível no cabeçalho e item textual no menu: “Conversar” / “Conversas”, com balão familiar e chevron. A conversa é uma tela própria com compositor leve.
- Ícones pequenos, simples e da mesma família, sempre junto de rótulo quando representam navegação.

## Fontes oficiais consultadas

- [Apple Newsroom — apresentação do Journal e imagens oficiais](https://www.apple.com/newsroom/2023/12/apple-launches-journal-app-a-new-app-for-reflecting-on-everyday-moments/): cronologia, captura multimídia e revisão de momentos.
- [Apple Support — pesquisar e rever registros no Journal](https://support.apple.com/en-in/guide/iphone/iph6257be047/ios): busca, calendário, filtros e favoritos.
- [Day One — atualização da timeline iOS](https://dayoneapp.com/releases/new-improved-journal-headers/): cor usada como organização e miniaturas para reconhecimento rápido de entradas.
- [Things — atualização visual para iOS 26 e screenshots](https://culturedcode.com/things/blog/2025/09/things-for-os-26/): tratamento atual de listas, espaçamento e controles contextuais.
- [Apple HIG — tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars): uma tab bar é para navegação entre áreas principais; rótulos curtos ajudam a identificar destinos. A proposta desta versão usa navegação pelo topo para responder ao pedido de remover a barra inferior fixa.

## Cobertura

| Arquivo | Telas/estados cobertos |
|---|---|
| `01-timeline-knowledge.png` | Linha do tempo e conhecimento |
| `02-insights-memory.png` | Insights e busca de memórias |
| `03-chat-review.png` | Conversa e revisão antes de enviar |
| `04-report-followups.png` | Relatório e encaminhamentos |
| `05-settings-models.png` | Configurações e provedores/modelos |
| `06-setup-permissions.png` | Configuração inicial e permissões |
| `07-calendar-detail.png` | Calendário e detalhe de memória |
| `08-agents-backup.png` | Agentes/habilidades e backup |
| `09-navigation-chat-icons.png` | Acesso ao chat, menu principal e família de ícones |
| `10-primary-states.png` | Timeline vazia, busca sem resultado e falha de restauração |
| `11-capture-quick-record.png` | Timeline com captura, composição de texto/anexos e gravação rápida |
| `12-timeline-card-types.png` | Tarefa, evento, métrica, humor, pessoa, lugar, link e citação |
| `13-timeline-card-types-2.png` | Galeria, transação, progresso, avaliação, rotina, conversa resumida e detalhe de métrica |
| `14-companion-profile-states.png` | Chat com personagem, perfil em folha, central de ações e indicador do agente |
| `15-app-lock.png` | Desbloqueio biométrico, PIN incorreto e bloqueio temporário |
| `16-global-search.png` | Busca recente, resultados agrupados e estado sem resultados |
| `17-insight-variants.png` | Insights em gráfico, mapa de conexões, timeline e narrativa |
| `18-agent-activity.png` | Atividade de agentes em execução, erro e estado vazio |
| `19-share-poster.png` | Prévia do pôster e folha de compartilhamento do sistema |
| `20-welcome-tour.png` | Três passos do tour inicial e guia em Conhecimento |
| `21-knowledge-reader.png` | Lista de guias e leitor de arquivo Markdown com metadados e ações |
| `22-import-data.png` | Seleção DOCX/TXT, prévia, consentimento e progresso de importação |
| `23-location-context.png` | Preferências de localização, teste e resultado via OpenStreetMap |

## Limites

São referências geradas, não capturas nem implementação do app. Textos e registros são exemplos, não copy aprovada nem prova de funcionalidades. O menu e a ausência de barra inferior são proposta visual; antes de implementar, conciliar os destinos com as rotas reais e preservar gestos, acessibilidade e navegação já existentes. As imagens não foram validadas em aparelho, com TalkBack/VoiceOver ou com fontes ampliadas.

## Decisões das novas pranchas

- **11 — Captura:** o botão `+` abre composição com anexos removíveis; gravação rápida mostra transcrição ao vivo e mantém “Cancelar” como alvo explícito de arraste.
- **12 — Tipos de registro (1):** todos os tipos usam a mesma linha editorial aberta; cada um ganha só um dado ou miniatura própria (por exemplo, métrica = número + mini-gráfico), sem caixa repetida.
- **13 — Tipos de registro (2) e detalhe:** galerias usam uma faixa de miniaturas; progresso, avaliação e rotina usam indicadores compactos. O detalhe de métrica prioriza gráfico e origem, com Editar/Mover/Excluir como ações textuais.
- **14 — Companheiro, perfil e avisos:** a conversa identifica o personagem; o perfil agrupa destinos em linhas; avisos mostram uma ação textual cada, enquanto “Organizando…” fica como indicador discreto separado do sino e do botão `+`.
- **15 — Bloqueio do app:** biometria e PIN são caminhos explícitos; erro informa tentativas restantes e o bloqueio mostra o tempo de espera.
- **16 — Busca global:** recentes ficam em linhas simples; resultados são agrupados por cartões, Conhecimento e Memória; busca vazia explica como continuar.
- **17 — Variantes de insight:** gráfico mostra tendência; mapa, timeline e narrativa são formatos possíveis. A implementação atual não tem dados nem fábrica para um grafo de conexões; o mapa geográfico existente só aparece quando há coordenadas reais.
- **18 — Atividade de agentes:** estados em execução e erro têm rótulo textual e ação; a tela vazia explica quando a atividade aparecerá.
- **19 — Compartilhamento:** a prévia do pôster é mostrada antes da folha nativa; a implementação usa os controles atuais, sem incluir data, editar texto ou compartilhar por proximidade.
- **20 — Tour:** três passos curtos explicam captura, organização e privacidade; o guia permanece encontrável em Conhecimento sem alterar o arquivo do usuário.
- **21 — Leitor de Conhecimento:** Markdown é apresentado como leitura editorial com título, metadados, tags textuais e ações no rodapé.
- **22 — Importação:** a referência mostra DOCX/TXT, mas a F2-03 atual permite somente TXT. A interface lista arquivos TXT, pede confirmação explícita e apresenta progresso/falha; DOCX fica adiado.
- **23 — Localização:** granularidade, frescor, teste e resultado são configuráveis; mapa e busca identificam apenas OpenStreetMap.
