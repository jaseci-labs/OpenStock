"""Chooses each page's frame by its route: the signed-in app, the auth pages, or the public site."""
import from "@jac/runtime" { Outlet, navigate, useLocation }

# A page is the app's or an auth page by its first path segment; every other route is the
# public site. A new private route is added to APP.
glob APP: list[str] = ["dashboard", "watchlist", "profile", "stocks"],
     AUTH: list[str] = ["sign-in", "sign-up", "forgot-password", "reset-password"],
     TITLES: dict[str, str] = {
         "/about": "About | OpenStock",
         "/help": "Help | OpenStock",
         "/terms": "Terms of Service | OpenStock",
         "/api-docs": "Architecture | OpenStock",
         "/love": "Wall of love",
         "/changelog": "Changelog",
         "/sponsor": "Sponsor OpenStock",
         "/compare": "Guides | OpenStock",
     },
     ABOUT: dict[str, str] = {
         "/changelog": "Everything that changed in OpenStock, release by release, since it started in September 2025.",
         "/sponsor": "Back free, open-source market data. Monthly tiers, one-time gifts, or talk with us about a partnership.",
         "/compare": "What OpenStock is and is not: an open-source stock tracker with TradingView charts, a watchlist, email alerts, and self-hosting. Honest comparisons, no account required.",
     };

def area(path: str) -> str {
    first = path.strip("/").split("/")[0];
    return "app" if first in APP else ("auth" if first in AUTH else "site");
}

# The palette's rows: the popular stocks for ""
async def find_stocks(query: str) -> list[dict[str, any]] {
    return [
        {"symbol": s.symbol, "name": s.name, "exchange": s.exchange, "type": s.kind}
        for s in await search_stocks(query)
    ];
}

# The sidebar's stocks. Whatever changes the watchlist dispatches the window event "watchlistchange".
async def starred -> list[dict[str, str]] {
    return [{"symbol": w.symbol, "company": w.company} for w in await get_watchlist()];
}

# The palette in "add to this list" mode: "" or what went wrong
async def file_into(list_id: str, symbol: str, name: str) -> str {
    refused = problem((await add_to_list(list_id, symbol, name)).error);
    if refused == "" {
        changed();
    }
    return refused;
}

def:pub layout -> JsxLayout {
    has who: dict[str, str] = {};
    has watchlist: list[dict[str, str]] = [];
    has on_change: Ref[any] = Ref(None);

    path = useLocation().pathname;
    kind = area(path);

    async def refresh(e: any) {
        if e.type == "userchange" {
            who = me();
        } elif me() {
            watchlist = await starred();
        }
    }

    can with entry {
        on_change.current = refresh;
        window.addEventListener("userchange", on_change.current);
        window.addEventListener("watchlistchange", on_change.current);
    }

    can with exit {
        window.removeEventListener("userchange", on_change.current);
        window.removeEventListener("watchlistchange", on_change.current);
    }

    can with [path] entry {
        head(TITLES.get(path, "OpenStock"), ABOUT.get(path, ""));
    }

    # The app and the auth pages are in the user's language; the public site is English, so
    # <html> goes back to what it renders with. The app needs a session, as the middleware did,
    # and the auth pages send a signed-in visitor on.
    async can with [kind] entry {
        loc = "en" if kind == "site" else locale();
        document.documentElement.lang = loc;
        document.documentElement.dir = "rtl" if is_rtl(loc) else "";
        if kind != "site" {
            signed = await load_user();
            if signed != (kind == "app") {
                navigate("/dashboard" if signed else "/sign-in");
            } elif signed {
                watchlist = await starred();
            }
        }
    }

    if kind == "site" {
        return <MarketingLayout><Outlet /></MarketingLayout>;
    }
    if kind == "auth" {
        return <AuthLayout><Outlet /></AuthLayout>;
    }
    return <AppShell
        user={who}
        {watchlist}
        palette={<SearchCommand search={find_stocks} addToList={file_into} />}
    >{<Outlet /> if who else <Loading />}</AppShell>;
}
