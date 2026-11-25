"""TradingView's free embeds: one component, and what each widget is configured with."""
import from "lucide-react" { Maximize2, Minimize2 }

glob TV_URL: str = "https://s3.tradingview.com/external-embedding/embed-widget-",
     DARK: dict[str, any] = {"colorTheme": "dark", "isTransparent": True},
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
     # By widget (the script's name); the caller adds the symbol or its groups, the component the language and size
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
         "symbol-info": DARK,
         "single-quote": DARK,
         # hide_side_toolbar off keeps the drawing tools (trend lines, Fibonacci, text); drawings last until reload
         "advanced-chart": {
             "allow_symbol_change": False,
             "calendar": False,
             "details": True,
             "hide_side_toolbar": False,
             "hide_top_toolbar": False,
             "hide_legend": False,
             "hide_volume": False,
             "hotlist": False,
             "interval": "D",
             "save_image": False,
             "style": 1,
             "theme": "dark",
             "timezone": "exchange",
             "backgroundColor": "#1f1e1a",  # --card
             "gridColor": "rgba(255, 255, 255, 0.04)",
             "watchlist": [],
             "withdateranges": False,
             "compareSymbols": [],
             "studies": [],
         },
         "technical-analysis": {**DARK, "interval": "1h", "largeChartUrl": ""},
         # embed-widget-company-profile.js was retired by TradingView (403); symbol-profile.js takes the same config
         "symbol-profile": DARK,
         "financials": {**DARK, "displayMode": "regular", "largeChartUrl": ""},
     };

# The widget `kind` with `config` over its base. It is made again only when either changes: a resize (full
# screen) keeps the same element, since re-creating the embed would wipe what the user did in the chart.
def:pub TradingView(
    kind: str, config: dict[str, any] = {}, height: int = 560, expand: bool = False
) -> JsxElement {
    has big: bool = False;
    has box: Ref[any] = Ref(None);
    has on_key: Ref[any] = Ref(None);

    # TradingView spells Arabic "ar_AE"; English and Polish are the same code as ours
    made = JSON.stringify({
        **TV_BASE[kind],
        "locale": "ar_AE" if locale() == "ar" else locale(),
        **config,
        "width": "100%",
        "height": "100%",
        "autosize": True,
    });

    can with [kind, made] entry {
        box.current.innerHTML = '<div class="tradingview-widget-container__widget" style="width: 100%; height: 100%;"></div>';
        script = document.createElement("script");
        script.src = f"{TV_URL}{kind}.js";
        script.async = True;
        script.innerHTML = made;
        box.current.appendChild(script);
    }

    can with [kind, made] exit {
        if box.current {
            box.current.innerHTML = "";
        }
    }

    can with [big] entry {
        on_key.current = lambda (e: any) {
            if e.key == "Escape" {
                big = False;
            }
        };
        if big {
            document.body.style.overflow = "hidden";
            window.addEventListener("keydown", on_key.current);
        }
    }

    can with [big] exit {
        document.body.style.overflow = "";
        window.removeEventListener("keydown", on_key.current);
    }

    label = t("TradingViewWidget.exitFullScreen" if big else "TradingViewWidget.fullScreen");
    return <>
        {<div
            className="fixed inset-0 z-50 bg-page/70 backdrop-blur-[3px]"
            onClick={lambda { big = False; }}
        />
            if big
            else None}
        {#* Height lives on the frame: TradingView's autosize overwrites the container's own height with 100% *#}
        <div
            className={cx("tv-frame group", big and "fixed inset-3 z-50 shadow-[0_0_0_4px_var(--frame),0_24px_60px_oklch(0_0_0/0.6)]")}
            style={{"height": None if big else height}}
        >
            {<button
                type="button"
                onClick={lambda { big = not big; }}
                className={cx("icon-btn absolute top-2 right-2 z-10 bg-card/80", not big and "opacity-0 group-hover:opacity-100 focus-visible:opacity-100")}
                aria-label={label}
                title={t("TradingViewWidget.exitFullScreenHint") if big else label}
            >{<Minimize2 /> if big else <Maximize2 />}</button>
                if expand
                else None}
            <div
                ref={box}
                className="tradingview-widget-container"
                style={{"height": "100%", "width": "100%"}}
            />
        </div>
    </>;
}
