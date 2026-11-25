"""OpenStock's changelog, newest first. The banner and its modal show RELEASES[0]; /changelog
shows the whole timeline."""

# Who made a release happen: pull requests they wrote and issues they opened that led to a change.
# Taken from GitHub (PR authors and the issues each PR closed); bots aren't listed.
obj Credit {
    has login: str,
        prs: list[int] = [],
        issues: list[int] = [];
}

obj Section {
    has title: str,
        items: list[str] = [];
}

# `highlights` is the short list in the banner's modal (latest release only).
obj Release {
    has id: str,
        date: str,
        title: str,
        summary: str,
        highlights: list[str] = [],
        sections: list[Section] = [],
        credits: list[Credit] = [];
}

glob MAINTAINER: str = "ravixalgorithm";

# One line each: `= id | date | title | summary` opens a release, `!` is a highlight, `#` a
# section, `-` an item of it ("#123" in an item links that pull request), and
# `@ login 12 34 issues 56` a credit for those pull requests and issues.
glob RELEASES: list[Release] = parse_releases("""
= 2026-11-22 | 22 Nov 2026 | Late November update | OpenStock in Polish and Arabic, named watchlists, moving-average alerts, pages that fit your phone, and safer sign-in
! The app in Polish and Arabic, laid out right to left in Arabic.
! Named watchlists: up to 10 lists of 50 stocks.
! Alerts when a price crosses its 20 to 200-day moving average.
! The Technicals gauge works again for US stocks.
! Every page fits phones and tablets, from 320px up.
! Fixes to password reset, signed-out devices and sign-up limits.
# Languages
- OpenStock in Polish: the app, sign-in pages, error messages and the welcome and password reset emails, in your browser’s language or the one you pick from the new Language menu in the sidebar. #157
- OpenStock in Arabic: the app, sign-in pages, error messages and emails, with the app laid out right to left in IBM Plex Sans Arabic and the menu drawer opening from the right. #146
# Watchlist
- Named watchlists: group the stocks you watch into up to 10 lists of 50, and file a stock into one from any watchlist row or straight from search. #148
- Live prices reach every row of a full 50-stock watchlist, not just the first 25, on realtime deployments. #162
# Alerts
- Alerts can follow a moving average: get an email when a US stock or coin crosses above or below its 20, 50, 100 or 200-day simple moving average. It’s worked out from free daily closes, so no paid data plan is needed. OpenStock Cloud and self-hosted realtime mode. #183
# Stock pages
- The Technicals gauge on US stock pages shows a reading again instead of “Permission denied”: each ticker now goes to TradingView with its real exchange (NASDAQ, NYSE, AMEX and so on). #176
- An optional scored news card: recent stories rated 1 to 10 for relevance, with what each means for the stock, when the server has an AlphAI key. #173
# Phones and tablets
- No more pages wider than the screen: the update banner, header, tables, stat tiles and stock headers now fit from 320px phones to tablets, and English names stay readable on the Arabic layout. #175
- Public pages are served from Vercel’s cache instead of running a function on every visit, so they open faster. #154
# Accounts and security
- Password reset emails always go out: the send is no longer cut off when the server answers first. #177
- Signing out your other devices when you change your password stops them changing anything straight away. They can only view their own pages until the 5-minute session cache runs out. #181
- mongoose 8.24.10, which closes a critical advisory in how database query filters are cleaned. #179
# Self-hosting
- OpenStock can also run on Cloudflare Workers (experimental), with a database connection per request and a rate limiter that only trusts Cloudflare’s client address there. The hosted site stays on Vercel. #150
- A team signing up from one shared address (one proxy, or Docker’s port forwarding) gets 30 sign-ups an hour instead of 5, with a per-email limit on top, and a forged client address no longer earns a fresh rate limit. Vercel keeps the strict limit. #178 #180
- The Docker image builds again: the lockfile now installs with the npm 10 that ships in node:22-alpine. #158
- The weekly news email no longer reports success when Kit only saved it as a draft, and doesn’t retry into more drafts. #151
- The environment check counts the Finnhub key as a required variable, so it no longer reports 4/3. #170
- Sign-in uses the same secret the production check looks for: BETTER_AUTH_SECRET, or AUTH_SECRET if that’s the one you set. #163
# Community
- The landing page, help, architecture page, guides and README describe OpenStock as it is today: nine markets, three languages, named lists and where each price comes from. #184
- The README shows the I Did My Own badge next to the Trendshift ones. #185
@ ravixalgorithm 150 154 175 180 181 183 184 185
@ ahmaddirar-ios 146 148
@ pawisoon 157 158
@ gugamorato-svg 177 178 179
@ dajiaohuang 151
@ mhatipog 162
@ parmeetkxur 163
@ inshu5757 170
@ makeev 173
@ mjmcg 176
@ raclure issues 165
@ kumetin issues 59
@ soarkit issues 144 149 159 160 161

= 2026-11-09 | 9 Nov 2026 | November update | Saudi Arabia and Poland on the dashboard, dividend yield, and public stock pages
! Two new markets: Saudi Arabia (Tadawul) and Poland (Warsaw), with delayed prices.
! Stock pages show the dividend yield.
! Company and comparison pages anyone can open, signed in or not.
! Docker self-hosters can switch on realtime mode again.
# Markets
- Saudi Arabia (Tadawul) joins the dashboard: TASI, Aramco, Al Rajhi and STC tiles, today’s movers and a quotes table, priced from Yahoo Finance because TradingView blocks Tadawul in embeds. Saudi stock pages and watchlist rows show the price too. #145
- Poland (GPW Warsaw) joins the dashboard: WIG20, WIG, mWIG40 and sWIG80 tiles, today’s movers and a quotes table of blue chips, priced from Yahoo Finance (delayed) because TradingView embeds have Warsaw only end of day. Polish stock pages and watchlist rows show the price too. #147
# Stock pages
- A dividend yield card, from Finnhub’s real data, with a dash for stocks and crypto that don’t pay one. #137
- Public company and comparison pages that work without signing in, and robots.txt and sitemap.xml that search engines can read. #136
# Self-hosting
- Docker and Railway self-hosters can switch on realtime mode again: the data mode is passed in at build time. #134
- MiniMax uses MiniMax-M3.1-Flash unless you pick another model. #140
- better-auth 1.7.10 and nodemailer 10.1.2, with 81 fewer packages to install. #132 #133
# Community
- Every release on this page credits the people who made it, and everyone who has built OpenStock is listed at the bottom. #131
- A README rewritten for how OpenStock works today, with a latest-release badge. #135 #141
- A Code of Conduct (Contributor Covenant 2.1) and a FLOSS/fund funding manifest. #139 #138
@ ravixalgorithm 131 132 133 134 135 136 138 139 141 145
@ ahmaddirar-ios 142
@ octo-patch 140
@ pawisoon 147
@ samki6576 137
@ soarkit issues 143

= 2026-10-18 | 18 Oct 2026 | October update | Draw on charts, keep your indicators, and safer sign-in
! Draw trend lines, Fibonacci and text on any stock chart.
! The indicators you pick stay on every chart.
! Tickers like M&M, Bajaj-Auto and Ericsson B now chart correctly.
! Sign-in and password reset are rate-limited, and a reset signs out your other devices.
! A prebuilt Docker image for self-hosting.
# Charts
- Draw on the stock chart: trend lines, horizontal lines, Fibonacci, shapes and text. #118
- The indicators you pick (SMA, EMA, Bollinger Bands, VWAP, RSI, MACD, Stochastic, ATR) stay on every chart, after a reload and in fullscreen. #119
- Tickers with a - or & now chart correctly: M&M and Bajaj-Auto in India, Ericsson B in Stockholm, Novo Nordisk B in Copenhagen. #117
# Watchlist
- Watchlists hold up to 50 stocks, and you’re told when yours is full. #127
- The Watching list in the sidebar scrolls on its own instead of pushing the page. #110
# Security
- Sign-in, sign-up and password reset are rate-limited, so nobody can guess passwords or flood inboxes. #126
- Resetting your password signs you out on every other device. #125
- Welcome emails can no longer carry links or markup injected at sign-up. #122
- A background job no longer risks emailing the whole newsletter list, and subscriber addresses stay out of the logs. #120
- Next.js security update covering about 30 advisories. #121
# Self-hosting
- A prebuilt Docker image for amd64 and arm64: ghcr.io/open-dev-society/openstock, on Node 22 LTS. #128
- Docker builds need no database or secrets, and no key is stored in the image. #123
- docker compose no longer publishes MongoDB on your network, and its password comes from .env. #124
- One-click deploys on RepoCloud, ZopDay and Railway. #111 #115 #94
# Community
- A Wall of love: our sponsors and supporters, and the posts, videos and articles people have made about OpenStock.
- Orbit and RapidProxy joined as sponsors.
@ ravixalgorithm 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130
@ cosmind-rusu 94
@ Yi-111-a 110
@ cosark 111
@ muskanbandta23 115
@ nexitpl issues 47 54
@ brainistry10 issues 113
@ Greatz08 issues 83
@ saschabrockel issues 36
@ a-lacruz issues 109

= 2026-09-25 | 25 Sep 2026 | The redesign | A new look, a public landing page, more markets and a lot of fixes
# New
- A redesigned app: floating shell, browser-style tabs and a warmer palette. #106
- A public landing page with a live NYSE session dial, and a Sponsor page. #106
- More markets on the dashboard: US, India, Germany, Canada, Australia, Crypto and Forex. #106
- A profile page to edit your details, see connected sign-ins and change your password, and sign-in with Google or GitHub. #106
# Changed
- Quotes refresh hourly for everyone on the free site. #106
- Price alerts are now part of OpenStock Cloud and self-hosting.
- Server functions run in Mumbai, next to the database, so pages respond faster.
# Fixed
- Watchlist and alert changes are tied to the signed-in user; before, one user could change another’s. #106
- Welcome emails, price alerts and the weekly digest run again, and password reset completes. #106
- Pages no longer hang when market data is slow, and email addresses with + are accepted. #106
- Charts no longer get stuck on exchanges TradingView blocks, or on Hong Kong stocks.
- A clearer environment check for self-hosters. #104
- The README now says the news summary is weekly, not daily. #91
- Community fixes brought into the redesign: no “NaN” market cap #82, Taiwan in the country picker #70, indicators that survive fullscreen #68, optional email settings #69, and tests for alert actions #93.
@ ravixalgorithm 106
@ keshav-005 68 69 70
@ Mubashirrrr 82
@ fuxicodex 93
@ BambaSatoru 104
@ kuishou68 91
@ nexitpl issues 49
@ juipeter-pixel issues 34
@ soonfatt issues 38
@ khajaG321 issues 28

= 2026-08 | Jun – Aug 2026 | Summer fixes | A market support guide, sturdier emails and a newer AI model
# Changes
- A Market Support guide explaining which exchanges chart, quote and alert, and why. #84
- Email features are optional: the app runs without mail settings, and warning messages no longer show garbled characters. #85
- Personalised emails use MiniMax’s newer M3 model by default. #87
@ akoweicollinxx 84 85
@ octo-patch 87
@ maxsyst issues 37

= 2026-05 | Apr – May 2026 | Password reset | Reset your password, see the password rules as you type, and better search
# Changes
- Forgot your password? Reset it by email. #71
- Sign-up shows the password rules and ticks them off as you type. #79
- Charts show the right time zone. #72
- Search shows the correct exchange and company details. #73
- No more Turbopack warning about the project root when running locally. #74
@ keshav-005 71 72 73 74
@ Chukwuebuka-2003 79
@ danieldanielecki issues 66
@ nexitpl issues 35
@ aaronwork1205 issues 55
@ k2alzhang issues 39

= 2026-03 | Mar 2026 | Sentiment and 40+ exchanges | What the crowd thinks, and many more markets
# Changes
- Sentiment on every stock page: buzz and bullishness from Reddit, X, news and Polymarket. #64
- Charts for 40+ international exchanges. #65
- MiniMax as an alternative AI provider for personalised emails. #61
- Updated dependencies and background jobs. #63
@ alexander-schneider 64
@ Bortlesboat 65
@ octo-patch 61
@ TPTBusiness 63
@ NicolasBohn 63
@ maplelaef0320 issues 24

= 2026-02 | Feb 2026 | China and Hong Kong charts | Shanghai, Shenzhen and Hong Kong stocks chart correctly
# Changes
- Shanghai, Shenzhen and Hong Kong tickers are converted to TradingView’s format, so their charts load. #57
@ CrixusWen 57
@ ravixalgorithm 51

= 2026-01 | Jan 2026 | Watchlist, alerts and news | Save stocks, get alerted, and read the news that matters to you
# New
- A Watchlist page to save stocks and follow their prices, sortable by symbol. #40 #46
- Price alerts when a stock goes above or below your target. #40
- A news feed for the stocks on your watchlist. #40
- Fullscreen charts. #45
- About, Help and API docs pages, and Siray.ai as a fallback AI provider. #40
- Fixed broken links in the README. #42
@ ravixalgorithm 40 45 46 48
@ ettoreciolli 42
@ nexitpl issues 33 44
@ cn-zeus-jp issues 27

= 2025-12 | Dec 2025 | Security and support | A critical framework fix and a way to support the project
# Changes
- Fixed a critical React Server Components vulnerability. #30
- Vercel Web Analytics. #31
- A way to donate to the project. #32
@ ravixalgorithm 32

= 2025-10 | Oct 2025 | OpenStock launches | Free, open-source market tracking for everyone
# Launch
- Started on 28 Sep 2025 and first deployed on 4 Oct 2025: accounts, stock search and a TradingView-powered dashboard. #1 #9
- Docker and Docker Compose support. #17
- Fixed a build error reported in the first weeks. #25
@ ravixalgorithm 1 2 3 4 5 6 7 8 9 10 11 12 13 14
@ chinnsenn 17
@ nb-src 25
@ Terry0930 issues 23
""");

def parse_releases(text: str) -> list[Release] {
    releases: list[Release] = [];
    for line in text.split("\n") {
        (mark, _, rest) = line.partition(" ");
        if mark == "=" {
            (id, date, title, summary) = rest.split(" | ");
            releases.append(Release(id, date, title, summary));
        } elif mark == "!" {
            releases[-1].highlights.append(rest);
        } elif mark == "#" {
            releases[-1].sections.append(Section(rest));
        } elif mark == "-" {
            releases[-1].sections[-1].items.append(rest);
        } elif mark == "@" {
            (prs, _, issues) = rest.partition(" issues");
            releases[-1].credits.append(
                Credit(
                    prs.split()[0],
                    [int(n) for n in prs.split()[1:]],
                    [int(n) for n in issues.split()],
                ),
            );
        }
    }
    return releases;
}

def count_of(n: int, word: str) -> str {
    return f"{n} {word}{'' if n == 1 else 's'}";
}

def credit_label(c: Credit) -> str {
    return " · ".join([
        count_of(len(xs), word)
        for (xs, word) in [(c.prs, "PR"), (c.issues, "issue")]
        if xs
    ]);
}

def credit_title(c: Credit) -> str {
    return " · ".join([
        f"{word} {' '.join([f'#{n}' for n in xs])}"
        for (xs, word) in [(c.prs, "Pull requests"), (c.issues, "Issues")]
        if xs
    ]);
}

"""Everyone across every release, the maintainer first, then by pull requests and issues."""
def contributors -> list[Credit] {
    everyone: dict[str, Credit] = {};
    for release in RELEASES {
        for c in release.credits {
            person = everyone.setdefault(c.login, Credit(c.login));
            person.prs += c.prs;
            person.issues += c.issues;
        }
    }
    return sorted(
        everyone.values(),
        key=lambda (c: Credit) -> tuple[bool, int, int, str] {
            (c.login != MAINTAINER, -len(c.prs), -len(c.issues), c.login.lower())
        },
    );
}
