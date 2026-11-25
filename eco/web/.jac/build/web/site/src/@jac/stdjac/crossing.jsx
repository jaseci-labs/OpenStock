import * as $j from "@jac/runtime/core";
import { post } from "@jac/runtime/core";
import { post_stream } from "@jac/runtime/core";
import { decode_failed } from "@jac/runtime/core";
import { file_from } from "@jac/runtime/core";
import { file_send } from "@jac/runtime/core";
function $face0($r) { return function (v, was) { return $r(this, arguments, new.target, [], undefined); }; }
function $face1($r) { return async function (space, module, name, args) { return $r(this, arguments, new.target, [], undefined); }; }
import * as $m0 from "./codec.jsx";
export var _leaving;
export function $set__leaving($v) { _leaving = $v; }
export function carries(v, was) {
    let held, x, items, $2, $3, $4, $5;
    if ((v === was)) {
        return true;
    }
    if ($j.isa(v, 8)) {
        held = $j.as_(v, ["d", "s", 0]);
        $L1: {
            $3 = held; $4 = $3.size;
            for ($2 of $3.values()) {
                if ($3.size !== $4) $j.resized($3);
                x = $2;
                if (carries(x, was)) {
                    return true;
                }
            }
            if ($3.size !== $4) $j.resized($3);
        }
    } else if ($j.isa(v, 7)) {
        items = $j.as_(v, ["l", 0]);
        for ($5 of items) {
            x = $5;
            if (carries(x, was)) {
                return true;
            }
        }
    }
    return false;
}
export function leave(space, module, name, args) {
    return $j.coro((function* () {
        let going, rest, pair, f, was, $6, $7, $8;
        if (((_leaving).length === 0)) {
            return;
        }
        going = [];
        rest = [];
        for ($6 of _leaving) {
            pair = $6;
            if (carries(args, (pair)[1])) {
                void (going).push(pair);
            } else {
                void (rest).push(pair);
            }
        }
        $j.list_clear(_leaving);
        $j.list_extend(_leaving, rest);
        for ($7 of going) {
            $8 = $j.unpack($7, 2);
            f = $8[0];
            was = $8[1];
            if (((f).id === "")) {
                (yield* $j.aw(file_send(f, space, name, ((space ?? "None") + "/" + (module ?? "None") + "/" + (name ?? "None")))));
            }
            (was).set("id", (f).id);
            (was).set("size", (f).size);
            (was).set("ctype", (f).ctype);
        }
    })(), "leave");
}
export function call_async_proc(space, module, name, args) {
    return $j.coro((function* () {
        (yield* $j.aw(leave(space, module, name, args)));
        (yield* $j.aw(post(space, name, ("/__jac/call/" + (space ?? "None") + "/" + (module ?? "None") + "/" + (name ?? "None")), ({"args": $j.plain(args)}))));
    })(), "call_async_proc");
}
export function call_async_def$2518(space, module, name, args) {
    return $j.coro((function* () {
        let data;
        (yield* $j.aw(leave(space, module, name, args)));
        data = (yield* $j.aw(post(space, name, ("/__jac/call/" + (space ?? "None") + "/" + (module ?? "None") + "/" + (name ?? "None")), ({"args": $j.plain(args)}))));
        return take$2522(space, ((module + ".") + name), data);
    })(), "call_async_def");
}
export function sent$2519(v) {
    let out;
    out = $m0.encode$2523(v);
    return out;
}
export function take$2522(space, endpoint, data) {
    let out, $s4, e, $10;
    try {
        out = $m0.decode$2524(data);
        return out;
    } catch ($10$) {
        $10 = $j.caught($10$);
        if (($10 instanceof $m0.CodecError)) {
            $s4 = $10;
            e = $10;
            decode_failed(space, endpoint, $j.str(e));
            throw $j.cause(e, undefined);
        } else throw $10;
    }
}
export function $make() {
    carries.$p = ["v", "was"]; carries.$face = $face0; $j.lengthed(carries);
    leave.$p = ["space", "module", "name", "args"]; leave.$async = 1; leave.$face = $face1; $j.lengthed(leave);
    call_async_proc.$p = ["space", "module", "name", "args"]; call_async_proc.$async = 1; call_async_proc.$face = $face1; $j.lengthed(call_async_proc);
}
export function $run() {
    _leaving = [];
}
$make();
$run();
//# debugId=d531383a-ab3f-0949-cd96-e103d9ce3925
//# sourceMappingURL=crossing.jsx.map
