"""The public stock pages' types, and the pure helpers the server and the pages both use."""

# One row of data/us-tickers.json, every field filled (a test holds the data to it).
# `indexes` holds "SP500", "NDX100" or both.
obj Ticker {
    has symbol: str,
        name: str,
        exchange: str,
        sector: str,
        sub_industry: str,
        cik: str,
        indexes: list[str];
}

# `filed` is an ISO date: format_filing_date makes it readable.
obj Filing {
    has form: str,
        filed: str,
        url: str;
}

obj EdgarCompany {
    has sic: str,
        sic_description: str,
        fiscal_year_end: str,
        state_of_incorporation: str,
        annual: Filing | None,
        quarterly: Filing | None,
        filings_url: str;
}

# What /s/<ticker> renders, but the EDGAR facts, which are a second and slower call.
obj TickerPage {
    has ticker: Ticker,
        url: str,
        title: str,
        intro: str,
        peers: list[Ticker],
        prev: Ticker | None,
        next: Ticker | None,
        json_ld: str;
}

glob INDEX_LABEL: dict[str, str] = {"SP500": "S&P 500", "NDX100": "Nasdaq-100"};

glob MONTHS: list[str] = "January February March April May June July August September October November December".split();

glob DIRECTORY_TITLE: str = "US stock charts and SEC filings | OpenStock";

def directory_description(count: int) -> str {
    return f"Public pages for {count} S&P 500 and Nasdaq-100 companies: a TradingView chart and links to recent SEC EDGAR filings. No account required.";
}

# Symbols are letters, digits and dots (a test holds the data to it), so nothing needs encoding.
def ticker_path(symbol: str) -> str {
    return f"/s/{symbol}";
}

def sector_anchor(sector: str) -> str {
    return "-".join("".join([c if c.isalnum() else " " for c in sector.lower()]).split());
}

def company_browse_url(cik: str) -> str {
    return f"https://www.sec.gov/edgar/browse/?CIK={int(cik)}&owner=exclude";
}

"""2025-10-31 as "October 31, 2025"; anything else is returned as it came."""
def format_filing_date(iso: str) -> str {
    parts = iso.split("-");
    if len(parts) != 3 or not all([p.isdigit() for p in parts]) or not 1 <= int(parts[1]) <= 12 {
        return iso;
    }
    return f"{MONTHS[int(parts[1]) - 1]} {int(parts[2])}, {int(parts[0])}";
}

"""The page's summary sentence, from static facts alone: it never states a price."""
def ticker_intro(t: Ticker) -> str {
    the = "the " if (t.exchange + " ").startswith("NYSE ") else "";
    indexes = " and ".join([f"the {INDEX_LABEL[i]}" for i in t.indexes]);
    return f"{t.name} ({t.symbol}) is listed on {the}{t.exchange}, in the {t.sector} sector ({t.sub_industry}). It is in {indexes}. This page shows a TradingView chart for {t.symbol} and the company's recent annual and quarterly reports from the SEC EDGAR database. It does not include a price quote.";
}
