# F9-01 — Mapeamento: requisito → recurso existente → lacuna

Data: 2026-11-05. Só leitura do código e da documentação (D-034); nenhuma decisão abaixo está aceita. Onde a F9-01 pede decisão do dono, a seção 3 lista a pergunta e a minha recomendação.

## 1. Requisito → o que já existe

| Requisito da F9 | Recurso existente | Lacuna |
|---|---|---|
| Relatório com resumo, decisões, ideias, oportunidades, dúvidas, tarefas e follow-ups | `SessionReport` e `ReportItemKind` (`summary, idea, opportunity, decision, task, followUp, question`) em `lib/domain/models/session_report.dart`; extração por modelo com JSON validado (F3-02) | Nenhuma de tipo. Falta organização visual "editorial" (F9-03) |
| Cada item aponta trecho e relógio | `ReportSegment` tem `clock`; o item guarda trecho literal obrigatório | **Não há campo de página.** PDF exige `page` no segmento e no item |
| Revisar item: editar, confirmar, descartar | `ReportItemStatus { unconfirmed, approved, discarded }`; edição com motivo e histórico de revisões (F3-05, F6-03) | Nenhuma de modelo. Tela por item já existe; F9-04 só ajusta ambiguidade e duplicata |
| Não inferir responsável nem data | `sessionReportFromModelJson` ignora pessoa, data e status vindos do modelo | Dono e prazo ficam em branco; não há campo "não informado" visível nem confirmação de data ambígua |
| Fato passado e opinião não viram tarefa; duplicata não entra duas vezes | Regras da F3-07 (lista de palavras pt-BR) | A duplicata é descartada em silêncio; F9 pede **sinalizar**, não remover |
| Entrada: conversa, nota, TXT/SRT/VTT | Importação de TXT, SRT e VTT, colar texto, voz (F2) | Nenhuma |
| Entrada: **PDF com texto selecionável** | PDF pode ser anexado e enviado a um provedor que o aceite (ChatGPT lê `input_file`) | **Não há leitura local de texto de PDF**: não existe biblioteca de PDF no `pubspec.yaml`. Sem provedor, o PDF não vira texto |
| PDF escaneado / imagem | `google_mlkit_text_recognition` (OCR no aparelho) para imagens | Falta transformar páginas de PDF em imagens (precisa de renderizador de PDF); decisão de OCR pendente |
| Resumo sem IA não inventa síntese | Há rascunho local determinístico (F3-02) | Definir o que o rascunho local faz com PDF |
| Todo pessoal, com busca, conclusão e vínculo à fonte | Nada equivalente. `TaskCard` não é lista agregada; `AsyncTaskListPage` é a fila interna dos agentes e **não** pode ser reaproveitada | Lista nova, entidade nova, rota nova no menu existente (F9-06) |
| Encaminhar para agenda ou lembrete, item a item | `SystemActionService` (agenda e lembrete, estado `pending` para revisão) e `NativeActionService.addReminder`; F6-11 abre o calendário por `ACTION_INSERT` sem pedir leitura | Falta ligar item aprovado → ação com confirmação individual e permissão no momento certo |
| Encaminhamentos aprovados | F6-02 lista só itens aprovados (painel de encaminhamentos) | Pode ser a fonte da Todo ou ficar separado: decisão pendente |
| Exportar Markdown, PDF, DOCX | F4 (DONE): `session_report_export*.dart`. PDF escrito à mão (fonte Helvetica, caracteres até 255) e DOCX por `archive` | Imagens no relatório não são suportadas; texto fora de WinAnsi vira "?" no PDF |
| Exportar JSON e ICS | Não existe | Só se a decisão confirmar a necessidade; ICS em America/Sao_Paulo apenas de ações confirmadas |
| Imagens relacionadas com proveniência | Não existe. O app só tem as imagens do próprio usuário e retratos locais | Sem fonte aprovada, o relatório diz que não há imagem; busca ou geração é decisão pendente |
| Excluir relatório e derivados | A exclusão da sessão apaga relatório, versões e tópicos ligados (F3-08, F6-04) | Incluir Todo, ações e exportações geradas |
| Sistema desktop | O projeto só tem `android/` e `ios/`; **não há alvo desktop** | Decisão do dono (seção 3) e criação do alvo, que é trabalho grande |
| Android e acessibilidade | F5V cobre telas atuais | F9-09 |

## 2. Fluxo de dados proposto (para decidir)

1. Entrada (texto, TXT, áudio já transcrito, PDF) → segmentos com relógio ou página.
2. Extração: local determinística sempre; por modelo só se o dono ligou a IA e confirmou o envio (F2-07). Com IA desligada nenhum item semântico é inventado.
3. Itens nascem `unconfirmed`. O dono edita, confirma ou descarta um por um.
4. Item aprovado pode ir para a Todo. Da Todo, ou do item, o dono escolhe encaminhar para agenda ou lembrete, uma ação por vez, com confirmação.
5. Descartado não chega à Todo, agenda ou lembrete.
6. Exportação reaproveita a F4 e inclui só o que o dono selecionou.

## 3. Decisões que a F9-01 pede ao dono

| # | Pergunta | Minha recomendação |
|---|---|---|
| 1 | **PDF**: ler o texto no aparelho (nova dependência de PDF) ou depender de um provedor que aceite PDF? | Leitura local só de texto selecionável, para o texto não sair do aparelho sem escolha. Avaliar dependências com licença compatível antes (GPL-3.0 do projeto) |
| 2 | **PDF escaneado / OCR** entra? | Fora da primeira entrega. O app avisa "sem texto selecionável" |
| 3 | **Outros formatos** ("etc."): DOCX, imagem, planilha? | Só PDF e os de texto já aceitos; DOCX depois |
| 4 | **Todo**: lista própria nova, ou reaproveitar o painel de encaminhamentos da F6-02? | Lista própria, alimentada por itens aprovados, mantendo o vínculo à fonte |
| 5 | **Lembretes**: usar o `SystemActionService` existente? | Sim; ação individual, sem permissão antecipada |
| 6 | **JSON e ICS**? | Só ICS se houver pedido real; JSON mantém proveniência e é barato |
| 7 | **Imagens relacionadas**: de onde? | Nenhuma fonte externa. Só imagens do próprio dono, com origem registrada |
| 8 | **Sistema desktop**: qual? Hoje não existe alvo desktop | Adiar; o dono usa Windows 11, mas criar o alvo Flutter Windows é projeto próprio |
| 9 | **Ordem**: F9 antes ou depois de F6/F7? | Depois do fechamento do MVP e das decisões da F5-02 |

## 4. Estado

F9-01 fica `IN_PROGRESS`: o mapeamento está feito; falta o dono decidir a seção 3. F9-02 a F9-09 seguem `BLOCKED`, exceto o corpus de dados já gerado (`docs/F9-02-corpus.md`).
