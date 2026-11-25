import { startApp } from "@jac/runtime";
import * as $entry from "./web.jsx";
const $p0 = () => import("./pages/index.jsx");
startApp({ routes: [{ path: "/", load: $p0, params: [], rest: "" }], layout: undefined, entry: $entry, base: "/" });
