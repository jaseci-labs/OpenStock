"""Everything sponsor-related lives here: edit this file when someone starts or stops sponsoring.
Perks only name placements the code actually renders (README, sponsor wall, site footer,
landing page, in-app sidebar), so the page never promises something the site doesn't do."""

# A checkout code shown in a modal before leaving OpenStock.
obj Perk {
    has code: str,
        discount: str,
        note: str = "";
}

# logo: white/transparent, in public/, for dark surfaces. blurb: one line for the floating banner
# on the landing page. icon_only: the logo is a mark without the name, so the name is shown beside
# it. banner: sponsor-supplied, shown whole in the sponsor band instead of the logo.
obj Sponsor {
    has name: str,
        url: str,
        logo: str,
        tier: str,
        blurb: str = "",
        perk: Perk | None = None,
        icon_only: bool = False,
        banner: str = "",
        period: str = "";
}

obj Tier {
    has id: str,
        name: str,
        monthly: int,
        blurb: str,
        perks: list[str],
        slots: int = 0,
        featured: bool = False;
}

# One border colour per tier, shared by the tier cards on /sponsor and the sponsor band.
glob TIER_COLOR: dict[str, str] = {
    "backer": "oklch(0.72 0.11 50)",
    "supporter": "oklch(0.72 0.12 250)",
    "company": "oklch(0.8 0.13 176)",
    "partner": "oklch(0.72 0.14 300)",
};

# Registered accounts on the hosted app (13K+ as of September 2026). Update from the user collection count.
glob REGISTERED_USERS: str = "13,000+";

# Partners share the app sidebar; the Partner tier sells exactly this many slots.
glob SIDEBAR_SPONSOR_SLOTS: int = 3;

glob SPONSOR_TIERS: list[Tier] = [
    Tier(
        "backer",
        "Backer",
        5,
        "For people who use OpenStock and want it to stay free.",
        ["Your name in the README sponsor list", "Our thanks, every month"],
    ),
    Tier(
        "supporter",
        "Supporter",
        25,
        "For regulars who want to be seen backing open source.",
        ["Everything in Backer", "Name and avatar on the sponsor wall", "Listed on this page"],
    ),
    Tier(
        "company",
        "Company",
        100,
        "For teams and products that reach developers and investors.",
        [
            "Logo in the footer of every public page",
            "Logo in the README",
            "Logo on this page, linked to your site",
        ],
        featured=True,
    ),
    Tier(
        "partner",
        "Partner",
        500,
        "The most visible spots in OpenStock, limited to three.",
        [
            "Everything in Company",
            f"One of three sponsor slots in the app sidebar, seen by {REGISTERED_USERS} registered users",
            "Logo on the landing page",
        ],
        slots=SIDEBAR_SPONSOR_SLOTS,
    ),
];

glob PROXY_SELLER_URL: str = "https://proxy-seller.com/?partner=0PC6QUN0HW8FI0";

glob ACTIVE_SPONSORS: list[Sponsor] = [
    Sponsor(
        "Orbit",
        "https://github.com/diip3sh/orbit",
        "/assets/icons/orbit.png",
        "partner",
        "Free, open-source screen recorder and video editor for macOS.",
        icon_only=True,
    ),
    Sponsor(
        "Proxy-Seller",
        PROXY_SELLER_URL,
        "/assets/images/proxy-seller-logo.png",
        "partner",
        "47M+ residential IPs across 220+ locations, with 99.7% uptime and 24/7 support. 15% off with promo code RAVI.",
        Perk("RAVI", "15% off"),
    ),
    Sponsor(
        "Swiftproxy",
        "https://www.swiftproxy.net/?ref=OpenStock",
        "/assets/images/swiftproxy-logo.png",
        "company",
        "90M+ residential IPs across 220+ locations, with free testing and 10% off using code PROXY90.",
        Perk("PROXY90", "10% off", "Free testing is also available."),
    ),
];

glob PREVIOUS_SPONSORS: list[Sponsor] = [
    Sponsor("Atlas Cloud", "https://www.atlascloud.ai", "/assets/icons/atlascloud.svg", "partner"),
    Sponsor(
        "Siray.ai", "https://www.siray.ai", "/assets/icons/siray.svg", "partner", period="2026"
    ),
    Sponsor(
        "RapidProxy",
        "https://www.rapidproxy.io",
        "/assets/icons/rapidproxy.png",
        "company",
        period="2026",
    ),
];

# People who used to sponsor publicly on GitHub (private sponsors stay anonymous), GitHub login
# to name. Avatars come from GitHub.
glob PREVIOUS_SUPPORTERS: dict[str, str] = {
    "jonasgunklach": "Jonas Gunklach",
    "xlab-nyc": "Dan Sellars",
    "Mangolito": "Mangolito",
};

# Counted from GitHub Sponsors; individual sponsors stay anonymous unless they sponsor publicly.
glob SPONSOR_GOAL: dict[str, int] = {"target": 1000, "current": 1};

glob SPONSOR_GOAL_LABEL: str = "monthly sponsors";

glob SPONSOR_CONTACT_EMAIL: str = "opendevsociety@gmail.com";

# Who receives sponsorships today (GitHub Sponsors is on the founder's personal account).
glob SPONSOR_RECIPIENT: dict[str, str] = {
    "name": "Ravi Pratap Singh",
    "handle": "ravixalgorithm",
    "role": "founder of Open Dev Society",
};

# Where sponsorship money goes, label to detail. No line has a known monthly bill yet, so the
# page shows no amounts.
glob FUNDING_USES: dict[str, str] = {
    "Hosting": "Vercel serves the app and site. Our traffic is past the free tier.",
    "Market data": "Finnhub keys, so quotes stay fast for everyone and OpenStock Cloud can go live.",
    "Database": "MongoDB Atlas for accounts, watchlists and alerts.",
    "AI and email": "Gemini for welcome emails and the weekly digest, plus email delivery.",
    "Maintenance": "Time to review community pull requests, fix bugs and ship features.",
};

def tier_border(tier: str) -> str {
    return f"color-mix(in oklch, {TIER_COLOR[tier]} 55%, transparent)";
}

def tier_name(tier: str) -> str {
    return {t.id: t.name for t in SPONSOR_TIERS}.get(tier, "Sponsor");
}

def sidebar_sponsors -> list[Sponsor] {
    return [s for s in ACTIVE_SPONSORS if s.tier == "partner"][:SIDEBAR_SPONSOR_SLOTS];
}
