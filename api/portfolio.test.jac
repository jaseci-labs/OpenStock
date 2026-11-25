import os;

glob history: Closes | None = None,
     quoted: Quote | None = None,
     asked: list[str] = [];

def fake_closes(symbol: str) -> Closes | None {
    asked.append(symbol);
    return history;
}

def fake_quote(symbol: str) -> Quote | None {
    return quoted;
}

"""A caller with nothing kept, in realtime mode, whose symbols have 60 daily closes (the last 50 average 105) and a
price of 110, above that."""
def fresh {
    for n in [root -->] {
        remove(n);
    }
    os.environ["NEXT_PUBLIC_OPENSTOCK_DATA_MODE"] = "realtime";
    quote_of = fake_quote;
    closes_of = fake_closes;
    history = Closes([1.0] * 10 + [80.5 + i for i in range(50)], 110.0);
    quoted = Quote(price=110.0);
    asked.clear();
}

def alerts -> list[Alert] {
    return [root --> [?:Alert]];
}

def sma_alert(condition: str = "ABOVE", period: int = 50, price: float = 0.0) -> Saved {
    return create_alert("AAPL", condition, price, "SMA", period);
}

"""Someone else's list: kept, but not under the caller's root."""
def foreign_list -> NamedList {
    theirs = root.shared ++> NamedList("Theirs", 0.0);
    theirs ++> Pick("MSFT", "Microsoft", 0.0);
    return theirs;
}

def symbols_of(list_id: str) -> list[str] {
    return [s.symbol for l in get_lists() if l.id == list_id for s in l.symbols];
}

test "list names are trimmed, collapsed and at most sixty characters" {
    assert normalize_list_name("  Banks  ") == "Banks";
    assert normalize_list_name("My    Dividend\nideas") == "My Dividend ideas";
    assert normalize_list_name("x" * 60) == "x" * 60 and normalize_list_name("x" * 61) == "";
    assert normalize_list_name("") == "" and normalize_list_name("   ") == "";
}

test "symbols take the shapes Finnhub writes, upper-cased and trimmed" {
    for s in ["AAPL", "BRK.B", "RELIANCE.NS", "M&M.NS", "0700.HK", "BINANCE:BTCUSDT"] {
        assert normalize_symbol(s) == s;
    }
    assert normalize_symbol(" aapl ") == "AAPL" and normalize_symbol("brk.b") == "BRK.B";
    for s in ["", "   ", "-AAPL", "AAPL;DROP", "x" * 26] {
        assert normalize_symbol(s) == "";
    }
}

test "company names are trimmed and capped at 120" {
    assert normalize_company("  Apple Inc  ") == "Apple Inc";
    assert len(normalize_company("x" * 200)) == 120;
}

test "the watchlist stars a symbol once, newest first, up to its cap" {
    fresh();
    assert add_to_watchlist(" aapl ", "Apple").error == "";
    assert add_to_watchlist("MSFT", "Microsoft").error == "";
    assert add_to_watchlist("AAPL", "Apple Inc").error == "";
    assert [(w.symbol, w.company) for w in get_watchlist()] == [
        ("AAPL", "Apple Inc"),
        ("MSFT", "Microsoft"),
    ];
    assert in_watchlist("aapl") and not in_watchlist("TSLA");
    assert add_to_watchlist("AAPL;DROP", "x").error == "symbolInvalid";
    remove_from_watchlist("aapl");
    remove_from_watchlist("TSLA");
    assert [w.symbol for w in get_watchlist()] == ["MSFT"];
    for i in range(MAX_WATCHLIST - 1) {
        assert add_to_watchlist(f"S{i}", "").error == "";
    }
    assert add_to_watchlist("ONEMORE", "").error == "watchlistFull";
    assert add_to_watchlist("MSFT", "Microsoft Corp").error
        == "", "a full watchlist still refreshes";
    assert visit_now().seen > 0, "reading the watchlist marks the caller seen";
}

test "a list allows its last slot and refuses the one after, for lists and for symbols" {
    fresh();
    ids = [create_list(f"List {i}").made.id for i in range(MAX_LISTS)];
    assert len(get_lists()) == MAX_LISTS and get_lists()[0].name == f"List {MAX_LISTS - 1}";
    assert create_list("One more").error == "listLimit";
    for i in range(MAX_LIST_SYMBOLS) {
        assert add_to_list(ids[0], f"S{i}", "").error == "";
    }
    assert add_to_list(ids[0], "AAPL", "Apple Inc.").error == "listFull";
    assert add_to_list(ids[0], "S0", "Still fits").error == "", "a full list still refreshes";
    assert delete_list(ids[0]).error == "" and delete_list(ids[0]).error == "listNotFound";
    assert create_list("One more").made.name == "One more";
}

test "a list takes one name per caller, cleaned" {
    fresh();
    made = create_list("  My   Banks ").made;
    assert made is not None and (made.name, made.count, made.symbols) == ("My Banks", 0, []);
    assert create_list("My Banks").error == "listExists";
    assert create_list("   ").error == "listNameInvalid"
        and create_list("x" * 61).error == "listNameInvalid";
    assert len(get_lists()) == 1;
}

test "two creates that overlap never pass the cap together" {
    fresh();
    for i in range(MAX_LISTS - 1) {
        create_list(f"Old {i}");
    }
    results: list[Saved] = [];
    tabs = [
        threading.Thread(target=lambda { results.append(create_list(f"New {n}")); })
        for n in ["First", "Second"]
    ];
    for t in tabs {
        t.start();
    }
    for t in tabs {
        t.join();
    }
    assert sorted([r.error for r in results]) == ["", "listLimit"];
    assert len(get_lists()) == MAX_LISTS;
    # A success must point at a list that is there
    assert [r.made.id for r in results if r.made][0] in [l.id for l in get_lists()];
}

test "adding to a list files the symbol once; again replaces it in place" {
    fresh();
    id = create_list("Tech").made.id;
    assert add_to_list(id, "aapl", "Apple").error == "" and add_to_list(id, "MSFT", "").error == "";
    first = [root --> [?:NamedList]][0];
    added = [p.added_at for p in [first --> [?:Pick]]];
    assert add_to_list(id, "AAPL", "Apple Inc.").error == "";
    held = get_lists()[0];
    assert held.count == 2
        and [(s.symbol, s.company) for s in held.symbols] == [
            ("AAPL", "Apple Inc."),
            ("MSFT", "MSFT"),
        ];
    # Only the company is refreshed: the day it was first added is the truthful one
    assert [s.added_at for s in held.symbols] == added;
}

test "removing from a list drops the symbol and is no error when it is not there" {
    fresh();
    id = create_list("Tech").made.id;
    add_to_list(id, "AAPL", "Apple");
    add_to_list(id, "MSFT", "Microsoft");
    assert remove_from_list(id, "msft").error == "" and symbols_of(id) == ["AAPL"];
    assert remove_from_list(id, "TSLA").error == "" and symbols_of(id) == ["AAPL"];
}

test "a list owned by someone else is missing, and nothing is written to it" {
    fresh();
    theirs = foreign_list();
    for id in [jid(theirs), "not-an-id"] {
        assert add_to_list(id, "AAPL", "Apple Inc.").error == "listNotFound";
        assert remove_from_list(id, "MSFT").error == "listNotFound";
        assert delete_list(id).error == "listNotFound";
    }
    assert [p.symbol for p in [theirs --> [?:Pick]]] == ["MSFT"];
    remove(theirs);
}

test "a list refuses a symbol the starred watchlist would also refuse" {
    fresh();
    id = create_list("Tech").made.id;
    assert add_to_list(id, "AAPL;DROP", "x").error == "symbolInvalid";
    assert remove_from_list(id, "AAPL;DROP").error == "symbolInvalid";
    assert symbols_of(id) == [];
}

test "active alerts are capped per caller, before any history is fetched" {
    fresh();
    for i in range(MAX_ACTIVE_ALERTS) {
        root ++> Alert("AAPL", "ABOVE", 200.0);
    }
    assert create_alert("AAPL", "ABOVE", 200.0).error == "alertLimit";
    assert sma_alert().error == "alertLimit" and asked == [];
    assert len(alerts()) == MAX_ACTIVE_ALERTS;
    # Only that caller's active ones count
    alerts()[0].active = False;
    root.shared ++> Alert("AAPL", "ABOVE", 200.0);
    assert create_alert("AAPL", "ABOVE", 200.0).error == "";
}

test "a caller deletes their own alert, and never someone else's" {
    fresh();
    mine = create_alert("AAPL", "ABOVE", 200.0).alert;
    theirs = root.shared ++> Alert("TSLA", "ABOVE", 1.0);
    assert mine is not None and [a.id for a in get_alerts()] == [mine.id];
    delete_alert(jid(theirs));
    delete_alert(mine.id);
    assert get_alerts() == [] and theirs in [root.shared --> [?:Alert]];
    remove(theirs);
}

test "alerts are refused where Cloud features are off" {
    fresh();
    os.environ["NEXT_PUBLIC_OPENSTOCK_DATA_MODE"] = "cached";
    assert create_alert("AAPL", "ABOVE", 200.0).error == "alertsOff" and alerts() == [];
}

test "alerts are refused for what the checker could never price, and for untrusted input" {
    fresh();
    assert create_alert("RELIANCE.NS", "ABOVE", 1000.0).error == "marketUnsupported";
    # A symbol could carry markup into alert emails
    assert create_alert("<img src=x>", "ABOVE", 1.0).error == "symbolInvalid";
    assert create_alert("AAPL", "SIDEWAYS", 1.0).error == "conditionInvalid";
    assert [create_alert("AAPL", "ABOVE", p).error for p in [0.0, -5.0, float("inf")]]
        == ["priceInvalid"] * 3;
    assert alerts() == [];
}

test "an alert stores only validated fields, so callers cannot pre-trigger or extend it" {
    fresh();
    made = create_alert(" brk.b ", "BELOW", 400.0).alert;
    assert made is not None
        and (made.symbol, made.target_price, made.condition, made.target)
            == ("BRK.B", 400.0, "BELOW", "PRICE");
    assert made.active and not made.triggered and alerts()[0].last_side == "";
    assert abs(made.expires_at - time.time() - 90 * 86400) < 60;
}

test "an SMA alert stores the period, the current average and the side the price is on now" {
    fresh();
    made = sma_alert("BELOW", price=1.0).alert;
    assert asked == ["AAPL"] and made is not None;
    # A target price sent with an SMA alert is ignored
    assert (made.target, made.sma_period, made.target_price) == ("SMA", 50, 105.0);
    assert alerts()[0].last_side == "ABOVE";
}

test "an SMA alert accepts only the listed periods" {
    fresh();
    assert sma_alert(period=7).error == "periodInvalid" and asked == [];
}

test "an SMA alert answers with a code the modal can translate when the history is too short" {
    fresh();
    assert sma_alert(period=200).error == "notEnoughHistory";
    history = Closes();  # Yahoo has no data for the symbol
    assert sma_alert(period=20).error == "notEnoughHistory" and alerts() == [];
}

test "an unreachable history is told apart, so the modal can say to try again" {
    fresh();
    history = None;
    assert sma_alert(period=20).error == "historyUnavailable" and alerts() == [];
}

test "an SMA alert takes its side from the Finnhub quote the checker uses, not Yahoo's older price" {
    fresh();
    quoted = Quote(price=100.0);  # below the average, while Yahoo still says above
    assert sma_alert().error == "" and alerts()[0].last_side == "BELOW";
}

test "an SMA alert falls back to Yahoo's price only when Finnhub has none" {
    fresh();
    quoted = None;
    assert sma_alert().error == "" and alerts()[0].last_side == "ABOVE";
}
