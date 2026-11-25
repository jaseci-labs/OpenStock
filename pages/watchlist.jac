"""The watchlist: starred symbols with their prices, named lists, alerts and news."""
import from "@jac/runtime" { Link, RemoteError, navigate, useLocation }
import from "lucide-react" {
    ArrowUpRight,
    Bell,
    BellRing,
    Newspaper,
    Plus,
    Search,
    Star,
    Trash2,
    X,
}

glob SUGGESTIONS: list[str] = ["AAPL", "NVDA", "MSFT", "TSLA", "AMZN"],
     NAME: str = "block max-w-40 truncate font-semibold rtl:text-right @min-[900px]:max-w-56 text-foreground group-hover:text-brand-ink transition-colors",
     PILL_STATUS: dict[str, str] = {"triggered": "pill is-brand", "watching": "pill is-up"},
     LOGO: str = "logo-well @max-[560px]:hidden",
     SYMBOL: str = "mono block truncate text-[12px] text-faint",
     DIM: str = "is-num text-muted-foreground",
     STORY: str = "group flex items-start gap-3 px-3 py-3 transition-colors hover:bg-hover/50",
     HEADLINE: str = "line-clamp-2 font-semibold text-foreground group-hover:text-brand-ink transition-colors rtl:text-right",
     OPEN_ICON: str = "mt-1 size-4 flex-none text-faint opacity-0 transition-opacity group-hover:opacity-100",
     DAY: dict[str, str] = {"month": "short", "day": "numeric"},
     SUGGESTION: str = "pill mono h-7 px-3 hover:bg-hover hover:text-foreground",
     TABLE: str = "data-table @max-[560px]:table-fixed @max-[560px]:[&_td]:px-2 @max-[560px]:[&_th]:px-2",
     ACTIONS: str = "flex items-center justify-end gap-1";

def Skeleton -> JsxElement {
    return <div className="row-list" aria-busy="true">
        {[
            <div key={i} className="flex items-center gap-3 px-3.5 py-3.5">
                <span className="size-8 animate-pulse rounded-full bg-hover" />
                <span className="h-3.5 flex-1 animate-pulse rounded-md bg-hover" />
                <span className="h-3.5 w-20 animate-pulse rounded-md bg-hover" />
            </div>
            for i in range(4)
        ]}
    </div>;
}

def Company(r: WatchlistRow) -> JsxElement {
    logo = <img src={r.logo} alt="" className="size-full object-contain p-1" />;
    return <Link to={f"/stocks/{r.symbol}"} className="group flex items-center gap-3">
        <span className={cx(LOGO, not r.logo and "is-empty")}>
            {logo if r.logo else r.symbol[0]}
        </span>
        <span className="min-w-0">
            <span dir="auto" className={NAME} title={r.name}>{r.name}</span>
            <span className={SYMBOL}>{r.symbol}</span>
        </span>
    </Link>;
}

# The starred table and a named list's: the same rows, each with the `actions` its table gives it. Columns
# drop by the card's width, not the viewport's, so the table fits wherever it sits; in a phone-width card the
# layout is fixed (`narrow` is the actions column there), the name truncates and the % pill sits under the price.
def StockTable(
    rows: list[WatchlistRow], actions: Callable[[WatchlistRow], any], narrow: str
) -> JsxElement {
    heads = [
        ["@max-[560px]:truncate", "WatchlistTable.headers.company"],
        ["is-num @max-[560px]:w-[112px]", "WatchlistTable.headers.price"],
        ["is-num @max-[560px]:hidden", "WatchlistTableRow.today"],
        ["is-num @max-[740px]:hidden", "WatchlistTable.headers.change"],
        ["is-num @max-[660px]:hidden", "WatchlistTable.headers.marketCap"],
    ];
    return <div className="@container overflow-x-auto rounded-[14px]">
        <table className={TABLE}>
            <thead>
                <tr>
                    {[<th key={h[1]} className={h[0]}>{t(h[1])}</th> for h in heads]}
                    <th className={cx("w-[88px]", narrow)}>
                        <span className="sr-only">{t("WatchlistTable.headers.action")}</span>
                    </th>
                </tr>
            </thead>
            <tbody>
                {
                    for r in rows {
                        pill = <ChangePill value={r.change_percent if r.price else None} />;
                        <tr key={r.symbol}>
                            <td className="max-w-[320px]"><Company {r} /></td>
                            <td className="is-num font-semibold text-foreground">
                                <PriceFlash value={r.price} className="px-1">
                                    {money(r.price, r.currency) if r.price else "—"}
                                </PriceFlash>
                                <div className="mt-1 @min-[560px]:hidden">{pill}</div>
                            </td>
                            <td className="is-num @max-[560px]:hidden">{pill}</td>
                            <td className={cx(DIM, "@max-[740px]:hidden")}>
                                {signed(r.change) if r.price else "—"}
                            </td>
                            <td className={cx(DIM, "@max-[660px]:hidden")}>
                                {compact(r.market_cap) if r.market_cap else "—"}
                            </td>
                            <td><div className={ACTIONS}>{actions(r)}</div></td>
                        </tr>
                    }
                }
            </tbody>
        </table>
    </div>;
}

def Alerts(
    alerts: list[AlertInfo], realtime: bool, onRemove: Callable[[AlertInfo], any]
) -> JsxElement {
    if not alerts {
        return <Empty
            icon={BellRing}
            className="py-10"
            title={t("AlertsPanel.emptyTitle" if realtime else "AlertsPanel.cloudTitle")}
            body={t("AlertsPanel.emptyBody" if realtime else "AlertsPanel.cloudBody")}
            width={"max-w-60 text-[13px]" if realtime else "max-w-64 text-[13px]"}
        >
            {None
                if realtime
                else <Link to="/#data" className="btn btn-ghost mt-2">
                    {t("AlertsPanel.seeCloud")}
                </Link>}
        </Empty>;
    }
    now = Date.now() / 1000;
    link = lambda (chunk: str) -> any {
        <Link key="link" to="/#data" className="text-brand-ink hover:underline">{chunk}</Link>
    };
    return <>
        {None
            if realtime
            else <p className="px-3 pt-3 pb-1 text-[12.5px] text-faint">
                {rich("AlertsPanel.movedNotice", {"link": link})}
            </p>}
        <ul className="row-list">
            {
                for a in alerts {
                    live = "expired"
                        if 0 < a.expires_at < now
                        else "watching" if a.active else "paused";
                    status = "triggered" if a.triggered else live if realtime else "paused";
                    said = {"period": a.sma_period, "price": money(a.target_price)};
                    rule = ("above" if a.condition == "ABOVE" else "below")
                        + ("Sma" if a.target == "SMA" else "");
                    date = new(Date, a.expires_at * 1000).toLocaleDateString(locale(), DAY);
                    until = " · " + t("AlertsPanel.until", {"date": date})
                        if a.expires_at and not a.triggered
                        else "";
                    <li key={a.id} className="flex items-center gap-3 px-3 py-2.5">
                        <div className="min-w-0 flex-1">
                            <p className="mono font-semibold text-foreground">{a.symbol}</p>
                            <p className="num truncate text-[12.5px] text-faint">
                                {t(f"AlertsPanel.{rule}", said) + until}
                            </p>
                        </div>
                        <span className={PILL_STATUS.get(status, "pill")}>
                            {t(f"AlertsPanel.status.{status}")}
                        </span>
                        <button
                            type="button"
                            onClick={lambda -> any { onRemove(a) }}
                            className="icon-btn is-danger"
                            title={t("AlertsPanel.removeTitle")}
                            aria-label={t("AlertsPanel.removeLabel", {"symbol": a.symbol})}
                        ><Trash2 /></button>
                    </li>
                }
            }
        </ul>
    </>;
}

def News(news: list[Article]) -> JsxElement {
    if not news {
        return <Empty
            icon={Newspaper}
            title={t("NewsList.emptyTitle")}
            body={t("NewsList.emptyBody")}
        />;
    }
    return <ul className="row-list">
        {[
            <li key={f"{n.id}-{n.url}"}>
                <a href={n.url} target="_blank" rel="noopener noreferrer" className={STORY}>
                    <span className="pill mono mt-0.5 w-16 justify-center">
                        {n.related or "MKT"}
                    </span>
                    <span className="min-w-0 flex-1">
                        <span dir="auto" className={HEADLINE}>{n.headline}</span>
                        <span className="mt-1 block truncate text-[12.5px] text-faint">
                            {n.source + (f" · {ago(n.datetime)}" if n.datetime else "")}
                        </span>
                    </span>
                    <ArrowUpRight className={OPEN_ICON} />
                </a>
            </li>
            for n in news
        ]}
    </ul>;
}

# The empty starred table: a way to search, and a few symbols to start from
def NoStars -> JsxElement {
    return <Empty
        icon={Star}
        width="max-w-sm"
        title={t("WatchlistTableRow.emptyTitle")}
        body={t("WatchlistTableRow.emptyBody")}
    >
        <button type="button" onClick={open_search} className="btn btn-primary mt-3"><Search /> {t(
            "WatchlistTableRow.searchStocks"
        )}</button>
        <div className="mt-4 flex flex-wrap justify-center gap-1.5">
            {[
                <Link key={s} to={f"/stocks/{s}"} className={SUGGESTION}>{s}</Link>
                for s in SUGGESTIONS
            ]}
        </div>
    </Empty>;
}

# The account's own data shows first; everything from Finnhub arrives behind skeletons and dashes
def:pub page -> JsxPage {
    has ready: bool = False;
    has items: list[WatchItem] = [];
    has lists: list[ListSummary] = [];
    has alerts: list[AlertInfo] = [];
    has data: dict[str, WatchlistRow] = {};
    has news: list[Article] | None = None;
    has name: str = "";
    has busy: bool = False;
    has on_change: Ref[any] = Ref(None);

    # The selection lives in the URL, so a list is linkable
    list_id = new(URLSearchParams, useLocation().search).get("list") or "";
    chosen = [l for l in lists if l.id == list_id];
    active = chosen[0] if chosen else None;
    starred = ",".join([i.symbol for i in items]);
    wanted = ",".join(sorted({i.symbol for i in items + (active.symbols if active else [])}));
    live = use_live(starred.split(",") if starred else []);

    async def load {
        try {
            items = await get_watchlist();
            lists = await get_lists();
            alerts = await get_alerts();
        } except RemoteError {}
        ready = True;
    }

    async can with entry {
        on_change.current = lambda -> any { load() };
        window.addEventListener("watchlistchange", on_change.current);
        await load();
    }

    can with exit {
        window.removeEventListener("watchlistchange", on_change.current);
    }

    async can with [wanted] entry {
        if wanted {
            try {
                data = {r.symbol: r for r in await get_watchlist_data(wanted.split(","))};
            } except RemoteError {}
        }
    }

    async can with [starred, ready] entry {
        if ready {
            symbols = starred.split(",") if starred else [];
            (company, market) = (t("NewsSources.companyNews"), t("NewsSources.marketNews"));
            news = await quiet(get_news(symbols, company, market), []);
        }
    }

    # The quote feed has no name for every exchange (it falls back to the ticker), so the company kept when
    # the symbol was added is the better label then; a live quote replaces the price it was loaded with
    def row(w: WatchItem) -> WatchlistRow {
        r = data.get(w.symbol) or WatchlistRow(w.symbol, 0.0, 0.0, 0.0, "USD", w.symbol);
        q = live.quotes.get(w.symbol) or Quote();
        return WatchlistRow(
            w.symbol,
            q.price or r.price,
            q.change if q.price else r.change,
            q.change_percent if q.price else r.change_percent,
            r.currency,
            r.name if r.name != r.symbol else w.company or r.name,
            r.logo,
            r.market_cap,
        );
    }

    # One write to a list or the alerts: says `done` or why not, and everything shown is read again
    async def write(saving: any, failed: str, done: str = "", name: str = "") -> Saved | None {
        busy = True;
        refused = failed;
        saved: Saved | None = None;
        try {
            saved = await saving or Saved();
            refused = problem(saved.error, name);
        } except RemoteError {}
        busy = False;
        if refused {
            toast_error(refused);
            return None;
        }
        if done {
            toast_ok(done);
        }
        changed();
        return saved;
    }

    async def create(e: any) {
        e.preventDefault();
        saved = await write(create_list(name), t("NamedLists.createFailed"), name=name.strip());
        if saved and saved.made {
            name = "";
            navigate(f"/watchlist?list={saved.made.id}");
        }
    }

    async def remove_list(l: ListSummary) {
        if window.confirm(t("NamedLists.deleteConfirm", {"list": l.name}))
            and await write(delete_list(l.id), t("NamedLists.deleteFailed"))
        {
            navigate("/watchlist");
        }
    }

    if not ready {
        return <Loading />;
    }
    shown = t("WatchlistPage.symbolCount", {"count": len(items)});
    fresh = <DataFreshness loc={locale()} realtime={live.realtime} />;
    pending = len([a for a in alerts if not a.triggered]);
    return <>
        <header className="page-head">
            <div>
                <h1 className="page-title">{t("WatchlistPage.title")}</h1>
                <p className="page-sub num flex flex-wrap items-center gap-x-2">{shown} <span
                    aria-hidden
                >·</span> {fresh}</p>
            </div>
            <button type="button" onClick={open_search} className="btn btn-primary"><Plus /> {t(
                "WatchlistPage.addSymbol"
            )}</button>
        </header>
        <Panel
            title={t("WatchlistPage.listsTitle")}
            sub={t("WatchlistPage.listsSub")}
            className="mb-3"
            action={<button type="button" className="btn btn-ghost" title={t("NamedLists.addStockTo", {"list": active.name})} onClick={lambda { open_search_for_list(active.id, active.name); }}><Plus /> {t("NamedLists.addStock")}</button> if active else None}
        >
            <div className="flex flex-wrap items-center gap-1.5 px-1 pb-1">
                <Link to="/watchlist" className={cx("pill h-8", not active and "is-up")}><Star
                    className="size-3.5"
                /> {t("NamedLists.starred")} <span className="num">· {len(items)}</span></Link>
                {[
                    <Link
                        key={l.id}
                        to={f"/watchlist?list={l.id}"}
                        className={cx("pill h-8 max-w-full", l.id == list_id and "is-up")}
                    ><span dir="auto" className="truncate">{l.name}</span> <span className="num">
                        · {l.count}</span></Link>
                    for l in lists
                ]}
                {<button
                    type="button"
                    onClick={lambda -> any { remove_list(active) }}
                    disabled={busy}
                    className="pill h-8 is-danger"
                    title={t("NamedLists.deleteTitle", {"list": active.name})}
                ><Trash2 className="size-3.5" /> {t("NamedLists.delete")}</button>
                    if active
                    else None}
                <form onSubmit={create} className="flex items-center gap-1.5">
                    <input
                        value={name}
                        onInput={lambda (e: any) { name = e.target.value; }}
                        placeholder={t("NamedLists.newListName")}
                        aria-label={t("NamedLists.newListName")}
                        className={cx("h-8 w-40", NAME_INPUT)}
                    />
                    <button
                        type="submit"
                        disabled={busy or not name.strip()}
                        className="pill h-8"
                        title={t("NamedLists.createTitle")}
                    ><Plus className="size-3.5" /> {t("NamedLists.create")}</button>
                </form>
            </div>
            {None
                if not active
                else <Empty
                    icon={Star}
                    className="py-12"
                    width="max-w-sm"
                    title={t("NamedLists.emptyTitle", {"list": active.name})}
                    body={t("NamedLists.emptyBody")}
                />
                    if not active.symbols
                    else <StockTable
                        rows={[row(w) for w in active.symbols]}
                        narrow="@max-[560px]:w-12"
                        actions={lambda (r: WatchlistRow) -> any { <button type="button" disabled={busy} className="icon-btn is-danger" title={t("NamedLists.removeFrom", {"symbol": r.symbol, "list": active.name})} aria-label={t("NamedLists.removeFrom", {"symbol": r.symbol, "list": active.name})} onClick={lambda -> any { write(remove_from_list(active.id, r.symbol), t("NamedLists.removeFailed"), t("NamedLists.removedFrom", {"symbol": r.symbol, "list": active.name})) }}><X /></button> }}
                    />}
        </Panel>
        <div className="grid gap-3 xl:grid-cols-[minmax(0,1fr)_minmax(300px,360px)]">
            <div className="flex min-w-0 flex-col gap-3">
                <Panel title={t("WatchlistPage.symbolsTitle")} sub={t("WatchlistPage.symbolsSub")}>
                    {<StockTable
                        rows={[row(w) for w in items]}
                        narrow="@max-[560px]:w-[120px]"
                        actions={lambda (r: WatchlistRow) -> any { <><ListButton symbol={r.symbol} company={r.name} />{<AlertButton symbol={r.symbol} price={r.price} currency={r.currency} realtime={live.realtime} className="icon-btn" title={t("WatchlistTableRow.setAlertLabel", {"symbol": r.symbol})} aria-label={t("WatchlistTableRow.setAlertLabel", {"symbol": r.symbol})}><Bell /></AlertButton> if has_finnhub_quotes(r.symbol) else <span className="icon-btn opacity-40" title={t("WatchlistTableRow.alertsUnavailable")}><Bell /></span>}<WatchButton symbol={r.symbol} company={r.name} on icon /></> }}
                    />
                        if items
                        else <NoStars />}
                </Panel>
                <Panel
                    title={t("WatchlistPage.newsTitle")}
                    sub={t("WatchlistPage.newsSubWatched" if items else "WatchlistPage.newsSubGeneral")}
                >{<Skeleton /> if news is None else <News {news} />}</Panel>
            </div>
            <Panel
                title={t("WatchlistPage.alertsTitle")}
                className="self-start"
                sub={t("WatchlistPage.alertsSubActive", {"count": pending}) if live.realtime else t("WatchlistPage.alertsSubCloud")}
            >
                <Alerts
                    {alerts}
                    realtime={live.realtime}
                    onRemove={lambda (a: AlertInfo) -> any { write(delete_alert(a.id), t("AlertsPanel.removeFailed"), t("AlertsPanel.removed", {"symbol": a.symbol})) }}
                />
            </Panel>
        </div>
    </>;
}
