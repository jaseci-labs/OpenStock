glob asked: list[str] = [],
     tokens: list[str] = [],
     replies: dict[str, tuple[int, str]] = {};

"""Stands in for the network: the reply of the first key that is part of the URL, else 404."""
def fake_get(url: str, headers: dict[str, str]) -> tuple[int, str] {
    asked.append(url);
    tokens.append(headers.get("X-Finnhub-Token", ""));
    for (part, reply) in replies.items() {
        if part in url {
            return reply;
        }
    }
    return (404, "");
}

def set_keys(pool: str, public: str = "", single: str = "") {
    (os.environ["FINNHUB_API_KEYS"], os.environ["NEXT_PUBLIC_FINNHUB_API_KEY"]) = (pool, public);
    os.environ["FINNHUB_API_KEY"] = single;
}

def serve(table: dict[str, tuple[int, str]], keys: str = "k1") {
    set_keys(keys);
    http_get = fake_get;
    replies = table;
    asked.clear();
    tokens.clear();
    cache.clear();
}

"""A 200 with this body, as JSON unless it is text already."""
def ok(body: any) -> tuple[int, str] {
    return (200, body if isinstance(body, str) else json.dumps(body));
}

def chart_json(closes: list[float | None], **meta: any) -> str {
    return json.dumps({
        "chart": {"result": [{"meta": meta, "indicators": {"quote": [{"close": closes}]}}]},
    });
}

def chart(closes: list[float | None], **meta: any) -> any {
    return json.loads(chart_json(closes, **meta))["chart"]["result"][0];
}

def near(a: float, b: float) -> bool {
    return abs(a - b) < 1e-6;
}

test "daily quote compares the last two closes, skipping gaps" {
    q = daily_quote_from_chart(
        chart([25.0, 26.0, None, 26.52], currency="SAR", shortName="Saudi Arabian Oil Co.")
    );
    assert q is not None
        and q.price == 26.52
        and near(q.change, 0.52)
        and near(q.change_percent, 2.0);
    assert q.currency == "SAR" and q.name == "Saudi Arabian Oil Co.";
}

test "daily quote prefers the long name (GPW short names look like 'PKN C.XWAR PLN')" {
    meta = {"currency": "PLN", "shortName": "PKN C.XWAR PLN", "longName": "Orlen S.A."};
    q = daily_quote_from_chart(chart([147.0, 146.38], **meta));
    assert q is not None and q.currency == "PLN" and q.name == "Orlen S.A.";
}

test "daily quote prefers Yahoo's own day change (TASI sends a single daily bar)" {
    meta = {"regularMarketPrice": 9921.5, "fulldayChange": -101.97};
    q = daily_quote_from_chart(chart([9921.5], regularMarketChangePercent=-1.017, **meta));
    assert q is not None and (q.price, q.change, q.change_percent) == (9921.5, -101.97, -1.017);
}

test "daily quote falls back to the exchange's currency when Yahoo omits it" {
    q = daily_quote_from_chart(chart([10.0, 11.0]), yahoo_currency("2222.SR"));
    assert q is not None and q.currency == "SAR";
    q = daily_quote_from_chart(chart([10.0, 11.0]));
    assert q is not None and q.currency == "USD";
}

test "daily quote is None when Yahoo has nothing" {
    assert daily_quote_from_chart(None) is None;
    assert daily_quote_from_chart(chart([None])) is None;
}

test "prices Yahoo's markets by the symbol asked for, and nothing else" {
    serve({"2222.SR": (200, chart_json([25.0, 26.0])), "PKN.WA": (503, "")});
    got = yahoo_daily_quotes(["TADAWUL:2222", "GPW:PKN", "AAPL"]);
    assert list(got.keys()) == ["TADAWUL:2222"] and got["TADAWUL:2222"].currency == "SAR";
    assert len(asked) == 2 and not any("AAPL" in url for url in asked);
}

test "maps alert symbols to Yahoo chart symbols" {
    got = [
        yahoo_chart_symbol(s)
        for s in "AAPL brk.b BINANCE:BTCUSDT BINANCE:ETHBTC 2222.SR".split()
    ];
    assert got == ["AAPL", "BRK-B", "BTC-USD", None, None] and yahoo_chart_symbol("") is None;
}

test "reads closes oldest first, skipping gaps, with Yahoo's latest price" {
    assert closes_from_chart(chart([10.0, None, 11.0, 0.0, 12.5], regularMarketPrice=12))
        == Closes([10.0, 11.0, 12.5], 12.0);
}

test "falls back to the last close for the price, and to None for an empty chart" {
    assert closes_from_chart(chart([5.0, 6.0])) == Closes([5.0, 6.0], 6.0);
    assert closes_from_chart(None) is None;
}

test "daily closes come from a good response" {
    serve({"AAPL?interval=1d&range=1y": (200, chart_json([1.0, 2.0, 3.0], regularMarketPrice=3))});
    assert daily_closes("AAPL") == Closes([1.0, 2.0, 3.0], 3.0);
}

test "daily closes answer 'no history' when Yahoo has no such symbol or no bars" {
    serve({});
    assert daily_closes("ZZZZQ") == Closes();
    serve({"ZZZZQ": (200, '{"chart": {"result": []}}')});
    assert daily_closes("ZZZZQ") == Closes();
}

test "daily closes answer None (try again) when Yahoo is down" {
    serve({"AAPL": (503, "")});
    assert daily_closes("AAPL") is None;
}

test "never asks Yahoo about a symbol it has no series for" {
    serve({});
    assert daily_closes("BINANCE:ETHBTC") == Closes() and not asked;
}

test "reads the data mode at run time" {
    os.environ["NEXT_PUBLIC_OPENSTOCK_DATA_MODE"] = "realtime";
    assert (data_mode(), is_realtime(), quote_ttl()) == ("realtime", True, 15);
    os.environ["NEXT_PUBLIC_OPENSTOCK_DATA_MODE"] = "anything else";
    assert (data_mode(), is_realtime(), quote_ttl()) == ("cached", False, 3600);
}

test "reads the key pool from the first variable that is set" {
    set_keys("", "", "solo");
    assert finnhub_keys() == ["solo"];
    set_keys("", "pub", "solo");
    assert finnhub_keys() == ["pub"];
    set_keys(" a, b ,,c ", "pub", "solo");
    assert finnhub_keys() == ["a", "b", "c"];
}

test "rotates keys per request and gives the next one a turn on 429" {
    serve(
        {"quote?symbol=AAPL": (200, '{"c": 190.5, "d": 1.5, "dp": 0.79, "t": 1700000000}')}, "k1,k2"
    );
    q = get_quote("AAPL");
    get_quote("AAPL");
    assert q == Quote(price=190.5, change=1.5, change_percent=0.79, at=1700000000);
    assert sorted(tokens) == ["k1", "k2"];
    serve({"quote": (429, "slow down")}, "k1,k2");
    assert get_quote("AAPL") is None and sorted(tokens) == ["k1", "k2"];
}

test "a quote without a price, or with no key configured, is None" {
    serve({"quote": (200, '{"c": 0, "d": null, "dp": null}')});
    assert get_quote("ZZZZ") is None;
    serve({"quote": (200, '{"c": 1}')}, "");
    assert get_quote("AAPL") is None and not asked;
}

test "shares a cached answer, serves a stale one, and fails fast after a failure" {
    serve({"quote": (200, '{"c": 5}')});
    url = f"{FINNHUB}/quote?symbol=AAPL";
    assert fetch_json(url, 60) == {"c": 5} and fetch_json(url, 60) == {"c": 5} and len(asked) == 1;
    cache[url].fresh_until = 0.0;
    assert fetch_json(url, 60) == {"c": 5};
    # The stale answer came at once; its refresh runs beside the call and lands within the timeout
    while cache[url].fresh_until < time.time() + 30 {
        time.sleep(0.01);
    }
    assert len(asked) == 2;
    serve({"quote": (500, "down")});
    for attempt in range(2) {
        try {
            fetch_json(url, 60);
            assert False, "no error";
        } except Exception as e {
            assert not isinstance(e, AssertionError)
                and isinstance(e, RecentFailure) == (attempt == 1);
        }
    }
    assert len(asked) == 1;
}

test "live quotes skip malformed symbols and those Finnhub free can't price" {
    serve({"quote?symbol=AAPL": (200, '{"c": 10}'), "quote?symbol=MSFT": (200, '{"c": 0}')});
    got = live_quotes([" aapl ", "AAPL", "MSFT", "7203.T", "FX:EURUSD", "bad symbol!", ""]);
    assert list(got.keys()) == ["AAPL"] and got["AAPL"].price == 10.0;
    assert len(asked) == 2;
    assert len(clean_symbols([f"S{i}" for i in range(80)])) == MAX_SYMBOLS;
}

test "polled quotes cost a signed-in caller one use per symbol, 300 a minute" {
    serve({"quote": (200, '{"c": 10}')});
    watchlist = [f"S{i}" for i in range(50)];
    assert all([len(quotes(watchlist)) == 50 for _ in range(6)]);
    assert quotes(["AAPL"]) == {};
}

test "watchlist rows are priced from Yahoo or Finnhub, and zero where neither covers" {
    serve({
        "PKN.WA": (200, chart_json([100.0, 110.0], longName="Orlen S.A.")),
        "quote?symbol=AAPL": (200, '{"c": 190.5, "d": 1.5, "dp": 0.79}'),
        "profile2?symbol=AAPL": ok(
            dict(name="Apple Inc", currency="USD", logo="a.png", marketCapitalization=3000000)
        ),
    });
    rows = get_watchlist_data(["PKN.WA", "AAPL", "7203.T"]);
    assert rows[0] == WatchlistRow("PKN.WA", 110.0, 10.0, 10.0, "PLN", "Orlen S.A.");
    assert rows[1]
        == WatchlistRow("AAPL", 190.5, 1.5, 0.79, "USD", "Apple Inc", "a.png", 3000000.0);
    assert rows[2] == WatchlistRow("7203.T", 0.0, 0.0, 0.0, "USD", "7203.T");
}

test "reads the dividend yield and the US listing's exchange" {
    listed = [("AAPL", "XNAS"), ("SPY", "ARCX"), ("X", "TXSE")];
    serve({
        "metric?symbol=KO": (200, '{"metric": {"dividendYieldIndicatedAnnual": 3.1}}'),
        "stock/symbol?exchange=US": ok([dict(symbol=s, mic=m) for (s, m) in listed]),
    });
    assert get_stock_metrics("KO") == 3.1
        and get_stock_metrics("AAPL") is None
        and get_stock_metrics("BINANCE:BTCUSDT") is None;
    got = [get_tradingview_exchange(s) for s in ["aapl", "SPY", "X", "7203.T"]];
    assert got == ["NASDAQ", "AMEX", None, None];
    assert len([url for url in asked if "exchange=US" in url]) == 1;
}

def article(id: int, headline: str, when: int) -> dict[str, any] {
    return dict(
        id=id, headline=f" {headline} ", summary="s" * 300, url=f"https://news/{id}", datetime=when
    );
}

test "news picks company articles round-robin, newest first" {
    apple: list[any] = [article(i, f"A{i}", 100 + i) for i in range(5)];
    serve({
        "company-news?symbol=AAPL": ok(apple + [{"id": 9, "headline": "no url"}]),
        "company-news?symbol=MSFT": ok([article(20 + i, f"M{i}", 200 + i) for i in range(5)]),
    });
    news = get_news(["aapl", "MSFT", "BINANCE:BTCUSDT", "7203.T"], company_source="Firma");
    assert [a.headline for a in news] == ["M2", "M1", "M0", "A2", "A1", "A0"];
    assert len({a.id for a in news}) == 6 and len(asked) == 2;
    first = news[0];
    assert (first.related, first.category, first.source, first.summary)
        == ("MSFT", "company", "Firma", "s" * 200 + "...");
}

test "news falls back to general market news, each article once" {
    general = [article(1, "One", 5), article(1, "One", 5), {"id": 2, "headline": "no summary"}] + [
        article(10 + i, f"G{i}", 6) | {"source": "Wire", "category": "top", "related": "X"}
        for i in range(8)
    ];
    serve({"news?category=general": (200, json.dumps(general))});
    news = get_news(["7203.T"]);
    assert [a.headline for a in news] == ["One", "G0", "G1", "G2", "G3", "G4"];
    assert (news[0].id, news[0].source, news[0].category, news[0].summary)
        == (1, "Market News", "general", "s" * 150 + "...");
    assert (news[1].id, news[1].source, news[1].category, news[1].related)
        == (11, "Wire", "top", "X");
}

test "search answers the popular list for no query, and Finnhub's matches for one" {
    toyota = {"symbol": "7203.t", "description": "TOYOTA", "type": "Common Stock"};
    berkshire = {"symbol": "BRK.B", "description": "BERKSHIRE"};
    serve({"search?q=toyota%20motor": ok({"result": [toyota, {"symbol": "TM"}, berkshire]})});
    assert [s.symbol for s in search_stocks()][:2] == ["AAPL", "MSFT"]
        and len(search_stocks("  ")) == 10
        and not asked;
    assert search_stocks()[9] == Stock("JPM", "JPMorgan Chase & Co", "NYSE", "Common Stock");
    assert search_stocks(" toyota motor ") == [
        Stock("7203.T", "TOYOTA", "T", "Common Stock"),
        Stock("TM", "TM", "US", "Stock"),
        Stock("BRK.B", "BERKSHIRE", "US", "Stock"),
    ];
}
