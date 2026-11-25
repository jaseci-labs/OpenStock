"""How numbers are written on every page: prices, amounts and market caps. Pure, so both sides and the
tests share it (no space holds this module)."""

# What Intl's en-US currency style writes before the amount; any other currency is its code and a hard space
glob CURRENCY_SIGN: dict[str, str] = {"USD": "$", "EUR": "€", "GBP": "£", "JPY": "¥", "INR": "₹"},
     SCALES: list[tuple[float, str]] = [(1e12, "T"), (1e9, "B"), (1e6, "M"), (1e3, "K")];

"""`v` with thousands separators and `digits` decimals: 1234.5 -> "1,234.50"."""
def grouped(v: float, digits: int = 2) -> str {
    scaled = str(int(abs(v) * 10 ** digits + 0.5 + 1e-9)).rjust(digits + 1, "0");
    whole = scaled[:len(scaled) - digits];
    parts = [whole[max(0, i - 3):i] for i in range(len(whole), 0, -3)][::-1];
    return ("-" if v < 0 else "") + ",".join(parts) + ("." + scaled[-digits:] if digits else "");
}

"""A price in its currency. Under a cent (small coins, their moving averages) it keeps 4 significant digits:
$0.00001235, not $0.00."""
def money(price: float, currency: str = "USD") -> str {
    size = abs(price);
    digits = 2;
    if 0 < size < 0.01 {
        digits = 6;
        while size < 0.001 {
            size *= 10;
            digits += 1;
        }
    }
    text = grouped(abs(price), digits);
    text = text.rstrip("0") if digits > 2 else text;
    return ("-" if price < 0 else "") + CURRENCY_SIGN.get(currency, currency + " ") + text;
}

"""A day change as the tables write it: "+1.20", "-0.35"."""
def signed(v: float) -> str {
    return f"{'+' if v > 0 else ''}{v:.2f}";
}

"""A market cap as Finnhub sends it, in millions: 150000 -> "150.00B"."""
def compact(millions: float | None, na: str = "N/A") -> str {
    if millions is None or millions != millions or abs(millions) >= 1e300 {
        return na;
    }
    v = millions * 1e6;
    hit = [f"{v / size:.2f}{unit}" for (size, unit) in SCALES if v >= size];
    return hit[0] if hit else f"{v:.0f}";
}

"""How often on-screen prices are asked for again, in ms: every 15 s in realtime mode, never (0) in cached mode,
where one read is good for the hour."""
def poll_ms(mode: str) -> int {
    return 15000 if mode == "realtime" else 0;
}

test "prices keep two decimals, and stay visible under a cent" {
    assert money(1234.5) == "$1,234.50";
    assert money(0.53) == "$0.53";
    assert money(0) == "$0.00";
    assert money(0.000012345) == "$0.00001235";
    assert money(0.0049) == "$0.0049";
    assert money(1234567.891, "EUR") == "€1,234,567.89";
    assert money(31.5, "SAR") == "SAR 31.50";
    assert money(-2.5) == "-$2.50";
}

test "market caps in millions get T/B/M/K suffixes" {
    assert compact(3000000) == "3.00T";
    assert compact(150000) == "150.00B";
    assert compact(150) == "150.00M";
    assert compact(0.5) == "500.00K";
    for missing in [None, float("nan"), float("inf")] {
        assert compact(missing) == "N/A";
    }
}

test "prices are polled every 15 s in realtime mode only" {
    assert poll_ms("realtime") == 15000;
    assert poll_ms("cached") == 0;
}
