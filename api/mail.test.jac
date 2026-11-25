glob outbox: list[tuple[str, str, str, str]] = [];  # (to, subject, text, html)

def fake_deliver(to: str, subject: str, text: str, body: str) {
    outbox.append((to, subject, text, body));
}

"""No SMTP: letters land in `outbox`. The messages are the project's own, beside the api directory."""
def stub(credentials: str = "secret") {
    deliver = fake_deliver;
    outbox.clear();
    os.environ.update({
        "NODEMAILER_EMAIL": "sender@example.com",
        "NODEMAILER_PASSWORD": credentials,
        "OPENSTOCK_MESSAGES": os.path.join(os.path.dirname(os.path.dirname(__file__)), "messages"),
    });
}

def alert_mail(condition: str, sma_period: int = 0, symbol: str = "AAPL") -> tuple[str, str, str] {
    stub();
    assert send_alert_email("user@example.com", symbol, 103.0, 100.0, condition, sma_period);
    return outbox[0][1:];
}

test "the welcome email escapes the name and keeps only text and <strong> from the AI intro" {
    stub();
    assert send_welcome_email(
        "user@example.com",
        """<a href="https://evil.example">Click</a> $' $&""",
        """<p style="x">Hi <strong>growth</strong> fan. <a href="https://evil.example">Verify your account</a><img src=x onerror=alert(1)><strong onclick="x">bold</strong> R&amp;D</p>""",
    );
    (to, subject, text, body) = outbox[0];
    assert to == "user@example.com" and subject.startswith("Welcome to Openstock");
    for bad in ['evil.example">', '<a href="https://evil', "<img src=x", "onclick", "{{"] {
        assert bad not in body, bad;
    }
    assert "&lt;a href=&quot;https://evil.example&quot;&gt;Click&lt;/a&gt; $&#39; $&amp;" in body;
    assert "Hi <strong>growth</strong> fan. Verify your account<strong>bold</strong> R&amp;D</p>"
        in body;
}

test "the welcome email goes out in the reader's language, English for one we have none for" {
    stub();
    send_welcome_email("a@example.com", "Ala", "Hi", "pl");
    send_welcome_email("b@example.com", "Bo", "Hi", "xx");
    send_welcome_email("c@example.com", "Bo", "Hi");
    assert '<html lang="pl">' in outbox[0][3] and outbox[0][1] != outbox[2][1];
    assert '<html lang="en">' in outbox[1][3] and outbox[1][1:3] == outbox[2][1:3];
    assert "Welcome aboard Bo" in outbox[1][3];
}

test "an email is skipped, not failed, where SMTP is not configured" {
    stub("");
    assert not send_welcome_email("user@example.com", "User", "Hi");
    assert not send_alert_email("user@example.com", "AAPL", 103.0, 100.0, "ABOVE");
    assert outbox == [];
}

test "a price alert email says which way the price went, in its colours" {
    (subject, text, body) = alert_mail("ABOVE");
    assert subject == "🔔 Price Alert: AAPL is above $100.00";
    assert text == "AAPL is now $103.00, above your target of $100.00.";
    for part in [
        "<title>Price Alert: AAPL Hit Upper Target</title>",
        "📈 Price Above Reached",
        "background-color: #059669;",
        "color: #10b981;\">$103.00</p>",
        "<strong>Target Price:</strong> $100.00",
        "<strong>Trigger:</strong> Price exceeded your upper threshold of $100.00",
        "Opportunity Alert!",
    ] {
        assert part in body, part;
    }
    (subject, text, body) = alert_mail("BELOW");
    assert subject == "🔔 Price Alert: AAPL is below $100.00" and "{{" not in body;
    assert "📉 Price Below Hit" in body
        and "background-color: #dc2626;" in body
        and "#ef4444" in body;
}

test "an SMA alert email names the average; heading and callout stay the price alert's" {
    (subject, text, body) = alert_mail("ABOVE", 20);
    assert subject == "🔔 Price Alert: AAPL crossed above its 20-day average";
    assert text == "AAPL is now $103.00, above its 20-day simple moving average of $100.00.";
    for part in [
        "<title>Price Alert: AAPL Crossed Above SMA 20</title>",
        "<strong>SMA 20:</strong> $100.00",
        "Price crossed above the 20-day simple moving average ($100.00)",
        "📈 Price Above Reached",
        "Opportunity Alert!",
    ] {
        assert part in body, part;
    }
    assert "crossed below its 50-day average" in alert_mail("BELOW", 50)[0];
}

test "money is dollars, USDT for Binance pairs, and stays visible under a cent" {
    assert money("AAPL", 1234.5) == "$1,234.50" and money("AAPL", 0.5) == "$0.50";
    assert money("AAPL", 0.001234) == "$0.001234" and money("AAPL", 0.005) == "$0.005";
    assert money("BINANCE:BTCUSDT", 65000.0) == "65,000 USDT";
    assert money("BINANCE:SHIBUSDT", 0.00002412) == "0.000024 USDT";
    assert alert_mail("ABOVE", 0, "BINANCE:BTCUSDT")[0].endswith("is above 100 USDT");
}

test "the weekly letter restyles the AI's summary and leaves Kit's unsubscribe token alone" {
    body = news_html(
        "Weekly", "Monday, November 23, 2026", '<h3 class="x">Top</h3><a href="u">Read</a> • one'
    );
    assert "<title>Weekly</title>" in body and "Monday, November 23, 2026</p>" in body;
    assert '<h3 style="color: #ffffff; margin-top: 30px; margin-bottom: 15px; font-size: 20px;" class="x">Top</h3>'
        in body;
    assert '<a style="color: #20c997; text-decoration: none; font-weight: 600;" href="u">' in body;
    assert 'font-size: 18px;">•</span> one' in body and '<a href="{{ unsubscribe_url }}"' in body;
}
