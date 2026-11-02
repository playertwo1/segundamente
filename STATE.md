# STATE — ponto de retomada

**Atualizado:** 2026-11-02 · **Fase ativa:** F0 — Fundação · **Estado:** IN_PROGRESS

O dono pediu para usar só o emulador por enquanto (D-009). O Galaxy S25 Ultra segue `NOT_RUN`.

## O que existe hoje (confirmado)
- Fork público `playertwo1/segundamente` de `memex-lab/memex` (Flutter, GPL-3.0), `main` ainda com o código do Memex (só docs foram adicionados).
- No código: login OAuth de OpenAI (`lib/data/services/openai_auth_service.dart`) e Gemini (`gemini_auth_service.dart`); Claude só por chave de API (`lib/domain/models/llm_config.dart`).
- Planejamento: `PROJECT.md`, `ROADMAP.md`, `docs/DECISIONS.md`, `docs/questionario/`.

## Evidência da F0 (2026-11-02; Windows 11, Flutter 3.47.9 stable, Dart 3.13.7, JDK 17)
- F0-01 `DONE`: `git remote -v` mostra `upstream=memex-lab/memex`; commit base do Memex = `6143923e7b2237520b7143f4e5aae88822788aa4`.
- F0-02 `DONE` no emulador, S25 `NOT_RUN` (D-009). `flutter build apk --debug --flavor globalDev` → `PASS` (`app-globaldev-debug.apk`, 355 MB, ~15 min no 1º build). Reaberto neste turno em `emulator-5554`, pacote `com.memexlab.memex.dev`, tela "Welcome to Memex". Na 1ª abertura do dia, com `flutter test` em paralelo, apareceu "Memex Dev isn't responding" (ANR); numa segunda abertura, sem carga, o app subiu normalmente.
- `flutter analyze`: 161 issues, 0 error, 0 warning (só `info` de estilo). O Flutter devolve exit code 1 por causa dos infos.
- `flutter test`: 1011 passaram, 7 ignorados, **30 falharam** (13 em `backup_service_test`, 4 em `file_operation_service_grep_test`, 3 em `share_intent_handler_test`, o resto isolado). Causas vistas: `PathAccessException` errno 32 (arquivo em uso no Windows) em 10 casos, `UNIQUE constraint failed` em 2, `MissingPluginException(path_provider)` em 1; o restante não foi investigado. O código era idêntico ao upstream quando esses testes rodaram, então são falhas da linha de base neste ambiente. Neste turno só rodei `flutter test test/l10n/welcome_name_test.dart`: 1 passou.
- F0-03 `DONE` no emulador. `aapt dump badging` do APK novo: `package: name='app.segundamente.dev'` e `application-label:'Segunda Mente Dev'`. `adb install` → `Success`. `pm path` mostrou os dois pacotes ao mesmo tempo: `com.memexlab.memex.dev` e `app.segundamente.dev`. O app novo abriu em "Welcome to Segunda Mente" (Maestro, `emulator-5554`). Assinatura: certificado de debug `CN=Android Debug`; nenhum `.jks`, `.keystore` ou `key-*.properties` versionado. Ícone provisório: adaptive icon em `mipmap-anydpi-v26/launcher_icon.xml`.
- **Ainda `NOT_RUN`:** execução no **S25 Ultra**; F0-04 a F0-06; logins OAuth.

## Toolchain (ambiente local, fora do repo)
- Flutter em `C:\Users\notefael\tools\flutter`, fora do PATH: usar `C:\Users\notefael\tools\flutter\bin\flutter`. `flutter config --jdk-dir` aponta para `C:\Users\notefael\AppData\Local\Programs\jdk-17` (o Java 25 padrão quebra o Gradle 8.14).
- O Flutter 3.47 reescreve `analysis_options.yaml` e `android/gradle.properties` ao rodar `pub get`/build; reverter com `git checkout` antes de commitar. Usar `flutter pub get --enforce-lockfile`.
- O Gradle instalou sozinho o Android SDK Platform 34. As demais licenças do SDK seguem não aceitas.

## Última atividade
- 2026-11-02: o dono mandou seguir só no emulador. F0-02 reconfirmada nele. F0-03 aplicada: nome "Segunda Mente", `applicationId` `app.segundamente*`, ícone provisório, APK debug instalado ao lado do pacote antigo.

## Próxima ação
- F0-04: auditoria de licenças GPL-3.0 das dependências, em `docs/`. Depois F0-05 (módulos, incluindo a decisão de voz) e F0-06 (rotina de upstream). O S25 Ultra entra quando o dono conectar o aparelho. Os 30 testes falhos da linha de base continuam baseline, salvo se atrapalharem.

## Bloqueios e aprovações humanas
- S25 Ultra adiado pelo dono (D-009). Commit e push desta identidade esperam aprovação do dono.

## Divergências entre roadmap e implementação
- Nenhuma.
