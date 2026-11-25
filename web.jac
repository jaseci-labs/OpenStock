import "./styles/globals.css";

# A language switch shows every page again: the key remounts what is under it
def:pub app(children: any) -> JsxElement {
    has loc: str = locale();

    listen(window, ["localechange"], lambda { loc = locale(); });

    return <><div key={loc} className="contents">{children}</div><Toasts /></>;
}
