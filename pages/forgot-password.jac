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
        <h1 className="form-title">{t("ForgotPassword.title")}</h1>
        <p className="mb-6 text-sm text-gray-400">{t("ForgotPassword.subtitle")}</p>
        <form onSubmit={submit} noValidate className="space-y-5">
            <Field
                name="email"
                label={t("AuthFields.email")}
                placeholder="opendevsociety@cc.cc"
                value={email}
                onInput={lambda (v: str) { email = v; }}
                error={email_problem(email) if tried else ""}
            />
            <SubmitButton
                {busy}
                label={t("ForgotPassword.submit")}
                busyLabel={t("ForgotPassword.submitting")}
                className="yellow-btn mt-5 w-full"
            />
            <FooterLink
                text={t("ForgotPassword.remembered")}
                linkText={t("ForgotPassword.signIn")}
                href="/sign-in"
            />
            <Branding className="mt-10 flex justify-center" />
        </form>
    </>;
}
