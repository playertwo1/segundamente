# F2-11 — Plano de medição: transcrição local em português

Data: 2026-11-05. Só plano e pesquisa. **Nada foi medido**, nenhum modelo foi baixado e nenhum código foi escrito. A medição precisa do S25 e de um áudio seu.

## 1. Ponto de partida

- Hoje o app transcreve por dois caminhos: nuvem (`chatgpt.com/backend-api/transcribe`, D-011) e local com SenseVoice (sherpa-onnx).
- **SenseVoice não cobre português**: a documentação do projeto lista chinês, cantonês, inglês, japonês e coreano (D-007; https://k2-fsa.github.io/sherpa/onnx/sense-voice). Por isso o local não serve para fala em pt-BR e a F2-11 existe.
- A pergunta: um modelo multilíngue que cobre português, rodando no aparelho, transcreve áudio longo bem o bastante para dispensar a nuvem?

## 2. Candidatos (pesquisa; níveis de evidência)

| Candidato | O que se sabe | Evidência |
|---|---|---|
| Whisper multilíngue (tiny, base, small) exportado para ONNX pelo sherpa-onnx | Cobre português (99 idiomas). A documentação do sherpa-onnx lista as exportações multilíngues; os arquivos ficam em repositórios `csukuangfj` no Hugging Face | OFICIAL (https://k2-fsa.github.io/sherpa/onnx/pretrained_models/whisper/index.html) |
| Tamanho em int8 | O codificador tiny int8 tem ~12 MB e o decodificador int8 ~86 MB (página de identificação de idioma). Para base e small **não achei número oficial**; blogs dão ~75 MB e ~250 MB sem dizer se é int8 | SECUNDÁRIA, **a medir** (tamanho real do arquivo baixado) |
| Qualidade em pt-BR por tamanho | Nenhum dado confiável | **A MEDIR** |
| Whisper com tempo de execução próprio (outro runtime) | Não pesquisado | Só se o sherpa-onnx falhar |
| Modelos NeMo em português do sherpa-onnx | As notas de versão citam suporte a português; não li detalhes | A pesquisar se o Whisper falhar |
| SenseVoice "Nano" com 31 idiomas | Os idiomas não aparecem na pesquisa; não confirmei português | A confirmar na página do modelo |

## 3. Método

Segue a F6-10: sonda separada em `tools/`, modelos enviados por `adb push` à pasta do app, resultado só em números, nada do seu áudio no repositório.

1. **Áudio de teste.** Um trecho de 3 a 5 minutos de fala sua em pt-BR (reunião ou nota de voz) com um texto de referência corrigido por você. Mais o áudio longo (~50 min) só para tempo e memória.
2. **Modelos.** Whisper tiny, base e small (int8) no sherpa-onnx; SenseVoice atual como referência de tempo (esperado: ruim em português).
3. **Medidas por modelo:** tamanho em disco; tempo de carga; fator de tempo real (segundos de processamento por segundo de áudio) no trecho de 5 minutos e no de ~50 minutos; pico de memória (RSS); aquecimento e bateria em 10 minutos; **erro de palavras (WER)** contra a referência; quantos nomes próprios do dicionário (F2-13) saem certos.
4. **Comparação:** o mesmo trecho pelo caminho da nuvem (D-011), como referência de qualidade, e o resultado pelo SenseVoice local.
5. **Áudio longo:** testar com divisão em janelas, porque Whisper trabalha em blocos de 30 s; verificar se o relógio por trecho continua correto (o app guarda relógio de cada segmento).

## 4. Critério de decisão

Só implementar se o melhor modelo local, no S25, tiver erro de palavras perto do da nuvem (a diferença aceitável é sua decisão), fator de tempo real abaixo de 1 para o áudio de 50 minutos (processar mais rápido que a duração), memória e aquecimento aceitáveis e tamanho dentro do que você aceita no aparelho. Sem isso, a nuvem continua como caminho e o local fica descartado com os números.

## 5. Antes de medir (pedidos a você)

1. Um trecho de áudio de 3 a 5 minutos e o texto de referência corrigido, ou aceitar que eu use a transcrição da nuvem como referência aproximada.
2. O áudio de ~50 minutos para tempo e memória.
3. S25 livre por cerca de uma hora e carregado.
4. Aprovar a sonda como app separado.

Estado: F2-11 segue `READY` no roadmap; este documento é o plano. A execução depende do S25.
