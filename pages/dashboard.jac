"""The markets overview. Widgets come from TradingView (live, no Finnhub quota); the tiles are our own quotes."""
import from "@jac/runtime" { Link, __getLocalStorage, __setLocalStorage }
import from "lucide-react" { ArrowDownRight, ArrowUpRight }

glob TD: str = "num px-3 py-2 text-end",
     ROW: str = "border-t border-line/60 transition-colors hover:bg-hover/40",
     MOVER: str = "flex items-center gap-3 rounded-[10px] px-3 py-2 transition-colors hover:bg-hover/60",
     HEADS: list[list[str]] = [
         ["px-3 py-2 font-medium", "WatchlistTable.headers.company"],
         ["px-3 py-2 font-medium text-end", "WatchlistTable.headers.price"],
         ["px-3 py-2 font-medium text-end max-sm:hidden", "WatchlistTable.headers.change"],
         ["px-3 py-2 font-medium text-end", "YahooQuotes.changePercent"],
     ];

def stock_path(tv_symbol: str) -> str {
    return f"/stocks/{yahoo_app_symbol(tv_symbol)}";
}

def QuoteRow(s: tuple[str, str], q: DailyQuote | None) -> JsxElement {
    code = yahoo_app_symbol(s[0]);
    change = ("+" if q.change > 0 else "") + grouped(q.change) if q else "—";
    tone = "text-down" if q and q.change < 0 else "text-up";
    return <tr className={ROW}>
        <td className="px-3 py-2">
            <Link to={stock_path(s[0])} className="font-semibold hover:text-brand-ink">{s[1]} <span
                className="mono text-[11px] text-faint"
            >{code}</span></Link>
        </td>
        <td className={cx(TD, "font-semibold")}>{grouped(q.price) if q else "—"}</td>
        <td className={cx(TD, "max-sm:hidden", tone)}>{change}</td>
        <td className="px-3 py-2 text-end">
            <ChangePill value={q.change_percent if q else None} />
        </td>
    </tr>;
}

# Our own quotes table for Yahoo-priced markets: TradingView's market-quotes widget shows no TADAWUL
# values in free embeds, and only end-of-day GPW values
def YahooQuotes(market: Market, daily: dict[str, DailyQuote]) -> JsxElement {
    currency = [q.currency for q in daily.values()][:1];
    return <div className="overflow-x-auto">
        <table className="w-full text-[13px]">
            <thead>
                <tr className="text-start text-faint">
                    {[<th key={h[1]} className={h[0]}>{t(h[1])}</th> for h in HEADS]}
                </tr>
            </thead>
            {[
                <tbody key={g.title}>
                    <tr>
                        <td colSpan={4} className="kicker px-3 pt-3 pb-1">
                            {t(f"Markets.groups.{message_key(g.title)}")}
                        </td>
                    </tr>
                    {
                        for s in g.symbols {
                            <QuoteRow key={s[0]} {s} q={daily.get(s[0])} />
                        }
                    }
                </tbody>
                for g in market.groups
            ]}
        </table>
        <p className="px-3 py-2 text-[11.5px] text-faint">
            {t("YahooQuotes.source", {"currency": currency[0]})
                if currency
                else t("YahooQuotes.sourceNoCurrency")}
        </p>
    </div>;
}

# Today's biggest movers across the same groups, ranked by day change %
def YahooMovers(market: Market, daily: dict[str, DailyQuote]) -> JsxElement {
    names = {s[0]: s[1] for g in market.groups for s in g.symbols};
    ranked = sorted(
        [s for s in names if s in daily],
        key=lambda (s: str) -> float { -abs(daily[s].change_percent) },
    )[:8];
    if not ranked {
        return <p className="search-list-indicator">{t("YahooQuotes.unavailable")}</p>;
    }
    top = max(0.01, abs(daily[ranked[0]].change_percent));
    return <ul className="flex flex-col gap-1 p-1">
        {
            for s in ranked {
                move = daily[s].change_percent;
                up = move >= 0;
                <li key={s}>
                    <Link to={stock_path(s)} className={MOVER}>
                        <span className={"text-up" if up else "text-down"}>
                            {<ArrowUpRight className="size-4" />
                                if up
                                else <ArrowDownRight className="size-4" />}
                        </span>
                        <span className="min-w-0 flex-1">
                            <span
                                dir="auto"
                                className="block truncate text-[13.5px] font-semibold rtl:text-right"
                            >{names[s]}</span>
                            <span className="mono block text-[11.5px] text-faint">
                                {s.split(":")[-1]}
                            </span>
                        </span>
                        <span className="relative h-1.5 w-20 overflow-hidden rounded-full bg-hover">
                            <span
                                className={cx("absolute inset-y-0 rounded-full", "left-0 bg-up" if up else "right-0 bg-down")}
                                style={{"width": f"{abs(move) / top * 100}%"}}
                            />
                        </span>
                        <ChangePill value={move} />
                    </Link>
                </li>
            }
        }
    </ul>;
}

# A full-height TradingView widget in the user's language
def Wide(widget: str, extra: dict[str, any] = {}, expand: bool = False) -> JsxElement {
    loc = locale();
    config = widget_config(widget, loc, extra);
    return <TradingView {widget} {config} height={560} {expand} {loc} />;
}

def:pub page -> JsxPage {
    has all: list[Market] = [];
    has open_ids: list[str] = [];
    has id: str = "";
    has realtime: bool = False;
    has daily: dict[str, DailyQuote] = {};

    loc = locale();
    found = [m for m in all if m.id == id] or all[:1];

    # An explicit ?market=, then the remembered one, then the market of the user's country
    async can with entry {
        id = new(URLSearchParams, location.search).get("market")
            or __getLocalStorage("openstock-market")
            or await market_for_country(me().get("country", ""));
        all = await markets();
        open_ids = await open_markets();
        realtime = await is_realtime();
    }

    async can with [id, all] entry {
        daily = {};
        if found and found[0].yahoo {
            daily = await yahoo_daily_quotes(
                list({s[0] for g in found[0].groups for s in g.symbols})
            );
        }
    }

    def pick(to: str) {
        id = to;
        __setLocalStorage("openstock-market", to);
    }

    if not found {
        return <Loading />;
    }
    market = found[0];
    ids = [m.id for m in all];
    name = t(f"Markets.names.{market.id}");
    feed = message_key(market.feed);
    groups = [(t(f"Markets.groups.{message_key(g.title)}"), g.symbols) for g in market.groups];
    native = any([p.finnhub for p in market.pulse]);
    status = "open" if market.id in open_ids else "closed";
    pulse_sub = t("Dashboard.pulseSubFinnhub")
        if native
        else t("Dashboard.pulseSubYahoo")
            if market.yahoo
            else t("Dashboard.pulseSubTradingView", {"feed": feed});
    quoted = [
        {"name": g[0], "symbols": [{"name": s[0], "displayName": s[1]} for s in g[1]]}
        for g in groups
    ];
    tabs = [{"title": g[0], "symbols": [{"s": s[0], "d": s[1]} for s in g[1]]} for g in groups];
    heat = {"stocks": "stock-heatmap", "crypto": "crypto-coins-heatmap"}.get(market.heatmap, "");
    quotes_panel = <Panel
        title={t("Dashboard.quotesTitle")}
        sub={t("Dashboard.quotesSub", {"market": name})}
    >
        {<YahooQuotes {market} {daily} />
            if market.yahoo
            else <Wide widget="market-quotes" extra={{"symbolsGroups": quoted}} />}
    </Panel>;
    return <>
        <header className="page-head">
            <div>
                <h1 className="page-title">{t("Dashboard.title")}</h1>
                <p className="page-sub">
                    {t("Dashboard.sub", {"market": name, "status": status, "feed": feed})}
                </p>
            </div>
        </header>
        <MarketSwitcher markets={ids} active={market.id} openIds={open_ids} onPick={pick} />
        <section className="hatch">
            <div className="section-head">
                <div>
                    <h2 className="section-title">{t("Dashboard.pulseTitle")}</h2>
                    <p className="section-sub">{pulse_sub}</p>
                </div>
                {<DataFreshness {loc} {realtime} /> if native else None}
            </div>
            {#* Keyed so switching markets swaps the tiles instead of reusing old widgets *#}
            <IndexPulse key={market.id} {market} {realtime} {loc} />
        </section>
        <div key={market.id} className="flex flex-col gap-3">
            <div className="grid gap-3 xl:grid-cols-[minmax(0,1fr)_minmax(0,2fr)]">
                {<Panel title={t("Dashboard.moversTitle")} sub={t("Dashboard.moversSub")}>
                    <YahooMovers {market} {daily} />
                </Panel>
                    if market.yahoo
                    else <Panel title={t("Dashboard.leadersTitle")} sub={t("Dashboard.leadersSub")}>
                        <Wide widget="market-overview" extra={{"tabs": tabs}} />
                    </Panel>}
                {<Panel
                    title={t("Dashboard.stockHeatmapTitle" if market.heatmap == "stocks" else "Dashboard.cryptoHeatmapTitle")}
                    sub={t("Dashboard.heatmapSub")}
                ><Wide widget={heat} expand /></Panel>
                    if heat
                    else quotes_panel}
            </div>
            <div className="grid gap-3 xl:grid-cols-[minmax(0,2fr)_minmax(0,1fr)]">
                {quotes_panel if heat else None}
                <Panel
                    title={t("Dashboard.storiesTitle")}
                    sub={t("Dashboard.storiesSub")}
                    className={"" if heat else "xl:col-span-2"}
                ><Wide widget="timeline" extra={{"market": market.news}} /></Panel>
            </div>
        </div>
    </>;
}
