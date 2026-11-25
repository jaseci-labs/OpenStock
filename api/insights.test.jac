glob sent: list[tuple[str, dict[str, str]]] = [],
     replies: dict[str, tuple[int, any]] = {};  # part of a URL: its reply, the first match wins

def fake_send(url: str, headers: dict[str, str], body: any, timeout: float) -> tuple[int, any] {
    sent.append((url, headers));
    for (part, reply) in replies.items() {
        if part in url {
            return reply;
        }
    }
    raise OSError("network failed");
}

"""Answer every request from `answers` (none: the network is down), with an empty cache and both keys set."""
def stub(answers: dict[str, tuple[int, any]] = {}) {
    send = fake_send;
    replies = answers;
    sent.clear();
    cache.clear();
    os.environ["ADANOS_API_KEY"] = "test-key";
    os.environ["ALPHAI_API_KEY"] = "test-key";
    os.environ.pop("ADANOS_API_BASE_URL", None);
}

"""One of Adanos's rows for a ticker."""
def found(ticker: str, buzz: float, bullish: any, trend: str, **more: any) -> dict[str, any] {
    return {"ticker": ticker, "buzz_score": buzz, "bullish_pct": bullish, "trend": trend} | more;
}

def stock(ticker: str, buzz: float, bullish: float, trend: str, mentions: int) -> dict[str, any] {
    name = f"{ticker}, Inc.";
    return {"stocks": [found(ticker, buzz, bullish, trend, company_name=name, mentions=mentions)]};
}

def insight(source: str, buzz: float, bullish: float) -> SourceInsight {
    return SourceInsight(source, source, "Tesla, Inc.", buzz, bullish, "falling", "Mentions", 1);
}

"""An AlphAI article; `analyses` are (ticker, sentiment, summary)."""
def article(
    uid: str,
    title: str = "",
    url: str = "",
    relevance: any = 6,
    analyses: list[tuple[str, str, str]] = [],
    sources_count: int | None = None,
) -> dict[str, any] {
    (site, when) = ("publisher.example", "2026-11-19T05:05:14Z");
    original = dict(uid=uid, title=title or f"Headline {uid}", url=url or f"https://{site}/{uid}");
    original |= dict(source=site, source_domain=site, time_published=when);
    takes = [
        {"ticker": t, "impact_analysis": {"sentiment": s, "summary": m}}
        for (t, s, m) in analyses
    ];
    scored: dict[str, any] = {"relevance_score": relevance, "category": "technology"};
    scored["ai_trading_insights"] = {"ticker_analysis": takes};
    return {"original": original, "enrichment": scored, "sources_count": sources_count};
}

def page(results: list[any]) -> dict[str, any] {
    return {"results": results, "next_cursor": None};
}

def ids(news: TickerNews | None) -> list[str] {
    return [item.id for item in news.items] if news is not None else [];
}

test "source insight maps source-specific metrics for mentions and trades" {
    got = source_insight("reddit", found("TSLA", 81.2, 46, "rising", mentions=647));
    assert got == SourceInsight("reddit", "Reddit", None, 81.2, 46.0, "rising", "Mentions", 647);
    got = source_insight("polymarket", found("TSLA", 55.7, 72, "stable", trade_count=3731));
    want = SourceInsight("polymarket", "Polymarket", None, 55.7, 72.0, "stable", "Trades", 3731);
    assert got == want;
}

test "source insight is None when required values are missing" {
    assert source_insight("x", {"ticker": "NVDA", "bullish_pct": 54, "mentions": 1200}) is None;
    assert source_insight("news", {"ticker": "NVDA", "buzz_score": 60, "bullish_pct": 54}) is None;
    assert source_insight("news", None) is None;
}

test "alignment names how far the sources agree, and which way" {
    assert source_alignment([31.0, 56.0, 48.0, 30.0]) == "Wide divergence";
    assert source_alignment([61.0, 64.0, 67.0]) == "Bullish alignment";
    assert source_alignment([35.0, 38.0]) == "Bearish alignment";
    assert source_alignment([45.0, 55.0]) == "Tight alignment";
    assert source_alignment([40.0, 60.0]) == "Mixed";
    assert source_alignment([50.0]) == "Single-source view"
        and source_alignment([]) == "No sentiment mix";
}

test "sentiment is a compact aggregate of the available sources" {
    found = [
        insight("reddit", 74.1, 31.0),
        insight("x", 86.1, 56.0),
        insight("polymarket", 83.3, 30.0),
    ];
    got = build_sentiment("tsla", found + [None]);
    assert got is not None and len(got.sources) == 3 and got.available_sources == 3;
    assert (got.symbol, got.company_name, got.average_buzz, got.bullish_average)
        == ("TSLA", "Tesla, Inc.", 81.2, 39.0);
    assert got.source_alignment == "Wide divergence";
}

test "sentiment is None when no source has usable data" {
    assert build_sentiment("MSFT", [None, None]) is None;
}

test "get_stock_sentiment reads the rows that match the requested ticker" {
    stub({
        "/reddit/": (200, stock("TSLA", 80.0, 40.0, "rising", 10)),
        "/x/": (200, stock("TSLA", 90.0, 60.0, "falling", 20)),
        "": (404, {"stocks": []}),
    });
    got = get_stock_sentiment(" tsla ");
    assert got is not None and [s.source for s in got.sources] == ["reddit", "x"];
    assert (got.symbol, got.company_name, got.average_buzz, got.bullish_average)
        == ("TSLA", "TSLA, Inc.", 85.0, 50.0);
    assert len(sent) == 4 and all([headers == {"X-API-Key": "test-key"} for (_, headers) in sent]);
    assert "https://api.adanos.org/polymarket/stocks/v1/compare?tickers=TSLA&days=7" in [
        url
        for (url, _) in sent
    ];
}

test "get_stock_sentiment asks nothing without a key or a symbol" {
    stub();
    assert get_stock_sentiment("  ") is None;
    os.environ.pop("ADANOS_API_KEY");
    assert get_stock_sentiment("TSLA") is None and not sent;
}

test "get_stock_sentiment is None on 404s, another ticker only, a body that is no JSON, a failure" {
    other = stock("MSFT", 70.0, 55.0, "stable", 30);
    cases: list[tuple[int, any]] = [(404, None), (200, other), (200, None)];
    for answer in cases {
        stub({"": answer});
        assert get_stock_sentiment("TSLA") is None, str(answer);
    }
    stub();
    assert get_stock_sentiment("TSLA") is None and len(sent) == 4;
}

test "AlphAI symbols are the ticker forms it uses, never exchange-prefixed ones" {
    assert all([is_alphai_symbol(s) for s in ["AAPL", "BRK.B", "VOD.L", "BTC-USD", "0700.HK"]]);
    assert not any([is_alphai_symbol(s) for s in ["", "BINANCE:BTCUSDT", "aapl", "A B", ".L"]]);
}

test "news maps an article and takes the analysis written for the page symbol" {
    analyses = [
        ("MSFT", "positive", "Good for Microsoft."),
        ("AAPL", "negative", "Margin pressure for Apple."),
    ];
    news = ticker_news(
        "aapl", page([article("a1", relevance=8, sources_count=3, analyses=analyses)])
    );
    (src, when, impact) = ("publisher.example", "2026-11-19T05:05:14Z", analyses[1][2]);
    item = NewsItem("a1", "Headline a1", f"https://{src}/a1", src, when, 8, "negative", impact, 3);
    assert news == TickerNews("AAPL", [item]);
}

test "news never shows another ticker's analysis on this symbol's page" {
    news = ticker_news(
        "AAPL", page([article("a2", analyses=[("MSFT", "positive", "Good for Microsoft.")])])
    );
    assert news is not None;
    assert (news.items[0].sentiment, news.items[0].impact, news.items[0].outlets)
        == (None, None, 1);
}

test "news cuts a long impact to 240 characters" {
    news = ticker_news("AAPL", page([article("a3", analyses=[("AAPL", "neutral", "word " * 60)])]));
    assert news is not None and news.items[0].impact == ("word " * 60)[:239].rstrip() + "…";
}

test "news drops rows without a usable title, link or score" {
    news = ticker_news(
        "AAPL",
        page([
            article("bad-score", relevance=11),
            article("low-score", relevance=4),
            article("string-score", relevance="7"),
            article("no-title", title="  "),
            article("script-link", url="javascript:alert(1)"),
            article("relative-link", url="/news/1"),
            {"original": None, "enrichment": {}},
            "garbage",
            article("kept"),
        ]),
    );
    assert ids(news) == ["kept"];
}

test "news drops duplicates and keeps at most five items" {
    assert ids(
        ticker_news("AAPL", page([article(uid) for uid in ["a", "a", "b", "c", "d", "e", "f"]]))
    ) == ["a", "b", "c", "d", "e"];
}

test "news is None for an empty page or an unexpected payload" {
    assert ticker_news("AAPL", page([])) is None;
    assert ticker_news("AAPL", {"detail": "Not found"}) is None;
    assert ticker_news("AAPL", None) is None;
}

test "get_alphai_news makes no request without a key, or for a symbol AlphAI cannot have" {
    stub();
    assert get_alphai_news("BINANCE:BTCUSDT") is None and not sent;
    os.environ.pop("ALPHAI_API_KEY");
    assert get_alphai_news("NOKEY") is None and not sent;
}

test "get_alphai_news asks with the key in a header and keeps the answer for an hour" {
    stub({"": (200, page([article("n1", analyses=[("NVDA", "positive", "Demand holds.")])]))});
    news = get_alphai_news("nvda");
    assert news is not None;
    assert (news.items[0].id, news.items[0].sentiment, news.items[0].impact)
        == ("n1", "positive", "Demand holds.");
    assert ids(get_alphai_news("NVDA")) == ["n1"];
    url = "https://api.alphai.io/api/news/?symbol=NVDA&page_size=5&min_relevance=5&collapse=story";
    assert sent == [(url, {"Authorization": "Bearer test-key", "Accept": "application/json"})];
    assert time.time() + 3590 < cache[sent[0][0]][0] <= time.time() + 3600;
}

test "get_alphai_news waits ten minutes after a failure before asking about that symbol again" {
    stub({"": (503, {})});
    assert get_alphai_news("META") is None and get_alphai_news("META") is None;
    assert len(sent) == 1;
    until = cache[sent[0][0]][0];
    assert time.time() + 590 < until <= time.time() + 600;
    # Ten minutes later
    cache[sent[0][0]] = (time.time() - 1, None);
    assert get_alphai_news("META") is None and len(sent) == 2;
}

test "get_alphai_news is None, and waits, when rate limited, the body is no JSON or the request fails" {
    cases: list[tuple[int, any]] = [(429, {"detail": "Rate limit exceeded"}), (200, None)];
    for answer in cases {
        stub({"": answer});
        assert get_alphai_news("AMD") is None and get_alphai_news("AMD") is None and len(sent) == 1;
    }
    stub();
    assert get_alphai_news("INTC") is None and len(sent) == 1;
}

test "the cache drops its oldest entry once it holds 500" {
    stub({"": (200, {})});
    for i in range(MAX_CACHED + 1) {
        get_json(f"https://example.test/{i}", {}, 60.0);
    }
    assert len(cache) == MAX_CACHED
        and "https://example.test/0" not in cache
        and "https://example.test/1" in cache;
}
