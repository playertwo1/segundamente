# STATE — ponto de retomada

**Atualizado:** 2026-11-02 · **Fase ativa:** F0 — Fundação · **Estado:** READY

## O que existe hoje (confirmado)
- Fork público `playertwo1/segundamente` de `memex-lab/memex` (Flutter, GPL-3.0), `main` ainda no código do Memex.
- No código: login OAuth de OpenAI (`lib/data/services/openai_auth_service.dart`) e Gemini (`gemini_auth_service.dart`); Claude só por chave de API (`lib/domain/models/llm_config.dart`).
- Planejamento: `PROJECT.md`, `ROADMAP.md`, `docs/DECISIONS.md`, `docs/questionario/`.

## O que NÃO foi verificado
- Build, `flutter analyze`, `flutter test` e execução no S25 Ultra: `NOT_RUN`.
- Se os logins OAuth ainda funcionam: `NOT_RUN`.

## Última atividade
- 2026-11-02: documento de visão lido, questionário de decisões concluído, roadmap F0–F8 criado.

## Próxima ação
- F0-01 → F0-02: configurar `upstream`, buildar `globalDev` e rodar no S25 Ultra. Ver `ROADMAP.md`.

## Bloqueios e aprovações humanas
- Nenhum. Commit/push de mudança de escopo exige aprovação do dono do repositório.

## Divergências entre roadmap e implementação
- Nenhuma.
