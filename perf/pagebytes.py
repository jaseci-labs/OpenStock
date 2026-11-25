import re, sys, urllib.request, gzip
def get(u):
    r=urllib.request.urlopen(urllib.request.Request(u,headers={"Accept-Encoding":"gzip"}))
    b=r.read(); return b, r.headers.get("Content-Encoding")
for base,path in [("http://127.0.0.1:8621","/s/AAPL"),("http://127.0.0.1:8622","/s/AAPL"),("http://127.0.0.1:8621","/"),("http://127.0.0.1:8622","/")]:
    html,enc=get(base+path); text=gzip.decompress(html).decode() if enc=="gzip" else html.decode()
    assets=set(re.findall(r'(?:src|href)="(/[^"]+\.(?:js|css))"',text))
    tot=len(html); raw=len(text); detail=[]
    for a in sorted(assets):
        b,e=get(base+a); tot+=len(b); raw+=len(gzip.decompress(b)) if e=="gzip" else len(b); detail.append(e)
    print(f"{base[-4:]} {path:8s} requests {1+len(assets):3d} wire {tot/1024:7.1f} KB  uncompressed {raw/1024:7.1f} KB  gzip:{set(detail)|{enc}}")
