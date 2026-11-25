"""Work no request waits for: the welcome email after sign-up, the weekly news letter, the price-alert checker and
the daily count of inactive users. The server's loop reads no request while a scheduled function runs, so each one
only decides whether work is due and starts it beside the loop."""
import json;
import sys;
import threading;
import time;
import from datetime { datetime, timezone }
import from stdjac { allroots, commit, encode }

glob DAY: int = 86400,
     WEEKLY_TRIES: int = 4,
     checking: threading.Lock = threading.Lock(),
     # Tests put fakes here
     clock: Callable[[], datetime] = lambda -> datetime { datetime.now(timezone.utc) },
     ask: Callable[[str], str] = ask_ai,
     price_of: Callable[[str], Quote | None] = lambda (s: str) -> Quote | None { get_quote(s) },
     closes_of: Callable[[str], Closes | None] = daily_closes,
     subscribe: Callable[[str, str], any] = lambda (email: str, first: str) -> any {
         add_subscriber(email, first)
     },
     mail_welcome: Callable[[str, str, str, str], bool] = send_welcome_email,
     mail_alert: Callable[[str, str, float, float, str, int, str], bool] = send_alert_email;

"""On root.shared, the day a clock-bound job last ran and how often it was tried that day: what stops a job that
ticks every few minutes from running twice."""
node Ran {
    has job: str,
        day: str = "",
        tries: int = 0;
}

def log(text: str) {
    print(text, file=sys.stderr);
}

"""A try at `job` for today (UTC), when it is due: from `hour` on, only on `weekday` (Monday is 0) when one is
given, and not yet tried `tries` times today. None otherwise. @schedule counts seconds, not clock times, so the
jobs tick and ask here."""
def claim(job: str, hour: int, weekday: int = -1, tries: int = 1) -> Ran | None {
    now = clock();
    found = [m for m in [root.shared --> [?:Ran]] if m.job == job];
    mark = found[0] if found else root.shared ++> Ran(job);
    if mark.day != now.date().isoformat() {
        (mark.day, mark.tries) = (now.date().isoformat(), 0);
    }
    if now.hour < hour or weekday not in [-1, now.weekday()] or mark.tries >= tries {
        return None;
    }
    mark.tries += 1;
    return mark;
}

"""The welcome email, as it is sent beside the sign-up: an intro the AI writes from the profile (the stock one when
every provider fails), in the language picked at sign-up, and a place on the Kit list the weekly letter goes to.
False when the email was skipped for want of SMTP settings."""
def welcome(
    email: str, name: str, country: str, goals: str, risk: str, industry: str, locale: str
) -> bool {
    profile = f"\n- Country: {country}\n- Investment goals: {goals}\n- Risk tolerance: {risk}\n- Preferred industry: {industry}\n";
    language = {"pl": "Polish", "ar": "Arabic"}.get(locale);
    prompt = PERSONALIZED_WELCOME_EMAIL_PROMPT.replace("{{userProfile}}", profile)
        + (f"\n\nWrite the intro in {language}." if language else "");
    try {
        intro = ask(prompt);
    } except Exception as e {
        log(f"All AI providers failed for welcome email: {e}");
        intro = phrase(locale, "welcome", "fallbackIntro");
    }
    try {
        subscribe(email, name.split(" ")[0]);
    } except Exception as e {
        log(f"Kit subscription failed for {email}: {e}");
    }
    return mail_welcome(email, name, intro, locale);
}

def welcome_quietly(
    email: str, name: str, country: str, goals: str, risk: str, industry: str, locale: str
) {
    try {
        welcome(email, name, country, goals, risk, industry, locale);
    } except Exception as e {
        log(f"Error sending welcome email to {email}: {e}");
    }
}

"""Called at sign-up, for the new caller: notes where their alerts go, then sends the welcome email beside the call,
so a slow AI or mail server never holds sign-up up or fails it."""
def send_welcome(
    email: str, name: str, country: str, goals: str, risk: str, industry: str, locale: str
) {
    try {
        remember_owner(email, name, locale);
    } except RuntimeError {
        log(
            f"send_welcome ran for no caller: {email} gets no alert emails until remember_owner is called",
        );
    }
    flow welcome_quietly(email, name, country, goals, risk, industry, locale);
}

"""Summarise the latest market news with the AI and send it to the whole Kit list. Also callable with the
deployment's key, to send one by hand."""
def send_weekly_news -> str {
    articles = get_news();
    if not articles {
        return "No news available to summarize.";
    }
    prompt = NEWS_SUMMARY_EMAIL_PROMPT.replace(
        "{{newsData}}", json.dumps(encode(articles), indent=2)
    ).replace("daily", "weekly", 1).replace("Daily", "Weekly", 1);
    try {
        summary = ask(prompt);
    } except Exception as e {
        log(f"All AI providers failed for news summary: {e}");
        summary = "Market is moving. Log in to see more.";
    }
    now = clock();
    date = f"{now:%A, %B} {now.day}, {now.year}";
    subject = f"📈 Weekly Market Summary - {date}";
    send_broadcast(subject, news_html(subject, date, summary));
    return "Weekly news broadcast sent";
}

def weekly_news_try(mark: Ran) {
    try {
        log(send_weekly_news());
        mark.tries = WEEKLY_TRIES;
    } except Exception as e {
        log(f"Weekly news failed (try {mark.tries} of {WEEKLY_TRIES}): {e}");
        # A retry would only save another draft until the sender address is confirmed in Kit
        if "saved as a draft" in str(e) {
            mark.tries = WEEKLY_TRIES;
        }
    }
    commit();
}

"""Mondays from 09:00 UTC, once: a failed send is tried again at the next ticks, four times in all."""
@schedule(interval=600.0)
def weekly_news {
    mark = claim("weekly-news", 9, 0, WEEKLY_TRIES);
    if mark {
        flow weekly_news_try(mark);
    }
}

"""Email the owner of a triggered alert. The alert is claimed (and the claim kept) before the email goes, so it
fires once whatever happens after; a failed or skipped send releases it for the next run. An SMA alert also stores
the average it crossed, so the alert matches its email."""
def fire(owner_root: Root, a: Alert, price: float, average: float | None) {
    (a.triggered, a.active) = (True, False);
    a.target_price = a.target_price if average is None else average;
    commit();
    owners = [o for o in [owner_root --> [?:Owner]] if o.email];
    if not owners {
        log(f"No email for the owner of alert {jid(a)}; closing it without notifying");
        return;
    }
    period = 0 if average is None else a.sma_period;
    (to, lang) = (owners[0].email, owners[0].locale);
    try {
        sent = mail_alert(to, a.symbol, price, a.target_price, a.condition, period, lang);
    } except Exception as e {
        log(f"Failed to process alert {jid(a)} ({a.symbol}); will retry next run: {e}");
        sent = False;
    }
    if not sent {
        (a.triggered, a.active) = (False, True);
    }
}

"""One pass over every active alert: fixed-price alerts fire on the level, SMA alerts on a cross of the average.
Each symbol is priced once, and its daily closes fetched once (they are cached for an hour besides), however many
alerts share it. `roots` is every caller's unless a test passes its own."""
def check_alerts(roots: list[Root] | None = None) -> dict[str, int] {
    now = time.time();
    live = [
        (r, a)
        for r in (allroots() if roots is None else roots)
        for a in [r --> [?:Alert]]
        if a.active and not a.triggered and a.expires_at > now
    ];
    quotes = {s: price_of(s) for s in {a.symbol for (_, a) in live}};
    closes = {s: closes_of(s) for s in {a.symbol for (_, a) in live if a.target == "SMA"}};
    fired = 0;
    for (owner_root, a) in live {
        (quote, daily, average) = (quotes[a.symbol], closes.get(a.symbol), None);
        if quote is None or not quote.price {
            continue;
        }
        if a.target == "SMA" {
            average = sma(daily.closes, a.sma_period) if daily else None;
            if average is None {
                continue;
            }
            if not has_crossed(a.condition, a.last_side, quote.price, average) {
                # Where the price sits now, saved so the next run can tell a cross from a level
                a.last_side = side_of(quote.price, average) or a.last_side;
                a.target_price = average;
                continue;
            }
        } elif quote.price < a.target_price
            if a.condition == "ABOVE"
            else quote.price > a.target_price {
            continue;
        }
        fired += 1;
        fire(owner_root, a, quote.price, average);
    }
    return {"processed": len(live), "triggered": fired};
}

"""One run at a time, so two overlapping runs can never both email an alert."""
def check_alerts_once {
    if checking.acquire(blocking=False) {
        try {
            log(f"Alert check: {check_alerts()}");
        } except Exception as e {
            log(f"Alert check failed: {e}");
        } finally {
            checking.release();
        }
        commit();
    }
}

"""Every 5 minutes. Price alerts are an OpenStock Cloud feature, so the checker only runs in realtime mode."""
@schedule(interval=300.0)
def check_stock_alerts {
    if is_realtime() {
        flow check_alerts_once();
    }
}

"""Up to 50 owners not seen for 30 days. Legacy composed a re-engagement email for each and sent none (Kit can only
mail the whole list), so until a 1:1 send is wired up this counts them and nothing else: marking them as mailed
would skip them for 30 days."""
def inactive_users(roots: list[Root] | None = None) -> list[Owner] {
    cutoff = time.time() - 30 * DAY;
    found = [
        o
        for r in (allroots() if roots is None else roots)
        for o in [r --> [?:Owner]]
        if o.email and o.seen < cutoff
    ];
    return found[:50];
}

"""Daily, from 10:00 UTC."""
@schedule(interval=3600.0)
def check_inactive_users {
    if claim("inactive-users", 10) {
        log(f"Inactive users: {len(inactive_users())} found, 0 emailed");
    }
}
