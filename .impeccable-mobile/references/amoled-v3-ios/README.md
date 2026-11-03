# Segunda Mente — referências AMOLED v3, inspiração iOS

Esta versão substitui as pranchas anteriores após a revisão do usuário. O conjunto foi refeito olhando capturas oficiais do Apple Journal, Day One e Things e usando-as como referência visual direta de hierarquia, densidade, espaçamento, cabeçalhos e listas. As capturas oficiais foram usadas durante a geração como inspiração, não foram copiadas para este repositório.

**Estado:** direção visual aprovada pelo dono em 2026-11-03 (D-017); aplicação no app ainda não iniciada.

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

## Limites

São referências geradas, não capturas nem implementação do app. Textos e registros são exemplos, não copy aprovada nem prova de funcionalidades. O menu e a ausência de barra inferior são proposta visual; antes de implementar, conciliar os destinos com as rotas reais e preservar gestos, acessibilidade e navegação já existentes. As imagens não foram validadas em aparelho, com TalkBack/VoiceOver ou com fontes ampliadas.
