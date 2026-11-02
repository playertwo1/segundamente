# F0-04 — Licenças

**Data:** 2026-11-02. **Fonte:** `pubspec.lock` (288 pacotes) e o arquivo `LICENSE` de cada um no pub-cache. O app é GPL-3.0 (`LICENSE` na raiz). Uso pessoal; a GPL passa a obrigar entrega de fonte e avisos se um APK for distribuído.

## Como a tabela foi feita

Um script local leu o `pubspec.lock`, abriu o `LICENSE` no pub-cache e classificou o cabeçalho. Pacotes `source: sdk` (`flutter`, `flutter_localizations`, `flutter_test`) usam a licença BSD-3-Clause do Dart/Flutter, lida em `flutter/bin/cache/dart-sdk/LICENSE`.

Sete versões do lock não estavam na pasta esperada do cache. O `.dart_tool/package_config.json` aponta para uma versão um pouco mais nova, resolvida pelo Flutter. O `LICENSE` dessas cópias foi lido e é BSD-3-Clause:

| Lock | Cópia lida |
|---|---|
| intl 0.20.2 | intl 0.20.3 |
| meta 1.17.0 | meta 1.19.0 |
| matcher 0.12.19 | matcher 0.12.20 |
| vector_math 2.2.0 | vector_math 2.4.4 |
| test 1.30.0 | test 1.31.1 |
| test_api 0.7.10 | test_api 0.7.12 |
| test_core 0.6.16 | test_core 0.6.18 |

`dbus`, `geoclue` e `gsettings` pareciam AGPL numa leitura automática, porque o texto da MPL-2.0 cita a GNU Affero GPL. O começo do arquivo é Mozilla Public License 2.0. Os fontes em `lib/` não trazem o aviso "Incompatible With Secondary Licenses". MPL-2.0, nesse caso, combina com GPL-3.0.

## Resultado

| Licença | Pacotes |
|---|---|
| BSD-3-Clause | 174 (167 pelo arquivo da versão do lock + 7 pela cópia do SDK acima) |
| MIT | 83 |
| Apache-2.0 | 27 |
| MPL-2.0 | 3 (`dbus`, `geoclue`, `gsettings`, todos transitivos e de desktop) |
| GPL-3.0 do próprio app | 1 (`agent_background_android`, plugin em `plugins/`, sem `LICENSE` próprio) |

Não apareceu GPL-2.0-only, AGPL aplicada ao código, licença não comercial nem pacote sem licença entre as dependências diretas. Nenhuma dependência direta impede o fork GPL-3.0.

`geoclue` e `gsettings` declaram `platforms: linux`. `dbus` declara linux e windows e é dependência desses dois. O `lib/` do app não importa nenhum deles. Eles não entram no APK Android.

## Dependências diretas

| Pacote | Versão no lock | Licença |
|---|---|---|
| flutter, flutter_localizations, flutter_test | SDK | BSD-3-Clause |
| agent_background_android | 0.0.1 (path) | GPL-3.0 do app |
| archive | 4.0.7 | MIT |
| audioplayers | 6.5.1 | MIT |
| build_runner | 2.10.4 | BSD-3-Clause |
| camera | 0.11.3+1 | BSD-3-Clause |
| chewie | 1.13.0 | MIT |
| collection | 1.19.1 | BSD-3-Clause |
| crypto | 3.0.7 | BSD-3-Clause |
| cupertino_icons | 1.0.8 | MIT |
| dart_agent_core | 2.1.8 | MIT |
| dart_jsonwebtoken | 2.17.0 | MIT |
| dio | 5.9.0 | MIT |
| drift, drift_dev | 2.30.0 | MIT |
| drift_flutter | 0.2.8 | MIT |
| exif | 3.3.0 | MIT |
| file_picker | 8.3.7 | MIT |
| fl_chart | 0.66.2 | MIT |
| flutter_image_compress | 2.4.0 | MIT |
| flutter_js | 0.8.7 | MIT |
| flutter_launcher_icons | 0.14.4 | MIT |
| flutter_lints | 3.0.2 | BSD-3-Clause |
| flutter_map | 6.2.1 | BSD-3-Clause |
| flutter_markdown | 0.7.7+1 | BSD-3-Clause |
| flutter_native_splash | 2.4.7 | MIT |
| flutter_svg | 2.2.4 | MIT |
| geolocator | 14.0.2 | MIT |
| go_router | 14.8.1 | BSD-3-Clause |
| google_fonts | 6.3.3 | BSD-3-Clause |
| google_generative_ai | 0.4.7 | Apache-2.0 |
| google_mlkit_image_labeling | 0.14.2 | MIT |
| google_mlkit_text_recognition | 0.15.1 | MIT |
| health | 13.2.1 | MIT |
| http | 1.6.0 | BSD-3-Clause |
| image | 4.7.2 | MIT |
| image_picker | 1.2.1 | Apache-2.0 |
| intl | 0.20.2 | BSD-3-Clause |
| latlong2 | 0.9.1 | Apache-2.0 |
| local_auth | 2.3.0 | BSD-3-Clause |
| logging | 1.3.0 | BSD-3-Clause |
| package_info_plus | 9.0.0 | BSD-3-Clause |
| path | 1.9.1 | BSD-3-Clause |
| path_provider | 2.1.5 | BSD-3-Clause |
| pedometer | 4.1.1 | MIT |
| permission_handler | 11.4.0 | MIT |
| photo_manager | 3.8.3 | Apache-2.0 |
| photo_view | 0.15.0 | MIT |
| provider | 6.1.5+1 | MIT |
| quick_actions | 1.1.0 | BSD-3-Clause |
| record | 6.1.2 | BSD-3-Clause |
| screenshot | 3.0.0 | MIT |
| share_handler | 0.0.25 | MIT |
| share_plus | 10.1.4 | BSD-3-Clause |
| shared_preferences | 2.5.4 | BSD-3-Clause |
| sherpa_onnx | 1.13.2 | Apache-2.0 |
| shimmer | 3.0.0 | BSD-3-Clause |
| sqlite3 | 2.9.4 | MIT |
| sqlite3_flutter_libs | 0.5.41 | MIT |
| synchronized | 3.4.0 | MIT |
| test | 1.30.0 | BSD-3-Clause |
| url_launcher | 6.3.2 | BSD-3-Clause |
| uuid | 4.5.2 | MIT |
| video_player | 2.10.1 | BSD-3-Clause |
| wakelock_plus | 1.4.0 | BSD-3-Clause |
| web_socket_channel | 3.0.3 | BSD-3-Clause |
| webview_flutter | 4.13.0 | BSD-3-Clause |
| wechat_assets_picker | 10.1.0 | Apache-2.0 |
| workmanager | 0.9.0+3 | MIT |
| xml | 6.6.1 | MIT |
| yaml | 3.1.3 | MIT |

## Fora do pub

- Fontes em `google_fonts/`: SIL OFL. Os textos estão em `OFL-Inter.txt`, `OFL-Imbue.txt` e `OFL-BricolageGrotesque.txt`. A OFL permite embutir a fonte. Os arquivos de licença ficam no repositório.
- `com.google.mlkit:text-recognition-chinese:16.0.1` está no Gradle (`android/app/build.gradle.kts`). O pacote Dart do ML Kit é MIT; o binário segue os termos da Google. Uso pessoal no aparelho. Se o APK for distribuído, esses termos precisam ser relidos.
- AndroidX e o SDK Android não são dependências pub. As licenças do SDK, fora a plataforma 34, continuam não aceitas nesta máquina.

## Atribuição

Enquanto o APK não for distribuído, o que já está no repositório basta: `LICENSE` GPL-3.0, cabeçalhos de copyright do Memex e os `OFL-*.txt`. Na primeira distribuição, publicar também um aviso das dependências BSD, MIT, Apache-2.0 e MPL-2.0. Não apagar esses avisos ao atualizar o upstream.
