"""What the dashboard, watchlist and stock pages share: live quotes, the star, alerts and filing into lists."""
import from "@jac/runtime" { Link, RemoteError }
import from "lucide-react" { ListPlus, Plus, Star }

glob mode: str = "",  # the server's data mode, asked once a visit
     SPANS: list[tuple[int, str]] = [
         (31536000, "year"),
         (2592000, "month"),
         (604800, "week"),
         (86400, "day"),
         (3600, "hour"),
         (60, "minute"),
         (1, "second"),
     ],
     NAME_INPUT: str = "rounded-full bg-page px-3 text-[13px] shadow-[inset_0_0_0_1px_var(--line)] outline-none placeholder:text-faint focus-visible:ring-2 focus-visible:ring-ring disabled:opacity-60",
     SEGMENT: str = "min-h-9 whitespace-nowrap rounded-[9px] px-1 text-[12px] font-semibold transition-colors min-[400px]:text-[14px]",
     CLOUD: str = "btn btn-primary h-11 flex-1",
     PICKED: str = "bg-hover text-foreground shadow-[inset_0_1px_0_oklch(1_0_0/0.06)]",
     PRICE_BOX: str = "flex h-12 items-center gap-2 rounded-[11px] border border-line bg-page px-3 focus-within:border-brand",
     PRICE_INPUT: str = "num w-full bg-transparent text-lg font-semibold text-foreground outline-none",
     ALERT_FAILURES: dict[str, str] = {
         "notEnoughHistory": "smaNoHistory",
         "historyUnavailable": "smaHistoryUnavailable",
     };

obj Live {
    has quotes: dict[str, Quote],
        realtime: bool;
}

# Every write to the watchlist, a list or the alerts says so: the sidebar and the watchlist page read again
def:pub changed {
    window.dispatchEvent(new(Event, "watchlistchange"));
}

# The message of a Saved.error from the watchlist and the lists, "" for none
def:pub problem(code: str, name: str = "") -> str {
    caps = {"watchlistFull": MAX_WATCHLIST, "listLimit": MAX_LISTS, "listFull": MAX_LIST_SYMBOLS};
    return t(f"Errors.{code}", {"max": caps.get(code, 0), "name": name}) if code else "";
}

# What a call to the server gives, or `fallback` when it fails
async def:pub quiet(call: any, fallback: any = None) -> any {
    try {
        return await call;
    } except RemoteError {
        return fallback;
    }
}

# "3 hours ago" for a unix time, in the user's language
def:pub ago(at: float) -> str {
    past = at - Date.now() / 1000;
    (size, unit) = [s for s in SPANS if abs(past) >= s[0] or s[0] == 1][0];
    return new(Intl.RelativeTimeFormat, locale(), {"numeric": "auto"}).format(
        Math.round(past / size), unit
    );
}

# What a panel shows in place of nothing: an icon, a title, a line, and whatever follows them
def:pub Empty(
    icon: any, title: str, body: str, children: any = None, className: str = "", width: str = ""
) -> JsxElement {
    return <div className={cx("empty-state", className)}>
        <span className="empty-icon"><@icon className="size-5" /></span>
        <h3>{title}</h3>
        <p className={width}>{body}</p>
        {children}
    </div>;
}

# Our own quotes for the symbols on screen, by symbol. Read once when shown; in realtime mode read again
# every 15 s while the tab is visible and when it comes back. A read that fails or comes back empty (the
# rate limit) keeps the last good prices, and an answer for symbols no longer shown is dropped.
def:pub use_live(symbols: list[str]) -> Live {
    has found: dict[str, Quote] = {};
    has realtime: bool = False;
    has shown: Ref[str] = Ref("");
    has timer: Ref[any] = Ref(None);
    has on_show: Ref[any] = Ref(None);

    key = ",".join(symbols);

    async def read(first: bool = False) {
        if not first and document.visibilityState != "visible" {
            return;
        }
        answer = await quiet(quotes(symbols), {});
        if shown.current == key and answer {
            found = answer;
        }
    }

    async can with [key] entry {
        shown.current = key;
        if mode == "" {
            mode = await quiet(data_mode(), "");
        }
        realtime = mode == "realtime";
        if key == "" or shown.current != key {
            return;
        }
        await read(True);
        if poll_ms(mode) and shown.current == key {
            on_show.current = lambda { read() };
            timer.current = setInterval(on_show.current, poll_ms(mode));
            document.addEventListener("visibilitychange", on_show.current);
        }
    }

    can with [key] exit {
        shown.current = "";
        clearInterval(timer.current);
        document.removeEventListener("visibilitychange", on_show.current);
    }

    return Live(quotes=found, realtime=realtime);
}

# The star: on the watchlist or not. `icon` is the table's small form.
def:pub WatchButton(symbol: str, company: str, on: bool, icon: bool = False) -> JsxElement {
    has added: bool = on;
    has busy: bool = False;

    can with [on] entry {
        added = on;
    }

    said: dict[str, any] = {"symbol": symbol};

    async def toggle(e: any) {
        e.preventDefault();
        want = not added;
        added = want;
        busy = True;
        refused = "";
        try {
            if want {
                refused = problem((await add_to_watchlist(symbol, company)).error);
            } else {
                await remove_from_watchlist(symbol);
            }
        } except RemoteError {
            refused = t("WatchlistButton.updateFailed");
        }
        busy = False;
        if refused {
            added = not want;
            toast_error(refused);
        } else {
            toast_ok(t("WatchlistButton.added" if want else "WatchlistButton.removed", said));
            changed();
        }
    }

    label = t("WatchlistButton.removeLabel" if added else "WatchlistButton.addLabel", said);
    return <button
        type="button"
        onClick={toggle}
        disabled={busy}
        className={cx("icon-btn" if icon else "btn btn-ghost", added and "is-on")}
        title={label if icon else None}
        aria-label={label if icon else None}
        aria-pressed={added}
    >
        <Star fill={"currentColor" if added else "none"} />
        {None if icon else t("WatchlistButton.watching" if added else "WatchlistButton.watch")}
    </button>;
}

# A row of mutually exclusive choices, each [value, label]: toggle buttons, so Tab and Enter/Space work as
# announced (a radiogroup would also promise arrow-key navigation)
def Segmented(
    label: str, value: any, options: list[list[any]], onPick: Callable[[any], None]
) -> JsxElement {
    return <div
        className="grid gap-1 rounded-[12px] bg-page p-1"
        style={{"gridTemplateColumns": f"repeat({len(options)}, minmax(0, 1fr))"}}
        role="group"
        aria-label={label}
    >
        {[
            <button
                key={o[0]}
                type="button"
                aria-pressed={value == o[0]}
                onClick={lambda { onPick(o[0]); }}
                className={cx(SEGMENT, PICKED if value == o[0] else "text-faint hover:text-foreground")}
            >{o[1]}</button>
            for o in options
        ]}
    </div>;
}

# A button (its children and whatever else it is given) that opens the alert form for a symbol: a fixed
# price, or a cross of a moving average. Where alerts are off (cached mode) it explains where they are.
def:pub AlertButton(
    symbol: str,
    children: any,
    realtime: bool,
    price: float = 0.0,
    currency: str = "USD",
    **rest: any,
) -> JsxElement {
    has open: bool = False;
    has condition: str = "ABOVE";
    has kind: str = "PRICE";
    has period: int = 50;
    has target: str = "";
    has busy: bool = False;

    sma = kind == "SMA";
    goal = parseFloat(target);
    distance = (goal - price) / price * 100 if price > 0 and isFinite(goal) else None;
    met = distance is not None and (distance <= 0 if condition == "ABOVE" else distance >= 0);
    vars = {"symbol": symbol, "condition": condition, "period": period};
    now: dict[str, any] = {"price": money(price, currency), "distance": signed(distance or 0.0)};
    hint = "priceUnavailable"
        if price <= 0
        else "alreadyMet" if met else "now" if distance is None else "nowWithDistance";
    m = lambda (k: str) -> str { t("CreateAlertModal." + k) };
    kinds: list[list[any]] = [["PRICE", m("typePrice")], ["SMA", m("typeSma")]];
    sides: list[list[any]] = [
        ["ABOVE", m("crossesAbove" if sma else "risesAbove")],
        ["BELOW", m("crossesBelow" if sma else "fallsBelow")],
    ];
    periods = [[p, t("CreateAlertModal.smaOption", {"period": p})] for p in SMA_PERIODS];
    on_kind = lambda (v: any) { kind = v; };
    on_side = lambda (v: any) { condition = v; };
    on_period = lambda (v: any) { period = v; };

    async def submit(e: any) {
        e.preventDefault();
        busy = True;
        code = "failed";
        made: AlertInfo | None = None;
        try {
            saved = await create_alert(
                symbol, condition, 0.0 if sma else goal, kind, period if sma else 0
            );
            (code, made) = (saved.error, saved.alert);
        } except RemoteError {}
        busy = False;
        if code or made is None {
            toast_error(t("CreateAlertModal." + ALERT_FAILURES.get(code, "createFailed"), vars));
            return;
        }
        done = {**vars, "price": money(made.target_price, currency)};
        toast_ok(t("CreateAlertModal.createdSma" if sma else "CreateAlertModal.created", done));
        open = False;
        changed();
    }

    return <>
        <button
            type="button"
            onClick={lambda {
                target = f"{price:.2f}" if price > 0 else "";
                open = True;
            }}
            {...rest}
        >{children}</button>
        <Dialog
            {open}
            onClose={lambda { open = False; }}
            className="grid gap-5 p-6 sm:max-w-[420px]"
        >
            {<>
                <div>
                    <p className="kicker text-brand-ink">{m("kicker")}</p>
                    <h2 className="mono mt-1 text-xl font-bold tracking-tight">{symbol}</h2>
                    <p className="mt-1 text-[13px] text-faint">{m("description")}</p>
                </div>
                <form onSubmit={submit} className="flex flex-col gap-4">
                    <Segmented label={m("alertOn")} value={kind} options={kinds} onPick={on_kind} />
                    <Segmented
                        label={m("conditionLabel")}
                        value={condition}
                        options={sides}
                        onPick={on_side}
                    />
                    {<div className="flex flex-col gap-2">
                        <span className="form-label">{m("smaPeriodLabel")}</span>
                        <Segmented
                            label={m("smaPeriodLabel")}
                            value={period}
                            options={periods}
                            onPick={on_period}
                        />
                        <span className="text-[12.5px] text-faint">{m("smaHint")}</span>
                    </div>
                        if sma
                        else <label className="flex flex-col gap-2">
                            <span className="form-label">{m("targetPrice")}</span>
                            <span className={PRICE_BOX}>
                                <span className="mono text-faint">{currency}</span>
                                <input
                                    type="number"
                                    inputMode="decimal"
                                    step="0.01"
                                    min="0.01"
                                    required
                                    autoFocus
                                    value={target}
                                    onInput={lambda (e: any) { target = e.target.value; }}
                                    className={PRICE_INPUT}
                                />
                            </span>
                            <span
                                className={cx("num text-[12.5px]", "text-warn" if met else "text-faint")}
                            >{t(f"CreateAlertModal.{hint}", {**vars, **now})}</span>
                        </label>}
                    <button
                        type="submit"
                        disabled={busy or (not sma and not goal > 0)}
                        className="btn btn-primary h-11"
                    >{m("setting" if busy else "setAlert")}</button>
                </form>
            </>
                if realtime
                else <div>
                    {#* Alerts are an OpenStock Cloud feature; the free hourly site points people to it *#}
                    <p className="kicker text-brand-ink">OpenStock Cloud</p>
                    <h2 className="mt-1 text-xl font-bold tracking-tight">{m("cloudTitle")}</h2>
                    <p className="mt-2 text-[13.5px] leading-relaxed text-muted-foreground">
                        {m("cloudBody")}
                    </p>
                    <div className="mt-5 flex flex-wrap gap-2">
                        <Link to="/#data" className={CLOUD}>{m("seeCloud")}</Link>
                        <Link to="/#self-host" className="btn btn-ghost h-11">{m("selfHost")}</Link>
                    </div>
                </div>}
        </Dialog>
    </>;
}

# The per-stock control that files a symbol into one of the user's named lists, or makes the list right
# there so a first-time user is never stuck without one
def:pub ListButton(symbol: str, company: str) -> JsxElement {
    has open: bool = False;
    has lists: list[ListSummary] = [];
    has name: str = "";
    has busy: bool = False;
    # A list that was made but whose add failed is a real list: retrying reuses it, or the second
    # attempt would die on the duplicate-name check
    has made: ListSummary | None = None;

    async def show {
        (open, made, name) = (True, None, "");
        lists = await quiet(get_lists(), lists);
    }

    async def add(to: ListSummary, fresh: bool) {
        said: dict[str, any] = {"symbol": symbol, "list": to.name};
        busy = True;
        refused = t("NamedLists.addToFailed" if fresh else "NamedLists.addFailed", said);
        try {
            refused = problem((await add_to_list(to.id, symbol, company)).error);
        } except RemoteError {}
        busy = False;
        if refused {
            toast_error(refused);
            return;
        }
        toast_ok(t("NamedLists.createdAndAdded" if fresh else "NamedLists.addedTo", said));
        open = False;
        changed();
    }

    # Making the list and filing the symbol fail differently and are reported separately
    async def create(e: any) {
        e.preventDefault();
        to = made;
        if to is None {
            busy = True;
            refused = t("NamedLists.createFailed");
            try {
                saved = await create_list(name);
                (refused, to) = (problem(saved.error, name.strip()), saved.made);
            } except RemoteError {}
            busy = False;
            if refused or to is None {
                toast_error(refused);
                return;
            }
            made = to;
            changed();
        }
        await add(to, True);
    }

    title = t("NamedLists.menuTitle", {"symbol": symbol});
    label = t("NamedLists.menuLabel", {"symbol": symbol});
    return <>
        <button type="button" className="icon-btn" onClick={show} {title} aria-label={label}>
            <ListPlus />
        </button>
        {#* Not dismissible while a request is in flight: closing would forget a list about to exist *#}
        <Dialog
            {open}
            onClose={lambda { open = open and busy; }}
            className="grid gap-4 p-6 sm:max-w-sm"
        >
            <h2 className="text-lg leading-none font-semibold">{title}</h2>
            {<p className="text-[12px] text-faint">{t("NamedLists.menuEmpty")}</p>
                if not lists
                else <div className="flex flex-wrap gap-1.5">
                    {[
                        <button
                            key={l.id}
                            type="button"
                            disabled={busy}
                            onClick={lambda { add(l, False) }}
                            className="pill h-8 max-w-full"
                        ><Star className="size-3.5" /> <span dir="auto" className="truncate">
                            {l.name}
                        </span></button>
                        for l in lists
                    ]}
                </div>}
            <form onSubmit={create} className="flex flex-col gap-3 border-t border-line pt-4">
                <span className="form-label">{t("NamedLists.newListTitle")}</span>
                <input
                    value={made.name if made else name}
                    onInput={lambda (e: any) { name = e.target.value; }}
                    placeholder={t("NamedLists.listName")}
                    aria-label={t("NamedLists.listName")}
                    disabled={made is not None}
                    className={cx("h-9", NAME_INPUT)}
                />
                {<p className="text-[12px] text-muted-foreground">
                    {t("NamedLists.retryHint", {"list": made.name, "symbol": symbol})}
                </p>
                    if made
                    else None}
                <button
                    type="submit"
                    disabled={busy or (made is None and not name.strip())}
                    className="btn btn-primary self-end"
                ><Plus className="size-3.5" /> {t(
                    "NamedLists.retryAdd" if made else "NamedLists.createAndAdd"
                )}</button>
            </form>
        </Dialog>
    </>;
}
