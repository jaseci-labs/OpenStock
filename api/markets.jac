"""Markets OpenStock can show for free. Coverage was tested against the free data sources:
  - Finnhub free: US stocks and crypto only (every other exchange returns 403).
  - TradingView embeds: US, crypto, forex live; TSX + ASX delayed; BSE + XETRA end-of-day.
    NSE and TVC indices (NIFTY, FTSE, DAX, N225, HSI) are blocked in embeds; LSE, Tokyo, Hong Kong and
    others block only the candle chart (see CHART_BLOCKED in model.jac).
  - Tadawul is blocked in embeds and on Finnhub free, so Saudi tiles and tables are priced from Yahoo Finance.
  - GPW (Warsaw) stocks, indices and charts render in embeds, but end of day only, so Polish tiles and tables use
    Yahoo's ~15-minute delayed quotes too.
Adding a market = adding an entry here with symbols from an exchange that renders in embeds."""
import from datetime { datetime }
import from zoneinfo { ZoneInfo }

"""One market from compact text: "id|name|short|time zone|hours|feed", its dashboard tiles as
"SYMBOL=Label[=Finnhub symbol], ..." and each titled group of its tables as "SYMBOL=Name, ..."."""
def market(
    head: str,
    pulse: str,
    groups: dict[str, str],
    news: str = "stock",
    heatmap: str = "",
    yahoo: bool = False,
    trading_days: list[int] = [1, 2, 3, 4, 5],
) -> Market {
    return Market(
        *head.split("|"),
        pulse=[Pulse(*item.split("=")) for item in pulse.split(", ")],
        groups=[
            Group(
                title, [(s, name) for (s, _, name) in [i.partition("=") for i in text.split(", ")]]
            )
            for (title, text) in groups.items()
        ],
        news=news,
        heatmap=heatmap,
        yahoo=yahoo,
        trading_days=trading_days,
    );
}

glob MARKETS: list[Market] = [
    market(
        "us|United States|US|America/New_York|09:30-16:00|Live",
        "AMEX:SPY=S&P 500=SPY, NASDAQ:QQQ=Nasdaq 100=QQQ, AMEX:DIA=Dow 30=DIA, AMEX:IWM=Russell 2000=IWM",
        {
            "Financial": "NYSE:JPM=JPMorgan Chase, NYSE:BAC=Bank of America, NYSE:WFC=Wells Fargo, NYSE:GS=Goldman Sachs, NYSE:MA=Mastercard, NYSE:V=Visa",
            "Technology": "NASDAQ:AAPL=Apple, NASDAQ:MSFT=Microsoft, NASDAQ:NVDA=NVIDIA, NASDAQ:GOOGL=Alphabet, NASDAQ:META=Meta, NASDAQ:AMD=AMD",
            "Consumer": "NASDAQ:AMZN=Amazon, NASDAQ:TSLA=Tesla, NYSE:WMT=Walmart, NASDAQ:COST=Costco, NYSE:KO=Coca-Cola, NASDAQ:NFLX=Netflix",
        },
        heatmap="stocks",
    ),
    market(
        "in|India|IN|Asia/Kolkata|09:15-15:30|End of day",
        "BSE:SENSEX=Sensex, BSE:RELIANCE=Reliance, BSE:TCS=TCS, BSE:HDFCBANK=HDFC Bank",
        {
            "Banks": "BSE:HDFCBANK=HDFC Bank, BSE:ICICIBANK=ICICI Bank, BSE:SBIN=State Bank of India, BSE:KOTAKBANK=Kotak Mahindra, BSE:AXISBANK=Axis Bank",
            "Technology": "BSE:TCS=TCS, BSE:INFY=Infosys, BSE:WIPRO=Wipro, BSE:HCLTECH=HCLTech, BSE:TECHM=Tech Mahindra",
            "Industry": "BSE:RELIANCE=Reliance, BSE:LT=Larsen & Toubro, BSE:ONGC=ONGC, BSE:NTPC=NTPC, BSE:TATASTEEL=Tata Steel",
        },
    ),
    market(
        "de|Germany|DE|Europe/Berlin|09:00-17:30|End of day",
        "XETR:SAP=SAP, XETR:SIE=Siemens, XETR:ALV=Allianz, XETR:DTE=Deutsche Telekom",
        {
            "Industry": "XETR:SIE=Siemens, XETR:BAS=BASF, XETR:BMW=BMW, XETR:MBG=Mercedes-Benz, XETR:VOW3=Volkswagen",
            "Finance": "XETR:ALV=Allianz, XETR:MUV2=Munich Re, XETR:DBK=Deutsche Bank, XETR:CBK=Commerzbank",
            "Technology": "XETR:SAP=SAP, XETR:IFX=Infineon, XETR:DTE=Deutsche Telekom, XETR:ADS=Adidas",
        },
    ),
    market(
        "ca|Canada|CA|America/Toronto|09:30-16:00|Delayed",
        "TSX:RY=Royal Bank, TSX:SHOP=Shopify, TSX:ENB=Enbridge, TSX:TD=TD Bank",
        {
            "Banks": "TSX:RY=Royal Bank, TSX:TD=TD Bank, TSX:BNS=Scotiabank, TSX:BMO=Bank of Montreal",
            "Energy": "TSX:ENB=Enbridge, TSX:CNQ=Canadian Natural, TSX:SU=Suncor",
            "Growth": "TSX:SHOP=Shopify, TSX:CNR=CN Rail, TSX:CP=CPKC",
        },
    ),
    market(
        "au|Australia|AU|Australia/Sydney|10:00-16:00|Delayed",
        "ASX:CBA=CommBank, ASX:BHP=BHP, ASX:CSL=CSL, ASX:NAB=NAB",
        {
            "Banks": "ASX:CBA=CommBank, ASX:NAB=NAB, ASX:WBC=Westpac, ASX:ANZ=ANZ, ASX:MQG=Macquarie",
            "Resources": "ASX:BHP=BHP, ASX:FMG=Fortescue, ASX:RIO=Rio Tinto",
            "Consumer & health": "ASX:CSL=CSL, ASX:WES=Wesfarmers, ASX:WOW=Woolworths",
        },
    ),
    market(
        "sa|Saudi Arabia|SA|Asia/Riyadh|10:00-15:00|Delayed",
        "TADAWUL:TASI=TASI, TADAWUL:2222=Aramco, TADAWUL:1120=Al Rajhi, TADAWUL:7010=STC",
        {
            "Banks": "TADAWUL:1120=Al Rajhi Bank, TADAWUL:1180=Saudi National Bank, TADAWUL:1150=Alinma Bank, TADAWUL:1010=Riyad Bank, TADAWUL:1060=SAB",
            "Energy & materials": "TADAWUL:2222=Saudi Aramco, TADAWUL:2010=SABIC, TADAWUL:2082=ACWA Power, TADAWUL:1111=Tadawul Group",
            "Telecom & consumer": "TADAWUL:7010=STC Group, TADAWUL:7020=Mobily, TADAWUL:7030=Zain KSA, TADAWUL:2280=Almarai, TADAWUL:4300=Dar Alarkan",
        },
        yahoo=True,
        trading_days=[0, 1, 2, 3, 4],
    ),
    market(
        "pl|Poland|PL|Europe/Warsaw|09:00-17:00|Delayed",
        "GPW:WIG20=WIG20, GPW:WIG=WIG, GPW:MWIG40=mWIG40, GPW:SWIG80=sWIG80",
        {
            "Banks & insurance": "GPW:PKO=PKO Bank Polski, GPW:PEO=Bank Pekao, GPW:PZU=PZU, GPW:MBK=mBank, GPW:ALR=Alior Bank",
            "Energy & industry": "GPW:PKN=Orlen, GPW:KGH=KGHM, GPW:PGE=PGE, GPW:TPE=Tauron, GPW:BDX=Budimex",
            "Consumer & tech": "GPW:DNP=Dino Polska, GPW:LPP=LPP, GPW:ALE=Allegro, GPW:CDR=CD Projekt, GPW:ZAB=Żabka",
        },
        yahoo=True,
    ),
    market(
        "crypto|Crypto|Crypto|UTC|24/7|Live",
        "BINANCE:BTCUSDT=Bitcoin=BINANCE:BTCUSDT, BINANCE:ETHUSDT=Ethereum=BINANCE:ETHUSDT, BINANCE:SOLUSDT=Solana=BINANCE:SOLUSDT, BINANCE:BNBUSDT=BNB=BINANCE:BNBUSDT",
        {
            "Majors": "BINANCE:BTCUSDT=Bitcoin, BINANCE:ETHUSDT=Ethereum, BINANCE:SOLUSDT=Solana, BINANCE:BNBUSDT=BNB, BINANCE:XRPUSDT=XRP",
            "More": "BINANCE:ADAUSDT=Cardano, BINANCE:DOGEUSDT=Dogecoin, BINANCE:AVAXUSDT=Avalanche, BINANCE:LINKUSDT=Chainlink, BINANCE:DOTUSDT=Polkadot",
        },
        news="crypto",
        heatmap="crypto",
    ),
    market(
        "fx|Forex|FX|America/New_York|24/5|Live",
        "FX:EURUSD=EUR / USD, FX:GBPUSD=GBP / USD, FX:USDJPY=USD / JPY, FX:AUDUSD=AUD / USD",
        {
            "Majors": "FX:EURUSD=EUR / USD, FX:GBPUSD=GBP / USD, FX:USDJPY=USD / JPY, FX:USDCHF=USD / CHF",
            "Commodity FX": "FX:AUDUSD=AUD / USD, FX:USDCAD=USD / CAD, FX:NZDUSD=NZD / USD",
        },
        news="forex",
    ),
];

glob COUNTRY_MARKET: dict[str, str] = {
    "IN": "in",
    "DE": "de",
    "CA": "ca",
    "AU": "au",
    "SA": "sa",
    "PL": "pl",
};

def:pub markets -> list[Market] {
    return MARKETS;
}

"""The market with this id, or the default one (US)."""
def:pub get_market(id: str = "") -> Market {
    return ([m for m in MARKETS if m.id == id] or MARKETS)[0];
}

def:pub market_for_country(country: str = "") -> str {
    return COUNTRY_MARKET.get(country, MARKETS[0].id);
}

def minutes_of(hhmm: str) -> int {
    (h, _, m) = hhmm.partition(":");
    return int(h) * 60 + int(m);
}

"""The weekday and time of day in a time zone, now or at `when` (an aware datetime)."""
def clock(time_zone: str, when: datetime | None = None) -> Clock {
    zone = ZoneInfo(time_zone);
    local = when.astimezone(zone) if when else datetime.now(zone);
    return Clock(local.isoweekday() % 7, local.hour * 60 + local.minute, local.strftime("%H:%M"));
}

"""Is the market trading, in its own time zone? Holidays aren't modelled."""
def is_market_open(market: Market, when: datetime | None = None) -> bool {
    if market.hours == "24/7" {
        return True;
    }
    now = clock(market.time_zone, when);
    if market.hours == "24/5" {
        # FX: Sunday 17:00 to Friday 17:00, New York time
        return {6: False, 0: now.minutes >= 17 * 60, 5: now.minutes < 17 * 60}.get(
            now.weekday, True
        );
    }
    (opens, _, closes) = market.hours.partition("-");
    return now.weekday in market.trading_days
        and minutes_of(opens) <= now.minutes < minutes_of(closes);
}

"""The ids of the markets trading right now."""
def:pub open_markets -> list[str] {
    return [m.id for m in MARKETS if is_market_open(m)];
}

def:pub is_open(id: str) -> bool {
    return is_market_open(get_market(id));
}

"""New York's clock, which `session_of` turns into the NYSE session."""
def:pub new_york_now -> Clock {
    return clock("America/New_York");
}

def:pub nyse_session -> MarketSession {
    now = new_york_now();
    return session_of(now.weekday, now.minutes);
}
