import os;
import from stdjac { remove }

glob prices: dict[str, float] = {},
     history_asked: list[str] = [],
     alert_mails: list[tuple[str, str, float, float, str, int, str]] = [],
     alert_mail_sends: bool = True,
     welcome_mails: list[tuple[str, str, str, str]] = [],
     prompts: list[str] = [],
     ai_answer: str = "",  # "" = every provider fails
     kit_calls: list[tuple[str, str]] = [],
     now_is: datetime = datetime(2026, 11, 23, 9, 5, tzinfo=timezone.utc);  # a Monday

def fake_closes(symbol: str) -> Closes | None {
    history_asked.append(symbol);
    return Closes([90.5 + i for i in range(20)], 109.5);  # 20 closes averaging 100
}

def fake_alert_mail(
    to: str, symbol: str, price: float, target: float, condition: str, period: int, locale: str
) -> bool {
    alert_mails.append((to, symbol, price, target, condition, period, locale));
    return alert_mail_sends;
}

def fake_welcome_mail(email: str, name: str, intro: str, locale: str) -> bool {
    welcome_mails.append((email, name, intro, locale));
    return True;
}

def fake_ask(prompt: str) -> str {
    prompts.append(prompt);
    if not ai_answer {
        raise RuntimeError("gemini returned empty response");
    }
    return ai_answer;
}

def fake_subscribe(email: str, first: str) -> any {
    kit_calls.append((email, first));
    raise RuntimeError("KIT_API_KEY or KIT_API_SECRET is not defined in environment variables.");
}

"""One caller (owner@example.test, Polish) with these alerts, every outside call faked, nothing run yet."""
def stub(alerts: list[Alert] = [], quotes: dict[str, float] = {}) {
    for n in [root -->] + [root.shared -->] {
        remove(n);
    }
    root ++> Profile(email="owner@example.test", locale="pl");
    for a in alerts {
        root ++> a;
    }
    clock = lambda -> datetime { now_is };
    ask = fake_ask;
    price_of = lambda (s: str) -> Quote | None { Quote(price=prices[s]) if s in prices else None };
    closes_of = fake_closes;
    subscribe = fake_subscribe;
    mail_welcome = fake_welcome_mail;
    mail_alert = fake_alert_mail;
    prices = quotes;
    (alert_mail_sends, ai_answer) = (True, "<p>Hi</p>");
    now_is = datetime(2026, 11, 23, 9, 5, tzinfo=timezone.utc);
    for sink in [history_asked, alert_mails, welcome_mails, prompts, kit_calls] {
        sink.clear();
    }
    os.environ["OPENSTOCK_MESSAGES"] = os.path.join(
        os.path.dirname(os.path.dirname(__file__)), "messages"
    );
}

def sma_alert(last_side: str = "", condition: str = "ABOVE", symbol: str = "AAPL") -> Alert {
    return Alert(symbol, condition, 99.0, "SMA", 20, last_side, expires_at=time.time() + 3600);
}

def price_alert(condition: str, target: float, expires_in: float = 3600.0) -> Alert {
    return Alert("TSLA", condition, target, expires_at=time.time() + expires_in);
}

def check -> tuple[int, int] {
    counts = check_alerts([root]);
    return (counts["processed"], counts["triggered"]);
}

test "an SMA alert fires when the price crosses the average, and says so in the email" {
    a = sma_alert("BELOW");
    stub([a], {"AAPL": 103.0});
    assert check() == (1, 1);
    assert alert_mails == [("owner@example.test", "AAPL", 103.0, 100.0, "ABOVE", 20, "pl")];
    # The stored alert matches the email: the claim saves the average that was crossed
    assert (a.triggered, a.active, a.target_price) == (True, False, 100.0);
    assert check() == (0, 0) and len(alert_mails) == 1, "an alert fires once";
}

test "an SMA alert does not fire while the price stays on the same side, but saves the new average" {
    a = sma_alert("ABOVE");
    stub([a], {"AAPL": 103.0});
    assert check() == (1, 0) and alert_mails == [];
    assert (a.target_price, a.last_side, a.active) == (100.0, "ABOVE", True);
}

test "a fresh SMA alert remembers the side it starts on, so the next move across can fire" {
    a = sma_alert("", "BELOW");
    stub([a], {"AAPL": 103.0});
    assert check() == (1, 0) and alert_mails == [] and a.last_side == "ABOVE";
    prices["AAPL"] = 97.0;
    assert check() == (1, 1) and alert_mails[0][2:6] == (97.0, 100.0, "BELOW", 20);
}

test "each symbol's closes are asked for once per run, however many alerts share it" {
    stub(
        [sma_alert(), sma_alert("", "BELOW"), sma_alert("", "ABOVE", "MSFT")],
        {"AAPL": 103.0, "MSFT": 103.0},
    );
    assert check() == (3, 0) and sorted(history_asked) == ["AAPL", "MSFT"];
}

test "fixed-price alerts stay on the level check, without any daily closes" {
    (up, down, waiting) = (
        price_alert("ABOVE", 200.0),
        price_alert("BELOW", 250.0),
        price_alert("ABOVE", 300.0),
    );
    stub([up, down, waiting, price_alert("ABOVE", 1.0, -60.0)], {"TSLA": 250.0});
    assert check() == (3, 2) and history_asked == [], "an expired alert is not checked";
    assert [m[1:6] for m in alert_mails] == [
        ("TSLA", 250.0, 200.0, "ABOVE", 0),
        ("TSLA", 250.0, 250.0, "BELOW", 0),
    ];
    assert (up.triggered, up.target_price, waiting.triggered, waiting.active)
        == (True, 200.0, False, True);
}

test "a symbol without a price is left for the next run" {
    a = price_alert("ABOVE", 200.0);
    stub([a]);
    assert check() == (1, 0) and a.active;
}

test "an email that is skipped or fails releases the alert; an owner with no address closes it" {
    a = price_alert("ABOVE", 200.0);
    stub([a], {"TSLA": 250.0});
    alert_mail_sends = False;  # email not configured: the alert fires once email works
    assert check() == (1, 1) and (a.triggered, a.active) == (False, True);
    alert_mail_sends = True;
    assert check() == (1, 1) and (a.triggered, a.active) == (True, False) and len(alert_mails) == 2;
    b = price_alert("ABOVE", 200.0);
    stub([b], {"TSLA": 250.0});
    [root --> [?:Profile]][0].email = "";
    assert check() == (1, 1) and alert_mails == [] and (b.triggered, b.active) == (True, False);
}

test "the welcome email carries the AI's intro, written from the profile in the sign-up language" {
    stub();
    assert welcome("ala@example.com", "Ala Nowak", "PL", "Growth", "Medium", "Technology", "pl");
    assert welcome_mails == [("ala@example.com", "Ala Nowak", "<p>Hi</p>", "pl")];
    for part in ["- Country: PL", "- Investment goals: Growth", "- Risk tolerance: Medium"] {
        assert part in prompts[0], part;
    }
    assert "{{userProfile}}" not in prompts[0]
        and prompts[0].endswith("Write the intro in Polish.");
    # Kit being down or unconfigured never costs the welcome email
    assert kit_calls == [("ala@example.com", "Ala")];
    welcome("bo@example.com", "Bo", "US", "Income", "Low", "Energy", "en");
    assert "Write the intro in" not in prompts[1];
}

test "the welcome email falls back to the stock intro when every AI provider fails" {
    stub();
    ai_answer = "";
    assert welcome("bo@example.com", "Bo", "US", "Income", "Low", "Energy", "en");
    assert welcome_mails[0][2].startswith("Thanks for joining Openstock.");
}

test "a clock-bound job is due once on its day, from its hour on, with its retries" {
    stub();
    assert claim("weekly-news", 9, 0, 2) is not None, "Monday 09:05";
    assert claim("weekly-news", 9, 0, 2) is not None, "a second try";
    assert claim("weekly-news", 9, 0, 2) is None, "no third";
    assert claim("inactive-users", 10) is None, "before its hour";
    now_is = datetime(2026, 11, 23, 10, 0, tzinfo=timezone.utc);
    assert claim("inactive-users", 10) is not None and claim("inactive-users", 10) is None;
    now_is = datetime(2026, 11, 24, 12, 0, tzinfo=timezone.utc);
    assert claim("weekly-news", 9, 0, 2) is None, "Tuesday";
    assert claim("inactive-users", 10) is not None, "daily";
    now_is = datetime(2026, 11, 30, 9, 0, tzinfo=timezone.utc);
    assert claim("weekly-news", 9, 0, 2) is not None, "the next Monday";
    assert len([root.shared --> [?:Ran]]) == 2;
}

test "inactive users are the profiles with an address whose caller was not seen for thirty days" {
    stub();
    assert inactive_users([root]) == [], "never seen: nothing to go by";
    seen = root ++> Visit(time.time() - 29 * DAY);
    assert inactive_users([root]) == [];
    seen.seen = time.time() - 31 * DAY;
    assert inactive_users([root]) == [root --> [?:Profile]];
}
