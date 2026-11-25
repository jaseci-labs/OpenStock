def:pub page -> JsxPage {
    has email: str = "";
    has tried: bool = False;
    has busy: bool = False;

    # The plugin answers the same for an address with no account, so the page cannot tell who has one
    async def submit(e: any) {
        e.preventDefault();
        tried = True;
        if email_problem(email) {
            return;
        }
        busy = True;
        problem = await auth_post("forgot", {"name": email.strip().lower()});
        busy = False;
        if problem {
            toast_error(t("ForgotPassword.unavailable"), problem);
        } else {
            toast_ok(t("ForgotPassword.sent"));
        }
    }

    return <>
        <AuthHead ns="ForgotPassword" quiet />
        <form onSubmit={submit} noValidate className="space-y-5">
            <EmailField value={email} onInput={lambda (v: str) { email = v; }} {tried} />
            <AuthEnd {busy} ns="ForgotPassword" text="remembered" link="signIn" href="/sign-in" />
        </form>
    </>;
}
