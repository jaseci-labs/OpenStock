import from "@jac/runtime" { navigate }

def:pub page -> JsxPage {
    has name: str = "";
    has email: str = "";
    has password: str = "";
    has country: str = "IN";
    has goal: str = "Growth";
    has risk: str = "Medium";
    has industry: str = "Technology";
    has tried: bool = False;
    has busy: bool = False;

    # The plugin makes the account; the rest of the form is saved on the new caller's own root
    async def submit(e: any) {
        e.preventDefault();
        tried = True;
        if len(name.strip()) < 2
            or email_problem(email)
            or password_problem(password)
            or country == ""
        {
            return;
        }
        busy = True;
        address = email.strip().lower();
        problem = await auth_post(
            "register", {"username": username_for(address), "email": address, "password": password}
        );
        if problem == "" {
            refused = await save_profile(name, address, country, goal, risk, industry, locale());
            problem = t(f"Errors.{refused}") if refused else "";
        }
        busy = False;
        if problem {
            toast_error(t("SignUp.failed"), problem);
        } else {
            navigate("/dashboard");
        }
    }

    return <>
        <AuthHead ns="SignUp" />
        <SocialButtons />
        <form onSubmit={submit} noValidate className="flex flex-col gap-8">
            <section className="flex flex-col gap-4" aria-label={t("SignUp.accountSection")}>
                <Field
                    name="fullName"
                    label={t("SignUp.fullNameLabel")}
                    placeholder={t("SignUp.fullNamePlaceholder")}
                    value={name}
                    onInput={lambda (v: str) { name = v; }}
                    error={t("SignUp.fullNameRequired") if tried and len(name.strip()) < 2 else ""}
                />
                <EmailField
                    value={email}
                    onInput={lambda (v: str) { email = v; }}
                    {tried}
                    placeholder="you@example.com"
                />
                <div className="flex flex-col gap-2">
                    <Field
                        name="password"
                        kind="password"
                        label={t("SignUp.passwordLabel")}
                        placeholder={t("SignUp.passwordPlaceholder")}
                        value={password}
                        onInput={lambda (v: str) { password = v; }}
                        error={password_problem(password) if tried else ""}
                    />
                    <PasswordChecklist {password} />
                </div>
            </section>
            <section
                className="flex flex-col gap-5 border-t border-line pt-6"
                aria-labelledby="personalize"
            >
                <div>
                    <p id="personalize" className="kicker text-brand-ink">
                        {t("SignUp.personalize")}
                    </p>
                    <p className="mt-1 text-[13px] text-faint">{t("SignUp.personalizeHint")}</p>
                </div>
                <CountrySelect
                    label={t("PreferenceFields.country")}
                    value={country}
                    onPick={lambda (v: str) { country = v; }}
                />
                <ChoiceChips
                    group="investmentGoals"
                    label={t("PreferenceFields.investmentGoal")}
                    value={goal}
                    onPick={lambda (v: str) { goal = v; }}
                />
                <ChoiceChips
                    group="riskTolerance"
                    label={t("PreferenceFields.riskTolerance")}
                    value={risk}
                    onPick={lambda (v: str) { risk = v; }}
                />
                <ChoiceChips
                    group="industries"
                    label={t("PreferenceFields.preferredIndustry")}
                    value={industry}
                    onPick={lambda (v: str) { industry = v; }}
                />
            </section>
            <div className="flex flex-col gap-4">
                <SubmitButton
                    {busy}
                    label={t("SignUp.submit")}
                    busyLabel={t("SignUp.submitting")}
                />
                <FooterLink
                    text={t("SignUp.haveAccount")}
                    linkText={t("SignUp.signIn")}
                    href="/sign-in"
                />
            </div>
            <Branding />
        </form>
    </>;
}
