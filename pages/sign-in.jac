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
        <h1 className="form-title mb-2">{t("SignIn.title")}</h1>
        <p className="mb-8 text-faint">{t("SignIn.subtitle")}</p>
        <SocialButtons />
        <form onSubmit={submit} noValidate className="space-y-5">
            <Field
                name="email"
                label={t("AuthFields.email")}
                placeholder="opendevsociety@cc.cc"
                value={email}
                onInput={lambda (v: str) { email = v; }}
                error={email_problem(email) if tried else ""}
            />
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
            <SubmitButton
                {busy}
                label={t("SignIn.submit")}
                busyLabel={t("SignIn.submitting")}
                className="yellow-btn mt-5 w-full"
            />
            <FooterLink
                text={t("SignIn.noAccount")}
                linkText={t("SignIn.createAccount")}
                href="/sign-up"
            />
            <Branding className="mt-10 flex justify-center" />
        </form>
    </>;
}
