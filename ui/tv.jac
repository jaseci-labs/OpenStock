"""What each TradingView widget of the app pages is configured with (ui.market's TradingView shows them)."""

glob DARK: dict[str, any] = {"colorTheme": "dark", "isTransparent": True},
     TEAL: str = "rgba(71, 217, 187, ",  # brand teal (oklch 0.80 0.13 176)
     HEAT: dict[str, any] = {
         **DARK,
         "blockColor": "change",
         "symbolUrl": "",
         "hasTopBar": False,
         "isDataSetEnabled": False,
         "isZoomEnabled": True,
         "hasSymbolTooltip": True,
         "isMonoSize": False,
     },
     # By widget (the script's name); widget_config adds the language and what the caller gives
     TV_BASE: dict[str, dict[str, any]] = {
         "market-overview": {
             **DARK,
             "dateRange": "12M",
             "largeChartUrl": "",
             "showFloatingTooltip": True,
             "plotLineColorGrowing": "#47d9bb",
             "plotLineColorFalling": "#47d9bb",
             "gridLineColor": "rgba(240, 243, 250, 0)",
             "scaleFontColor": "#adaba3",  # --muted
             "belowLineFillColorGrowing": TEAL + "0.12)",
             "belowLineFillColorFalling": TEAL + "0.12)",
             "belowLineFillColorGrowingBottom": TEAL + "0)",
             "belowLineFillColorFallingBottom": TEAL + "0)",
             "symbolActiveColor": TEAL + "0.08)",
             "support_host": "https://www.tradingview.com",
             "showSymbolLogo": True,
             "showChart": True,
         },
         "market-quotes": {**DARK, "showSymbolLogo": True},
         "stock-heatmap": {
             **HEAT,
             "dataSource": "SPX500",
             "blockSize": "market_cap_basic",
             "grouping": "sector",
             "exchanges": [],
         },
         "crypto-coins-heatmap": {**HEAT, "dataSource": "Crypto", "blockSize": "market_cap_calc"},
         "timeline": {**DARK, "displayMode": "regular", "feedMode": "market"},
         "technical-analysis": {**DARK, "interval": "1h", "largeChartUrl": ""},
         # embed-widget-company-profile.js was retired by TradingView (403); symbol-profile.js takes the same config
         "symbol-profile": DARK,
         "financials": {**DARK, "displayMode": "regular", "largeChartUrl": ""},
     };

# The config of `widget` in the language `loc`, with the caller's symbol or groups
def:pub widget_config(widget: str, loc: str, extra: dict[str, any]) -> dict[str, any] {
    return {**TV_BASE[widget], "locale": tv_locale(loc), **extra};
}
