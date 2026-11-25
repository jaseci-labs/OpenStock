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
     PAGE_ICONS: dict[str, any] = {"/dashboard": LayoutDashboard, "/watchlist": Star},
     MAX_TABS: int = 12,
     RESOURCES: list[list[any]] = [
         ["/help", "Sidebar.resources.help", LifeBuoy],
         ["/api-docs", "Sidebar.resources.apiDocs", Code2],
         ["/about", "Sidebar.resources.about", Info],
         ["/terms", "Sidebar.resources.terms", BookOpen],
     ],
     DONATE_COOLDOWN_MS: int = 24 * 60 * 60 * 1000,
     DISMISSED: str = "opendevsociety-donate-popup-dismissed",
     CURVE: str = "M12 0v12H0c6.627 0 12-5.373 12-12z",
     # One palette is mounted in the shell, so a request to file results into a named list
     # travels with the open event: {} or {"id", "name"}
     requested_list: dict[str, str] = {},
     SYMBOL: str = "mono w-20 shrink-0 truncate text-[13px] font-semibold text-brand-ink",
     ARROW: str = "size-4 text-faint opacity-0 transition-opacity group-hover:opacity-100",
     CHIP: str = "flex h-9 flex-none items-center gap-2 rounded-full px-3.5 text-[13.5px] font-semibold transition-[background-color,color,box-shadow] duration-150",
     CHIP_ON: str = "bg-brand-soft text-brand-ink shadow-[inset_0_0_0_1px_oklch(0.8_0.13_176/0.45)]",
     CHIP_OFF: str = "text-muted-foreground shadow-[inset_0_0_0_1px_var(--line)] hover:bg-hover hover:text-foreground",
     WATCHED: str = "mono min-w-14 max-w-24 shrink-0 truncate text-[12.5px] font-semibold text-foreground",
     BOXED: str = "rounded-[11px] shadow-[inset_0_0_0_1px_var(--line)] transition-colors hover:bg-white/5",
     ME: str = "-m-1 flex min-w-0 flex-1 items-center gap-2.5 rounded-[10px] p-1 transition-colors hover:bg-white/5",
     INITIAL: str = "grid size-8 flex-none place-items-center rounded-full bg-brand-soft text-[13px] font-bold text-brand-ink",
     NAMED: str = "block truncate text-[13px] font-semibold text-foreground rtl:text-right",
     PITCH: str = "text-[12.5px] text-faint transition-colors group-hover:text-muted-foreground",
     SHADE: str = "fixed inset-0 z-40 bg-page/60 backdrop-blur-[2px] lg:hidden",
     STRETCHED: str = "flex min-w-0 flex-1 items-center gap-2 before:absolute before:inset-0 before:content-['']",
     DRAWER: str = "min-h-0 max-lg:fixed max-lg:inset-y-0 max-lg:left-0 max-lg:rtl:left-auto max-lg:rtl:right-0 max-lg:z-50 max-lg:w-[272px] max-lg:transition-transform max-lg:duration-200",
     DRAWER_SHUT: str = "max-lg:-translate-x-full max-lg:rtl:translate-x-full";

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

# One stock in the palette; in list mode it carries an Add button
def Result(
    stock: Stock,
    target: dict[str, str],
    adding: str,
    onPick: Callable[[any, Stock], any],
    onAdd: Callable[[Stock], any],
) -> JsxElement {
    vars: dict[str, any] = {"symbol": stock.symbol, "list": target.get("name", "")};
    said = t("SearchCommand.adding" if adding == stock.symbol else "SearchCommand.add");
    tip = t("SearchCommand.addTitle", vars);
    add = lambda { onAdd(stock) };
    busy = adding != "";
    look = "pill h-7 shrink-0";
    inner = <><Plus className="size-3.5" /> {said}</>;
    button = <button type="button" onClick={add} disabled={busy} className={look} title={tip}>
        {inner}
    </button>;
    where = " · ".join([str(x) for x in [stock.exchange, stock.kind] if x]);
    pick = lambda (e: any) -> any { onPick(e, stock) };
    link = cx("search-item-link group", target and "min-w-0 flex-1");
    return <li className={cx("search-item", target and "flex items-center gap-1 pe-2")}>
        <Link to={f"/stocks/{stock.symbol}"} onClick={pick} className={link}>
            <span className={SYMBOL}>{stock.symbol}</span>
            <span className="search-item-name flex-1">{stock.name}</span>
            <span className="hidden max-w-40 truncate text-xs text-faint sm:block">{where}</span>
            <ArrowUpRight className={ARROW} />
        </Link>
        {button if target else None}
    </li>;
}

# The stock palette (⌘K): the popular stocks until something is typed, then the server's matches. Opened for
# a named list (open_search_for_list), each result files into that list instead.
def:pub SearchCommand -> JsxElement {
    has open: bool = False;
    has term: str = "";
    has loading: bool = False;
    has popular: list[Stock] = [];
    has found: list[Stock] = [];
    has target: dict[str, str] = {};
    has adding: str = "";
    has timer: Ref[any] = Ref(None);

    query = term.strip();
    stocks = found if query else popular[:10];

    def close {
        open = False;
        target = {};
        term = "";
    }

    def heard(e: any) {
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
    }

    listen(window, ["keydown", "open-search"], heard);

    async can with entry {
        popular = await search_stocks("");
    }

    async def run(text: str) {
        try {
            found = await search_stocks(text);
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

    async def add(stock: Stock) {
        if adding {
            return;
        }
        adding = stock.symbol;
        refused = problem((await add_to_list(target["id"], stock.symbol, stock.name)).error);
        if refused {
            toast_error(refused);
        } else {
            # The palette stays open so several stocks can be filed in one go
            toast_ok(
                t("SearchCommand.addedToList", {"symbol": stock.symbol, "list": target["name"]})
            );
            changed();
        }
        adding = "";
    }

    # In list mode the row files the stock instead of navigating: the prompt says "add", and the
    # row is the biggest target. A modified click is still a request to open the stock.
    def picked(e: any, stock: Stock) -> any {
        if not target {
            close();
        } elif not (e.metaKey or e.ctrlKey or e.shiftKey) {
            e.preventDefault();
            return add(stock);
        }
    }

    bold = lambda (chunk: str) -> any { <span key="name" className="font-semibold">{chunk}</span> };
    named: dict[str, any] = {"list": target.get("name", "")};
    heading = rich("SearchCommand.addingTo", {"name": bold}, named)
        if target
        else t("SearchCommand.results" if query else "SearchCommand.popular");
    prompt = t("SearchCommand.listPlaceholder", named)
        if target
        else t("SearchCommand.placeholder");
    none = t("SearchCommand.noMatch", {"query": query}) if query else t("SearchCommand.noStocks");
    typed = lambda (e: any) { term = e.target.value; };
    field = "search-input w-full bg-transparent outline-hidden";
    rows = [
        <Result key={s.symbol} stock={s} {target} {adding} onPick={picked} onAdd={add} />
        for s in stocks
    ];
    head = <li className="search-count">{heading}<span className="num"> · {len(stocks)}</span></li>;
    listed = <ul>{head}{rows}</ul>
        if stocks
        else <div className="search-list-indicator">{none}</div>;
    busy = <p className="search-list-empty text-sm">{t("SearchCommand.searching")}</p>;
    shown = busy if loading else listed;
    label = t("SearchCommand.dialogTitle");
    return <Dialog {open} onClose={close} {label} className="search-dialog sm:max-w-lg">
        <div className="search-field flex items-center gap-2 px-3">
            <Search className="size-5 shrink-0 opacity-50" />
            <input autoFocus value={term} onInput={typed} placeholder={prompt} className={field} />
            {<Loader2 className="search-loader" /> if loading else None}
        </div>
        <div className="search-list overflow-x-hidden overflow-y-auto">{shown}</div>
    </Dialog>;
}

# Language names stay in their own language so anyone can find theirs
def:pub LanguageSwitcher -> JsxElement {
    loc = locale();
    trigger = <>
        <Languages />
        <span className="flex-1">{t("Language.label")}</span>
        <span className="text-xs text-faint" lang={loc}>{LOCALE_NAMES[loc]}</span>
    </>;
    names = [
        <MenuItem key={c} radio checked={c == loc} lang={c} onSelect={lambda { set_locale(c); }}>
            {LOCALE_NAMES[c]}
        </MenuItem>
        for c in LOCALES
    ];
    look = "side-item h-8 w-full text-start outline-none";
    return <Menu up className={look} panelClassName="w-full" {trigger}>{names}</Menu>;
}

# Asks for sponsors 3 seconds into a visit, at most once a day; the sidebar's Support button opens it too
def:pub DonatePopup -> JsxElement {
    has open: bool = False;
    has timer: Ref[any] = Ref(None);

    listen(window, ["open-donate-popup"], lambda { open = True; });

    can with entry {
        if Date.now() - int(__getLocalStorage(DISMISSED) or "0") >= DONATE_COOLDOWN_MS {
            timer.current = setTimeout(lambda { open = True; }, 3000);
        }
    }

    can with exit {
        clearTimeout(timer.current);
    }

    def dismiss {
        open = False;
        __setLocalStorage(DISMISSED, str(Date.now()));
    }

    title = "mt-1.5 text-2xl font-bold leading-none tracking-[-0.03em]";
    become = <><Heart className="fill-current" /> {t("DonatePopup.becomeSponsor")}</>;
    about = t("DonatePopup.description");
    return <Dialog {open} onClose={dismiss} className="grid gap-5 p-6 sm:max-w-[440px]">
        <div className="flex flex-col gap-3 text-start">
            <span className="bento-ico size-11 bg-brand-soft text-brand-ink">
                <Heart className="size-5 fill-current" />
            </span>
            <div>
                <Live>{t("DonatePopup.kicker")}</Live>
                <h2 className={title}>{t("DonatePopup.title")}</h2>
            </div>
            <p className="text-[15px] leading-relaxed text-muted-foreground">{about}</p>
        </div>
        <div className="flex flex-col gap-2 sm:flex-row">
            <Link to="/sponsor" onClick={dismiss} className="btn btn-primary h-11 flex-1">
                {become}
            </Link>
            <button type="button" onClick={dismiss} className="btn btn-ghost h-11 flex-1">
                {t("DonatePopup.maybeLater")}
            </button>
        </div>
    </Dialog>;
}

# One market chip: a dot says whether it is trading now
def Chip(id: str, active: bool, trading: bool, onPick: Callable[[str], None]) -> JsxElement {
    dot = cx("size-1.5 rounded-full", "bg-up" if trading else "bg-line-strong");
    state = t("MarketSwitcher.openNow" if trading else "MarketSwitcher.closedNow");
    pick = lambda { onPick(id); };
    look = cx(CHIP, CHIP_ON if active else CHIP_OFF);
    current = "page" if active else None;
    return <button type="button" onClick={pick} aria-current={current} className={look}>
        <span className={dot} title={state} />
        {t(f"Markets.names.{id}")}
    </button>;
}

# Market chips for the dashboard: `markets` are ids (named by Markets.names.<id>), `openIds` the ones trading now
def:pub MarketSwitcher(
    markets: list[str], active: str, openIds: list[str], onPick: Callable[[str], None]
) -> JsxElement {
    chips = [
        <Chip key={id} {id} active={id == active} trading={id in openIds} {onPick} />
        for id in markets
    ];
    look = "flex gap-1.5 overflow-x-auto px-1 pb-1 [scrollbar-width:none]";
    return <nav aria-label={t("MarketSwitcher.label")} className={look}>{chips}</nav>;
}

# One stock on the watchlist, a link to its page
def Watched(w: dict[str, str], path: str) -> JsxElement {
    to = f"/stocks/{w['symbol']}";
    company = <span dir="auto" className="truncate text-[12.5px] text-faint">{w["company"]}</span>;
    look = cx("side-item h-8 font-medium", path == to and "is-active");
    return <li>
        <Link {to} title={w["company"]} className={look}>
            <span className={WATCHED}>{w["symbol"]}</span>
            {company if w["company"] != w["symbol"] else None}
        </Link>
    </li>;
}

# The stocks on the watchlist
def Watching(watchlist: list[dict[str, str]], path: str) -> JsxElement {
    if not watchlist {
        return <p className="px-2.5 text-[12.5px] text-faint">{t("Sidebar.watchingEmpty")}</p>;
    }
    return <ul className="scrollbar-hide-default flex min-h-0 flex-col gap-0.5 overflow-y-auto">
        {[<Watched key={w["symbol"]} {w} {path} /> for w in watchlist]}
    </ul>;
}

# One sponsor in the sidebar
def Partner(s: any) -> JsxElement {
    look = cx("flex h-11 items-center gap-2.5 px-3", BOXED);
    name = "truncate text-[13px] font-semibold text-muted-foreground";
    return <SponsorLink sponsor={s} title={s.name} className={look}>
        <SponsorMark sponsor={s} logoClassName="h-5 w-auto max-w-[120px]" nameClassName={name} />
        <span className="kicker ms-auto">{t("Sidebar.sponsor")}</span>
    </SponsorLink>;
}

# The sidebar's sponsors, then an invite while slots are free
def SidebarSponsors -> JsxElement {
    partners = sidebar_sponsors();
    free = SIDEBAR_SPONSOR_SLOTS - len(partners);
    slots = t("Sidebar.sponsorSlotsOpen")
        if free == SIDEBAR_SPONSOR_SLOTS
        else t("Sidebar.sponsorSlotsLeft", {"count": free});
    look = cx("group flex flex-col gap-0.5 px-3 py-2.5", BOXED);
    dot = <><span className="live-dot" /> {slots}</>;
    invite = <Link to="/sponsor#tiers" className={look}>
        <span className="kicker flex items-center gap-1.5 text-brand-ink">{dot}</span>
        <span className={PITCH}>{t("Sidebar.sponsorPitch")}</span>
    </Link>;
    return <div className="flex flex-col gap-1.5">
        {[<Partner key={s.name} {s} /> for s in partners]}
        {invite if free > 0 else None}
    </div>;
}

# Who is signed in, a link to their profile, and the way out
def Me(user: dict[str, str], path: str) -> JsxElement {
    name = user.get("name", "");
    out = t("Sidebar.signOut");
    mail = "block truncate text-[12px] text-faint rtl:text-right";
    return <div className="flex items-center gap-2.5 border-t border-line px-1 pt-3">
        <Link to="/profile" className={cx(ME, path == "/profile" and "bg-white/5")}>
            <span className={INITIAL}>{name[:1].upper() or "?"}</span>
            <span className="min-w-0 flex-1">
                <span dir="auto" className={NAMED}>{name}</span>
                <span dir="auto" className={mail}>{user.get("email", "")}</span>
            </span>
        </Link>
        <button type="button" onClick={leave} className="icon-btn" title={out} aria-label={out}>
            <LogOut />
        </button>
    </div>;
}

def SideLink(to: str, icon: any, label: str, path: str, className: str = "") -> JsxElement {
    return <Link {to} className={cx("side-item", path == to and "is-active", className)}><@icon
    /> {label}</Link>;
}

def Sidebar(user: dict[str, str], watchlist: list[dict[str, str]], path: str) -> JsxElement {
    count = <span className="num text-xs text-faint">{len(watchlist)}</span>;
    watching = cx("side-item", path == "/watchlist" and "is-active");
    starred = <span className="flex-1">{t("Sidebar.watchlist")}</span>;
    resources = [
        <SideLink key={r[0]} to={r[0]} icon={r[2]} label={t(r[1])} {path} className="h-8" />
        for r in RESOURCES
    ];
    heart = <><Heart /> {t("Sidebar.support")}</>;
    support = <button type="button" onClick={open_donate} className="side-item h-8 text-start">
        {heart}
    </button>;
    return <aside className="sidebar">
        <Link to="/dashboard" className="px-2 pt-1 pb-2" aria-label={t("Sidebar.homeAria")}>
            <Logo width={150} height={38} />
        </Link>
        <button type="button" onClick={open_search} className="side-cta">
            <Search className="size-4" strokeWidth={2.5} />
            <span className="flex-1 text-start">{t("Sidebar.searchStocks")}</span>
            <kbd className="kbd bg-on-brand/10">⌘K</kbd>
        </button>
        <nav className="flex flex-col gap-0.5">
            <SideLink to="/dashboard" icon={LayoutDashboard} label={t("Sidebar.overview")} {path} />
            <Link to="/watchlist" className={watching}><Star /> {starred}{count}</Link>
        </nav>
        <div className="flex min-h-0 flex-col gap-1">
            <p className="side-label shrink-0">{t("Sidebar.watching")}</p>
            <Watching {watchlist} {path} />
        </div>
        <div className="mt-auto flex flex-col gap-0.5">
            {resources}
            {support}
            <LanguageSwitcher />
        </div>
        <SidebarSponsors />
        <Me {user} {path} />
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

def Tab(tab: str, active: bool, onClose: Callable[[str], None]) -> JsxElement {
    icon = <@{PAGE_ICONS[tab]} /> if tab in PAGE_ICONS else None;
    label = tab_label(tab);
    shut = lambda { onClose(tab); };
    named = t("TabBar.closeTab", {"label": label});
    x = "tab-close relative z-10";
    close = <button type="button" aria-label={named} className={x} onClick={shut}><X /></button>;
    look = cx("tab", active and "is-active", tab in PINNED and "pe-4");
    text = cx("tab-label", tab.startswith("/stocks/") and "mono text-[13px]");
    return <div data-active={"" if active else None} className={look}>
        {#* Stretched link: the whole tab navigates, while the close button stays a real, focusable button *#}
        <Link to={tab} aria-current={"page" if active else None} className={STRETCHED}>
            {icon}
            <span className={text}>{label}</span>
        </Link>
        {close if tab not in PINNED else None}
    </div>;
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

    place = {"transform": f"translateX({glider[0]}px)", "width": glider[1]} if glider else None;
    curve = lambda (side: str) -> any {
        <svg className={side} viewBox="0 0 12 12"><path d={CURVE} /></svg>
    };
    menu = t("TabBar.openMenu");
    more = t("TabBar.openStock");
    hint = t("TabBar.openStockHint");
    plus = "chrome-btn -ms-2";
    return <div className="tabbar">
        <button type="button" onClick={onMenu} className="chrome-btn lg:hidden" aria-label={menu}>
            <MenuIcon />
        </button>
        <div ref={strip} className="tabs ps-3 pe-3">
            <div className={cx("tab-glider", glider and "is-ready")} style={place} aria-hidden>
                {curve("tab-glider-curve is-left")}
                <div className="tab-glider-body" />
                {curve("tab-glider-curve is-right")}
            </div>
            {[<Tab key={tab} {tab} active={tab == path} onClose={close_tab} /> for tab in tabs]}
        </div>
        <button type="button" onClick={open_search} className={plus} aria-label={more} title={hint}>
            <Plus />
        </button>
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

    # The drawer slides in from the reading side: the right in Arabic
    drawer = cx(DRAWER, "max-lg:translate-x-0" if nav_open else DRAWER_SHUT);
    shade = <div className={SHADE} onClick={lambda { nav_open = False; }} />;
    work = cx("workspace", path == "/dashboard" and "is-first-tab");
    return <div className="shell">
        <div className={drawer}><Sidebar {user} {watchlist} {path} /></div>
        {shade if nav_open else None}
        <div className="shell-container">
            <div className="app">
                <TabBar {path} onMenu={lambda { nav_open = True; }} />
                <main ref={workspace} className={work}>
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
    (src, alt) = ("/assets/icons/star.svg", t("AuthLayout.starAlt"));
    stars = [
        <img key={i} {src} {alt} width={20} height={20} className="h-4 w-4" />
        for i in range(5)
    ];
    founder = <cite
        className="auth-testimonial-author"
    >- Ravi Pratap Singh (@ravixalgorithm)</cite>;
    logo = <Logo width={140} height={35} />;
    quote = t("AuthLayout.testimonialQuote");
    role = t("AuthLayout.founderRole", {"org": "@opendevsociety"});
    return <main className="auth-layout">
        <section className="auth-left-section scrollbar-hide-default">
            <Link to="/" className="auth-logo flex items-center gap-2">{logo}</Link>
            <div className="flex-1 pb-6 lg:pb-8">{children}</div>
        </section>
        <section className="auth-right-section">
            <div className="relative z-10 lg:mt-4 lg:mb-16">
                <blockquote className="auth-blockquote">{quote}</blockquote>
                <div className="flex items-center justify-between">
                    <div>{founder}<p className="text-gray-500 max-md:text-xs">{role}</p></div>
                    <div className="flex items-center gap-0.5">{stars}</div>
                </div>
            </div>
            <div className="relative flex-1" aria-hidden>
                <div className="auth-dashboard-preview absolute top-0"><ProductPreview /></div>
            </div>
        </section>
    </main>;
}
