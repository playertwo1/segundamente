# F8-01 — Viabilidade: levar material ao NotebookLM

Data: 2026-11-05. Estado: pesquisa feita; **a decisão de escopo é do dono** (seção 5). Nada aqui é código nem autoriza código (D-034).

Níveis de evidência: **OFICIAL** (página do Google lida em 2026-11-05), **SECUNDÁRIA** (blog, índice de pacotes, fórum) e **A MEDIR**.

## 1. O que o NotebookLM aceita como fonte (conta pessoal)

OFICIAL (https://support.google.com/notebooklm/answer/16215270):
- Google Docs, Word (.docx), PDF, texto (.txt), Markdown (.md), CSV, PowerPoint, Google Slides (até 100 slides), ePub, Google Sheets (até 100 mil tokens), imagens, áudio (transcrito ao importar), texto colado, endereços web (só texto) e YouTube público com legenda.
- Limites por fonte: 500 mil palavras ou 200 MB; plano gratuito: 50 fontes por caderno.
- Fontes do Drive sincronizam sozinhas a cada poucos minutos e ao abrir o caderno. Comentários e notas de rodapé não entram. O NotebookLM não edita nem apaga o arquivo original.
- Os limites dos planos pagos variam entre blogs (300 ou 600 fontes) e não foram confirmados em página do Google: **SECUNDÁRIA**.
- Um blog diz que o produto foi renomeado "Gemini Notebook" em 2026-07-16. Não confirmei; a documentação de API usa "Gemini Notebook Enterprise".

## 2. API

| Caminho | Situação | Evidência |
|---|---|---|
| API do NotebookLM Enterprise (`discoveryengine.googleapis.com/v1alpha/.../notebooks/.../sources:batchCreate` e `:uploadFile`) | **Prévia (alfa)**, "como está e com suporte limitado". Exige projeto no Google Cloud, assinatura Enterprise e token do `gcloud`; Docs e Slides exigem acesso ao Drive. Aceita Docs/Slides, texto, web, YouTube e envio de PDF, TXT, MD, DOCX, PPTX, XLSX, áudio e imagem. Não informa limites numéricos. | OFICIAL (https://docs.cloud.google.com/gemini/enterprise/notebooklm-enterprise/docs/api-notebooks-sources) |
| API para conta pessoal | Não encontrei API oficial. Um fórum do Google fala em lançamento sem detalhes; um guia de janeiro de 2026 diz que não é aberta a pessoas. | SECUNDÁRIA, **não confirmado** |
| Clientes comunitários (`notebooklm-py`, `notebooklm-go`, servidores MCP) | Usam protocolo obtido por engenharia reversa. Os próprios READMEs avisam que podem quebrar a qualquer mudança e que uso em volume ou comercial provavelmente viola os termos do Google. | SECUNDÁRIA |

## 3. Opções de integração

| Opção | Como funciona | Dados que saem do aparelho | Risco | Esforço |
|---|---|---|---|---|
| **A. Exportar arquivo e o dono importa** | O app já exporta Markdown, PDF e DOCX (F4, DONE) pela folha nativa. O dono escolhe o NotebookLM como destino ou adiciona o arquivo no caderno. Se o NotebookLM não aparecer na folha de compartilhar: **A MEDIR** no S25. | Só o que o dono envia ao Google, por ação dele. | Mínimo; sem credenciais no app. | Nenhum código novo. |
| **B. Criar um Google Doc do conteúdo escolhido** | O app cria o documento na conta do dono (escopo mínimo de arquivo) e o dono o adiciona ao caderno; o Drive sincroniza depois. Exige um cliente OAuth próprio do app e pedir consentimento. | Conteúdo escolhido vai ao Google Docs, após prévia e autorização. | Médio: novo OAuth; o app já usa um fluxo de terceiros no Gemini (D-013), que não deve servir de base. | Médio. |
| **C. API Enterprise** | Chamar `sources:batchCreate`. | Conteúdo vai ao Google Cloud. | Alto para este caso: alfa, assinatura Enterprise e projeto de nuvem; não serve a uma conta pessoal. | Alto. **Descartada para o MVP.** |
| **D. Cliente comunitário** | Usar o protocolo não documentado. | Mesma conta do dono. | Alto: pode violar os termos e quebra sem aviso. | Médio. **Descartada**; F8-03 só avalia por escrito. |

## 4. Consequências para o desenho

1. Nenhuma opção exige mandar token do dono para um servidor nosso. O app não promete "integração com NotebookLM"; promete "exportar o que você escolher".
2. Antes de qualquer envio (opção B), a prévia mostra o conteúdo e o destino, como na F2-07, e cancelar não cria nada (critério de F8-02).
3. Excluir o relatório no app não apaga a cópia no Google; o aviso diz isso.
4. A exportação segue as regras existentes da F4: itens descartados ficam de fora.

## 5. Recomendação e decisões do dono

Recomendo **A agora**, porque já existe e não exige nada novo. **B só se** o dono quiser o passo de "criar o Doc sozinho", e então como decisão própria (F8-02). C e D ficam descartadas.

Decisões pedidas: (1) começar por A? (2) B entra no plano? (3) o dono usa NotebookLM gratuito, Pro ou Enterprise? Isso muda os limites e se a C seria sequer possível.

Teste que depende do S25 (**NOT_RUN**): o NotebookLM aparece na folha de compartilhar do Android com um PDF e com um DOCX exportados?

## Fontes

- Google, fontes e limites: https://support.google.com/notebooklm/answer/16215270
- Google Cloud, API de fontes (alfa): https://docs.cloud.google.com/gemini/enterprise/notebooklm-enterprise/docs/api-notebooks-sources
- Google Workspace, ativar ou desativar o NotebookLM: https://knowledge.workspace.google.com/admin/users/access/turn-notebooklm-on-or-off-for-users
- Fórum de IA do Google (sem API oficial, afirmação não confirmada): https://discuss.ai.google.dev/t/notebooklm-api/55950
- Clientes comunitários (README e avisos próprios): https://pkg.go.dev/github.com/LocalKinAI/notebooklm-go
