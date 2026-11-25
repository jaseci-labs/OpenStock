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
     };

def area(path: str) -> str {
    first = path.strip("/").split("/")[0];
    return "app" if first in APP else ("auth" if first in AUTH else "site");
}

# SLOT for the search server function: rows of {"symbol", "name", "exchange", "type"}, the popular stocks for ""
async def search_stocks(query: str) -> list[dict[str, any]] {
    return [];
}

# SLOT for the watchlist server function: the caller's starred stocks as {"symbol", "company"}.
# A page that changes the watchlist dispatches the window event "watchlistchange".
async def starred -> list[dict[str, str]] {
    return [];
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
        document.title = TITLES.get(path, "OpenStock");
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
    return <AppShell user={who} {watchlist} palette={<SearchCommand search={search_stocks} />}>
        {<Outlet /> if who else <Loading />}
    </AppShell>;
}
