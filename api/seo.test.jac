glob GICS: list[str] = [
    "Communication Services",
    "Consumer Discretionary",
    "Consumer Staples",
    "Energy",
    "Financials",
    "Health Care",
    "Industrials",
    "Information Technology",
    "Materials",
    "Real Estate",
    "Utilities",
];

test "tickers cover the S&P 500 and the Nasdaq-100, with every field on every row" {
    assert 500 <= len(TICKERS) < 600;
    for t in TICKERS {
        assert t.symbol
            and t.name
            and t.exchange
            and t.sub_industry
            and t.cik
            and t.indexes, t.symbol;
        assert t.sector in GICS, t.symbol;
        assert t.symbol.replace(".", "").isalnum(), t.symbol;
    }
    assert [t.symbol for t in TICKERS] == sorted(BY_SYMBOL);
    apple = find_ticker("aapl");
    assert apple is not None and apple.indexes == ["SP500", "NDX100"] and apple.cik == "320193";
}

test "find_ticker accepts the dotted class share and the hyphenated form" {
    for raw in ["BRK.B", "brk-b", " brk%2Eb "] {
        found = find_ticker(raw);
        assert found is not None and found.symbol == "BRK.B", raw;
    }
    assert find_ticker("not-a-ticker") is None;
    assert ticker_path("BRK.B") == "/s/BRK.B";
}

test "the intro is written from static facts and does not invent a price" {
    page = ticker_page("AAPL");
    assert page is not None;
    for part in [
        "Apple Inc.",
        "listed on Nasdaq,",
        "S&P 500 and the Nasdaq-100",
        "does not include a price quote",
    ] {
        assert part in page.intro, part;
    }
    assert "finnhub" not in page.intro.lower();
    nyse = find_ticker("JPM");
    assert nyse is not None and "listed on the NYSE" in ticker_intro(nyse);
}

test "a ticker page links peers in the same sector and the neighbouring symbols" {
    page = ticker_page("AAPL");
    assert page is not None and 0 < len(page.peers) <= 8;
    assert all([p.sector == page.ticker.sector and p.symbol != "AAPL" for p in page.peers]);
    assert page.peers[0].symbol > "AAPL";
    assert page.prev is not None and page.prev.symbol < "AAPL";
    assert page.next is not None and page.next.symbol > "AAPL";
    assert ticker_page(TICKERS[0].symbol).prev is None
        and ticker_page(TICKERS[-1].symbol).next is None;
    assert ticker_page("nope") is None;
}

test "tickers_by_sector groups every ticker under a sorted GICS sector" {
    groups = tickers_by_sector();
    assert list(groups) == GICS;
    assert sum([len(g) for g in groups.values()]) == len(TICKERS);
}

test "edgar helpers build an archives URL and format filing facts" {
    assert filing_url("320193", "0000320193-25-000079", "aapl-20250927.htm")
        == "https://www.sec.gov/Archives/edgar/data/320193/000032019325000079/aapl-20250927.htm";
    assert format_fiscal_year_end("0926") == "September 26";
    assert format_fiscal_year_end("nope") == "" and format_fiscal_year_end("1340") == "";
    assert STATES["DE"] == "Delaware" and len(STATES) == 51;
    assert edgar_company("") is None;
}

test "parse_submissions picks the annual report ahead of a later amendment" {
    company = parse_submissions(
        "320193",
        {
            "sic": "3571",
            "sicDescription": "Electronic Computers",
            "fiscalYearEnd": "0926",
            "stateOfIncorporation": "CA",
            "filings": {
                "recent": {
                    "form": ["10-K/A", "8-K", "10-Q", "10-K"],
                    "filingDate": ["2026-01-01", "2025-12-01", "2025-08-01", "2025-10-31"],
                    "accessionNumber": [
                        "0000320193-26-000001",
                        "0000320193-25-000003",
                        "0000320193-25-000002",
                        "0000320193-25-000079",
                    ],
                    "primaryDocument": ["amend.htm", "8k.htm", "10q.htm", "aapl-20250927.htm"],
                },
            },
        },
    );
    assert company.annual is not None and company.annual.form == "10-K";
    assert company.annual.url.endswith("aapl-20250927.htm")
        and company.annual.filed == "2025-10-31";
    assert company.quarterly is not None and company.quarterly.form == "10-Q";
    assert company.sic_description == "Electronic Computers";
    assert company.state_of_incorporation == "California";
    assert company.fiscal_year_end == "September 26";
    assert parse_submissions("320193", {}).annual is None;
}

test "the sitemap lists marketing pages, guides and every ticker, and not the signed-in app" {
    entries = sitemap_entries("https://openstock.example/");
    urls = [e[0] for e in entries];
    for path in PUBLIC_EXACT_PATHS
        + ["/s/AAPL", "/s/BRK.B"]
        + [f"/compare/{g.slug}" for g in GUIDES] {
        assert f"https://openstock.example{path}" in urls, path;
    }
    assert not [u for u in urls if "/stocks" in u or "/dashboard" in u];
    assert len(set(urls)) == len(urls);
    assert ("https://openstock.example/", "monthly", 1.0) in entries;
    assert ("https://openstock.example/s/AAPL", "weekly", 0.6) in entries;
    assert ("https://openstock.example/compare", "monthly", 0.7) in entries;
    assert ("https://openstock.example/s", "monthly", 0.5) in entries;
}

test "site_url, sitemap.xml and robots.txt use BETTER_AUTH_URL without a trailing slash" {
    os.environ["BETTER_AUTH_URL"] = "https://openstock.example/";
    assert site_url() == "https://openstock.example";
    xml = sitemap();
    assert xml.startswith('<?xml version="1.0" encoding="UTF-8"?>\n<urlset ')
        and xml.endswith("</urlset>\n");
    assert xml.count("<url>") == len(sitemap_entries(site_url()));
    assert "<url><loc>https://openstock.example/</loc><changefreq>monthly</changefreq><priority>1</priority></url>"
        in xml;
    assert "<loc>https://openstock.example/s/BRK.B</loc><changefreq>weekly</changefreq><priority>0.6</priority>"
        in xml;
    lines = robots().split("\n");
    assert lines[0] == "User-Agent: *" and "Allow: /s/" in lines and "Disallow: /stocks" in lines;
    assert lines[-3:] == [
        "Host: https://openstock.example",
        "Sitemap: https://openstock.example/sitemap.xml",
        "",
    ];
    del os.environ["BETTER_AUTH_URL"];
    assert site_url() == "http://localhost:8000";
}

test "JSON-LD is valid JSON with the nodes each page emitted" {
    os.environ["BETTER_AUTH_URL"] = "https://openstock.example";
    page = ticker_page("AAPL");
    assert page is not None and "<" not in page.json_ld;
    nodes = json.loads(page.json_ld)["@graph"];
    assert [n["@type"] for n in nodes] == ["BreadcrumbList", "Corporation", "WebPage"];
    assert nodes[0]["itemListElement"][2] == {
        "@type": "ListItem",
        "position": 3,
        "name": "Information Technology",
        "item": "https://openstock.example/s#information-technology",
    };
    assert nodes[1]["url"] == "https://www.sec.gov/edgar/browse/?CIK=320193&owner=exclude";
    assert nodes[2]["url"] == page.url == "https://openstock.example/s/AAPL";
    guide = json.loads(guide_ld(GUIDES[0].slug))["@graph"];
    assert [n["@type"] for n in guide] == ["BreadcrumbList", "FAQPage", "Article"];
    assert guide[1]["mainEntity"][0]["acceptedAnswer"]["text"] == GUIDES[0].faqs[0].answer;
    assert guide[2]["publisher"]["url"] == "https://openstock.example";
    assert guide_ld("no-such-guide") == "";
    directory = json.loads(directory_ld());
    assert directory["@context"] == "https://schema.org";
    assert directory["@graph"][0]["description"].startswith(
        f"Public pages for {len(TICKERS)} S&P 500"
    );
    del os.environ["BETTER_AUTH_URL"];
}

test "the public ticker and EDGAR code stays off the quote client" {
    for path in ["api/seo.jac", "content/tickers.jac", "content/comparisons.jac"] {
        with open(path) as f {
            assert "finnhub." not in f.read().lower(), path;
        }
    }
}
