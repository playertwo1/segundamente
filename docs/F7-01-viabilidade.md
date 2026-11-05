# F7-01 — Viabilidade: voz contínua, modelos locais e ponte para CLIs oficiais

Data: 2026-11-05. Estado: **decidido pelo dono em D-032: sem ponte para CLIs**. Nada aqui é código nem autoriza código.

Nível de evidência usado abaixo: **OFICIAL** (página do fornecedor lida em 2026-11-05), **SECUNDÁRIA** (blog ou índice de pacotes, a confirmar) e **A MEDIR** (só se sabe testando no S25 ou no PC do dono).

## 1. Regra de ouro

A ponte não pode contornar autenticação nem termos do fornecedor, e toda captura e todo encaminhamento começam por uma ação do usuário (portão F7). O app nunca lê, copia, guarda nem repassa credenciais dos CLIs.

## 2. CLIs oficiais no desktop

| Ponto | Claude Code (Anthropic) | Codex CLI (OpenAI) |
|---|---|---|
| Licença do programa | Termos de uso da Anthropic (Consumer para Free/Pro/Max/Ultra; Commercial para Team/Enterprise/API). Não é código aberto. **OFICIAL** | Apache-2.0. **OFICIAL** |
| Login | OAuth da conta Claude (assinatura) ou chave de API. **OFICIAL** | "Sign in with ChatGPT" (assinatura) ou chave de API. **OFICIAL** |
| Onde ficam as credenciais | No próprio CLI, na máquina do usuário. | `~/.codex/auth.json` em texto puro ou no cofre do SO; a OpenAI manda tratá-lo "como senha". **OFICIAL** |
| Uso por terceiros | Terceiro **não pode** oferecer login Claude.ai no próprio app, nem rotear pedidos pelas credenciais de assinatura em nome de usuários, nem coletar, guardar ou intermediar credenciais ou tokens de sessão. Quem constrói produto com o Agent SDK deve usar chave de API. O usuário **pode** entrar, com a própria assinatura, no binário **sem modificação**. Limites das assinaturas "assumem uso comum e individual". **OFICIAL** | Para automação, a OpenAI manda usar chave de API; tokens de acesso servem a "scripts, agendadores e runners privados de confiança"; não expor a execução em ambiente público. **OFICIAL** |
| Modo sem tela | `claude -p` (imprime e sai). **SECUNDÁRIA**; cobrança com token de assinatura é descrita de formas conflitantes. | `codex exec`. Reaproveita o login salvo; sem aprovações interativas, o padrão é somente leitura; a documentação manda definir sandbox e aprovação explícitos. **OFICIAL** (documentação de modo não interativo) |
| Sistemas | Windows, macOS e Linux. **A MEDIR** na instalação do dono. | macOS e Linux têm binário; o README só dá comando PowerShell para Windows. **A MEDIR** no PC do dono (WSL é a alternativa). |
| Dados | O que a ponte enviar vai para a Anthropic sob os termos da conta do dono. | O que a ponte enviar vai para a OpenAI sob a conta do dono. |

Consequência para o desenho (decorre dos termos acima, não é opinião):
1. O app **não** chama a API de assinatura de nenhum dos dois, e **não** manda token do celular para lugar nenhum.
2. Quem fala com o fornecedor é o **binário oficial, sem modificação, na conta do dono, no PC dele**. O app só entrega um texto ao PC.
3. O app não promete "Claude no celular". Isso continua proibido pela D-005.
4. Uso é individual e do dono. Distribuir a ponte a outras pessoas exigiria rever os termos (a Anthropic proíbe pagar ou intermediar o uso de terceiros).

## 3. Modelos locais (Ollama)

| Ponto | Resultado |
|---|---|
| Licença | MIT (índice de pacotes Go). Cada modelo tem a própria licença. **SECUNDÁRIA** |
| API | REST em `http://localhost:11434`, **sem autenticação por padrão**; expor na rede exige firewall ou proxy. **SECUNDÁRIA** |
| Sistemas | Windows, macOS e Linux. **SECUNDÁRIA** |
| Memória | Depende do modelo. Regra de bolso de blogs: 1 a 4 bilhões de parâmetros cabem em ~8 GB de RAM; 7 a 14 bilhões pedem ~16 GB. **SECUNDÁRIA** |
| Qualidade em pt-BR | **A MEDIR** (F7-02). As buscas não trouxeram nenhum dado confiável. |
| No app hoje | O app já aceita Ollama como provedor (ver `AGENTS.md`). F7-02 não cria provedor: mede. |

Privacidade: modelo local no PC mantém o texto na máquina. Mas o celular só alcança o Ollama do PC pela rede; isso exige um canal protegido (a rede do dono já usa Tailscale) e nunca a porta aberta na internet.

## 4. Voz full duplex no Android

O que o app tem: gravar e transcrever com SenseVoice offline (sherpa-onnx), com o texto voltando ao campo para revisão (D-028). Não há voz sintetizada nem escuta contínua.

O que full duplex pede e hoje **não existe**: escuta contínua com detecção de voz (VAD), voz sintetizada, e **interrupção** (o usuário fala por cima da resposta). O pacote sherpa-onnx tem VAD (Silero) e reconhecimento em fluxo para Flutter (**SECUNDÁRIA**).

Riscos que só medição resolve (**A MEDIR** no S25, F7-03):
- eco: o microfone ouve a própria resposta e se interrompe;
- bateria e calor com microfone aberto;
- latência até a primeira palavra da resposta;
- privacidade: microfone aberto é o maior risco do F7. Exige indicador sempre visível, pausa e cancelamento em um toque, e nenhuma gravação sem ação visível (critério F7-03).

## 5. Opções para a ponte celular → PC

| Opção | Como funciona | Credenciais | Risco | Esforço |
|---|---|---|---|---|
| **A. Entrega de texto pronto (recomendada para começar)** | O app monta o pedido (cartões ou itens escolhidos pelo usuário), mostra a prévia exata e entrega o texto ao PC por um caminho que o dono já usa (área de transferência sincronizada, arquivo numa pasta, compartilhar). O dono cola no `claude` ou no `codex` já abertos. | Nenhuma passa pelo app. | Mínimo. Nada executa sem o dono. | Baixo |
| **B. Serviço pequeno no PC** | Um programa no PC recebe o pedido, mostra uma janela de confirmação com destino, pasta e comando, e só então roda `codex exec` ou `claude -p` na conta do dono, em modo somente leitura por padrão. Pareamento com código; canal só pela rede privada. | O CLI usa o login que ele já tem; o serviço não lê o arquivo de credenciais. | Médio: executar programa a pedido de outro aparelho. Precisa de pareamento, lista de pastas permitidas, cancelamento e registro. | Médio-alto |
| **C. SSH do celular** | O celular abre sessão no PC. | Chave SSH no celular. | Alto: shell completo no celular. | Alto; descartada |

Opção B só entra depois de A funcionar e de o dono aprovar o desenho de segurança. MCP (F7-05) fica adiado: é outra porta de entrada e dobra a superfície de risco.

## 6. Recomendação

1. F7-01 aceita com a opção **A** como primeira entrega de F7-04, e **B** como etapa opcional posterior, só com decisão própria.
2. Sistema desktop: o do dono, Windows 11; Claude Code e Codex precisam ser testados nele (F7-04 pede teste com cada CLI instalada). Linux e macOS ficam fora até haver necessidade.
3. F7-02 (Ollama): medir antes de qualquer promessa, no PC do dono, com texto inventado; sem ganho em pt-BR, descartar com o motivo.
4. F7-03 (voz): só começa depois do F7-02, e o primeiro passo é medir eco e bateria no S25 com um protótipo descartável, antes de qualquer tela.
5. Nada do F7 muda o MVP: F5 continua aberta.

## 7. O que o dono precisa decidir

Está em D-032: escopo da ponte (A, B ou as duas, em ordem), e se a voz full duplex continua no plano.

## Fontes

- Anthropic, Claude Code — Legal and compliance: https://code.claude.com/docs/en/legal-and-compliance
- OpenAI, Codex CLI (repositório e licença): https://github.com/openai/codex
- OpenAI, Codex — autenticação: https://learn.chatgpt.com/docs/auth (redireciona de https://developers.openai.com/codex/auth)
- OpenAI, Codex — modo não interativo: https://developers.openai.com/codex/noninteractive
- Ollama (licença, API, sistemas): resultados de busca de 2026-11-05, secundários; confirmar em https://ollama.com
- sherpa-onnx (VAD, reconhecimento em fluxo, Flutter): https://pub.dev/packages/sherpa_onnx
