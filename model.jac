"""What the server and the pages share: the market-data types, and the pure rules on symbols, sessions and moving
averages (no clock, no network), compiled into both sides."""

obj Pulse {
    has symbol: str,
        label: str,
        # Set = a native tile with our own cached Finnhub quote; otherwise a TradingView quote
        finnhub: str = "";
}

obj Group {
    has title: str,
        symbols: list[tuple[str, str]];  # (TradingView symbol, name)
}

obj Market {
    has id: str,
        name: str,
        short: str,
        time_zone: str,
        hours: str,  # "HH:MM-HH:MM" of the local day, "24/7" or "24/5"
        feed: str,  # Live | Delayed | End of day
        pulse: list[Pulse],
        groups: list[Group],
        news: str = "stock",  # stock | crypto | forex
        heatmap: str = "",  # stocks | crypto | none
        # Priced from Yahoo instead of TradingView: tiles, leaders and quotes are our own components
        yahoo: bool = False,
        trading_days: list[int] = [1, 2, 3, 4, 5];  # 0 = Sunday
}

obj Clock {
    has weekday: int,  # 0 = Sunday
        minutes: int,  # of the local day
        time: str;  # "HH:MM"
}

obj MarketSession {
    has phase: str,  # pre | open | after | closed
        line: str;
}

obj Quote {
    has price: float = 0.0,
        change: float = 0.0,
        change_percent: float = 0.0,
        high: float = 0.0,
        low: float = 0.0,
        open: float = 0.0,
        prev_close: float = 0.0,
        at: int = 0;  # unix time of the last trade
}

obj DailyQuote {
    has price: float,
        change: float,
        change_percent: float,
        currency: str,
        name: str;
}

obj Closes {
    has closes: list[float] = [],  # daily, oldest first
        price: float | None = None;
}

obj Profile {
    has name: str = "",
        ticker: str = "",
        currency: str = "",
        exchange: str = "",
        logo: str = "",
        industry: str = "",
        weburl: str = "",
        market_cap: float | None = None;  # millions, as Finnhub sends it
}

obj WatchlistRow {
    has symbol: str,
        price: float,
        change: float,
        change_percent: float,
        currency: str,
        name: str,
        logo: str = "",
        market_cap: float | None = None,
        pe_ratio: float = 0.0;
}

obj Stock {
    has symbol: str,
        name: str,
        exchange: str,
        kind: str,
        in_watchlist: bool = False;
}

obj Article {
    has id: int,
        headline: str,
        summary: str,
        source: str,
        url: str,
        datetime: int,
        image: str,
        category: str,
        related: str;
}

"""A table written as text: "A=1 B=2" -> {"A": "1", "B": "2"}."""
def table(text: str) -> dict[str, str] {
    return {k: v for (k, _, v) in [pair.partition("=") for pair in text.split()]};
}

# Finnhub's dot suffix (2330.TW) -> TradingView's exchange prefix (TWSE:2330), by region. .NS charts on BSE: NSE is
# blocked in free TradingView embeds and the same ticker renders there. Prague is PSECZ (TradingView's PSE is the
# Philippines).
glob TV_EXCHANGE: dict[str, str] = table(
    """TW=TWSE TWO=TPEX T=TSE HK=HKEX SS=SSE SZ=SZSE KS=KRX KQ=KRX SI=SGX AX=ASX NZ=NZX BO=BSE NS=BSE BK=SET JK=IDX KL=MYX
    L=LSE IL=LSE DE=XETR F=FWB PA=EURONEXT AS=EURONEXT BR=EURONEXT LS=EURONEXT MI=MIL MC=BME ST=OMXSTO HE=OMXHEX
    CO=OMXCOP OL=OSL SW=SIX VI=VIE WA=GPW PR=PSECZ AT=ATHEX IS=BIST
    TO=TSX V=TSXV SA=BMFBOVESPA MX=BMV BA=BCBA
    TA=TASE JO=JSE SR=TADAWUL""",
);

# Exchanges whose candle chart TradingView refuses in free embeds ("This symbol doesn't exist"), each confirmed
# with two tickers. Financials, technicals and profile still work for them.
# ponytail: static list, re-test with a real browser user agent if TradingView changes its licensing.
glob CHART_BLOCKED: set[str] = set(
    "TSE HKEX LSE KRX TWSE SGX NZX SET MYX BIST TSXV BMV JSE TADAWUL".split()
);

# Finnhub's US symbol list tags each listing with its venue's MIC; TradingView names the same venues its own way.
# NYSE Arca listings (SPY) live under AMEX on TradingView, Cboe BZX listings (ARKK) under CBOE.
glob US_MIC: dict[str, str] = table("XNAS=NASDAQ XNYS=NYSE XASE=AMEX ARCX=AMEX BATS=CBOE OOTC=OTC");

# Finnhub writes share classes and symbols with - or &; on these exchanges TradingView only knows its own spelling:
# BAJAJ-AUTO.NS -> BSE:BAJAJ_AUTO, M&M.NS -> BSE:M_M, ERIC-B.ST -> OMXSTO:ERIC_B, BT-A.L -> LSE:BT.A. TSX accepts RCI-B.
glob TICKER_SEPARATOR: dict[str, str] = {"BSE": "_", "OMXSTO": "_", "OMXCOP": "_", "LSE": "."};

"""Listed outside the US (a known exchange suffix like .L, .T, .NS). Class shares such as BRK.B are not."""
def is_international_symbol(symbol: str) -> bool {
    (ticker, _, suffix) = symbol.upper().rpartition(".");
    return bool(ticker) and suffix in TV_EXCHANGE;
}

"""A Finnhub symbol as TradingView spells it: 2330.TW -> TWSE:2330, AAPL -> AAPL."""
def tradingview_symbol(symbol: str) -> str {
    upper = symbol.upper();
    if not is_international_symbol(upper) {
        return upper;
    }
    (ticker, _, suffix) = upper.rpartition(".");
    exchange = TV_EXCHANGE[suffix];
    # Finnhub pads Hong Kong codes (0700.HK); TradingView doesn't (HKEX:700)
    if exchange == "HKEX" and ticker.isdigit() {
        ticker = str(int(ticker));
    }
    if exchange in TICKER_SEPARATOR {
        sep = TICKER_SEPARATOR[exchange];
        ticker = ticker.replace("-", sep).replace("&", sep);
    }
    return f"{exchange}:{ticker}";
}

def is_chart_embeddable(tv_symbol: str) -> bool {
    return tv_symbol.split(":")[0] not in CHART_BLOCKED;
}

def tradingview_symbol_url(tv_symbol: str) -> str {
    return f"https://www.tradingview.com/symbols/{tv_symbol.replace(':', '-', 1)}/";
}

def tradingview_exchange_for_mic(mic: str | None) -> str | None {
    return US_MIC.get((mic or "").upper());
}

"""Prefix a bare US ticker with its exchange (AAPL -> NASDAQ:AAPL). The technical-analysis widget answers
"Permission denied" for bare US tickers and "Invalid symbol" for the wrong exchange, so an unknown one stays bare."""
def qualify_tradingview_symbol(tv_symbol: str, exchange: str | None) -> str {
    return tv_symbol
        if not tv_symbol or not exchange or ":" in tv_symbol
        else f"{exchange}:{tv_symbol}";
}

"""Finnhub free can price (and so alert on) US listings and Binance pairs only."""
def has_finnhub_quotes(symbol: str) -> bool {
    upper = symbol.upper();
    return upper.startswith("BINANCE:")
        or (":" not in upper and not is_international_symbol(upper));
}

"""Company data (profile, metrics, company news) on Finnhub free: US listings only, not crypto pairs; elsewhere it
answers 403."""
def has_finnhub_company_data(symbol: str) -> bool {
    return ":" not in symbol and has_finnhub_quotes(symbol);
}

# Yahoo Finance prices the exchanges the free sources price badly: Tadawul (.SR) is blocked in TradingView's free
# embeds and on Finnhub free; Warsaw (GPW, .WA) renders in embeds but only end of day, where Yahoo is ~15 minutes
# delayed.
obj YahooExchange {
    has suffix: str,
        currency: str,
        numeric: bool,  # tickers are all digits (else letters and digits)
        indices: dict[str, str];  # index ticker -> its Yahoo symbol
}

glob YAHOO_EXCHANGES: dict[str, YahooExchange] = {
    "TADAWUL": YahooExchange("SR", "SAR", True, {"TASI": "^TASI.SR"}),
    "GPW": YahooExchange(
        "WA", "PLN", False, table("WIG20=WIG20.WA WIG=WIG.WA MWIG40=MWIG40.WA SWIG80=SWIG80.WA")
    ),
};

glob YAHOO_INDICES: set[str] = {y for ex in YAHOO_EXCHANGES.values() for y in ex.indices.values()};

""""2222.SR" or "TADAWUL:2222" -> "2222.SR"; "PKN.WA" or "GPW:PKN" -> "PKN.WA". Indices: "TADAWUL:TASI" ->
"^TASI.SR", "GPW:WIG20" -> "WIG20.WA". Anything else -> None."""
def yahoo_symbol(symbol: str) -> str | None {
    upper = symbol.strip().upper();
    if upper in YAHOO_INDICES {
        return upper;
    }
    for (prefix, ex) in YAHOO_EXCHANGES.items() {
        if upper.startswith(prefix + ":") {
            ticker = upper[len(prefix) + 1:];
        } elif upper.endswith("." + ex.suffix) {
            ticker = upper[:-len(ex.suffix) - 1];
        } else {
            continue;
        }
        if ticker in ex.indices {
            return ex.indices[ticker];
        }
        ok = ticker.isascii() and (ticker.isdigit() if ex.numeric else ticker.isalnum());
        return f"{ticker}.{ex.suffix}" if ok else None;
    }
    return None;
}

def is_yahoo_symbol(symbol: str) -> bool {
    return yahoo_symbol(symbol) is not None;
}

""""TADAWUL:2222" -> "2222.SR", "GPW:PKN" -> "PKN.WA": the symbols our stock pages use. Indices have no stock page."""
def yahoo_app_symbol(tv_symbol: str) -> str | None {
    yahoo = yahoo_symbol(tv_symbol);
    return None if yahoo in YAHOO_INDICES else yahoo;
}

"""The exchange's currency for a Yahoo symbol ("PKN.WA" -> "PLN"), for when Yahoo leaves meta.currency out."""
def yahoo_currency(symbol: str) -> str {
    for ex in YAHOO_EXCHANGES.values() {
        if symbol.upper().endswith("." + ex.suffix) {
            return ex.currency;
        }
    }
    return "USD";
}

# NYSE trading sessions, in New York minutes-of-day.
# ponytail: exchange holidays and half-days are ignored; add a holiday list if it matters.
glob PRE: int = 4 * 60,
     OPEN: int = 9 * 60 + 30,
     CLOSE: int = 16 * 60,
     AFTER_END: int = 20 * 60,
     DAY: int = 24 * 60;

def format_span(total: int) -> str {
    (d, h, m) = (total // DAY, total % DAY // 60, total % 60);
    return f"{d}d {h}h" if d else f"{h}h {m:02d}m" if h else f"{m}m";
}

"""The NYSE session at a New York weekday (0 = Sunday) and minute of the day."""
def session_of(weekday: int, minutes: int) -> MarketSession {
    # (phase, from, until, what the countdown is to, when that is)
    phases = [
        ("open", OPEN, CLOSE, "Market open · closes", CLOSE),
        ("pre", PRE, OPEN, "Pre-market · opens", OPEN),
        ("after", CLOSE, AFTER_END, "After hours · ends", AFTER_END),
        ("closed", 0, PRE, "Market closed · opens", OPEN),
    ];
    for (phase, start, end, line, at) in phases {
        if 1 <= weekday <= 5 and start <= minutes < end {
            return MarketSession(phase, f"{line} in {format_span(at - minutes)}");
        }
    }
    # Next weekday open, counting whole days from today
    days = 1;
    while not 1 <= (weekday + days) % 7 <= 5 {
        days += 1;
    }
    return MarketSession(
        "closed", f"Market closed · opens in {format_span(days * DAY + OPEN - minutes)}"
    );
}

# Moving-average price alerts (issue #59). Finnhub's indicator endpoints need a paid plan, so the simple moving
# average is computed here from free daily closes on Yahoo Finance's chart endpoint.
glob SMA_PERIODS: list[int] = [20, 50, 100, 200];

def is_sma_period(period: int) -> bool {
    return period in SMA_PERIODS;
}

"""Mean of the last `period` closes; None until there are that many."""
def sma(closes: list[float], period: int) -> float | None {
    return sum(closes[-period:]) / period if 1 <= period <= len(closes) else None;
}

"""Which side of the average the price is on: "ABOVE", "BELOW", or "" exactly on it, which is neither, so it keeps
whatever side came before."""
def side_of(price: float, average: float) -> str {
    return "ABOVE" if price > average else "BELOW" if price < average else "";
}

"""TradingView's "crossing up/down": the previous check saw the price on the other side and this one sees it on the
alert's side. Unlike a fixed-price alert, a price that is already past the average when the alert is set waits for the
next cross instead of firing at once. No previous side yet means no cross."""
def has_crossed(condition: str, last_side: str, price: float, average: float) -> bool {
    return bool(last_side) and last_side != condition and side_of(price, average) == condition;
}

# Watchlists, named lists and alerts. The caps are shared so pages can say them in their messages.
glob MAX_WATCHLIST: int = 50,
     MAX_LISTS: int = 10,
     MAX_LIST_SYMBOLS: int = 50,
     MAX_LIST_NAME: int = 60,
     # The checker re-prices every active alert's symbol through Finnhub every 5 minutes
     MAX_ACTIVE_ALERTS: int = 50;

obj WatchItem {
    has symbol: str,
        company: str,
        added_at: float = 0.0;  # unix time, like every time below
}

"""A named list ("Banks"): an extra grouping beside the starred watchlist."""
obj ListSummary {
    has id: str,
        name: str,
        count: int,
        symbols: list[WatchItem];
}

"""A fixed-price alert, or (target "SMA") a cross of the moving average of the last sma_period daily closes; then
target_price holds the average as last computed."""
obj AlertInfo {
    has id: str,
        symbol: str,
        condition: str,  # ABOVE | BELOW
        target_price: float,
        target: str = "PRICE",  # PRICE | SMA
        sma_period: int = 0,
        active: bool = True,
        triggered: bool = False,
        expires_at: float = 0.0,
        created_at: float = 0.0;
}

"""What a write answers: `error` is "" when it worked, else a code the page translates (a key of the Errors
messages for the watchlist and lists; for alerts see create_alert), then the list or alert made, where one was."""
obj Saved {
    has error: str = "",
        made: ListSummary | None = None,
        alert: AlertInfo | None = None;
}
