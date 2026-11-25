import json;

obj Row {
    has symbol: str,
        name: str,
        exchange: str,
        sector: str,
        sub_industry: str,
        cik: str,
        indexes: list[str];
}

glob BIG: str = "<url><loc>https://openstock.example/s/AAPL</loc></url>\n" * 1000,
     ROWS: list[Row] = [
         Row(f"SYM{i}", f"Company number {i} Inc.", "NYSE", "Information Technology", "Technology Hardware, Storage & Peripherals", str(320193 + i), ["SP500", "NDX100"])
         for i in range(518)
     ],
     DICTS: list[dict[str, str]] = [
         {"symbol": r.symbol, "name": r.name, "exchange": r.exchange, "sector": r.sector, "sub_industry": r.sub_industry, "cik": r.cik}
         for r in ROWS
     ];

def:pub small -> str {
    return "ok";
}

def:pub big_str -> str {
    return BIG;
}

def:pub rows -> list[Row] {
    return ROWS;
}

def:pub dicts -> list[dict[str, str]] {
    return DICTS;
}

def:pub dumped -> str {
    return json.dumps(DICTS);
}

def:pub big2 -> str {
    return BIG + BIG;
}

def:pub quoted -> str {
    return BIG.replace("<", '"');
}
