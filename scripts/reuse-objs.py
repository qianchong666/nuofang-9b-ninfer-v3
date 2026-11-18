import json, os, hashlib, shutil, time
OLD_BUILD="G:/build/ninfer-86"; OLD_ROOT="G:/build/src"
NEW_BUILD="G:/build/wemx-86"; NEW_ROOT="G:/build/wemx-9b/src/src-tree/fusion-engine-src"
def load(build, root):
    p=os.path.join(build,"compile_commands.json")
    m={}
    for e in json.load(open(p,encoding="utf-8")):
        src=e["file"].replace("\\","/")
        if not src.lower().startswith(root.lower()): continue
        rel=src[len(root):].lstrip("/").lower()
        out=e.get("output")
        if not out: continue
        m[rel]=os.path.join(build,out.replace("\\","/"))
    return m
old=load(OLD_BUILD,OLD_ROOT); new=load(NEW_BUILD,NEW_ROOT)
print("old entries %d, new entries %d, common %d"%(len(old),len(new),len(set(old)&set(new))))
def sha(p):
    h=hashlib.sha256()
    with open(p,"rb") as f:
        for b in iter(lambda:f.read(1<<20), b""): h.update(b)
    return h.hexdigest()
copied=skipped_same=missing=diff=0
for rel in sorted(set(old)&set(new)):
    so=os.path.join(OLD_ROOT,rel); sn=os.path.join(NEW_ROOT,rel)
    oo=old[rel]; no=new[rel]
    if not (os.path.exists(so) and os.path.exists(sn)): missing+=1; continue
    if not os.path.exists(oo): missing+=1; continue
    if sha(so)!=sha(sn): diff+=1; continue
    if os.path.exists(no):
        skipped_same+=1; continue
    os.makedirs(os.path.dirname(no),exist_ok=True)
    shutil.copyfile(oo,no); os.utime(no,None); copied+=1
print("copied=%d already=%d diff-source=%d missing=%d"%(copied,skipped_same,diff,missing))
