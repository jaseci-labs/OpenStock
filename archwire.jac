graph layers {
    layer all { *; }
}

graph spaces {
    space api: native { api.*; }
    space site: browser { entry web; pages.* | ui.*; }

    app web { run api; serve site; }
}

graph import {
    api.quotes ++> pages.index { ping }
    ui.bits ++> pages.index { Panel }
    api.fetch ++> api.insights | api.ai | api.kit { request_json }
    insight_model ++> api.insights { SourceInsight, StockSentiment, NewsItem, TickerNews }
}
