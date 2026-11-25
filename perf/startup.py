import subprocess, time, urllib.request, os, sys, statistics, signal, shutil, tempfile
BASE="/home/jayanaka/neojac-deslop/base/OpenStock"
JAC="/home/jayanaka/neojac-deslop/repos/Open-Dev-Society_OpenStock"
ENV=dict(os.environ, BETTER_AUTH_SECRET="0123456789abcdef0123456789abcdef", BETTER_AUTH_URL="https://openstock.example",
         MONGODB_URI="mongodb://127.0.0.1:27117/openstock_bench", NEXT_TELEMETRY_DISABLED="1", NODE_ENV="production")
def orig(port):
    return subprocess.Popen([f"{BASE}/node_modules/.bin/next","start","-p",str(port)],cwd=BASE,env=ENV,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
def jac(port):
    d=os.environ.get("JACDATA") or tempfile.mkdtemp()
    e=dict(ENV, JAC_WEB_LISTEN=f"127.0.0.1:{port}", JAC_WEB_DATA=d)
    return subprocess.Popen([f"{JAC}/dist/web-linux-x86_64/web"],cwd=JAC,env=e,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
def first(port, path):
    t0=time.perf_counter()
    while True:
        try:
            with urllib.request.urlopen(f"http://127.0.0.1:{port}{path}",timeout=5) as r:
                body=r.read()
                return time.perf_counter()-t0, body
        except Exception:
            if time.perf_counter()-t0>60: raise
            time.sleep(0.005)
N=int(sys.argv[1]) if len(sys.argv)>1 else 7
path=sys.argv[2] if len(sys.argv)>2 else "/robots.txt"
res={"orig":[], "jac":[]}; bodies={}
for i in range(N):
    for name,f,port in (("orig",orig,8611),("jac",jac,8612)):
        t0=time.perf_counter(); p=f(port)
        dt,body=first(port,path)
        res[name].append(dt); bodies[name]=body
        p.send_signal(signal.SIGTERM); p.wait()
        time.sleep(0.3)
for k,v in res.items(): print(k, "median %.3fs"%statistics.median(v), " ".join("%.3f"%x for x in v))
print("same body:", bodies["orig"]==bodies["jac"])
if bodies["orig"]!=bodies["jac"]:
    print("ORIG:",bodies["orig"][:600]); print("JAC:",bodies["jac"][:600])
