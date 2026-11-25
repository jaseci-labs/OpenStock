import from datetime { datetime, timezone }

def open_at(id: str, day: int, hour: int, minute: int = 0) -> bool {
    return is_market_open(
        get_market(id), datetime(2026, 9, day, hour, minute, tzinfo=timezone.utc)
    );
}

test "builds every market from its text" {
    assert [m.id for m in markets()] == ["us", "in", "de", "ca", "au", "sa", "pl", "crypto", "fx"];
    us = get_market("us");
    assert us.pulse[0] == Pulse("AMEX:SPY", "S&P 500", "SPY") and us.heatmap == "stocks";
    assert us.groups[0].title == "Financial"
        and us.groups[0].symbols[0] == ("NYSE:JPM", "JPMorgan Chase");
    assert get_market("in").pulse[0].finnhub == "" and get_market("sa").yahoo;
    assert all(len(m.pulse) == 4 and m.groups for m in MARKETS);
}

test "falls back to the US market" {
    assert get_market("nope").id == "us" and get_market().id == "us";
    assert market_for_country("PL") == "pl"
        and market_for_country("FR") == "us"
        and market_for_country() == "us";
}

test "opens each market in its own time zone" {
    # Wed 2026-09-23 10:00 in Mumbai = 04:30 UTC
    assert open_at("in", 23, 4, 30) and not open_at("us", 23, 4, 30);
    # Saturday: stocks and FX closed, crypto open
    assert not open_at("de", 26, 10) and not open_at("fx", 26, 10) and open_at("crypto", 26, 10);
    # FX reopens Sunday 17:00 New York (21:00 UTC in September)
    assert open_at("fx", 27, 21, 30);
    # Tadawul trades Sunday to Thursday, 10:00-15:00 Riyadh (07:00-12:00 UTC)
    assert open_at("sa", 27, 8) and not open_at("sa", 25, 8) and not open_at("sa", 27, 12, 30);
    # GPW trades Monday to Friday, 09:00-17:00 Warsaw (07:00-15:00 UTC in September)
    assert open_at("pl", 23, 8) and not open_at("pl", 23, 15, 30) and not open_at("pl", 26, 10);
}

test "reads a zone's clock" {
    now = clock("America/New_York", datetime(2026, 9, 27, 21, 30, tzinfo=timezone.utc));
    assert now == Clock(0, 17 * 60 + 30, "17:30");
}
