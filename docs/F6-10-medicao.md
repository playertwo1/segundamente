# F6-10 — Medição de embeddings locais para busca em português

Data: 2026-11-05. Estado: **etapa 1 (PC) e etapa 2 (S25: tempo e memória) feitas; falta tokenizador em Dart, bateria em uso longo e teste com notas reais**. Nada foi implementado no app.

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

## Etapa 2 — S25 Ultra (2026-11-05)
Sonda separada, fora do app: `tools/f610_probe` (Flutter, `flutter_onnxruntime` 1.9.0, build release, CPU). Os textos já chegam tokenizados do PC (o tokenizador em Dart **não** foi medido). Resultado bruto: `docs/medicoes/f6-10/resultado-s25.json`. Bateria 70%, 38,9 °C; a medição durou poucos segundos.

| Modelo | Arquivo | Carregar | Por nota (média / p95) | Por consulta | RAM do processo (antes → depois / pico) | Cosseno mínimo vs PC | Acerto@3 "par" | Acerto@3 "lex" |
|---|---|---|---|---|---|---|---|---|
| e5-small int8 | 118 MB | 0,35 s | 9,8 ms / 23 ms | 4 ms | 167 → 410 / 472 MB | 0,997 | 17/22 | 12/12 |
| MiniLM-L12 fp32 | 470 MB | 0,91 s | 10,4 ms / 14 ms | 6 ms | 291 → 693 / 1134 MB | 1,000 | 21/22 | 12/12 |

- Os acertos no aparelho batem com o PC (0,77 e 0,95), então o modelo roda certo no Android.
- Indexar 1.000 notas curtas levaria ~10 s com qualquer um dos dois (estimativa linear a partir de 48 notas; notas longas custam mais).
- O e5 int8 usa ~240 MB de RAM acima da linha de base e 118 MB de disco. O MiniLM fp32 é 4 vezes maior em disco e pico de ~1,1 GB (o pico do MiniLM inclui o e5 carregado antes no mesmo processo, então está superestimado). A versão int8 do MiniLM (118 MB) não foi testada e é o candidato óbvio.
- O APK da sonda ficou com 125,8 MB, a maior parte do ONNX Runtime para todas as arquiteturas; no app principal isso aumentaria o APK e precisa de filtro de arquitetura (`arm64-v8a`).
- Não medido: bateria e calor em uso real, nota longa (limite de 128 tokens), tokenizador SentencePiece em Dart (maior trabalho restante), notas reais do dono.

### MiniLM-L12 int8 (arm64), medido em seguida no S25 e no PC
O arquivo `model_qint8_arm64.onnx` (118 MB) foi enviado no lugar do fp32, então o log o chama de `minilm_fp32` (o campo `modelo_mb` = 118 mostra que é o int8). Nova rodada: o e5 int8 repetiu os resultados da primeira.

| MiniLM-L12 int8 | Valor |
|---|---|
| Arquivo / carregar | 118 MB / 0,23 s |
| Por nota (média / p95) / por consulta | 6,8 ms / 12 ms / 6,8 ms |
| RAM do processo | 278 → 413 MB, pico 485 MB (o pico inclui o e5 rodado antes no mesmo processo) |
| Cosseno mínimo vs fp32 do PC | 0,981 |
| Acerto@3 reformuladas / mesmas palavras | 20/22 (0,91) / 12/12 |
| PC: acerto@1 reformuladas / MRR | 0,77 / 0,86 |
| PC: fora do tema, acertos acima da maior nota fora do tema (0,48) | 56% |

- A quantização custou pouco: 21/22 → 20/22 e cosseno mínimo 0,98. O S25 e o PC concordam (20/22).
- Comparado ao e5 int8 (mesmo tamanho): o MiniLM int8 acerta mais nas reformulações (0,91 contra 0,77), mas separa pior o que está fora do tema (56% contra 88%). Como o app teria texto primeiro e corte de nota, o corte é o ponto fraco do MiniLM; o e5 tem o corte melhor e o acerto menor. Escolher entre os dois exige as notas reais do dono; com este corpus pequeno, a diferença de 2 a 3 acertos não é conclusiva.
