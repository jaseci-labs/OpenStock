graph layers {
    layer all { *; }
}

graph spaces {
    space api: native { api.*; }
    space site: browser { entry web; pages.* | ui.*; }

    app web { run api; serve site; }
}

graph import {
    api.quotes ++> api.portfolio { get_quote, daily_closes, is_realtime }
    api.quotes ++> api.jobs { get_quote, daily_closes, is_realtime, get_news }
    api.portfolio ++> api.jobs { Alert, Visit }
    api.account ++> api.jobs { Profile }
    api.account ++> ui.session { get_profile }
    api.account ++> "pages/sign-up" { save_profile }
    ui.i18n ++> web { locale }
    ui.i18n ++> ui.kit { t, tr }
    ui.i18n ++> ui.session { t }
    ui.i18n ++> ui.forms { t, locale, message_key }
    ui.i18n ++> ui.shell { t, rich, locale, set_locale, LOCALES, LOCALE_NAMES }
    ui.i18n ++> pages.layout { locale }
    ui.i18n ++> "pages/sign-in" | "pages/sign-up" | "pages/forgot-password" | "pages/reset-password" {
        t,
    }
    ui.kit ++> web { Toasts, listen }
    ui.kit ++> ui.forms { cx, Menu }
    ui.kit ++> ui.shell { cx, listen, Dialog, Menu, MenuItem, toast_error, toast_ok }
    ui.kit ++> pages.layout { Loading, listen }
    ui.kit ++> "pages/sign-in" | "pages/sign-up" { toast_error }
    ui.kit ++> "pages/forgot-password" | "pages/reset-password" { toast_error, toast_ok }
    ui.session ++> ui.forms { auth_ways, social_sign_in }
    ui.session ++> ui.shell { leave }
    ui.session ++> pages.layout { load_user, me }
    ui.session ++> "pages/sign-in" | "pages/sign-up" | "pages/forgot-password" | "pages/reset-password" {
        auth_post,
    }
    ui.forms ++> "pages/sign-in" | "pages/sign-up" | "pages/forgot-password" | "pages/reset-password" {
        AuthHead,
    }
    ui.forms ++> "pages/sign-in" | "pages/forgot-password" | "pages/reset-password" { AuthEnd }
    ui.forms ++> "pages/sign-in" | "pages/sign-up" | "pages/forgot-password" { EmailField }
    ui.forms ++> "pages/sign-in" | "pages/forgot-password" { email_problem }
    ui.forms ++> "pages/sign-in" | "pages/sign-up" | "pages/reset-password" { Field }
    ui.forms ++> "pages/sign-in" | "pages/sign-up" { SocialButtons }
    ui.forms ++> "pages/sign-up" | "pages/reset-password" { PasswordChecklist, password_problem }
    ui.forms ++> "pages/sign-up" {
        SubmitButton,
        FooterLink,
        Branding,
        ChoiceChips,
        CountrySelect,
        email_problem,
    }
    ui.i18n ++> ui.site | ui.market { tr }
    ui.kit ++> ui.site { cx, Dialog }
    ui.kit ++> ui.market { cx, ChangePill, PriceFlash, DataFreshness }
    ui.kit ++> pages.index | pages.love | pages.sponsor | pages.changelog | pages.compare.index | pages.s.index | pages.s {
        cx,
    }
    api.seo ++> ui.site { repo_stats }
    api.quotes ++> ui.market { live_quotes, yahoo_daily_quotes, is_realtime }
    api.markets ++> ui.market { get_market }
    ui.site ++> ui.shell { SponsorLink, SponsorMark, UpdateBanner, Live, Logo }
    ui.market ++> ui.shell { ProductPreview }
    ui.site ++> pages.layout { MarketingLayout, head }
    ui.site ++> pages.about { PageHero, IconCard, Go, CTA, CTA_GHOST, rows, Band, Hatch }
    ui.site ++> pages.help { PageHero, IconCard, Go, Faqs, CtaCard, rows, Band }
    ui.site ++> pages.terms { PageHero, Band, Hatch, LINK }
    ui.site ++> "pages/api-docs" { PageHero, SectionHead, IconCard, Go, rows, Band, Hatch }
    ui.site ++> pages.love { PageHero, SponsorLink, Go, CTA, CTA_GHOST, rows, Band, LINK, HATCHED }
    ui.site ++> pages.index {
        SectionHead,
        IconCard,
        SponsorLink,
        Go,
        CTA,
        CTA_GHOST,
        MUTED,
        use_anchor,
        rows,
        Band,
        Hatch,
        Live,
    }
    ui.market ++> pages.index { ProductPreview }
    api.seo ++> pages.index | pages.sponsor { repo_stats }
    ui.site ++> pages.sponsor {
        IconCard,
        SponsorLink,
        SponsorMark,
        Go,
        CTA,
        CTA_GHOST,
        MAILTO,
        use_anchor,
        rows,
        Hatch,
        Live,
        MUTED,
        LINK,
    }
    ui.site ++> pages.changelog { PageHero, Go, CTA, CTA_GHOST, Band, Hatch, LINK }
    ui.site ++> pages.compare { PageHero, Band }
    ui.site ++> pages.compare.index { PageHero, Faqs, CtaCard, NotFound, head, CTA, CTA_GHOST }
    api.seo ++> pages.compare.index { guide_ld, find_ticker }
    ui.site ++> pages.s { PageHero, head, use_anchor, CTA, CTA_GHOST, WIDE }
    api.seo ++> pages.s { tickers_by_sector, directory_ld }
    ui.site ++> pages.s.index { Go, Faqs, CtaCard, NotFound, head, CTA, CTA_GHOST, Hatch }
    ui.market ++> pages.s.index { TradingView, symbol_info, candle_chart }
    api.seo ++> pages.s.index { ticker_page, edgar_company }
    ui.shell ++> pages.layout { AppShell, AuthLayout, SearchCommand }
    api.quotes ++> ui.stocks { quotes, data_mode }
    api.portfolio ++> ui.stocks {
        add_to_watchlist,
        remove_from_watchlist,
        create_alert,
        get_lists,
        add_to_list,
        create_list,
    }
    ui.i18n ++> ui.stocks { t, locale }
    ui.kit ++> ui.stocks { cx, Dialog, toast_error, toast_ok }
    ui.i18n ++> "pages/sign-up" { locale }
    api.quotes ++> ui.shell { search_stocks }
    api.portfolio ++> pages.layout { get_watchlist }
    api.portfolio ++> ui.shell { add_to_list }
    ui.stocks ++> ui.shell { problem, changed }
    ui.i18n ++> pages.dashboard | pages.watchlist | pages.stocks { t, locale }
    ui.i18n ++> pages.profile { t }
    ui.i18n ++> pages.dashboard | pages.stocks { message_key }
    ui.i18n ++> pages.watchlist | pages.stocks { rich }
    ui.kit ++> pages.dashboard { cx, Panel, ChangePill, DataFreshness, Loading }
    ui.kit ++> pages.watchlist {
        cx,
        Panel,
        ChangePill,
        PriceFlash,
        DataFreshness,
        Loading,
        toast_error,
        toast_ok,
    }
    ui.kit ++> pages.stocks { cx, Panel, Menu, MenuItem, ChangePill, PriceFlash, DataFreshness }
    ui.kit ++> pages.profile { Panel, toast_error, toast_ok }
    ui.session ++> pages.dashboard { me }
    ui.session ++> pages.profile { me, load_user, auth_post }
    ui.forms ++> pages.profile { Field, SubmitButton, ChoiceChips, CountrySelect }
    ui.shell ++> pages.dashboard { MarketSwitcher }
    ui.shell ++> pages.watchlist { open_search, open_search_for_list }
    ui.market ++> pages.dashboard { TradingView, IndexPulse, widget_config }
    ui.market ++> pages.stocks { TradingView, symbol_info, candle_chart, widget_config }
    ui.stocks ++> pages.watchlist {
        use_live,
        Empty,
        WatchButton,
        AlertButton,
        ListButton,
        problem,
        changed,
        ago,
        quiet,
        NAME_INPUT,
    }
    ui.stocks ++> pages.stocks { use_live, Empty, WatchButton, AlertButton, ListButton, ago, quiet }
    api.markets ++> pages.dashboard { markets, open_markets, market_for_country }
    api.quotes ++> pages.dashboard { yahoo_daily_quotes, is_realtime }
    api.quotes ++> pages.watchlist { get_watchlist_data, get_news }
    api.quotes ++> pages.stocks {
        get_company_profile,
        get_stock_metrics,
        get_tradingview_exchange,
        yahoo_daily_quotes,
    }
    api.quotes ++> pages.profile { is_realtime }
    api.insights ++> pages.stocks { get_stock_sentiment, get_alphai_news }
    api.portfolio ++> pages.watchlist {
        get_watchlist,
        get_lists,
        get_alerts,
        create_list,
        delete_list,
        remove_from_list,
        delete_alert,
    }
    api.portfolio ++> pages.stocks { in_watchlist }
    api.portfolio ++> pages.profile { get_watchlist, get_alerts }
    api.account ++> pages.profile { update_profile }
    include model ++> api.quotes | api.markets | api.portfolio | api.jobs | ui.market | pages.index | pages.s.index | ui.stocks | ui.shell | pages.dashboard | pages.watchlist | pages.stocks;
    include api.fetch ++> api.insights | api.ai | api.kit | api.quotes | api.seo;
    include insight_model ++> api.insights | pages.stocks;
    include api.jobs ++> api.account;
    include api.mail ++> api.jobs;
    include api.prompts ++> api.jobs;
    include api.ai ++> api.jobs;
    include api.kit ++> api.jobs;
    include content.tickers ++> api.seo | pages.compare.index | pages.s | pages.s.index;
    include content.comparisons ++> api.seo | pages.compare | pages.s.index | pages.compare.index;
    include content.site ++> api.seo | ui.site | pages.about | pages.help | "pages/api-docs" | pages.love | pages.index | pages.sponsor | pages.changelog;
    include rules ++> api.account | ui.forms | "pages/sign-up";
    include content.sponsors ++> ui.site | ui.shell | pages.help | pages.terms | pages.love | pages.index | pages.sponsor;
    include content.changelog ++> ui.site | "pages/api-docs" | pages.changelog;
    include fmt ++> ui.stocks | pages.dashboard | pages.watchlist | pages.stocks;
}
