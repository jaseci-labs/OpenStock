import from "lucide-react" { BarChart2, Clock, Mail, UserX }

glob DATA_MODES: list[list[str]] = [
         [
             "Cached",
             "Hourly",
             "Default for the public site. Quotes are fetched once an hour and shared by every user, so cost grows with symbols, not people.",
         ],
         [
             "Realtime",
             "Every 15 seconds",
             "For OpenStock Cloud and self-hosting. Set NEXT_PUBLIC_OPENSTOCK_DATA_MODE=realtime and on-screen prices refresh live and email price alerts turn on.",
         ],
     ],
     COVERAGE: list[list[str]] = [
         ["US stocks, crypto", "Live", "Yes"],
         ["Forex", "Live", "No"],
         ["Canada, Australia", "Delayed", "No"],
         ["Saudi Arabia, Poland (Yahoo Finance)", "Delayed", "No"],
         ["India (BSE), Germany", "End of day", "No"],
     ],
     FLOW: list[str] = [
         "A user signs up, or a cron fires",
         "Inngest runs the function",
         "Gemini writes the text",
         "MiniMax (or Siray) takes over if Gemini fails",
         "The email goes out",
     ],
     JOBS: list[list[any]] = [
         [
             Mail,
             "Welcome email",
             "On sign-up",
             "An AI-written intro tailored to the country, goal, risk and industry picked at sign-up.",
         ],
         [
             BarChart2,
             "Weekly news",
             "Mon 09:00",
             "Summarises the week’s market news and sends it as a Kit broadcast.",
         ],
         [
             Clock,
             "Price alerts",
             "Every 5 min",
             "Checks every active alert against Finnhub quotes, and moving-average alerts against daily closes from Yahoo Finance, then emails the owner when one fires. Realtime mode only.",
         ],
         [
             UserX,
             "Re-engagement",
             "Daily 10:00",
             "Finds dormant accounts and sends a gentle nudge.",
         ],
     ],
     STACK: list[list[str]] = [
         [
             "Finnhub",
             "Quotes, company profiles, search and news. A pool of keys, rotated per request.",
             "https://finnhub.io",
         ],
         [
             "TradingView",
             "Charts, heatmaps, technicals and market widgets, embedded live.",
             "https://www.tradingview.com/widget/",
         ],
         ["Inngest", "Background jobs and schedules, with retries.", "https://www.inngest.com"],
         [
             "Better Auth",
             "Email, Google and GitHub sign-in with MongoDB sessions.",
             "https://www.better-auth.com",
         ],
         [
             "Yahoo Finance",
             "Delayed quotes for Saudi Arabia and Poland, which TradingView embeds block or show only end of day.",
             "https://finance.yahoo.com",
         ],
         [
             "Adanos",
             "Optional: the sentiment card, from Reddit, X, news and Polymarket.",
             "https://adanos.org",
         ],
         ["AlphAI", "Optional: the scored news card on stock pages.", "https://alphai.io"],
         [
             "MongoDB Atlas",
             "Users, watchlists, named lists, alerts and rate limits.",
             "https://www.mongodb.com/atlas",
         ],
         ["Kit", "Newsletter broadcasts for the weekly digest.", "https://kit.com"],
     ];

def:pub page -> JsxPage {
    return <>
        <PageHero
            kicker="Architecture"
            title="How OpenStock works."
            sub="A transparent look at the event-driven, multi-provider system behind your market data and emails."
        >
            <span className="pill h-8 px-3">v{LATEST_RELEASE["id"].replace("-", ".")}</span>
            <span className="pill h-8 px-3">Gemini with MiniMax fallback</span>
            <span className="pill h-8 px-3">Open source · AGPL-3.0</span>
        </PageHero>
        <section className="mx-auto mt-20 max-w-[1200px] px-5">
            <SectionHead
                kicker="Market data"
                title="Two data modes, one cache."
                sub="Charts always stream from TradingView. Everything we price ourselves goes through a shared cache with timeouts, so a slow provider never stalls a page."
            />
            <div className="grid gap-3 md:grid-cols-2">
                {[
                    <div key={mode[0]} className="hatch">
                        <div className="card flex h-full flex-col gap-2 p-5">
                            <div className="flex items-center justify-between">
                                <h3 className="text-[16px] font-bold">{mode[0]}</h3>
                                <span className="pill is-brand">{mode[1]}</span>
                            </div>
                            {#* The env var name is one long word; let it break instead of widening the page on phones *#}
                            <p
                                className="text-[14px] leading-relaxed text-muted-foreground [overflow-wrap:anywhere]"
                            >{mode[2]}</p>
                        </div>
                    </div>
                    for mode in DATA_MODES
                ]}
            </div>
            <div className="hatch mt-3">
                <div className="card overflow-x-auto">
                    <table className="data-table">
                        <thead>
                            <tr><th>Market</th><th>Charts</th><th>Our quotes and alerts</th></tr>
                        </thead>
                        <tbody>
                            {[
                                <tr key={row[0]}>
                                    <td className="font-semibold text-foreground">{row[0]}</td>
                                    <td className="text-muted-foreground">{row[1]}</td>
                                    <td>
                                        <span
                                            className={"pill is-up" if row[2] == "Yes" else "pill"}
                                        >{row[2]}</span>
                                    </td>
                                </tr>
                                for row in COVERAGE
                            ]}
                        </tbody>
                    </table>
                </div>
            </div>
            <a
                href={REPO_URL + "/blob/main/MARKET_SUPPORT.md"}
                target="_blank"
                rel="noreferrer"
                className="btn btn-ghost mt-4"
            >Full market support notes</a>
        </section>
        <section
            className="mx-auto mt-24 grid max-w-[1200px] items-start gap-10 px-5 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)]"
        >
            <div>
                <SectionHead
                    kicker="AI"
                    title="Emails that don’t go down with a provider."
                    sub="Welcome emails and news summaries are written by Gemini 2.5 Flash-Lite. If it fails, the request is retried on MiniMax (MiniMax-M3.1-Flash by default), or on Siray when that is the only fallback key set. Set MINIMAX_MODEL to MiniMax-M3 or keep your configured model override."
                />
            </div>
            <div className="hatch">
                <ol className="card flex flex-col gap-1 p-4">
                    {[
                        <li
                            key={step}
                            className="flex items-center gap-3 rounded-[10px] px-2 py-2.5"
                        >
                            <span
                                className="mono grid size-7 flex-none place-items-center rounded-full bg-page text-[12px] text-brand-ink shadow-[inset_0_0_0_1px_var(--line)]"
                            >{i + 1}</span>
                            <span className="font-semibold">{step}</span>
                        </li>
                        for (i, step) in enumerate(FLOW)
                    ]}
                </ol>
            </div>
        </section>
        <section className="mx-auto mt-24 max-w-[1200px] px-5">
            <SectionHead kicker="Background jobs" title="Four jobs keep things moving." />
            <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
                {[
                    <IconCard
                        key={job[1]}
                        icon={job[0]}
                        title={job[1]}
                        footer={<span className="pill mono">{job[2]}</span>}
                    >{job[3]}</IconCard>
                    for job in JOBS
                ]}
            </div>
        </section>
        <section className="mx-auto mt-24 max-w-[1200px] px-5">
            <SectionHead kicker="Stack" title="Built on services you can inspect." />
            <div className="hatch">
                <div className="card row-list">
                    {[
                        <a
                            key={s[0]}
                            href={s[2]}
                            target="_blank"
                            rel="noreferrer"
                            className="group flex flex-col gap-1 px-5 py-4 transition-colors hover:bg-hover/40 sm:flex-row sm:items-center sm:gap-6"
                        >
                            <span
                                className="w-40 flex-none font-bold text-foreground group-hover:text-brand-ink"
                            >{s[0]}</span>
                            <span className="text-muted-foreground">{s[1]}</span>
                        </a>
                        for s in STACK
                    ]}
                </div>
            </div>
        </section>
    </>;
}
