# F5-02 — Privacidade

**Data:** 2026-11-02. Revisão desta sessão, com o código aberto. Uma passagem sem histórico leu os mesmos arquivos e devolveu achados; esta nota incorpora os que eram fato. Essa passagem não é isolada. A F5-02 fica `IN_PROGRESS`.

## O que mudou neste turno

O sucesso do OAuth OpenAI deixou de escrever access token, refresh token e ID token no log. No sucesso ficam `Exchanging code for tokens...`, `Token exchange successful.` e `OpenAI auth tokens stored`. Nenhuma das três interpola o token. A falha dedicada registra só o status HTTP.

A falha da troca de código do Gemini montava a exceção com `tokenResponse.body`. O `catch` gravava essa exceção no log e a mostrava na tela. Agora a exceção e o log levam só o status HTTP. `jsonDecode(tokenResponse.body)` continua, porque é a leitura da resposta, não um log.

Guarda em `test/data/services/openai_auth_log_test.dart`. O teste recusa a interpolação `${tokenResponse.body}` nos dois serviços e ainda exige o `jsonDecode`.

## Achado aberto

Tokens e a configuração de modelo ficam em `SharedPreferences`, sem cofre do Android e sem `flutter_secure_storage` (o pacote não está no `pubspec.yaml`).

Chaves:

- `openai_access_token`, `openai_refresh_token`, `openai_account_id`, `openai_expires_at`
- `gemini_access_token`, `gemini_refresh_token`, `gemini_email`, `gemini_expires_at`
- `llm_client_configs` — o JSON de `LLMConfig` inclui `apiKey`

O ID token da OpenAI entra em `_saveTokens` e não é gravado nessas chaves. Access token e refresh token são gravados. Nada disso entra no git. Este turno não migra o armazenamento. Por isso "chaves e tokens protegidos" não está atendido.

## O que ficou de fora, de propósito

`lib/llm_client/gemini_oauth_project.dart` registra `response.body` quando `retrieveUserQuota`, `loadCodeAssist` ou `onboardUser` falham. O access token desse cliente vai no cabeçalho `Authorization`. `lib/data/services/model_list_service.dart` registra `endpoint` e `response.body` quando a lista de modelos não volta 200. No Gemini, a `apiKey` vai na query `key=` da URI pedida; a variável `endpoint` que entra no log não leva essa query. Nos outros tipos, a chave vai em `Authorization` ou `x-api-key`. Severidade baixa. Não foram alterados.

O `catch` dos dois logins ainda grava `OAuth error: $e` ou `Google OAuth error: $e`. Depois deste turno, a exceção da troca de código não inclui o corpo. Uma falha de `jsonDecode` ou de JWT pode ainda carregar um pedaço da resposta. Isso não foi reproduzido.

## Envio

`hasLLMConsent` / `saveLLMConsent` em `lib/utils/user_storage.dart` guardam `llm_data_sharing_consent` e `llm_consent_$providerType`. O uso encontrado na tela é a edição de modelo. A importação de transcrição passa pela tela que mostra o texto antes de gravar. A mensagem de chat sai pela ação de enviar do usuário. A trilha de cada chamada de modelo: `NOT_RUN`.
