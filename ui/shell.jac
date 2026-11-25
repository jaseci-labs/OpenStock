"""The signed-in app's frame (sidebar, tab bar, search palette) and the auth pages' frame."""
import from "@jac/runtime" { Link, __getLocalStorage, __setLocalStorage, navigate, useLocation }
import from "lucide-react" {
    ArrowUpRight,
    BookOpen,
    Code2,
    Heart,
    Info,
    Languages,
    LayoutDashboard,
    LifeBuoy,
    Loader2,
    LogOut,
    Menu as MenuIcon,
    Plus,
    Search,
    Star,
    X,
}

glob PINNED: list[str] = ["/dashboard", "/watchlist"],
     # Message keys under TabBar.pages
     PAGE_LABELS: dict[str, str] = {
         "/dashboard": "overview",
         "/watchlist": "watchlist",
         "/profile": "profile",
     },
     MAX_TABS: int = 12,
     RESOURCES: list[list[any]] = [
         ["/help", "help", LifeBuoy],
         ["/api-docs", "apiDocs", Code2],
         ["/about", "about", Info],
         ["/terms", "terms", BookOpen],
     ],
     DONATE_COOLDOWN_MS: int = 24 * 60 * 60 * 1000,
     CURVE: str = "M12 0v12H0c6.627 0 12-5.373 12-12z",
     # One palette is mounted in the shell, so a request to file results into a named list
     # travels with the open event: {} or {"id", "name"}
     requested_list: dict[str, str] = {};

# Any button can open the one palette mounted in the app shell
def:pub open_search {
    window.dispatchEvent(new(Event, "open-search"));
}

# Opens the palette in "add to this list" mode: each result gets an Add button and files into the list
def:pub open_search_for_list(id: str, name: str) {
    requested_list = {"id": id, "name": name};
    open_search();
}

def:pub open_donate {
    window.dispatchEvent(new(Event, "open-donate-popup"));
}

# The stock palette (⌘K). `search` is given the typed text ("" for the popular stocks) and gives
# rows of {"symbol", "name", "exchange", "type"}; `addToList(listId, symbol, name)` gives "" or what went wrong.
def:pub SearchCommand(
    search: Callable[[str], Coroutine[any, any, list[dict[str, any]]]],
    addToList: Callable[[str, str, str], Coroutine[any, any, str]] | None = None,
) -> JsxElement {
    has open: bool = False;
    has term: str = "";
    has loading: bool = False;
    has popular: list[dict[str, any]] = [];
    has found: list[dict[str, any]] = [];
    has target: dict[str, str] = {};
    has adding: str = "";
    has timer: Ref[any] = Ref(None);
    has on_event: Ref[any] = Ref(None);

    query = term.strip();
    stocks = found if query else popular[:10];

    def close {
        open = False;
        target = {};
        term = "";
    }

    async can with entry {
        on_event.current = lambda (e: any) {
            if e.type == "open-search" {
                # Read once, then clear: a later plain open must not keep adding to the old list
                target = requested_list;
                requested_list = {};
                open = True;
            } elif (e.metaKey or e.ctrlKey) and str(e.key).lower() == "k" {
                e.preventDefault();
                target = {};
                open = not open;
            }
        };
        window.addEventListener("keydown", on_event.current);
        window.addEventListener("open-search", on_event.current);
        popular = await search("");
    }

    can with exit {
        window.removeEventListener("keydown", on_event.current);
        window.removeEventListener("open-search", on_event.current);
    }

    async def run(text: str) {
        try {
            found = await search(text);
        } except Exception {
            found = [];
        }
        loading = False;
    }

    # Searches 300ms after the last key
    can with [query] entry {
        clearTimeout(timer.current);
        if query {
            loading = True;
            timer.current = setTimeout(lambda { run(query) }, 300);
        }
    }

    async def add(stock: dict[str, any]) {
        if adding or addToList is None {
            return;
        }
        adding = stock["symbol"];
        problem = await addToList(target["id"], stock["symbol"], stock["name"]);
        if problem {
            toast_error(problem);
        } else {
            # The palette stays open so several stocks can be filed in one go
            toast_ok(
                t("SearchCommand.addedToList", {"symbol": stock["symbol"], "list": target["name"]})
            );
        }
        adding = "";
    }

    # In list mode the row files the stock instead of navigating: the prompt says "add", and the
    # row is the biggest target. A modified click is still a request to open the stock.
    def picked(e: any, stock: dict[str, any]) -> any {
        if not target {
            close();
        } elif not (e.metaKey or e.ctrlKey or e.shiftKey) {
            e.preventDefault();
            return add(stock);
        }
    }

    return <Dialog
        {open}
        onClose={close}
        label={t("SearchCommand.dialogTitle")}
        className="search-dialog sm:max-w-lg"
    >
        <div className="search-field flex items-center gap-2 px-3">
            <Search className="size-5 shrink-0 opacity-50" />
            <input
                autoFocus
                value={term}
                onInput={lambda (e: any) { term = e.target.value; }}
                placeholder={t("SearchCommand.listPlaceholder", {"list": target["name"]}) if target else t("SearchCommand.placeholder")}
                className="search-input w-full bg-transparent outline-hidden"
            />
            {<Loader2 className="search-loader" /> if loading else None}
        </div>
        <div className="search-list overflow-x-hidden overflow-y-auto">
            {
                if loading {
                    <p className="search-list-empty text-sm">{t("SearchCommand.searching")}</p>
                } elif not stocks {
                    <div className="search-list-indicator">
                        {t("SearchCommand.noMatch", {"query": query})
                            if query
                            else t("SearchCommand.noStocks")}
                    </div>
                } else {
                    <ul>
                        <li className="search-count">
                            {rich(
                                "SearchCommand.addingTo",
                                {
                                    "name": lambda (chunk: str) -> any {
                                        <span key="name" className="font-semibold">{chunk}</span>
                                    },
                                },
                                {"list": target["name"]},
                            )
                                if target
                                else t(
                                    "SearchCommand.results" if query else "SearchCommand.popular"
                                )}
                            <span className="num"> · {len(stocks)}</span>
                        </li>
                        {[
                            <li
                                key={stock["symbol"]}
                                className={cx("search-item", target and "flex items-center gap-1 pe-2")}
                            >
                                <Link
                                    to={f"/stocks/{stock['symbol']}"}
                                    onClick={lambda (e: any) -> any { picked(e, stock) }}
                                    className={cx("search-item-link group", target and "min-w-0 flex-1")}
                                >
                                    <span
                                        className="mono w-20 shrink-0 truncate text-[13px] font-semibold text-brand-ink"
                                    >{stock["symbol"]}</span>
                                    <span className="search-item-name flex-1">{stock["name"]}</span>
                                    <span
                                        className="hidden max-w-40 truncate text-xs text-faint sm:block"
                                    >
                                        {" · ".join([
                                            str(x)
                                            for x in [stock.get("exchange"), stock.get("type")]
                                            if x
                                        ])}
                                    </span>
                                    <ArrowUpRight
                                        className="size-4 text-faint opacity-0 transition-opacity group-hover:opacity-100"
                                    />
                                </Link>
                                {<button
                                    type="button"
                                    onClick={lambda { add(stock) }}
                                    disabled={adding != ""}
                                    className="pill h-7 shrink-0"
                                    title={t("SearchCommand.addTitle", {"symbol": stock["symbol"], "list": target["name"]})}
                                ><Plus className="size-3.5" /> {t(
                                    "SearchCommand.adding"
                                        if adding == stock["symbol"]
                                        else "SearchCommand.add",
                                )}</button>
                                    if target
                                    else None}
                            </li>
                            for stock in stocks
                        ]}
                    </ul>
                }
            }
        </div>
    </Dialog>;
}

# Language names stay in their own language so anyone can find theirs
def:pub LanguageSwitcher -> JsxElement {
    return <Menu
        up
        className="side-item h-8 w-full text-start outline-none"
        panelClassName="w-full"
        trigger={<><Languages /><span className="flex-1">{t("Language.label")}</span><span className="text-xs text-faint" lang={locale()}>{LOCALE_NAMES[locale()]}</span></>}
    >
        {[
            <MenuItem
                key={code}
                radio
                checked={code == locale()}
                lang={code}
                onSelect={lambda { set_locale(code); }}
            >{LOCALE_NAMES[code]}</MenuItem>
            for code in LOCALES
        ]}
    </Menu>;
}

# Asks for sponsors 3 seconds into a visit, at most once a day; the sidebar's Support button opens it too
def:pub DonatePopup -> JsxElement {
    has open: bool = False;
    has timer: Ref[any] = Ref(None);
    has on_open: Ref[any] = Ref(None);

    can with entry {
        on_open.current = lambda { open = True; };
        window.addEventListener("open-donate-popup", on_open.current);
        if Date.now() - int(__getLocalStorage("opendevsociety-donate-popup-dismissed") or "0")
            >= DONATE_COOLDOWN_MS
        {
            timer.current = setTimeout(on_open.current, 3000);
        }
    }

    can with exit {
        clearTimeout(timer.current);
        window.removeEventListener("open-donate-popup", on_open.current);
    }

    def dismiss {
        open = False;
        __setLocalStorage("opendevsociety-donate-popup-dismissed", str(Date.now()));
    }

    return <Dialog {open} onClose={dismiss} className="grid gap-5 p-6 sm:max-w-[440px]">
        <div className="flex flex-col gap-3 text-start">
            <span className="bento-ico size-11 bg-brand-soft text-brand-ink">
                <Heart className="size-5 fill-current" />
            </span>
            <div>
                <p className="kicker flex items-center gap-2 text-brand-ink"><span
                    className="live-dot"
                /> {t("DonatePopup.kicker")}</p>
                <h2 className="mt-1.5 text-2xl font-bold leading-none tracking-[-0.03em]">
                    {t("DonatePopup.title")}
                </h2>
            </div>
            <p className="text-[15px] leading-relaxed text-muted-foreground">
                {t("DonatePopup.description")}
            </p>
        </div>
        <div className="flex flex-col gap-2 sm:flex-row">
            <Link to="/sponsor" onClick={dismiss} className="btn btn-primary h-11 flex-1"><Heart
                className="fill-current"
            /> {t("DonatePopup.becomeSponsor")}</Link>
            <button type="button" onClick={dismiss} className="btn btn-ghost h-11 flex-1">
                {t("DonatePopup.maybeLater")}
            </button>
        </div>
    </Dialog>;
}

# Market chips for the dashboard: `markets` are ids (named by Markets.names.<id>), `openIds` the ones trading now
def:pub MarketSwitcher(
    markets: list[str], active: str, openIds: list[str], onPick: Callable[[str], None]
) -> JsxElement {
    return <nav
        aria-label={t("MarketSwitcher.label")}
        className="flex gap-1.5 overflow-x-auto px-1 pb-1 [scrollbar-width:none]"
    >
        {[
            <button
                key={id}
                type="button"
                onClick={lambda { onPick(id); }}
                aria-current={"page" if id == active else None}
                className={cx("flex h-9 flex-none items-center gap-2 rounded-full px-3.5 text-[13.5px] font-semibold transition-[background-color,color,box-shadow] duration-150", "bg-brand-soft text-brand-ink shadow-[inset_0_0_0_1px_oklch(0.8_0.13_176/0.45)]" if id == active else "text-muted-foreground shadow-[inset_0_0_0_1px_var(--line)] hover:bg-hover hover:text-foreground")}
            >
                <span
                    className={cx("size-1.5 rounded-full", "bg-up" if id in openIds else "bg-line-strong")}
                    title={t("MarketSwitcher.openNow" if id in openIds else "MarketSwitcher.closedNow")}
                />
                {t(f"Markets.names.{id}")}
            </button>
            for id in markets
        ]}
    </nav>;
}

def Sidebar(user: dict[str, str], watchlist: list[dict[str, str]], path: str) -> JsxElement {
    partners = sidebar_sponsors();
    free = SIDEBAR_SPONSOR_SLOTS - len(partners);
    name = user.get("name", "");
    return <aside className="sidebar">
        <Link to="/dashboard" className="px-2 pt-1 pb-2" aria-label={t("Sidebar.homeAria")}>
            <img src="/assets/images/logo.png" alt="OpenStock" width={150} height={38} />
        </Link>
        <button type="button" onClick={open_search} className="side-cta">
            <Search className="size-4" strokeWidth={2.5} />
            <span className="flex-1 text-start">{t("Sidebar.searchStocks")}</span>
            <kbd className="kbd bg-on-brand/10">⌘K</kbd>
        </button>
        <nav className="flex flex-col gap-0.5">
            <Link
                to="/dashboard"
                className={cx("side-item", path == "/dashboard" and "is-active")}
            ><LayoutDashboard /> {t("Sidebar.overview")}</Link>
            <Link
                to="/watchlist"
                className={cx("side-item", path == "/watchlist" and "is-active")}
            ><Star /> <span className="flex-1">{t("Sidebar.watchlist")}</span><span
                className="num text-xs text-faint"
            >{len(watchlist)}</span></Link>
        </nav>
        <div className="flex min-h-0 flex-col gap-1">
            <p className="side-label shrink-0">{t("Sidebar.watching")}</p>
            {<p className="px-2.5 text-[12.5px] text-faint">{t("Sidebar.watchingEmpty")}</p>
                if not watchlist
                else <ul
                    className="scrollbar-hide-default flex min-h-0 flex-col gap-0.5 overflow-y-auto"
                >
                    {[
                        <li key={w["symbol"]}>
                            <Link
                                to={f"/stocks/{w['symbol']}"}
                                title={w["company"]}
                                className={cx("side-item h-8 font-medium", path == f"/stocks/{w['symbol']}" and "is-active")}
                            >
                                <span
                                    className="mono min-w-14 max-w-24 shrink-0 truncate text-[12.5px] font-semibold text-foreground"
                                >{w["symbol"]}</span>
                                {<span dir="auto" className="truncate text-[12.5px] text-faint">
                                    {w["company"]}
                                </span>
                                    if w["company"] != w["symbol"]
                                    else None}
                            </Link>
                        </li>
                        for w in watchlist
                    ]}
                </ul>}
        </div>
        <div className="mt-auto flex flex-col gap-0.5">
            {[
                <Link
                    key={r[0]}
                    to={r[0]}
                    className={cx("side-item h-8", path == r[0] and "is-active")}
                ><@{r[2]} /> {t(f"Sidebar.resources.{r[1]}")}</Link>
                for r in RESOURCES
            ]}
            <button type="button" onClick={open_donate} className="side-item h-8 text-start"><Heart
            /> {t("Sidebar.support")}</button>
            <LanguageSwitcher />
        </div>
        <div className="flex flex-col gap-1.5">
            {[
                <SponsorLink
                    key={s.name}
                    sponsor={s}
                    title={s.name}
                    className="flex h-11 items-center gap-2.5 rounded-[11px] px-3 shadow-[inset_0_0_0_1px_var(--line)] transition-colors hover:bg-white/5"
                >
                    <SponsorMark
                        sponsor={s}
                        logoClassName="h-5 w-auto max-w-[120px]"
                        nameClassName="truncate text-[13px] font-semibold text-muted-foreground"
                    />
                    <span className="kicker ms-auto">{t("Sidebar.sponsor")}</span>
                </SponsorLink>
                for s in partners
            ]}
            {<Link
                to="/sponsor#tiers"
                className="group flex flex-col gap-0.5 rounded-[11px] px-3 py-2.5 shadow-[inset_0_0_0_1px_var(--line)] transition-colors hover:bg-white/5"
            >
                <span className="kicker flex items-center gap-1.5 text-brand-ink"><span
                    className="live-dot"
                /> {t("Sidebar.sponsorSlotsOpen")
                    if free == SIDEBAR_SPONSOR_SLOTS
                    else t("Sidebar.sponsorSlotsLeft", {"count": free})}</span>
                <span
                    className="text-[12.5px] text-faint transition-colors group-hover:text-muted-foreground"
                >{t("Sidebar.sponsorPitch")}</span>
            </Link>
                if free > 0
                else None}
        </div>
        <div className="flex items-center gap-2.5 border-t border-line px-1 pt-3">
            <Link
                to="/profile"
                className={cx("-m-1 flex min-w-0 flex-1 items-center gap-2.5 rounded-[10px] p-1 transition-colors hover:bg-white/5", path == "/profile" and "bg-white/5")}
            >
                <span
                    className="grid size-8 flex-none place-items-center rounded-full bg-brand-soft text-[13px] font-bold text-brand-ink"
                >{name[:1].upper() or "?"}</span>
                <span className="min-w-0 flex-1">
                    <span
                        dir="auto"
                        className="block truncate text-[13px] font-semibold text-foreground rtl:text-right"
                    >{name}</span>
                    <span
                        dir="auto"
                        className="block truncate text-[12px] text-faint rtl:text-right"
                    >{user.get("email", "")}</span>
                </span>
            </Link>
            <button
                type="button"
                onClick={leave}
                className="icon-btn"
                title={t("Sidebar.signOut")}
                aria-label={t("Sidebar.signOut")}
            ><LogOut /></button>
        </div>
    </aside>;
}

# Pages become browser-style tabs; stock pages are labelled by their symbol
def tab_label(path: str) -> str {
    if path.startswith("/stocks/") and path.count("/") == 2 {
        return decodeURIComponent(path[8:]).upper();
    }
    return t(f"TabBar.pages.{PAGE_LABELS[path]}") if path in PAGE_LABELS else "";
}

def with_tab(tabs: list[str], path: str) -> list[str] {
    if tab_label(path) == "" or path in tabs {
        return tabs;
    }
    opened = tabs + [path];
    extra = len(opened) - MAX_TABS;
    return [p for (i, p) in enumerate(opened) if p in PINNED or i >= extra + len(PINNED)]
        if extra > 0
        else opened;
}

def saved_tabs(path: str) -> list[str] {
    tabs = PINNED;
    try {
        for saved in JSON.parse(__getLocalStorage("openstock-tabs") or "[]") {
            tabs = with_tab(tabs, str(saved));
        }
    } except Exception {}
    return with_tab(tabs, path);
}

def TabBar(path: str, onMenu: Callable[[], None]) -> JsxElement {
    has tabs: list[str] = saved_tabs(path);
    has strip: Ref[any] = Ref(None);
    has glider: list[float] = [];

    # The glider sits under the active tab: measured once the tabs are laid out
    can with [path, tabs] entry {
        if path not in tabs and tab_label(path) {
            tabs = with_tab(tabs, path);
            return;
        }
        __setLocalStorage("openstock-tabs", JSON.stringify(tabs));
        el = strip.current.querySelector("[data-active]");
        glider = [el.offsetLeft - 11, el.offsetWidth + 22] if el else [];
        if el {
            el.scrollIntoView({"block": "nearest", "inline": "nearest"});
        }
    }

    def close_tab(tab: str) {
        left = [p for p in tabs if p != tab];
        if tab == path {
            navigate(left[max(0, tabs.index(tab) - 1)]);
        }
        tabs = left;
    }

    return <div className="tabbar">
        <button
            type="button"
            onClick={lambda { onMenu(); }}
            className="chrome-btn lg:hidden"
            aria-label={t("TabBar.openMenu")}
        ><MenuIcon /></button>
        <div ref={strip} className="tabs ps-3 pe-3">
            <div
                className={cx("tab-glider", glider and "is-ready")}
                style={{"transform": f"translateX({glider[0]}px)", "width": glider[1]} if glider else None}
                aria-hidden
            >
                <svg className="tab-glider-curve is-left" viewBox="0 0 12 12">
                    <path d={CURVE} />
                </svg>
                <div className="tab-glider-body" />
                <svg className="tab-glider-curve is-right" viewBox="0 0 12 12">
                    <path d={CURVE} />
                </svg>
            </div>
            {[
                <div
                    key={tab}
                    data-active={"" if tab == path else None}
                    className={cx("tab", tab == path and "is-active", tab in PINNED and "pe-4")}
                >
                    {#* Stretched link: the whole tab navigates, while the close button stays a real, focusable button *#}
                    <Link
                        to={tab}
                        aria-current={"page" if tab == path else None}
                        className="flex min-w-0 flex-1 items-center gap-2 before:absolute before:inset-0 before:content-['']"
                    >
                        {<LayoutDashboard />
                            if tab == "/dashboard"
                            else (<Star /> if tab == "/watchlist" else None)}
                        <span
                            className={cx("tab-label", tab.startswith("/stocks/") and "mono text-[13px]")}
                        >{tab_label(tab)}</span>
                    </Link>
                    {<button
                        type="button"
                        aria-label={t("TabBar.closeTab", {"label": tab_label(tab)})}
                        className="tab-close relative z-10"
                        onClick={lambda { close_tab(tab); }}
                    ><X /></button>
                        if tab not in PINNED
                        else None}
                </div>
                for tab in tabs
            ]}
        </div>
        <button
            type="button"
            onClick={open_search}
            className="chrome-btn -ms-2"
            aria-label={t("TabBar.openStock")}
            title={t("TabBar.openStockHint")}
        ><Plus /></button>
    </div>;
}

# The signed-in app around a page. `user` is session.me(); `watchlist` rows are {"symbol", "company"};
# `palette` is the mounted <SearchCommand>.
def:pub AppShell(
    user: dict[str, str], watchlist: list[dict[str, str]], children: any, palette: any = None
) -> JsxElement {
    has nav_open: bool = False;
    has workspace: Ref[any] = Ref(None);

    path = useLocation().pathname;

    # The workspace is the scroll container, so reset it on navigation
    can with [path] entry {
        nav_open = False;
        workspace.current.scrollTo({"top": 0});
    }

    return <div className="shell">
        {#* The drawer slides in from the reading side: the right in Arabic *#}
        <div
            className={cx("min-h-0 max-lg:fixed max-lg:inset-y-0 max-lg:left-0 max-lg:rtl:left-auto max-lg:rtl:right-0 max-lg:z-50 max-lg:w-[272px] max-lg:transition-transform max-lg:duration-200", "max-lg:translate-x-0" if nav_open else "max-lg:-translate-x-full max-lg:rtl:translate-x-full")}
        ><Sidebar {user} {watchlist} {path} /></div>
        {<div
            className="fixed inset-0 z-40 bg-page/60 backdrop-blur-[2px] lg:hidden"
            onClick={lambda { nav_open = False; }}
        />
            if nav_open
            else None}
        <div className="shell-container">
            <div className="app">
                <TabBar {path} onMenu={lambda { nav_open = True; }} />
                <main
                    ref={workspace}
                    className={cx("workspace", path == "/dashboard" and "is-first-tab")}
                >
                    <div className="workspace-inner"><UpdateBanner loc={locale()} />{children}</div>
                </main>
            </div>
        </div>
        {palette}
        <DonatePopup />
    </div>;
}

# The sign-in pages' frame: the form on one side, the founder's words over a product preview on the other
def:pub AuthLayout(children: any) -> JsxElement {
    return <main className="auth-layout">
        <section className="auth-left-section scrollbar-hide-default">
            <Link to="/" className="auth-logo flex items-center gap-2">
                <img src="/assets/images/logo.png" alt="OpenStock" width={140} height={35} />
            </Link>
            <div className="flex-1 pb-6 lg:pb-8">{children}</div>
        </section>
        <section className="auth-right-section">
            <div className="relative z-10 lg:mt-4 lg:mb-16">
                <blockquote className="auth-blockquote">
                    {t("AuthLayout.testimonialQuote")}
                </blockquote>
                <div className="flex items-center justify-between">
                    <div>
                        <cite
                            className="auth-testimonial-author"
                        >- Ravi Pratap Singh (@ravixalgorithm)</cite>
                        <p className="text-gray-500 max-md:text-xs">
                            {t("AuthLayout.founderRole", {"org": "@opendevsociety"})}
                        </p>
                    </div>
                    <div className="flex items-center gap-0.5">
                        {[
                            <img
                                key={i}
                                src="/assets/icons/star.svg"
                                alt={t("AuthLayout.starAlt")}
                                width={20}
                                height={20}
                                className="h-4 w-4"
                            />
                            for i in range(5)
                        ]}
                    </div>
                </div>
            </div>
            <div className="relative flex-1" aria-hidden>
                <div className="auth-dashboard-preview absolute top-0"><ProductPreview /></div>
            </div>
        </section>
    </main>;
}
