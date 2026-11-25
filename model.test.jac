import math;

def at(h: int, m: int = 0) -> int {
    return h * 60 + m;
}

test "NYSE session knows each weekday phase" {
    for (minutes, phase) in table(
        "180=closed 240=pre 570=open 959=open 960=after 1200=closed"
    ).items() {
        assert session_of(2, int(minutes)).phase == phase, minutes;
    }
}

test "NYSE session counts down to the right open" {
    assert session_of(2, at(9)).line == "Pre-market · opens in 30m";
    assert session_of(2, at(14)).line == "Market open · closes in 2h 00m";
    # Friday night and Saturday wait for Monday 9:30
    assert session_of(5, at(21)).line == "Market closed · opens in 2d 12h";
    assert session_of(6, at(12)).line == "Market closed · opens in 1d 21h";
}

test "formats spans" {
    assert format_span(45) == "45m";
    assert format_span(125) == "2h 05m";
}

test "knows which symbols Finnhub free can price" {
    for s in ["AAPL", "BRK.B", "BINANCE:BTCUSDT"] {
        assert has_finnhub_quotes(s), s;
    }
    for s in ["RELIANCE.NS", "BARC.L", "7203.T", "2222.SR", "PKN.WA", "FX:EURUSD"] {
        assert not has_finnhub_quotes(s), s;
    }
}

test "asks Finnhub for company data only where it has some" {
    assert has_finnhub_company_data("AAPL");
    for s in ["BINANCE:BTCUSDT", "2222.SR", "PKN.WA"] {
        assert not has_finnhub_company_data(s), s;
    }
}

test "maps Finnhub symbols to TradingView's" {
    # Asia-Pacific (TradingView drops Finnhub's zero padding: HKEX:0700 is an invalid symbol there); India, where
    # NSE listings chart on BSE, with - and & spelled TradingView's way (#113); Europe (Prague is PSECZ, not the
    # Philippine PSE); the Americas (TSX accepts RCI-B as is), the Middle East and Africa.
    cases = table("""AAPL=AAPL aapl=AAPL
        2330.TW=TWSE:2330 6488.TWO=TPEX:6488 7203.T=TSE:7203 0700.HK=HKEX:700 600519.SS=SSE:600519
        000858.SZ=SZSE:000858 005930.KS=KRX:005930 BHP.AX=ASX:BHP D05.SI=SGX:D05
        RELIANCE.NS=BSE:RELIANCE RELIANCE.BO=BSE:RELIANCE BAJAJ-AUTO.NS=BSE:BAJAJ_AUTO M&M.NS=BSE:M_M
        M&MFIN.BO=BSE:M_MFIN
        SHEL.L=LSE:SHEL BT-A.L=LSE:BT.A SAP.DE=XETR:SAP MC.PA=EURONEXT:MC ASML.AS=EURONEXT:ASML ENI.MI=MIL:ENI
        SAN.MC=BME:SAN NESN.SW=SIX:NESN ERIC-B.ST=OMXSTO:ERIC_B NOVO-B.CO=OMXCOP:NOVO_B CEZ.PR=PSECZ:CEZ
        PKN.WA=GPW:PKN
        RY.TO=TSX:RY RCI-B.TO=TSX:RCI-B VALE3.SA=BMFBOVESPA:VALE3 TEVA.TA=TASE:TEVA NPN.JO=JSE:NPN
        2222.SR=TADAWUL:2222 2330.tw=TWSE:2330 shel.l=LSE:SHEL""");
    assert tradingview_symbol("") == "";
    for (finnhub, tradingview) in cases.items() {
        assert tradingview_symbol(finnhub) == tradingview, finnhub;
    }
}

test "knows which candle charts TradingView embeds" {
    for s in "AAPL BINANCE:BTCUSDT BSE:RELIANCE XETR:SAP TSX:SHOP PSECZ:CEZ GPW:PKN".split() {
        assert is_chart_embeddable(s), s;
    }
    for s in ["TSE:7203", "HKEX:700", "LSE:VOD", "KRX:005930", "TADAWUL:2222"] {
        assert not is_chart_embeddable(s), s;
    }
}

test "maps US listing venues to TradingView exchanges" {
    cases = table("XNAS=NASDAQ XNYS=NYSE XASE=AMEX ARCX=AMEX BATS=CBOE OOTC=OTC xnas=NASDAQ");
    for (mic, exchange) in cases.items() {
        assert tradingview_exchange_for_mic(mic) == exchange, mic;
    }
    for mic in ["TXSE", "", None] {
        assert tradingview_exchange_for_mic(mic) is None;
    }
}

test "prefixes a bare US ticker with its exchange, and only that" {
    assert qualify_tradingview_symbol("AAPL", "NASDAQ") == "NASDAQ:AAPL";
    assert qualify_tradingview_symbol("SPY", "AMEX") == "AMEX:SPY";
    assert qualify_tradingview_symbol("BRK.B", "NYSE") == "NYSE:BRK.B";
    assert qualify_tradingview_symbol("AAPL", None) == "AAPL";
    assert qualify_tradingview_symbol("TSX:RY", "NYSE") == "TSX:RY";
    assert qualify_tradingview_symbol("BINANCE:BTCUSDT", "NASDAQ") == "BINANCE:BTCUSDT";
    assert qualify_tradingview_symbol("", "NASDAQ") == "";
}

test "maps Tadawul app and TradingView symbols to Yahoo" {
    assert yahoo_symbol("2222.SR") == "2222.SR";
    assert yahoo_symbol("tadawul:2222") == "2222.SR";
    assert yahoo_symbol("TADAWUL:TASI") == "^TASI.SR";
    # Bare numbers stay ambiguous: 7203 is Toyota in Tokyo
    assert yahoo_symbol("7203") is None;
    assert yahoo_symbol("AAPL") is None;
    assert yahoo_app_symbol("TADAWUL:1120") == "1120.SR";
    assert yahoo_app_symbol("TADAWUL:TASI") is None;
}

test "maps Warsaw (GPW) app and TradingView symbols to Yahoo" {
    assert yahoo_symbol("PKN.WA") == "PKN.WA";
    assert yahoo_symbol("gpw:pkn") == "PKN.WA";
    assert yahoo_symbol("GPW:WIG20") == "WIG20.WA";
    assert yahoo_symbol("GPW:MWIG40") == "MWIG40.WA";
    assert yahoo_symbol("WIG20.WA") == "WIG20.WA";
    assert yahoo_symbol("XETR:SAP") is None;
    assert yahoo_app_symbol("GPW:CDR") == "CDR.WA";
    assert yahoo_app_symbol("GPW:WIG20") is None;
    assert yahoo_app_symbol("WIG.WA") is None;
}

test "knows each Yahoo exchange's currency" {
    assert [yahoo_currency(s) for s in ["PKN.WA", "^TASI.SR", "AAPL"]] == ["PLN", "SAR", "USD"];
}

test "sma averages the last N closes, and is None until there are N, or for a bad period" {
    assert sma([1.0, 2.0, 3.0, 4.0, 5.0], 5) == 3.0;
    assert sma([100.0, 1.0, 2.0, 3.0, 4.0, 5.0], 5) == 3.0;  # older closes don't count
    assert sma([10.0, 20.0], 1) == 20.0;
    assert sma([1.0, 2.0, 3.0], 4) is None;
    assert sma([1.0, 2.0, 3.0], 0) is None;
}

test "sma matches a direct mean over a 200-day window" {
    closes = [100 + math.sin(i) * 10 for i in range(250)];
    got = sma(closes, 200);
    assert got is not None and abs(got - sum(closes[50:]) / 200) < 1e-10;
}

test "only offers the listed SMA periods" {
    assert all(is_sma_period(p) for p in [20, 50, 100, 200]);
    assert not any(is_sma_period(p) for p in [0, 10, 21]);
}

test "knows which side of the average the price is on" {
    assert [side_of(p, 100.0) for p in [101.0, 99.0, 100.0]] == ["ABOVE", "BELOW", ""];
}

test "fires 'above' only when the price comes up from below" {
    assert has_crossed("ABOVE", "BELOW", 101.0, 100.0);
    assert not has_crossed("ABOVE", "ABOVE", 101.0, 100.0);  # already above: wait for a cross
    assert not has_crossed("ABOVE", "BELOW", 99.0, 100.0);  # still below
    assert not has_crossed("ABOVE", "BELOW", 100.0, 100.0);  # touching is not crossing
}

test "fires 'below' only when the price comes down from above, and needs a previous side for a cross" {
    assert has_crossed("BELOW", "ABOVE", 99.0, 100.0);
    assert not has_crossed("BELOW", "BELOW", 99.0, 100.0);
    assert not has_crossed("BELOW", "ABOVE", 101.0, 100.0);
    assert not has_crossed("ABOVE", "", 150.0, 100.0);
    assert not has_crossed("BELOW", "", 50.0, 100.0);
}
