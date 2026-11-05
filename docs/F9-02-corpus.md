# F9-02 — Corpus de 40 exemplos fictícios

Data: 2026-11-05. Dados, não código (D-034). Arquivo: `docs/medicoes/f9-02/corpus.json`, gerado por `gerar_corpus.py`, que confere 40 casos, ids únicos e tipos válidos. Todos os nomes e fatos são inventados.

| Categoria | Casos | O que verifica |
|---|---:|---|
| `tarefa_clara` | 6 | responsável e prazo ditos; nota própria |
| `hipotese_opiniao` | 5 | opinião, suposição e intenção vaga não viram tarefa |
| `fato_passado` | 5 | passado vira resumo (também em 1ª pessoa do plural) |
| `duplicata` | 3 | uma tarefa, duas evidências; duplicata sinalizada, nunca removida em silêncio |
| `dono_ausente` | 4 | não inferir responsável |
| `data_ambigua` | 4 | "quinta", "dia 3", "semana que vem" ficam pendentes |
| `decisao` | 3 | decisão explícita x alternativas em aberto |
| `duvida` | 3 | pergunta sem resposta vira dúvida; respondida não |
| `followup` | 2 | voltar a um assunto |
| `pdf_pagina` | 5 | evidência por página; PDF escaneado sem texto |

Formato de cada caso: `id`, `categoria`, `origem` (conversa, nota ou pdf), `texto` (com relógio `[hh:mm:ss]` ou página `[p.N]`), `esperado` (lista de itens com `tipo`, `texto`, `responsavel`, `prazo`, `evidencia`, `estado`) e `nota`. Dono ou prazo ausentes valem "não informado". Todo item nasce `sugerido`; nenhum vem confirmado.

Correspondência com o código atual (`ReportItemKind`, `ReportItemStatus`): `tarefa`=`task`, `decisao`=`decision`, `ideia`=`idea`, `duvida`=`question`, `followup`=`followUp`, `resumo`=`summary`; `sugerido`=`unconfirmed`. `oportunidade` (`opportunity`) não tem caso: o corpus não a cobre ainda.

## O que ainda falta (por isso F9-02 fica `IN_PROGRESS`)

- **Arquivos PDF de verdade.** Os cinco casos `pdf_pagina` têm o texto com marcas de página, mas não os binários. Gerar PDFs selecionáveis e um escaneado exige uma ferramenta de geração; não instalei nenhuma. O app só escreve PDF (`session_report_export.dart`); não lê texto de PDF.
- **Execução do corpus.** Rodar os 40 casos contra a extração atual precisa de modelo real. Fica para depois do desenho da F9-03.
- **Revisão do dono.** Os "esperados" são a minha leitura; o dono pode discordar de casos limítrofes (por exemplo `c24`, `c27` e `c33`).

Parte dos casos negativos (`hipotese_opiniao`, `fato_passado`, `duplicata`) repete frases já cobertas pela regra de tarefas da F3-07 (`test/domain/models/session_report_test.dart`), de propósito, para o corpus servir de régua comum.
