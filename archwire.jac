graph layers {
    layer all { *; }
}

graph spaces {
    space Openstock: browser { "."; }
    space Openstock_dev: node {
        "eslint.config";
        "next.config";
        "postcss.config";
        "vite.config";
        "vitest.config";
        __tests__.*
            | app.*
            | database.*
            | i18n.*
            | lib.*
            | types.*
            | components.*
            | hooks.*
            | middleware
            | scripts.*;
    }
}

graph import {
    "lib/actions/adanos.actions" --> "__tests__/adanos.actions.test" { getStockSentimentInsights }
    "lib/actions/adanos.helpers" --> "__tests__/adanos.actions.test" {
        buildStockSentimentInsights,
        getSourceAlignment,
        normalizeSourceInsight,
    }
    "lib/actions/adanos.helpers" --> "lib/actions/adanos.actions" {
        SOURCE_CONFIG,
        SentimentSourceInsight,
        SentimentSourceKey,
        SourceComparePayload,
        StockSentimentInsights,
        buildStockSentimentInsights,
        normalizeSourceInsight,
    }
    "lib/ai-provider" --> "__tests__/ai-provider.integration.test" { callAIProvider }
    "lib/ai-provider" --> "__tests__/ai-provider.test" {
        callAIProvider,
        callAIProviderWithFallback,
        getFallbackProviderName,
        getProviderConfig,
    }
    "lib/actions/alert.actions" --> "__tests__/alert-actions.test" { createAlert, deleteAlert }
    database.mongoose --> "lib/actions/alert.actions" { connectToDatabase }
    "database/models/alert.model" --> "lib/actions/alert.actions" { alertModel }
    "lib/better-auth/auth" --> "lib/actions/alert.actions" { requireUserId, requireUserIdForRead }
    lib.markets --> "lib/actions/alert.actions" { hasFinnhubQuotes }
    "lib/market-data" --> "lib/actions/alert.actions" { alertsEnabled }
    lib.sma --> "lib/actions/alert.actions" { getDailyCloses, isSmaPeriod, sideOf, sma }
    "lib/actions/finnhub.actions" --> "lib/actions/alert.actions" { getQuote }
    "database/request-connection" --> "database/models/alert.model" { DbHandle, modelOn }
    lib.sma --> "database/models/alert.model" { SMA_PERIODS }
    database.mongoose --> "database/request-connection" { isWorkersRuntime }
    database.mongoose --> "lib/better-auth/auth" { connectToDatabase, isWorkersRuntime }
    "lib/nodemailer/reset-password" --> "lib/better-auth/auth" { sendPasswordResetEmail }
    i18n.locale --> "lib/better-auth/auth" { resolveLocale }
    lib.nodemailer.index --> "lib/nodemailer/reset-password" { transporter }
    lib.utils --> "lib/nodemailer/reset-password" { escapeHtml }
    lib.nodemailer.i18n --> "lib/nodemailer/reset-password" { getEmailTranslator }
    lib.nodemailer.templates --> lib.nodemailer.index {
        STOCK_ALERT_LOWER_EMAIL_TEMPLATE,
        STOCK_ALERT_UPPER_EMAIL_TEMPLATE,
        WELCOME_EMAIL_TEMPLATE,
    }
    lib.utils --> lib.nodemailer.index { formatPrice, sanitizeEmailIntro }
    lib.nodemailer.i18n --> lib.nodemailer.index { escapeAll, fillTemplate, getEmailTranslator }
    database.mongoose --> lib.nodemailer.index { isWorkersRuntime }
    i18n.config --> lib.nodemailer.i18n { DEFAULT_LOCALE, Locale, isLocale }
    lib.utils --> lib.nodemailer.i18n { escapeHtml }
    i18n.config --> i18n.locale { DEFAULT_LOCALE, LOCALE_COOKIE, Locale, isLocale }
    lib.utils --> lib.markets { isInternationalSymbol }
    lib.utils --> "lib/actions/finnhub.actions" {
        formatArticle,
        getDateRange,
        tradingViewExchangeForMic,
        validateArticle,
    }
    lib.constants --> "lib/actions/finnhub.actions" { POPULAR_STOCKS }
    "lib/market-data" --> "lib/actions/finnhub.actions" { QUOTE_TTL_SECONDS }
    lib.markets --> "lib/actions/finnhub.actions" { hasFinnhubCompanyData, hasFinnhubQuotes }
    "lib/actions/yahoo.actions" --> "lib/actions/finnhub.actions" { getYahooDailyQuotes }
    lib.yahoo --> "lib/actions/finnhub.actions" { isYahooSymbol }
    "lib/better-auth/auth" --> "lib/actions/finnhub.actions" { getSession }
    i18n.config --> lib.constants { Locale }
    "lib/market-data" --> "lib/actions/yahoo.actions" { QUOTE_TTL_SECONDS }
    lib.yahoo --> "lib/actions/yahoo.actions" {
        YahooDailyQuote,
        dailyQuoteFromChart,
        normalizeYahooSymbol,
        yahooCurrency,
    }
    lib.inngest.functions --> "__tests__/alert-checker.test" { checkStockAlertsHandler }
    lib.inngest.client --> lib.inngest.functions { inngest }
    lib.inngest.prompts --> lib.inngest.functions {
        NEWS_SUMMARY_EMAIL_PROMPT,
        PERSONALIZED_WELCOME_EMAIL_PROMPT,
    }
    lib.nodemailer.index --> lib.inngest.functions { sendStockAlertEmail, sendWelcomeEmail }
    "lib/ai-provider" --> lib.inngest.functions { callAIProviderWithFallback }
    lib.nodemailer.i18n --> lib.inngest.functions { getEmailTranslator }
    "lib/actions/finnhub.actions" --> lib.inngest.functions;
    lib.kit --> lib.inngest.functions;
    lib.utils --> lib.inngest.functions;
    database.mongoose --> lib.inngest.functions;
    "database/models/alert.model" --> lib.inngest.functions;
    lib.sma --> lib.inngest.functions;
    "lib/actions/alphai.actions" --> "__tests__/alphai.actions.test" { getAlphaiTickerNews }
    "lib/actions/alphai.helpers" --> "__tests__/alphai.actions.test" {
        alphaiStockUrl,
        isAlphaiSymbol,
        normalizeAlphaiNews,
    }
    "lib/actions/alphai.helpers" --> "lib/actions/alphai.actions" {
        ALPHAI_MAX_ITEMS,
        ALPHAI_MIN_RELEVANCE,
        AlphaiTickerNews,
        isAlphaiSymbol,
        normalizeAlphaiNews,
    }
    "lib/better-auth/auth" --> "__tests__/auth.test";
    "lib/nodemailer/reset-password" --> "__tests__/auth.test";
    lib.kit --> "__tests__/kit.test" { kit }
    "lib/market-session" --> "__tests__/market-clock.test" { formatSpan, sessionOf }
    lib.markets --> "__tests__/market-clock.test" {
        getMarket,
        hasFinnhubCompanyData,
        hasFinnhubQuotes,
        isMarketOpen,
    }
    i18n.config --> "__tests__/messages.test" { LOCALES, localeDir }
    database.mongoose --> "__tests__/mongoose-workers.test";
    "database/request-connection" --> "__tests__/mongoose-workers.test";
    middleware --> "__tests__/public-seo.test" { config, middleware }
    "lib/public-paths" --> "__tests__/public-seo.test" { PUBLIC_EXACT_PATHS, isPublicPath }
    lib.seo.comparisons --> "__tests__/public-seo.test" { GUIDES, findGuide }
    lib.seo.edgar --> "__tests__/public-seo.test" {
        filingUrl,
        formatFilingDate,
        formatFiscalYearEnd,
        parseSubmissions,
        stateName,
    }
    lib.seo.sitemap --> "__tests__/public-seo.test" { sitemapEntries }
    lib.seo.site --> "__tests__/public-seo.test" { siteUrl }
    lib.seo.tickers --> "__tests__/public-seo.test" {
        US_TICKERS,
        adjacentTickers,
        findTicker,
        relatedTickers,
        tickerIntro,
        tickerPath,
    }
    "lib/public-paths" --> middleware { isPublicPath }
    "lib/public-paths" --> lib.seo.sitemap { PUBLIC_EXACT_PATHS }
    lib.seo.comparisons --> lib.seo.sitemap { GUIDES }
    lib.seo.tickers --> lib.seo.sitemap { US_TICKERS, tickerPath }
    "lib/rate-limit" --> "__tests__/rate-limit.test" {
        NO_IP_BUDGET_FACTOR,
        clientIp,
        isClientRateLimited,
        signUpLimitPerIp,
    }
    database.mongoose --> "lib/rate-limit" { connectToDatabase, isWorkersRuntime }
    lib.nodemailer.index --> "__tests__/reset-password-email.test" { transporter }
    "lib/nodemailer/reset-password" --> "__tests__/reset-password-email.test" {
        sendPasswordResetEmail,
    }
    lib.sma --> "__tests__/sma.test" {
        closesFromChart,
        getDailyCloses,
        hasCrossed,
        isSmaPeriod,
        sideOf,
        sma,
        yahooChartSymbol,
    }
    hooks.useLiveQuotes --> "__tests__/use-live-quotes.test" { useLiveQuotes }
    app.api.quotes.route --> "__tests__/use-live-quotes.test" { GET }
    "lib/market-data" --> hooks.useLiveQuotes { isRealtime }
    "lib/better-auth/auth" --> app.api.quotes.route { getSession }
    "lib/actions/finnhub.actions" --> app.api.quotes.route { getLiveQuotes }
    "lib/rate-limit" --> app.api.quotes.route { isRateLimited }
    "lib/watchlist-lists" --> app.api.quotes.route { MAX_LIST_SYMBOLS }
    lib.utils --> "__tests__/utils.test" {
        calculateNewsDistribution,
        formatChangePercent,
        formatMarketCapValue,
        formatNumber,
        formatPrice,
        formatSymbolForTradingView,
        getChangeColorClass,
        isChartEmbeddable,
        qualifyTradingViewSymbol,
        tradingViewExchangeForMic,
    }
    "lib/actions/watchlist-lists.actions" --> "__tests__/watchlist-list-actions.test" {
        WatchlistListSummary,
        addSymbolToList,
        createWatchlistList,
        removeSymbolFromList,
    }
    "lib/watchlist-lists" --> "__tests__/watchlist-list-actions.test" {
        MAX_LISTS,
        MAX_LIST_SYMBOLS,
    }
    database.mongoose --> "lib/actions/watchlist-lists.actions" { connectToDatabase }
    "database/models/watchlist-list.model" --> "lib/actions/watchlist-lists.actions" {
        watchlistListModel,
    }
    "lib/better-auth/auth" --> "lib/actions/watchlist-lists.actions" {
        requireUserId,
        requireUserIdForRead,
    }
    "lib/watchlist-lists" --> "lib/actions/watchlist-lists.actions" {
        MAX_LISTS,
        MAX_LIST_SYMBOLS,
        canAddList,
        normalizeCompany,
        normalizeListName,
        normalizeSymbol,
    }
    i18n.errors --> "lib/actions/watchlist-lists.actions" { getErrorTranslator }
    "lib/watchlist-lists" --> "database/models/watchlist-list.model" { MAX_LIST_NAME }
    "database/request-connection" --> "database/models/watchlist-list.model" { DbHandle, modelOn }
    "lib/watchlist-lists" --> "__tests__/watchlist-lists.test" {
        ListSymbol,
        MAX_LISTS,
        MAX_LIST_SYMBOLS,
        addSymbol,
        canAddList,
        canAddSymbol,
        normalizeCompany,
        normalizeListName,
        normalizeSymbol,
        removeSymbol,
    }
    lib.nodemailer.index --> "__tests__/welcome-email.test";
    lib.yahoo --> "__tests__/yahoo.test" {
        dailyQuoteFromChart,
        normalizeYahooSymbol,
        yahooAppSymbol,
        yahooCurrency,
    }
    lib.utils --> "__tests__/yahoo.test" { formatSymbolForTradingView, isChartEmbeddable }
    "lib/better-auth/auth" --> "app/api/auth/[...all]/route" { auth }
    "database/request-connection" --> "database/models/watchlist.model" { DbHandle, modelOn }
    i18n.config --> "i18n/types.d" { Locale }
    "lib/better-auth/auth" --> "lib/actions/auth.actions" { auth }
    lib.inngest.client --> "lib/actions/auth.actions" { inngest }
    lib.constants --> "lib/actions/auth.actions" {
        INVESTMENT_GOALS,
        PREFERRED_INDUSTRIES,
        RISK_TOLERANCE_OPTIONS,
    }
    "lib/rate-limit" --> "lib/actions/auth.actions" {
        isClientRateLimited,
        isRateLimited,
        signUpLimitPerIp,
    }
    i18n.locale --> "lib/actions/auth.actions" { resolveLocale }
    database.mongoose --> "lib/actions/auth.actions";
    i18n.config --> "lib/actions/locale.actions" { LOCALE_COOKIE, isLocale }
    "lib/better-auth/auth" --> "lib/actions/profile.actions" { auth }
    lib.constants --> "lib/actions/profile.actions" {
        INVESTMENT_GOALS,
        PREFERRED_INDUSTRIES,
        RISK_TOLERANCE_OPTIONS,
    }
    database.mongoose --> "lib/actions/watchlist.actions" { connectToDatabase }
    "database/models/watchlist.model" --> "lib/actions/watchlist.actions" { watchlistModel }
    "lib/better-auth/auth" --> "lib/actions/watchlist.actions" {
        requireUserId,
        requireUserIdForRead,
    }
    components.ui.button --> "app/(auth)/forgot-password/page" { Button }
    components.forms.InputField --> "app/(auth)/forgot-password/page" { default }
    components.forms.FooterLink --> "app/(auth)/forgot-password/page" { default }
    components.OpenDevSocietyBranding --> "app/(auth)/forgot-password/page" { default }
    "lib/actions/auth.actions" --> "app/(auth)/forgot-password/page" { requestPasswordResetEmail }
    lib.utils --> components.ui.button { cn }
    components.ui.label --> components.forms.InputField { Label }
    components.ui.input --> components.forms.InputField { Input }
    lib.utils --> components.forms.InputField { cn }
    lib.utils --> components.ui.label { cn }
    lib.utils --> components.ui.input { cn }
    components.HtmlLang --> "app/(auth)/layout" { default }
    "lib/better-auth/auth" --> "app/(auth)/layout" { getSession }
    components.landing.ProductPreview --> "app/(auth)/layout" { default }
    components.forms.SocialAuthButtons --> "app/(auth)/layout" { SocialProvidersProvider }
    i18n.config --> components.HtmlLang { localeDir }
    components.IndexPulse --> components.landing.ProductPreview { PulseSkeleton, default }
    components.DataFreshness --> components.landing.ProductPreview { default }
    components.TradingViewWidget --> components.landing.ProductPreview { default }
    lib.utils --> components.landing.ProductPreview { cn }
    components.PulseTile --> components.IndexPulse { LocalizedPulseTile, default }
    components.YahooPulseTile --> components.IndexPulse { default }
    components.TradingViewWidget --> components.IndexPulse { default }
    "lib/actions/finnhub.actions" --> components.IndexPulse { getLiveQuotes }
    "lib/actions/yahoo.actions" --> components.IndexPulse { getYahooDailyQuotes }
    lib.constants --> components.IndexPulse { singleQuoteConfig }
    lib.markets --> components.IndexPulse { Market, getMarket }
    i18n.config --> components.IndexPulse { Locale }
    components.ChangePill --> components.PulseTile { default }
    components.PriceFlash --> components.PulseTile { default }
    hooks.useLiveQuotes --> components.PulseTile { LiveQuote, useLiveQuotes }
    lib.utils --> components.PriceFlash { cn }
    components.ChangePill --> components.YahooPulseTile { default }
    lib.yahoo --> components.YahooPulseTile { YahooDailyQuote, yahooAppSymbol }
    hooks.useTradingViewWidget --> components.TradingViewWidget { default }
    lib.utils --> components.TradingViewWidget { cn }
    "lib/market-data" --> components.DataFreshness { isRealtime }
    components.ui.button --> components.forms.SocialAuthButtons { Button }
    "lib/actions/auth.actions" --> components.forms.SocialAuthButtons { signInWithSocial }
    components.forms.FooterLink --> "app/(auth)/reset-password/ResetPasswordForm" { default }
    components.forms.InputField --> "app/(auth)/reset-password/ResetPasswordForm" { default }
    components.forms.PasswordRequirements --> "app/(auth)/reset-password/ResetPasswordForm" {
        default,
    }
    components.OpenDevSocietyBranding --> "app/(auth)/reset-password/ResetPasswordForm" { default }
    components.ui.button --> "app/(auth)/reset-password/ResetPasswordForm" { Button }
    "lib/actions/auth.actions" --> "app/(auth)/reset-password/ResetPasswordForm" {
        resetPasswordWithToken,
    }
    lib.constants --> "app/(auth)/reset-password/ResetPasswordForm" { passwordValidation }
    lib.constants --> components.forms.PasswordRequirements { PASSWORD_RULES }
    lib.utils --> components.forms.PasswordRequirements { cn }
    "app/(auth)/reset-password/ResetPasswordForm" --> "app/(auth)/reset-password/page" { default }
    components.ui.button --> "app/(auth)/sign-in/page" { Button }
    components.forms.InputField --> "app/(auth)/sign-in/page" { default }
    components.forms.FooterLink --> "app/(auth)/sign-in/page" { default }
    "lib/actions/auth.actions" --> "app/(auth)/sign-in/page" { signInWithEmail }
    components.OpenDevSocietyBranding --> "app/(auth)/sign-in/page" { default }
    components.forms.SocialAuthButtons --> "app/(auth)/sign-in/page" { default }
    components.ui.button --> "app/(auth)/sign-up/page" { Button }
    components.forms.InputField --> "app/(auth)/sign-up/page" { default }
    components.forms.ChoiceChips --> "app/(auth)/sign-up/page" { default }
    components.forms.PasswordRequirements --> "app/(auth)/sign-up/page" { default }
    lib.constants --> "app/(auth)/sign-up/page" {
        INVESTMENT_GOALS,
        PREFERRED_INDUSTRIES,
        RISK_TOLERANCE_OPTIONS,
        passwordValidation,
    }
    components.forms.CountrySelectField --> "app/(auth)/sign-up/page" { CountrySelectField }
    components.forms.FooterLink --> "app/(auth)/sign-up/page" { default }
    "lib/actions/auth.actions" --> "app/(auth)/sign-up/page" { signUpWithEmail }
    components.OpenDevSocietyBranding --> "app/(auth)/sign-up/page" { default }
    components.forms.SocialAuthButtons --> "app/(auth)/sign-up/page" { default }
    lib.utils --> components.forms.ChoiceChips { cn }
    i18n.config --> components.forms.ChoiceChips { toMessageKey }
    components.ui.popover --> components.forms.CountrySelectField {
        Popover,
        PopoverContent,
        PopoverTrigger,
    }
    components.ui.command --> components.forms.CountrySelectField {
        Command,
        CommandEmpty,
        CommandGroup,
        CommandInput,
        CommandItem,
        CommandList,
    }
    components.ui.button --> components.forms.CountrySelectField { Button }
    components.ui.label --> components.forms.CountrySelectField { Label }
    lib.utils --> components.forms.CountrySelectField { cn }
    lib.utils --> components.ui.popover { cn }
    lib.utils --> components.ui.command { cn }
    components.ui.dialog --> components.ui.command {
        Dialog,
        DialogContent,
        DialogDescription,
        DialogHeader,
        DialogTitle,
    }
    lib.utils --> components.ui.dialog { cn }
    components.marketing.PageHero --> "app/(marketing)/about/page" { default }
    components.marketing.SectionHead --> "app/(marketing)/about/page" { default }
    components.marketing.IconCard --> "app/(marketing)/about/page" { default }
    lib.constants --> "app/(marketing)/about/page" { GOOD_FIRST_ISSUES_URL, REPO_URL }
    components.marketing.PageHero --> "app/(marketing)/api-docs/page" { default }
    components.marketing.SectionHead --> "app/(marketing)/api-docs/page" { default }
    components.marketing.IconCard --> "app/(marketing)/api-docs/page" { default }
    lib.constants --> "app/(marketing)/api-docs/page" { REPO_URL }
    lib.changelog --> "app/(marketing)/api-docs/page" { LATEST_RELEASE }
    components.marketing.PageHero --> "app/(marketing)/changelog/page" { default }
    components.marketing.SectionHead --> "app/(marketing)/changelog/page" { default }
    lib.constants --> "app/(marketing)/changelog/page" { GOOD_FIRST_ISSUES_URL, REPO_URL }
    lib.changelog --> "app/(marketing)/changelog/page" { Credit, MAINTAINER, RELEASES }
    lib.utils --> "app/(marketing)/changelog/page" { cn }
    components.marketing.PageHero --> "app/(marketing)/compare/[slug]/page" { default }
    components.seo.JsonLd --> "app/(marketing)/compare/[slug]/page" { default }
    components.seo.SignUpCta --> "app/(marketing)/compare/[slug]/page" { default }
    lib.seo.comparisons --> "app/(marketing)/compare/[slug]/page" { GUIDES, findGuide }
    lib.seo.site --> "app/(marketing)/compare/[slug]/page" { siteUrl }
    lib.seo.tickers --> "app/(marketing)/compare/[slug]/page" { findTicker, tickerPath }
    components.marketing.PageHero --> "app/(marketing)/compare/page" { default }
    lib.seo.comparisons --> "app/(marketing)/compare/page" { GUIDES }
    lib.seo.site --> "app/(marketing)/compare/page" { siteUrl }
    components.marketing.PageHero --> "app/(marketing)/help/page" { default }
    components.marketing.SectionHead --> "app/(marketing)/help/page" { default }
    components.marketing.IconCard --> "app/(marketing)/help/page" { default }
    lib.constants --> "app/(marketing)/help/page" { DISCORD_URL, REPO_URL }
    lib.github --> "app/(marketing)/layout" { formatCount, getRepoStats }
    components.marketing.SiteFooter --> "app/(marketing)/layout" { default }
    components.UpdateBanner --> "app/(marketing)/layout" { default }
    lib.constants --> "app/(marketing)/layout" { REPO_URL }
    components.sponsors.SponsorsBand --> components.marketing.SiteFooter { default }
    lib.constants --> components.marketing.SiteFooter { DISCORD_URL, REPO_URL }
    lib.sponsors --> components.sponsors.SponsorsBand {
        ACTIVE_SPONSORS,
        SPONSOR_CONTACT_EMAIL,
        SPONSOR_TIERS,
        Sponsor,
        SponsorTierId,
        TIER_COLOR,
        tierBorder,
    }
    components.sponsors.SponsorLink --> components.sponsors.SponsorsBand { default }
    lib.utils --> components.sponsors.SponsorsBand { cn }
    lib.sponsors --> components.sponsors.SponsorLink { Sponsor }
    components.sponsors.SponsorPerkModal --> components.sponsors.SponsorLink { default }
    components.ui.dialog --> components.sponsors.SponsorPerkModal {
        Dialog,
        DialogContent,
        DialogDescription,
        DialogTitle,
    }
    lib.sponsors --> components.sponsors.SponsorPerkModal { Sponsor }
    components.ui.dialog --> components.UpdateBanner {
        Dialog,
        DialogClose,
        DialogContent,
        DialogDescription,
        DialogTitle,
        DialogTrigger,
    }
    lib.changelog --> components.UpdateBanner { LATEST_RELEASE }
    lib.utils --> components.UpdateBanner { cn }
    components.marketing.PageHero --> "app/(marketing)/love/page" { default }
    components.marketing.SectionHead --> "app/(marketing)/love/page" { default }
    lib.constants --> "app/(marketing)/love/page" { REPO_URL }
    lib.sponsors --> "app/(marketing)/love/page" {
        ACTIVE_SPONSORS,
        PREVIOUS_SPONSORS,
        PREVIOUS_SUPPORTERS,
        SPONSOR_TIERS,
        Sponsor,
    }
    components.sponsors.SponsorLink --> "app/(marketing)/love/page" { default }
    lib.utils --> "app/(marketing)/love/page" { cn }
    components.landing.MarketClock --> "app/(marketing)/page" { MarketDial, MarketStatus }
    components.landing.ProductPreview --> "app/(marketing)/page" { default }
    components.marketing.SectionHead --> "app/(marketing)/page" { default }
    components.marketing.IconCard --> "app/(marketing)/page" { default }
    lib.github --> "app/(marketing)/page" { formatCount, getRepoStats }
    lib.utils --> "app/(marketing)/page" { cn }
    lib.sponsors --> "app/(marketing)/page" { sidebarSponsors }
    components.sponsors.SponsorLink --> "app/(marketing)/page" { default }
    lib.constants --> "app/(marketing)/page" { DISCORD_URL, GOOD_FIRST_ISSUES_URL, REPO_URL }
    lib.utils --> components.landing.MarketClock { cn }
    "lib/market-session" --> components.landing.MarketClock {
        AFTER_END,
        CLOSE,
        DAY,
        OPEN,
        PRE,
        Phase,
        isWeekday,
        newYorkNow,
        sessionOf,
    }
    components.seo.JsonLd --> "app/(marketing)/s/[ticker]/page" { default }
    components.seo.SignUpCta --> "app/(marketing)/s/[ticker]/page" { default }
    components.seo.TradingViewEmbed --> "app/(marketing)/s/[ticker]/page" { default }
    lib.constants --> "app/(marketing)/s/[ticker]/page" {
        CANDLE_CHART_WIDGET_CONFIG,
        symbolInfoConfig,
    }
    lib.seo.edgar --> "app/(marketing)/s/[ticker]/page" {
        EdgarFiling,
        companyBrowseUrl,
        formatFilingDate,
        getEdgarCompany,
    }
    lib.seo.comparisons --> "app/(marketing)/s/[ticker]/page" { GUIDES }
    lib.seo.site --> "app/(marketing)/s/[ticker]/page" { siteUrl }
    lib.seo.tickers --> "app/(marketing)/s/[ticker]/page" {
        UsTicker,
        adjacentTickers,
        findTicker,
        relatedTickers,
        sectorAnchor,
        tickerIntro,
        tickerPath,
    }
    lib.utils --> "app/(marketing)/s/[ticker]/page" {
        formatSymbolForTradingView,
        tradingViewSymbolUrl,
    }
    components.TradingViewWidget --> components.seo.TradingViewEmbed { default }
    components.marketing.PageHero --> "app/(marketing)/s/page" { default }
    components.seo.JsonLd --> "app/(marketing)/s/page" { default }
    lib.seo.site --> "app/(marketing)/s/page" { siteUrl }
    lib.seo.tickers --> "app/(marketing)/s/page" {
        US_TICKERS,
        sectorAnchor,
        tickerPath,
        tickersBySector,
    }
    components.marketing.IconCard --> "app/(marketing)/sponsor/page" { default }
    lib.github --> "app/(marketing)/sponsor/page" { formatCount, getRepoStats }
    lib.constants --> "app/(marketing)/sponsor/page" { DISCORD_URL, sponsorCheckoutUrl }
    lib.sponsors --> "app/(marketing)/sponsor/page" {
        ACTIVE_SPONSORS,
        FUNDING_USES,
        PREVIOUS_SPONSORS,
        PREVIOUS_SUPPORTERS,
        REGISTERED_USERS,
        SPONSOR_CONTACT_EMAIL,
        SPONSOR_GOAL,
        SPONSOR_RECIPIENT,
        SPONSOR_TIERS,
        Sponsor,
        SponsorTierId,
        TIER_COLOR,
        tierBorder,
    }
    components.sponsors.SponsorLink --> "app/(marketing)/sponsor/page" { default }
    lib.utils --> "app/(marketing)/sponsor/page" { cn }
    components.marketing.PageHero --> "app/(marketing)/terms/page" { default }
    components.marketing.SectionHead --> "app/(marketing)/terms/page" { default }
    components.TradingViewWidget --> "app/(root)/dashboard/page" { default }
    components.Panel --> "app/(root)/dashboard/page" { default }
    components.IndexPulse --> "app/(root)/dashboard/page" { PulseSkeleton, default }
    components.DataFreshness --> "app/(root)/dashboard/page" { LocalizedDataFreshness }
    components.MarketSwitcher --> "app/(root)/dashboard/page" { default }
    components.YahooQuotes --> "app/(root)/dashboard/page" { YahooMovers, default }
    lib.constants --> "app/(root)/dashboard/page" {
        CRYPTO_HEATMAP_CONFIG,
        STOCK_HEATMAP_CONFIG,
        marketOverviewConfig,
        marketQuotesConfig,
        timelineConfig,
    }
    lib.markets --> "app/(root)/dashboard/page" {
        MARKETS,
        MARKET_COOKIE,
        getMarket,
        isMarketOpen,
        marketForCountry,
    }
    "lib/better-auth/auth" --> "app/(root)/dashboard/page" { getSession }
    i18n.config --> "app/(root)/dashboard/page" { toMessageKey }
    lib.utils --> components.Panel { cn }
    lib.markets --> components.MarketSwitcher { MARKETS, MARKET_COOKIE, MarketId }
    lib.utils --> components.MarketSwitcher { cn }
    components.ChangePill --> components.YahooQuotes { default }
    "lib/actions/yahoo.actions" --> components.YahooQuotes { getYahooDailyQuotes }
    lib.yahoo --> components.YahooQuotes { yahooAppSymbol }
    lib.markets --> components.YahooQuotes { Market }
    i18n.config --> components.YahooQuotes { toMessageKey }
    "lib/better-auth/auth" --> "app/(root)/layout" { getSession }
    components.HtmlLang --> "app/(root)/layout" { default }
    components.shell.AppShell --> "app/(root)/layout" { default }
    components.DonatePopup --> "app/(root)/layout" { default }
    "lib/actions/finnhub.actions" --> "app/(root)/layout" { searchStocks }
    "lib/actions/watchlist.actions" --> "app/(root)/layout" { getUserWatchlist }
    components.shell.Sidebar --> components.shell.AppShell { default }
    components.shell.TabBar --> components.shell.AppShell { default }
    components.SearchCommand --> components.shell.AppShell { default }
    lib.utils --> components.shell.AppShell { cn }
    components.UpdateBanner --> components.shell.AppShell { default }
    components.SearchCommand --> components.shell.Sidebar { openSearch }
    components.LanguageSwitcher --> components.shell.Sidebar { default }
    "lib/actions/auth.actions" --> components.shell.Sidebar { signOut }
    lib.utils --> components.shell.Sidebar { cn }
    lib.sponsors --> components.shell.Sidebar { SIDEBAR_SPONSOR_SLOTS, sidebarSponsors }
    components.sponsors.SponsorLink --> components.shell.Sidebar { default }
    components.ui.command --> components.SearchCommand {
        CommandDialog,
        CommandEmpty,
        CommandInput,
        CommandList,
    }
    "lib/actions/finnhub.actions" --> components.SearchCommand { searchStocks }
    "lib/actions/watchlist-lists.actions" --> components.SearchCommand { addSymbolToList }
    hooks.useDebounce --> components.SearchCommand { useDebounce }
    lib.utils --> components.SearchCommand { cn }
    "components/ui/dropdown-menu" --> components.LanguageSwitcher {
        DropdownMenu,
        DropdownMenuContent,
        DropdownMenuRadioGroup,
        DropdownMenuRadioItem,
        DropdownMenuTrigger,
    }
    i18n.config --> components.LanguageSwitcher { LOCALES, LOCALE_NAMES, isLocale }
    "lib/actions/locale.actions" --> components.LanguageSwitcher { setLocale }
    lib.utils --> components.LanguageSwitcher { cn }
    lib.utils --> "components/ui/dropdown-menu" { cn }
    components.SearchCommand --> components.shell.TabBar { openSearch }
    lib.utils --> components.shell.TabBar { cn }
    components.ui.dialog --> components.DonatePopup {
        Dialog,
        DialogContent,
        DialogDescription,
        DialogHeader,
        DialogTitle,
    }
    components.Panel --> "app/(root)/profile/page" { default }
    components.profile.ProfileForm --> "app/(root)/profile/page" { default }
    components.profile.PasswordForm --> "app/(root)/profile/page" { default }
    "lib/better-auth/auth" --> "app/(root)/profile/page" { auth, getSession }
    "lib/actions/watchlist.actions" --> "app/(root)/profile/page" { getUserWatchlist }
    "lib/actions/alert.actions" --> "app/(root)/profile/page" { getUserAlerts }
    "lib/market-data" --> "app/(root)/profile/page" { alertsEnabled }
    components.forms.InputField --> components.profile.ProfileForm { default }
    components.forms.ChoiceChips --> components.profile.ProfileForm { default }
    components.forms.CountrySelectField --> components.profile.ProfileForm { CountrySelectField }
    lib.constants --> components.profile.ProfileForm {
        INVESTMENT_GOALS,
        PREFERRED_INDUSTRIES,
        RISK_TOLERANCE_OPTIONS,
    }
    "lib/actions/profile.actions" --> components.profile.ProfileForm { ProfileInput, updateProfile }
    components.forms.InputField --> components.profile.PasswordForm { default }
    components.forms.PasswordRequirements --> components.profile.PasswordForm { default }
    lib.constants --> components.profile.PasswordForm { passwordValidation }
    "lib/actions/profile.actions" --> components.profile.PasswordForm { changePassword }
    components.TradingViewWidget --> "app/(root)/stocks/[symbol]/page" { default }
    components.stocks.StockHeader --> "app/(root)/stocks/[symbol]/page" {
        StockHeaderSkeleton,
        default,
    }
    components.stocks.StockSentimentCard --> "app/(root)/stocks/[symbol]/page" { default }
    components.stocks.AlphaiNewsCard --> "app/(root)/stocks/[symbol]/page" { default }
    components.stocks.StockChart --> "app/(root)/stocks/[symbol]/page" { default }
    components.Panel --> "app/(root)/stocks/[symbol]/page" { default }
    lib.constants --> "app/(root)/stocks/[symbol]/page" {
        COMPANY_FINANCIALS_WIDGET_CONFIG,
        COMPANY_PROFILE_WIDGET_CONFIG,
        TECHNICAL_ANALYSIS_WIDGET_CONFIG,
    }
    "lib/actions/adanos.actions" --> "app/(root)/stocks/[symbol]/page" { getStockSentimentInsights }
    "lib/actions/alphai.actions" --> "app/(root)/stocks/[symbol]/page" { getAlphaiTickerNews }
    "lib/actions/finnhub.actions" --> "app/(root)/stocks/[symbol]/page" {
        getStockMetrics,
        getTradingViewExchange,
    }
    lib.markets --> "app/(root)/stocks/[symbol]/page" { hasFinnhubCompanyData }
    lib.utils --> "app/(root)/stocks/[symbol]/page" {
        formatSymbolForTradingView,
        isChartEmbeddable,
        qualifyTradingViewSymbol,
        tradingViewSymbolUrl,
    }
    i18n.config --> "app/(root)/stocks/[symbol]/page" { Locale }
    components.WatchlistButton --> components.stocks.StockHeader { default }
    components.watchlist.CreateAlertModal --> components.stocks.StockHeader { default }
    components.stocks.StockLivePrice --> components.stocks.StockHeader { default }
    "lib/actions/watchlist.actions" --> components.stocks.StockHeader { isStockInWatchlist }
    "lib/actions/finnhub.actions" --> components.stocks.StockHeader {
        getCompanyProfile,
        getLiveQuotes,
    }
    lib.utils --> components.stocks.StockHeader {
        formatNumber,
        formatPrice,
        formatSymbolForTradingView,
        isChartEmbeddable,
    }
    lib.markets --> components.stocks.StockHeader { hasFinnhubQuotes }
    lib.constants --> components.stocks.StockHeader { symbolInfoConfig }
    components.TradingViewWidget --> components.stocks.StockHeader { default }
    components.ChangePill --> components.stocks.StockHeader { default }
    "lib/actions/yahoo.actions" --> components.stocks.StockHeader { getYahooDailyQuotes }
    lib.yahoo --> components.stocks.StockHeader { isYahooSymbol }
    "lib/actions/watchlist.actions" --> components.WatchlistButton {
        addToWatchlist,
        removeFromWatchlist,
    }
    lib.utils --> components.WatchlistButton { cn }
    components.ui.dialog --> components.watchlist.CreateAlertModal {
        Dialog,
        DialogContent,
        DialogDescription,
        DialogTitle,
        DialogTrigger,
    }
    "lib/actions/alert.actions" --> components.watchlist.CreateAlertModal { createAlert }
    lib.sma --> components.watchlist.CreateAlertModal { SMA_PERIODS, SmaPeriod }
    "lib/market-data" --> components.watchlist.CreateAlertModal { alertsEnabled }
    lib.utils --> components.watchlist.CreateAlertModal { cn, formatPrice }
    components.ChangePill --> components.stocks.StockLivePrice { default }
    components.DataFreshness --> components.stocks.StockLivePrice { LocalizedDataFreshness }
    components.PriceFlash --> components.stocks.StockLivePrice { default }
    hooks.useLiveQuotes --> components.stocks.StockLivePrice { LiveQuote, useLiveQuotes }
    lib.utils --> components.stocks.StockLivePrice { formatPrice }
    "lib/actions/adanos.helpers" --> components.stocks.StockSentimentCard { StockSentimentInsights }
    lib.utils --> components.stocks.StockSentimentCard { cn }
    i18n.config --> components.stocks.StockSentimentCard { toMessageKey }
    "lib/actions/alphai.helpers" --> components.stocks.AlphaiNewsCard {
        AlphaiSentiment,
        AlphaiTickerNews,
        alphaiStockUrl,
    }
    lib.utils --> components.stocks.AlphaiNewsCard { cn }
    components.TradingViewWidget --> components.stocks.StockChart { default }
    components.Panel --> components.stocks.StockChart { default }
    "components/ui/dropdown-menu" --> components.stocks.StockChart {
        DropdownMenu,
        DropdownMenuCheckboxItem,
        DropdownMenuContent,
        DropdownMenuLabel,
        DropdownMenuTrigger,
    }
    lib.constants --> components.stocks.StockChart { CANDLE_CHART_WIDGET_CONFIG }
    "lib/actions/watchlist.actions" --> "app/(root)/watchlist/page" { getUserWatchlist }
    "lib/actions/alert.actions" --> "app/(root)/watchlist/page" { getUserAlerts }
    "lib/market-data" --> "app/(root)/watchlist/page" { alertsEnabled }
    "lib/actions/finnhub.actions" --> "app/(root)/watchlist/page" { getNews, getWatchlistData }
    "lib/actions/watchlist-lists.actions" --> "app/(root)/watchlist/page" { getWatchlistLists }
    components.watchlist.WatchlistTable --> "app/(root)/watchlist/page" { default }
    components.watchlist.AlertsPanel --> "app/(root)/watchlist/page" { default }
    components.watchlist.NewsList --> "app/(root)/watchlist/page" { default }
    components.watchlist.NamedListTabs --> "app/(root)/watchlist/page" { default }
    components.watchlist.NamedListTable --> "app/(root)/watchlist/page" { default }
    components.watchlist.AddToListButton --> "app/(root)/watchlist/page" { default }
    components.Panel --> "app/(root)/watchlist/page" { default }
    components.DataFreshness --> "app/(root)/watchlist/page" { LocalizedDataFreshness }
    components.SearchCommand --> "app/(root)/watchlist/page" { SearchButton }
    components.watchlist.CreateAlertModal --> components.watchlist.WatchlistTable { default }
    components.watchlist.AddToListMenu --> components.watchlist.WatchlistTable { default }
    components.WatchlistButton --> components.watchlist.WatchlistTable { default }
    components.ChangePill --> components.watchlist.WatchlistTable { default }
    components.PriceFlash --> components.watchlist.WatchlistTable { default }
    hooks.useLiveQuotes --> components.watchlist.WatchlistTable { useLiveQuotes }
    components.SearchCommand --> components.watchlist.WatchlistTable { SearchButton }
    lib.utils --> components.watchlist.WatchlistTable { formatNumber, formatPrice }
    lib.markets --> components.watchlist.WatchlistTable { hasFinnhubQuotes }
    "lib/actions/finnhub.actions" --> components.watchlist.WatchlistTable { getWatchlistData }
    "components/ui/dropdown-menu" --> components.watchlist.AddToListMenu {
        DropdownMenu,
        DropdownMenuContent,
        DropdownMenuItem,
        DropdownMenuLabel,
        DropdownMenuSeparator,
        DropdownMenuTrigger,
    }
    components.ui.dialog --> components.watchlist.AddToListMenu {
        Dialog,
        DialogContent,
        DialogHeader,
        DialogTitle,
    }
    "lib/actions/watchlist-lists.actions" --> components.watchlist.AddToListMenu {
        addSymbolToList,
        createWatchlistList,
    }
    "lib/actions/alert.actions" --> components.watchlist.AlertsPanel { deleteAlert }
    "lib/market-data" --> components.watchlist.AlertsPanel { alertsEnabled }
    lib.utils --> components.watchlist.AlertsPanel { formatPrice }
    "lib/actions/watchlist-lists.actions" --> components.watchlist.NamedListTabs {
        WatchlistListSummary,
        createWatchlistList,
        deleteWatchlistList,
    }
    lib.utils --> components.watchlist.NamedListTabs { cn }
    components.ChangePill --> components.watchlist.NamedListTable { default }
    "lib/actions/finnhub.actions" --> components.watchlist.NamedListTable { getWatchlistData }
    lib.utils --> components.watchlist.NamedListTable { formatNumber, formatPrice }
    components.watchlist.RemoveFromListButton --> components.watchlist.NamedListTable { default }
    "lib/actions/watchlist-lists.actions" --> components.watchlist.RemoveFromListButton {
        removeSymbolFromList,
    }
    components.SearchCommand --> components.watchlist.AddToListButton { openSearchForList }
    lib.inngest.client --> app.api.inngest.route { inngest }
    "lib/market-data" --> app.api.inngest.route { alertsEnabled }
    lib.inngest.functions --> app.api.inngest.route {
        checkInactiveUsers,
        checkStockAlerts,
        sendSignUpEmail,
        sendWeeklyNewsSummary,
    }
    components.ui.sonner --> app.layout { Toaster }
    components.OntoLaunchCard --> app.layout { default }
    lib.seo.site --> app.robots { siteUrl }
    lib.seo.sitemap --> app.sitemap { sitemapEntries }
    lib.seo.site --> app.sitemap { siteUrl }
    i18n.config --> i18n.request { isLocale }
    i18n.locale --> i18n.request { resolveLocale }
}
