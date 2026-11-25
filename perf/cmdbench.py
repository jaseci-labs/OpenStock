import subprocess, time, statistics, os, sys
BASE="/home/jayanaka/neojac-deslop/base/OpenStock"; JAC="/home/jayanaka/neojac-deslop/repos/Open-Dev-Society_OpenStock"
env=dict(os.environ, BETTER_AUTH_URL="https://openstock.example", FINNHUB_API_KEY="x", MONGODB_URI="mongodb://x", BETTER_AUTH_SECRET="0123456789abcdef0123456789abcdef")
cmds={"orig":(["node","scripts/check-env.mjs"],BASE), "jac":(["/tmp/osbench/check_env"],JAC)}
res={k:[] for k in cmds}; outs={}
for i in range(int(sys.argv[1]) if len(sys.argv)>1 else 15):
    for k,(c,cwd) in cmds.items():
        t=time.perf_counter(); p=subprocess.run(c,cwd=cwd,env=env,capture_output=True,text=True); res[k].append(time.perf_counter()-t); outs[k]=(p.returncode,p.stdout)
for k,v in res.items(): print(k,"median %.1f ms"%(statistics.median(v)*1000),"exit",outs[k][0])
print("ORIG:\n"+outs["orig"][1][:500]); print("JAC:\n"+outs["jac"][1][:500])
