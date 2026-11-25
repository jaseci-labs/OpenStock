"""Regenerates data/us-tickers.json. Static names, sectors and CIKs only: no prices.
S&P 500: datasets/s-and-p-500-companies (GICS sector, sub-industry, CIK).
Nasdaq-100: Wikipedia "List of NASDAQ-100 companies" (tickers not already in the S&P 500).
Exchange: SEC company_tickers_exchange.json (public domain). SEC writes class shares as BRK-B;
we keep the dotted form (BRK.B) used by the S&P list and by TradingView.

    neojac run tools/build_tickers.jac
"""
import csv;
import html;
import json;
import re;
import urllib.request;
import from datetime { date }

# SEC fair-access rules: a User-Agent that names the app and a contact address. A URL in the
# header is what their edge blocks; the email form is the one their docs ask for.
glob UA: str = "OpenStock (opendevsociety@gmail.com)",
     SP500_URL: str = "https://raw.githubusercontent.com/datasets/s-and-p-500-companies/master/data/constituents.csv",
     NDX_URL: str = "https://en.wikipedia.org/wiki/List_of_NASDAQ-100_companies",
     SEC_URL: str = "https://www.sec.gov/files/company_tickers_exchange.json";

# Wikipedia's Nasdaq-100 table uses ICB industries. /s groups by sector, so these strings
# have to match the S&P 500 GICS sectors or the same industry splits into two headings.
# An industry that is not here stops the run with a KeyError.
glob ICB_TO_GICS: dict[str, str] = {
    "Technology": "Information Technology",
    "Telecommunications": "Communication Services",
    "Health Care": "Health Care",
    "Financials": "Financials",
    "Real Estate": "Real Estate",
    "Consumer Discretionary": "Consumer Discretionary",
    "Consumer Staples": "Consumer Staples",
    "Industrials": "Industrials",
    "Basic Materials": "Materials",
    "Energy": "Energy",
    "Utilities": "Utilities",
};

def fetch(url: str, accept: str) -> str {
    request = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": accept});
    with urllib.request.urlopen(request, timeout=30) as response {
        return response.read().decode("utf-8");
    }
}

"""The (symbol, name, ICB industry, sub-industry) rows of Wikipedia's table."""
def parse_nasdaq100(page: str) -> list[tuple[str, str, str, str]] {
    start = page.index(">Ticker<");
    rows: list[tuple[str, str, str, str]] = [];
    for row in re.findall(r"<tr[\s\S]*?</tr>", page[start:page.index("</table>", start)]) {
        cells = [
            html.unescape(re.sub(r"<[^>]+>", "", cell)).strip()
            for cell in re.findall(r"<td[^>]*>([\s\S]*?)</td>", row)
        ];
        if len(cells) >= 4 and re.fullmatch(r"[A-Z][A-Z0-9.-]{0,7}", cells[0]) {
            rows.append((cells[0], cells[1], cells[2], cells[3]));
        }
    }
    assert len(rows) >= 90, f"Expected about 100 Nasdaq-100 rows, parsed {len(rows)}";
    return rows;
}

def build(sp_csv: str, ndx_page: str, sec_json: str) -> list[dict[str, any]] {
    # SEC rows are [cik, name, ticker, exchange].
    sec: dict[str, list[any]] = {
        str(r[2]).upper(): r
        for r in json.loads(sec_json)["data"]
        if r[2]
    };
    found: dict[str, dict[str, any]] = {};
    for row in csv.DictReader(sp_csv.splitlines()) {
        symbol = row["Symbol"].strip().upper();
        hit = sec.get(symbol) or sec.get(symbol.replace(".", "-")) or ["", "", "", ""];
        found[symbol] = {
            "symbol": symbol,
            "name": row["Security"].strip(),
            "exchange": hit[3] or "",
            "sector": row["GICS Sector"].strip(),
            "subIndustry": row["GICS Sub-Industry"].strip(),
            "cik": str(row["CIK"] or hit[0]).lstrip("0"),
            "indexes": ["SP500"],
        };
    }
    for (symbol, name, industry, sub) in parse_nasdaq100(ndx_page) {
        if symbol in found {
            found[symbol]["indexes"].append("NDX100");
            continue;
        }
        hit = sec.get(symbol) or sec.get(symbol.replace(".", "-")) or ["", "", "", ""];
        found[symbol] = {
            "symbol": symbol,
            "name": name,
            "exchange": hit[3] or "Nasdaq",
            "sector": ICB_TO_GICS[industry],
            "subIndustry": sub,
            "cik": str(hit[0]),
            "indexes": ["NDX100"],
        };
    }
    return [found[s] for s in sorted(found)];
}

with entry:__main__ {
    rows = build(
        fetch(SP500_URL, "text/csv"),
        fetch(NDX_URL, "text/html"),
        fetch(SEC_URL, "application/json"),
    );
    out = {
        "generated": date.today().isoformat(),
        "note": "Static index membership, names, GICS sector, and SEC CIK. No market prices. Regenerate with tools/build_tickers.jac.",
        "tickers": rows,
    };
    with open("data/us-tickers.json", "w") as f {
        f.write(json.dumps(out, indent=2, ensure_ascii=False) + "\n");
    }
    missing = [r["symbol"] for r in rows if not r["cik"]];
    print(f"Wrote {len(rows)} tickers. Missing CIK: {', '.join(missing) or 'none'}");
}
