import json, re, sqlite3, time, numpy as np, onnxruntime as ort
from tokenizers import Tokenizer
C=json.load(open('corpus.json',encoding='utf-8')); notes=C['notes']; ids=list(notes); Q=C['queries']
def rank_metrics(rank_lists):
    out={}
    for kind in ('lex','par'):
        rs=[(q,g,r) for (q,g,k),r in zip([x for x in Q],rank_lists) if k==kind and g]
        h1=h3=mrr=0
        for q,g,r in rs:
            pos=r.index(g)+1 if g in r else 99
            h1+=pos==1; h3+=pos<=3; mrr+=1/pos if pos<99 else 0
        n=len(rs); out[kind]=(n,h1/n,h3/n,mrr/n)
    return out
# baseline FTS5
db=sqlite3.connect(':memory:'); db.execute("create virtual table t using fts5(id unindexed, body, tokenize='unicode61 remove_diacritics 2')")
for i in ids: db.execute("insert into t values(?,?)",(i,notes[i]))
def fts(q,strict=False):
    toks=re.findall(r'\w+',q.lower()); 
    if not toks: return []
    m=(' AND ' if strict else ' OR ').join('"%s"'%t for t in toks)
    return [r[0] for r in db.execute("select id from t where t match ? order by bm25(t) limit 10",(m,))]
def report(name,res,off):
    print(f"\n== {name}")
    for k,(n,h1,h3,mrr) in res.items(): print(f"  {k}: n={n} acerto@1={h1:.2f} acerto@3={h3:.2f} MRR={mrr:.2f}")
    print("  "+off)
for strict in (False,True):
    ranks=[fts(q,strict) for q,g,k in Q]
    offn=sum(1 for (q,g,k),r in zip(Q,ranks) if k=='off' and r)
    report("busca textual FTS5 "+("E (todas as palavras)" if strict else "OU (qualquer palavra)"),rank_metrics(ranks),f"fora do tema com algum resultado: {offn}/{sum(1 for x in Q if x[2]=='off')}")
# embeddings
def make(path,tokp,qp='',pp='',maxlen=128):
    tok=Tokenizer.from_file(tokp); tok.enable_truncation(maxlen); tok.enable_padding()
    so=ort.SessionOptions(); s=ort.InferenceSession(path,so,providers=['CPUExecutionProvider'])
    names={i.name for i in s.get_inputs()}
    def emb(texts,prefix):
        e=tok.encode_batch([prefix+t for t in texts]); ii=np.array([x.ids for x in e]); am=np.array([x.attention_mask for x in e])
        feed={'input_ids':ii,'attention_mask':am}
        if 'token_type_ids' in names: feed['token_type_ids']=np.zeros_like(ii)
        h=s.run(None,feed)[0]; m=am[...,None]; v=(h*m).sum(1)/m.sum(1)
        return v/np.linalg.norm(v,axis=1,keepdims=True)
    return emb
cfgs=[("multilingual-e5-small fp32 (470 MB)","m/multilingual-e5-small/onnx/model.onnx","m/multilingual-e5-small/tokenizer.json","query: ","passage: "),
("multilingual-e5-small int8 (118 MB)","m/multilingual-e5-small/onnx/model_int8.onnx","m/multilingual-e5-small/tokenizer.json","query: ","passage: "),
("paraphrase-multilingual-MiniLM-L12 fp32 (470 MB)","m/paraphrase-multilingual-MiniLM-L12-v2/onnx/model.onnx","m/paraphrase-multilingual-MiniLM-L12-v2/tokenizer.json","","")]
for name,mp,tp,qp,pp in cfgs:
    emb=make(mp,tp); t=time.time(); D=emb([notes[i] for i in ids],pp); td=(time.time()-t)/len(ids)*1000
    t=time.time(); QE=emb([q[0] for q in Q],qp); tq=(time.time()-t)/len(Q)*1000
    S=QE@D.T; ranks=[[ids[j] for j in np.argsort(-S[i])] for i in range(len(Q))]
    top=S.max(1); offs=[top[i] for i,x in enumerate(Q) if x[2]=='off']
    good=[S[i,ids.index(x[1])] for i,x in enumerate(Q) if x[1]]
    thr=max(offs); above=np.mean([g>thr for g in good])
    report(name,rank_metrics(ranks),f"fora do tema: maior nota {max(offs):.2f} | acertos com nota acima dela: {above:.0%} | ms/nota {td:.0f}, ms/consulta {tq:.0f} (PC, 16 núcleos)")
