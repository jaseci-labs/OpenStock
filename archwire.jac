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
}
