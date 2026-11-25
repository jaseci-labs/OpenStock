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
}
