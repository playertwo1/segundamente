# F5-02 — Privacidade

**Data:** 2026-11-02. Revisão desta sessão, com o código aberto. Uma passagem sem histórico leu os mesmos arquivos e devolveu achados; esta nota incorpora os que eram fato. Essa passagem não é isolada. A F5-02 fica `IN_PROGRESS` até a migração ser vista no S25.

## O que mudou neste turno

O sucesso do OAuth OpenAI deixou de escrever access token, refresh token e ID token no log. No sucesso ficam `Exchanging code for tokens...`, `Token exchange successful.` e `OpenAI auth tokens stored`. Nenhuma das três interpola o token. A falha dedicada registra só o status HTTP.

A falha da troca de código do Gemini montava a exceção com `tokenResponse.body`. O `catch` gravava essa exceção no log e a mostrava na tela. Agora a exceção e o log levam só o status HTTP. `jsonDecode(tokenResponse.body)` continua, porque é a leitura da resposta, não um log.

Guarda em `test/data/services/openai_auth_log_test.dart`. O teste recusa a interpolação `${tokenResponse.body}` nos dois serviços e ainda exige o `jsonDecode`.

## Cofre do sistema (2026-11-03)

Os segredos saíram do `SharedPreferences` e foram para o `flutter_secure_storage` (Android Keystore), por `lib/utils/secret_storage.dart`.

- `openai_*`, `gemini_*` e `claude_*` `_access_token` e `_refresh_token` ficam no cofre. E-mail, id da conta, validade e `gemini_project_id` continuam em `SharedPreferences`.
- `llm_client_configs` continua em `SharedPreferences`, mas com `apiKey`, `extra.accessKeyId` e `extra.secretAccessKey` vazios. Os valores ficam no cofre, na chave `llm_config_secrets`, por chave de configuração.
- Migração: na primeira leitura, um token ou uma `apiKey` em texto puro no `SharedPreferences` vai para o cofre e sai do XML. O mesmo vale para o que um backup antigo restaurar.
- Backup `.memex`: ele copia todas as chaves do `SharedPreferences`. Antes desta mudança, levava os tokens OAuth e as `apiKey`. Agora não leva mais. Restaurar num aparelho novo exige entrar de novo nas contas e redigitar as chaves.
- `clearAllData` (exclusão de conta) apaga também o cofre. `resetLLMConfigs` apaga `llm_config_secrets`.
- Testes: `test/utils/secret_storage_test.dart` (migração dos tokens, chaves fora do XML, `apiKey` antiga migrada). Mock global do cofre em `test/flutter_test_config.dart`.
- No aparelho: `NOT_RUN`. Falta abrir no S25 um app que já tinha login e confirmar que a sessão continua, sem pedir login de novo.

## Logs

`gemini_oauth_project.dart` e `model_list_service.dart` registram só o status HTTP, sem `response.body`. A guarda em `openai_auth_log_test.dart` cobre esses dois arquivos e o `claude_auth_service.dart`.

O `catch` dos logins ainda grava `OAuth error: $e`, `Google OAuth error: $e` e `Claude OAuth error: $e`. Uma falha de `jsonDecode` ou de JWT pode carregar um pedaço da resposta. Isso não foi reproduzido nem alterado.

## Envio

`hasLLMConsent` / `saveLLMConsent` em `lib/utils/user_storage.dart` guardam `llm_data_sharing_consent` e `llm_consent_$providerType`. O uso encontrado na tela é a edição de modelo. A importação de transcrição passa pela tela que mostra o texto antes de gravar. A mensagem de chat sai pela ação de enviar do usuário. A trilha de cada chamada de modelo: `NOT_RUN`.

## Inventário de destinos de rede (2026-11-05)

Revisão por busca no código (`lib/`). Só leitura; nada foi alterado. A coluna "Quem aciona" separa o que o usuário inicia do que o app faz sozinho.

| Destino | O que sai | Quem aciona | Observação |
|---|---|---|---|
| `api.openai.com`, `chatgpt.com`, `auth.openai.com` | texto, anexos escolhidos, áudio (só para `backend-api/transcribe`), tokens OAuth | usuário (enviar, anexar, gravar) | D-011. Consentimento por provedor em `model_config_edit_page`. |
| `generativelanguage.googleapis.com`, `daily-cloudcode-pa.googleapis.com`, `oauth2.googleapis.com`, `accounts.google.com`, `www.googleapis.com` | texto e anexos escolhidos; tokens | usuário | Igual ao acima. |
| `api.anthropic.com`, `platform.claude.com`, `claude.com` | texto e anexos escolhidos; tokens | usuário | Claude por chave de API ou OAuth permitido (D-015/D-020). |
| `openrouter.ai`, base URL personalizada | texto e anexos escolhidos | usuário | Endereço digitado pelo dono. |
| `models.dev` | nada do usuário (lista pública de modelos) | app, ao listar modelos OpenAI | Sem dado pessoal. |
| `tile.openstreetmap.org` | tela e zoom do mapa (revela a região vista) | app, ao abrir mapa ou cartão de lugar | Terceiro vê IP e região. |
| `nominatim.openstreetmap.org` | **latitude e longitude** | ver achado 2 | Terceiro recebe coordenadas exatas. |
| `api.dicebear.com` | semente do avatar | app, só quando o avatar não é uma imagem local | Avatares padrão agora são locais; resta a alternativa em erro e avatares antigos. |
| `api.github.com/repos/memex-lab/memex` | nada do usuário | app, só no canal `early` | Os sabores `globalDev` e `app.segundamente` (estável) não usam: `isSupported` exige canal early. |
| `www.memexlab.ai` | nome de usuário e senha, idioma | ver achado 1 | Servidor do projeto original. |
| `picsum.photos` | nada do usuário | só aparece em exemplos dentro de prompts de habilidade | Se o modelo copiar a URL, o cartão busca uma foto aleatória. |
| Prévia de link (F6-07) | endereço do link | usuário, interruptor desligado por padrão | Proteções em `url_guard` (sem rede privada, sem cookies). |

## Achados abertos (dependem de decisão do dono)

1. **MÉDIO — conta do Memex original dentro do app.** A tela de configuração de IA oferece "Ativar serviço de IA", que abre cadastro e login no servidor `www.memexlab.ai` (usuário, senha, recarga) e devolve chave e modelos desse serviço. É um serviço de terceiro, fora do plano da Segunda Mente, e o código ainda traz o comentário "TODO: trocar pelo domínio real". Opções: (a) esconder a seção; (b) manter e documentar como serviço do projeto original; (c) trocar pelo servidor próprio, se houver. Recomendo (a) até haver decisão.
2. **MÉDIO — foto com GPS envia coordenadas a dois terceiros sem opção.** `buildImageExifInfo` lê o GPS da foto, chama `GeocodingService.reverseGeocode` (Nominatim, coordenadas exatas) e coloca as coordenadas com 6 casas e o endereço no texto enviado ao modelo. A chave `LocationContextConfig.enabled` (desligada por padrão) só controla a "localização atual", não este caminho. Opções: (a) só geocodificar e incluir coordenadas se o interruptor estiver ligado; (b) incluir só a cidade; (c) manter e avisar no envio. Recomendo (a), com aviso na prévia de envio quando a foto tem GPS.
3. **BAIXO — mapas e avatar alternativo.** Os ladrilhos do OpenStreetMap e o DiceBear expõem IP e região ou semente a terceiros. Aceitável se documentado; avatar alternativo pode ser trocado por iniciais locais.
4. **BAIXO — exceções de login no log.** Continua o `OAuth error: $e` descrito acima (não reproduzido).

Nada disso foi corrigido: os achados 1 e 2 mudam o produto e esperam a decisão. A trilha de cada chamada de modelo e a migração do cofre no S25 seguem `NOT_RUN`.
