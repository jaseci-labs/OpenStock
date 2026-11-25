"""The sponsor page: who backs OpenStock, the tiers, where the money goes and where a name shows up."""
import from "lucide-react" { ArrowUpRight, Check, Cloud, HandCoins, MessageCircle, Minus, Users }

# Where each tier shows up, with the index in SPONSOR_TIERS of the first tier that includes it.
# Mirrors the perks in content/sponsors.jac.
glob PLACEMENTS: list[tuple[str, int]] = [
         ("Name in the README sponsor list", 0),
         ("Name and avatar on the sponsor wall", 1),
         ("Logo in the footer of every public page", 2),
         ("Logo in the README", 2),
         ("Logo on the landing page", 3),
         ("Sponsor slot in the app sidebar", 3),
     ],
     FAQ: list[list[str]] = [
         [
             "How do I pay?",
             "Through GitHub Sponsors, by card or PayPal. Pick a monthly amount or give once.",
         ],
         ["Can I stop?", "Yes, any time from your GitHub Sponsors settings."],
         [
             "Can we sponsor as a company?",
             "Yes. Sponsor from your organisation’s GitHub account, then send us your logo and link. For invoices or a custom deal, talk with us.",
         ],
     ],
     H2: str = "mt-2 text-[28px] font-bold tracking-[-0.04em] md:text-[34px]",
     STAT: str = "rounded-[12px] bg-page px-3 py-3 shadow-[inset_0_0_0_1px_var(--line)] sm:px-3.5",
     PAST: str = "flex h-14 items-center justify-between gap-3 rounded-[12px] bg-page px-4 shadow-[inset_0_0_0_1px_var(--line)] transition-colors hover:bg-hover/60";

def outlined(tier: str) -> dict[str, str] {
    return {"outline": f"1px solid {tier_border(tier)}"};
}

# Logo, or the name when the logo is a mark without it
def Logo(sponsor: Sponsor, className: str = "") -> JsxElement {
    return <span className={cx("flex items-center gap-2", className)}>
        <SponsorMark {sponsor} logoClassName="h-7 w-auto" nameClassName="text-[17px] font-bold" />
    </span>;
}

# Current sponsors first and large, then everyone who used to back us, quieter
def BackedBy -> JsxElement {
    return <section id="sponsors" className="mt-24 scroll-mt-24">
        <p className="kicker text-brand-ink">Backed by</p>
        <h2 className={H2}>The people and companies keeping it free.</h2>
        <div className="mt-8 grid gap-3 md:grid-cols-2">
            {[
                <SponsorLink
                    key={s.name}
                    sponsor={s}
                    className="hatch group"
                    style={outlined(s.tier)}
                >
                    <div className="card flex h-full flex-col gap-4 p-5">
                        <div className="flex items-center justify-between gap-3">
                            <Logo sponsor={s} />
                            <span
                                className="kicker text-[10px]"
                                style={{"color": TIER_COLOR[s.tier]}}
                            >{tier_name(s.tier)}</span>
                        </div>
                        <p className="text-[14px] leading-relaxed text-muted-foreground">
                            {s.blurb}
                        </p>
                        <span
                            className="mt-auto flex items-center gap-1 text-[13px] font-semibold text-faint transition-colors group-hover:text-brand-ink"
                        >Visit {s.name} <ArrowUpRight className="size-3.5" /></span>
                    </div>
                </SponsorLink>
                for s in ACTIVE_SPONSORS
            ]}
        </div>
        <div className="hatch mt-3">
            <div className="card p-5">
                <p className="kicker">Previously backed by</p>
                <ul className="mt-4 grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
                    {[
                        <li key={s.name}>
                            <Go to={s.url} className={PAST}>
                                <Logo sponsor={s} className="opacity-60 grayscale" />
                                <span className="num shrink-0 text-[12px] text-faint">
                                    Past {tier_name(s.tier).lower()}{f" · {s.period}"
                                    if s.period
                                    else ""}</span>
                            </Go>
                        </li>
                        for s in PREVIOUS_SPONSORS
                    ]}
                    {[
                        <li key={login}>
                            <Go to={f"https://github.com/{login}"} className={PAST}>
                                <span className="flex min-w-0 items-center gap-2.5">
                                    <img
                                        src={f"https://github.com/{login}.png?size=64"}
                                        alt=""
                                        width={28}
                                        height={28}
                                        loading="lazy"
                                        className="size-7 rounded-full opacity-80 grayscale"
                                    />
                                    <span className="truncate font-semibold text-muted-foreground">
                                        {name}
                                    </span>
                                </span>
                                <span
                                    className="shrink-0 text-[12px] text-faint"
                                >Past supporter</span>
                            </Go>
                        </li>
                        for (login, name) in PREVIOUS_SUPPORTERS.items()
                    ]}
                </ul>
            </div>
        </div>
    </section>;
}

def TierCard(tier: Tier) -> JsxElement {
    filled = len([s for s in ACTIVE_SPONSORS if s.tier == tier.id]);
    taken = tier.slots > 0 and filled >= tier.slots;
    return <div
        className={cx("hatch", tier.featured and "shadow-[0_6px_18px_oklch(0_0_0/0.22)]")}
        style={outlined(tier.id)}
    >
        <div className="card flex h-full flex-col gap-4 p-5">
            <div className="flex items-center justify-between gap-2">
                <h3 className="text-[17px] font-bold tracking-[-0.02em]">{tier.name}</h3>
                {<span className="pill is-brand">Best for teams</span> if tier.featured else None}
                {<span className={cx("pill", not taken and "is-up")}>
                    {"All taken" if taken else f"{tier.slots - filled} of {tier.slots} open"}
                </span>
                    if tier.slots
                    else None}
            </div>
            <p className="bento-value text-[36px]">
                <small>$</small>
                {tier.monthly}
                <small className="text-faint"> /month</small>
            </p>
            <p className="text-[14px] leading-relaxed text-muted-foreground">{tier.blurb}</p>
            <ul className="flex flex-col gap-2 text-[13.5px]">
                {[
                    <li key={perk} className="flex gap-2">
                        <Check className="mt-0.5 size-4 flex-none text-brand-ink" />
                        <span>{perk}</span>
                    </li>
                    for perk in tier.perks
                ]}
            </ul>
            <Go
                to={MAILTO if taken else sponsor_checkout_url(tier.monthly)}
                className={cx("btn mt-auto", "btn-primary" if tier.featured else "btn-ghost")}
            >{"Join the waitlist" if taken else f"Sponsor ${tier.monthly}/month"}</Go>
        </div>
    </div>;
}

# A wide card under the tiers: an icon, a line of pitch and its buttons
def Offer(icon: any, title: str, body: str, children: any) -> JsxElement {
    return <div className="hatch">
        <div className="card flex h-full flex-col gap-3 p-5 sm:flex-row sm:items-center">
            <span className="bento-ico size-10 bg-brand-soft text-brand-ink">
                <@icon className="size-5" />
            </span>
            <div className="flex-1">
                <h3 className="text-[16px] font-bold">{title}</h3>
                <p className="text-[14px] text-muted-foreground">{body}</p>
            </div>
            {children}
        </div>
    </div>;
}

def:pub page -> JsxPage {
    has repo: RepoStats | None = None;

    goal = SPONSOR_GOAL["target"];
    backers = SPONSOR_GOAL["current"];
    use_anchor();

    async can with entry {
        repo = await repo_stats();
    }

    return <div className="mx-auto max-w-[1200px] px-5">
        <section
            className="grid items-end gap-10 pt-14 md:pt-20 lg:grid-cols-[minmax(0,1fr)_380px]"
        >
            <div>
                <p className="kicker flex items-center gap-2 text-brand-ink"><span
                    className="live-dot"
                /> Open for sponsors
                </p>
                <h1
                    className="mt-4 text-[44px] font-bold leading-[1.02] tracking-[-0.05em] md:text-[64px]"
                >
                    Back free<br />market data.
                </h1>
                <p className="mt-5 max-w-xl text-[17px] leading-relaxed text-muted-foreground">
                    OpenStock is an open-source market terminal used by {REGISTERED_USERS} registered people
                    {f", with {format_count(repo.stars)} stars on GitHub" if repo else ""}.
                    Sponsors keep it free and independent for everyone who can’t pay for a terminal.
                </p>
                <div className="mt-8 flex flex-wrap gap-2">
                    <a href="#tiers" className={CTA}>See tiers</a>
                    <a href={MAILTO} className={CTA_GHOST}>Talk with us</a>
                </div>
            </div>
            <div className="hatch">
                <div className="card flex flex-col gap-4 p-5">
                    <div className="flex items-baseline justify-between gap-3">
                        <p className="kicker">Goal</p>
                        <p className="num text-[13px] text-faint">{backers} of {f"{goal:,}"}</p>
                    </div>
                    <p
                        className="text-[20px] font-bold tracking-[-0.02em]"
                    >{f"{goal:,}"} {SPONSOR_GOAL_LABEL}</p>
                    <div
                        className="h-2.5 overflow-hidden rounded-full bg-page shadow-[inset_0_0_0_1px_var(--line)]"
                        role="progressbar"
                        aria-valuenow={backers}
                        aria-valuemax={goal}
                    >
                        <div
                            className="h-full rounded-full bg-brand"
                            style={{"width": f"max({min(100.0, backers / goal * 100)}%, 6px)"}}
                        />
                    </div>
                    {<dl className="grid grid-cols-3 gap-2">
                        {[
                            <div key={stat[0]} className={STAT}>
                                <dt className="kicker">{stat[0]}</dt>
                                <dd className="bento-value mt-1 text-[18px] sm:text-[22px]">
                                    {stat[1]}
                                </dd>
                            </div>
                            for stat in [
                                ["Users", REGISTERED_USERS.replace(",000", "K")],
                                ["Stars", format_count(repo.stars)],
                                ["Forks", format_count(repo.forks)],
                            ]
                        ]}
                    </dl>
                        if repo
                        else None}
                </div>
            </div>
        </section>
        <BackedBy />
        <section id="tiers" className="mt-24 scroll-mt-24">
            <p className="kicker text-brand-ink">Monthly</p>
            <h2
                className="mt-2 text-[32px] font-bold tracking-[-0.04em] md:text-[40px]"
            >Pick a tier.</h2>
            <div className="mt-8 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
                {[<TierCard key={tier.id} {tier} /> for tier in SPONSOR_TIERS]}
            </div>
            <div className="mt-3 grid gap-3 md:grid-cols-2">
                <Offer
                    icon={HandCoins}
                    title="Give once"
                    body="Any amount, one time, through GitHub Sponsors."
                >
                    <Go
                        to={sponsor_checkout_url(0, "one-time")}
                        className="btn btn-ghost"
                    >Give once</Go>
                </Offer>
                <Offer
                    icon={MessageCircle}
                    title="Something else in mind?"
                    body="Data or infrastructure credits, a custom placement or a partnership."
                >
                    <div className="flex gap-2">
                        <a href={MAILTO} className="btn btn-primary">Talk with us</a>
                        <Go to={DISCORD_URL} className="btn btn-ghost">Discord</Go>
                    </div>
                </Offer>
            </div>
        </section>
        <section className="mt-24">
            <p className="kicker text-brand-ink">Transparency</p>
            <h2 className={H2}>Where your money goes.</h2>
            <p className="mt-3 max-w-2xl text-[16px] text-muted-foreground">
                Sponsorships are paid through GitHub Sponsors to {SPONSOR_RECIPIENT["name"]}{" ("}<Go
                to={f"https://github.com/{SPONSOR_RECIPIENT['handle']}"}
                className="font-semibold text-brand-ink hover:underline"
            >@{SPONSOR_RECIPIENT["handle"]}</Go>
                ), {SPONSOR_RECIPIENT["role"]}, and pay for keeping OpenStock free:
            </p>
            <div className="hatch mt-8">
                <div className="card row-list">
                    {[
                        <div
                            key={label}
                            className="grid gap-1 px-5 py-4 sm:grid-cols-[180px_minmax(0,1fr)_auto] sm:items-center sm:gap-6"
                        >
                            <span className="flex items-center gap-3 font-bold">
                                <span className="mono text-[12px] text-faint">
                                    {f"{i + 1:02d}"}
                                </span>
                                {label}
                            </span>
                            <span className="text-muted-foreground">{detail}</span>
                        </div>
                        for (i, (label, detail)) in enumerate(FUNDING_USES.items())
                    ]}
                </div>
            </div>
            <div className="mt-10 grid gap-3 md:grid-cols-2">
                <IconCard icon={Cloud} title="OpenStock Cloud will pay for hosting">
                    Cloud ($5 a month, coming soon) adds live quotes and price alerts. Its subscribers will cover the servers, database and
                    market data the hosted app needs, so the free site stays online without depending on donations.
                </IconCard>
                <IconCard icon={Users} title="Sponsors keep the community moving">
                    Sponsorships pay for the time behind OpenStock: reviewing community pull requests, fixing bugs and shipping features
                    at the pace {REGISTERED_USERS} people expect, with the core free for everyone.
                </IconCard>
            </div>
        </section>
        <section className="mt-24">
            <p className="kicker text-brand-ink">Placements</p>
            <h2 className={H2}>Where your name shows up.</h2>
            <div className="hatch mt-8">
                <div className="card overflow-x-auto">
                    <table className="data-table">
                        <thead>
                            <tr>
                                <th>Placement</th>
                                {[
                                    <th key={t.id} className="text-center">{t.name}</th>
                                    for t in SPONSOR_TIERS
                                ]}
                            </tr>
                        </thead>
                        <tbody>
                            {[
                                <tr key={label}>
                                    <td className="font-semibold text-foreground">{label}</td>
                                    {[
                                        <td key={i} className="text-center">
                                            {<Check
                                                className="mx-auto size-4 text-brand-ink"
                                                aria-label="Included"
                                            />
                                                if i >= first
                                                else <Minus
                                                    className="mx-auto size-4 text-line-strong"
                                                    aria-label="Not included"
                                                />}
                                        </td>
                                        for i in range(len(SPONSOR_TIERS))
                                    ]}
                                </tr>
                                for (label, first) in PLACEMENTS
                            ]}
                        </tbody>
                    </table>
                </div>
            </div>
        </section>
        <section className="mt-24 grid gap-3 md:grid-cols-3">
            {[
                <div key={q[0]} className="hatch">
                    <div className="card h-full p-5">
                        <h3 className="font-bold">{q[0]}</h3>
                        <p className="mt-2 text-[14px] leading-relaxed text-muted-foreground">
                            {q[1]}
                        </p>
                    </div>
                </div>
                for q in FAQ
            ]}
        </section>
    </div>;
}
