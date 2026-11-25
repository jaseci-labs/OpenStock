// rt/js.jac's names on a JS host, where a JavaScript value is the program's
// own: JavaScript's null, what a handler caught as JavaScript threw it, and
// JavaScript's own operations, which js_gen writes in place where it calls
// them (js_truthy, js_item, js_lt, js_add, ...; js_set_item as core.js's
// js_store, which gives JavaScript's object JavaScript's face of a Jac function).

import { call, Coroutine, fn_kind, held_at, js_agen, js_args, js_called, js_fn, js_got, js_store, own_array, params_length, plain, run, this_call, with_length } from "../core.js";

// JavaScript's null; None is undefined.
export const JsNull = null;

// What JavaScript threw that `e` is: what the host made a Jac exception of
// (core.js's caught), or `e` itself when JavaScript did not throw it.
export function js_error(e) {
    return e !== null && typeof e === "object" && "js" in e ? e.js : e;
}

export const js_truthy = (x) => !!x;
export const js_item = js_got;
export const js_set_item = js_store;
export const js_lt = (a, b) => a < b;
export const js_le = (a, b) => a <= b;
export const js_gt = (a, b) => a > b;
export const js_ge = (a, b) => a >= b;
export const js_add = (a, b) => a + b;
export const js_sub = (a, b) => a - b;
export const js_mul = (a, b) => a * b;
export const js_div = (a, b) => a / b;
export const js_pow = (a, b) => a ** b;
export const js_mod = (a, b) => a % b;
export const js_shl = (a, b) => a << b;
export const js_shr = (a, b) => a >> b;
export const js_ushr = (a, b) => a >>> b;
export const js_band = (a, b) => a & b;
export const js_bor = (a, b) => a | b;
export const js_bxor = (a, b) => a ^ b;
export const js_inc = (x) => ++x;
export const js_dec = (x) => --x;
export const js_number = (x) => +x;
export const js_same = (a, b) => a === b;
export const js_method = (o, k, ...a) => js_called(o, k, a);
// A function called on no object, as JavaScript calls it: a Jac function
// through its JavaScript face (js_fn's), which binds the arguments as
// JavaScript binds them (a `self` that is `this` gets undefined there), any
// other function as it is, a Jac class by Jac's call.
export function js_invoke(f, a) {
    if (typeof f === "function" && Object.hasOwn(f, "$js")) return f(...a);
    if (typeof f === "function" && f.$p !== undefined && !f.$cls) return js_fn(f)(...a);
    return call(f, a);
}
export const js_typeof = (x) => typeof x;
// Written in place as `import.meta`, the calling module's; a call of it as a
// value has no module to give.
// A function's prototype as JavaScript constructs with it: a Jac function's
// is its JavaScript face's (js_fn, one face for each function).
export function js_prototype(f) { return js_fn(f).prototype; }
// An object literal's method of `key`, made of `f`, which takes the object
// as its first argument: JavaScript's `this` is that argument, a coroutine
// the call makes is run, its name is the key's, and JavaScript cannot
// construct it, as it cannot an object literal's method (`new o.m()` is a
// TypeError). A generator function's is a generator method.
const GeneratorFunction = Object.getPrototypeOf(function* () {});
export function js_as_method(f, key) {
    const o = fn_kind(f) === GeneratorFunction
        ? { *[key](...a) { return yield* f.apply(undefined, js_args(f, [this, ...a])); } }
        : { [key](...a) { return this_call(f, this, a, undefined); } };
    const w = o[key];
    w.$js = true;
    // (Its `length` is the method's: the parameters after the object, or
    // what js_with_length gave.)
    return with_length(w, f.$len !== undefined ? f.$len : f.$p !== undefined ? params_length(f.$p, 1) : Math.max(0, f.length - 1));
}
// What JavaScript's `await x` waits for: of a Jac coroutine its promise, run
// at once to its first wait; of anything else Promise.resolve's.
export const js_promise = (x) => (x instanceof Coroutine ? run(x) : Promise.resolve(x));
// `f` with JavaScript's `length` n, which js_as_method keeps.
export function js_with_length(f, n) { f.$len = n; return with_length(f, n); }
// JavaScript's async generator of a Jac async generator (core.js's js_agen).
export const js_async_generator = js_agen;
export function js_global(k) { if (!(k in globalThis)) throw new ReferenceError(k + " is not defined"); return globalThis[k]; }
export function js_new_target() { throw new TypeError("js_new_target is new.target of the function that calls it, and is called by its name"); }
export function js_meta() { throw new TypeError("js_meta is import.meta of the module that calls it, and is called by its name"); }
export const js_iter = (x) => x[Symbol.iterator]();
export function* js_for_in(o) { for (const k in o) yield k; }
// The rest of an object pattern: o's own enumerable properties but `keys`,
// each defined on the new object as a value (so a key "__proto__" too).
export function js_rest(o, keys) {
    if (o === null || o === undefined) throw new TypeError("Cannot destructure " + o + " as it is " + o + ".");
    const from = Object(o), r = {};
    for (const k of Reflect.ownKeys(from)) {
        if (keys.includes(k)) continue;
        const d = Reflect.getOwnPropertyDescriptor(from, k);
        if (d !== undefined && d.enumerable) Object.defineProperty(r, k, { value: from[k], writable: true, enumerable: true, configurable: true });
    }
    return r;
}
export const js_delete = (o, k) => delete held_at(o)[k];
// JavaScript's own array, its items as JavaScript is given them: it crosses
// to JavaScript as itself.
export const js_array = (xs) => own_array(xs.map(plain));
// An array pattern's items, as JavaScript iterates the value for it.
export function js_unpack(o, n, rest) {
    if (o === null || o === undefined) throw new TypeError(o + " is not iterable");
    const it = o[Symbol.iterator](), out = [];
    let done = false;
    for (let i = 0; i < n; i++) {
        const r = done ? undefined : it.next();
        done = done || !!r.done;
        out.push(done ? undefined : r.value);
    }
    if (rest) {
        const more = [];
        while (!done) {
            const r = it.next();
            done = !!r.done;
            if (!done) more.push(r.value);
        }
        out.push(more);
    } else if (!done && typeof it.return === "function") it.return();
    return out;
}
