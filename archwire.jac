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
    api.seo ++> ui.site { repo_stats }
    api.quotes ++> ui.market { live_quotes, yahoo_daily_quotes, is_realtime }
    api.markets ++> ui.market { get_market }
    api.seo ++> pages.index | pages.sponsor { repo_stats }
    api.seo ++> pages.compare.index { guide_ld, find_ticker }
    api.seo ++> pages.s { tickers_by_sector, directory_ld }
    api.seo ++> pages.s.index { ticker_page, edgar_company }
    api.quotes ++> ui.stocks { quotes, data_mode }
    api.portfolio ++> ui.stocks {
        add_to_watchlist,
        remove_from_watchlist,
        create_alert,
        get_lists,
        add_to_list,
        create_list,
    }
    api.quotes ++> ui.shell { search_stocks }
    api.portfolio ++> pages.layout { get_watchlist }
    api.portfolio ++> ui.shell { add_to_list }
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
    include ui.kit ++> web | ui.forms | ui.shell | pages.layout | "pages/sign-in" | "pages/sign-up" | "pages/forgot-password" | "pages/reset-password" | ui.site | ui.market | pages.index | pages.love | pages.sponsor | pages.changelog | pages.compare.index | pages.s.index | pages.s | ui.stocks | pages.dashboard | pages.watchlist | pages.stocks | pages.profile;
    include model ++> api.quotes | api.markets | api.portfolio | api.jobs | ui.market | pages.index | pages.s.index | ui.stocks | ui.shell | pages.dashboard | pages.watchlist | pages.stocks;
    include insight_model ++> api.insights | pages.stocks;
    include content.tickers ++> api.seo | pages.compare.index | pages.s | pages.s.index;
    include content.comparisons ++> api.seo | pages.compare | pages.s.index | pages.compare.index;
    include content.site ++> api.seo | ui.site | pages.about | pages.help | "pages/api-docs" | pages.love | pages.index | pages.sponsor | pages.changelog;
    include rules ++> api.account | ui.forms | "pages/sign-up";
    include ui.i18n ++> web | ui.kit | ui.session | ui.forms | ui.shell | pages.layout | "pages/sign-in" | "pages/sign-up" | "pages/forgot-password" | "pages/reset-password" | ui.site | ui.market | ui.stocks | pages.dashboard | pages.watchlist | pages.stocks | pages.profile;
    include ui.session ++> ui.forms | ui.shell | pages.layout | "pages/sign-in" | "pages/sign-up" | "pages/forgot-password" | "pages/reset-password" | pages.dashboard | pages.profile;
    include ui.forms ++> "pages/sign-in" | "pages/sign-up" | "pages/forgot-password" | "pages/reset-password" | pages.profile;
    include content.sponsors ++> ui.site | ui.shell | pages.help | pages.terms | pages.love | pages.index | pages.sponsor;
    include content.changelog ++> ui.site | "pages/api-docs" | pages.changelog;
    include ui.site ++> ui.shell | pages.layout | pages.about | pages.help | pages.terms | "pages/api-docs" | pages.love | pages.index | pages.sponsor | pages.changelog | pages.compare | pages.compare.index | pages.s | pages.s.index;
    include ui.market ++> ui.shell | pages.index | pages.s.index | pages.dashboard | pages.stocks;
    include ui.shell ++> pages.layout | pages.dashboard | pages.watchlist;
    include fmt ++> ui.stocks | pages.dashboard | pages.watchlist | pages.stocks;
    include ui.stocks ++> ui.shell | pages.watchlist | pages.stocks;
    include api.fetch ++> api.insights | api.ai | api.kit | api.quotes | api.seo;
    include api.prompts ++> api.jobs;
    include api.mail ++> api.jobs;
    include api.kit ++> api.jobs;
    include api.jobs ++> api.account;
    include api.ai ++> api.jobs;
}
