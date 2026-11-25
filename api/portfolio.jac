"""What each signed-in caller keeps, under their own root: the starred watchlist, named lists and price alerts.
Every endpoint works on `root`, so nothing here can reach another caller's data."""
import re;
import threading;
import time;
import from stdjac { remove }

# Tickers as Finnhub writes them (AAPL, BRK.B, RELIANCE.NS, M&M.NS, 0700.HK, BINANCE:BTCUSDT). Endpoints take
# untrusted input, and every symbol here becomes Finnhub calls on /watchlist and in the news digest.
glob SYMBOL: str = r"[A-Z0-9][A-Z0-9.&:-]{0,24}",
     # Alerts are stricter, a ticker or a Binance pair: the symbol ends up in alert emails.
     ALERT_SYMBOL: str = r"BINANCE:[A-Z0-9]{2,20}|[A-Z0-9][A-Z0-9.-]{0,14}",
     MAX_COMPANY: int = 120,
     ALERT_DAYS: int = 90,
     # Calls run at once: a cap or a no-duplicates rule is checked and written under this, so two tabs can't both pass
     writing: threading.Lock = threading.Lock(),
     # Tests put fakes here
     quote_of: Callable[[str], Quote | None] = lambda (s: str) -> Quote | None { get_quote(s) },
     closes_of: Callable[[str], Closes | None] = daily_closes;

"""A symbol starred (under the root) or filed in a named list (under it)."""
node Pick {
    has symbol: str,
        company: str,
        added_at: float;
}

node NamedList {
    has name: str,
        created_at: float;
}

"""For an SMA alert target_price is the average as last computed (for the list and the email) and last_side is where
the price was at the last check."""
node Alert {
    has symbol: str,
        condition: str,
        target_price: float,
        target: str = "PRICE",
        sma_period: int = 0,
        last_side: str = "",
        active: bool = True,
        triggered: bool = False,
        expires_at: float = 0.0,
        created_at: float = 0.0;
}

"""When a root's caller was last here, for the inactive-user check: the accounts plugin's own records are out of the
app's reach."""
node Visit {
    has seen: float = 0.0;
}

"""Mark the caller seen: at most hourly, to spare the store a write per call."""
def visit_now -> Visit {
    found = [root --> [?:Visit]];
    me = found[0] if found else root ++> Visit();
    if time.time() - me.seen > 3600 {
        me.seen = time.time();
    }
    return me;
}

"""A cleaned list name; "" when it would be empty or too long."""
def normalize_list_name(raw: str) -> str {
    name = " ".join(raw.split());
    return name if len(name) <= MAX_LIST_NAME else "";
}

"""A ticker cleaned the way the watchlist does; "" when it is not one."""
def normalize_symbol(raw: str) -> str {
    symbol = raw.strip().upper();
    return symbol if re.fullmatch(SYMBOL, symbol) else "";
}

def normalize_company(raw: str) -> str {
    return raw.strip()[:MAX_COMPANY];
}

def item(p: Pick) -> WatchItem {
    return WatchItem(p.symbol, p.company, p.added_at);
}

"""File a symbol under the caller's root or one of their lists; False when the holder is full. One that is already
there is replaced in place, so a holder never has the same ticker twice: the newer company name wins, and in a list
the day it was first added is kept."""
def keep(holder: Root | NamedList, cap: int, symbol: str, company: str, restamp: bool) -> bool {
    with writing {
        held = [holder --> [?:Pick]];
        for p in held {
            if p.symbol == symbol {
                (p.company, p.added_at) = (company, time.time() if restamp else p.added_at);
                return True;
            }
        }
        if len(held) < cap {
            holder ++> Pick(symbol, company, time.time());
        }
        return len(held) < cap;
    }
}

"""Take a symbol out of a holder; one that is not there is no error."""
def drop(holder: Root | NamedList, symbol: str) {
    for p in [holder --> [?:Pick]] {
        if p.symbol == symbol {
            remove(p);
        }
    }
}

"""The starred watchlist, newest first. The sidebar asks on every page, which is what keeps `seen` current."""
def:protect get_watchlist -> list[WatchItem] {
    visit_now();
    return sorted(
        [item(p) for p in [root --> [?:Pick]]], key=lambda (w: WatchItem) -> float { -w.added_at }
    );
}

def:protect in_watchlist(symbol: str) -> bool {
    return symbol.upper() in [p.symbol for p in [root --> [?:Pick]]];
}

"""Star a symbol. Errors: symbolInvalid, watchlistFull."""
def:protect add_to_watchlist(symbol: str, company: str) -> Saved {
    ticker = normalize_symbol(symbol);
    if not ticker {
        return Saved("symbolInvalid");
    }
    kept = keep(root, MAX_WATCHLIST, ticker, normalize_company(company), True);
    return Saved("" if kept else "watchlistFull");
}

def:protect remove_from_watchlist(symbol: str) {
    drop(root, symbol.upper());
}

def summary(of: NamedList) -> ListSummary {
    symbols = [item(p) for p in [of --> [?:Pick]]];
    return ListSummary(jid(of), of.name, len(symbols), symbols);
}

"""The caller's own list with that id. An id that is malformed, unknown or someone else's all look the same: None."""
def find_list(list_id: str) -> NamedList | None {
    for candidate in [root --> [?:NamedList]] {
        if jid(candidate) == list_id {
            return candidate;
        }
    }
    return None;
}

"""The caller's named lists, newest first."""
def:protect get_lists -> list[ListSummary] {
    lists = [root --> [?:NamedList]][::-1];
    return [
        summary(l)
        for l in sorted(lists, key=lambda (l: NamedList) -> float { -l.created_at })
    ];
}

"""Errors: listNameInvalid, listLimit, listExists (one name per caller, so a list never needs disambiguating)."""
def:protect create_list(name: str) -> Saved {
    clean = normalize_list_name(name);
    if not clean {
        return Saved("listNameInvalid");
    }
    with writing {
        mine = [root --> [?:NamedList]];
        if len(mine) >= MAX_LISTS or clean in [l.name for l in mine] {
            return Saved("listLimit" if len(mine) >= MAX_LISTS else "listExists");
        }
        return Saved(made=summary(root ++> NamedList(clean, time.time())));
    }
}

"""Errors: symbolInvalid, listNotFound, listFull."""
def:protect add_to_list(list_id: str, symbol: str, company: str) -> Saved {
    ticker = normalize_symbol(symbol);
    found = find_list(list_id);
    if not ticker or found is None {
        return Saved("listNotFound" if ticker else "symbolInvalid");
    }
    kept = keep(found, MAX_LIST_SYMBOLS, ticker, normalize_company(company) or ticker, False);
    return Saved("" if kept else "listFull");
}

"""Errors: symbolInvalid, listNotFound."""
def:protect remove_from_list(list_id: str, symbol: str) -> Saved {
    ticker = normalize_symbol(symbol);
    found = find_list(list_id);
    if not ticker or found is None {
        return Saved("listNotFound" if ticker else "symbolInvalid");
    }
    drop(found, ticker);
    return Saved();
}

"""Errors: listNotFound."""
def:protect delete_list(list_id: str) -> Saved {
    found = find_list(list_id);
    if found is None {
        return Saved("listNotFound");
    }
    remove(found);
    return Saved();
}

def info(a: Alert) -> AlertInfo {
    what = (a.symbol, a.condition, a.target_price, a.target, a.sma_period);
    return AlertInfo(jid(a), *what, a.active, a.triggered, a.expires_at, a.created_at);
}

"""The caller's alerts, newest first."""
def:protect get_alerts -> list[AlertInfo] {
    alerts = [root --> [?:Alert]][::-1];
    return [info(a) for a in sorted(alerts, key=lambda (a: Alert) -> float { -a.created_at })];
}

def:protect delete_alert(alert_id: str) {
    for a in [root --> [?:Alert]] {
        if jid(a) == alert_id {
            remove(a);
        }
    }
}

"""Why an alert can't be made, "" when it can. Only validated fields are stored, and the 90 days and `triggered` are
never the caller's to set."""
def alert_error(symbol: str, condition: str, price: float, is_sma: bool, period: int) -> str {
    active = len([a for a in [root --> [?:Alert]] if a.active]);
    refusals = [
        (not is_realtime(), "alertsOff"),
        (not re.fullmatch(ALERT_SYMBOL, symbol), "symbolInvalid"),
        (condition not in ["ABOVE", "BELOW"], "conditionInvalid"),
        # The alert checker prices symbols through Finnhub, whose free plan covers US stocks and crypto
        (not has_finnhub_quotes(symbol), "marketUnsupported"),
        (not is_sma and not 0 < price < float("inf"), "priceInvalid"),
        (is_sma and not is_sma_period(period), "periodInvalid"),
        (active >= MAX_ACTIVE_ALERTS, "alertLimit"),
    ];
    return ([code for (refused, code) in refusals if refused] + [""])[0];
}

"""A fixed-price alert, or with target "SMA" a cross of the sma_period-day moving average (target_price is then
ignored). Errors: alertsOff (cached mode), symbolInvalid, conditionInvalid, marketUnsupported, priceInvalid,
periodInvalid, alertLimit, and for SMA historyUnavailable (try again) and notEnoughHistory."""
def:protect create_alert(
    symbol: str,
    condition: str,
    target_price: float = 0.0,
    target: str = "PRICE",
    sma_period: int = 0,
) -> Saved {
    ticker = symbol.strip().upper();
    error = alert_error(ticker, condition, target_price, target == "SMA", sma_period);
    if error {
        return Saved(error);
    }
    now = time.time();
    made = Alert(
        ticker, condition, target_price, expires_at=now + ALERT_DAYS * 86400, created_at=now
    );
    # An SMA alert starts from the average and the side the price is on now, so it fires on the next cross rather
    # than at once when the price is already past the line.
    if target == "SMA" {
        daily = closes_of(ticker);
        average = sma(daily.closes, sma_period) if daily else None;
        if daily is None or average is None {
            return Saved("notEnoughHistory" if daily else "historyUnavailable");
        }
        # The side comes from the same Finnhub quote the checker compares, so the two can't disagree about which
        # side the price starts on; Yahoo's price (up to an hour old) only when Finnhub has none
        quote = quote_of(ticker);
        price = quote.price if quote and quote.price > 0 else daily.price;
        (made.target, made.sma_period, made.target_price) = ("SMA", sma_period, average);
        made.last_side = side_of(price, average) if price else "";
    }
    return Saved(alert=info(root ++> made));
}
