"""Quotes, company data, search and news from Finnhub's free plan; daily quotes and closes from Yahoo Finance for
what Finnhub free can't give (Tadawul, Warsaw, a year of history for moving averages)."""
import json;
import math;
import os;
import re;
import sys;
import threading;
import time;
import urllib.parse;
import from datetime { datetime, timedelta, timezone }
import from stdjac { consume_limit }

glob FINNHUB: str = "https://finnhub.io/api/v1",
     YAHOO: str = "https://query1.finance.yahoo.com/v8/finance/chart/",
     # Without a timeout a stalled socket holds the page (and the whole dashboard) up
     FETCH_TIMEOUT: float = 5.0,
     # Finnhub stalls bursts of parallel requests from one key (measured: 4 at once -> most hang), so calls queue.
     # ponytail: per-instance limiter; a shared queue (Redis) if instances multiply.
     MAX_IN_FLIGHT_PER_KEY: int = 2,
     MAX_CACHE_ENTRIES: int = 1000,
     FAILURE_TTL: float = 60.0,
     MAX_ARTICLES: int = 6,
     MAX_SYMBOLS: int = 50;  # a full watchlist in one request

obj Cached {
    has value: any,
        fresh_until: float,
        failed: bool = False;
}

"""Raised instead of calling out while an endpoint is in its failure cool-down; not worth logging again."""
obj RecentFailure(Exception) {}

"""How fresh market numbers are: "cached" (the default, a public instance: quotes refresh hourly, shared by every
user) or "realtime" (OpenStock Cloud, or self-hosted with your own Finnhub keys: quotes refresh every 15s)."""
def:pub data_mode -> str {
    realtime = os.environ.get("NEXT_PUBLIC_OPENSTOCK_DATA_MODE") == "realtime";
    return "realtime" if realtime else "cached";
}

"""Email price alerts are on in realtime mode only, off on the free hourly site."""
def:pub is_realtime -> bool {
    return data_mode() == "realtime";
}

"""Quotes are shared across everyone looking at a symbol: Finnhub cost scales with symbols, not users."""
def quote_ttl -> int {
    return 15 if is_realtime() else 3600;
}

"""The key pool: each free key has its own 60 req/min, so N keys = N x the quota. Rotated per request."""
def finnhub_keys -> list[str] {
    env = os.environ;
    pool = env.get("FINNHUB_API_KEYS")
        or env.get("NEXT_PUBLIC_FINNHUB_API_KEY")
        or env.get("FINNHUB_API_KEY")
        or "";
    return [k.strip() for k in pool.split(",") if k.strip()];
}

# tests put a fake here
glob http_get: Callable[[str, dict[str, str]], tuple[int, str]] = lambda (
         url: str, headers: dict[str, str]
     ) -> tuple[int, str] { fetch_text(url, headers, None, FETCH_TIMEOUT) },
     cache: dict[str, Cached] = {},
     next_key: int = 0,
     slots: threading.Semaphore = threading.Semaphore(
         MAX_IN_FLIGHT_PER_KEY * max(1, len(finnhub_keys()))
     ),
     us_listings: dict[str, str] = {},
     us_listings_fresh_until: float = 0.0;

def log_failure(what: str, symbol: str, e: Exception) {
    if not isinstance(e, RecentFailure) {
        print(f"Error fetching {what} for {symbol}: {e}", file=sys.stderr);
    }
}

def enc(text: str) -> str {
    return urllib.parse.quote(text, safe="");
}

def is_num(v: any) -> bool {
    return isinstance(v, (int, float)) and not isinstance(v, bool) and math.isfinite(v);
}

def num(v: any, fallback: float = 0.0) -> float {
    return float(v) if is_num(v) else fallback;
}

"""data[a][b]..., or None where the path ends early."""
def dig(data: any, *path: str | int) -> any {
    try {
        return data if not path else dig(data[path[0]], *path[1:]);
    } except Exception {
        return None;
    }
}

"""One uncached call. Finnhub's token travels in a header, and on 429 the next key in the pool gets a turn. Yahoo
needs no key; a 404 there is an answer (no such symbol), {}."""
def request(url: str) -> any {
    if url.startswith(YAHOO) {
        (status, body) = http_get(url, {"User-Agent": "Mozilla/5.0"});
        if status == 404 {
            return {};
        }
    } else {
        keys = finnhub_keys();
        if not keys {
            raise RuntimeError("No Finnhub API key configured (FINNHUB_API_KEYS)");
        }
        (status, body) = (429, "");
        with slots {
            for _ in keys {
                next_key += 1;
                (status, body) = http_get(url, {"X-Finnhub-Token": keys[next_key % len(keys)]});
                if status != 429 {
                    break;
                }
            }
        }
    }
    if not 200 <= status < 300 {
        raise RuntimeError(f"Fetch failed {status}: {body[:200]}");
    }
    return json.loads(body);
}

def store(url: str, kept: Cached) {
    if url not in cache and len(cache) >= MAX_CACHE_ENTRIES {
        del cache[next(iter(cache))];
    }
    cache[url] = kept;
}

def refresh(url: str, ttl: int) -> any {
    try {
        value = request(url);
        store(url, Cached(value, time.time() + ttl));
        return value;
    } except Exception as e {
        # A stalling endpoint fails fast for a minute instead of costing every visitor the full timeout.
        # A stale value keeps being served, but its next refresh also waits out the cool-down.
        (old, t) = (cache.get(url), time.time() + FAILURE_TTL);
        store(url, Cached(old.value, t) if old and not old.failed else Cached(None, t, True));
        raise e;
    }
}

def refresh_quietly(url: str, ttl: int) {
    try {
        refresh(url, ttl);
    } except Exception {}
}

"""Stale-while-revalidate: after the first fetch nobody waits; an expired entry is served at once and refreshed
beside the call. No ttl = always a fresh call."""
def fetch_json(url: str, ttl: int = 0) -> any {
    if not ttl {
        return request(url);
    }
    (now, hit) = (time.time(), cache.get(url));
    if hit is None or (hit.failed and hit.fresh_until < now) {
        return refresh(url, ttl);
    }
    if hit.failed {
        raise RecentFailure(f"Request failed recently: {url.split('?')[0]}");
    }
    if hit.fresh_until < now {
        hit.fresh_until = now + FETCH_TIMEOUT;  # one refresher, however many ask meanwhile
        flow refresh_quietly(url, ttl);
    }
    return hit.value;
}

"""Finnhub's JSON for a path, or None after logging why not."""
def finnhub(what: str, symbol: str, path: str, ttl: int = 0) -> any {
    try {
        return fetch_json(FINNHUB + path, ttl);
    } except Exception as e {
        log_failure(what, symbol, e);
        return None;
    }
}

def to_quote(q: any) -> Quote | None {
    if not num(dig(q, "c")) {
        return None;
    }
    return Quote(
        *[num(q.get(k)) for k in ["c", "d", "dp", "h", "l", "o", "pc"]], at=int(num(q.get("t")))
    );
}

"""Finnhub's quote, or None when it has no price. Real-time by default; shared views pass a short cache to stay
inside Finnhub's 60 req/min."""
def get_quote(symbol: str, ttl: int = 0) -> Quote | None {
    return to_quote(finnhub("quote", symbol, f"/quote?symbol={enc(symbol)}", ttl));
}

"""Upper-cased, well-formed, each once, at most a watchlist's worth."""
def clean_symbols(symbols: list[str]) -> list[str] {
    upper = [s.strip().upper() for s in symbols];
    return list(
        dict.fromkeys([s for s in upper if re.fullmatch(r"[A-Z0-9.:\-]{1,20}", s)])
    )[:MAX_SYMBOLS];
}

"""Shared, short-lived quotes for anything shown live on screen, by symbol. Symbols the free plan can't price are
skipped instead of spending a request on a 403; one without a price is left out."""
def:pub live_quotes(symbols: list[str]) -> dict[str, Quote] {
    wanted = [s for s in clean_symbols(symbols) if has_finnhub_quotes(s)];
    found = [wait t for t in [flow get_quote(s, quote_ttl()) for s in wanted]];
    return {s: q for (s, q) in zip(wanted, found) if q};
}

"""Polled by on-screen prices. Signed-in only and capped, so nobody can burn the shared Finnhub quota. Counted per
symbol: unseen tickers each cost a Finnhub call. A 50-symbol watchlist polled every 15 s uses about 200 a minute; the
cap stops one free account from draining the shared key pool. Past it the answer is empty."""
def:protect quotes(symbols: list[str]) -> dict[str, Quote] {
    wanted = clean_symbols(symbols);
    if any([consume_limit("quotes", jid(root), 300, 60) for _ in wanted]) {
        return {};
    }
    return live_quotes(wanted);
}

"""Profiles exist for stocks Finnhub free covers; crypto pairs and non-US listings have none. Cached for a day."""
def:pub get_company_profile(symbol: str) -> Profile | None {
    p = finnhub("profile", symbol, f"/stock/profile2?symbol={enc(symbol)}", 86400)
        if has_finnhub_company_data(symbol)
        else None;
    if not isinstance(p, dict) {
        return None;
    }
    cap = p.get("marketCapitalization");
    fields = "name ticker currency exchange logo finnhubIndustry weburl".split();
    return Profile(*[str(p.get(k) or "") for k in fields], float(cap) if is_num(cap) else None);
}

"""The indicated annual dividend yield, where Finnhub has one."""
def:pub get_stock_metrics(symbol: str) -> float | None {
    if not has_finnhub_company_data(symbol) {
        return None;
    }
    m = finnhub("stock metrics", symbol, f"/stock/metric?symbol={enc(symbol)}&metric=all", 3600);
    found = dig(m, "metric", "dividendYieldIndicatedAnnual");
    return float(found) if is_num(found) else None;
}

"""symbol -> TradingView exchange for every US listing, from one daily download of Finnhub's US symbol list (~31k
listings, also covers ETFs, which have no profile). Finnhub serves it as a static file rebuilt daily with no delta or
ETag support: ~1.3 MB compressed, 7 MB of JSON. Kept as a compact map, not in the cache."""
def load_us_listings {
    try {
        listed = [
            (str(l.get("symbol") or "").upper(), tradingview_exchange_for_mic(l.get("mic")))
            for l in request(f"{FINNHUB}/stock/symbol?exchange=US")
        ];
        us_listings = {s: ex for (s, ex) in listed if s and ex};
        us_listings_fresh_until = time.time() + 86400;
    } except Exception as e {
        log_failure("US symbol list", "US", e);
    }
}

"""TradingView exchange of a US listing (AAPL -> NASDAQ, SPY -> AMEX), or None when unknown or not a US listing."""
def:pub get_tradingview_exchange(symbol: str) -> str | None {
    if not has_finnhub_company_data(symbol) or not finnhub_keys() {
        return None;
    }
    if us_listings_fresh_until < time.time() {
        # One download at a time, and none again for a minute while Finnhub is failing. A stale map keeps being
        # served while it is replaced.
        us_listings_fresh_until = time.time() + FAILURE_TTL;
        if us_listings {
            flow load_us_listings();
        } else {
            load_us_listings();
        }
    }
    return us_listings.get(symbol.upper());
}

def yahoo_chart(symbol: str, span: str, ttl: int) -> any {
    return dig(
        fetch_json(f"{YAHOO}{enc(symbol)}?interval=1d&range={span}", ttl), "chart", "result", 0
    );
}

"""A chart's daily closes, oldest first. Gaps (null closes on holidays or halts) are dropped."""
def chart_closes(chart: any) -> list[float] {
    return [float(c) for c in dig(chart, "indicators", "quote", 0, "close") or [] if is_num(c)];
}

"""Today's quote from a chart: Yahoo's own day change when it sends one, else the last two daily closes (TASI and
the WIG indices only ever return one daily bar, so they need the former). longName first: GPW short names look like
"PKN C.XWAR PLN"."""
def daily_quote_from_chart(chart: any, fallback_currency: str = "USD") -> DailyQuote | None {
    closes = chart_closes(chart);
    if not closes {
        return None;
    }
    meta: any = dig(chart, "meta") or {};
    prev = closes[-2] if len(closes) > 1 else 0.0;
    price = num(meta.get("regularMarketPrice"), closes[-1]);
    change = num(meta.get("fulldayChange"), price - prev if prev else 0.0);
    pct = num(meta.get("regularMarketChangePercent"), change / prev * 100 if prev else 0.0);
    name = meta.get("longName") or meta.get("shortName") or "";
    return DailyQuote(price, change, pct, meta.get("currency") or fallback_currency, name);
}

def yahoo_daily_quote(symbol: str) -> DailyQuote | None {
    yahoo = yahoo_symbol(symbol);
    if yahoo is None {
        return None;
    }
    try {
        return daily_quote_from_chart(
            yahoo_chart(yahoo, "5d", max(quote_ttl(), 300)), yahoo_currency(yahoo)
        );
    } except Exception as e {
        log_failure("Yahoo daily quote", symbol, e);
        return None;
    }
}

"""Daily Tadawul and Warsaw quotes from Yahoo Finance (free, no key, covers .SR and .WA), keyed by the symbol passed
in. One chart call per symbol (no batch endpoint without login) behind the shared cache (hourly in cached mode, 5
minutes in realtime), so the Saudi or Polish dashboard costs ~17-19 requests per refresh, not per user."""
def:pub yahoo_daily_quotes(symbols: list[str]) -> dict[str, DailyQuote] {
    found = [wait t for t in [flow yahoo_daily_quote(s) for s in symbols]];
    return {s: q for (s, q) in zip(symbols, found) if q};
}

"""Alert symbols (Finnhub's: US tickers and Binance pairs) as Yahoo chart symbols: AAPL -> AAPL, BRK.B -> BRK-B,
BINANCE:BTCUSDT -> BTC-USD (USDT tracks the dollar). None when Yahoo has no matching daily series."""
def yahoo_chart_symbol(symbol: str) -> str | None {
    upper = symbol.strip().upper();
    pair = re.fullmatch(r"BINANCE:([A-Z0-9]{2,15})USDT", upper);
    if pair {
        return f"{pair.group(1)}-USD";
    }
    return upper.replace(".", "-")
        if re.fullmatch(r"[A-Z][A-Z0-9]{0,9}(\.[A-Z])?", upper)
        else None;
}

"""A chart's positive daily closes plus Yahoo's latest price (the last close without one); None for an empty chart."""
def closes_from_chart(chart: any) -> Closes | None {
    closes = [c for c in chart_closes(chart) if c > 0];
    price = num(dig(chart, "meta", "regularMarketPrice"));
    return Closes(closes, price if price > 0 else closes[-1]) if closes else None;
}

"""A year of daily bars covers SMA 200 (about 250 trading days). The average moves once a day, so the response is
cached for an hour and shared: one request per symbol per hour, however many alerts or checks use it. None means
Yahoo couldn't be reached (timeout, 5xx), worth retrying; an empty history means it has none for this symbol (404,
an empty chart), which retrying won't change."""
def daily_closes(symbol: str) -> Closes | None {
    yahoo = yahoo_chart_symbol(symbol);
    if yahoo is None {
        return Closes();
    }
    try {
        return closes_from_chart(yahoo_chart(yahoo, "1y", 3600)) or Closes();
    } except Exception as e {
        log_failure("daily closes", symbol, e);
        return None;
    }
}

def watchlist_row(symbol: str, yahoo: DailyQuote | None) -> WatchlistRow {
    p = Profile();
    y = yahoo;
    if y is None {
        covered = has_finnhub_quotes(symbol);
        q = (get_quote(symbol, quote_ttl()) if covered else None) or Quote();
        p = (get_company_profile(symbol) if covered else None) or p;
        y = DailyQuote(q.price, q.change, q.change_percent, p.currency or "USD", p.name);
    }
    # pe_ratio stays 0: Finnhub's quote and profile2 don't give a real-time P/E, and the metric endpoint would cost
    # another call per symbol.
    (c, n) = (y.currency, y.name or symbol);
    return WatchlistRow(symbol, y.price, y.change, y.change_percent, c, n, p.logo, p.market_cap);
}

"""Price, change, market cap and name for each symbol. Finnhub free doesn't price Tadawul or Warsaw; Yahoo does
(delayed)."""
def:pub get_watchlist_data(symbols: list[str]) -> list[WatchlistRow] {
    yahoo = yahoo_daily_quotes([s for s in symbols if is_yahoo_symbol(s)]);
    return [wait t for t in [flow watchlist_row(s, yahoo.get(s)) for s in symbols]];
}

def valid_article(a: any) -> bool {
    return isinstance(a, dict)
        and all([a.get(k) for k in ["headline", "summary", "url", "datetime"]]);
}

"""`index` keeps ids apart within one answer: the same company article can come back for two symbols."""
def format_article(
    a: any, company: bool, symbol: str = "", index: int = 0, fallback_source: str = ""
) -> Article {
    return Article(
        id=(int(time.time() * 1000) if company else int(num(a.get("id")))) + index,
        headline=a["headline"].strip(),
        summary=a["summary"].strip()[:200 if company else 150] + "...",
        source=a.get("source") or fallback_source or ("Company News" if company else "Market News"),
        url=a["url"],
        datetime=int(a["datetime"]),
        image=a.get("image") or "",
        category="company" if company else a.get("category") or "general",
        related=symbol if company else a.get("related") or "",
    );
}

def company_news(symbol: str, span: str) -> list[any] {
    return [
        a
        for a in finnhub("company news", symbol, f"/company-news?symbol={enc(symbol)}&{span}", 300)
            or []
        if valid_article(a)
    ];
}

"""Six articles: company news of the last five days for the symbols Finnhub covers, picked round-robin and newest
first, else general market news. The sources label articles Finnhub leaves without one (pages pass translations)."""
def:pub get_news(
    symbols: list[str] = [], company_source: str = "", market_source: str = ""
) -> list[Article] {
    wanted = [s for s in [s.strip().upper() for s in symbols] if s and has_finnhub_company_data(s)];
    today = datetime.now(timezone.utc).date();
    span = f"from={(today - timedelta(days=5)).isoformat()}&to={today.isoformat()}";
    per_symbol = [wait t for t in [flow company_news(s, span) for s in wanted]];
    picked: list[Article] = [];
    for turn in range(MAX_ARTICLES) {
        for (s, articles) in zip(wanted, per_symbol) {
            if turn < len(articles) and len(picked) < MAX_ARTICLES {
                picked.append(format_article(articles[turn], True, s, len(picked), company_source));
            }
        }
    }
    if picked {
        return sorted(picked, key=lambda (a: Article) -> int { -a.datetime });
    }
    general = fetch_json(f"{FINNHUB}/news?category=general", 300) or [];
    unique = {
        f"{a.get('id')}-{a.get('url')}-{a.get('headline')}": a
        for a in general
        if valid_article(a)
    };
    return [
        format_article(a, False, index=i, fallback_source=market_source)
        for (i, a) in enumerate(list(unique.values())[:MAX_ARTICLES])
    ];
}

# Default list in the search palette: shown on every page, so static (Finnhub's free tier is 60 req/min)
glob POPULAR_STOCKS: list[Stock] = [
    Stock(*item.split("="), kind="Common Stock")
    for item in ("AAPL=Apple Inc=NASDAQ, MSFT=Microsoft Corp=NASDAQ, NVDA=NVIDIA Corp=NASDAQ, GOOGL=Alphabet Inc=NASDAQ, "
        "AMZN=Amazon.com Inc=NASDAQ, META=Meta Platforms Inc=NASDAQ, TSLA=Tesla Inc=NASDAQ, NFLX=Netflix Inc=NASDAQ, "
        "AMD=Advanced Micro Devices Inc=NASDAQ, JPM=JPMorgan Chase & Co=NYSE").split(", ")
];

def signed_in -> bool {
    try {
        return root is not None;
    } except RuntimeError {
        return False;
    }
}

"""Up to 15 matches for a query; the popular list for none. Only signed-in users may spend Finnhub quota on
searches: anyone else gets no matches."""
def:pub search_stocks(query: str = "") -> list[Stock] {
    if not query.strip() {
        return POPULAR_STOCKS;
    }
    if not signed_in() {
        return [];
    }
    found = dig(finnhub("search", query, f"/search?q={enc(query.strip())}", 1800), "result");
    return [stock_of(r) for r in (found if isinstance(found, list) else [])[:15]];
}

"""A search match; its exchange is the symbol's Finnhub suffix (7203.T -> T), else US."""
def stock_of(r: any) -> Stock {
    s = str(r.get("symbol") or "").upper();
    (_, dot, suffix) = s.rpartition(".");
    exchange = suffix if dot and suffix in TV_EXCHANGE else "US";
    return Stock(s, r.get("description") or s, exchange, r.get("type") or "Stock");
}
