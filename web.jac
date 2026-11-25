import "./styles/globals.css";

def:pub app(children: any) -> JsxElement {
    return <div className="min-h-screen">{children}</div>;
}
