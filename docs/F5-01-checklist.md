# F5-01 — Checklist dos 7 critérios

**Data:** 2026-11-02. **Aparelho exigido:** Galaxy S25 Ultra. **Nesta máquina:** nenhum dos sete critérios foi executado no S25. Cada linha abaixo fica `NOT_RUN` no aparelho. Ponteiros de fixture não substituem essa execução.

| # | Critério | No S25 | O que já existe no repositório |
|---|---|---|---|
| 1 | Conversar por texto e falar, com resposta opcional em áudio | `NOT_RUN` | F2-01 leu a conversa numa segunda instância de armazenamento. F2-02, voz e TTS, está `NOT_RUN`. |
| 2 | TXT real do Samsung vira relatório com trecho e relógio | `NOT_RUN` | O botão de `.txt` está no commit local `db7bc1d`. O parser e o relatório passaram em fixture curto. Não há TXT real de ~50 min nem amostra de 53 min. |
| 3 | Foto analisada em um provedor com visão; aviso nos demais | `NOT_RUN` | F2-05 está `NOT_RUN`. Nenhuma foto foi enviada a um provedor. |
| 4 | Escolher modelo por ID ou catálogo atualizado, sem APK novo | `NOT_RUN` | O catálogo versão 1 e o id manual `my-manual-model` estão testados com cliente falso. Resposta real de OpenAI e de Gemini: `NOT_RUN`. |
| 5 | O mesmo relatório em PDF, DOCX e MD, com acentos | `NOT_RUN` | No fixture, os três formatos saem do mesmo Markdown. PDF é WinAnsi: caractere fora do Latin-1 vira `?` só no PDF. PDF no aparelho, DOCX no Word/Docs e a folha de compartilhamento: `NOT_RUN`. |
| 6 | Editar e confirmar sem perder o original; histórico sobrevive à troca de modelo | `NOT_RUN` | No fixture, aprovar, editar e excluir derivados preservam `original.bin`. A troca de modelo manteve o texto da conversa no armazenamento. Sessão real e modelo ao vivo: `NOT_RUN`. |
| 7 | Nada sai sem escolha explícita; nada vira tarefa ou decisão sem confirmação | `NOT_RUN` | Texto importado passa pela tela de confirmação. Item de relatório nasce `não confirmado`. A trilha de cada chamada de modelo no aparelho: `NOT_RUN`. |

A F5-01 fica `IN_PROGRESS`. O checklist preenchido com evidência no S25 é o que falta para `DONE`.
