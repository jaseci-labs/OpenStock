import * as $j from "@jac/runtime/core";
export function Panel($props) {
    let children = $props["children"];
    let className = $props["className"];
    if (className === undefined) className = "";
    return <section className={("rounded-xl border border-line bg-card p-4 " + className)}>{children}</section>;
}
export function $make() {}
export function $run() {}
$make();
$run();
//# debugId=0278e641-5dc0-a3e5-a361-05f5247c985e
//# sourceMappingURL=bits.jsx.map
