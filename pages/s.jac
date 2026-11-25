"""The stock directory: every S&P 500 and Nasdaq-100 company under its sector."""
import from "@jac/runtime" { Link }

glob ROW: str = "group flex items-baseline justify-between gap-3 rounded-lg px-2 py-1.5 hover:bg-hover/50";

def Sector(sector: str, found: list[Ticker]) -> JsxElement {
    symbol = "mono shrink-0 text-[12px] text-faint group-hover:text-foreground";
    return <section id={sector_anchor(sector)} className="scroll-mt-24">
        <h2 className="text-[22px] font-bold tracking-[-0.03em]">{sector}</h2>
        <ul className="mt-4 grid gap-x-6 gap-y-2 sm:grid-cols-2 lg:grid-cols-3">
            {[
                <li key={t.symbol}>
                    <Link to={ticker_path(t.symbol)} className={ROW}>
                        <span className="truncate text-[14px]">{t.name}</span>
                        <span className={symbol}>{t.symbol}</span>
                    </Link>
                </li>
                for t in found
            ]}
        </ul>
    </section>;
}

def:pub page -> JsxPage {
    has sectors: dict[str, list[Ticker]] = {};

    count = sum([len(found) for found in sectors.values()]);
    use_anchor(count > 0);

    async can with entry {
        sectors = await tickers_by_sector();
        total = sum([len(found) for found in sectors.values()]);
        head(DIRECTORY_TITLE, directory_description(total), await directory_ld());
    }

    return <>
        <PageHero
            kicker="US stocks"
            title="Charts and filings, no account."
            sub={f"{count or 'Hundreds of'} companies from the S&P 500 and the Nasdaq-100. Each page is a TradingView chart plus the latest annual and quarterly report on SEC EDGAR. The signed-in app is where watchlists and alerts live."}
        >
            <Link to="/sign-up" className={CTA}>Track them free</Link>
            <Link to="/compare" className={CTA_GHOST}>Read the guides</Link>
        </PageHero>
        <nav aria-label="Sectors" className={cx(WIDE, "mt-10 flex flex-wrap gap-2")}>
            {[
                <a
                    key={sector}
                    href={f"#{sector_anchor(sector)}"}
                    className="pill h-8 px-3 text-[13px]"
                >{sector} <span className="num text-faint">{len(found)}</span></a>
                for (sector, found) in sectors.items()
            ]}
        </nav>
        <div className={cx(WIDE, "mt-12 flex flex-col gap-12")}>
            {[<Sector key={sector} {sector} {found} /> for (sector, found) in sectors.items()]}
        </div>
    </>;
}
