# F0-05 — Módulos reutilizáveis

**Data:** 2026-11-02. Leitura do código em `main`. Nada disso foi executado com uma conta real. OAuth continua `NOT_RUN`.

## Provedores

A lista do flavor global está em `lib/config/app_config.dart`. Os tipos estão em `lib/domain/models/llm_config.dart`.

Para o MVP entram OpenAI (chave, Responses e OAuth), Gemini (chave e OAuth) e Claude só por chave. O mesmo arquivo também traz Bedrock, Kimi, Qwen, Seed, Zhipu, DeepSeek, MiniMax, MIMO, OpenRouter, Ollama e Memex AI. Vários deles só trocam a base URL e usam o cliente de chat completions, Responses ou Claude (`LLMConfig.underlyingClientType`).

Onde mexer na F1: `app_config.dart` para o que aparece no flavor, `llm_config.dart` para o tipo, e os clientes em `lib/llm_client/` (`codex_responses_client.dart`, `gemini_oauth_client.dart`). Modelo por ID e teste de capacidade ainda não são uma tela própria; o ponto de partida é `lib/data/services/model_list_service.dart` e `model_test_service.dart`.

## OAuth

- OpenAI: `lib/data/services/openai_auth_service.dart`. Fluxo PKCE. O callback é `http://localhost:1455/auth/callback`. O `client_id` é o do CLI Codex, cliente público.
- Gemini: `lib/data/services/gemini_auth_service.dart`. Fluxo PKCE com callback em `http://localhost:8085/oauth2callback` e o `client_id` do Gemini CLI. O arquivo também traz um client secret no fonte. O valor não é repetido aqui. Risco: o segredo está no repositório público do upstream, pode ser revogado, e o uso num app de terceiro pode ferir os termos. O teste real fica na F1-04. Não copiar o segredo para documento, log ou commit novo.

Os dois gravam o resultado via `UserStorage`. Nenhum dos dois foi aberto no emulador nesta fase.

## Voz

Decisão em D-007.

O que existe:

- Microfone: pacote `record`.
- STT local: `WhisperService` (`lib/data/services/whisper_service.dart`) com sherpa-onnx. O modelo fixo é `sherpa-onnx-sense-voice-zh-en-ja-ko-yue-int8-2024-07-17`. Os idiomas do nome são chinês, inglês, japonês, coreano e cantonês. Português não entra.
- STT na nuvem: `SpeechTranscriptionService._transcribeAudioBytesWithCloud` manda o áudio ao modelo já configurado (`AudioPart`) e pede só o transcript, no idioma falado. O interruptor é `UserStorage.getUseLocalSpeechToText`.
- TTS: não há pacote nem serviço de síntese. `audioplayers` só toca arquivo pronto.

O que falta para o MVP: transcrição pt-BR em turnos e áudio opcional da resposta. Full duplex continua na F7.

Onde mexer na F2-02: a preferência local/nuvem em `speech_transcription_service.dart`; um serviço novo de TTS do Android, ao lado de `lib/data/services/`, chamado pelo turno de chat. Não trocar o modelo SenseVoice na F2: ele não fala português.

## Anexos e importação

- Compartilhar do sistema: `share_handler`, tratado em `lib/ui/main_screen/widgets/share_intent_handler.dart`. `ACTION_SEND` passa por esse plugin.
- Abrir arquivo pelo gerenciador: `external_file_import_intent_service.dart` e `backup_import_intent_service.dart`. O comentário desses arquivos diz que o `share_handler` não entrega `ACTION_VIEW`.
- Cópia para o workspace: `file_import_service.dart`.
- Texto de documento: `document_text_extraction_service.dart` lê DOCX e XLSX. PDF devolve mensagem de não suportado. DOC/XLS antigos também.
- Foto: `image_picker`, `camera`, `photo_manager`, `wechat_assets_picker`, `photo_attachment_service.dart`, `card_attachment_service.dart`.

Onde mexer na F2: o handler de share e o `FileImportService` para o TXT do Samsung; a extração se o TXT precisar de pré-visualização. PDF de entrada continua opcional (F2-06).

## Banco

Drift em `lib/db/app_database.dart`, schema 19. Tabelas: `Tasks`, `KvStore`, `AgentActivityMessages`, `CardCache`, `SystemActions`, `ClarificationRequests`, `PersonaChatMessages`, `PersonaChatReplyCursors`, `UserNotifications`. Busca FTS em `lib/db/daos/search_dao.dart`.

O texto do diário, os cards e a PKM continuam no filesystem, via `FileSystemService`. O SQLite é índice, fila e cache. A F3 não deve guardar o relatório só no SQLite se o original precisa sobreviver fora do banco. O original segue arquivo; o derivado pode indexar.

## Exportação

Não há gerador de relatório em PDF, DOCX ou Markdown. `share_plus` (`lib/utils/share_service.dart`) compartilha o que já existe. `backup_service.dart` empacota o workspace; a lista de extensões inclui `.pdf` como arquivo de entrada do backup, não como relatório gerado.

Onde mexer na F4: um serviço novo em `lib/data/services/`, chamado pela tela do relatório, escrevendo os três formatos a partir do mesmo objeto. Não passar por `MemexRouter` com a lógica de layout dentro do router.
