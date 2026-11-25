"""A stock: our header and price, TradingView's chart, financials, technicals and profile, then sentiment and news.
The charts come straight from TradingView (live, no quota); only the header and the cards wait on the server."""
import from "@jac/runtime" { RemoteError, __getLocalStorage, __setLocalStorage }
import from "lucide-react" {
    Bell,
    CalendarClock,
    CandlestickChart,
    Gauge,
    Landmark,
    MoveVertical,
    SlidersHorizontal,
}

# The free embed can't save indicators added inside it, so the ones picked here are kept per browser and
# passed in as `studies` on every chart. Each id was checked on a live advanced-chart embed.
glob INDICATORS: dict[str, str] = {
         "STD;SMA": "sma",
         "STD;EMA": "ema",
         "STD;Bollinger_Bands": "bollingerBands",
         "STD;VWAP": "vwap",
         "STD;RSI": "rsi",
         "STD;MACD": "macd",
         "STD;Stochastic": "stochastic",
         "STD;Average_True_Range": "atr",
     },
     STUDIES: str = "openstock:chart-indicators",
     TREND: dict[str, str] = {"rising": "is-up", "falling": "is-down"},
     ALIGNMENT: dict[str, str] = {
         "Bullish alignment": "text-up",
         "Bearish alignment": "text-down",
         "Wide divergence": "text-down",
         "Mixed": "text-warn",
     },
     MOOD: dict[str, str] = {"positive": "text-up", "negative": "text-down"},
     PULSE: str = "animate-pulse rounded-md bg-hover";

def saved_studies -> list[str] {
    try {
        saved = JSON.parse(__getLocalStorage(STUDIES) or "[]");
        return [id for id in INDICATORS if Array.isArray(saved) and saved.includes(id)];
    } except Exception {
        return [];
    }
}

def Chart(tv: str) -> JsxElement {
    has studies: list[str] = saved_studies();

    def toggle(id: str) {
        picked = [i for i in INDICATORS if (i in studies) != (i == id)];
        studies = picked;
        __setLocalStorage(STUDIES, JSON.stringify(picked));
    }

    return <Panel
        title={t("StockChart.title")}
        sub={t("StockChart.sub")}
        action={<Menu end className="btn btn-ghost h-8 px-2.5 text-[13px]" panelClassName="w-56" trigger={<><SlidersHorizontal /> {t("StockChart.indicatorsButton")}{<span className="num text-faint">{len(studies)}</span> if studies else None}</>}><p className="px-2 py-1.5 text-[12px] text-faint">{t("StockChart.keptNote")}</p>{[<MenuItem key={id} keepOpen checked={id in studies} onSelect={lambda { toggle(id); }}>{t(f"StockChart.indicators.{INDICATORS[id]}")}</MenuItem> for id in INDICATORS]}</Menu>}
    >
        <TradingView
            widget="advanced-chart"
            config={{**candle_chart(tv, locale()), "studies": studies}}
            height={560}
            expand
            loc={locale()}
        />
    </Panel>;
}

# Symbols Finnhub's free plan prices (US stocks, crypto) get our own header: company, live price, the day's
# numbers, alerts. The rest use TradingView's quote panel, except that TradingView blocks Tadawul quotes in
# embeds and has Warsaw only end of day: those show a delayed Yahoo price and skip the panel, which would show
# a second, older price. If Yahoo has no quote, Warsaw falls back to the panel; Tadawul's is blocked either way.
def Header(sym: str) -> JsxElement {
    has ready: bool = False;
    has watching: bool = False;
    has profile: Profile = Profile();
    has daily: DailyQuote | None = None;

    covered = has_finnhub_quotes(sym);
    yahoo = is_yahoo_symbol(sym);
    tv = tradingview_symbol(sym);
    live = use_live([sym] if covered else []);
    q = live.quotes.get(sym) or Quote();
    currency = profile.currency or "USD";
    company = profile.name or sym;
    cash = lambda (v: float) -> str { money(v, currency) if v else "—" };

    async can with entry {
        try {
            watching = await in_watchlist(sym);
            if covered {
                profile = await get_company_profile(sym) or Profile();
            } elif yahoo {
                daily = (await yahoo_daily_quotes([sym])).get(sym);
            }
        } except RemoteError {}
        ready = True;
    }

    if not ready {
        return <section className="hatch" aria-busy="true">
            <div className="card flex items-center gap-3 p-4">
                <span className="size-11 animate-pulse rounded-full bg-hover" />
                <span className="flex flex-col gap-2">
                    <span className={cx("h-5 w-48", PULSE)} />
                    <span className={cx("h-3 w-32", PULSE)} />
                </span>
                <span className={cx("ms-auto h-8 w-36", PULSE)} />
            </div>
        </section>;
    }
    star = <WatchButton symbol={sym} {company} on={watching} />;
    if not covered {
        return <section className="hatch">
            <div className="card flex flex-wrap items-center justify-between gap-4 p-4">
                <div className="min-w-0">
                    <h1 className="mono truncate text-xl font-bold tracking-[-0.02em]">{sym}</h1>
                    <p className="text-[12.5px] text-faint">
                        {" · ".join([
                            x
                            for x in [
                                tv.split(":")[0],
                                daily.name if daily else "",
                                t(
                                    "StockHeader.quoteViaYahoo"
                                        if yahoo
                                        else "StockHeader.quoteViaTradingView",
                                ),
                            ]
                            if x
                        ])}
                    </p>
                </div>
                {<div className="flex items-center gap-3">
                    <p className="num text-2xl font-bold tracking-[-0.03em]">
                        {money(daily.price, daily.currency)}
                    </p>
                    <ChangePill value={daily.change_percent} />
                </div>
                    if daily
                    else None}
                <div className="flex flex-wrap items-center gap-2">
                    {star}
                    <ListButton symbol={sym} {company} />
                    <span className="pill h-9 px-3" title={t("StockHeader.alertsHint")}><Bell /> {t(
                        "StockHeader.alertsScope"
                    )}</span>
                </div>
            </div>
            {None
                if daily or (yahoo and not is_chart_embeddable(tv))
                else <div className="card mt-[3px] p-1">
                    <TradingView
                        widget="symbol-info"
                        config={symbol_info(tv, locale())}
                        height={180}
                    />
                </div>}
        </section>;
    }
    stats = [
        ["open", CalendarClock, cash(q.open), t("StockHeader.openHint")],
        [
            "dayRange",
            MoveVertical,
            f"{cash(q.low)} – {cash(q.high)}" if q.low and q.high else "—",
            t("StockHeader.dayRangeHint"),
        ],
        ["prevClose", Gauge, cash(q.prev_close), t("StockHeader.prevCloseHint")],
        [
            "marketCap",
            Landmark,
            compact(profile.market_cap) if profile.market_cap else "—",
            currency,
        ],
    ];
    return <section className="hatch">
        <div className="card flex flex-wrap items-center gap-x-6 gap-y-4 p-4">
            <div className="flex min-w-0 flex-1 basis-64 items-center gap-3">
                <span className={cx("logo-well size-11", not profile.logo and "is-empty")}>
                    {<img src={profile.logo} alt="" className="size-full object-contain p-1.5" />
                        if profile.logo
                        else sym[0]}
                </span>
                <div className="min-w-0">
                    <h1
                        dir="auto"
                        className="truncate text-xl font-bold tracking-[-0.03em] rtl:text-right"
                    >{company}</h1>
                    <p className="mono truncate text-[12.5px] text-faint">
                        {" · ".join([x for x in [sym, profile.exchange, profile.industry] if x])}
                    </p>
                </div>
            </div>
            <div className="flex items-end gap-3">
                <PriceFlash value={q.price or None} className="bento-value px-1 text-[32px]">
                    {cash(q.price)}
                </PriceFlash>
                <div className="flex flex-col items-start gap-1 pb-0.5">
                    <span className="flex items-center gap-2">
                        <ChangePill value={q.change_percent if q.price else None} />
                        <span className="num text-[12px] text-faint">
                            {signed(q.change) if q.price else ""}
                        </span>
                    </span>
                    <DataFreshness
                        loc={locale()}
                        tradeTime={q.at or None}
                        realtime={live.realtime}
                    />
                </div>
            </div>
            <div className="flex flex-wrap items-center gap-2">
                {star}
                <ListButton symbol={sym} {company} />
                <AlertButton
                    symbol={sym}
                    price={q.price}
                    {currency}
                    realtime={live.realtime}
                    className="btn btn-primary"
                ><Bell /> {t("StockHeader.setAlert")}</AlertButton>
            </div>
        </div>
        <div className="bento mt-[3px]">
            {[
                <div key={s[0]} className="bento-tile gap-2.5">
                    <div className="bento-head">
                        <span className="bento-ico"><@{s[1]} /></span>
                        {t(f"StockHeader.{s[0]}")}
                    </div>
                    <p
                        className="num text-[17px] font-bold tracking-[-0.02em] [overflow-wrap:anywhere]"
                    >{s[2]}</p>
                    <p className="text-[12px] text-faint">{s[3]}</p>
                </div>
                for s in stats
            ]}
        </div>
    </section>;
}

def Sentiment(insight: StockSentiment) -> JsxElement {
    score = lambda (v: float | None, suffix: str) -> str {
        "—" if v is None else f"{v:.1f}{suffix}"
    };
    short = new(Intl.NumberFormat, "en-US", {"notation": "compact", "maximumFractionDigits": 1});
    summary = [
        ["avgBuzz", score(insight.average_buzz, "/100")],
        ["bullishAvg", score(insight.bullish_average, "%")],
        [
            "coverage",
            t("StockSentiment.coverageValue", {"count": insight.available_sources, "total": 4}),
        ],
    ];
    return <div className="flex flex-col">
        <div className="grid grid-cols-3 gap-2 p-3">
            {[
                <div key={s[0]} className="min-w-0">
                    <p className="kicker">{t(f"StockSentiment.{s[0]}")}</p>
                    <p className="num mt-1 truncate font-bold text-foreground">{s[1]}</p>
                </div>
                for s in summary
            ]}
        </div>
        <p className="border-t border-line px-3 py-2.5 text-[12.5px] text-faint">
            {rich(
                "StockSentiment.sourceAlignment",
                {
                    "value": lambda (chunk: str) -> any {
                        <span
                            key="value"
                            className={cx("font-semibold", ALIGNMENT.get(insight.source_alignment, "text-muted-foreground"))}
                        >{chunk}</span>
                    },
                },
                {
                    "alignment": t(
                        f"StockSentiment.alignment.{message_key(insight.source_alignment)}"
                    ),
                },
            )}
        </p>
        <ul className="row-list border-t border-line">
            {[
                <li
                    key={s.source}
                    className="grid grid-cols-[minmax(0,1fr)_auto_auto] items-center gap-3 px-3 py-2.5"
                >
                    <div className="min-w-0">
                        <p className="truncate font-semibold text-foreground">
                            {t("StockSentiment.newsSource") if s.source == "news" else s.label}
                        </p>
                        <p className="num truncate text-[12px] text-faint">
                            {t(
                                f"StockSentiment.metric.{message_key(s.metric_label)}",
                                {"value": short.format(s.metric_value), "count": s.metric_value},
                            )}
                        </p>
                    </div>
                    <div className="num text-end text-[12.5px]">
                        <p className="font-semibold text-foreground">{score(s.buzz_score, "")}</p>
                        <p className="text-faint">{t("StockSentiment.buzz")}</p>
                    </div>
                    <span
                        className={cx("pill w-[74px] justify-center capitalize", TREND.get(s.trend or "", ""))}
                    >
                        {t("StockSentiment.bullPct", {"pct": f"{s.bullish_pct:.0f}"})
                            if s.bullish_pct is not None
                            else t(
                                f"StockSentiment.trend.{s.trend}"
                                    if s.trend
                                    else "StockSentiment.noTrend",
                            )}
                    </span>
                </li>
                for s in insight.sources
            ]}
        </ul>
    </div>;
}

def ScoredNews(news: TickerNews) -> JsxElement {
    return <div className="flex flex-col">
        <ul className="row-list">
            {[
                <li key={n.id}>
                    <a
                        href={n.url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="group flex items-start gap-3 px-3 py-2.5 transition-colors hover:bg-hover/50"
                    >
                        <span
                            className={cx("pill num mt-0.5 w-12 flex-none justify-center", n.relevance >= 7 and "font-bold text-foreground")}
                            title={t("AlphaiNews.relevanceHint", {"score": n.relevance})}
                        >{t("AlphaiNews.relevanceValue", {"score": n.relevance})}</span>
                        <span className="min-w-0 flex-1">
                            <span
                                dir="auto"
                                className="line-clamp-2 font-semibold text-foreground transition-colors group-hover:text-brand-ink"
                            >{n.title}</span>
                            {<span
                                dir="auto"
                                className="mt-1 line-clamp-2 block text-[12.5px] text-muted-foreground"
                            >
                                {<span
                                    className={cx("font-semibold", MOOD.get(n.sentiment, "text-muted-foreground"))}
                                >{t(f"AlphaiNews.sentiment.{n.sentiment}")}: </span>
                                    if n.sentiment
                                    else None}
                                {#* AlphAI writes in English: isolated so its punctuation stays put after an Arabic label *#}
                                <bdi>{n.impact}</bdi>
                            </span>
                                if n.impact
                                else None}
                            <span className="mt-1 block truncate text-[12px] text-faint">
                                {n.source}
                                {f" · {ago(Date.parse(n.published_at) / 1000)}"
                                    if n.published_at
                                    else ""}
                                {" · " + t("AlphaiNews.outlets", {"count": n.outlets})
                                    if n.outlets > 1
                                    else ""}
                            </span>
                        </span>
                    </a>
                </li>
                for n in news.items
            ]}
        </ul>
        <p className="border-t border-line px-3 py-2.5 text-[12.5px] text-faint">
            {rich(
                "AlphaiNews.scoredBy",
                {
                    "link": lambda (chunk: str) -> any {
                        <a
                            key="link"
                            href={alphai_stock_url(news.symbol)}
                            target="_blank"
                            rel="noopener"
                            className="font-semibold text-foreground transition-colors hover:text-brand-ink"
                        >{chunk}</a>
                    },
                },
            )}
        </p>
    </div>;
}

def Stock(sym: str) -> JsxElement {
    has exchange: str | None = "";
    has paid: float | None = -1.0;
    has mood: StockSentiment | None = None;
    has scored: TickerNews | None = None;

    loc = locale();
    tv = tradingview_symbol(sym);
    # Outside the US we can't tell "no dividend" from "no data", so nothing is shown rather than a misleading dash
    company = has_finnhub_company_data(sym);

    # The technical-analysis widget refuses bare US tickers ("Permission denied"), so it gets NASDAQ:AAPL, AMEX:SPY...
    async can with entry {
        try {
            exchange = await get_tradingview_exchange(sym);
        } except RemoteError {
            exchange = None;
        }
    }

    async can with entry {
        try {
            if company {
                paid = await get_stock_metrics(sym);
            }
        } except RemoteError {}
    }

    async can with entry {
        try {
            mood = await get_stock_sentiment(sym);
        } except RemoteError {}
    }

    async can with entry {
        try {
            scored = await get_alphai_news(sym);
        } except RemoteError {}
    }

    return <>
        <Header {sym} />
        <div className="grid gap-3 xl:grid-cols-[minmax(0,1fr)_minmax(320px,400px)]">
            <div className="flex min-w-0 flex-col gap-3">
                {<Chart {tv} />
                    if is_chart_embeddable(tv)
                    else <Panel
                        title={t("StockPage.chartTitle")}
                        sub={t("StockPage.chartUnavailableSub")}
                    >
                        {#* TradingView refuses this exchange's chart in embeds; say so instead of showing its error *#}
                        <Empty
                            icon={CandlestickChart}
                            className="py-14"
                            width="max-w-80 text-[13px]"
                            title={t("StockPage.chartUnavailableTitle")}
                            body={t("StockPage.chartUnavailableBody", {"exchange": tv.split(":")[0]})}
                        >
                            <a
                                href={tradingview_symbol_url(tv)}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="btn btn-ghost mt-2"
                            >{t("StockPage.openOnTradingView")}</a>
                        </Empty>
                    </Panel>}
                <Panel title={t("StockPage.financialsTitle")} sub={t("StockPage.financialsSub")}>
                    <TradingView
                        widget="financials"
                        config={widget_config("financials", loc, {"symbol": tv})}
                        height={500}
                    />
                </Panel>
            </div>
            <div className="flex min-w-0 flex-col gap-3">
                <Panel title={t("StockPage.technicalsTitle")} sub={t("StockPage.technicalsSub")}>
                    {<div style={{"height": 400}} />
                        if exchange == ""
                        else <TradingView
                            widget="technical-analysis"
                            height={400}
                            config={widget_config("technical-analysis", loc, {"symbol": qualify_tradingview_symbol(tv, exchange)})}
                        />}
                </Panel>
                {<Panel title={t("StockPage.dividendYieldTitle")}>
                    <p className="text-2xl font-semibold text-white">
                        {"—" if paid is None else f"{paid:.2f}%"}
                    </p>
                </Panel>
                    if company and paid != -1.0
                    else None}
                {<Panel title={t("StockPage.sentimentTitle")} sub={t("StockPage.sentimentSub")}>
                    <Sentiment insight={mood} />
                </Panel>
                    if mood
                    else None}
                {<Panel title={t("StockPage.alphaiNewsTitle")} sub={t("StockPage.alphaiNewsSub")}>
                    <ScoredNews news={scored} />
                </Panel>
                    if scored
                    else None}
                <Panel title={t("StockPage.profileTitle")} sub={t("StockPage.profileSub")}>
                    <TradingView
                        widget="symbol-profile"
                        config={widget_config("symbol-profile", loc, {"symbol": tv})}
                        height={440}
                    />
                </Panel>
            </div>
        </div>
    </>;
}

# Keyed by the symbol, so going from one stock's tab to another starts from nothing
def:pub page(symbol: str) -> JsxPage {
    return <Stock key={symbol.upper()} sym={symbol.upper()} />;
}
