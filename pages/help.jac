import from "lucide-react" { BookOpen, ChevronDown, Github, MessageCircle }

glob CARDS: list[list[any]] = [
         [
             BookOpen,
             "How it works",
             "Data sources, background jobs and the AI behind the emails.",
             "/api-docs",
             "Read the architecture",
         ],
         [
             MessageCircle,
             "Community chat",
             "Get answers from other users and the maintainers.",
             DISCORD_URL,
             "Join Discord",
         ],
         [
             Github,
             "Report a bug",
             "Found something broken? Tell us on GitHub.",
             REPO_URL + "/issues",
             "Open an issue",
         ],
     ],
     FAQS: list[list[str]] = [
         [
             "Is OpenStock really free?",
             "Yes. We run on sponsors and community contributions. Charts, watchlists and research stay free. OpenStock Cloud, coming soon, adds live quotes and email price alerts for $5 a month. Self-hosting includes both.",
         ],
         [
             "How do I add a stock to my watchlist?",
             "Press ⌘K (or Search stocks in the sidebar), open the company, then press Watch. It shows up in your watchlist and in the sidebar.",
         ],
         [
             "Can I sort stocks into lists?",
             "Yes. Next to your starred watchlist of up to 50 stocks, you can make up to 10 named lists of 50 each. Add a stock to one with the list button on any watchlist row, or straight from search.",
         ],
         [
             "Is OpenStock in my language?",
             "The app, the sign-in pages and the emails are in English, Polish and Arabic, with Arabic laid out right to left. OpenStock follows your browser’s language, or pick one from Language in the sidebar. This public site is in English.",
         ],
         [
             "Where does the market data come from?",
             "Charts come live from TradingView. Quotes, watchlist prices and alerts come from Finnhub; on this site they refresh hourly and every price shows when it was last traded.",
         ],
         [
             "Which markets are supported?",
             "US stocks, crypto and forex live; Canada and Australia delayed; Saudi Arabia and Poland delayed through Yahoo Finance; India (through BSE) and Germany end of day. Alerts work for US stocks and crypto.",
         ],
         [
             "My alert hasn’t fired.",
             "Price alerts are part of OpenStock Cloud (or a self-hosted instance in realtime mode). There they are checked every five minutes and emailed to your account address when the price crosses your target, or the 20, 50, 100 or 200-day moving average you picked. Check the alert’s status on the watchlist page.",
         ],
         [
             "Can I contribute code or designs?",
             "Absolutely. Issues labelled “good first issue” are a good start. We welcome designers, developers and writers alike.",
         ],
     ];

def:pub page -> JsxPage {
    return <>
        <PageHero
            kicker="Help"
            title="How can we help?"
            sub="Community-powered support for everyone."
        />
        <section className="mx-auto mt-14 grid max-w-[1200px] gap-3 px-5 md:grid-cols-3">
            {[
                <IconCard
                    key={c[1]}
                    icon={c[0]}
                    title={c[1]}
                    footer={<a href={c[3]} target={"_blank" if c[3].startswith("http") else None} rel="noreferrer" className="btn btn-ghost w-full">{c[4]}</a>}
                >{c[2]}</IconCard>
                for c in CARDS
            ]}
        </section>
        <section className="mx-auto mt-24 max-w-[1200px] px-5">
            <SectionHead kicker="FAQ" title="Common questions." />
            <div className="hatch">
                <div className="card row-list overflow-hidden">
                    {[
                        <details key={faq[0]} className="group">
                            {#* Padding lives on the summary so the whole row is the click target, in every browser *#}
                            <summary
                                className="flex min-h-14 cursor-pointer list-none items-center justify-between gap-4 px-5 py-4 font-semibold text-foreground transition-colors hover:bg-hover/40 [&::-webkit-details-marker]:hidden"
                            >
                                {faq[0]}
                                <ChevronDown
                                    className="size-4 flex-none text-faint transition-transform duration-200 group-open:rotate-180"
                                />
                            </summary>
                            <p
                                className="max-w-3xl px-5 pb-5 text-[15px] leading-relaxed text-muted-foreground"
                            >{faq[1]}</p>
                        </details>
                        for faq in FAQS
                    ]}
                </div>
            </div>
        </section>
        <section className="mx-auto mt-24 max-w-[1200px] px-5">
            <div className="hatch">
                <div
                    className="card flex flex-col items-start justify-between gap-5 p-8 md:flex-row md:items-center"
                >
                    <div>
                        <h2 className="text-[22px] font-bold tracking-[-0.03em]">Still stuck?</h2>
                        <p
                            className="mt-1 text-muted-foreground"
                        >Our team and community answer emails, for free.</p>
                    </div>
                    <a
                        href={f"mailto:{CONTACT_EMAIL}"}
                        className="btn btn-primary h-11 px-5 text-[15px]"
                    >Email support</a>
                </div>
            </div>
        </section>
    </>;
}
