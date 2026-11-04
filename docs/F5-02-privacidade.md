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
