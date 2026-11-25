"""The guides: short, factual pages on what OpenStock is and is not."""
import from "@jac/runtime" { Link }

def:pub page -> JsxPage {
    return <>
        <PageHero
            kicker="Guides"
            title="What OpenStock is for."
            sub="Short, factual pages for the questions people actually ask. Charts on this site are TradingView widgets. The signed-in app is free to try."
        />
        <section className="mx-auto mt-12 grid max-w-[1200px] gap-3 px-5 md:grid-cols-2">
            {[
                <Link key={g.slug} to={f"/compare/{g.slug}"} className="hatch group">
                    <article className="card flex h-full flex-col gap-3 p-6">
                        <p className="kicker text-brand-ink">{g.kicker}</p>
                        <h2
                            className="text-[22px] font-bold tracking-[-0.03em] group-hover:text-brand-ink"
                        >{g.title}</h2>
                        <p className="text-[15px] leading-relaxed text-muted-foreground">
                            {g.description}
                        </p>
                    </article>
                </Link>
                for g in GUIDES
            ]}
        </section>
    </>;
}
