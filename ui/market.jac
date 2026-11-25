"""Market data on screen: TradingView embeds, the index pulse tiles and the product preview."""
import from "@jac/runtime" { Link }
import from "lucide-react" { LineChart, Maximize2, Minimize2, Plus }

glob TV_EMBED: str = "https://s3.tradingview.com/external-embedding/embed-widget-";

# TradingView spells Arabic "ar_AE"; English and Polish are the same code as ours
def:pub tv_locale(loc: str) -> str {
    return "ar_AE" if loc == "ar" else loc;
}

def:pub symbol_info(symbol: str, loc: str = "en") -> dict[str, any] {
    return {
        "symbol": symbol,
        "colorTheme": "dark",
        "isTransparent": True,
        "locale": tv_locale(loc),
    };
}

# The side toolbar is the drawing tools (trend lines, Fibonacci, text); drawings last until reload
def:pub candle_chart(symbol: str, loc: str = "en") -> dict[str, any] {
    return {
        "symbol": symbol.upper(),
        "locale": tv_locale(loc),
        "interval": "D",
        "style": 1,
        "theme": "dark",
        "timezone": "exchange",
        "backgroundColor": "#1f1e1a",
        "gridColor": "rgba(255, 255, 255, 0.04)",
        "details": True,
        **{
            off: False
            for off in "allow_symbol_change calendar hide_side_toolbar hide_top_toolbar hide_legend hide_volume hotlist save_image withdateranges".split()
        },
        **{none: [] for none in ["watchlist", "compareSymbols", "studies"]},
    };
}

def mini_chart(symbol: str) -> dict[str, any] {
    return {
        "symbol": symbol,
        "locale": "en",
        "dateRange": "1M",
        "colorTheme": "dark",
        "isTransparent": True,
        "trendLineColor": "#47d9bb",
        "underLineColor": "rgba(71, 217, 187, 0.14)",
        "underLineBottomColor": "rgba(71, 217, 187, 0)",
    };
}

def amount(value: float, digits: int = 2) -> str {
    shown = {"minimumFractionDigits": 2, "maximumFractionDigits": digits};
    return new(Intl.NumberFormat, "en-US", shown).format(value);
}

# A TradingView embed (`widget` is the script's name: "advanced-chart", "single-quote"...),
# mounted once per widget and config. Fullscreen resizes the same element in place: moving or
# re-creating the embed would reset the chart. The height lives on the frame, because
# TradingView's autosize overwrites the container's own height with 100%.
def:pub TradingView(
    widget: str,
    config: dict[str, any],
    height: int = 600,
    className: str = "",
    expand: bool = False,
    loc: str = "en",
) -> JsxElement {
    has big: bool = False;
    has box: Ref[any] = Ref(None);
    has on_key: Ref[any] = Ref(None);

    setup = JSON.stringify({**config, "width": "100%", "height": "100%", "autosize": True});
    label = tr(loc, "TradingViewWidget.exitFullScreen" if big else "TradingViewWidget.fullScreen");

    can with [widget, setup] entry {
        box.current.innerHTML = '<div class="tradingview-widget-container__widget" style="width: 100%; height: 100%;"></div>';
        script = document.createElement("script");
        script.src = f"{TV_EMBED}{widget}.js";
        script.async = True;
        script.innerHTML = setup;
        box.current.appendChild(script);
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

    return <>
        {<div
            className="fixed inset-0 z-50 bg-page/70 backdrop-blur-[3px]"
            onClick={lambda { big = False; }}
        />
            if big
            else None}
        <div
            className={cx("tv-frame group", big and "fixed inset-3 z-50 shadow-[0_0_0_4px_var(--frame),0_24px_60px_oklch(0_0_0/0.6)]")}
            style={None if big else {"height": height}}
        >
            {<button
                type="button"
                onClick={lambda { big = not big; }}
                className={cx("icon-btn absolute top-2 right-2 z-10 bg-card/80", not big and "opacity-0 group-hover:opacity-100 focus-visible:opacity-100")}
                aria-label={label}
                title={tr(loc, "TradingViewWidget.exitFullScreenHint") if big else label}
            >{<Minimize2 /> if big else <Maximize2 />}</button>
                if expand
                else None}
            <div
                ref={box}
                className={cx("tradingview-widget-container", className)}
                style={{"height": "100%", "width": "100%"}}
            />
        </div>
    </>;
}

# One headline tile: a label, its code and a price with the day's change. `href` makes it a link
# (an index has no stock page); `price` 0 is a quote we do not have.
def:pub PulseTile(
    label: str,
    code: str,
    href: str = "",
    price: float = 0.0,
    change: float = 0.0,
    percent: float = 0.0,
    before: str = "",
    after: str = "",
    loc: str = "en",
) -> JsxElement {
    body = <>
        <div className="bento-head">
            <span className="bento-ico"><LineChart /></span>
            <span className="truncate">{label}</span>
            <span className="mono ms-auto text-xs text-faint">{code}</span>
        </div>
        <PriceFlash
            value={price or None}
            className="bento-value num self-start text-[length:clamp(20px,15cqi,28px)]"
        >
            {<>
                {<small>{before}</small> if before else None}
                {amount(price, 4 if price < 1 else 2)}
                {<small>{after}</small> if after else None}
            </>
                if price
                else "—"}
        </PriceFlash>
        <div className="bento-foot">
            {<>
                <ChangePill value={percent} />
                <span className="num truncate">
                    {tr(
                        loc,
                        "PulseTile.vsPrevClose",
                        {
                            "change": ("+" if change > 0 else "")
                                + amount(change, 4 if abs(change) < 1 else 2),
                        },
                    )}
                </span>
            </>
                if price
                else <span>{tr(loc, "PulseTile.unavailable")}</span>}
        </div>
    </>;
    if not href {
        return <div className="bento-tile @container">{body}</div>;
    }
    return <Link to={href} className="bento-tile @container transition-colors hover:bg-hover/60">
        {body}
    </Link>;
}

# Four headline tiles for a market (a skeleton until it is known). Markets Finnhub can price
# get our own tiles from the shared quote cache, refreshed on screen every 15 seconds when
# `realtime`; Yahoo-priced markets (Tadawul, Warsaw) get our tiles from daily quotes; the rest
# use TradingView's quote tile, which is free for those exchanges.
def:pub IndexPulse(
    market: Market | None = None, realtime: bool = False, loc: str = "en"
) -> JsxElement {
    has quotes: dict[str, Quote] = {};
    has daily: dict[str, DailyQuote] = {};
    has timer: Ref[any] = Ref(None);

    pulse = market.pulse if market else [];

    async def load {
        native = [p.finnhub for p in pulse if p.finnhub];
        if market and market.yahoo {
            daily = await yahoo_daily_quotes([p.symbol for p in pulse]);
        } elif native {
            quotes = await live_quotes(native);
        }
    }

    async def refresh {
        if document.visibilityState == "visible" {
            await load();
        }
    }

    async can with [market] entry {
        await load();
    }

    can with [market, realtime] entry {
        timer.current = setInterval(refresh, 15000) if realtime else None;
    }

    can with [market, realtime] exit {
        clearInterval(timer.current);
    }

    if not market {
        return <div className="bento" aria-busy="true">
            {[
                <div key={i} className="bento-tile h-[124px]">
                    <span className="h-full animate-pulse rounded-lg bg-hover/60" />
                </div>
                for i in range(4)
            ]}
        </div>;
    }
    return <div className="bento">
        {
            for p in pulse {
                q = quotes.get(p.finnhub);
                d = daily.get(p.symbol);
                stock = yahoo_app_symbol(p.symbol) if market.yahoo else None;
                if market.yahoo {
                    <PulseTile
                        key={p.symbol}
                        label={p.label}
                        code={p.symbol.split(":")[-1]}
                        href={f"/stocks/{stock}" if stock else ""}
                        price={d.price if d else 0.0}
                        change={d.change if d else 0.0}
                        percent={d.change_percent if d else 0.0}
                        before={f"{d.currency} " if d and stock else ""}
                        {loc}
                    />
                } elif p.finnhub {
                    <PulseTile
                        key={p.symbol}
                        label={p.label}
                        code={p.finnhub.replace("BINANCE:", "")}
                        href={f"/stocks/{encodeURIComponent(p.finnhub)}"}
                        price={q.price if q else 0.0}
                        change={q.change if q else 0.0}
                        percent={q.change_percent if q else 0.0}
                        before={"" if p.finnhub.startswith("BINANCE:") else "$"}
                        after={" USDT" if p.finnhub.startswith("BINANCE:") else ""}
                        {loc}
                    />
                } else {
                    <div key={p.symbol} className="bento-tile p-1.5">
                        <TradingView
                            widget="single-quote"
                            config={symbol_info(p.symbol, loc)}
                            height={112}
                        />
                    </div>
                }
            }
        }
    </div>;
}

# The real app chrome with the same live data a signed-in user sees. Used on the landing and
# auth pages, in English, so marketing never shows a stale screenshot.
def:pub ProductPreview -> JsxElement {
    has us: Market | None = None;
    has realtime: bool = False;

    async can with entry {
        us = await get_market();
        realtime = await is_realtime();
    }

    return <div
        className="overflow-hidden rounded-[18px] bg-side p-[3px] shadow-[0_0_0_1px_oklch(1_0_0/0.05),0_30px_80px_oklch(0_0_0/0.55)]"
    >
        <div className="flex items-end gap-1 px-3 pt-2" aria-hidden>
            {[
                <span
                    key={tab}
                    className={cx("flex h-9 items-center rounded-t-xl px-3 font-semibold sm:min-w-[104px] sm:px-4", "mono text-[13px] text-faint" if i else "bg-canvas text-foreground")}
                >{tab}</span>
                for (i, tab) in enumerate(["Overview", "AAPL", "NVDA"])
            ]}
            <span className="chrome-btn"><Plus /></span>
        </div>
        <div className="flex flex-col gap-3 rounded-[15px] bg-canvas p-3 md:p-4">
            <section className="hatch">
                <div className="section-head">
                    <div>
                        <h3 className="section-title">Index pulse</h3>
                        <p className="section-sub">Tracking ETFs via Finnhub</p>
                    </div>
                    <DataFreshness loc="en" {realtime} />
                </div>
                <IndexPulse market={us} {realtime} />
            </section>
            <div className="grid gap-3 md:grid-cols-2">
                {[
                    <section key={symbol} className="hatch">
                        <div className="card overflow-hidden">
                            <TradingView
                                widget="mini-symbol-overview"
                                config={mini_chart(symbol)}
                                height={220}
                            />
                        </div>
                    </section>
                    for symbol in ["AMEX:SPY", "NASDAQ:QQQ"]
                ]}
            </div>
        </div>
    </div>;
}
