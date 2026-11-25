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
    ui.bits ++> pages.index { Panel }
    api.fetch ++> api.insights | api.ai | api.kit { request_json }
    insight_model ++> api.insights { SourceInsight, StockSentiment, NewsItem, TickerNews }
    model ++> api.portfolio { Quote, Closes, WatchItem, ListSummary, AlertInfo, Saved, MAX_WATCHLIST, MAX_LISTS, MAX_LIST_SYMBOLS, MAX_LIST_NAME, MAX_ACTIVE_ALERTS, has_finnhub_quotes, is_sma_period, sma, side_of }
    api.quotes ++> api.portfolio { get_quote, daily_closes, is_realtime }
    model ++> api.jobs { Quote, Closes, sma, side_of, has_crossed }
    api.quotes ++> api.jobs { get_quote, daily_closes, is_realtime, get_news }
    api.portfolio ++> api.jobs { Alert, Owner, remember_owner }
    api.mail ++> api.jobs { send_welcome_email, send_alert_email, phrase, news_html }
    api.prompts ++> api.jobs { PERSONALIZED_WELCOME_EMAIL_PROMPT, NEWS_SUMMARY_EMAIL_PROMPT }
    api.ai ++> api.jobs { ask_ai }
    api.kit ++> api.jobs { add_subscriber, send_broadcast }
}
