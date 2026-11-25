"""The public site's frame: header, footer, sponsors, the update banner and the page furniture."""
import from "@jac/runtime" { Link }
import from "lucide-react" { ArrowRight, ArrowUpRight, Check, Copy, Github, Linkedin }

glob REPO_URL: str = "https://github.com/Open-Dev-Society/OpenStock",
     DISCORD_URL: str = "https://discord.gg/JkJ8kfxgxB",
     GOOD_FIRST_ISSUES_URL: str = REPO_URL + "/issues?q=is%3Aopen+label%3A%22good+first+issue%22",
     CONTACT_EMAIL: str = "opendevsociety@gmail.com",
     # What the banner and its modal show: the newest entry of the changelog
     LATEST_RELEASE: dict[str, any] = {
         "id": "2026-11-22",
         "date": "22 Nov 2026",
         "title": "Late November update",
         "summary": "OpenStock in Polish and Arabic, named watchlists, moving-average alerts, pages that fit your phone, and safer sign-in",
         "highlights": [
             "The app in Polish and Arabic, laid out right to left in Arabic.",
             "Named watchlists: up to 10 lists of 50 stocks.",
             "Alerts when a price crosses its 20 to 200-day moving average.",
             "The Technicals gauge works again for US stocks.",
             "Every page fits phones and tablets, from 320px up.",
             "Fixes to password reset, signed-out devices and sign-up limits.",
         ],
     },
     # Edit these when someone starts or stops sponsoring. `slots` limits a tier (partners share the app sidebar).
     SPONSOR_TIERS: dict[str, dict[str, any]] = {
         "backer": {"name": "Backer", "color": "oklch(0.72 0.11 50)", "slots": 0},
         "supporter": {"name": "Supporter", "color": "oklch(0.72 0.12 250)", "slots": 0},
         "company": {"name": "Company", "color": "oklch(0.8 0.13 176)", "slots": 0},
         "partner": {"name": "Partner", "color": "oklch(0.72 0.14 300)", "slots": 3},
     },
     # `iconOnly`: the logo is a mark without the name. `perk`: a checkout code shown before leaving.
     ACTIVE_SPONSORS: list[dict[str, any]] = [
         {
             "name": "Orbit",
             "url": "https://github.com/diip3sh/orbit",
             "logo": "/assets/icons/orbit.png",
             "iconOnly": True,
             "tier": "partner",
             "blurb": "Free, open-source screen recorder and video editor for macOS.",
         },
         {
             "name": "Proxy-Seller",
             "url": "https://proxy-seller.com/?partner=0PC6QUN0HW8FI0",
             "logo": "/assets/images/proxy-seller-logo.png",
             "tier": "partner",
             "blurb": "47M+ residential IPs across 220+ locations, with 99.7% uptime and 24/7 support. 15% off with promo code RAVI.",
             "perk": {"code": "RAVI", "discount": "15% off"},
         },
         {
             "name": "Swiftproxy",
             "url": "https://www.swiftproxy.net/?ref=OpenStock",
             "logo": "/assets/images/swiftproxy-logo.png",
             "tier": "company",
             "blurb": "90M+ residential IPs across 220+ locations, with free testing and 10% off using code PROXY90.",
             "perk": {
                 "code": "PROXY90",
                 "discount": "10% off",
                 "note": "Free testing is also available.",
             },
         },
     ],
     PREVIOUS_SPONSORS: list[dict[str, any]] = [
         {
             "name": "Atlas Cloud",
             "url": "https://www.atlascloud.ai",
             "logo": "/assets/icons/atlascloud.svg",
             "tier": "partner",
         },
         {
             "name": "Siray.ai",
             "url": "https://www.siray.ai",
             "logo": "/assets/icons/siray.svg",
             "tier": "partner",
             "period": "2026",
         },
         {
             "name": "RapidProxy",
             "url": "https://www.rapidproxy.io",
             "logo": "/assets/icons/rapidproxy.png",
             "tier": "company",
             "period": "2026",
         },
     ],
     # People who used to sponsor publicly on GitHub: [name, login]
     PREVIOUS_SUPPORTERS: list[list[str]] = [
         ["Jonas Gunklach", "jonasgunklach"],
         ["Dan Sellars", "xlab-nyc"],
         ["Mangolito", "Mangolito"],
     ],
     FOCUS: str = "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand/70 focus-visible:ring-offset-2 focus-visible:ring-offset-side",
     HATCHED: str = "repeating-linear-gradient(-45deg, oklch(0.4 0.01 95 / 0.22) 0 1px, transparent 1px 5px)",
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
     DISCORD_PATH: str = "M20.317 4.37a19.79 19.79 0 0 0-4.885-1.515.074.074 0 0 0-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 0 0-5.487 0 12.64 12.64 0 0 0-.617-1.25.077.077 0 0 0-.079-.037A19.74 19.74 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057 19.9 19.9 0 0 0 5.993 3.03.078.078 0 0 0 .084-.028 14.09 14.09 0 0 0 1.226-1.994.076.076 0 0 0-.041-.106 13.11 13.11 0 0 1-1.872-.892.077.077 0 0 1-.008-.128 10.2 10.2 0 0 0 .372-.292.074.074 0 0 1 .077-.01c3.928 1.793 8.18 1.793 12.062 0a.074.074 0 0 1 .078.01c.12.098.246.198.373.292a.077.077 0 0 1-.006.127 12.3 12.3 0 0 1-1.873.892.077.077 0 0 0-.041.107c.36.698.772 1.363 1.225 1.993a.076.076 0 0 0 .084.028 19.84 19.84 0 0 0 6.002-3.03.077.077 0 0 0 .032-.055c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.03zM8.02 15.331c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.956-2.419 2.157-2.419 1.211 0 2.176 1.095 2.157 2.42 0 1.333-.956 2.418-2.157 2.418m7.975 0c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.955-2.419 2.157-2.419 1.21 0 2.176 1.095 2.157 2.42 0 1.333-.946 2.418-2.157 2.418";

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

# A link to a sponsor. One with a perk first shows its checkout code; a modified click still just opens the site.
def:pub SponsorLink(sponsor: dict[str, any], children: any, **rest: any) -> JsxElement {
    has open: bool = False;
    has copied: bool = False;

    perk: any = sponsor.get("perk");

    async def copy_code {
        try {
            await navigator.clipboard.writeText(perk["code"]);
            copied = True;
        } except Exception {
            copied = False;
        }
    }

    def clicked(e: any) {
        if perk and e.button == 0 and not (e.metaKey or e.ctrlKey or e.shiftKey or e.altKey) {
            e.preventDefault();
            copied = False;
            open = True;
        }
    }

    return <>
        <a
            href={sponsor["url"]}
            target="_blank"
            rel={"noopener sponsored" if perk else "noreferrer"}
            onClick={clicked}
            {...rest}
        >{children}</a>
        {<Dialog
            {open}
            onClose={lambda { open = False; }}
            className="grid gap-6 p-6 sm:max-w-[420px]"
        >
            <div className="flex items-center gap-3 pr-8">
                {<img
                    src={sponsor["logo"]}
                    alt=""
                    className="h-8 w-auto max-w-[140px] object-contain"
                />
                    if sponsor.get("logo")
                    else None}
                <p className="text-[17px] font-bold tracking-[-0.02em]">{sponsor["name"]}</p>
            </div>
            <div>
                <h2 className="kicker text-brand-ink">An OpenStock perk</h2>
                <p className="mt-2 text-[28px] font-bold tracking-[-0.04em] text-foreground">
                    {perk["discount"]}
                </p>
                {<p className="mt-1.5 text-[14px] text-muted-foreground">{perk["note"]}</p>
                    if perk.get("note")
                    else None}
            </div>
            <div className="flex items-stretch gap-2">
                <p
                    className="flex min-w-0 flex-1 items-center justify-center rounded-[12px] bg-page px-4 py-3 font-mono text-[22px] font-bold tracking-[0.06em] text-foreground shadow-[inset_0_0_0_1px_var(--line)]"
                >{perk["code"]}</p>
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
                    href={sponsor["url"]}
                    target="_blank"
                    rel="noopener sponsored"
                    className="btn btn-primary h-11 px-5 text-[15px]"
                    onClick={lambda {
                        navigator.clipboard.writeText(perk["code"]);
                        open = False;
                    }}
                >
                        Continue to {sponsor["name"]} <ArrowUpRight /></a>
            </div>
        </Dialog>
            if perk
            else None}
    </>;
}

# A sponsor's logo, with its name beside it when the logo is only a mark
def:pub SponsorMark(
    sponsor: dict[str, any], logoClassName: str = "h-6 w-auto", nameClassName: str = "font-bold"
) -> JsxElement {
    logo = sponsor.get("logo");
    return <>
        {<img
            src={logo}
            alt={"" if sponsor.get("iconOnly") else sponsor["name"]}
            className={logoClassName}
        />
            if logo
            else None}
        {<span className={nameClassName}>{sponsor["name"]}</span>
            if not logo or sponsor.get("iconOnly")
            else None}
    </>;
}

# Only the Company and Partner tiers include a footer logo. A limited tier shows every free slot,
# an unlimited one a single invite: each open slot is a tier someone can take today.
def:pub SponsorsBand -> JsxElement {
    def ring(tier: str, dashed: bool = False) -> dict[str, any] {
        color = SPONSOR_TIERS[tier]["color"];
        # Outline, not an inset shadow, so the tier colour also draws over full-bleed banners
        return {
            "outline": f"1px {'dashed' if dashed else 'solid'} color-mix(in oklch, {color} 55%, transparent)",
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
                <Link
                    to="/sponsor"
                    className="btn btn-primary h-11 px-5 text-[15px]"
                >Become a sponsor</Link>
                <a
                    href={f"mailto:{CONTACT_EMAIL}?subject=Sponsoring%20OpenStock"}
                    className="btn btn-ghost h-11 px-5 text-[15px]"
                >Talk with us</a>
            </div>
        </div>
        <div className="flex flex-col gap-2.5">
            <p className="kicker">Current sponsors</p>
            <div className="flex flex-col gap-4">
                {
                    for tier in ["partner", "company"] {
                        slots = SPONSOR_TIERS[tier]["slots"];
                        taken = [s for s in ACTIVE_SPONSORS if s["tier"] == tier];
                        <div key={tier} className="flex flex-col gap-1.5">
                            <p
                                className="kicker text-[10px]"
                                style={{"color": SPONSOR_TIERS[tier]["color"]}}
                            >{SPONSOR_TIERS[tier]["name"]}{" (limited)" if slots else ""}</p>
                            <div className="flex flex-wrap gap-2">
                                {[
                                    <SponsorLink
                                        key={s["name"]}
                                        sponsor={s}
                                        title={s["name"]}
                                        style={ring(tier)}
                                        className={cx("flex h-12 min-w-[140px] items-center justify-center gap-2 rounded-[12px] bg-page/60 px-4 transition-opacity hover:opacity-90", FOCUS)}
                                    ><SponsorMark sponsor={s} /></SponsorLink>
                                    for s in taken
                                ]}
                                {[
                                    <Link
                                        key={i}
                                        to="/sponsor#tiers"
                                        style={ring(tier, True)}
                                        className={cx("flex h-12 min-w-[140px] items-center justify-center rounded-[12px] px-4 text-[13px] font-semibold text-faint transition-colors hover:text-brand-ink", FOCUS)}
                                    >{"Slot open" if slots else "Add yours"}</Link>
                                    for i in range(max(0, slots - len(taken)) if slots else 1)
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
                                <a
                                    href={s[0]}
                                    target="_blank"
                                    rel="noreferrer"
                                    aria-label={s[1]}
                                    className={cx("icon-btn shadow-[inset_0_0_0_1px_var(--line)]", FOCUS)}
                                >{s[2]}</a>
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
                                <li key={l[1]}>
                                    {<a
                                        href={l[0]}
                                        target="_blank"
                                        rel="noreferrer"
                                        className={link}
                                    >{l[1]}</a>
                                        if l[0].startswith("http")
                                        else <Link to={l[0]} className={link}>{l[1]}</Link>}
                                </li>
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
                <a
                    href="https://opendevsociety.org"
                    target="_blank"
                    rel="noreferrer"
                    className={cx("inline-flex w-fit shrink-0 items-center gap-2 whitespace-nowrap rounded-[10px] px-3 py-1.5 text-[13px] font-semibold text-muted-foreground shadow-[inset_0_0_0_1px_var(--line)] transition-colors hover:text-foreground", FOCUS)}
                ><img
                    src="/assets/icons/odsLogo.svg"
                    alt=""
                    width={22}
                    height={22}
                    className="size-[22px]"
                />
                    An Open Dev Society initiative
                </a>
            </div>
        </div>
    </footer>;
}

# Always shows the latest release. The whole strip opens a short summary; the full history is on /changelog.
# The release notes stay English; `loc` is the language of the chrome around them ("en" on the public site).
def:pub UpdateBanner(loc: str = "en") -> JsxElement {
    has open: bool = False;

    return <>
        <button
            type="button"
            onClick={lambda { open = True; }}
            className="group flex w-full items-center gap-2.5 rounded-[12px] bg-brand-soft/50 py-1.5 ps-2 pe-3 text-start text-[13px] shadow-[inset_0_0_0_1px_oklch(0.8_0.13_176/0.25)] transition-colors hover:bg-brand-soft/80"
        >
            <span className="pill is-brand shrink-0">{tr(loc, "UpdateBanner.new")}</span>
            {#* dir=auto clips the English notes at their own end on the Arabic page *#}
            <span dir="auto" className="min-w-0 flex-1 truncate rtl:text-right">
                <span className="font-semibold text-foreground">{LATEST_RELEASE["title"]}:</span>
                {" "}
                <span className="text-muted-foreground">{LATEST_RELEASE["summary"]}</span>
            </span>
            <span className="flex shrink-0 items-center gap-1 font-semibold text-brand-ink">
                <span className="max-sm:hidden">{tr(loc, "UpdateBanner.seeWhatsNew")}</span>
                <ArrowRight className="size-3.5 transition-transform group-hover:translate-x-0.5" />
            </span>
        </button>
        <Dialog {open} onClose={lambda { open = False; }} className="grid gap-4 p-6 sm:max-w-md">
            <div>
                <p className="kicker text-brand-ink">{LATEST_RELEASE["date"]}</p>
                <h2 className="mt-1.5 text-[22px] font-bold leading-none tracking-[-0.03em]">
                    {LATEST_RELEASE["title"]}
                </h2>
                <p
                    className="mt-1 text-[14px] text-muted-foreground"
                >{LATEST_RELEASE["summary"]}.</p>
            </div>
            <ul className="flex flex-col gap-2.5 text-[14px] leading-relaxed">
                {[
                    <li key={item} className="flex gap-2.5">
                        <Check className="mt-1 size-4 flex-none text-brand-ink" />
                        <span>{item}</span>
                    </li>
                    for item in LATEST_RELEASE["highlights"]
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
    has stars: int = 0;

    async can with entry {
        stars = await repo_stars();
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
                        <a key={l[0]} href={l[0]} className="side-item h-8 font-semibold">{l[1]}</a>
                        for l in [
                            ["/#inside", "Product"],
                            ["/#data", "Data"],
                            ["/#self-host", "Self-host"],
                        ]
                    ]}
                    <Link to="/about" className="side-item h-8 font-semibold">About</Link>
                    <Link
                        to="/sponsor"
                        className="side-item h-8 gap-2 font-semibold text-brand-ink hover:text-brand-ink"
                    ><span className="live-dot" /> Sponsor</Link>
                </nav>
                <div className="ml-auto flex items-center gap-1.5 sm:gap-2">
                    <a
                        href={REPO_URL}
                        target="_blank"
                        rel="noreferrer"
                        className="btn btn-ghost hidden h-9 px-3 sm:inline-flex"
                        aria-label="OpenStock on GitHub"
                    >
                        <Github />
                        {<span className="num">
                            {new(
                                Intl.NumberFormat,
                                "en-US",
                                {"notation": "compact", "maximumFractionDigits": 1},
                            ).format(stars)}
                        </span>
                            if stars
                            else None}
                    </a>
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
