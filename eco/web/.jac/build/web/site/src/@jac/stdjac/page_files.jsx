import * as $j from "@jac/runtime/core";
import { file_address } from "@jac/runtime/core";
import { file_bytes } from "@jac/runtime/core";
import { file_local } from "@jac/runtime/core";
export var OCTETS, File;
export function $set_OCTETS($v) { OCTETS = $v; }
export function $make() {
    File = class File extends $j.Obj {
        static $name = "File";
        static $key = "File";
        static $fields = [["id", 0, 1], ["size", 0, 1], ["ctype", 0, 1]];
        static $unhashable = true;
        __repr__() { return $j.obj_repr(this); }
        $init(...$a) {
            this.id = "";
            this.size = 0;
            this.ctype = OCTETS;
            this.init(...$a);
            return this;
        }
        init(source, ctype) {
            const self = this;
            if (arguments.length < 2 || ctype === $j.NA) ctype = "";
            file_local(self, $j.plain(source), ctype);
        }
        read() {
            const self = this;
            return $j.coro((function* () {
                let data;
                data = (yield* $j.aw(file_bytes(self)));
                return data;
            })(), "read");
        }
        url() {
            const self = this;
            let where;
            where = $j.as_(file_address(self), "s");
            return where;
        }
    };
    File.prototype.init.$p = ["source", "ctype="]; File.prototype.init.$q = "File.init"; $j.lengthed(File.prototype.init);
    File.prototype.read.$p = []; File.prototype.read.$q = "File.read"; File.prototype.read.$async = 1; $j.lengthed(File.prototype.read);
    File.prototype.url.$p = []; File.prototype.url.$q = "File.url"; $j.lengthed(File.prototype.url);
    $j.register(File, "File");
}
export function $run() {
    OCTETS = "application/octet-stream";
}
$make();
$run();
//# debugId=a15f5453-95a4-2fe0-c826-33f8be1527b1
//# sourceMappingURL=page_files.jsx.map
