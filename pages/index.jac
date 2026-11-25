"""The landing page: the New York session, the live product preview and what OpenStock offers."""
import from "@jac/runtime" { Link }
import from "lucide-react" {
    ArrowUpRight,
    Bell,
    CandlestickChart,
    Command,
    FileText,
    GitPullRequest,
    Github,
    Grid3x3,
    HeartHandshake,
    Languages,
    ListChecks,
    MailOpen,
    MessagesSquare,
    Star,
}

glob FEATURE_ICONS: list[any] = [
         CandlestickChart,
         Bell,
         MessagesSquare,
         Grid3x3,
         Command,
         MailOpen,
         ListChecks,
         Languages,
         FileText,
     ],
     FEATURES: list[list[str]] = rows("""
Charts that move | TradingView candles, technicals and financials for any listed company, full screen when you need room.
Alerts by email | With OpenStock Cloud, set a target price, or follow the 20, 50, 100 or 200-day moving average. We check every five minutes and write when it crosses.
Sentiment in one read | Buzz and bullishness from Reddit, X.com, news and Polymarket, side by side for each stock.
The whole market | Nine markets on one switch: US, India, Germany, Canada, Australia, Saudi Arabia, Poland, crypto and forex, each with index tiles, movers or a heatmap, and top stories.
Find anything with ⌘K | Search every exchange Finnhub covers and open a stock as a tab, like a browser.
A Monday digest | A short, AI-written summary of the week’s news for the stocks you watch.
Lists for every idea | Star up to 50 stocks, then group them into up to 10 named lists of 50, from any watchlist row or straight from search.
In your language | The app, sign-in pages and emails in English, Polish and Arabic, with Arabic laid out right to left.
Open stock pages | A chart and the latest SEC filings for every S&P 500 and Nasdaq-100 company, no account needed."""),
     # name | price | per | tag | cadence | updates an hour | body | button | where it leads
     TIERS: list[list[str]] = rows(f"""
Community | Free | | | Hourly | 1 | This site. Quotes refresh every hour and are shared by everyone from the edge. Charts stay live. | Get started | /sign-up
OpenStock Cloud | $5 | /month | Coming soon | Every 15 seconds | 240 | The same app with live quotes and email price alerts, hosted on a pool of market data keys. Nothing to set up. | Get notified on Discord | {DISCORD_URL}
Self-host | Free | | | Your call | 240 | Run it on your own server with your own Finnhub keys: realtime quotes and alerts for you and your team. | Setup guide | #self-host"""),
     SUPPORT_ICONS: list[any] = [HeartHandshake, GitPullRequest, Star],
     # title | body | button | where it leads
     SUPPORT: list[list[str]] = rows(f"""
Sponsor | Monthly tiers from $5, a one-time gift, or a custom partnership. Sponsors are shown on this site, in the app and in the README. | See sponsor tiers | /sponsor
Contribute | Pick a good first issue, improve the docs or design a screen. Every merged pull request keeps OpenStock moving. | Good first issues | {GOOD_FIRST_ISSUES_URL}
Spread the word | Star the repo and share it with someone paying for a terminal they barely use. | Star on GitHub | {REPO_URL}"""),
     # The self-host snippet: [class of the first part, first part, the rest]
     SETUP: list[list[str]] = [
         ["text-faint", "$ ", f"git clone {REPO_URL}.git"],
         ["text-faint", "$ ", "cd OpenStock"],
         [],
         ["text-faint", "# .env (every variable is in the README)", ""],
         ["text-brand-ink", "FINNHUB_API_KEYS", "=key_one,key_two,key_three"],
         ["text-brand-ink", "NEXT_PUBLIC_OPENSTOCK_DATA_MODE", "=realtime"],
         [],
         ["text-faint", "$ ", "docker compose up -d --build"],
     ],
     # The dial's sessions: phase, from and to in New York minutes, label
     ARCS: list[list[any]] = [
         ["pre", PRE, OPEN, "Pre"],
         ["open", OPEN, CLOSE, "Regular"],
         ["after", CLOSE, AFTER_END, "After"],
     ],
     R: int = 88,
     C: float = 2 * Math.PI * R,
     SECTION: str = "mt-28 scroll-mt-24",
     H1: str = "mt-6 text-[44px] font-bold leading-[1.02] tracking-[-0.05em] md:text-[68px]",
     LEDE: str = "mt-5 max-w-xl text-[17px] leading-relaxed text-muted-foreground",
     STATUS: str = "inline-flex h-8 items-center gap-2 rounded-full bg-card px-3.5 text-[13px] font-semibold text-muted-foreground shadow-[inset_0_0_0_1px_var(--line)]",
     QUOTE: str = "mt-4 text-[26px] font-semibold leading-snug tracking-[-0.03em] md:text-[30px]",
     BANNER: str = "fixed top-[130px] right-[calc((100vw-1200px)/4-100px)] z-30 hidden w-[200px] min-[1680px]:flex min-[1680px]:flex-col min-[1680px]:gap-3",
     VISIT: str = "btn btn-ghost h-9 text-[13px] group-hover:bg-[var(--hover)] group-hover:text-foreground",
     RAIL: str = "h-7 rounded-md bg-page shadow-[inset_0_0_0_1px_var(--line)]",
     PITCH: str = "card grid gap-10 p-5 sm:p-8 md:p-12 lg:grid-cols-[minmax(0,1.4fr)_minmax(0,1fr)]";

# New York's weekday (0 = Sunday) and minute of the day, by the visitor's own clock
def new_york -> list[int] {
    there = new(Date, new(Date).toLocaleString("en-US", {"timeZone": "America/New_York"}));
    return [there.getDay(), there.getHours() * 60 + there.getMinutes()];
}

# The live session line for the hero
def MarketStatus(phase: str, line: str) -> JsxElement {
    dot = {"open": "bg-up shadow-[0_0_0_3px_oklch(0.70_0.164_150/0.2)]", "closed": "bg-faint"};
    return <span className={STATUS}>
        <span className={cx("size-1.5 rounded-full", dot.get(phase, "bg-warn"))} />
        <span className="num">{line}</span>
    </span>;
}

# A 24h dial of the New York trading day. Sessions that aren't happening now are hatched.
def MarketDial(phase: str, minutes: int) -> JsxElement {
    ring = {"cx": "110", "cy": "110", "r": R, "fill": "none", "strokeWidth": "18"};
    turn = {"transform": f"rotate({minutes / DAY * 360}deg)", "transformOrigin": "110px 110px"};
    hand = {"x1": 110 + R - 14, "y1": "110", "x2": 110 + R + 14, "y2": "110"};
    hatch = {"x1": "0", "y1": "0", "x2": "0", "y2": "5", "stroke": "var(--line-strong)"};
    return <figure className="mx-auto w-full max-w-[280px]" aria-label="New York trading sessions">
        <div className="relative aspect-square">
            <svg viewBox="0 0 220 220" className="size-full -rotate-90">
                <defs>
                    <pattern
                        id="dial-hatch"
                        width="5"
                        height="5"
                        patternUnits="userSpaceOnUse"
                        patternTransform="rotate(45)"
                    >
                        <rect width="5" height="5" fill="var(--frame)" />
                        <line {...hatch} strokeWidth="1.4" />
                    </pattern>
                </defs>
                <circle {...ring} stroke="url(#dial-hatch)" />
                {[
                    <circle
                        key={a[0]}
                        {...ring}
                        strokeDasharray={f"{(a[2] - a[1]) / DAY * C} {C}"}
                        strokeDashoffset={-a[1] / DAY * C}
                        className={cx("transition-[stroke] duration-300", "stroke-brand" if a[0] == phase else "stroke-line-strong" if a[0] == "open" else "stroke-hover")}
                    />
                    for a in ARCS
                ]}
                <g style={turn}>
                    <line {...hand} stroke="var(--text)" strokeWidth="2.5" strokeLinecap="round" />
                </g>
            </svg>
            <div className="absolute inset-0 grid place-items-center text-center">
                <span>
                    <span
                        className="mono block text-[34px] font-medium tracking-[-0.04em] text-foreground"
                    >{f"{minutes // 60:02d}:{minutes % 60:02d}"}</span>
                    <span className="kicker">New York</span>
                </span>
            </div>
        </div>
        <ul className="mt-4 flex justify-center gap-4 text-[12px] text-faint">
            {[
                <li key={a[0]} className="flex items-center gap-1.5">
                    <span
                        className={cx("size-2 rounded-full", "bg-brand" if a[0] == phase else "bg-line-strong" if a[0] == "open" else "bg-hover")}
                    />
                    {a[3]}
                </li>
                for a in ARCS
            ]}
        </ul>
    </figure>;
}

# Floats in the empty gutter beside the 1200px column, so it only shows on screens wide enough to have one
def SponsorBanner -> JsxElement {
    logo = "h-14 w-auto max-w-full self-start object-contain";
    return <aside aria-label="Sponsors" className={BANNER}>
        {[
            <SponsorLink key={s.name} sponsor={s} className="hatch group">
                <div className="card flex flex-col gap-4 p-5">
                    <Live className="gap-1.5">Sponsor</Live>
                    <img src={s.logo} alt={"" if s.icon_only else s.name} className={logo} />
                    <div>
                        <p className="text-[17px] font-bold tracking-[-0.02em]">{s.name}</p>
                        <p className="mt-1 text-[13px] leading-relaxed text-muted-foreground">
                            {s.blurb}
                        </p>
                    </div>
                    <span className={VISIT}>Visit {s.name} <ArrowUpRight /></span>
                </div>
            </SponsorLink>
            for s in sidebar_sponsors()
        ]}
    </aside>;
}

# One way to get the data: its price, how often quotes update, drawn as ticks, and its button
def DataTier(tier: list[str]) -> JsxElement {
    (name, price, per, tag, cadence, rate, body, label, to) = tier;
    # 60 minutes of updates drawn as ticks: one line per refresh
    rail = f"repeating-linear-gradient(90deg, var(--brand) 0 1px, transparent 1px calc(100% / {rate}))"
        if rate != "1"
        else "linear-gradient(90deg, var(--brand) 0 2px, transparent 2px)";
    return <Hatch className="flex h-full flex-col gap-4 p-5">
        <div className="flex items-center justify-between gap-3">
            <h3 className="text-[18px] font-bold tracking-[-0.02em]">{name}</h3>
            {<span className="pill is-brand">{tag}</span> if tag else None}
        </div>
        <p className="bento-value text-[30px]">
            {price}
            {<small className="text-faint"> {per}</small> if per else None}
        </p>
        <p className={MUTED}>{body}</p>
        <div className="mt-auto flex flex-col gap-2">
            <div className={RAIL} style={{"backgroundImage": rail}} aria-hidden />
            <p className="num flex justify-between text-[12px] text-faint">
                <span>{cadence}</span>
                <span>{rate} {"update" if rate == "1" else "updates"} an hour</span>
            </p>
        </div>
        <Go {to} className={"btn btn-primary" if name == "Community" else "btn btn-ghost"}>
            {label}
        </Go>
    </Hatch>;
}

def:pub page -> JsxPage {
    has now: list[int] = new_york();
    has repo: RepoStats | None = None;
    has timer: Ref[any] = Ref(None);

    session = session_of(now[0], now[1]);
    use_anchor();

    async can with entry {
        timer.current = setInterval(lambda { now = new_york(); }, 15000);
        repo = await repo_stats();
    }

    can with exit {
        clearInterval(timer.current);
    }

    stars = <span className="num text-faint">{format_count(repo.stars)} stars</span>
        if repo
        else None;
    stats = [
        ["Stars", format_count(repo.stars)],
        ["Forks", format_count(repo.forks)],
        ["License", repo.license],
        ["Written in", "Jac"],
    ]
        if repo
        else [];
    return <>
        <SponsorBanner />
        <Band
            className="grid items-center gap-12 pt-14 md:pt-20 lg:grid-cols-[minmax(0,1fr)_320px]"
        >
            <div>
                <MarketStatus phase={session.phase} line={session.line} />
                <h1 className={H1}>Markets, minus<br />the paywall.</h1>
                <p className={LEDE}>
                    OpenStock is an open-source alternative to expensive market platforms. Track prices, watch the whole market and dig into
                    company insights, built openly, for everyone.
                </p>
                <div className="mt-8 flex flex-wrap items-center gap-2">
                    <Link to="/sign-up" className={CTA}>Get started free</Link>
                    <Go to={REPO_URL} className={CTA_GHOST}><Github /> Self-host it{stars}</Go>
                </div>
            </div>
            <Hatch className="px-6 pb-5 pt-6">
                <MarketDial phase={session.phase} minutes={now[1]} />
            </Hatch>
        </Band>
        <Band className="mt-16"><ProductPreview /></Band>
        <Band
            id="inside"
            className={SECTION}
            kicker="What's inside"
            title="A terminal for people who aren't at a bank."
            sub="Everything you need to follow the market, in one place, without a subscription."
        >
            <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
                {[
                    <IconCard key={f[0]} icon={FEATURE_ICONS[i]} title={f[0]}>{f[1]}</IconCard>
                    for (i, f) in enumerate(FEATURES)
                ]}
            </div>
        </Band>
        <Band
            id="data"
            className={SECTION}
            kicker="Data"
            title="Pick how fresh your numbers are."
            sub="Charts come from TradingView: live for most markets, end of day for some, and a link out where TradingView blocks the embed. Quotes, watchlists and alerts come from Finnhub (Saudi and Polish prices from Yahoo Finance, delayed), and this is how often they update."
        >
            <div className="grid gap-3 lg:grid-cols-3">
                {[<DataTier key={tier[0]} {tier} /> for tier in TIERS]}
            </div>
        </Band>
        <Band
            id="self-host"
            className={cx(SECTION, "grid items-start gap-10 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.15fr)]")}
        >
            <div>
                <SectionHead
                    kicker="Self-host"
                    title="Your server, your keys, live quotes."
                    sub="Add as many free Finnhub keys as you like: each one adds 60 requests a minute. Switch the data mode to realtime and prices refresh every 15 seconds. Run it with Docker, on Railway or Vercel, or on Cloudflare Workers (experimental)."
                />
                <Go
                    to={f"{REPO_URL}#docker-setup"}
                    className="btn btn-ghost"
                >Full setup in the README</Go>
            </div>
            <Hatch
                inner="pre"
                className="mono overflow-x-auto p-5 text-[13px] leading-7 text-muted-foreground"
            >
                {[
                    <span key={i}>
                        {"\n" if i else ""}
                        {<>
                            <span className={row[0]}>{row[1]}</span>
                            <span className="text-foreground">{row[2]}</span>
                        </>
                            if row
                            else None}
                    </span>
                    for (i, row) in enumerate(SETUP)
                ]}
            </Hatch>
        </Band>
        <Band
            id="sponsor"
            className={SECTION}
            kicker="Support"
            title="OpenStock is open for sponsors."
            sub="It stays free because people and companies back it. Pay what you can, or give time instead."
        >
            <div className="grid gap-3 lg:grid-cols-3">
                {[
                    <IconCard
                        key={s[0]}
                        icon={SUPPORT_ICONS[i]}
                        title={s[0]}
                        footer={<Go to={s[3]} className={cx("btn w-full", "btn-ghost" if i else "btn-primary")}>{s[2]}</Go>}
                    >{s[1]}</IconCard>
                    for (i, s) in enumerate(SUPPORT)
                ]}
            </div>
        </Band>
        <Band className="mt-28">
            <div className="hatch">
                {#* Two columns only from lg: at md the stats column was too narrow for the longest value *#}
                <div className={PITCH}>
                    <div>
                        <p className="kicker text-brand-ink">Open Dev Society</p>
                        <blockquote className={QUOTE}>
                            Technology should belong to everyone. Knowledge should be open, free, and accessible.
                        </blockquote>
                        <div className="mt-8 flex flex-wrap gap-2">
                            <Link to="/sign-up" className={CTA}>Get started free</Link>
                            <Link to="/about" className={CTA_GHOST}>Read the manifesto</Link>
                        </div>
                    </div>
                    {<dl className="grid grid-cols-2 content-end gap-2 sm:gap-3">
                        {[
                            <div key={s[0]} className="bento-tile col-span-1 bg-page">
                                <dt className="kicker">{s[0]}</dt>
                                <dd className="bento-value text-[18px] sm:text-[26px]">{s[1]}</dd>
                            </div>
                            for s in stats
                        ]}
                    </dl>
                        if repo
                        else None}
                </div>
            </div>
        </Band>
    </>;
}
