"""One guide: its sections, its questions, and a few companies to look up."""
import from "@jac/runtime" { Link }

glob EXAMPLES: list[str] = ["AAPL", "MSFT", "NVDA", "AMZN", "JPM", "XOM"],
     COLUMN: str = "mx-auto max-w-[800px] px-5",
     H2: str = "text-[28px] font-bold tracking-[-0.04em]",
     # Env var names are one long word; let them break instead of widening the page on phones
     PARAGRAPH: str = "text-[16px] leading-relaxed text-muted-foreground [overflow-wrap:anywhere]",
     COMPANY: str = "pill h-9 px-3 text-[13px] hover:text-foreground";

def:pub page(slug: str) -> JsxPage {
    has examples: list[Ticker] = [];

    guide = find_guide(slug);

    async can with [slug] entry {
        ld = await guide_ld(slug);
        if guide {
            head(f"{guide.title} | OpenStock", guide.description, ld);
            found = await Promise.all([find_ticker(symbol) for symbol in EXAMPLES]);
            examples = [t for t in found if t];
        }
    }

    if not guide {
        return <NotFound title="Guide not found | OpenStock" />;
    }
    return <>
        <PageHero kicker={guide.kicker} title={guide.title} sub={guide.lede}>
            <Link to="/sign-up" className={CTA}>Get started free</Link>
            <Link to="/s" className={CTA_GHOST}>Browse US stocks</Link>
        </PageHero>
        <div className={cx(COLUMN, "mt-14 flex flex-col gap-12")}>
            {[
                <section key={part.heading}>
                    <h2 className={H2}>{part.heading}</h2>
                    <div className="mt-3 flex flex-col gap-4">
                        {[
                            <p key={text} className={PARAGRAPH}>{text}</p>
                            for text in part.paragraphs
                        ]}
                    </div>
                </section>
                for part in guide.sections
            ]}
        </div>
        <section className={cx(COLUMN, "mt-16")}>
            <h2 className={cx(H2, "mb-4")}>Questions</h2>
            <Faqs items={[[f.question, f.answer] for f in guide.faqs]} />
        </section>
        {<section className={cx(COLUMN, "mt-16")}>
            <h2 className="text-[22px] font-bold tracking-[-0.03em]">Look up a company</h2>
            <ul className="mt-4 flex flex-wrap gap-2">
                {[
                    <li key={t.symbol}>
                        <Link to={ticker_path(t.symbol)} className={COMPANY}><span className="mono">
                            {t.symbol}
                        </span> {t.name}</Link>
                    </li>
                    for t in examples
                ]}
            </ul>
        </section>
            if examples
            else None}
        <section className={cx(COLUMN, "mt-12")}>
            <h2 className="text-[13px] font-semibold text-faint">Other guides</h2>
            <ul className="mt-3 flex flex-col gap-2">
                {[
                    <li key={g.slug}>
                        <Link
                            to={f"/compare/{g.slug}"}
                            className="font-semibold hover:text-brand-ink"
                        >{g.title}</Link>
                    </li>
                    for g in GUIDES
                    if g.slug != slug
                ]}
            </ul>
        </section>
        <section className={cx(COLUMN, "mt-12")}>
            <CtaCard
                title="Use OpenStock free"
                body="Charts, a watchlist and the US filing pages are free. OpenStock is not a broker and this is not investment advice."
                to="/sign-up"
                label="Create a free account"
            />
        </section>
    </>;
}
