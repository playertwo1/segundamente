# Prompt para o Codex: imagens dos 15 personagens

Cole o bloco abaixo no Codex. Ele gera uma imagem por personagem. Os textos e os ids
dos personagens estão em `lib/l10n/app_localizations_ext_pt.dart` (`defaultCharacters`).

---

Você vai criar 15 retratos de personagem para o app Segunda Mente, um app de notas
pessoal em tema escuro (fundo preto AMOLED). Não altere código nem texto. Só produza as
imagens e os arquivos descritos em "Entrega".

## Estilo comum (vale para as 15)

- Ilustração de linha, plana e limpa, de busto (cabeça e ombros), centralizado.
- Fundo preto puro `#000000`, sem textura e sem degradê.
- Traço marfim `#F3EEE6`, com no máximo um detalhe em âmbar `#E99A3D` por imagem.
- Preenchimento só com preto, cinza escuro `#1C1B19` e marfim. Sem outras cores.
- Rostos simples e expressivos, sem realismo e sem caricatura exagerada.
- Mesmo peso de traço e mesmo nível de detalhe nas 15, para parecerem uma família.
- Sem texto, sem letras, sem logotipo, sem moldura, sem marca d'água.
- Adultos de aparências variadas (idade, gênero e traços diferentes entre os personagens).
- Não copie personagens, marcas ou pessoas reais.

## Os 15 personagens

Cada linha traz o `id` (nome do arquivo), o nome e o que a imagem deve passar.

1. `socio_tecnico` — Sócio técnico. Pessoa de postura franca, olhando de frente, sobrancelha levemente levantada. Detalhe âmbar: um pequeno marcador de código `</>` no bolso ou na lapela.
2. `revisor_chato` — Revisor chato. Óculos, olhar atento e cético, caneta atrás da orelha. Detalhe âmbar: um visto ou lupa pequena.
3. `cobrador_prazo` — Cobrador de prazo. Expressão serena e firme, relógio de pulso bem visível. Detalhe âmbar: o ponteiro do relógio.
4. `memoria_projeto` — Memória do projeto. Pessoa calma com um caderno ou arquivo aberto no colo. Detalhe âmbar: um marcador de página.
5. `advogado_diabo` — Advogado do diabo. Sorriso de canto, cabeça inclinada. Detalhe âmbar: uma pequena marca de interrogação, sem chifres nem cara de demônio.
6. `gerente_escopo` — Gerente de escopo. Pessoa organizada segurando uma tesoura grande ou uma régua. Detalhe âmbar: a linha de corte.
7. `parceiro_foco` — Parceiro de foco. Olhar concentrado, mão apontando para um único ponto à frente. Detalhe âmbar: um ponto único.
8. `guardiao_energia` — Guardião de energia. Pessoa com aparência descansada, olhos suaves, caneca ou lua pequena ao lado. Detalhe âmbar: a lua ou o vapor da caneca.
9. `diario_bordo` — Diário de bordo. Pessoa escrevendo à mão em um diário, de lado. Detalhe âmbar: a ponta da caneta.
10. `calmo_crise` — Calmo na crise. Expressão tranquila, mãos abertas em sinal de "calma". Detalhe âmbar: uma pequena chama estável ao fundo.
11. `provocador_criativo` — Provocador criativo. Olhar travesso, uma sobrancelha mais alta, cabelo bagunçado. Detalhe âmbar: uma centelha ou lâmpada pequena.
12. `tradutor` — Tradutor. Pessoa simpática com um balão de fala e um segundo balão menor com formas simples. Detalhe âmbar: a seta entre os dois balões.
13. `amigo_bar` — Amigo de bar. Sorriso de lado, relaxado, camisa com a gola aberta, copo na mão. Detalhe âmbar: o copo.
14. `financas_burocracia` — Finanças e burocracia. Pessoa séria e cuidadosa com uma pasta de documentos e uma calculadora simples. Detalhe âmbar: o carimbo.
15. `curador` — Curador. Pessoa com um fio ligando pequenos itens (livro, link, vídeo) ao lado da cabeça. Detalhe âmbar: o fio que liga os itens.

## Entrega

- Formato PNG, 1024 × 1024 px, fundo preto sólido (sem transparência).
- Um arquivo por personagem, nomeado `<id>.png` (por exemplo `socio_tecnico.png`).
- Salve em `assets/characters/` (crie a pasta).
- Também gere `assets/characters/contact_sheet.png`, uma folha 5 × 3 com as 15 imagens
  lado a lado, só para revisão.
- Cada imagem deve continuar legível em círculo de 40 px (o rosto no centro, sem detalhes
  importantes nos cantos).

## O que NÃO fazer

- Não mude `pubspec.yaml`, código Dart nem os textos dos personagens. A ligação das
  imagens ao app é uma etapa separada.
- Não use fotos, rostos de pessoas reais ou estilos de artistas vivos.
- Não coloque nomes, rótulos ou legendas dentro das imagens.
- Se um personagem ficar parecido demais com outro, refaça o menos fiel à descrição.

Ao terminar, liste os 15 arquivos gerados e diga se algum precisou de mais de uma tentativa.
