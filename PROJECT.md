# PROJECT — Segunda Mente

Fork Android independente do [Memex](https://github.com/memex-lab/memex) (Flutter, GPL-3.0). Nome do projeto no doc de visão: "Segunda Memória". Decisões: [docs/questionario/2026-11-02-segunda-memoria.md](docs/questionario/2026-11-02-segunda-memoria.md).

Direção visual aprovada: [DESIGN.md](DESIGN.md) · [índice de documentação e referências](docs/INDEX.md).

## Problema
Pensamentos, ideias e conversas se perdem. Falta um app pessoal para conversar por texto/voz, importar transcrições (TXT do Gravador Samsung) e fotos, gerar relatórios fiéis com evidências e exportá-los, sem perder o histórico ao trocar de modelo de IA.

## Para quem
Uso pessoal do dono do repositório, no Galaxy S25 Ultra. Não há distribuição pública prevista (a GPL-3.0 só passa a pesar se um APK for distribuído).

## MVP (escopo fechado — não acrescentar antes do ponta a ponta)
1. Chat de texto e voz em turnos (falar → transcrever → IA → áudio opcional), com histórico.
2. Importar/compartilhar TXT do Samsung (com timestamps), fotos/imagens (JPG/PNG) e texto colado. Imagem só em modelo com visão, com aviso nos demais. PDF de entrada é desejável, não obrigatório.
3. Registro de modelos: provedores OpenAI e Gemini (OAuth já existente no fork) e Claude por chave de API opcional; model ID personalizado, base URL customizável, teste de conexão e de capacidades, sem lista estática.
4. Relatório por sessão (resumo, ideias, oportunidades, decisões, tarefas, follow-ups, dúvidas) com tipo selecionável e opção customizada; trechos-fonte e timestamps.
5. Exportar o mesmo relatório em PDF, DOCX e Markdown, com acentuação correta em português.
6. Histórico local: conversas, textos originais, imagens, relatórios e itens derivados; busca simples, edição e exclusão; dados independentes do provedor.
7. Controle: nada de responsável/prazo inferido, ideia registrada como decisão ou tarefa definitiva sem confirmação do usuário; dado local por padrão; envio remoto só com escolha explícita e prévia do conteúdo.

## Fora do MVP
Voz full duplex, NotebookLM, grafo temporal (Graphiti), ponte Claude Code/Codex CLI, memória longitudinal avançada, login Claude.ai por assinatura (proibido pelos termos da Anthropic; só via Claude Code oficial no PC, fase F7).

## Restrições
- Base: `main` auditada do Memex; upstream `memex-lab/memex`; app com nome e `applicationId` próprios (Segunda Mente, ex.: `app.segundamente`), sem colidir com o original.
- Sem dependência obrigatória de Hermes, NotebookLM, PC ligado ou serviço pago próprio.
- Conteúdo profissional confidencial de terceiros não vai a provedor externo sem autorização.
- Dependência nova só se reduz trabalho e risco, e se a licença for compatível com GPL-3.0.

## Como saberemos que funcionou
Os 7 critérios de aceite do ROADMAP (seção "Critérios de aceite do MVP") passam no S25 Ultra.

## Autoridade de produto
O dono do repositório aprova mudanças de escopo.
