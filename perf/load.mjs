// node load.mjs '<json spec>' total conc  ; spec: {url, method, headers, body}
import http from 'node:http';
const [specS, total=500, conc=1] = process.argv.slice(2);
const spec = JSON.parse(specS);
const agent = new http.Agent({keepAlive:true, maxSockets:Number(conc)});
const u = new URL(spec.url); let sent=0; const lat=[]; let errs=0; let last='';
const body = spec.body;
const headers = Object.assign({}, spec.headers||{}); if(body!==undefined) headers['content-length']=Buffer.byteLength(body);
let k=Math.floor(Math.random()*16000000); function one(){ return new Promise(res=>{ const t=process.hrtime.bigint(); if(spec.xff){k++; headers['x-forwarded-for']=`10.${(k>>16)&255}.${(k>>8)&255}.${k&255}`; headers['x-real-ip']=headers['x-forwarded-for'];}
  const opts={host:u.hostname,port:u.port,path:u.pathname+u.search,method:spec.method||'GET',agent,headers}; if(spec.xff){opts.agent=false; opts.localAddress=`127.${(k>>16)&255}.${(k>>8)&255}.${(k&255)||1}`;} const r=http.request(opts, resp=>{
    const ch=[]; resp.on('data',c=>ch.push(c)); resp.on('end',()=>{ if(resp.statusCode!==200) errs++; last=Buffer.concat(ch).toString(); lat.push(Number(process.hrtime.bigint()-t)/1e6); res();});});
  r.on('error',()=>{errs++;res();}); if(body!==undefined) r.write(body); r.end();});}
async function worker(){ while(sent<Number(total)){ sent++; await one(); } }
for(let i=0;i<10;i++) await one(); lat.length=0;
const t0=performance.now(); await Promise.all(Array.from({length:Number(conc)},worker)); const dt=(performance.now()-t0)/1000;
lat.sort((a,b)=>a-b);
process.stdout.write(JSON.stringify({rps:Number(total)/dt, p50:lat[lat.length>>1], p99:lat[Math.floor(lat.length*.99)], errs, body:last})+'\n', ()=>process.exit(0));
