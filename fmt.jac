"""How numbers are written on every page: prices, amounts, market caps and day changes. Pure, so both sides and the
tests share it (no space holds this module)."""

# What Intl's en-US currency style writes before the amount; any other currency is its code and a hard space
glob CURRENCY_SIGN: dict[str, str] = {"USD": "$", "EUR": "€", "GBP": "£", "JPY": "¥", "INR": "₹"},
     SCALES: list[tuple[float, str]] = [(1e12, "T"), (1e9, "B"), (1e6, "M")];

def finite(v: float | None) -> bool {
    return v is not None and v == v and abs(v) < 1e300;
}

"""`v` with thousands separators and `digits` decimals: 1234.5 -> "1,234.50"."""
def grouped(v: float, digits: int = 2) -> str {
    scaled = str(int(abs(v) * 10 ** digits + 0.5 + 1e-9)).rjust(digits + 1, "0");
    whole = scaled[:len(scaled) - digits];
    parts = [whole[max(0, i - 3):i] for i in range(len(whole), 0, -3)][::-1];
    return ("-" if v < 0 else "") + ",".join(parts) + ("." + scaled[-digits:] if digits else "");
}

"""An amount with two decimals, or up to four below 1 when `fine` (index points, crypto pairs)."""
def amount(v: float, fine: bool = False) -> str {
    if not fine or abs(v) >= 1 {
        return grouped(v);
    }
    text = grouped(v, 4);
    return text[:-2] if text.endswith("00") else text[:-1] if text.endswith("0") else text;
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

def change_percent(v: float | None) -> str {
    return "" if v is None else signed(v) + "%";
}

def change_color(v: float | None) -> str {
    return "text-gray-400" if not v else "text-green-500" if v > 0 else "text-red-500";
}

def scaled(v: float, units: list[tuple[float, str]]) -> str | None {
    for (size, unit) in units {
        if v >= size {
            return f"{v / size:.2f}{unit}";
        }
    }
    return None;
}

"""A market cap in dollars: "$3.10T", "$900.00B", "$25.00M" or "$999999.99"."""
def market_cap_usd(v: float | None, na: str = "N/A") -> str {
    return na if not finite(v) or v <= 0 else "$" + (scaled(v, SCALES) or f"{v:.2f}");
}

"""A market cap as Finnhub sends it, in millions: 150000 -> "150.00B"."""
def compact(millions: float | None, na: str = "N/A") -> str {
    if not finite(millions) {
        return na;
    }
    v = millions * 1e6;
    return scaled(v, SCALES + [(1e3, "K")]) or f"{v:.0f}";
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

test "amounts group thousands and show small ones finer" {
    assert amount(5123.456) == "5,123.46";
    assert amount(0.12345, True) == "0.1235";
    assert amount(0.5, True) == "0.50";
    assert amount(-12.3) == "-12.30";
    assert amount(64000.129, True) == "64,000.13";
}

test "market caps in dollars" {
    for bad in [0.0, -100.0, float("nan"), float("inf")] {
        assert market_cap_usd(bad) == "N/A";
    }
    assert market_cap_usd(None, "—") == "—";
    assert market_cap_usd(3.1e12) == "$3.10T";
    assert market_cap_usd(900e9) == "$900.00B";
    assert market_cap_usd(25e6) == "$25.00M";
    assert market_cap_usd(999999.99) == "$999999.99";
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

test "day changes carry their sign and colour" {
    assert change_percent(None) == "";
    assert change_percent(2.5) == "+2.50%";
    assert change_percent(-1.23) == "-1.23%";
    assert change_percent(0) == "0.00%";
    assert [change_color(v) for v in [0.0, None, 1.5, -0.5]] == [
        "text-gray-400",
        "text-gray-400",
        "text-green-500",
        "text-red-500",
    ];
}

test "prices are polled every 15 s in realtime mode only" {
    assert poll_ms("realtime") == 15000;
    assert poll_ms("cached") == 0;
}
