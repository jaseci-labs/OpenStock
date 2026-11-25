"""The public SEO surface: the US ticker index, EDGAR company facts, JSON-LD, sitemap.xml,
robots.txt and the GitHub repo numbers. Nothing here reads a price quote."""
import json;
import os;
import threading;
import time;
import from urllib.parse { unquote }

# SEC fair-access rules: https://www.sec.gov/os/accessing-edgar-data
# Declare a User-Agent with a contact address, and stay under 10 requests per second.
glob SEC_USER_AGENT: str = "OpenStock (opendevsociety@gmail.com)";

# Each in order of preference, so a 10-K wins over a 10-K/A filed after it.
glob ANNUAL_FORMS: list[str] = ["10-K", "20-F", "40-F", "10-K/A", "20-F/A", "40-F/A"],
     QUARTERLY_FORMS: list[str] = ["10-Q", "10-Q/A"];

glob STATES: dict[str, str] = {row[:2]: row[3:] for row in """
AL Alabama, AK Alaska, AZ Arizona, AR Arkansas, CA California, CO Colorado, CT Connecticut,
DE Delaware, DC District of Columbia, FL Florida, GA Georgia, HI Hawaii, ID Idaho, IL Illinois,
IN Indiana, IA Iowa, KS Kansas, KY Kentucky, LA Louisiana, ME Maine, MD Maryland,
MA Massachusetts, MI Michigan, MN Minnesota, MS Mississippi, MO Missouri, MT Montana,
NE Nebraska, NV Nevada, NH New Hampshire, NJ New Jersey, NM New Mexico, NY New York,
NC North Carolina, ND North Dakota, OH Ohio, OK Oklahoma, OR Oregon, PA Pennsylvania,
RI Rhode Island, SC South Carolina, SD South Dakota, TN Tennessee, TX Texas, UT Utah, VT Vermont,
VA Virginia, WA Washington, WV West Virginia, WI Wisconsin, WY Wyoming
""".replace(",\n", ", ").strip().split(", ")};

# /__jac/ is where this app's endpoints are; /api/ is where the Next.js app's were.
glob ROBOTS_ALLOW: list[str] = ["/", "/s", "/s/", "/compare", "/compare/"],
     ROBOTS_DISALLOW: list[str] = "/api/ /__jac/ /dashboard /watchlist /profile /stocks /stocks/ /sign-in /sign-up /forgot-password /reset-password".split();

# Sorted by symbol. Regenerated with tools/build_tickers.jac.
glob TICKERS: list[Ticker] = load_tickers(),
     BY_SYMBOL: dict[str, Ticker] = {t.symbol: t for t in TICKERS},
     BY_SECTOR: dict[str, list[Ticker]] = {
         s: [t for t in TICKERS if t.sector == s]
         for s in sorted({t.sector for t in TICKERS})
     };

# sitemap.xml by origin: it is the same text until BETTER_AUTH_URL changes, and building it is the
# costliest thing a crawler asks for.
glob sitemaps: dict[str, str] = {};

# EDGAR answers are kept 12 hours and failures 10 minutes, by CIK: (expires, company).
glob edgar_lock: threading.Lock = threading.Lock(),
     edgar_cache: dict[str, tuple[float, EdgarCompany | None]] = {},
     edgar_next: float = 0.0,
     repo_cache: tuple[float, RepoStats | None] = (0.0, None);

def load_tickers -> list[Ticker] {
    with open(os.environ.get("US_TICKERS_FILE", "data/us-tickers.json")) as f {
        # The file's one camelCase key is the one field named otherwise here.
        rows: list[dict[str, any]] = json.load(f)["tickers"];
    }
    for r in rows {
        r["sub_industry"] = r.pop("subIndustry");
    }
    return [Ticker(**r) for r in rows];
}

"""Canonical origin for sitemap, robots and meta: BETTER_AUTH_URL, the app's public URL, read
as the app runs so a deployment sets it without a rebuild."""
def:pub site_url -> str {
    return os.environ.get("BETTER_AUTH_URL", "").strip().rstrip("/") or "http://localhost:8000";
}

def:pub tickers -> list[Ticker] {
    return TICKERS;
}

"""Every ticker under its sector, sectors and symbols both in order."""
def:pub tickers_by_sector -> dict[str, list[Ticker]] {
    return BY_SECTOR;
}

"""The ticker a URL segment names, in any case, percent-encoded or not, BRK.B or BRK-B."""
def:pub find_ticker(raw: str) -> Ticker | None {
    symbol = unquote(raw.strip().upper());
    return BY_SYMBOL.get(symbol) or BY_SYMBOL.get(symbol.replace("-", "."));
}

def:pub ticker_page(raw: str) -> TickerPage | None {
    t = find_ticker(raw);
    if t is None {
        return None;
    }
    i = TICKERS.index(t);
    origin = site_url();
    (url, crumb) = (origin + ticker_path(t.symbol), f"{t.name} ({t.symbol})");
    intro = ticker_intro(t);
    title = f"{crumb} stock chart and SEC filings";
    trail = [("OpenStock", f"{origin}/"), ("US stocks", f"{origin}/s")];
    trail += [(t.sector, f"{origin}/s#{sector_anchor(t.sector)}"), (crumb, url)];
    company = company_browse_url(t.cik);
    corp = ld("Corporation", name=t.name, tickerSymbol=t.symbol, url=company, industry=t.sector);
    webpage = ld("WebPage", name=title, description=intro, url=url, isPartOf=website(origin));
    # Same sector: the 8 that follow it in symbol order, wrapping round to those before.
    peers = [o for o in TICKERS[i + 1:] + TICKERS[:i] if o.sector == t.sector][:8];
    prev = TICKERS[i - 1] if i > 0 else None;
    after = TICKERS[i + 1] if i + 1 < len(TICKERS) else None;
    graph_ld = json_ld(breadcrumbs(trail), corp, webpage);
    return TickerPage(t, url, title, intro, peers, prev, after, graph_ld);
}

def ld(kind: str, **props: any) -> dict[str, any] {
    return {"@type": kind, **props};
}

def website(origin: str) -> dict[str, any] {
    return ld("WebSite", name="OpenStock", url=origin);
}

def breadcrumbs(trail: list[tuple[str, str]]) -> dict[str, any] {
    items = [ld("ListItem", position=i + 1, name=c[0], item=c[1]) for (i, c) in enumerate(trail)];
    return ld("BreadcrumbList", itemListElement=items);
}

"""A schema.org @graph as the text of a <script type="application/ld+json">: `<` is escaped so
no string in it can close the script element."""
def json_ld(*nodes: dict[str, any]) -> str {
    doc = {"@context": "https://schema.org", "@graph": list(nodes)};
    return json.dumps(doc).replace("<", "\\u003c");
}

"""The JSON-LD of /s, the stock directory."""
def:pub directory_ld -> str {
    origin = site_url();
    about = directory_description(len(TICKERS));
    page = ld("CollectionPage", name=DIRECTORY_TITLE, description=about, url=f"{origin}/s");
    page["isPartOf"] = website(origin);
    return json_ld(page);
}

"""The JSON-LD of /compare/<slug>, or "" for a slug that is no guide."""
def:pub guide_ld(slug: str) -> str {
    guide = find_guide(slug);
    if guide is None {
        return "";
    }
    origin = site_url();
    url = f"{origin}/compare/{guide.slug}";
    trail = [("OpenStock", f"{origin}/"), ("Guides", f"{origin}/compare"), (guide.title, url)];
    faqs = [
        ld("Question", name=f.question, acceptedAnswer=ld("Answer", text=f.answer))
        for f in guide.faqs
    ];
    article = ld("Article", headline=guide.title, description=guide.description, url=url);
    article["author"] = ld("Organization", name="Open Dev Society", url=REPO_URL.rsplit("/", 1)[0]);
    article["publisher"] = ld("Organization", name="OpenStock", url=origin);
    return json_ld(breadcrumbs(trail), ld("FAQPage", mainEntity=faqs), article);
}

def filing_url(cik: str, accession: str, document: str) -> str {
    return f"https://www.sec.gov/Archives/edgar/data/{int(cik)}/{accession.replace('-', '')}/{document}";
}

"""0926 as "September 26", and "" for anything that is no month and day."""
def format_fiscal_year_end(mmdd: str) -> str {
    if len(mmdd) != 4 or not mmdd.isdigit() {
        return "";
    }
    (month, day) = (int(mmdd[:2]), int(mmdd[2:]));
    return f"{MONTHS[month - 1]} {day}" if 1 <= month <= 12 and 1 <= day <= 31 else "";
}

"""The latest filing of the first of `forms` that EDGAR's recent index has whole."""
def pick_filing(recent: dict[str, any], forms: list[str], cik: str) -> Filing | None {
    filed: list[str] = recent.get("form", []);
    for form in forms {
        if form in filed {
            i = filed.index(form);
            (accession, document) = (recent["accessionNumber"][i], recent["primaryDocument"][i]);
            if accession and document and recent["filingDate"][i] {
                return Filing(form, recent["filingDate"][i], filing_url(cik, accession, document));
            }
        }
    }
    return None;
}

def parse_submissions(cik: str, body: dict[str, any]) -> EdgarCompany {
    recent: dict[str, any] = body.get("filings", {}).get("recent", {});
    state: str = body.get("stateOfIncorporation", "");
    (sic, about) = (body.get("sic", ""), body.get("sicDescription", ""));
    year_end = format_fiscal_year_end(body.get("fiscalYearEnd", ""));
    (annual, quarterly) = [pick_filing(recent, f, cik) for f in [ANNUAL_FORMS, QUARTERLY_FORMS]];
    state = STATES.get(state, state);
    return EdgarCompany(sic, about, year_end, state, annual, quarterly, company_browse_url(cik));
}

def get_json(url: str, agent: str, timeout: float) -> any {
    (status, body) = fetch_text(
        url, {"User-Agent": agent, "Accept": "application/json"}, None, timeout
    );
    if not 200 <= status < 300 {
        raise RuntimeError(f"HTTP Error {status}");
    }
    return json.loads(body);
}

"""A company's facts from SEC EDGAR's submissions feed, or None when EDGAR does not answer."""
def:pub edgar_company(cik: str) -> EdgarCompany | None {
    key = "".join([c for c in cik if c.isdigit()]).zfill(10);
    if not int(key) {
        return None;
    }
    # One lock for every lookup: requests leave one at a time, at least 125 ms apart, which keeps
    # this process under the SEC's rate, and a second caller for the same company waits and then
    # reads the first one's answer. A second instance of the app can double the rate.
    with edgar_lock {
        hit = edgar_cache.get(key);
        if hit is not None and hit[0] > time.time() {
            return hit[1];
        }
        time.sleep(max(0.0, edgar_next - time.time()));
        company: EdgarCompany | None = None;
        try {
            body = get_json(f"https://data.sec.gov/submissions/CIK{key}.json", SEC_USER_AGENT, 8);
            company = parse_submissions(cik, body);
        } except Exception as e {
            print("EDGAR submissions failed", key, e);
        }
        edgar_next = time.time() + 0.125;
        edgar_cache[key] = (time.time() + (43200 if company else 600), company);
        return company;
    }
}

"""Real repo numbers for the public site, refreshed daily. None hides the stat instead of guessing."""
def:pub repo_stats -> RepoStats | None {
    if repo_cache[0] > time.time() {
        return repo_cache[1];
    }
    stats: RepoStats | None = None;
    try {
        repo = get_json(REPO_URL.replace("github.com", "api.github.com/repos"), "OpenStock", 4);
        spdx = (repo["license"] or {}).get("spdx_id") or "AGPL-3.0";
        stats = RepoStats(repo["stargazers_count"], repo["forks_count"], spdx);
    } except Exception {}
    # A failure is asked again in 10 minutes, not a day.
    repo_cache = (time.time() + (86400 if stats else 600), stats);
    return stats;
}

"""Every public URL as (url, change frequency, priority): the marketing pages, the guides and
every ticker, and nothing of the signed-in app."""
def sitemap_entries(origin: str) -> list[tuple[str, str, float]] {
    entries: list[tuple[str, str, float]] = [];
    paths = [f"/compare/{g.slug}" for g in GUIDES] + [ticker_path(t.symbol) for t in TICKERS];
    for path in PUBLIC_EXACT_PATHS + paths {
        (stock, guide) = (path.startswith("/s/"), path.startswith("/compare"));
        rank = 1.0 if path == "/" else 0.6 if stock else 0.7 if guide else 0.5;
        entries.append((origin.rstrip("/") + path, "weekly" if stock else "monthly", rank));
    }
    return entries;
}

@restspec(method=HTTPMethod.GET, path="/sitemap.xml", produces="application/xml", envelope=False)
def:pub sitemap -> str {
    origin = site_url();
    if origin not in sitemaps {
        sitemaps[origin] = sitemap_xml(origin);
    }
    return sitemaps[origin];
}

def sitemap_xml(origin: str) -> str {
    urls = [
        f"<url><loc>{url}</loc><changefreq>{freq}</changefreq><priority>{priority:g}</priority></url>"
        for (url, freq, priority) in sitemap_entries(origin)
    ];
    head = '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n';
    return head + "\n".join(urls) + "\n</urlset>\n";
}

@restspec(method=HTTPMethod.GET, path="/robots.txt", envelope=False)
def:pub robots -> str {
    origin = site_url();
    rules = [f"Allow: {p}" for p in ROBOTS_ALLOW] + [f"Disallow: {p}" for p in ROBOTS_DISALLOW];
    return "\n".join(["User-Agent: *"] + rules)
        + f"\n\nHost: {origin}\nSitemap: {origin}/sitemap.xml\n";
}
