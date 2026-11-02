# F5-03 — Medições

**Data:** 2026-11-02. Fixture sintético, nesta máquina. Não é o TXT do Samsung e não é o S25. A F5-03 fica `IN_PROGRESS`. Nenhum código de desempenho foi alterado: os números não mostraram fila nem estouro.

## Comando

`flutter test --reporter expanded test/domain/models/f5_measurements_test.dart` (no mesmo processo que o teste de log).

Saída:

```text
F5-03 parse_ms=15 segments=1500
F5-03 export_ms=25 items=100
00:00 +3: All tests passed!
```

O `+3` inclui os dois testes de log. O teto do teste é 5000 ms. Os tempos medidos não substituem esse teto.

## O que foi medido

`TranscriptImport.parse` em 1500 pares relógio + `frase N`, um a cada 2 segundos, cobrindo 50 minutos. Texto ASCII. Resultado: 1500 segmentos, `timestampsFound`, 15 ms.

`exportSessionReportBytes` de um relatório de reunião com 100 decisões `não confirmado`, nos três formatos, 25 ms. A data de exportação do teste é `2026-11-02 15:04`.

## O que não foi medido

`ChatSessionStorage.listSessionMetadata` não entrou no teste. Esse método chama a migração e a varredura do YAML antigo. Lista de histórico: `NOT_RUN`. Aparelho: `NOT_RUN`.
