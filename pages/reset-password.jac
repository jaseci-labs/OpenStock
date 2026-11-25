import from "@jac/runtime" { navigate }

# The link's token: in the fragment, as the accounts plugin mails it, or ?token= as the old links had it
def link_token -> str {
    return location.hash[1:] or new(URLSearchParams, location.search).get("token") or "";
}

def:pub page -> JsxPage {
    has password: str = "";
    has confirm: str = "";
    has tried: bool = False;
    has busy: bool = False;

    can with entry {
        if link_token() == "" {
            toast_error(t("ResetPassword.invalidLink"));
        }
    }

    def confirm_problem -> str {
        if confirm == "" {
            return t("ResetPassword.confirmRequired");
        }
        return "" if confirm == password else t("ResetPassword.mismatch");
    }

    # Setting the password signs the caller in and ends the account's other sessions
    async def submit(e: any) {
        e.preventDefault();
        tried = True;
        if password_problem(password) or confirm_problem() {
            return;
        }
        if link_token() == "" {
            toast_error(t("ResetPassword.invalidLink"));
            return;
        }
        busy = True;
        problem = await auth_post("reset", {"token": link_token(), "password": password});
        busy = False;
        if problem {
            toast_error(t("ResetPassword.failed"), t("Errors.resetLinkInvalid"));
        } else {
            toast_ok(t("ResetPassword.updated"));
            navigate("/dashboard");
        }
    }

    return <>
        <h1 className="form-title">{t("ResetPassword.title")}</h1>
        <p className="mb-6 text-sm text-gray-400">{t("ResetPassword.subtitle")}</p>
        <form onSubmit={submit} noValidate className="space-y-5">
            <Field
                name="newPassword"
                kind="password"
                label={t("ResetPassword.newPasswordLabel")}
                placeholder={t("ResetPassword.newPasswordPlaceholder")}
                value={password}
                onInput={lambda (v: str) { password = v; }}
                error={password_problem(password) if tried else ""}
            />
            <PasswordChecklist {password} />
            <Field
                name="confirmPassword"
                kind="password"
                label={t("ResetPassword.confirmPasswordLabel")}
                placeholder={t("ResetPassword.confirmPasswordPlaceholder")}
                value={confirm}
                onInput={lambda (v: str) { confirm = v; }}
                error={confirm_problem() if tried else ""}
            />
            <SubmitButton
                {busy}
                label={t("ResetPassword.submit")}
                busyLabel={t("ResetPassword.submitting")}
                className="yellow-btn mt-5 w-full"
            />
            <FooterLink
                text={t("ResetPassword.needFreshLink")}
                linkText={t("ResetPassword.requestAnother")}
                href="/forgot-password"
            />
            <Branding className="mt-10 flex justify-center" />
        </form>
    </>;
}
