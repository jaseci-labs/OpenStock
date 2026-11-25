"""Form parts shared by the auth pages and the profile page."""
import from "@jac/runtime" { Link }
import from "lucide-react" { Check, ChevronsUpDown, Github, Search, X }
import from "react-select-country-list" { default as countryList }

glob INPUT: str = "placeholder:text-muted-foreground dark:bg-input/30 border-input h-9 w-full min-w-0 rounded-md border bg-transparent px-3 py-1 text-base shadow-xs transition-[color,box-shadow] outline-none disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50 md:text-sm focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]",
     CHIP: str = "h-9 rounded-full px-3.5 text-[13.5px] font-semibold transition-[background-color,color,box-shadow,transform] duration-150 active:scale-[0.96]",
     CHIP_ON: str = "bg-brand-soft text-brand-ink shadow-[inset_0_0_0_1px_oklch(0.8_0.13_176/0.45)]",
     CHIP_OFF: str = "text-muted-foreground shadow-[inset_0_0_0_1px_var(--line)] hover:bg-hover hover:text-foreground",
     GOOGLE_PATHS: list[list[str]] = [
         [
             "#4285F4",
             "M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.27-4.74 3.27-8.1z",
         ],
         [
             "#34A853",
             "M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84A11 11 0 0 0 12 23z",
         ],
         ["#FBBC05", "M5.84 14.1a6.6 6.6 0 0 1 0-4.2V7.06H2.18a11 11 0 0 0 0 9.88l3.66-2.84z"],
         [
             "#EA4335",
             "M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15A10.96 10.96 0 0 0 12 1 11 11 0 0 0 2.18 7.06l3.66 2.84C6.71 7.31 9.14 5.38 12 5.38z",
         ],
     ];

def:pub Field(
    name: str,
    label: str,
    value: str,
    onInput: Callable[[str], None],
    kind: str = "text",
    placeholder: str = "",
    error: str = "",
    disabled: bool = False,
) -> JsxElement {
    return <div className="space-y-2">
        <label
            htmlFor={name}
            className="form-label flex items-center gap-2 leading-none select-none"
        >{label}</label>
        <input
            id={name}
            name={name}
            type={kind}
            {value}
            {placeholder}
            {disabled}
            aria-invalid={bool(error)}
            className={cx(INPUT, "form-input", disabled and "opacity-50 cursor-not-allowed")}
            onInput={lambda (e: any) { onInput(e.target.value); }}
        />
        {<p className="text-[13px] text-down">{error}</p> if error else None}
    </div>;
}

def:pub SubmitButton(
    busy: bool, label: str, busyLabel: str, className: str = "yellow-btn w-full"
) -> JsxElement {
    return <button
        type="submit"
        disabled={busy}
        className={cx("inline-flex items-center justify-center gap-2", className)}
    >{busyLabel if busy else label}</button>;
}

# Single-choice pills for one group of rules.PROFILE_OPTIONS: every choice is visible and one tap away
def:pub ChoiceChips(
    group: str, label: str, value: str, onPick: Callable[[str], None]
) -> JsxElement {
    return <div className="flex flex-col gap-2">
        <span id={f"{group}-label"} className="form-label">{label}</span>
        <div
            role="radiogroup"
            aria-labelledby={f"{group}-label"}
            className="flex flex-wrap gap-1.5"
        >
            {[
                <button
                    key={option}
                    type="button"
                    role="radio"
                    aria-checked={value == option}
                    onClick={lambda { onPick(option); }}
                    className={cx(CHIP, CHIP_ON if value == option else CHIP_OFF)}
                >{t(f"Options.{group}.{message_key(option)}")}</button>
                for option in PROFILE_OPTIONS[group]
            ]}
        </div>
    </div>;
}

def flag(code: str) -> str {
    return "".join([chr(127397 + ord(c)) for c in code.upper()]);
}

# [code, name] pairs. English keeps the library's names; other locales get the browser's own region names.
def countries(loc: str) -> list[list[str]] {
    listed = [
        [str(c.value), "Taiwan" if c.value == "TW" else str(c.label)]
        for c in countryList().getData()
    ];
    if loc == "en" {
        return listed;
    }
    names = new(Intl.DisplayNames, [loc], {"type": "region", "fallback": "none"});
    return sorted(
        [[c[0], str(names.of(c[0]) or c[1])] for c in listed],
        key=lambda (c: list[str]) -> str { c[1] },
    );
}

# A searchable country picker; `value` is the ISO code
def:pub CountrySelect(
    label: str, value: str, onPick: Callable[[str], None], error: str = ""
) -> JsxElement {
    has query: str = "";

    options = countries(locale());
    chosen = [c[1] for c in options if c[0] == value];
    shown = [c for c in options if query.lower() in f"{c[1]} {c[0]}".lower()];
    return <div className="space-y-2">
        <span className="form-label flex items-center gap-2 leading-none select-none">{label}</span>
        <Menu
            role="combobox"
            className="country-select-trigger inline-flex items-center gap-2 whitespace-nowrap border shadow-xs outline-none"
            panelClassName="w-full p-0 bg-gray-800 border-gray-600"
            trigger={<>{<span className="flex items-center gap-2"><span>{flag(value)}</span><span>{chosen[0]}</span></span> if chosen else t("CountrySelect.placeholder")}<ChevronsUpDown className="ms-2 h-4 w-4 shrink-0 opacity-50" /></>}
        >
            <div className="country-select-input flex h-9 items-center gap-2 px-3">
                <Search className="size-4 shrink-0 opacity-50" />
                <input
                    autoFocus
                    value={query}
                    placeholder={t("CountrySelect.searchPlaceholder")}
                    onInput={lambda (e: any) { query = e.target.value; }}
                    className="flex h-10 w-full bg-transparent py-3 text-sm outline-hidden placeholder:text-faint"
                />
            </div>
            <div className="scrollbar-hide-default max-h-60 overflow-y-auto p-1">
                {<p className="country-select-empty text-sm">{t("CountrySelect.empty")}</p>
                    if not shown
                    else None}
                {[
                    <button
                        key={c[0]}
                        type="button"
                        data-close=""
                        onClick={lambda {
                            onPick(c[0]);
                            query = "";
                        }}
                        className="country-select-item flex w-full items-center gap-2 text-start text-sm"
                    >
                        <Check
                            className={cx("me-2 h-4 w-4 text-teal-500", "opacity-100" if value == c[0] else "opacity-0")}
                        />
                        <span>{flag(c[0])}</span>
                        <span>{c[1]}</span>
                    </button>
                    for c in shown
                ]}
            </div>
        </Menu>
        {<p className="text-[13px] text-down">{error}</p> if error else None}
        <p className="text-[12.5px] text-faint">{t("CountrySelect.hint")}</p>
    </div>;
}

# The four password rules, ticked as the password comes to meet them
def:pub PasswordChecklist(password: str) -> JsxElement {
    return <ul className="grid grid-cols-2 gap-x-4 gap-y-1.5">
        {[
            <li key={rule} className="flex items-center gap-2 text-xs">
                {<span className="size-3.5 rounded-full border border-gray-500" />
                    if password == ""
                    else (
                        <Check className="size-3.5 text-green-500" />
                            if passed
                            else <X className="size-3.5 text-red-500" />
                    )}
                <span
                    className={cx("transition-colors", "text-gray-500" if password == "" else ("text-green-500" if passed else "text-red-500"))}
                >{t(f"Password.rules.{rule}")}</span>
            </li>
            for (rule, passed) in password_checks(password).items()
        ]}
    </ul>;
}

# The message for a password a form may not take, "" for one it may
def:pub password_problem(password: str) -> str {
    if password == "" {
        return t("Password.required");
    }
    if len(password) < 8 {
        return t("Password.minLength");
    }
    return "" if password_ok(password) else t("Password.pattern");
}

def:pub email_problem(email: str) -> str {
    if email.strip() == "" {
        return t("AuthFields.emailRequired");
    }
    return "" if valid_email(email.strip()) else t("AuthFields.emailInvalid");
}

def:pub FooterLink(text: str, linkText: str, href: str) -> JsxElement {
    return <div className="pt-4 text-center">
        <p className="text-sm text-gray-500">{text} <Link to={href} className="footer-link">
            {linkText}
        </Link></p>
    </div>;
}

def:pub Branding(className: str = "flex justify-center") -> JsxElement {
    return <div className={className}>
        <div
            className="inline-flex items-center gap-1 rounded-lg px-3 py-0.5 text-[1.17em] font-medium text-white shadow-[inset_0_0_0_1px_var(--line)]"
        >
            <span className="text-sm -tracking-tighter opacity-75">
                {t("OpenDevSocietyBranding.initiativeBy")}
            </span>
            <img src="/assets/icons/odsLogo.svg" alt="" width={40} height={40} />
            <span className="font-bold tracking-tight">Open Dev Society</span>
        </div>
    </div>;
}

# Google and GitHub buttons, only for the ones the accounts plugin offers (their keys are set)
def:pub SocialButtons -> JsxElement | None {
    has ways: list[any] = [];
    has pending: str = "";

    async can with entry {
        offered = (await auth_ways()).actions;
        ways = [a for name in ["google", "github"] for a in offered if a.name == name];
    }

    if not ways {
        return None;
    }
    return <div className="mb-5 space-y-5">
        <div className={"grid grid-cols-2 gap-3" if len(ways) > 1 else "grid gap-3"}>
            {[
                <button
                    key={way.name}
                    type="button"
                    disabled={pending != ""}
                    onClick={lambda {
                        pending = way.name;
                        social_sign_in(way);
                    }}
                    className="inline-flex h-12 cursor-pointer items-center justify-center gap-2 rounded-lg border border-gray-600 text-base font-medium text-gray-400 shadow-xs transition-all hover:bg-hover disabled:opacity-50 dark:bg-input/30"
                >
                    {<Github className="size-5" />
                        if way.name == "github"
                        else <svg viewBox="0 0 24 24" aria-hidden="true" className="size-5">
                            {[<path key={p[0]} fill={p[0]} d={p[1]} /> for p in GOOGLE_PATHS]}
                        </svg>}
                    {t("SocialAuth.redirecting")
                        if pending == way.name
                        else ("GitHub" if way.name == "github" else "Google")}
                </button>
                for way in ways
            ]}
        </div>
        <div className="flex items-center gap-3 text-sm text-gray-500">
            <span className="h-px flex-1 bg-gray-600" />
            {t("SocialAuth.or")}
            <span className="h-px flex-1 bg-gray-600" />
        </div>
    </div>;
}
