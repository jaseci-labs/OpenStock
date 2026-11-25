graph layers {
    layer all { *; }
}

graph spaces {
    space api: native { api.*; }
    space site: browser { entry web; pages.* | ui.*; }

    app web { run api; serve site; }
}

graph import {
    model ++> api.quotes {
        Quote,
        DailyQuote,
        Closes,
        Profile,
        WatchlistRow,
        Stock,
        Article,
        has_finnhub_quotes,
        has_finnhub_company_data,
        tradingview_exchange_for_mic,
        yahoo_symbol,
        is_yahoo_symbol,
        yahoo_currency,
    }
    model ++> api.markets { Market, Pulse, Group, Clock, MarketSession, session_of }
    api.fetch ++> api.insights | api.ai | api.kit { request_json }
    insight_model ++> api.insights { SourceInsight, StockSentiment, NewsItem, TickerNews }
    model ++> api.portfolio {
        Quote,
        Closes,
        WatchItem,
        ListSummary,
        AlertInfo,
        Saved,
        MAX_WATCHLIST,
        MAX_LISTS,
        MAX_LIST_SYMBOLS,
        MAX_LIST_NAME,
        MAX_ACTIVE_ALERTS,
        has_finnhub_quotes,
        is_sma_period,
        sma,
        side_of,
    }
    api.quotes ++> api.portfolio { get_quote, daily_closes, is_realtime }
    model ++> api.jobs { Quote, Closes, sma, side_of, has_crossed }
    api.quotes ++> api.jobs { get_quote, daily_closes, is_realtime, get_news }
    api.portfolio ++> api.jobs { Alert, Visit }
    api.account ++> api.jobs { Profile }
    api.jobs ++> api.account { send_welcome }
    api.mail ++> api.jobs { send_welcome_email, send_alert_email, phrase, news_html }
    api.prompts ++> api.jobs { PERSONALIZED_WELCOME_EMAIL_PROMPT, NEWS_SUMMARY_EMAIL_PROMPT }
    api.ai ++> api.jobs { ask_ai }
    api.kit ++> api.jobs { add_subscriber, send_broadcast }
    content.tickers ++> api.seo {
        Ticker,
        Filing,
        EdgarCompany,
        TickerPage,
        MONTHS,
        DIRECTORY_TITLE,
        directory_description,
        ticker_path,
        sector_anchor,
        company_browse_url,
        ticker_intro,
    }
    content.comparisons ++> api.seo { GUIDES, find_guide }
    content.site ++> api.seo { RepoStats, REPO_URL, PUBLIC_EXACT_PATHS }
    rules ++> api.account { profile_problem, valid_email }
    rules ++> ui.forms { PROFILE_OPTIONS, password_checks, password_ok, valid_email }
    rules ++> "pages/sign-up" { username_for }
    api.account ++> ui.session { get_profile }
    api.account ++> "pages/sign-up" { save_profile }
    ui.i18n ++> web { locale }
    ui.i18n ++> ui.kit { t, tr }
    ui.i18n ++> ui.session { t }
    ui.i18n ++> ui.forms { t, locale, message_key }
    ui.i18n ++> ui.shell { t, rich, locale, set_locale, LOCALES, LOCALE_NAMES }
    ui.i18n ++> pages.layout { locale, is_rtl }
    ui.i18n ++> "pages/sign-in" | "pages/sign-up" | "pages/forgot-password" | "pages/reset-password" {
        t,
    }
    ui.kit ++> web { Toasts }
    ui.kit ++> ui.forms { cx, Menu }
    ui.kit ++> ui.shell { cx, Dialog, Menu, MenuItem, toast_error, toast_ok }
    ui.kit ++> pages.layout { Loading }
    ui.kit ++> "pages/sign-in" | "pages/sign-up" { toast_error }
    ui.kit ++> "pages/forgot-password" | "pages/reset-password" { toast_error, toast_ok }
    ui.session ++> ui.forms { auth_ways, social_sign_in }
    ui.session ++> ui.shell { leave }
    ui.session ++> pages.layout { load_user, me }
    ui.session ++> "pages/sign-in" | "pages/sign-up" | "pages/forgot-password" | "pages/reset-password" {
        auth_post,
    }
    ui.forms ++> "pages/sign-in" {
        Field,
        SubmitButton,
        FooterLink,
        Branding,
        SocialButtons,
        email_problem,
    }
    ui.forms ++> "pages/sign-up" {
        Field,
        SubmitButton,
        FooterLink,
        Branding,
        SocialButtons,
        ChoiceChips,
        CountrySelect,
        PasswordChecklist,
        email_problem,
        password_problem,
    }
    ui.forms ++> "pages/forgot-password" {
        Field,
        SubmitButton,
        FooterLink,
        Branding,
        email_problem,
    }
    ui.forms ++> "pages/reset-password" {
        Field,
        SubmitButton,
        FooterLink,
        Branding,
        PasswordChecklist,
        password_problem,
    }
    ui.i18n ++> ui.site | ui.market { tr }
    ui.kit ++> ui.site { cx, Dialog }
    ui.kit ++> ui.market { cx, ChangePill, PriceFlash, DataFreshness }
    ui.kit ++> pages.index | pages.love | pages.sponsor | pages.changelog | pages.compare.index | pages.s.index {
        cx,
    }
    content.site ++> ui.site { REPO_URL, DISCORD_URL, RepoStats, format_count }
    content.sponsors ++> ui.site {
        Sponsor,
        Perk,
        Tier,
        SPONSOR_TIERS,
        ACTIVE_SPONSORS,
        TIER_COLOR,
        SPONSOR_CONTACT_EMAIL,
        tier_border,
    }
    content.changelog ++> ui.site { RELEASES }
    api.seo ++> ui.site { repo_stats }
    model ++> ui.market { Market, Quote, DailyQuote, yahoo_app_symbol }
    api.quotes ++> ui.market { live_quotes, yahoo_daily_quotes, is_realtime }
    api.markets ++> ui.market { get_market }
    content.sponsors ++> ui.shell { sidebar_sponsors, SIDEBAR_SPONSOR_SLOTS }
    ui.site ++> ui.shell { SponsorLink, SponsorMark, UpdateBanner }
    ui.market ++> ui.shell { ProductPreview }
    ui.site ++> pages.layout { MarketingLayout, head }
    ui.site ++> pages.about { PageHero, SectionHead, IconCard, Go, CTA, CTA_GHOST }
    content.site ++> pages.about { REPO_URL, GOOD_FIRST_ISSUES_URL }
    ui.site ++> pages.help { PageHero, SectionHead, IconCard, Go, Faqs, CtaCard }
    content.site ++> pages.help { REPO_URL, DISCORD_URL }
    content.sponsors ++> pages.help | pages.terms { SPONSOR_CONTACT_EMAIL }
    ui.site ++> pages.terms { PageHero, SectionHead }
    ui.site ++> "pages/api-docs" { PageHero, SectionHead, IconCard, Go, rows, Band, Hatch }
    content.site ++> "pages/api-docs" { REPO_URL }
    content.changelog ++> "pages/api-docs" { RELEASES }
    ui.site ++> pages.love { PageHero, SponsorLink, Go, CTA, CTA_GHOST, rows, Band, LINK, HATCHED }
    content.site ++> pages.love { REPO_URL }
    content.sponsors ++> pages.love {
        Sponsor,
        ACTIVE_SPONSORS,
        PREVIOUS_SPONSORS,
        PREVIOUS_SUPPORTERS,
        tier_name,
    }
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
    content.site ++> pages.index {
        REPO_URL,
        DISCORD_URL,
        GOOD_FIRST_ISSUES_URL,
        RepoStats,
        format_count,
    }
    content.sponsors ++> pages.index { sidebar_sponsors }
    api.seo ++> pages.index | pages.sponsor { repo_stats }
    model ++> pages.index { session_of, PRE, OPEN, CLOSE, AFTER_END, DAY }
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
    content.site ++> pages.sponsor { DISCORD_URL, RepoStats, format_count, sponsor_checkout_url }
    content.sponsors ++> pages.sponsor {
        Sponsor,
        Tier,
        SPONSOR_TIERS,
        ACTIVE_SPONSORS,
        PREVIOUS_SPONSORS,
        PREVIOUS_SUPPORTERS,
        TIER_COLOR,
        REGISTERED_USERS,
        SPONSOR_GOAL,
        SPONSOR_GOAL_LABEL,
        SPONSOR_RECIPIENT,
        FUNDING_USES,
        tier_border,
        tier_name,
    }
    ui.site ++> pages.changelog { PageHero, SectionHead, Go, CTA, CTA_GHOST }
    content.site ++> pages.changelog { REPO_URL, GOOD_FIRST_ISSUES_URL }
    content.changelog ++> pages.changelog {
        Credit,
        Release,
        RELEASES,
        MAINTAINER,
        contributors,
        credit_label,
        credit_title,
    }
    ui.site ++> pages.compare { PageHero }
    content.comparisons ++> pages.compare | pages.s.index { GUIDES }
    ui.site ++> pages.compare.index { PageHero, Faqs, CtaCard, NotFound, head, CTA, CTA_GHOST }
    content.comparisons ++> pages.compare.index { GUIDES, find_guide }
    content.tickers ++> pages.compare.index { Ticker, ticker_path }
    api.seo ++> pages.compare.index { guide_ld, find_ticker }
    ui.site ++> pages.s { PageHero, head, use_anchor, CTA, CTA_GHOST }
    content.tickers ++> pages.s {
        Ticker,
        DIRECTORY_TITLE,
        directory_description,
        ticker_path,
        sector_anchor,
    }
    api.seo ++> pages.s { tickers_by_sector, directory_ld }
    ui.site ++> pages.s.index { Go, Faqs, CtaCard, NotFound, head, CTA, CTA_GHOST }
    ui.market ++> pages.s.index { TradingView, symbol_info, candle_chart }
    content.tickers ++> pages.s.index {
        Filing,
        EdgarCompany,
        TickerPage,
        ticker_path,
        sector_anchor,
        company_browse_url,
        format_filing_date,
    }
    model ++> pages.s.index { tradingview_symbol, tradingview_symbol_url }
    api.seo ++> pages.s.index { ticker_page, edgar_company }
    ui.shell ++> pages.layout { AppShell, AuthLayout, SearchCommand }
    fmt ++> ui.stocks { money, signed, poll_ms }
    model ++> ui.stocks {
        Quote,
        ListSummary,
        AlertInfo,
        MAX_WATCHLIST,
        MAX_LISTS,
        MAX_LIST_SYMBOLS,
        SMA_PERIODS,
    }
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
    model ++> ui.shell { Stock }
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
        NAME_INPUT,
    }
    ui.stocks ++> pages.stocks { use_live, Empty, WatchButton, AlertButton, ListButton, ago }
    fmt ++> pages.dashboard { grouped }
    fmt ++> pages.watchlist | pages.stocks { money, signed, compact }
    model ++> pages.dashboard { Market, DailyQuote, yahoo_app_symbol }
    model ++> pages.watchlist {
        Quote,
        WatchlistRow,
        Article,
        WatchItem,
        ListSummary,
        AlertInfo,
        Saved,
        has_finnhub_quotes,
    }
    model ++> pages.stocks {
        Quote,
        DailyQuote,
        Profile,
        tradingview_symbol,
        is_chart_embeddable,
        tradingview_symbol_url,
        qualify_tradingview_symbol,
        has_finnhub_quotes,
        has_finnhub_company_data,
        is_yahoo_symbol,
    }
    insight_model ++> pages.stocks { StockSentiment, TickerNews, alphai_stock_url }
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
}
