"""A stock: our header and price, TradingView's chart, financials, technicals and profile, then sentiment and news.
The charts come straight from TradingView (live, no quota); only the header and the cards wait on the server."""
import from "@jac/runtime" { __getLocalStorage, __setLocalStorage }
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
     PULSE: str = "animate-pulse rounded-md bg-hover",
     FOOT: str = "border-t border-line px-3 py-2.5 text-[12.5px] text-faint",
     SOURCE_ROW: str = "grid grid-cols-[minmax(0,1fr)_auto_auto] items-center gap-3 px-3 py-2.5",
     TREND_PILL: str = "pill w-[74px] justify-center capitalize",
     LINK: str = "font-semibold text-foreground transition-colors hover:text-brand-ink",
     STORY: str = "group flex items-start gap-3 px-3 py-2.5 transition-colors hover:bg-hover/50",
     RELEVANCE: str = "pill num mt-0.5 w-12 flex-none justify-center",
     HEADLINE: str = "line-clamp-2 font-semibold text-foreground transition-colors group-hover:text-brand-ink",
     IMPACT: str = "mt-1 line-clamp-2 block text-[12.5px] text-muted-foreground",
     STAT: str = "num text-[17px] font-bold tracking-[-0.02em] [overflow-wrap:anywhere]",
     COMPANY: str = "truncate text-xl font-bold tracking-[-0.03em] rtl:text-right";

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

    config = {**candle_chart(tv, locale()), "studies": studies};
    if not is_chart_embeddable(tv) {
        exchange: dict[str, any] = {"exchange": tv.split(":")[0]};
        href = tradingview_symbol_url(tv);
        return <Panel title={t("StockPage.chartTitle")} sub={t("StockPage.chartUnavailableSub")}>
            {#* TradingView refuses this exchange's chart in embeds; say so instead of showing its error *#}
            <Empty
                icon={CandlestickChart}
                className="py-14"
                width="max-w-80 text-[13px]"
                title={t("StockPage.chartUnavailableTitle")}
                body={t("StockPage.chartUnavailableBody", exchange)}
            >
                <a {href} target="_blank" rel="noopener noreferrer" className="btn btn-ghost mt-2">
                    {t("StockPage.openOnTradingView")}
                </a>
            </Empty>
        </Panel>;
    }

    return <Panel
        title={t("StockChart.title")}
        sub={t("StockChart.sub")}
        action={<Menu end className="btn btn-ghost h-8 px-2.5 text-[13px]" panelClassName="w-56" trigger={<><SlidersHorizontal /> {t("StockChart.indicatorsButton")}{<span className="num text-faint">{len(studies)}</span> if studies else None}</>}><p className="px-2 py-1.5 text-[12px] text-faint">{t("StockChart.keptNote")}</p>{[<MenuItem key={id} keepOpen checked={id in studies} onSelect={lambda { toggle(id); }}>{t(f"StockChart.indicators.{INDICATORS[id]}")}</MenuItem> for id in INDICATORS]}</Menu>}
    ><TradingView widget="advanced-chart" {config} height={560} expand loc={locale()} /></Panel>;
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
    loc = locale();
    live = use_live([sym] if covered else []);
    q = live.quotes.get(sym) or Quote();
    currency = profile.currency or "USD";
    company = profile.name or sym;
    cash = lambda (v: float) -> str { money(v, currency) if v else "—" };

    async can with entry {
        watching = await quiet(in_watchlist(sym), False);
        if covered {
            profile = await quiet(get_company_profile(sym)) or Profile();
        } elif yahoo {
            daily = (await quiet(yahoo_daily_quotes([sym]), {})).get(sym);
        }
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
    acts = <div className="flex flex-wrap items-center gap-2">
        <WatchButton symbol={sym} {company} on={watching} />
        <ListButton symbol={sym} {company} />
        {<AlertButton
            symbol={sym}
            price={q.price}
            {currency}
            realtime={live.realtime}
            className="btn btn-primary"
        ><Bell /> {t("StockHeader.setAlert")}</AlertButton>
            if covered
            else <span className="pill h-9 px-3" title={t("StockHeader.alertsHint")}><Bell /> {t(
                "StockHeader.alertsScope"
            )}</span>}
    </div>;
    if not covered {
        via = t("StockHeader.quoteViaYahoo" if yahoo else "StockHeader.quoteViaTradingView");
        about = [x for x in [tv.split(":")[0], daily.name if daily else "", via] if x];
        return <section className="hatch">
            <div className="card flex flex-wrap items-center justify-between gap-4 p-4">
                <div className="min-w-0">
                    <h1 className="mono truncate text-xl font-bold tracking-[-0.02em]">{sym}</h1>
                    <p className="text-[12.5px] text-faint">{" · ".join(about)}</p>
                </div>
                {<div className="flex items-center gap-3">
                    <p className="num text-2xl font-bold tracking-[-0.03em]">
                        {money(daily.price, daily.currency)}
                    </p>
                    <ChangePill value={daily.change_percent} />
                </div>
                    if daily
                    else None}
                {acts}
            </div>
            {None
                if daily or (yahoo and not is_chart_embeddable(tv))
                else <div className="card mt-[3px] p-1">
                    <TradingView widget="symbol-info" config={symbol_info(tv, loc)} height={180} />
                </div>}
        </section>;
    }
    day = f"{cash(q.low)} – {cash(q.high)}" if q.low and q.high else "—";
    cap = compact(profile.market_cap) if profile.market_cap else "—";
    stats = [
        ["open", CalendarClock, cash(q.open), t("StockHeader.openHint")],
        ["dayRange", MoveVertical, day, t("StockHeader.dayRangeHint")],
        ["prevClose", Gauge, cash(q.prev_close), t("StockHeader.prevCloseHint")],
        ["marketCap", Landmark, cap, currency],
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
                    <h1 dir="auto" className={COMPANY}>{company}</h1>
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
                    <DataFreshness {loc} tradeTime={q.at or None} realtime={live.realtime} />
                </div>
            </div>
            {acts}
        </div>
        <div className="bento mt-[3px]">
            {[
                <div key={s[0]} className="bento-tile gap-2.5">
                    <div className="bento-head">
                        <span className="bento-ico"><@{s[1]} /></span>
                        {t(f"StockHeader.{s[0]}")}
                    </div>
                    <p className={STAT}>{s[2]}</p>
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
    coverage: dict[str, any] = {"count": insight.available_sources, "total": 4};
    summary = [
        ["avgBuzz", score(insight.average_buzz, "/100")],
        ["bullishAvg", score(insight.bullish_average, "%")],
        ["coverage", t("StockSentiment.coverageValue", coverage)],
    ];
    tone = cx("font-semibold", ALIGNMENT.get(insight.source_alignment, "text-muted-foreground"));
    value = lambda (chunk: str) -> any { <span key="value" className={tone}>{chunk}</span> };
    alignment = t(f"StockSentiment.alignment.{message_key(insight.source_alignment)}");
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
        <p className={FOOT}>
            {rich("StockSentiment.sourceAlignment", {"value": value}, {"alignment": alignment})}
        </p>
        <ul className="row-list border-t border-line">
            {
                for s in insight.sources {
                    said = {"value": short.format(s.metric_value), "count": s.metric_value};
                    trend = f"trend.{s.trend}" if s.trend else "noTrend";
                    buzz = score(s.buzz_score, "");
                    <li key={s.source} className={SOURCE_ROW}>
                        <div className="min-w-0">
                            <p className="truncate font-semibold text-foreground">
                                {t("StockSentiment.newsSource") if s.source == "news" else s.label}
                            </p>
                            <p className="num truncate text-[12px] text-faint">
                                {t(f"StockSentiment.metric.{message_key(s.metric_label)}", said)}
                            </p>
                        </div>
                        <div className="num text-end text-[12.5px]">
                            <p className="font-semibold text-foreground">{buzz}</p>
                            <p className="text-faint">{t("StockSentiment.buzz")}</p>
                        </div>
                        <span className={cx(TREND_PILL, TREND.get(s.trend or "", ""))}>
                            {t(f"StockSentiment.{trend}")
                                if s.bullish_pct is None
                                else t("StockSentiment.bullPct", {"pct": f"{s.bullish_pct:.0f}"})}
                        </span>
                    </li>
                }
            }
        </ul>
    </div>;
}

def ScoredNews(news: TickerNews) -> JsxElement {
    href = alphai_stock_url(news.symbol);
    link = lambda (chunk: str) -> any {
        <a key="link" {href} target="_blank" rel="noopener" className={LINK}>{chunk}</a>
    };
    return <div className="flex flex-col">
        <ul className="row-list">
            {
                for n in news.items {
                    score: dict[str, any] = {"score": n.relevance};
                    mood = cx("font-semibold", MOOD.get(n.sentiment, "text-muted-foreground"));
                    felt = t(f"AlphaiNews.sentiment.{n.sentiment}") if n.sentiment else "";
                    when = f" · {ago(Date.parse(n.published_at) / 1000)}" if n.published_at else "";
                    outlets = " · " + t("AlphaiNews.outlets", {"count": n.outlets})
                        if n.outlets > 1
                        else "";
                    <li key={n.id}>
                        <a href={n.url} target="_blank" rel="noopener noreferrer" className={STORY}>
                            <span
                                className={cx(RELEVANCE, n.relevance >= 7 and "font-bold text-foreground")}
                                title={t("AlphaiNews.relevanceHint", score)}
                            >{t("AlphaiNews.relevanceValue", score)}</span>
                            <span className="min-w-0 flex-1">
                                <span dir="auto" className={HEADLINE}>{n.title}</span>
                                {<span dir="auto" className={IMPACT}>
                                    {<span className={mood}>{felt}: </span> if felt else None}
                                    {#* AlphAI writes in English: isolated so its punctuation stays put after an Arabic label *#}
                                    <bdi>{n.impact}</bdi>
                                </span>
                                    if n.impact
                                    else None}
                                <span className="mt-1 block truncate text-[12px] text-faint">
                                    {n.source + when + outlets}
                                </span>
                            </span>
                        </a>
                    </li>
                }
            }
        </ul>
        <p className={FOOT}>{rich("AlphaiNews.scoredBy", {"link": link})}</p>
    </div>;
}

# A panel titled and described by its StockPage messages
def Card(k: str, children: any, sub: bool = True) -> JsxElement {
    return <Panel title={t(f"StockPage.{k}Title")} sub={t(f"StockPage.{k}Sub") if sub else None}>
        {children}
    </Panel>;
}

# A TradingView panel for `symbol`, held at its height while the symbol is not known yet
def Widget(k: str, widget: str, height: int, symbol: str | None) -> JsxElement {
    config = widget_config(widget, locale(), {"symbol": symbol});
    return <Card {k}>
        {<div style={{"height": height}} />
            if symbol is None
            else <TradingView {widget} {config} {height} />}
    </Card>;
}

def Stock(sym: str) -> JsxElement {
    has exchange: str | None = "";
    has paid: float | None = -1.0;
    has mood: StockSentiment | None = None;
    has scored: TickerNews | None = None;

    tv = tradingview_symbol(sym);
    # Outside the US we can't tell "no dividend" from "no data", so nothing is shown rather than a misleading dash
    company = has_finnhub_company_data(sym);

    # The technical-analysis widget refuses bare US tickers ("Permission denied"), so it gets NASDAQ:AAPL, AMEX:SPY...
    async can with entry {
        exchange = await quiet(get_tradingview_exchange(sym));
    }

    async can with entry {
        if company {
            paid = await quiet(get_stock_metrics(sym), -1.0);
        }
    }

    async can with entry {
        mood = await quiet(get_stock_sentiment(sym));
    }

    async can with entry {
        scored = await quiet(get_alphai_news(sym));
    }

    ta = None if exchange == "" else qualify_tradingview_symbol(tv, exchange);
    dividend = "—" if paid is None else f"{paid:.2f}%";
    return <>
        <Header {sym} />
        <div className="grid gap-3 xl:grid-cols-[minmax(0,1fr)_minmax(320px,400px)]">
            <div className="flex min-w-0 flex-col gap-3">
                <Chart {tv} />
                <Widget k="financials" widget="financials" height={500} symbol={tv} />
            </div>
            <div className="flex min-w-0 flex-col gap-3">
                <Widget k="technicals" widget="technical-analysis" height={400} symbol={ta} />
                {<Card k="dividendYield" sub={False}>
                    <p className="text-2xl font-semibold text-white">{dividend}</p>
                </Card>
                    if company and paid != -1.0
                    else None}
                {<Card k="sentiment"><Sentiment insight={mood} /></Card> if mood else None}
                {<Card k="alphaiNews"><ScoredNews news={scored} /></Card> if scored else None}
                <Widget k="profile" widget="symbol-profile" height={440} symbol={tv} />
            </div>
        </div>
    </>;
}

# Keyed by the symbol, so going from one stock's tab to another starts from nothing
def:pub page(symbol: str) -> JsxPage {
    return <Stock key={symbol.upper()} sym={symbol.upper()} />;
}
