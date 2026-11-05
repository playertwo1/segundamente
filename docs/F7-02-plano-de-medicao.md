# F7-02 — Plano de medição de modelo local no S25

Data: 2026-11-05. Só plano e pesquisa (D-034). **Nada foi medido** e nenhum modelo foi baixado. A medição precisa do S25 e segue o método da F6-10 (sonda separada em `tools/`, fora do app e do APK principal).

## 1. Pergunta

Um modelo de linguagem pequeno, rodando no aparelho, serve para alguma tarefa do app em pt-BR (resumo curto, classificar tarefa x opinião, responder sobre notas) sem mandar texto para a nuvem? Se não houver ganho medido, o caminho é descartado com o motivo (critério da F7-02).

## 2. Candidatos (pesquisa, níveis de evidência)

| Candidato | O que se sabe | Evidência |
|---|---|---|
| Gemma 3 1B (versão int4 da comunidade LiteRT) | ~529 MB, quantização int4, roda no Android por LiteRT e pela API de inferência de LLM do MediaPipe; o Google sugere 4 GB de memória ou mais. O `daedalus-echo` usa esse modelo para resumo (D-033). | SECUNDÁRIA (blog do Google e cartão do repositório; https://developers.googleblog.com/en/gemma-3-on-mobile-and-web-with-google-ai-edge/) |
| Licença do Gemma | O repositório é protegido: exige aceitar a licença Gemma; o texto dos Termos de Uso **não foi lido** | **A CONFIRMAR** antes de baixar ou distribuir (compatibilidade com GPL-3.0 do projeto) |
| Qualidade em português do Gemma 3 1B | Nenhum dado encontrado | **A MEDIR** |
| Outros modelos pequenos (por exemplo, famílias de 1 a 4 bilhões de parâmetros) | Não pesquisados nesta rodada | A pesquisar só se o Gemma 3 1B falhar |

## 3. Método proposto (reaproveita a F6-10)

- **Sonda separada** em `tools/f7_02_probe/`, sem tocar no app principal; o modelo entra pelo `adb push` na pasta do app, não por download dentro do app.
- **Corpus**: os 40 casos fictícios da F9-02 (`docs/medicoes/f9-02/corpus.json`) para classificação de tarefa x opinião x fato passado, mais 10 textos curtos para resumo. Dados reais só com o dono vendo e só números no resultado, como na F6-10.
- **O que medir**: tamanho em disco; tempo de carga; tempo até o primeiro token; tokens por segundo; pico de memória (RSS); temperatura e bateria em 5 minutos de uso contínuo; qualidade (acerto na classificação contra o "esperado" do corpus; resumo julgado às cegas pelo dono em escala de 3 notas).
- **Linha de comparação**: a regra por lista de palavras da F3-07 no mesmo corpus (acerto atual) e o modelo remoto já configurado (qualidade de referência).
- **Critério de decisão**: só vale implementar se o modelo local igualar ou superar a regra atual no corpus e responder em tempo razoável (a definir com o dono, por exemplo menos de 10 s para um resumo curto) sem estourar memória do aparelho.

## 4. Fora de escopo

Ollama no PC, ponte para CLIs e voz full duplex (F7-03). O duplex segue sem exemplo e sem teste; medir eco e bateria é um protótipo descartável à parte, também só no S25.

## 5. Antes de medir (decisões e pré-requisitos do dono)

1. Aceitar ou recusar baixar o Gemma 3 1B depois da leitura dos Termos de Uso (eu leio o texto antes de qualquer download).
2. S25 livre por cerca de uma hora e carregado.
3. Aprovar a sonda como app separado, como na F6-10.

Estado: F7-02 continua `BLOCKED` para execução; este documento é o plano.
