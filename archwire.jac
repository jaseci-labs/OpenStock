graph layers {
    layer all { *; }
}

graph spaces {
    space api: native { api.*; }
    space site: browser { entry web; pages.* | ui.*; }

    app web { run api; serve site; }
}

graph import {
    model ++> api.quotes { Quote, DailyQuote, Closes, Profile, WatchlistRow, Stock, Article, has_finnhub_quotes, has_finnhub_company_data, tradingview_exchange_for_mic, yahoo_symbol, is_yahoo_symbol, yahoo_currency }
    model ++> api.markets { Market, Pulse, Group, Clock, MarketSession, session_of }
    api.fetch ++> api.insights | api.ai | api.kit { request_json }
    insight_model ++> api.insights { SourceInsight, StockSentiment, NewsItem, TickerNews }
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
    api.account ++> ui.site { repo_stars }
    api.account ++> "pages/sign-up" { save_profile }
    ui.i18n ++> web { locale }
    ui.i18n ++> ui.kit { t, tr }
    ui.i18n ++> ui.session { t }
    ui.i18n ++> ui.forms { t, locale, message_key }
    ui.i18n ++> ui.site { tr }
    ui.i18n ++> ui.shell { t, rich, locale, set_locale, LOCALES, LOCALE_NAMES }
    ui.i18n ++> pages.layout { locale, is_rtl }
    ui.i18n ++> "pages/sign-in" | "pages/sign-up" | "pages/forgot-password" | "pages/reset-password" { t }
    ui.kit ++> web { Toasts }
    ui.kit ++> ui.forms { cx, Menu }
    ui.kit ++> ui.site { cx, Dialog }
    ui.kit ++> ui.shell { cx, Dialog, Menu, MenuItem, toast_error, toast_ok }
    ui.kit ++> pages.layout { Loading }
    ui.kit ++> pages.love { cx }
    ui.kit ++> "pages/sign-in" | "pages/sign-up" { toast_error }
    ui.kit ++> "pages/forgot-password" | "pages/reset-password" { toast_error, toast_ok }
    ui.session ++> ui.forms { auth_ways, social_sign_in }
    ui.session ++> ui.shell { leave }
    ui.session ++> pages.layout { load_user, me }
    ui.session ++> "pages/sign-in" | "pages/sign-up" | "pages/forgot-password" | "pages/reset-password" { auth_post }
    ui.forms ++> "pages/sign-in" { Field, SubmitButton, FooterLink, Branding, SocialButtons, email_problem }
    ui.forms ++> "pages/sign-up" { Field, SubmitButton, FooterLink, Branding, SocialButtons, ChoiceChips, CountrySelect, PasswordChecklist, email_problem, password_problem }
    ui.forms ++> "pages/forgot-password" { Field, SubmitButton, FooterLink, Branding, email_problem }
    ui.forms ++> "pages/reset-password" { Field, SubmitButton, FooterLink, Branding, PasswordChecklist, password_problem }
    ui.site ++> ui.shell { ACTIVE_SPONSORS, SponsorLink, SponsorMark, UpdateBanner }
    ui.site ++> pages.layout { MarketingLayout }
    ui.site ++> pages.about { PageHero, SectionHead, IconCard, REPO_URL, GOOD_FIRST_ISSUES_URL }
    ui.site ++> pages.help { PageHero, SectionHead, IconCard, REPO_URL, DISCORD_URL, CONTACT_EMAIL }
    ui.site ++> pages.terms { PageHero, SectionHead, CONTACT_EMAIL }
    ui.site ++> "pages/api-docs" { PageHero, SectionHead, IconCard, REPO_URL, LATEST_RELEASE }
    ui.site ++> pages.love { PageHero, SectionHead, SponsorLink, REPO_URL, SPONSOR_TIERS, ACTIVE_SPONSORS, PREVIOUS_SPONSORS, PREVIOUS_SUPPORTERS }
    ui.shell ++> pages.layout { AppShell, AuthLayout, SearchCommand }
}
