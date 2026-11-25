def:pub page -> JsxPage {
    has text: str = "...";

    async can with entry {
        text = await ping("AAPL");
    }

    return <Panel className="m-6"><h1 className="text-2xl text-brand">{text}</h1></Panel>;
}
