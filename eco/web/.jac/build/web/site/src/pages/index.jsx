import * as $j from "@jac/runtime/core";
import { useState as $state } from "react";
import { useEffect as $effect } from "react";
import * as $m0 from "../@jac/stdjac/crossing.jsx";
import * as $m1 from "../ui/bits.jsx";
function $face0($r) { return function () { return $r(this, arguments, new.target, [], undefined); }; }
export function page() {
    const [text, setText] = $state("...");
    $effect(() => { $j.run((function* () {
        setText((yield* $j.aw($m0.call_async_def$2518("api", "api.quotes", "ping", $j.dict_of([["symbol", $m0.sent$2519("AAPL")]])))));
    })()); }, []);
    return <$m1.Panel className={"m-6"}><h1 className={"text-2xl text-brand"}>{text}</h1></$m1.Panel>;
}
export function $make() {
    page.$p = []; page.$face = $face0; $j.lengthed(page);
}
export function $run() {}
$make();
$run();
//# debugId=d41a44c7-1064-d11a-afe3-6007c93f592d
//# sourceMappingURL=index.jsx.map
