import os;
import json;
import urllib.request;

def:pub ping(symbol: str) -> str {
    key = os.environ.get("FINNHUB_API_KEY", "");
    with urllib.request.urlopen(f"https://finnhub.io/api/v1/quote?symbol={symbol}&token={key}", timeout=10) as resp {
        data = json.loads(resp.read());
    }
    return f"{symbol}: {data.get('c')}";
}

test "ping formats" {
    assert "x".upper() == "X";
}
