#!/bin/bash
# serve.sh orig|jac port  -> starts the server in background, prints pid
BASE=/home/jayanaka/neojac-deslop/base/OpenStock
JAC=/home/jayanaka/neojac-deslop/repos/Open-Dev-Society_OpenStock
export BETTER_AUTH_SECRET=0123456789abcdef0123456789abcdef BETTER_AUTH_URL=https://openstock.example MONGODB_URI=mongodb://127.0.0.1:27117/openstock_bench NEXT_TELEMETRY_DISABLED=1 NODE_ENV=production
if [ "$1" = orig ]; then cd $BASE; nohup node_modules/.bin/next start -p $2 > /tmp/osbench/orig.log 2>&1 &
elif [ "$1" = before ]; then cd $JAC; mkdir -p /tmp/osbench/jacdata_before; JAC_WEB_LISTEN=127.0.0.1:$2 JAC_WEB_DATA=/tmp/osbench/jacdata_before nohup /tmp/osbench/before/web > /tmp/osbench/before.log 2>&1 &
else cd $JAC; mkdir -p /tmp/osbench/jacdata; JAC_WEB_LISTEN=127.0.0.1:$2 JAC_WEB_DATA=/tmp/osbench/jacdata nohup dist/web-linux-x86_64/web > /tmp/osbench/jac.log 2>&1 & fi
echo $!
