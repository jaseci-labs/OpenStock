"""The public site's frame: header, footer, sponsors, the update banner and the page furniture."""
import from "@jac/runtime" { Link, useLocation }
import from "lucide-react" { ArrowRight, ArrowUpRight, Check, ChevronDown, Copy, Github, Linkedin }

glob CTA: str = "btn btn-primary h-11 px-5 text-[15px]",
     CTA_GHOST: str = "btn btn-ghost h-11 px-5 text-[15px]",
     MAILTO: str = f"mailto:{SPONSOR_CONTACT_EMAIL}?subject=Sponsoring%20OpenStock",
     FOCUS: str = "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand/70 focus-visible:ring-offset-2 focus-visible:ring-offset-side",
     HATCHED: str = "repeating-linear-gradient(-45deg, oklch(0.4 0.01 95 / 0.22) 0 1px, transparent 1px 5px)",
     SLOT: str = "flex h-12 min-w-[140px] items-center justify-center rounded-[12px] px-4",
     SUMMARY: str = "flex min-h-14 cursor-pointer list-none items-center justify-between gap-4 px-5 py-4 font-semibold [&::-webkit-details-marker]:hidden",
     FOOTER_LINKS: dict[str, list[list[str]]] = {
         "Product": [
             ["/s", "Stocks"],
             ["/compare", "Guides"],
             ["/changelog", "Changelog"],
             ["/api-docs", "Architecture"],
         ],
         "Community": [
             ["/love", "Wall of love"],
             ["/sponsor", "Sponsor"],
             [REPO_URL, "GitHub"],
             [DISCORD_URL, "Discord"],
         ],
         "Company": [["/about", "About"], ["/help", "Help"], ["/terms", "Terms"]],
     },
     # index.html's own description, kept the first time `head` replaces it
     site_description: str = "",
     DISCORD_PATH: str = "M20.317 4.37a19.79 19.79 0 0 0-4.885-1.515.074.074 0 0 0-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 0 0-5.487 0 12.64 12.64 0 0 0-.617-1.25.077.077 0 0 0-.079-.037A19.74 19.74 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057 19.9 19.9 0 0 0 5.993 3.03.078.078 0 0 0 .084-.028 14.09 14.09 0 0 0 1.226-1.994.076.076 0 0 0-.041-.106 13.11 13.11 0 0 1-1.872-.892.077.077 0 0 1-.008-.128 10.2 10.2 0 0 0 .372-.292.074.074 0 0 1 .077-.01c3.928 1.793 8.18 1.793 12.062 0a.074.074 0 0 1 .078.01c.12.098.246.198.373.292a.077.077 0 0 1-.006.127 12.3 12.3 0 0 1-1.873.892.077.077 0 0 0-.041.107c.36.698.772 1.363 1.225 1.993a.076.076 0 0 0 .084.028 19.84 19.84 0 0 0 6.002-3.03.077.077 0 0 0 .032-.055c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.03zM8.02 15.331c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.956-2.419 2.157-2.419 1.211 0 2.176 1.095 2.157 2.42 0 1.333-.956 2.418-2.157 2.418m7.975 0c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.955-2.419 2.157-2.419 1.21 0 2.176 1.095 2.157 2.42 0 1.333-.946 2.418-2.157 2.418";

# One element of <head> found by an attribute: made, given its value, or removed for no value
def put(kind: str, key: str, name: str, value: str, held: str = "content") {
    found: any = document.head.querySelector(f'{kind}[{key}="{name}"]');
    if found and not value {
        found.remove();
    } elif value {
        if not found {
            found = document.createElement(kind);
            found.setAttribute(key, name);
            document.head.appendChild(found);
        }
        Reflect.set(found, held, value);
    }
}

# What a crawler reads of a page: its title, description, canonical URL and JSON-LD. The layout
# calls it for every route, so a page that sets more does so after a crossing, or once mounted late.
def:pub head(title: str, description: str = "", ld: str = "", url: str = "", found: bool = True) {
    meta: any = document.head.querySelector('meta[name="description"]');
    site_description = site_description or meta.content;
    document.title = title;
    put("meta", "name", "description", description or site_description);
    put("meta", "name", "robots", "" if found else "noindex, nofollow");
    put("link", "rel", "canonical", url, "href");
    put("script", "type", "application/ld+json", ld, "text");
}

# Scrolls to the URL's #anchor once the page holding it has shown (`ready`), as a document load would
def:pub use_anchor(ready: bool = True) {
    spot = useLocation().hash;

    can with [spot, ready] entry {
        target = document.getElementById(spot[1:]) if spot and ready else None;
        if target {
            target.scrollIntoView();
        }
    }
}

# A link by where it leads: a route, another site (in a new tab), or an anchor or mailto
def:pub Go(to: str, children: any, **rest: any) -> JsxElement {
    if to.startswith("/") {
        return <Link {to} {...rest}>{children}</Link>;
    }
    if to.startswith("http") {
        return <a href={to} target="_blank" rel="noreferrer" {...rest}>{children}</a>;
    }
    return <a href={to} {...rest}>{children}</a>;
}

# Top of every public page: kicker, one headline, one supporting line, optional actions
def:pub PageHero(kicker: str, title: str, sub: str = "", children: any = None) -> JsxElement {
    return <section className="mx-auto max-w-[1200px] px-5 pt-14 md:pt-20">
        <p className="kicker text-brand-ink">{kicker}</p>
        <h1
            className="mt-3 max-w-3xl text-[40px] font-bold leading-[1.04] tracking-[-0.05em] md:text-[60px]"
        >{title}</h1>
        {<p className="mt-5 max-w-2xl text-[17px] leading-relaxed text-muted-foreground">{sub}</p>
            if sub
            else None}
        {<div className="mt-8 flex flex-wrap gap-2">{children}</div> if children else None}
    </section>;
}

def:pub SectionHead(kicker: str, title: str, sub: str = "") -> JsxElement {
    return <div className="mb-8 max-w-2xl">
        <p className="kicker text-brand-ink">{kicker}</p>
        <h2 className="mt-2 text-[32px] font-bold leading-[1.1] tracking-[-0.04em] md:text-[40px]">
            {title}
        </h2>
        {<p className="mt-3 text-[16px] text-muted-foreground">{sub}</p> if sub else None}
    </div>;
}

# Hatch shell holding one card: icon well, title, short body, optional footer (a link or a pill)
def:pub IconCard(icon: any, title: str, children: any, footer: any = None) -> JsxElement {
    return <div className="hatch">
        <div className="card flex h-full flex-col gap-3 p-5">
            <span className="bento-ico size-9 bg-brand-soft text-brand-ink">
                <@icon className="size-[18px]" />
            </span>
            <h3 className="text-[16px] font-bold tracking-[-0.02em]">{title}</h3>
            <div className="text-[14px] leading-relaxed text-muted-foreground">{children}</div>
            {<div className="mt-auto pt-1">{footer}</div> if footer else None}
        </div>
    </div>;
}

# A closing card: one line of pitch and the button it leads to
def:pub CtaCard(title: str, body: str, to: str, label: str) -> JsxElement {
    return <div className="hatch">
        <div
            className="card flex flex-col items-start justify-between gap-5 p-8 md:flex-row md:items-center"
        >
            <div>
                <h2 className="text-[22px] font-bold tracking-[-0.03em]">{title}</h2>
                <p className="mt-1 max-w-xl text-muted-foreground">{body}</p>
            </div>
            <Go {to} className={CTA}>{label}</Go>
        </div>
    </div>;
}

# Questions that open in place, each [question, answer]. Padding lives on the summary so the
# whole row is the click target, in every browser.
def:pub Faqs(items: list[list[str]], hover: bool = False) -> JsxElement {
    return <div className="hatch">
        <div className="card row-list overflow-hidden">
            {[
                <details key={q[0]} className="group">
                    <summary
                        className={cx(SUMMARY, hover and "text-foreground transition-colors hover:bg-hover/40")}
                    >
                        {q[0]}
                        <ChevronDown
                            className={cx("size-4 flex-none text-faint transition-transform group-open:rotate-180", hover and "duration-200")}
                        />
                    </summary>
                    <p
                        className="max-w-3xl px-5 pb-5 text-[15px] leading-relaxed text-muted-foreground"
                    >{q[1]}</p>
                </details>
                for q in items
            ]}
        </div>
    </div>;
}

# What a public route shows for a slug or ticker that names nothing
def:pub NotFound(title: str) -> JsxElement {
    can with entry {
        head(title, found=False);
    }

    return <section
        className="mx-auto flex min-h-[50vh] max-w-[1200px] items-center justify-center px-5"
    >
        <h1
            className="border-e border-line-strong pe-5 text-[24px] font-medium leading-[49px]"
        >404</h1>
        <p className="ps-5 text-[14px]">This page could not be found.</p>
    </section>;
}

# A link to a sponsor. One with a perk first shows its checkout code; a modified click still just opens the site.
def:pub SponsorLink(sponsor: Sponsor, children: any, **rest: any) -> JsxElement {
    has open: bool = False;
    has copied: bool = False;

    perk = sponsor.perk or Perk("", "");

    async def copy_code {
        try {
            await navigator.clipboard.writeText(perk.code);
            copied = True;
        } except Exception {
            copied = False;
        }
    }

    def clicked(e: any) {
        if perk.code and e.button == 0 and not (e.metaKey or e.ctrlKey or e.shiftKey or e.altKey) {
            e.preventDefault();
            copied = False;
            open = True;
        }
    }

    return <>
        <a
            href={sponsor.url}
            target="_blank"
            rel={"noopener sponsored" if perk.code else "noreferrer"}
            onClick={clicked}
            {...rest}
        >{children}</a>
        <Dialog
            {open}
            onClose={lambda { open = False; }}
            className="grid gap-6 p-6 sm:max-w-[420px]"
        >
            <div className="flex items-center gap-3 pr-8">
                {<img
                    src={sponsor.logo}
                    alt=""
                    className="h-8 w-auto max-w-[140px] object-contain"
                />
                    if sponsor.logo
                    else None}
                <p className="text-[17px] font-bold tracking-[-0.02em]">{sponsor.name}</p>
            </div>
            <div>
                <h2 className="kicker text-brand-ink">An OpenStock perk</h2>
                <p className="mt-2 text-[28px] font-bold tracking-[-0.04em] text-foreground">
                    {perk.discount}
                </p>
                {<p className="mt-1.5 text-[14px] text-muted-foreground">{perk.note}</p>
                    if perk.note
                    else None}
            </div>
            <div className="flex items-stretch gap-2">
                <p
                    className="flex min-w-0 flex-1 items-center justify-center rounded-[12px] bg-page px-4 py-3 font-mono text-[22px] font-bold tracking-[0.06em] text-foreground shadow-[inset_0_0_0_1px_var(--line)]"
                >{perk.code}</p>
                <button
                    type="button"
                    className="btn btn-ghost h-auto min-w-[96px] px-4"
                    onClick={copy_code}
                >{<Check /> if copied else <Copy />}{"Copied" if copied else "Copy"}</button>
            </div>
            <p
                className="text-[14px] leading-relaxed text-muted-foreground"
            >Use this code at checkout. A thank-you for being part of OpenStock.</p>
            <div className="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
                <button
                    type="button"
                    className="btn btn-ghost h-11 px-5"
                    onClick={lambda { open = False; }}
                >Cancel</button>
                <a
                    href={sponsor.url}
                    target="_blank"
                    rel="noopener sponsored"
                    className={CTA}
                    onClick={lambda {
                        navigator.clipboard.writeText(perk.code);
                        open = False;
                    }}
                >
                        Continue to {sponsor.name} <ArrowUpRight /></a>
            </div>
        </Dialog>
    </>;
}

# A sponsor's logo, with its name beside it when the logo is only a mark
def:pub SponsorMark(
    sponsor: Sponsor, logoClassName: str = "h-6 w-auto", nameClassName: str = "font-bold"
) -> JsxElement {
    return <>
        {<img
            src={sponsor.logo}
            alt={"" if sponsor.icon_only else sponsor.name}
            className={logoClassName}
        />
            if sponsor.logo
            else None}
        {<span className={nameClassName}>{sponsor.name}</span>
            if not sponsor.logo or sponsor.icon_only
            else None}
    </>;
}

# Only the Company and Partner tiers include a footer logo. A limited tier shows every free slot,
# an unlimited one a single invite: each open slot is a tier someone can take today.
def:pub SponsorsBand -> JsxElement {
    # Outline, not an inset shadow, so the tier colour also draws over full-bleed banners
    def ring(tier: str, dashed: bool = False) -> dict[str, any] {
        return {
            "outline": f"1px {'dashed' if dashed else 'solid'} {tier_border(tier)}",
            "outlineOffset": -1,
            "backgroundImage": HATCHED if dashed else None,
        };
    }

    return <section aria-labelledby="footer-sponsors" className="flex flex-col gap-8">
        <div className="flex flex-col gap-5 sm:flex-row sm:items-end sm:justify-between sm:gap-8">
            <div className="min-w-0">
                <p className="kicker flex items-center gap-2 text-brand-ink"><span
                    className="live-dot"
                /> Open for sponsors</p>
                <h2
                    id="footer-sponsors"
                    className="mt-2 text-[20px] font-bold tracking-[-0.03em] md:text-[22px]"
                >Keep market data free for everyone.</h2>
            </div>
            <div className="flex shrink-0 flex-wrap gap-2">
                <Link to="/sponsor" className={CTA}>Become a sponsor</Link>
                <a href={MAILTO} className={CTA_GHOST}>Talk with us</a>
            </div>
        </div>
        <div className="flex flex-col gap-2.5">
            <p className="kicker">Current sponsors</p>
            <div className="flex flex-col gap-4">
                {
                    for tier in reversed(SPONSOR_TIERS[2:]) {
                        taken = [s for s in ACTIVE_SPONSORS if s.tier == tier.id];
                        <div key={tier.id} className="flex flex-col gap-1.5">
                            <p
                                className="kicker text-[10px]"
                                style={{"color": TIER_COLOR[tier.id]}}
                            >{tier.name}{" (limited)" if tier.slots else ""}</p>
                            <div className="flex flex-wrap gap-2">
                                {[
                                    <SponsorLink
                                        key={s.name}
                                        sponsor={s}
                                        title={s.name}
                                        style={ring(tier.id)}
                                        className={cx(SLOT, "gap-2 bg-page/60 transition-opacity hover:opacity-90", FOCUS)}
                                    ><SponsorMark sponsor={s} /></SponsorLink>
                                    for s in taken
                                ]}
                                {[
                                    <Link
                                        key={i}
                                        to="/sponsor#tiers"
                                        style={ring(tier.id, True)}
                                        className={cx(SLOT, "text-[13px] font-semibold text-faint transition-colors hover:text-brand-ink", FOCUS)}
                                    >{"Slot open" if tier.slots else "Add yours"}</Link>
                                    for i in range(
                                        max(0, tier.slots - len(taken)) if tier.slots else 1
                                    )
                                ]}
                            </div>
                        </div>
                    }
                }
            </div>
        </div>
    </section>;
}

def:pub SiteFooter -> JsxElement {
    link = cx(
        "rounded-[4px] text-[14px] font-semibold text-muted-foreground transition-colors hover:text-foreground",
        FOCUS,
    );
    social = [
        [REPO_URL, "OpenStock on GitHub", <Github />],
        [
            DISCORD_URL,
            "Open Dev Society on Discord",
            <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                <path d={DISCORD_PATH} />
            </svg>,
        ],
        [
            "https://www.linkedin.com/company/opendevsociety-in/",
            "Open Dev Society on LinkedIn",
            <Linkedin />,
        ],
    ];
    return <footer className="mt-24 border-t border-line bg-side">
        <div className="mx-auto max-w-[1200px] px-5">
            <div className="border-b border-line py-10 md:py-12"><SponsorsBand /></div>
            <div
                className="grid grid-cols-2 gap-x-8 gap-y-10 py-12 lg:grid-cols-[minmax(0,260px)_repeat(3,minmax(0,1fr))] lg:gap-x-16"
            >
                <div className="col-span-2 flex max-w-sm flex-col gap-5 lg:col-span-1">
                    <Link
                        to="/"
                        aria-label="OpenStock home"
                        className={cx("w-fit rounded-[4px]", FOCUS)}
                    >
                        <img
                            src="/assets/images/logo.png"
                            alt="OpenStock"
                            width={132}
                            height={33}
                        />
                    </Link>
                    <p
                        className="text-[14px] leading-relaxed text-muted-foreground"
                    >A free, open-source alternative to expensive market platforms.</p>
                    <ul className="flex items-center gap-1.5">
                        {[
                            <li key={s[1]}>
                                <Go
                                    to={s[0]}
                                    aria-label={s[1]}
                                    className={cx("icon-btn shadow-[inset_0_0_0_1px_var(--line)]", FOCUS)}
                                >{s[2]}</Go>
                            </li>
                            for s in social
                        ]}
                    </ul>
                </div>
                {[
                    <nav key={title} aria-label={title} className="flex flex-col gap-3">
                        <p className="kicker">{title}</p>
                        <ul className="flex flex-col gap-2.5">
                            {[
                                <li key={l[1]}><Go to={l[0]} className={link}>{l[1]}</Go></li>
                                for l in links
                            ]}
                        </ul>
                    </nav>
                    for (title, links) in FOOTER_LINKS.items()
                ]}
            </div>
            <div
                className="flex flex-col gap-4 border-t border-line py-6 pb-8 sm:flex-row sm:items-center sm:justify-between"
            >
                <p className="text-[13px] text-faint">© {new(
                    Date
                ).getFullYear()} Open Dev Society · AGPL-3.0</p>
                <Go
                    to="https://opendevsociety.org"
                    className={cx("inline-flex w-fit shrink-0 items-center gap-2 whitespace-nowrap rounded-[10px] px-3 py-1.5 text-[13px] font-semibold text-muted-foreground shadow-[inset_0_0_0_1px_var(--line)] transition-colors hover:text-foreground", FOCUS)}
                ><img
                    src="/assets/icons/odsLogo.svg"
                    alt=""
                    width={22}
                    height={22}
                    className="size-[22px]"
                />
                    An Open Dev Society initiative
                </Go>
            </div>
        </div>
    </footer>;
}

# Always shows the latest release. The whole strip opens a short summary; the full history is on /changelog.
# The release notes stay English; `loc` is the language of the chrome around them ("en" on the public site).
def:pub UpdateBanner(loc: str = "en") -> JsxElement {
    has open: bool = False;

    latest = RELEASES[0];
    return <>
        <button
            type="button"
            onClick={lambda { open = True; }}
            className="group flex w-full items-center gap-2.5 rounded-[12px] bg-brand-soft/50 py-1.5 ps-2 pe-3 text-start text-[13px] shadow-[inset_0_0_0_1px_oklch(0.8_0.13_176/0.25)] transition-colors hover:bg-brand-soft/80"
        >
            <span className="pill is-brand shrink-0">{tr(loc, "UpdateBanner.new")}</span>
            {#* dir=auto clips the English notes at their own end on the Arabic page *#}
            <span dir="auto" className="min-w-0 flex-1 truncate rtl:text-right">
                <span className="font-semibold text-foreground">{latest.title}:</span>
                {" "}
                <span className="text-muted-foreground">{latest.summary}</span>
            </span>
            <span className="flex shrink-0 items-center gap-1 font-semibold text-brand-ink">
                <span className="max-sm:hidden">{tr(loc, "UpdateBanner.seeWhatsNew")}</span>
                <ArrowRight className="size-3.5 transition-transform group-hover:translate-x-0.5" />
            </span>
        </button>
        <Dialog {open} onClose={lambda { open = False; }} className="grid gap-4 p-6 sm:max-w-md">
            <div>
                <p className="kicker text-brand-ink">{latest.date}</p>
                <h2 className="mt-1.5 text-[22px] font-bold leading-none tracking-[-0.03em]">
                    {latest.title}
                </h2>
                <p className="mt-1 text-[14px] text-muted-foreground">{latest.summary}.</p>
            </div>
            <ul className="flex flex-col gap-2.5 text-[14px] leading-relaxed">
                {[
                    <li key={item} className="flex gap-2.5">
                        <Check className="mt-1 size-4 flex-none text-brand-ink" />
                        <span>{item}</span>
                    </li>
                    for item in latest.highlights
                ]}
            </ul>
            <Link
                to="/changelog"
                onClick={lambda { open = False; }}
                className="btn btn-primary h-10 w-full"
            >{tr(loc, "UpdateBanner.fullChangelog")} <ArrowRight /></Link>
        </Dialog>
    </>;
}

# The public site's header and footer around a page. The header always shows the signed-out
# buttons: /sign-in and /sign-up send a signed-in visitor on to /dashboard.
def:pub MarketingLayout(children: any) -> JsxElement {
    has repo: RepoStats | None = None;

    async can with entry {
        repo = await repo_stats();
    }

    return <div className="min-h-dvh bg-page">
        <div className="mx-auto max-w-[1200px] px-4 pt-3 sm:px-5"><UpdateBanner /></div>
        <header
            className="sticky top-0 z-40 border-b border-transparent bg-page/80 backdrop-blur-md"
        >
            <div
                className="mx-auto flex h-16 max-w-[1200px] items-center gap-3 px-4 sm:gap-6 sm:px-5"
            >
                <Link to="/" aria-label="OpenStock home" className="shrink-0">
                    <img
                        src="/assets/images/logo.png"
                        alt="OpenStock"
                        width={140}
                        height={35}
                        className="h-auto w-[104px] sm:w-[140px]"
                    />
                </Link>
                {#* Not at md: the links plus the buttons are ~830px wide, past a 768px tablet *#}
                <nav className="hidden items-center gap-1 lg:flex">
                    {[
                        <Link key={l[0]} to={l[0]} className="side-item h-8 font-semibold">
                            {l[1]}
                        </Link>
                        for l in [
                            ["/#inside", "Product"],
                            ["/#data", "Data"],
                            ["/#self-host", "Self-host"],
                            ["/about", "About"],
                        ]
                    ]}
                    <Link
                        to="/sponsor"
                        className="side-item h-8 gap-2 font-semibold text-brand-ink hover:text-brand-ink"
                    ><span className="live-dot" /> Sponsor</Link>
                </nav>
                <div className="ml-auto flex items-center gap-1.5 sm:gap-2">
                    <Go
                        to={REPO_URL}
                        className="btn btn-ghost hidden h-9 px-3 sm:inline-flex"
                        aria-label="OpenStock on GitHub"
                    >
                        <Github />
                        {<span className="num">{format_count(repo.stars)}</span> if repo else None}
                    </Go>
                    <Link
                        to="/sign-in"
                        className="btn h-9 px-2 text-muted-foreground hover:text-foreground sm:px-3"
                    >Sign in</Link>
                    <Link
                        to="/sign-up"
                        className="btn btn-primary h-9 px-3 sm:px-[14px]"
                    >Get started</Link>
                </div>
            </div>
        </header>
        <main>{children}</main>
        <SiteFooter />
    </div>;
}
