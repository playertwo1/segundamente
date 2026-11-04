# Segunda Mente — direção visual móvel

**Estado:** aprovada pelo dono em 2026-11-03. **Escopo atual:** em implementação na fase F5V (D-022).

## Contrato visual

Segunda Mente deve parecer um diário pessoal contemporâneo: calmo, editorial e fácil de percorrer. A referência combina a timeline com prévias de mídia do Journal e Day One e a hierarquia direta de listas do Things. Use essas referências como inspiração de ritmo e organização, sem copiar marcas ou telas.

- Fundo AMOLED preto puro `#000000`.
- Texto principal marfim `#F3EEE6`; texto secundário cinza quente `#AAA6A0`; divisores discretos `#33312E`.
- Âmbar/cobre `#E99A3D` em seleção, confirmação e ação importante. O azul fica restrito ao ícone do app.
- Poucas superfícies: conteúdo aberto, listas, alinhamento tipográfico e divisores finos. Evitar cartões repetidos, grandes painéis, sombras, gradientes e ornamentação.
- Ritmo compacto e legível: títulos de tela perto de 20sp, corpo 14–15sp, metadados 12sp. Respeitar a escala de texto do sistema; esses valores não são limites máximos.
- Manter a família Inter já usada por `AppTheme`; não adicionar fonte ou dependência para esta direção.
- Ícones simples da mesma família, de preferência contorno. Ícone de navegação vem acompanhado de rótulo; cor sozinha nunca define um estado.
- Alvo de toque confortável mesmo com glifo pequeno: mínimo de 48dp no Android e equivalente recomendado pelo sistema iOS.

## Navegação e conversa

- Não há barra inferior persistente do app nesta direção aprovada.
- Destinos principais ficam num menu compacto acessível pelo cabeçalho; telas internas usam voltar e ações próprias. Manter o menu curto, com nomes literais e hierarquia compatível com as rotas existentes.
- A conversa deve ser encontrada sem adivinhação: ação rotulada **“Conversar”** no cabeçalho, destino **“Conversas”** no menu e uma linha acionável **“Conversar com a Segunda Mente”** perto do início da timeline. A linha mostra balão de conversa e chevron.
- A tela de conversa identifica “Segunda Mente” no cabeçalho. O compositor é estreito, rotulado e separado do conteúdo; a barra de entrada da conversa não vira navegação global.
- Não esconder destinos frequentes atrás de ícones sem nome nem voltar a introduzir uma faixa inferior fixa sem uma nova decisão do dono.

## Composição de telas

- **Timeline e conhecimento:** datas e registros em sequência aberta; títulos, prévias, horários e miniaturas pequenas. Conhecimento usa grupos e linhas simples.
- **Memórias e insights:** busca visível, grupos com nomes curtos e resumos em texto; gráficos discretos quando existirem no produto.
- **Chat e revisão:** conversa alinhada por autor e horário, compositor leve; prévia do texto que será enviado e confirmação clara.
- **Relatório e encaminhamentos:** leitura editorial com seções, trechos e tarefas em lista; sem transformar cada parágrafo em cartão.
- **Configurações, modelos, agentes e backup:** grupos nomeados, linhas com rótulo e estado secundário, separadores finos.
- **Calendário e detalhe:** mês compacto, seleção âmbar discreta, lista cronológica e mídia integrada ao detalhe.
- **Estados vazios, busca e erro:** uma frase que explique o estado e uma ação textual objetiva; sem ilustrações dominantes.

## Acessibilidade e implementação

- Preservar contraste forte sobre preto, fontes ampliadas, VoiceOver/TalkBack, ordem de foco e alvos de toque.
- Fornecer rótulo semântico a cada ícone funcional; sucesso, erro e seleção não dependem apenas de cor.
- A direção visual não altera fluxos, dados ou regras dos serviços. Conservar MVVM, navegação e fábricas de cartões existentes; fazer a mudança em `lib/ui/core/themes/` (`AppColors`/`AppTheme`) em vez de criar outro sistema de tokens.
- Implementar por família de tela, conferindo a rota e o estado real antes de mudar a composição. Mudanças de UI exigem widget tests para o comportamento visível, conforme `AGENTS.md`.
- Antes de fechar F5-04, registrar capturas antes/depois no S25 Ultra, conferir navegação e rolagem sem barra fixa, texto ampliado, contraste e leitor de tela. Até isso acontecer, F5-04 continua `NOT_RUN`.

## Referências aprovadas

Vinte e três pranchas da versão escolhida estão em [`.impeccable-mobile/references/amoled-v3-ios/`](.impeccable-mobile/references/amoled-v3-ios/README.md). Use-as como direção, não como copy ou especificação literal: textos e dados nas imagens são ilustrativos.

Fontes oficiais usadas para a inspiração: [Apple Journal](https://www.apple.com/newsroom/2023/12/apple-launches-journal-app-a-new-app-for-reflecting-on-everyday-moments/), [Day One](https://dayoneapp.com/releases/new-improved-journal-headers/) e [Things para iOS 26](https://culturedcode.com/things/blog/2025/09/things-for-os-26/). A decisão está registrada em [D-017](docs/DECISIONS.md#d-017--direção-visual-móvel).
