# F6-10 — Medição de embeddings locais para busca em português

Data: 2026-11-05. Estado: **etapa 1 (qualidade, no PC) feita; etapa 2 (S25: tamanho, tempo, memória) NOT_RUN**. Nada foi implementado no app.

## Como foi medido
- Script e dados: `docs/medicoes/f6-10/bench.py` e `corpus.json` (reproduzível: `pip install onnxruntime tokenizers numpy huggingface_hub`, baixar os modelos citados e rodar).
- Corpus: **48 notas e 40 consultas escritas por mim**, em português, sem dados do dono. 12 consultas "lex" (usam palavras da nota, algumas sem acento), 22 "par" (reescrevem a ideia sem repetir as palavras) e 6 "fora do tema".
- Baseline: SQLite FTS5 (`unicode61`, sem acento), ranking BM25, em duas versões: qualquer palavra (OU) e todas as palavras (E). O app usa FTS5 com outro tokenizador (Jieba) e busca textual direta; esta é uma aproximação, não o código do app.
- Modelos (ONNX, CPU, média das palavras, vetor normalizado): `multilingual-e5-small` (MIT; fp32 470 MB, int8 118 MB; prefixos `query:`/`passage:`) e `paraphrase-multilingual-MiniLM-L12-v2` (Apache-2.0; fp32 470 MB; versão int8 de 118 MB existe e não foi testada).

## Resultado (consultas com resposta certa)
| Método | "lex" acerto@3 | "par" acerto@1 | "par" acerto@3 | "par" MRR |
|---|---|---|---|---|
| Texto, qualquer palavra | 1,00 | 0,18 | 0,27 | 0,25 |
| Texto, todas as palavras | 0,75 | 0,00 | 0,00 | 0,00 |
| e5-small int8 (118 MB) | 1,00 | 0,59 | 0,77 | 0,70 |
| e5-small fp32 | 1,00 | 0,59 | 0,82 | 0,73 |
| MiniLM-L12 fp32 | 1,00 | 0,73 | 0,95 | 0,83 |

Fora do tema (6 consultas): o texto "qualquer palavra" devolveu resultado nas 6 (palavras como "de" e "como"); "todas as palavras" devolveu em 0. Os embeddings sempre devolvem alguém, então precisam de um corte de nota. Com o corte logo acima da maior nota fora do tema: e5 int8 mantém 88% dos acertos, e5 fp32 82%, MiniLM só 53%.

## Leitura
- Em consulta que repete as palavras da nota, o texto já basta (e embeddings empatam ou perdem em acerto@1).
- Em consulta que só reformula a ideia, os embeddings ganham muito: acerto@3 de 0,27 para 0,77–0,95.
- A quantização int8 do e5 custou pouco (0,82 → 0,77 em acerto@3) e deixa o modelo em 118 MB.
- Para recusar pergunta fora do tema, o e5 separa melhor que o MiniLM.
- Caminho que esses números sugerem: texto primeiro, embeddings só quando o texto não achar ou achar pouco, com corte de nota. Isto é hipótese, não decisão.

## Limites (leia antes de confiar)
- Corpus pequeno, inventado por quem escreveu as consultas: as reformulações podem ser mais fáceis ou mais difíceis que as do dono. Falta repetir com notas reais, com o consentimento do dono e sem sair do aparelho.
- Tempos de PC (16 núcleos) não valem para o S25.
- Não testei EmbeddingGemma (exige aceite dos termos Gemma) nem o Universal Sentence Encoder do `daedalus-echo`.
- Etapa 2, `NOT_RUN`: rodar o modelo no S25 (tamanho no aparelho, tempo por nota, pico de RAM, bateria ao indexar). Falta decidir como executar ONNX no Flutter; o app já usa `sherpa_onnx`, que não faz embeddings de texto. Nenhuma dependência foi escolhida.
- Critério do ROADMAP: "sem benefício medido, não implementar". Há benefício medido no PC em consultas reformuladas; a decisão de implementar depende da etapa 2 e do dono.
