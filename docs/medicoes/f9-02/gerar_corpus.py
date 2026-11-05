import json, collections, sys

NI = "não informado"
cases = []

def case(cat, source, text, expect, note=""):
    cases.append({"id": f"c{len(cases)+1:02d}", "categoria": cat, "origem": source, "texto": text, "esperado": expect, "nota": note})

def item(kind, text, owner=NI, due=NI, ev="", status="sugerido"):
    return {"tipo": kind, "texto": text, "responsavel": owner, "prazo": due, "evidencia": ev, "estado": status}

# 1. tarefa clara (6)
case("tarefa_clara", "conversa", "[00:01:10] Carlos: Eu envio a proposta revisada para a Marina até sexta-feira, dia 21.",
     [item("tarefa", "Enviar a proposta revisada à Marina", "Carlos", "2026-11-21", "00:01:10")],
     "responsável e data ditos de forma explícita; sexta dia 21 coincide")
case("tarefa_clara", "conversa", "[00:03:02] Marina: Fica combinado: eu agendo a reunião com o fornecedor amanhã às 10h.",
     [item("tarefa", "Agendar a reunião com o fornecedor", "Marina", "amanhã 10h", "00:03:02")],
     "'amanhã' depende da data da sessão; registrar a data da sessão no corpo do teste")
case("tarefa_clara", "nota", "Preciso renovar o seguro do carro antes do dia 30.",
     [item("tarefa", "Renovar o seguro do carro", "o próprio autor", "antes do dia 30", "nota")],
     "nota própria: o autor é o responsável")
case("tarefa_clara", "conversa", "[00:12:40] Paulo: Vou ligar para o contador na segunda e perguntar sobre o imposto.",
     [item("tarefa", "Ligar para o contador sobre o imposto", "Paulo", "segunda (data a confirmar)", "00:12:40")],
     "'segunda' sem semana definida fica pendente")
case("tarefa_clara", "conversa", "[00:20:15] Ana: Tem que atualizar o manual até o fim do mês, e o Rui revisa.",
     [item("tarefa", "Atualizar o manual", NI, "fim do mês", "00:20:15"), item("tarefa", "Revisar o manual", "Rui", NI, "00:20:15")],
     "dois itens; dono da primeira não foi dito")
case("tarefa_clara", "nota", "Lembrar de pagar a taxa do condomínio dia 5.",
     [item("tarefa", "Pagar a taxa do condomínio", "o próprio autor", "dia 5", "nota")])

# 2. hipótese / opinião (5)
case("hipotese_opiniao", "conversa", "[00:05:00] Rui: Acho que talvez a gente devesse trocar de fornecedor.",
     [], "hipótese: não vira tarefa nem decisão; pode virar ideia")
case("hipotese_opiniao", "conversa", "[00:06:12] Ana: Seria legal ter um painel com as métricas.",
     [item("ideia", "Painel com as métricas", NI, NI, "00:06:12")], "ideia, não tarefa")
case("hipotese_opiniao", "nota", "Quem sabe eu começo a correr de manhã.",
     [], "intenção vaga sem compromisso")
case("hipotese_opiniao", "conversa", "[00:30:00] Paulo: Não gosto de ligar para clientes sem aviso.",
     [], "opinião; verbo solto não vira tarefa")
case("hipotese_opiniao", "conversa", "[00:31:10] Carlos: Eu achei que o Rui ia mandar o arquivo.",
     [], "suposição passada; não é compromisso")

# 3. fato passado (5)
case("fato_passado", "conversa", "[00:02:00] Marina: Ontem o time enviou o relatório ao cliente.",
     [item("resumo", "O time enviou o relatório ao cliente ontem", NI, NI, "00:02:00")], "fato; vira resumo")
case("fato_passado", "conversa", "[00:08:20] Carlos: Já resolvi o problema do login.",
     [item("resumo", "Carlos resolveu o problema do login", "Carlos", NI, "00:08:20")])
case("fato_passado", "nota", "Fizemos a migração do banco na sexta passada.",
     [item("resumo", "Migração do banco feita na sexta passada", NI, NI, "nota")])
case("fato_passado", "conversa", "[00:15:30] Ana: O contrato foi assinado semana passada.",
     [item("resumo", "Contrato assinado na semana passada", NI, NI, "00:15:30")])
case("fato_passado", "conversa", "[00:16:00] Rui: Concluímos a revisão do código.",
     [item("resumo", "Revisão do código concluída", NI, NI, "00:16:00")])

# 4. duplicata (3)
case("duplicata", "conversa", "[00:04:00] Carlos: Eu envio o resumo. [00:09:00] Carlos: Então, o resumo eu mando hoje.",
     [item("tarefa", "Enviar o resumo", "Carlos", "hoje", "00:04:00"), ],
     "mesma tarefa em dois trechos: um item, com os dois trechos como evidência; duplicata é sinalizada, não removida em silêncio")
case("duplicata", "nota", "Ligar para o dentista. Marcar a consulta no dentista.",
     [item("tarefa", "Marcar consulta no dentista", "o próprio autor", NI, "nota")], "possível duplicata sinalizada")
case("duplicata", "conversa", "[00:10:00] Ana: Revisar o manual. [00:40:00] Rui: Revisar o manual de usuário. ",
     [item("tarefa", "Revisar o manual", NI, NI, "00:10:00")], "dono ausente e quase duplicata: sinalizar, deixar o usuário decidir")

# 5. dono ausente (4)
case("dono_ausente", "conversa", "[00:07:00] Marina: Alguém precisa atualizar a planilha de custos.",
     [item("tarefa", "Atualizar a planilha de custos", NI, NI, "00:07:00")], "não inferir responsável")
case("dono_ausente", "conversa", "[00:11:00] Paulo: Temos que enviar o orçamento ao cliente.",
     [item("tarefa", "Enviar o orçamento ao cliente", NI, NI, "00:11:00")], "'temos' não nomeia ninguém")
case("dono_ausente", "nota", "Falta marcar a reunião de equipe.",
     [item("tarefa", "Marcar a reunião de equipe", "o próprio autor", NI, "nota")], "em nota própria o autor é presumido como dono")
case("dono_ausente", "conversa", "[00:21:00] Ana: Vamos revisar os contratos antigos.",
     [item("tarefa", "Revisar os contratos antigos", NI, NI, "00:21:00")], "'vamos' é do grupo; dono não informado")

# 6. data ambígua (4)
case("data_ambigua", "conversa", "[00:13:00] Rui: Eu entrego na quinta.",
     [item("tarefa", "Entregar", "Rui", "quinta (semana a confirmar)", "00:13:00")], "sem semana definida; exige confirmação")
case("data_ambigua", "nota", "Pagar a fatura no dia 3.",
     [item("tarefa", "Pagar a fatura", "o próprio autor", "dia 3 (mês a confirmar)", "nota")], "mês ausente")
case("data_ambigua", "conversa", "[00:14:00] Carlos: A gente se fala semana que vem e fecha isso.",
     [item("tarefa", "Fechar o assunto", NI, "semana que vem (dia a confirmar)", "00:14:00")], "intervalo vago")
case("data_ambigua", "conversa", "[00:17:00] Marina: Pode ficar para o começo do mês.",
     [], "sem tarefa explícita; só uma preferência de prazo")

# 7. decisão x brainstorm (3)
case("decisao", "conversa", "[00:18:00] Ana: Decidido: vamos adiar o lançamento para dezembro.",
     [item("decisao", "Adiar o lançamento para dezembro", NI, "dezembro", "00:18:00")], "decisão explícita")
case("decisao", "conversa", "[00:19:00] Rui: Podemos adiar o lançamento ou lançar só a versão básica; vamos pensar.",
     [item("ideia", "Adiar o lançamento ou lançar só a versão básica", NI, NI, "00:19:00")], "alternativas em aberto: não é decisão")
case("decisao", "conversa", "[00:22:00] Carlos: Ficou combinado que a reunião de segunda passa para terça.",
     [item("decisao", "Reunião de segunda passa para terça", NI, "terça (semana a confirmar)", "00:22:00")])

# 8. dúvida (3)
case("duvida", "conversa", "[00:23:00] Marina: Quem fica com o suporte no feriado?",
     [item("duvida", "Quem fica com o suporte no feriado", NI, NI, "00:23:00")], "pergunta sem resposta vira dúvida")
case("duvida", "nota", "Será que o contrato permite renovação automática?",
     [item("duvida", "O contrato permite renovação automática?", NI, NI, "nota")])
case("duvida", "conversa", "[00:24:00] Paulo: Qual é o limite de gasto? [00:24:20] Ana: Dez mil.",
     [item("resumo", "O limite de gasto é dez mil", NI, NI, "00:24:20")], "pergunta respondida no mesmo trecho não fica como dúvida")

# 9. follow-up (2)
case("followup", "conversa", "[00:25:00] Carlos: Depois eu volto com o preço do frete e a gente confirma.",
     [item("followup", "Voltar com o preço do frete e confirmar", "Carlos", NI, "00:25:00")])
case("followup", "nota", "Perguntar ao Rui se o prazo mudou.",
     [item("followup", "Perguntar ao Rui se o prazo mudou", "o próprio autor", NI, "nota")])

# 10. PDF com texto selecionável: evidência por página (5)
case("pdf_pagina", "pdf", "[p.1] Ata da reunião de 12/09. Presentes: Ana, Rui, Paulo. [p.2] Ficou decidido que o orçamento será revisado. Paulo envia a versão final até 20/09.",
     [item("decisao", "Revisar o orçamento", NI, NI, "p.2"), item("tarefa", "Enviar a versão final do orçamento", "Paulo", "2026-09-20", "p.2")],
     "evidência por página; resumo deve citar p.1 para a lista de presentes")
case("pdf_pagina", "pdf", "[p.1] Contrato de prestação de serviços. [p.3] A contratada deve entregar o relatório mensal até o dia 10 de cada mês.",
     [item("tarefa", "Entregar o relatório mensal até o dia 10 de cada mês", "a contratada", "dia 10 de cada mês", "p.3")],
     "obrigação contratual; recorrente, não data única")
case("pdf_pagina", "pdf", "[p.1] Relatório trimestral. [p.2] No trimestre anterior, foram vendidas 120 unidades. [p.4] Recomenda-se avaliar um novo canal de vendas.",
     [item("resumo", "No trimestre anterior foram vendidas 120 unidades", NI, NI, "p.2"), item("ideia", "Avaliar um novo canal de vendas", NI, NI, "p.4")],
     "fato passado e recomendação (ideia), cada um com a sua página")
case("pdf_pagina", "pdf", "[p.1] Página sem texto selecionável (imagem escaneada).",
     [], "PDF escaneado: F9-01 decide OCR; sem OCR o relatório avisa que não há texto, em vez de inventar")
case("pdf_pagina", "pdf", "[p.2] Prazo: 15/10. [p.5] Prazo: 15/10.",
     [item("tarefa", "Cumprir o prazo de 15/10", NI, "2026-10-15", "p.2")], "mesma data em duas páginas: um item, com as duas páginas de evidência")

assert len(cases) == 40, len(cases)
assert len({c["id"] for c in cases}) == 40
for c in cases:
    for e in c["esperado"]:
        assert e["tipo"] in {"tarefa", "decisao", "ideia", "duvida", "followup", "resumo"}, e
        assert e["evidencia"], (c["id"], e)
contagem = collections.Counter(c["categoria"] for c in cases)
doc = {"versao": 1, "aviso": "Casos fictícios; nenhum dado pessoal real. Dono e prazo ausentes ficam como 'não informado'. Nenhum item é confirmado: todos nascem 'sugerido'.", "casos": cases}
out = sys.argv[1]
with open(out, "w", encoding="utf-8") as f:
    json.dump(doc, f, ensure_ascii=False, indent=1)
print(dict(contagem), len(cases))
