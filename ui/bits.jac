def:pub Panel(children: any, className: str = "") -> JsxElement {
    return <section className={"rounded-xl border border-line bg-card p-4 " + className}>{children}</section>;
}
