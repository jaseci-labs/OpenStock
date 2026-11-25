"""The stock page's two insight cards: cross-source sentiment (Adanos) and scored news (AlphAI)."""
import math;
import os;
import re;
import sys;
import threading;
import time;
import from datetime { datetime }
import from urllib.parse { urlencode, urlsplit }

glob SOURCES: dict[str, tuple[str, str, str]] = {  # source: (label, metric label, metric field)
         "reddit": ("Reddit", "Mentions", "mentions"),
         "x": ("X.com", "Mentions", "mentions"),
         "news": ("News", "Mentions", "mentions"),
         "polymarket": ("Polymarket", "Trades", "trade_count"),
     },
     NEWS_URL: str = "https://api.alphai.io/api/news/",
     MAX_ITEMS: int = 5,
     # 5 and up: real company news and sector datapoints; recaps of already-known events stay out.
     # Sent to AlphAI as min_relevance and checked again here, so the card never depends on the server honouring it.
     MIN_RELEVANCE: int = 5,
     MAX_IMPACT: int = 240,
     TIMEOUT: float = 5.0,
     SENTIMENT_TTL: float = 300.0,
     # The free AlphAI key allows 100 requests a day, so each symbol is asked about once an hour,
     # and a failed or rate-limited symbol waits ten minutes before the next try.
     NEWS_TTL: float = 3600.0,
     NEWS_FAILURE_TTL: float = 600.0,
     MAX_CACHED: int = 500,
     send: Callable[[str, dict[str, str], any, float], tuple[int, any]] = request_json,
     cache: dict[str, tuple[float, any]] = {},  # url: (fresh until, payload or None for a failure)
     cache_lock: threading.Lock = threading.Lock();

"""A 200's JSON, kept `ttl` seconds per URL. Anything else is None, kept `fail_ttl` seconds."""
def get_json(url: str, headers: dict[str, str], ttl: float, fail_ttl: float = 0.0) -> any {
    with cache_lock {
        hit = cache.get(url);
    }
    if hit is not None and hit[0] > time.time() {
        return hit[1];
    }
    data: any = None;
    try {
        (status, body) = send(url, headers, None, TIMEOUT);
        if status == 200 {
            data = body;
        } elif status != 404 {
            print(f"{url} answered {status}", file=sys.stderr);
        }
    } except Exception as e {
        print(f"{url} failed: {e}", file=sys.stderr);
    }
    with cache_lock {
        cache.pop(url, None);
        if len(cache) >= MAX_CACHED {
            cache.pop(next(iter(cache)));  # the oldest entry
        }
        cache[url] = (time.time() + (fail_ttl if data is None else ttl), data);
    }
    return data;
}

def row(v: any) -> dict[str, any] {
    return v if isinstance(v, dict) else {};
}

def rows(v: any) -> list[any] {
    return v if isinstance(v, list) else [];
}

def text(v: any) -> str | None {
    return v.strip() if isinstance(v, str) and v.strip() else None;
}

def is_real(v: any) -> bool {
    return isinstance(v, (int, float)) and not isinstance(v, bool) and math.isfinite(v);
}

def num(v: any) -> float | None {
    if isinstance(v, str) and v.strip() {
        try {
            v = float(v);
        } except ValueError {
            return None;
        }
    }
    return float(v) if is_real(v) else None;
}

def whole(v: any) -> int | None {
    return int(v) if is_real(v) and v == int(v) else None;
}

# Halves round up, as the legacy Math.round did (round() would send 0.25 to 0.2)
def round_to(v: float, digits: int = 1) -> float {
    return math.floor(v * 10 ** digits + 0.5) / 10 ** digits;
}

def mean(values: list[float]) -> float {
    return sum(values) / len(values);
}

def source_alignment(bullish: list[float]) -> str {
    if len(bullish) < 2 {
        return "Single-source view" if bullish else "No sentiment mix";
    }
    spread = max(bullish) - min(bullish);
    avg = mean(bullish);
    if spread <= 12 {
        return "Bullish alignment"
            if avg >= 60
            else "Bearish alignment" if avg <= 40 else "Tight alignment";
    }
    return "Wide divergence" if spread >= 25 else "Mixed";
}

def source_insight(source: str, found: any) -> SourceInsight | None {
    (label, metric_label, metric_field) = SOURCES[source];
    buzz = num(row(found).get("buzz_score"));
    metric = num(row(found).get(metric_field));
    if buzz is None or metric is None {
        return None;
    }
    (name, trend) = (found.get("company_name"), found.get("trend"));
    name = name if isinstance(name, str) else None;
    trend = trend if trend in ("rising", "falling", "stable") else None;
    (bullish, count) = (num(found.get("bullish_pct")), int(round_to(metric, 0)));
    return SourceInsight(source, label, name, round_to(buzz), bullish, trend, metric_label, count);
}

def build_sentiment(symbol: str, found: list[SourceInsight | None]) -> StockSentiment | None {
    sources = [s for s in found if s is not None];
    if not sources {
        return None;
    }
    bullish: list[float] = [];
    for s in sources {
        if s.bullish_pct is not None {
            bullish.append(s.bullish_pct);
        }
    }
    names = [s.company_name for s in sources if s.company_name];
    name = names[0] if names else None;
    buzz = round_to(mean([s.buzz_score for s in sources]));
    average = round_to(mean(bullish)) if bullish else None;
    mix = source_alignment(bullish);
    return StockSentiment(symbol.upper(), name, buzz, average, mix, len(sources), sources);
}

def fetch_source(source: str, symbol: str, days: int, key: str) -> SourceInsight | None {
    base = (os.environ.get("ADANOS_API_BASE_URL") or "https://api.adanos.org").rstrip("/");
    query = urlencode({"tickers": symbol, "days": days});
    payload = get_json(
        f"{base}/{source}/stocks/v1/compare?{query}", {"X-API-Key": key}, SENTIMENT_TTL
    );
    for found in rows(row(payload).get("stocks")) {
        if (text(row(found).get("ticker")) or "").upper() == symbol {
            return source_insight(source, found);
        }
    }
    return None;
}

"""Buzz and bullishness for a symbol across Reddit, X, news and Polymarket; None without a key or any data."""
def:pub get_stock_sentiment(symbol: str, days: int = 7) -> StockSentiment | None {
    key = os.environ.get("ADANOS_API_KEY", "");
    ticker = symbol.strip().upper();
    if not key or not ticker {
        return None;
    }
    span = max(1, min(days, 30));
    return build_sentiment(
        ticker, [wait t for t in [flow fetch_source(s, ticker, span, key) for s in SOURCES]]
    );
}

# AlphAI tickers are bare US symbols (NVDA, BRK.B), Yahoo-suffixed listings (VOD.L) or crypto pairs (BTC-USD).
# Exchange-prefixed symbols (BINANCE:BTCUSDT) can't match, so they never spend a request.
def is_alphai_symbol(symbol: str) -> bool {
    return re.fullmatch(r"[A-Z0-9][A-Z0-9.-]{0,19}", symbol) is not None;
}

"""The host of an http(s) link, None for anything else: a javascript: URL must never become an href."""
def http_host(url: str) -> str | None {
    try {
        parts = urlsplit(url);
    } except ValueError {
        return None;
    }
    return (parts.hostname or None) if parts.scheme in ("http", "https") else None;
}

def is_date(value: str) -> bool {
    try {
        datetime.fromisoformat(value);
        return True;
    } except ValueError {
        return False;
    }
}

def news_item(symbol: str, value: any) -> NewsItem | None {
    original = row(row(value).get("original"));
    enrichment = row(row(value).get("enrichment"));
    title = text(original.get("title"));
    url = text(original.get("url"));
    host = http_host(url or "");
    relevance = whole(enrichment.get("relevance_score"));
    if title is None or url is None or host is None or relevance is None {
        return None;
    }
    if not MIN_RELEVANCE <= relevance <= 10 {
        return None;
    }
    # The analysis for the page's own symbol only: an article about AAPL and MSFT carries one entry per ticker.
    verdict: dict[str, any] = {};
    for analysis in rows(row(enrichment.get("ai_trading_insights")).get("ticker_analysis")) {
        if (text(row(analysis).get("ticker")) or "").upper() == symbol {
            verdict = row(analysis.get("impact_analysis"));
            break;
        }
    }
    sentiment = verdict.get("sentiment");
    impact = text(verdict.get("summary"));
    if impact is not None and len(impact) > MAX_IMPACT {
        impact = impact[:MAX_IMPACT - 1].rstrip() + "…";
    }
    published = text(original.get("time_published"));
    when = published if published and is_date(published) else None;
    outlets = max(whole(row(value).get("sources_count")) or 1, 1);
    uid = text(original.get("uid")) or url;
    source = text(original.get("source")) or text(original.get("source_domain")) or host;
    mood = sentiment if sentiment in ("positive", "neutral", "negative") else None;
    return NewsItem(uid, title, url, source, when, relevance, mood, impact, outlets);
}

def ticker_news(symbol: str, payload: any) -> TickerNews | None {
    ticker = symbol.strip().upper();
    seen: set[str] = set();
    items: list[NewsItem] = [];
    for result in rows(row(payload).get("results")) {
        item = news_item(ticker, result);
        if item is None or item.id in seen or item.url in seen {
            continue;
        }
        seen |= {item.id, item.url};
        items.append(item);
        if len(items) == MAX_ITEMS {
            break;
        }
    }
    return TickerNews(symbol=ticker, items=items) if items else None;
}

"""Up to five relevance-scored stories for a symbol; None without a key, for a symbol AlphAI cannot have, or without news."""
def:pub get_alphai_news(symbol: str) -> TickerNews | None {
    key = os.environ.get("ALPHAI_API_KEY", "").strip();
    ticker = symbol.strip().upper();
    if not key or not is_alphai_symbol(ticker) {
        return None;
    }
    # collapse=story: one row per story, so five reprints of the same event don't fill the card
    query = urlencode(
        dict(symbol=ticker, page_size=MAX_ITEMS, min_relevance=MIN_RELEVANCE, collapse="story")
    );
    headers = {"Authorization": f"Bearer {key}", "Accept": "application/json"};
    return ticker_news(
        ticker, get_json(f"{NEWS_URL}?{query}", headers, NEWS_TTL, NEWS_FAILURE_TTL)
    );
}
