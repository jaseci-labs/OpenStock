import from "@jac/runtime" { Link, navigate }

def:pub page -> JsxPage {
    has email: str = "";
    has password: str = "";
    has tried: bool = False;
    has busy: bool = False;

    async def submit(e: any) {
        e.preventDefault();
        tried = True;
        if email_problem(email) or password == "" {
            return;
        }
        busy = True;
        # The plugin signs in by username or by email
        problem = await auth_post(
            "login", {"username": email.strip().lower(), "password": password}
        );
        busy = False;
        if problem {
            toast_error(t("SignIn.failed"), problem);
        } else {
            navigate("/dashboard");
        }
    }

    return <>
        <AuthHead ns="SignIn" />
        <SocialButtons />
        <form onSubmit={submit} noValidate className="space-y-5">
            <EmailField value={email} onInput={lambda (v: str) { email = v; }} {tried} />
            <Field
                name="password"
                kind="password"
                label={t("SignIn.passwordLabel")}
                placeholder={t("SignIn.passwordPlaceholder")}
                value={password}
                onInput={lambda (v: str) { password = v; }}
                error={t("Password.required") if tried and password == "" else ""}
            />
            <div className="flex justify-end">
                <Link to="/forgot-password" className="footer-link text-sm">
                    {t("SignIn.forgotPassword")}
                </Link>
            </div>
            <AuthEnd {busy} ns="SignIn" text="noAccount" link="createAccount" href="/sign-up" />
        </form>
    </>;
}
