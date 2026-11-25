import from "lucide-react" { AlertTriangle, Check, X }

glob PROMISES: list[str] = [
         "Core features will remain free forever.",
         "We will never sell your personal data.",
         "Terms changes will be discussed openly.",
         "You own your watchlists and analysis.",
     ],
     RULES: list[list[any]] = [
         [
             "Do",
             Check,
             "text-up",
             [
                 "Share knowledge freely",
                 "Use the API for personal projects",
                 "Respect other members",
             ],
         ],
         [
             "Don’t",
             X,
             "text-down",
             [
                 "Scrape data excessively",
                 "Share API keys",
                 "Use OpenStock for high-frequency trading",
             ],
         ],
     ];

def:pub page -> JsxPage {
    return <>
        <PageHero
            kicker="Terms · Last updated October 2025"
            title="Terms of Service"
            sub="Built on trust, transparency and community values. No hidden gotchas, just clear rules."
        />
        <section className="mx-auto mt-14 max-w-[1200px] px-5">
            <div className="hatch">
                <div
                    className="card flex gap-4 p-6 shadow-[inset_0_0_0_1px_oklch(0.76_0.119_70/0.35)]"
                >
                    <AlertTriangle className="mt-0.5 size-5 flex-none text-warn" />
                    <div>
                        <h2 className="font-bold text-warn">Investment disclaimer</h2>
                        <p className="mt-2 max-w-3xl leading-relaxed text-muted-foreground"><strong
                            className="text-foreground"
                        >OpenStock is an educational and analysis tool, not a financial advisor.</strong>{" "}
                            Data is provided as is, for information only. Never invest money you cannot afford to lose. Always do your own
                            research or consult a certified professional before making financial decisions.
                        </p>
                    </div>
                </div>
            </div>
        </section>
        <section className="mx-auto mt-20 max-w-[1200px] px-5">
            <SectionHead kicker="Our promise" title="What you can count on." />
            <div className="grid gap-3 sm:grid-cols-2">
                {[
                    <div key={promise} className="hatch">
                        <div className="card flex h-full items-center gap-3 p-5">
                            <span className="bento-ico bg-brand-soft text-brand-ink">
                                <Check />
                            </span>
                            <span className="font-semibold">{promise}</span>
                        </div>
                    </div>
                    for promise in PROMISES
                ]}
            </div>
        </section>
        <section className="mx-auto mt-20 max-w-[1200px] px-5">
            <SectionHead kicker="Community rules" title="Do’s and don’ts." />
            <div className="grid gap-3 md:grid-cols-2">
                {[
                    <div key={rule[0]} className="hatch">
                        <div className="card h-full p-5">
                            <h3 className="kicker">{rule[0]}</h3>
                            <ul className="mt-3 flex flex-col gap-2.5">
                                {[
                                    <li key={item} className="flex items-center gap-2.5">
                                        <@{rule[1]} className={f"size-4 flex-none {rule[2]}"} />
                                        <span className="text-muted-foreground">{item}</span>
                                    </li>
                                    for item in rule[3]
                                ]}
                            </ul>
                        </div>
                    </div>
                    for rule in RULES
                ]}
            </div>
            <p className="mt-8 text-muted-foreground">
                Questions about these terms? Email <a
                href={f"mailto:{SPONSOR_CONTACT_EMAIL}"}
                className="font-semibold text-brand-ink hover:underline"
            >{SPONSOR_CONTACT_EMAIL}</a>.
            </p>
        </section>
    </>;
}
