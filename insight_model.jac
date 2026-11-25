"""What the stock page's sentiment and scored-news cards show: made by api.insights, read by pages."""

obj SourceInsight {
    has source: str,  # reddit | x | news | polymarket
        label: str,
        company_name: str | None,
        buzz_score: float,
        bullish_pct: float | None,
        trend: str | None,  # rising | falling | stable
        metric_label: str,  # Mentions | Trades
        metric_value: int;
}

obj StockSentiment {
    has symbol: str,
        company_name: str | None,
        average_buzz: float,
        bullish_average: float | None,
        source_alignment: str,
        available_sources: int,
        sources: list[SourceInsight];
}

obj NewsItem {
    has id: str,
        title: str,
        url: str,
        source: str,
        published_at: str | None,
        relevance: int,  # AlphAI's 1-10 score for the article
        # Sentiment and one-line impact written for this symbol, when the article analyses it
        sentiment: str | None,  # positive | neutral | negative
        impact: str | None,
        outlets: int;  # distinct outlets that covered the story, 1 for a single publisher
}

obj TickerNews {
    has symbol: str,
        items: list[NewsItem];
}

def alphai_stock_url(symbol: str) -> str {
    return f"https://alphai.io/stock/{symbol.upper()}?utm_source=openstock&utm_medium=partner";
}

test "the AlphAI link is the symbol's page with the partner tags" {
    assert alphai_stock_url("brk.b")
        == "https://alphai.io/stock/BRK.B?utm_source=openstock&utm_medium=partner";
}
