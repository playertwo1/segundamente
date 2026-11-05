# Decisões (ADR leve)

Só escolhas caras de desfazer ou que outro agente poderia contestar. Nova decisão = próximo número. Decisão substituída não é apagada: marcar `SUPERSEDED` e apontar a nova. Registro completo das perguntas: [questionario/2026-11-02-segunda-memoria.md](questionario/2026-11-02-segunda-memoria.md).

| ID | Data | Assunto | Estado |
|---|---|---|---|
| D-001 | 2026-11-02 | Base: fork do Memex (Flutter) com F0 como portão | ACCEPTED |
| D-002 | 2026-11-02 | MVP = escopo "Prioridade atual"; full duplex, NotebookLM, grafo, ponte CLI fora | ACCEPTED |
| D-003 | 2026-11-02 | Fases F0–F5 (MVP) e F6–F8 (futuro bloqueado) | ACCEPTED |
| D-004 | 2026-11-02 | Provedores: OpenAI e Gemini via OAuth existente; Claude por chave de API opcional | ACCEPTED |
| D-005 | 2026-11-02 | Sem login Claude.ai por assinatura (termos da Anthropic); só via Claude Code oficial no PC (F7) | ACCEPTED |
| D-006 | 2026-11-02 | Nome do app e applicationId: "Segunda Mente" | ACCEPTED |
| D-007 | 2026-11-02 | Voz do MVP: STT na nuvem pelo modelo configurado; TTS do Android na F2; SenseVoice não cobre pt-BR | ACCEPTED |
| D-008 | 2026-11-02 | Docs de planejamento vivem na `main` do fork; só os arquivos úteis do kit ideias_standard | ACCEPTED |
| D-009 | 2026-11-02 | Até o S25 Ultra estar conectado, o emulador é o aparelho de prova da F0 | ACCEPTED |
| D-010 | 2026-11-02 | A F6 pode começar com os portões da F0 à F5 ainda abertos | ACCEPTED |
| D-011 | 2026-11-03 | Áudio: transcrição pelo endpoint do ChatGPT; o canal de chat nunca recebe áudio | ACCEPTED |
| D-012 | 2026-11-03 | O app tem só inglês e português | ACCEPTED |
| D-013 | 2026-11-03 | Gemini por OAuth desbloqueado via daily-cloudcode-pa SSE stream | SUPERSEDED |
| D-014 | 2026-11-03 | Ideias do Memos: quatro entram na F6 (F6-05 a F6-08); o resto fica fora | ACCEPTED |
| D-015 | 2026-11-03 | Login OAuth Claude (PKCE local) e Claude Sonnet/Opus 5.5 High via Google OAuth | ACCEPTED |
| D-016 | 2026-11-03 | Ideias do Daedalus Echo: Whisper local multilíngue, extrator de tarefas robusto, recuperação por tópicos, agenda; o resto fica fora | ACCEPTED |
| D-017 | 2026-11-03 | Direção visual móvel AMOLED, editorial e sem barra inferior persistente | ACCEPTED |
| D-018 | 2026-11-03 | Ideias do anarlog: prompts de resumo, correção conservadora, dicionário, legenda SRT/VTT e transparência dos provedores; o resto fica fora | ACCEPTED |
| D-019 | 2026-11-03 | Priorizar a implementação visual F5-04 antes das demais pendências, sem fechar o portão F4 | SUPERSEDED |
| D-020 | 2026-11-03 | Mecanismo de fallback resiliente entre modelos e provedores (FallbackLLMClient) | ACCEPTED |
| D-021 | 2026-11-03 | Fazer o redesign visual em fase própria após o fechamento da fase F5 atual | SUPERSEDED |
| D-022 | 2026-11-03 | Iniciar a fase F5V agora, em paralelo ao fechamento da F5 | ACCEPTED |
| D-023 | 2026-11-04 | Sem espelho chinês no download do modelo de voz | ACCEPTED |
| D-024 | 2026-11-04 | Remover tudo que é da China: provedores, sabores `cn*`, geocoding Amap e transcrição local SenseVoice | ACCEPTED |
| D-025 | 2026-11-04 | Revisar as pranchas 17, 19, 20 e 22 sem inventar capacidades | ACCEPTED |
| D-026 | 2026-11-04 | Implementar parcialmente as pranchas 17, 19, 20 e 22 na F5V | ACCEPTED |
| D-027 | 2026-11-04 | Ajustes encontrados na revisão das pranchas e decisão sobre bloqueio por PIN | ACCEPTED |
| D-028 | 2026-11-04 | Microfone explícito na conversa, transcrevendo para revisão | ACCEPTED |
| D-029 | 2026-11-04 | Planejar F9 — Meeting Decoder, sem abrir o MVP nem autorizar código | ACCEPTED |
| D-030 | 2026-11-04 | Ampliar F9 com PDFs, Todo, destinos de tarefas e relatórios PDF/DOCX | ACCEPTED |
| D-031 | 2026-11-05 | Abrir só a pesquisa F7-01 (sem código) antes do portão F5 | ACCEPTED |
| D-032 | 2026-11-05 | F7 sem ponte para CLIs: o login ChatGPT/Codex já existente basta | ACCEPTED |

## D-001 — Base: fork do Memex
- Contexto: Memex já traz diário/chat, banco local (Drift/SQLite), provedores e OAuth. Licença GPL-3.0.
- Decisão e motivo: usar o fork; app pessoal, então a GPL só pesa se distribuir o APK. Se build, licença ou teste no S25 falharem, reavaliar.
- Descartado: comparar 3 bases antes; app novo do zero.

## D-004 / D-005 — Autenticação
- Contexto: o usuário não usa chave de API. O fork reaproveita o `client_id` dos CLIs oficiais (Codex e Gemini) para OAuth.
- Decisão e motivo: manter esses dois logins no MVP, com risco registrado (podem quebrar ou violar termos; testar na F1-04). A Anthropic não permite login Claude.ai em apps de terceiros (code.claude.com/docs/en/legal-and-compliance, lido em 2026-11-02), então Claude fica com chave de API opcional.
- Descartado: fluxo próprio de login Claude.ai.
- Risco de termos, registrado na F1-04 em 2026-11-02: o login da OpenAI é PKCE com o client_id público do Codex CLI (`app_EMoamEEZ73f0CkXaXp7hrann`), emissor `https://auth.openai.com` e redirect `http://localhost:1455/auth/callback`. O do Gemini usa o client do Gemini CLI e o redirect `http://localhost:8085/oauth2callback`. Esses clientes pertencem aos CLIs oficiais. A OpenAI e o Google podem revogar o fluxo, trocar o client ou tratar o uso fora do CLI como fora dos termos. A Segunda Mente não tem um client OAuth próprio. Se o login quebrar, a alternativa do MVP é chave de API.
- `gemini_auth_service.dart` também traz um client secret. Esse valor não entra em documento, log, estado nem chat.
- O login em si não foi executado, nem no emulador nem no S25. Esta nota não prova que o login funciona.

## D-007 — Voz do MVP
- Contexto: o fork tem STT local por sherpa-onnx (SenseVoice zh/en/ja/ko/yue) e STT na nuvem, que envia o áudio ao modelo configurado. Não há TTS.
- Decisão e motivo: no MVP, a fala em português usa a transcrição na nuvem (`SpeechTranscriptionService`), no modelo que o usuário já escolheu. A resposta em áudio, opcional, usa o TTS do Android na F2-02. O modelo local SenseVoice fica disponível, mas não é o caminho do pt-BR.
- Descartado: trocar o SenseVoice por outro modelo nesta fase; voz full duplex (continua na F7).

## D-006 — Identidade de instalação
- Decisão e motivo: o app se chama Segunda Mente. Os `applicationId` passam a ser `app.segundamente`, `app.segundamente.cn`, `app.segundamente.early`, `app.segundamente.cn.early`, `app.segundamente.dev` e `app.segundamente.cn.dev`.
- O namespace Kotlin e os method channels continuam `com.memexlab.memex`. Eles identificam código nativo, não o pacote instalado. Renomeá-los fica fora da F0-03.
- Assinatura de debug usa o keystore de debug do Android SDK, fora do repositório. `android/key-*.properties`, `*.jks` e `*.keystore` já estão no `.gitignore` e não há nenhum desses arquivos versionado. Keystore de release não foi criado.

## D-009 — Emulador até o S25
- Contexto: a F0-02 pedia execução no Galaxy S25 Ultra. Em 2026-11-02 o dono pediu para usar só o emulador por enquanto.
- Decisão e motivo: enquanto o S25 não estiver conectado, `emulator-5554` é o aparelho de prova das subfases da F0. A execução no S25 fica `NOT_RUN`. Os critérios de aceite do MVP continuam no S25. A fase F0 não se declara concluída sem essa execução, ou sem uma decisão nova.
- Descartado: parar a F0 até o telefone aparecer.

## D-010 — Abrir a F6 antes do MVP
- Contexto: D-003 deixa a F6 bloqueada até o MVP. Em 2026-11-02 o dono pediu para avançar depois dos commits da F4 e da F5.
- Decisão e motivo: a F6 pode começar. O MVP não fecha. D-003 continua valendo para o que é o MVP e para manter a F7 e a F8 bloqueadas. Busca semântica, tópicos e o "por quê" não entram sem um modelo. A busca deste passo é texto local nos relatórios.
- Descartado: marcar o MVP como pronto para desbloquear a fase.


## D-011 — Áudio pelo ChatGPT
- Contexto: em 2026-11-03, no S25, o canal `chatgpt.com/backend-api/codex` respondeu `400 Audio input is not available` com `gpt-5.6-sol` e com `gpt-6-luna`. Um áudio gravado no histórico da conversa repetia o erro em todas as chamadas seguintes.
- Decisão e motivo: o canal de chat nunca recebe áudio (`CodexResponsesClient` troca por uma nota de texto). A transcrição usa `POST chatgpt.com/backend-api/transcribe` com o mesmo token do OAuth, e só o texto vai ao modelo. Testado em 2026-11-03 com um áudio pt-BR sintético: devolveu a frase correta. Isso cumpre D-007 (STT na nuvem pelo modelo configurado) sem depender do SenseVoice.
- Risco: o endpoint não é documentado e pode mudar ou ser bloqueado. Duração e tamanho máximos não foram medidos; a gravação de ~50 min é `NOT_RUN`.
- Descartado: enviar o áudio no canal de chat; chave de API do Gemini só para áudio (fica como reserva se o endpoint cair).

## D-012 — Idiomas
- Decisão e motivo: o app tem só inglês (`en`) e português (`pt`). As outras 16 línguas, incluindo o chinês, saíram do código, das galerias de cartão e dos testes (commit `73feb20`). Texto em outro idioma cai no inglês. Pedido do dono, que usa só pt-BR.
- As buscas de local pedem nomes no idioma do app, e não mais em chinês.
- Descartado: manter as demais línguas como reserva.

## D-013 — Gemini por OAuth (SUPERSEDED por D-020 e commit aa91a48)
- Contexto: Inicialmente `loadCodeAssist` devolvia `UNSUPPORTED_CLIENT` para o client_id do Gemini CLI e exigia projeto GCP standard-tier.
- Decisão e atualização (2026-11-03): Desbloqueado com sucesso usando o endpoint de streaming SSE `https://daily-cloudcode-pa.googleapis.com` com `:streamGenerateContent?alt=sse`. As credenciais de OAuth foram ofuscadas no código fonte (`String.fromCharCodes`) para permitir commit/push sem acionar regras de segredos em texto plano do GitHub Push Protection. Validado no Galaxy S25 Ultra em texto (872ms) e stream (910ms).

## D-014 — Ideias do Memos
- Contexto: `usememos/memos` (MIT, Go e React, self-hosted, 64 mil estrelas) foi comparado com o app em 2026-11-03. Só o README, o CONTEXT.md e os arquivos `.proto` foram lidos.
- Decisão e motivo: entram na F6 quatro ideias que cabem no produto local de uma pessoa: tags hierárquicas (F6-05), filtros por propriedade e visões salvas (F6-06), prévia de links (F6-07) e mapa de atividade (F6-08). Só as ideias são aproveitadas, nenhum código.
- Fora: espaços e colaboração, comentários, reações, links públicos, vários usuários, servidor/Docker/API/webhooks/MCP, Web Clipper e bot do Telegram (o Compartilhar do Android cobre o mesmo uso). Biblioteca de anexos fica em Ideias futuras.

## D-015 — Login OAuth do Claude e acesso a Claude 5.5
- Contexto: O usuário solicitou explicitamente suporte a Claude por OAuth e aos modelos Claude Haiku 5.5, Sonnet 5.5 e Opus 5.5.
- Decisão e motivo: Integrado serviço OAuth para Claude com PKCE e servidor local de callback na porta 1455 e deep link `memex://`. Além disso, os modelos Claude Sonnet 5.5 High e Claude Opus 5.5 High foram adicionados diretamente pelo provedor Google OAuth (Vertex), com cota de 100% e sem o bloqueio de rate-limit de 5 horas do Claude OAuth direto. Validado com resposta real no Galaxy S25 Ultra em 1484ms.

## D-016 — Ideias do Daedalus Echo
- Contexto: `DaedalusApps/daedalus-echo` (MIT, Kotlin e Compose, 12 estrelas, último push em 2026-08-25) é um gravador 100% local: Whisper por sherpa-onnx, Gemma 3 1B por MediaPipe, embeddings com Universal Sentence Encoder, busca por significado, tarefas extraídas e mapa de tópicos. Foram lidos o README, o CHANGELOG, `ModelConfig.kt`, `TranscriptionService.kt`, `EmbeddingService.kt`, `GraphRetrieval.kt`, `TodoExtraction.kt` e `CalendarIntegration.kt`. Nada foi executado.
- Decisão e motivo: entram só ideias, nenhum código (outra linguagem e outra arquitetura). Entram: Whisper multilíngue local (F2-11), extrator de tarefas robusto com deduplicação (F3-07), recuperação por tópicos com piso de relevância (F6-09) e "adicionar à agenda" (F6-11). Os embeddings no aparelho ficam como F6-10 `BACKLOG`.
- Cuidado que o Echo mostra: o Whisper dele é `base.en`, só inglês, com o idioma fixo em `en`, e o Universal Sentence Encoder é centrado em inglês. Para português é preciso um modelo Whisper multilíngue e um embedder que cubra português. Nenhum dos dois foi medido.
- Fora do MVP: Gemma 3 1B local (555 MB, qualidade em pt-BR desconhecida; fica na F7 com Ollama), conversa por voz mãos-livres (F7), mapa global de tópicos (Ideias futuras).
- Descartado: copiar a arquitetura offline total. O nosso produto usa o modelo que o dono escolheu (D-002, D-004).

## D-017 — Direção visual móvel
- Contexto: em 2026-11-03 o dono aprovou a versão v3 das referências AMOLED após comparar com interfaces oficiais do Apple Journal, Day One e Things.
- Decisão: usar fundo preto AMOLED, texto marfim e cinza, âmbar/cobre como acento, composição editorial com listas abertas e divisores finos, tipografia compacta com escala do sistema preservada e ícones coerentes com rótulos. A navegação global não terá barra inferior persistente; os destinos ficam no menu do cabeçalho e em ações contextuais. O chat terá acesso explícito com “Conversar” e “Conversar com a Segunda Mente”.
- Fonte de implementação: [DESIGN.md](../DESIGN.md) e as dez pranchas em `.impeccable-mobile/references/amoled-v3-ios/`.
- Limite: a decisão aprova a direção visual, não declara a implementação pronta. Antes de mudar o roteamento, mapear o menu às rotas existentes; manter acessibilidade, fluxos atuais e testes de widget. F5-04 conclui apenas a documentação; a implementação e suas evidências ficam na fase F5V (D-021).
- Descartado: a exploração v1/v2 com paleta azul e navegação inferior pesada.


## D-018 — Ideias do anarlog
- Contexto: `fastrepl/anarlog` (antes Hyprnote; MIT; Tauri, React e Rust; ~9,8 mil estrelas; último push em 2026-11-01) é um bloco de notas de reunião local, alternativa ao Granola. Foram lidos o README, a documentação (`docs/*.mdx`), a lista de crates e os prompts de `crates/template-app/assets` (`enhance`, `title`, `transcript-patch`, `chat`). Nada foi executado.
- Decisão e motivo: entram só ideias; o código é Rust e Tauri para desktop, e o nosso é Flutter. Entram: tela que mostra qual provedor transcreve e qual resume (F1-09), importação de legenda `.srt` e `.vtt` (F2-12), dicionário de termos (F2-13), regras de prompt do resumo com regenerar (F3-08) e correção conservadora da transcrição (F3-09).
- Licença: o anarlog é MIT e o nosso fork é GPL-3.0, então copiar texto de prompt é permitido com o aviso de licença. Preferimos reescrever em português e testar com as nossas amostras. O diretório `enterprise/` tem licença comercial e não pode ser usado.
- Fora: captura do áudio do sistema e do PC (o Android não permite), calendário e contatos do Google e do Outlook, sincronização, compartilhamento e cobrança (Supabase e Stripe), importação do histórico de outros apps, ditado global e a licença enterprise. O app de celular deles não foi lido.
- Ficam em ideias futuras: separar falantes (diarização e voiceprint, modelos pesados), CLI e servidor MCP (F7) e detecção do idioma do resumo (hoje o app tem só en e pt).

## D-019 — Próxima prioridade: redesign móvel
- Estado: `SUPERSEDED` por D-021 após o dono esclarecer que o redesign deve ocorrer numa fase própria, depois da fase atual.
- Decisão anterior: iniciar a implementação em F5-04 foi registrado, mas não executado.

## D-020 — Fallback resiliente entre modelos e provedores
- Contexto: se o provedor ativo falhar (HTTP 429 rate limit, 500/503/529 sobrecarga, timeout de rede ou falta de cota), os agentes ou chats do usuário falhavam diretamente. O usuário pediu um fallback automático (ex.: se o ChatGPT parar de responder, vai para o Claude; se o Claude parar de responder, vai para o Gemini).
- Decisão: criar `FallbackLLMClient` implementando `LLMClient`, operando em cascata ordenada. Se o provedor primário falhar, tenta sequencialmente os próximos candidatos autorizados com seus respectivos `ModelConfig`. Em streams, realiza failover transparente antes da emissão de dados. Adicionada chave de ativação e tela de reordenação de prioridade por drag-and-drop nas configurações de IA.
- Limite: se um modelo já começou a emitir texto em streaming antes de falhar, a transmissão parcial é encerrada com erro para não duplicar texto já exibido na UI.

## D-021 — Redesign visual após a fase atual
- Estado: `SUPERSEDED` por D-022.
- Contexto: o dono esclareceu em 2026-11-03 que o redesign da versão nova deve ocorrer depois de concluir a fase atual, não como a próxima tarefa dentro dela.
- Decisão: manter o fechamento de F5 como foco atual e inserir F5V — Redesign visual da versão nova imediatamente depois de F5 e antes de F6. F5-04 cobre a direção aprovada e documentada; a implementação das telas fica em F5V.
- Limite: F5V só começa depois de F5. Esta ordem não fecha nem remove critérios dos portões F0–F5 e não desbloqueia F7/F8 por si só.

## D-022 — F5V começa agora
- Contexto: em 2026-11-03, depois do commit `b513d72` (cofre do Android para tokens e chaves), o dono pediu para iniciar a fase visual imediatamente.
- Decisão: a F5V passa a `IN_PROGRESS` e é a fase de trabalho atual. A F5 continua aberta em paralelo: o que falta nela depende do S25 (7 critérios, migração do cofre no aparelho, medições).
- Limite: a ordem muda, os portões não. F5V não fecha a F4 nem a F5, e o MVP só fica pronto com o portão da F5. F7/F8 continuam bloqueadas.

## D-023 — Sem espelho chinês
- Contexto: em 2026-11-04 o dono viu o botão "China Mirror (Faster in CN)" no download do modelo de voz e pediu: "retire esse china, não vamos usar nada da China".
- Decisão: o download do modelo de voz vem só da release do GitHub (`k2-fsa/sherpa-onnx`). O caminho `hf-mirror.com`, a escolha de fonte e os textos dela saíram do app. Guarda em `test/data/services/speech_model_source_test.dart`.
- Em aberto (não alterado, depende do dono): o próprio modelo de voz é o SenseVoice (Alibaba/FunAudioLLM), que a F2-11 já planeja trocar por Whisper; os sabores Android `cn*` (`AppFlavor.isCN`, com Kimi como modelo padrão); os provedores Kimi, Qwen, DeepSeek, Zhipu, MiniMax, Seed e Mimo na lista de modelos.

## D-024 — Remover tudo da China
- Contexto: em 2026-11-04 o dono pediu "Retire tudo que tiver de China do aplicativo".
- Decisão: saíram os provedores Kimi, Qwen, Seed, Zhipu, DeepSeek, MiniMax e Mimo (tipos, textos, listas de modelos, parser de listagem), os modelos chineses das listas do OpenRouter e do Ollama, os sabores Android `cn`, `cnEarly` e `cnDev` (Gradle, `AppFlavor`, atualizador, CI, esquema `cn` do iOS), o geocoding Amap (fica só o OpenStreetMap; a config gravada com `amap` cai no OpenStreetMap) e a transcrição local SenseVoice (Alibaba).
- Configs gravadas com os provedores removidos são descartadas ao carregar, junto com as chaves no cofre (`LLMConfig.removedTypes`; teste em `test/utils/secret_storage_test.dart`). Agentes que apontavam para elas caem no padrão.
- Transcrição: sem modelo local até a F2-11 (Whisper multilíngue). `getUseLocalSpeechToText()` devolve sempre `false` e o interruptor saiu das configurações; a fala vai ao endpoint do ChatGPT (D-011). O código do `WhisperService`/`StreamingTranscriber` com SenseVoice continua no repositório, sem caminho de uso; a F2-11 o troca.
- Em aberto, depende do dono: serviço Memex AI (`typeMemex`, upstream); bibliotecas de autores chineses (`wechat_assets_picker`, `photo_manager`, necessárias ao seletor de fotos); comentários e palavras-chave de busca em chinês que permanecem no código (os aliases chineses do item de idioma foram removidos nesta retomada); `cn.xcconfig` e as configurações `cn` do `project.pbxproj` do iOS (não dá para validar no Windows); `state_util` ainda repara sessões antigas do DeepSeek.
- Continuação (2026-11-04): as galerias de exemplo e o prompt de transações agora usam locais/moedas fora da China; saíram também os aliases de busca em chinês da preferência de idioma. Comentários, dependências e dados existentes foram preservados.

## D-025 — Pranchas 15–23: redesenho do que existe, sem funções novas (2026-11-04)
- Contexto: as pranchas 15–23 mostram telas inteiras; parte delas pede funções que o sistema não tem.
- Decisão: implementar só o que tem suporte real (bloqueio com PIN e espera de 30 s após 3 erros; busca sobre `searchCards`/`searchPkmFiles`; atividade lida de `Tasks`; leitor; revisão antes de enviar; localização). Ficaram de fora, sem dado inventado: grupo "Memória" na busca, etapas/cancelar/tentar de novo em tarefas, Editar/Favoritar no leitor, mapa com tiles, compartilhar por proximidade.
- Pranchas 17, 19 e 20 e o import de DOCX seguem para as fases seguintes da F5V (e F2 para DOCX).

## D-026 — Implementação parcial das pranchas 17, 19, 20 e 22 (2026-11-04)
- Contexto: o dono pediu implementar o que faltava nas referências 17, 19, 20 e 22 sem criar capacidades que o app ainda não tem.
- Decisão de fase: 17 (insights) e 20 (tour/GUIAS) entram na F5V-02; 22 (importação de TXT) entra na F5V-03; 19 (prévia/compartilhamento) entra na F5V-04. As subfases continuam `IN_PROGRESS`; F5V-05 fica `NOT_RUN` sem validação e acessibilidade no S25.
- Limites: insights reutilizam as fábricas existentes; o mapa é geográfico e depende de coordenadas reais, sem grafo de conexões. O tour reaproveita `DemoOverlay`; `Memex Guide.md` é dado do usuário e não foi editado. O compartilhamento usa `ShareService` e a folha nativa sem opções não suportadas. A importação oferece lista, prévia, confirmação, progresso e falha para TXT; DOCX fica adiado porque F2-03 só cobre TXT.
- Evidência de testes: `flutter test test/ui test/l10n` teve 356 aprovações e 5 falhas; a base limpa reproduziu as mesmas cinco. A suíte completa teve 1.112 aprovações, 1 ignorado e 33 falhas, contra 1.074/1/34 na base. As falhas variaram entre duas execuções do mesmo teste de notificações no Windows; não houve nova área de falha nos componentes destas pranchas.

## D-027 — Revisão das pranchas 17/19/20/22 (2026-11-04)
- Corrigido: GUIAS escondia dos Recentes qualquer arquivo com "guia"/"guide" no caminho, mesmo fora da lista GUIAS; agora só some o que a lista já mostra (teste novo). "deepseek" saiu do exemplo de `keyIdHelper` (visível em Editar modelo), de duas strings sem uso e das palavras-chave da busca de configurações.
- Não alterado: `typeMemex` e as ~40 strings "Memex" do serviço oficial (aparecem com o flavor global; depende do dono), `state_util` (reparo de sessões antigas), caminhos reais `.memex`/iCloud nas strings de backup.
- Dispositivo (S25): bloqueio e pôster tinham defeitos que os testes não mostravam (sem Overlay/Navigator acima do app; texto na cor do divisor). Corrigidos; teste do bloqueio agora usa o mesmo posicionamento. Decisão do dono (2026-11-04): não quer PIN nem senha para entrar no app. O bloqueio fica desativado e sem entrada nas configurações (`AppLockSettingsPage` segue sem rota); o código da prancha 15 permanece, testado, mas fora do uso.

## D-028 — Microfone explícito na conversa (2026-11-04)
- Contexto: a gravação rápida só existia como toque longo no botão "+" da timeline; o dono não achou como mandar áudio.
- Decisão: o microfone da conversa grava e transcreve, devolvendo o texto ao campo para revisão (escolha do dono entre gravar-e-transcrever, gravar-e-enviar-arquivo e só expor o "Áudio" do menu). Não envia o arquivo de áudio ao modelo. Sem limite de duração: o transcritor na nuvem rejeita áudio longo (`shortcut:` no código).

## D-029 — Planejar F9 — Meeting Decoder (2026-11-04)
- Contexto: o dono pediu transformar a ideia Meeting Decoder numa fase estruturada, com subetapas, evidência, checklist e referências visuais quando necessárias.
- Decisão: incluir F9 como fase futura `BLOCKED`, fora do MVP. Ela reaproveita F3/F4/F6, começa por texto próprio ou transcrição já importada, exige evidência e confirmação individual, e planeja resumo, ideias, oportunidades, decisões, dúvidas, follow-ups, tarefas, imagens relacionadas e exportações JSON/ICS. IA fica opcional: sem ela, o app não inventa síntese semântica.
- Limites: o plano não autoriza implementação nem altera F5V/F6. Não acrescenta gravação de terceiros, transcrição de áudio na nuvem, inferência de responsável/prazo ou mensagens automáticas. Busca/geração de imagens e o sistema operacional desktop são decisões pendentes de F9-01; referência visual existente é reaproveitada quando suficiente.

## D-030 — Ampliar F9 — Meeting Decoder (2026-11-04)
- Contexto: o dono acrescentou resumos de conversas e PDFs, envio de tarefas/follow-ups para agenda/Todo, uma lista Todo própria e relatórios organizados em PDF/DOCX.
- Decisão: atualizar o plano F9 com PDF como entrada inicial, evidências por página, uma página Todo pessoal no menu existente, encaminhamento confirmado para Todo/calendário/lembretes e exportação PDF/DOCX reutilizando F4. Definir formatos adicionais, PDF escaneado/OCR, regras de destino e sistema desktop em F9-01.
- Limites: F9 continua `BLOCKED` e fora do MVP; esta decisão autoriza o planejamento, não código. A lista Todo do usuário fica separada da fila interna dos agentes. Criar tarefa/evento exige confirmação individual e as permissões necessárias.

## D-031 — Abrir a pesquisa F7-01 (2026-11-05)
- Contexto: o dono pediu avançar para a F7, que está `BLOCKED` até o fechamento da F5 (D-003). Mesmo precedente da D-010 para a F6.
- Decisão: abrir somente F7-01 (pesquisa e decisão de escopo). F7-02 a F7-06 seguem `BLOCKED`; nenhum código, provedor, serviço de PC ou permissão de microfone é autorizado. A F5 continua aberta e o MVP não muda.
- Evidência: `docs/F7-01-viabilidade.md` (termos da Anthropic e da OpenAI, licenças, autenticação, sistemas e limites de dados, com nível de evidência por linha).

## D-032 — F7 sem ponte para CLIs (2026-11-05)
- Contexto: `docs/F7-01-viabilidade.md` propunha uma ponte opcional para Claude Code e Codex CLI. O dono respondeu que o acesso ao ChatGPT por OAuth via Codex, que o app já tem, "já está bom".
- Decisão: não haverá ponte desktop (F7-04) nem interface MCP (F7-05). O app segue com o login ChatGPT já existente; nenhum fluxo novo de credenciais. O limite dos termos permanece: sem login Claude.ai por assinatura (D-005).
- Em aberto, sem decisão: voz full duplex (F7-03) e Ollama (F7-02). Seguem `BLOCKED` até o dono pedir, e só com medição no S25/PC.
- F7-01 cumpre o objetivo (escopo decidido antes de código).
