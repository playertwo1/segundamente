# F0-06 — Atualizar o upstream

O upstream é `memex-lab/memex`, branch `main`. A `main` deste fork já foi publicada. A atualização entra por merge. Rebase da `main` reescreveria commits que já estão no GitHub.

## Procedimento

1. Árvore limpa. `analysis_options.yaml` e `android/gradle.properties` não entram no commit se o Flutter os tiver reescrito: `git checkout --` nesses dois arquivos.
2. `git fetch upstream --prune`
3. `git rev-list --left-right --count HEAD...upstream/main`
4. `git merge upstream/main`
5. Se houver conflito, parar. Não usar `-X ours` nem `-X theirs`. Preservar a identidade do fork nestes arquivos:
   - `android/app/build.gradle.kts` (`applicationId` e `appLabel`)
   - `android/app/src/**/res/xml/shortcuts.xml` (`targetPackage`)
   - `android/app/src/main/res/mipmap-anydpi-v26/launcher_icon.xml`
   - `android/app/src/main/res/drawable/ic_sm_launcher_foreground.xml`
   - `android/app/src/main/res/values/colors.xml`
   - as strings `welcomeToMemex` em `lib/l10n/`
   - `STATE.md`, `ROADMAP.md`, `PROJECT.md`, `docs/`
6. `flutter pub get --enforce-lockfile`. Se o lock do upstream mudou, revisar o diff antes de aceitar.
7. Rodar o teste mais próximo do que o upstream mexeu. Build `flutter build apk --debug --flavor globalDev` se o merge tocou `lib/` ou `android/`.
8. Commit do merge só com a aprovação do dono. Push também.

## Teste em 2026-11-02

```
git fetch upstream --prune
git rev-parse HEAD
22901fec66c3b414ec540caa04f6843b1fb79e99
git rev-parse upstream/main
6143923e7b2237520b7143f4e5aae88822788aa4
git rev-list --left-right --count HEAD...upstream/main
3	0
git merge upstream/main
Already up to date.
```

O fork está 3 commits à frente e 0 atrás. O merge não criou commit. A base do Memex continua `6143923`. Não havia atualização para integrar.
