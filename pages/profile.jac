"""The signed-in user's account: what they told us at sign-up, and how they get in."""
import from "@jac/runtime" { RemoteError }
import from "lucide-react" { Bell, KeyRound, ShieldCheck, Star }

# The profile's fields in the form's order, each with what an account without one starts from
glob FIELDS: dict[str, str] = {
    "name": "",
    "country": "US",
    "investmentGoals": "Growth",
    "riskTolerance": "Medium",
    "preferredIndustry": "Technology",
};

def kept -> list[str] {
    return [me().get(k) or FIELDS[k] for k in FIELDS];
}

def:pub page -> JsxPage {
    has form: list[str] = kept();
    has tried: bool = False;
    has busy: bool = False;
    has watching: int = 0;
    has active: int = 0;
    has realtime: bool = False;

    user = me();
    email = user.get("email", "");
    dirty = "|".join(form) != "|".join(kept());
    short = len(form[0].strip()) < 2;
    put = lambda (i: int, v: str) { form = form[:i] + [v] + form[i + 1:]; };

    async can with entry {
        try {
            watching = len(await get_watchlist());
            active = len([a for a in await get_alerts() if not a.triggered]);
            realtime = await is_realtime();
        } except RemoteError {}
    }

    async def save(e: any) {
        e.preventDefault();
        tried = True;
        if short {
            return;
        }
        busy = True;
        refused = "profileSaveFailed";
        try {
            refused = await update_profile(form[0], form[1], form[2], form[3], form[4]);
            if refused == "" {
                await load_user();
            }
        } except RemoteError {}
        busy = False;
        if refused {
            toast_error(t("ProfileForm.saveFailed"), t(f"Errors.{refused}"));
        } else {
            toast_ok(t("ProfileForm.saved"));
        }
    }

    # The accounts plugin changes a password only through its mailed link, so that is what this asks for
    async def reset {
        busy = True;
        refused = await auth_post("forgot", {"name": email});
        busy = False;
        if refused {
            toast_error(t("ForgotPassword.unavailable"), refused);
        } else {
            toast_ok(t("ForgotPassword.sent"));
        }
    }

    stats = [
        ["statWatching", watching, Star],
        ["statActiveAlerts" if realtime else "statPausedAlerts", active, Bell],
        ["statSignInMethods", 1, ShieldCheck],
    ];
    return <>
        <section className="hatch">
            <div className="card flex flex-wrap items-center gap-4 p-5">
                <span
                    className="grid size-14 flex-none place-items-center rounded-full bg-brand-soft text-[22px] font-bold text-brand-ink"
                >{user.get("name", "")[:1].upper() or "?"}</span>
                <div className="min-w-0 flex-1">
                    <h1
                        dir="auto"
                        className="truncate text-[22px] font-bold tracking-[-0.03em] rtl:text-right"
                    >{user.get("name", "")}</h1>
                    <p className="truncate text-faint">{email}</p>
                </div>
            </div>
            <div className="bento mt-[3px]">
                {[
                    <div key={s[0]} className="bento-tile col-span-4 gap-2.5 max-lg:col-span-12">
                        <div className="bento-head">
                            <span className="bento-ico"><@{s[2]} /></span>
                            {t(f"ProfilePage.{s[0]}")}
                        </div>
                        <p className="bento-value text-[26px]">{s[1]}</p>
                    </div>
                    for s in stats
                ]}
            </div>
        </section>
        <div className="grid items-start gap-3 xl:grid-cols-[minmax(0,1fr)_minmax(320px,420px)]">
            <Panel title={t("ProfilePage.detailsTitle")} sub={t("ProfilePage.detailsSub")}>
                <form onSubmit={save} noValidate className="flex flex-col gap-5 p-4">
                    <Field
                        name="name"
                        label={t("ProfileForm.nameLabel")}
                        placeholder={t("ProfileForm.namePlaceholder")}
                        value={form[0]}
                        onInput={lambda (v: str) { put(0, v); }}
                        error={t("ProfileForm.nameMinLength" if form[0].strip() else "ProfileForm.nameRequired") if tried and short else ""}
                    />
                    <CountrySelect
                        label={t("PreferenceFields.country")}
                        value={form[1]}
                        onPick={lambda (v: str) { put(1, v); }}
                    />
                    <ChoiceChips
                        group="investmentGoals"
                        label={t("PreferenceFields.investmentGoal")}
                        value={form[2]}
                        onPick={lambda (v: str) { put(2, v); }}
                    />
                    <ChoiceChips
                        group="riskTolerance"
                        label={t("PreferenceFields.riskTolerance")}
                        value={form[3]}
                        onPick={lambda (v: str) { put(3, v); }}
                    />
                    <ChoiceChips
                        group="industries"
                        label={t("PreferenceFields.preferredIndustry")}
                        value={form[4]}
                        onPick={lambda (v: str) { put(4, v); }}
                    />
                    <div className="flex items-center gap-3 pt-1">
                        <SubmitButton
                            busy={busy or not dirty}
                            label={t("ProfileForm.submit")}
                            busyLabel={t("ProfileForm.submitting" if busy else "ProfileForm.submit")}
                            className="btn btn-primary"
                        />
                        {None
                            if dirty
                            else <span className="text-[13px] text-faint">
                                {t("ProfileForm.upToDate")}
                            </span>}
                    </div>
                </form>
            </Panel>
            <div className="flex min-w-0 flex-col gap-3">
                <Panel
                    title={t("ProfilePage.signInMethodsTitle")}
                    sub={t("ProfilePage.signInMethodsSub")}
                >
                    <ul className="row-list">
                        <li className="flex items-center gap-3 px-3.5 py-3">
                            <span className="bento-ico"><KeyRound /></span>
                            <span className="flex-1 font-semibold">
                                {t("ProfilePage.methodCredential")
                                    if email
                                    else user.get("name", "")}
                            </span>
                            <span className="pill is-up">{t("ProfilePage.connected")}</span>
                        </li>
                    </ul>
                </Panel>
                {<Panel title={t("ProfilePage.passwordTitle")} sub={email}>
                    <div className="p-4">
                        <button
                            type="button"
                            onClick={reset}
                            disabled={busy}
                            className="btn btn-ghost"
                        >{t("ForgotPassword.submit")}</button>
                    </div>
                </Panel>
                    if email
                    else None}
            </div>
        </div>
    </>;
}
