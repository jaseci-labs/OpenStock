import json, subprocess, statistics, sys, re, os
O="http://127.0.0.1:8621"; J="__J__"
SIDES=[("jac-before","http://127.0.0.1:8623"),("jac","http://127.0.0.1:8622")]
C=open(os.environ.get('OCOOKIE','/tmp/osbench/ocookie')).read().strip(); T=open(os.environ.get('JTOKEN','/tmp/osbench/jtok')).read().strip()
def act(aid, args): return {"url":O+"/watchlist","method":"POST","headers":{"Cookie":C,"Next-Action":aid,"content-type":"text/plain;charset=UTF-8"},"body":json.dumps(args)}
def call(mod, fn, args, auth=True):
    h={"content-type":"application/json"}
    if auth: h["Authorization"]="Bearer "+T
    return {"url":f"__J__/__jac/call/api/{mod}/{fn}","method":"POST","headers":h,"body":json.dumps({"args":args})}
def flight(b): # Next server action reply: line "1:<json>"
    for line in b.splitlines():
        if line.startswith("1:"): return json.loads(line[2:])
def jd(b): return json.loads(b)["data"]
def smap(b): return re.findall(r"<loc>(.*?)</loc>\s*<changefreq>(.*?)</changefreq>\s*<priority>(.*?)</priority>", b)
W = {
 "robots.txt": ({"url":O+"/robots.txt"}, [{"url":"__J__/robots.txt"}], lambda o,j: o==j.replace("Disallow: /__jac/\n","")),
 "sitemap.xml": ({"url":O+"/sitemap.xml"}, [{"url":"__J__/sitemap.xml"}], lambda o,j: smap(o)==smap(j) and len(smap(o))>500),
 "stock page /s/AAPL": ({"url":O+"/s/AAPL"}, [{"url":"__J__/s/AAPL"}, call("api.seo","ticker_page",{"raw":"AAPL"},False)],
     lambda o,j: jd(j)["title"].replace("&","&amp;") in o and jd(j)["intro"][:60] in o.replace("&#x27;","'")),
 "directory /s": ({"url":O+"/s"}, [{"url":"__J__/s"}, call("api.seo","tickers_by_sector",{},False), call("api.seo","directory_ld",{},False)],
     lambda o,j: True),
 "get watchlist": (act("004f4efcea4520b00e8468880fa8243f005aa3d7de",[]), [call("api.portfolio","get_watchlist",{})],
     lambda o,j: [(x["symbol"],x["company"]) for x in flight(o)]==[(x["symbol"],x["company"]) for x in jd(j)]),
 "in watchlist": (act("401965890773be5b3e30ff4502e7feb2c605781a7d",["AAPL"]), [call("api.portfolio","in_watchlist",{"symbol":"AAPL"})],
     lambda o,j: flight(o) is True and jd(j) is True),
 "get lists": (act("00979fc478c3e07f2eceb87f07a6c7cf8b72aac83e",[]), [call("api.portfolio","get_lists",{})],
     lambda o,j: [(x["name"],x["count"],x["symbols"]) for x in flight(o)]==[(x["name"],x["count"],x["symbols"]) for x in jd(j)]),
 "get alerts": (act("00f6810536a0e6d4f3ca44d4d4e6ad728c685b653e",[]), [call("api.portfolio","get_alerts",{})],
     lambda o,j: flight(o)==[] and jd(j)==[]),
 "sign in": ({"url":O+"/api/auth/sign-in/email","method":"POST","headers":{"content-type":"application/json","origin":"https://openstock.example"},"body":json.dumps({"email":"bench1@example.com","password":"benchpass123"}),"xff":1},
     [{"url":"__J__/__jac/auth/login","method":"POST","headers":{"content-type":"application/json"},"body":json.dumps({"username":"bench1","password":"benchpass123"}),"xff":1}],
     lambda o,j: json.loads(o)["user"]["email"]=="bench1@example.com" and json.loads(j)["data"]["user"]=="bench1"),
}
def run(spec, n, c):
    out=subprocess.run(["node",os.path.join(os.path.dirname(os.path.abspath(__file__)),'load.mjs'),json.dumps(spec),str(n),str(c)],capture_output=True,text=True).stdout
    return json.loads(out)
R=int(os.environ.get("ROUNDS","5")); only=sys.argv[1:]
def sub(spec, base): return json.loads(json.dumps(spec).replace("__J__", base))
print("load:", open("/proc/loadavg").read().split()[:3])
print(f"{'workload':22s} {'orig p50':>9s} {'before':>9s} {'after':>9s}   {'orig rps':>8s} {'before':>8s} {'after':>8s}  same")
for name,(o,js,cmp) in W.items():
    if only and name not in only: continue
    n = 30 if name=="sign in" else 300
    p50={"orig":[]}; p50.update({s:[] for s,_ in SIDES}); bodies={}
    for r in range(R):
        a=run(o,n,1); assert a["errs"]==0,(name,a["body"][:300]); p50["orig"].append(a["p50"]); bodies["orig"]=a["body"]
        for side,base in SIDES:
            tot=0
            for s in js:
                b=run(sub(s,base),n,1); assert b["errs"]==0,(name,side,b["body"][:300]); tot+=b["p50"]; bodies[side]=b["body"]
            p50[side].append(tot)
    rps={"orig":run(o,n*2,16)["rps"]}
    for side,base in SIDES:
        rps[side]=1/sum(1/run(sub(s,base),n*2,16)["rps"] for s in js)
    same=all(cmp(bodies["orig"],bodies[s]) for s,_ in SIDES)
    med={k:statistics.median(v) for k,v in p50.items()}
    print(f"{name:22s} {med['orig']:9.2f} {med['jac-before']:9.2f} {med['jac']:9.2f}   {rps['orig']:8.0f} {rps['jac-before']:8.0f} {rps['jac']:8.0f}  {same}", flush=True)
print("load:", open("/proc/loadavg").read().split()[:3])
