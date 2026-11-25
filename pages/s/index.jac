"""A public company page: TradingView's quote and chart, and the facts SEC EDGAR has on it.
OpenStock prints no quote of its own here."""
import from "@jac/runtime" { Link }

glob UNDERLINED: str = "font-semibold text-foreground underline decoration-[var(--line)] underline-offset-4 hover:decoration-foreground",
     H2: str = "text-[22px] font-bold tracking-[-0.03em]",
     QUIET: str = "hover:text-foreground";

def Fact(label: str, children: any) -> JsxElement {
    return <div>
        <dt className="kicker">{label}</dt>
        <dd className="mt-1 text-[15px]">{children or "Not listed"}</dd>
    </div>;
}

def Report(label: str, filing: Filing | None = None) -> JsxElement {
    return <Fact {label}>
        {<Go
            to={filing.url}
            rel="noopener noreferrer"
            className={UNDERLINED}
        >{filing.form} filed {format_filing_date(filing.filed)}</Go>
            if filing
            else <span className="text-muted-foreground">Not in the recent EDGAR index</span>}
    </Fact>;
}

# The widget frame clips overflow, so the attribution TradingView requires sits under it,
# visible, with their link left as nofollow the way their embed snippet ships it
def Embed(widget: str, config: dict[str, any], height: int, to: str, credit: str) -> JsxElement {
    return <section className="hatch">
        <div className="card p-1">
            <TradingView {widget} {config} {height} expand />
            <p className="tradingview-widget-copyright">
                <Go {to} rel="noopener nofollow">{credit}</Go>
            </p>
        </div>
    </section>;
}

def:pub page(ticker: str) -> JsxPage {
    has shown: TickerPage | None = None;
    has edgar: EdgarCompany | None = None;
    has loaded: str = "";  # "", then "page", then "edgar"

    async can with [ticker] entry {
        found = await ticker_page(ticker);
        shown = found;
        loaded = "page";
        if found {
            head(f"{found.title} | OpenStock", found.intro, found.json_ld, found.url);
            edgar = await edgar_company(found.ticker.cik);
            loaded = "edgar";
        }
    }

    if not shown {
        return <NotFound title="Stock not found | OpenStock" />
            if loaded
            else <div className="min-h-dvh" />;
    }
    t = shown.ticker;
    tv = tradingview_symbol(t.symbol);
    tv_url = tradingview_symbol_url(tv);
    return <article className="mx-auto max-w-[1200px] px-5 pt-10 pb-4">
        <nav
            aria-label="Breadcrumb"
            className="flex flex-wrap items-center gap-x-2 text-[13px] font-semibold text-muted-foreground"
        >
            {[
                <span key={crumb[0]} className="contents">
                    <Link to={crumb[0]} className={QUIET}>{crumb[1]}</Link>
                    <span aria-hidden>/</span>
                </span>
                for crumb in [
                    ["/", "OpenStock"],
                    ["/s", "US stocks"],
                    [f"/s#{sector_anchor(t.sector)}", t.sector],
                ]
            ]}
            <span className="text-foreground">{t.symbol}</span>
        </nav>
        <header className="mt-6 max-w-3xl">
            <p className="kicker text-brand-ink">{t.exchange} · {t.symbol}</p>
            <h1
                className="mt-2 text-[36px] font-bold leading-[1.05] tracking-[-0.045em] md:text-[48px]"
            >{t.name}</h1>
            <p className="mt-4 text-[16px] leading-relaxed text-muted-foreground">{shown.intro}</p>
        </header>
        <div className="mt-8 flex flex-wrap gap-2">
            <Link to="/sign-up" className={CTA}>Track {t.symbol} free</Link>
            <Go to={tv_url} rel="noopener nofollow" className={CTA_GHOST}>View on TradingView</Go>
        </div>
        <div className="mt-8 flex flex-col gap-3">
            <Embed
                widget="symbol-info"
                config={symbol_info(tv)}
                height={180}
                to={tv_url}
                credit={f"{t.symbol} quote by TradingView"}
            />
            <Embed
                widget="advanced-chart"
                config={candle_chart(tv)}
                height={560}
                to={tv_url}
                credit={f"{t.symbol} chart by TradingView"}
            />
        </div>
        <section className="mt-10">
            <h2 className="text-[28px] font-bold tracking-[-0.04em]">SEC filings</h2>
            <p className="mt-2 max-w-2xl text-[15px] leading-relaxed text-muted-foreground">
                Industry code, fiscal year and filing dates come from the SEC’s EDGAR submissions feed for CIK {t.cik}.
                The annual report is a Form 10-K, or a 20-F or 40-F for a foreign issuer. The quarterly report is a Form 10-Q when the company files one.
            </p>
            <div className="hatch mt-5">
                <div className="card p-6">
                    {<dl className="grid gap-6 sm:grid-cols-2">
                        <Fact label="SIC">
                            {" · ".join([
                                part
                                for part in [edgar.sic, edgar.sic_description]
                                if part
                            ])}
                        </Fact>
                        <Fact label="Fiscal year ends">{edgar.fiscal_year_end}</Fact>
                        <Fact label="Incorporated">{edgar.state_of_incorporation}</Fact>
                        <Report label="Latest annual report" filing={edgar.annual} />
                        <Report label="Latest quarterly report" filing={edgar.quarterly} />
                        <Fact label="All filings">
                            <Go
                                to={edgar.filings_url}
                                rel="noopener noreferrer"
                                className={UNDERLINED}
                            >{t.name} on EDGAR
                            </Go>
                        </Fact>
                    </dl>
                        if edgar
                        else <p
                            className="text-[15px] leading-relaxed text-muted-foreground"
                        >{"EDGAR did not respond for this company just now. The chart above is unaffected. "
                            if loaded == "edgar"
                            else "Asking EDGAR for this company’s filings. "}<Go
                            to={company_browse_url(t.cik)}
                            rel="noopener noreferrer"
                            className={UNDERLINED}
                        >
                                Open {t.symbol} on EDGAR
                            </Go>
                            .
                        </p>}
                </div>
            </div>
        </section>
        <section className="mt-12">
            <h2 className={H2}>More in {t.sector}</h2>
            <ul className="mt-4 grid gap-2 sm:grid-cols-2 lg:grid-cols-4">
                {[
                    <li key={peer.symbol}>
                        <Link
                            to={ticker_path(peer.symbol)}
                            className="card flex items-baseline justify-between gap-3 px-3 py-2 hover:bg-hover/40"
                        >
                            <span className="truncate text-[14px]">{peer.name}</span>
                            <span className="mono shrink-0 text-[12px] text-faint">
                                {peer.symbol}
                            </span>
                        </Link>
                    </li>
                    for peer in shown.peers
                ]}
            </ul>
            <p
                className="mt-4 flex flex-wrap gap-x-4 gap-y-2 text-[13px] font-semibold text-muted-foreground"
            >
                {[
                    <Link
                        key={word}
                        to={ticker_path(near.symbol)}
                        className={QUIET}
                    >{word}: {near.symbol}</Link>
                    for (word, near) in [("Previous", shown.prev), ("Next", shown.next)]
                    if near
                ]}
                <Link to="/s" className={QUIET}>All US stocks</Link>
            </p>
        </section>
        <section className="mt-12">
            <h2 className={cx(H2, "mb-4")}>Questions about tracking {t.symbol}</h2>
            <Faqs
                items={[["Does this page show a live price?", f"The number you see in the chart is rendered by TradingView’s widget in your browser. OpenStock does not print a quote of its own on this page. A free account adds {t.symbol} to a watchlist; email alerts, when that deployment has them, run inside the app."], ["Where do the filing dates come from?", f"From the SEC’s EDGAR submissions feed for CIK {t.cik}. The link opens the filing on sec.gov. OpenStock is not affiliated with the SEC."]]}
            />
        </section>
        <nav
            aria-label="Related guides"
            className="mt-10 flex flex-wrap gap-x-4 gap-y-2 text-[13px] font-semibold text-muted-foreground"
        >
            {[
                <Link key={g.slug} to={f"/compare/{g.slug}"} className={QUIET}>{g.title}</Link>
                for g in GUIDES[:4]
            ]}
        </nav>
        <div className="mt-10">
            <CtaCard
                title={f"Track {t.symbol} free on OpenStock"}
                body="Save it to a watchlist, keep the chart open in a tab, and read the filings from one place. OpenStock is not a broker, and nothing here is investment advice."
                to="/sign-up"
                label={f"Track {t.symbol} free"}
            />
        </div>
    </article>;
}
