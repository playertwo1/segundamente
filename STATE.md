# STATE — ponto de retomada

**Atualizado:** 2026-11-02 · **Fase ativa:** F0 — Fundação · **Estado:** IN_PROGRESS

## O que existe hoje (confirmado)
- Fork público `playertwo1/segundamente` de `memex-lab/memex` (Flutter, GPL-3.0), `main` ainda com o código do Memex (só docs foram adicionados).
- No código: login OAuth de OpenAI (`lib/data/services/openai_auth_service.dart`) e Gemini (`gemini_auth_service.dart`); Claude só por chave de API (`lib/domain/models/llm_config.dart`).
- Planejamento: `PROJECT.md`, `ROADMAP.md`, `docs/DECISIONS.md`, `docs/questionario/`.

## Evidência da F0 (2026-11-02; Windows 11, Flutter 3.47.9 stable, Dart 3.13.7, JDK 17)
- F0-01 `DONE`: `git remote -v` mostra `upstream=memex-lab/memex`; commit base do Memex = `6143923e7b2237520b7143f4e5aae88822788aa4`.
- F0-02 parcial: `flutter build apk --debug --flavor globalDev` → `PASS` (`app-globaldev-debug.apk`, 355 MB, ~15 min no 1º build). Instalado no **emulador** (`emulator-5554`, pacote `com.memexlab.memex.dev`); abre na tela "Welcome to Memex". Na 1ª abertura, com `flutter test` rodando em paralelo, apareceu "Memex Dev isn't responding" (ANR); numa segunda abertura, sem carga, o app subiu normalmente.
- `flutter analyze`: 161 issues, 0 error, 0 warning (só `info` de estilo). O Flutter devolve exit code 1 por causa dos infos.
- `flutter test`: 1011 passaram, 7 ignorados, **30 falharam** (13 em `backup_service_test`, 4 em `file_operation_service_grep_test`, 3 em `share_intent_handler_test`, o resto isolado). Causas vistas: `PathAccessException` errno 32 (arquivo em uso no Windows) em 10 casos, `UNIQUE constraint failed` em 2, `MissingPluginException(path_provider)` em 1; o restante não foi investigado. O código é idêntico ao upstream (só docs adicionados), então são falhas da linha de base neste ambiente.
- **Ainda `NOT_RUN`:** execução no **S25 Ultra** (só havia emulador); F0-03 a F0-06; logins OAuth.

## Toolchain (ambiente local, fora do repo)
- Flutter em `C:\Users\notefael\tools\flutter`, fora do PATH: usar `C:\Users\notefael\tools\flutter\bin\flutter`. `flutter config --jdk-dir` aponta para `C:\Users\notefael\AppData\Local\Programs\jdk-17` (o Java 25 padrão quebra o Gradle 8.14).
- O Flutter 3.47 reescreve `analysis_options.yaml` e `android/gradle.properties` ao rodar `pub get`/build; reverter com `git checkout` antes de commitar. Usar `flutter pub get --enforce-lockfile`.
- O Gradle instalou sozinho o Android SDK Platform 34. As demais licenças do SDK seguem não aceitas.

## Última atividade
- 2026-11-02: documento de visão lido, questionário concluído, roadmap F0–F8 criado, upstream configurado, build debug `globalDev` gerado e testado no emulador.

## Próxima ação
- Conectar o S25 Ultra por USB (depuração ligada), instalar o APK e fechar F0-02. Depois F0-03 (identidade própria), F0-04 (licenças) e F0-05 (auditoria de módulos, incluindo voz). Investigar os 30 testes falhos só se atrapalharem; até lá, tratar como baseline.

## Bloqueios e aprovações humanas
- F0-02 precisa do S25 Ultra conectado (ação do dono). Commit/push de mudança de escopo exige aprovação do dono do repositório.

## Divergências entre roadmap e implementação
- Nenhuma.
