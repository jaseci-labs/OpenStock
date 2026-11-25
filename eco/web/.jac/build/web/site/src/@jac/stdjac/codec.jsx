import * as $j from "@jac/runtime/core";
function $face0($r) { return function (v) { return $r(this, arguments, new.target, [], undefined); }; }
export var CodecError;
export function decode_complex(v) {
    let items, parts, i, x, $s5, e, $1, $2, $4;
    if (!$j.isa(v, 7)) {
        throw $j.cause(new CodecError().$init("", undefined, undefined, undefined, undefined, [], undefined, undefined, ("expected a list, got " + ($j.repr(v) ?? "None")), "", []), undefined);
    }
    items = $j.as_(v, ["l", 0]);
    if (((items).length !== 2)) {
        throw $j.cause(new CodecError().$init("", undefined, undefined, undefined, undefined, [], undefined, undefined, ("expected 2 items, got " + $j.str((items).length)), "", []), undefined);
    }
    parts = [];
    for ($1 of $j.enumerate(items, 0)) {
        $2 = $j.unpack($1, 2);
        i = $2[0];
        x = $2[1];
        try {
            void (parts).push(decode$2517(x));
        } catch ($4$) {
            $4 = $j.caught($4$);
            if (($4 instanceof CodecError)) {
                $s5 = $4;
                e = $4;
                throw $j.cause(new CodecError().$init("", undefined, undefined, undefined, undefined, [], undefined, undefined, (e).detail, ("[" + $j.str(i) + "]" + ((e).path ?? "None")), []), undefined);
            } else throw $4;
        }
    }
    return $j.rt_complex_parts($j.at(parts, 0), $j.at(parts, 1), true);
}
export function decode$2517(v) {
    return decode_sent$2521(v);
}
export function decode_sent$2521(v) {
    if ($j.isa(v, 3)) {
        return $j.as_(v, "f");
    }
    if (($j.isa(v, 2) && !$j.isa(v, 6))) {
        return $j.float(v);
    }
    throw $j.cause(new CodecError().$init("", undefined, undefined, undefined, undefined, [], undefined, undefined, ("expected a float, got " + ($j.repr(v) ?? "None")), "", []), undefined);
}
export function encode$2523(v) {
    return encode_sent$2525(v);
}
export function decode$2524(v) {
    return decode_sent$2526(v);
}
export function encode_sent$2525(v) {
    if ((v === undefined)) {
        return undefined;
    }
    return v;
}
export function decode_sent$2526(v) {
    if ((v === undefined)) {
        return undefined;
    }
    if ($j.isa(v, 4)) {
        return $j.as_(v, "s");
    }
    throw $j.cause(new CodecError().$init("", undefined, undefined, undefined, undefined, [], undefined, undefined, ("expected a str, got " + ($j.repr(v) ?? "None")), "", []), undefined);
}
export function $make() {
    decode_complex.$p = ["v"]; decode_complex.$face = $face0; $j.lengthed(decode_complex);
    CodecError = class CodecError extends $j.Exception {
        static $name = "CodecError";
        static $key = "CodecError";
        static $fields = [["message", 0, 1], ["__cause__", 0, 1], ["args", 0, 1], ["_neojac_py", 0, 1], ["_neojac_js", 0, 1], ["_neojac_tb", 0, 1], ["_neojac_made", 0, 1], ["_neojac_notes", 0, 1], ["detail", 0], ["path", 0, 1]];
        init($0, $1, $2, $3, $4, $5, $6, $7, $8, $9) {
            if (arguments.length < 1 || $0 === $j.NA) $0 = "";
            this.message = $0;
            if (arguments.length < 2 || $1 === $j.NA) $1 = undefined;
            this.__cause__ = $1;
            if (arguments.length < 3 || $2 === $j.NA) $2 = undefined;
            this.args = $2;
            if (arguments.length < 4 || $3 === $j.NA) $3 = undefined;
            this._neojac_py = $3;
            if (arguments.length < 5 || $4 === $j.NA) $4 = undefined;
            this._neojac_js = $4;
            if (arguments.length < 6 || $5 === $j.NA) $5 = [];
            this._neojac_tb = $5;
            if (arguments.length < 7 || $6 === $j.NA) $6 = undefined;
            this._neojac_made = $6;
            if (arguments.length < 8 || $7 === $j.NA) $7 = undefined;
            this._neojac_notes = $7;
            this.detail = $8;
            if (arguments.length < 10 || $9 === $j.NA) $9 = "";
            this.path = $9;
        }
        static $ctor = ["message=", "__cause__=", "args=", "_neojac_py=", "_neojac_js=", "_neojac_tb=", "_neojac_made=", "_neojac_notes=", "detail", "path="];
        __str__() {
            const self = this;
            return (((self).path !== "") ? (((self).path ?? "None") + ": " + ((self).detail ?? "None")) : (self).detail);
        }
    };
    CodecError.prototype.__str__.$p = []; CodecError.prototype.__str__.$q = "CodecError.__str__"; $j.lengthed(CodecError.prototype.__str__);
    $j.register(CodecError, "CodecError");
}
export function $run() {}
$make();
$run();
//# debugId=78b40498-b87e-7729-58c9-8985fb53dd73
//# sourceMappingURL=codec.jsx.map
