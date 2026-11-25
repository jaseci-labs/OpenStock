"""The emails the app sends itself, over Gmail SMTP and in the reader's language (welcome, price alerts), and the
HTML of the weekly news letter, which Kit sends. The password-reset email is the accounts plugin's own."""
import html;
import json;
import math;
import os;
import re;
import smtplib;
import ssl;
import sys;
import from datetime { datetime, timezone }
import from email.message { EmailMessage }

glob LOCALES: list[str] = ["en", "pl", "ar"],
     deliver: Callable[[str, str, str, str], None] = smtp_send,  # tests put a fake here
     messages: dict[str, any] = {};

# One layout for our own emails; {{body}} is the rows under the logo. Inline styles, since mail clients drop most CSS.
glob SHELL: str = """<!DOCTYPE html>
<html lang="{{lang}}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="format-detection" content="telephone=no">
    <meta name="x-apple-disable-message-reformatting">
    <title>{{title}}</title>
    <!--[if mso]>
    <noscript><xml><o:OfficeDocumentSettings><o:AllowPNG/><o:PixelsPerInch>96</o:PixelsPerInch></o:OfficeDocumentSettings></xml></noscript>
    <![endif]-->
    <style type="text/css">
        @media (prefers-color-scheme: dark) {
            .email-container { background-color: #141414 !important; border: 1px solid #30333A !important; }
            .dark-bg { background-color: #050505 !important; }
            .dark-text { color: #ffffff !important; }
            .dark-text-secondary { color: #9ca3af !important; }
            .dark-text-muted { color: #6b7280 !important; }
            .dark-border { border-color: #30333A !important; }
            .dark-info-box { background-color: #1f2937 !important; border: 1px solid #374151 !important; }
        }
        @media only screen and (max-width: 600px) {
            .email-container { width: 100% !important; margin: 0 !important; }
            .mobile-padding { padding: 24px !important; }
            .mobile-header-padding { padding: 24px 24px 12px 24px !important; }
            .mobile-text { font-size: 14px !important; line-height: 1.5 !important; }
            .mobile-title { font-size: 24px !important; line-height: 1.3 !important; }
            .mobile-outer-padding { padding: 20px 10px !important; }
            .mobile-price { font-size: 28px !important; }
            .dashboard-preview { padding: 0 15px 30px 15px !important; }
        }
        @media only screen and (max-width: 480px) {
            .mobile-title { font-size: 22px !important; }
            .mobile-padding { padding: 15px !important; }
            .mobile-header-padding { padding: 15px 15px 8px 15px !important; }
            .mobile-price { font-size: 24px !important; }
        }
    </style>
</head>
<body style="margin: 0; padding: 0; background-color: #050505; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;">
    <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="background-color: #050505;">
        <tr>
            <td align="center" class="mobile-outer-padding" style="padding: 40px 20px;">
                <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" class="email-container" style="max-width: 600px; background-color: #141414; border-radius: 8px; border: 1px solid #30333A;">
                    <tr>
                        <td align="left" class="mobile-header-padding" style="padding: 40px 40px 20px 40px;">
                            <img src="https://i.ibb.co/r28VWPjS/Screenshot-2025-10-04-123317-Picsart-Ai-Image-Enhancer-removebg-preview.png" alt="{{logoAlt}}" width="150" style="max-width: 100%; height: auto;">
                        </td>
                    </tr>
{{body}}
                </table>
            </td>
        </tr>
    </table>
</body>
</html>""";

glob WELCOME: str = """<tr>
    <td align="center" class="dashboard-preview" style="padding: 40px 40px 0px 40px;">
        <img src="https://i.ibb.co/BKC2HBBQ/dashboard.png" alt="{{dashboardAlt}}" width="100%" style="max-width: 520px; width: 100%; height: auto; border-radius: 12px; border: 1px solid #30333A;">
    </td>
</tr>
<tr>
    <td class="mobile-padding" style="padding: 40px 40px 40px 40px;">
        <h1 class="mobile-title dark-text" style="margin: 0 0 30px 0; font-size: 24px; font-weight: 600; color: #FDD458; line-height: 1.2;">{{heading}}</h1>
        {{intro}}
        <p class="mobile-text dark-text-secondary" style="margin: 0 0 15px 0; font-size: 16px; line-height: 1.6; color: #CCDADC; font-weight: 600;">{{featuresLabel}}</p>
        <ul class="mobile-text dark-text-secondary" style="margin: 0 0 30px 0; padding-left: 20px; font-size: 16px; line-height: 1.6; color: #CCDADC;">
            <li style="margin-bottom: 12px;">{{featureWatchlist}}</li>
            <li style="margin-bottom: 12px;">{{featureSearch}}</li>
            <li style="margin-bottom: 12px;">{{featureDashboard}}</li>
        </ul>
        <p class="mobile-text dark-text-secondary" style="margin: 0 0 40px 0; font-size: 16px; line-height: 1.6; color: #CCDADC;">{{closing}}</p>
        <table role="presentation" cellspacing="0" cellpadding="0" border="0" style="margin: 0 0 40px 0; width: 100%;">
            <tr>
                <td align="center">
                    <a href="https://openstock-ods.vercel.app/" style="display: block; width: 100%; background: linear-gradient(135deg, #FDD458 0%, #E8BA40 100%); color: #000000; text-decoration: none; padding: 16px 32px; border-radius: 8px; font-size: 16px; font-weight: 500; line-height: 1; text-align: center; box-sizing: border-box;">{{cta}}</a>
                </td>
            </tr>
        </table>
        <p class="mobile-text dark-text-muted" style="margin: 40px 0 0 0; font-size: 14px; line-height: 1.5; color: #CCDADC !important; text-align: center;">
            {{initiative}}<br>
            <a href="#" style="color: #CCDADC !important; text-decoration: underline;">{{unsubscribe}}</a> |
            <a href="https://stock-market-dev.vercel.app/" style="color: #CCDADC !important; text-decoration: underline;">{{visitOpenstock}}</a><br>
            © 2025 Open Dev Society
        </p>
    </td>
</tr>""";

# {{accent}} and {{priceColor}} are green for a price above its target and red for one below
glob ALERT: str = """<tr>
    <td class="mobile-padding" style="padding: 0 40px 20px 40px;">
        <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="background-color: {{accent}}; border-radius: 8px; padding: 20px;">
            <tr>
                <td align="center">
                    <h1 class="mobile-title" style="margin: 0 0 10px 0; font-size: 24px; font-weight: 700; color: #ffffff; line-height: 1.2;">{{heading}}</h1>
                    <p style="margin: 0; font-size: 16px; color: #ffffff; opacity: 0.9;">{{timestamp}}</p>
                </td>
            </tr>
        </table>
    </td>
</tr>
<tr>
    <td class="mobile-padding" style="padding: 0 40px 40px 40px;">
        <div class="dark-bg" style="text-align: center; padding: 30px 20px; background-color: #212328; border-radius: 8px; margin-bottom: 10px;">
            <h2 class="dark-text" style="margin: 0 0 10px 0; font-size: 28px; font-weight: 700; color: #ffffff;">{{symbol}}</h2>
            <p class="dark-text-muted" style="margin: 0 0 20px 0; font-size: 16px; color: #6b7280;">{{company}}</p>
            <div style="margin-bottom: 20px;">
                <p class="dark-text-muted" style="margin: 0 0 5px 0; font-size: 14px; color: #6b7280; text-transform: uppercase; letter-spacing: 0.5px;">{{currentPrice}}</p>
                <p class="mobile-price" style="margin: 0; font-size: 36px; font-weight: 700; color: {{priceColor}};">{{price}}</p>
            </div>
        </div>
        <div class="dark-info-box" style="background-color: #212328; border-radius: 8px; padding: 20px; margin-bottom: 30px;">
            <h3 class="dark-text" style="margin: 0 0 15px 0; font-size: 18px; font-weight: 600; color: #ffffff;">{{details}}</h3>
            <p class="mobile-text dark-text-secondary" style="margin: 0 0 10px 0; font-size: 16px; line-height: 1.5; color: #9ca3af;"><strong>{{targetPriceLabel}}</strong> {{target}}</p>
            <p class="mobile-text dark-text-secondary" style="margin: 0 0 10px 0; font-size: 16px; line-height: 1.5; color: #9ca3af;"><strong>{{triggerLabel}}</strong> {{trigger}}</p>
        </div>
        <div style="background-color: #050505; border: 1px solid #374151; border-radius: 8px; padding: 20px; margin-bottom: 30px;">
            <h3 style="margin: 0 0 8px 0; font-size: 18px; font-weight: 600; color: #E8BA40;">{{calloutTitle}}</h3>
            <p class="mobile-text" style="margin: 0; font-size: 14px; line-height: 1.5; color: #ccdadc;">{{calloutBody}}</p>
        </div>
        <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="margin-bottom: 30px;">
            <tr>
                <td align="center">
                    <a href="https://openstock-ods.vercel.app/" style="display: block; width: 100%; max-width: 100%; box-sizing: border-box; background-color: #E8BA40; color: #000000; text-decoration: none; padding: 16px 32px; border-radius: 8px; font-size: 16px; font-weight: 500; line-height: 1; text-align: center;">{{cta}}</a>
                </td>
            </tr>
        </table>
        <div style="text-align: center; margin: 40px 0 0 0;">
            <p style="margin: 0 0 10px 0; font-size: 14px; line-height: 1.5; color: #CCDADC !important;">{{footer}}</p>
            <p style="margin: 0 0 10px 0; font-size: 14px; line-height: 1.5; color: #CCDADC !important;">
                <a href="#" style="color: #CCDADC !important; text-decoration: underline;">{{unsubscribe}}</a> |
                <a href="https://openstock-ods.vercel.app/" style="color: #CCDADC !important; text-decoration: underline;">{{visitOpenstock}}</a>
            </p>
            <p style="margin: 0; font-size: 14px; line-height: 1.5; color: #CCDADC !important;">© 2025 Open Dev Society</p>
        </div>
    </td>
</tr>""";

# The weekly letter has a look of its own (teal). {{ unsubscribe_url }} is Kit's own token: Kit fills it per reader.
glob NEWS: str = """<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{{subject}}</title>
</head>
<body style="margin: 0; padding: 0; background-color: #000000; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;">
    <table role="presentation" width="100%" border="0" cellspacing="0" cellpadding="0" style="background-color: #000000; padding: 20px;">
        <tr>
            <td align="center">
                <div style="max-width: 600px; width: 100%; border: 2px dashed #20c997; border-radius: 4px; padding: 2px;">
                    <div style="background-color: #000000; padding: 30px 20px;">
                        <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 30px;">
                            <tr>
                                <td style="border-bottom: 1px dashed #333; padding-bottom: 20px;">
                                    <h2 style="margin: 0; font-size: 24px; font-weight: 700; color: #ffffff; display: flex; align-items: center;">
                                        <span style="color: #20c997; margin-right: 10px;">📊</span> OpenStock
                                    </h2>
                                </td>
                            </tr>
                        </table>
                        <div style="margin-bottom: 30px;">
                            <h1 style="margin: 0 0 10px 0; font-size: 28px; font-weight: 700; color: #ffffff; line-height: 1.2;">Weekly Market News</h1>
                            <p style="margin: 0; color: #888888; font-size: 16px;">{{date}}</p>
                        </div>
                        <div style="text-align: left;">{{summary}}</div>
                        <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-top: 40px; border-top: 1px dashed #333; padding-top: 20px;">
                            <tr>
                                <td align="center" style="color: #666666; font-size: 14px; line-height: 1.5;">
                                    <p style="margin: 0 0 10px 0;">You're receiving this email because you signed up for OpenStock.</p>
                                    <p style="margin: 0;">
                                        <a href="{{ unsubscribe_url }}" style="color: #20c997; text-decoration: underline;">Unsubscribe</a>
                                        <span style="margin: 0 10px;">•</span>
                                        <a href="https://openstock-ods.vercel.app" style="color: #20c997; text-decoration: underline;">Visit OpenStock</a>
                                    </p>
                                    <p style="margin: 20px 0 0 0; font-size: 12px;">&copy; {{year}} OpenStock</p>
                                </td>
                            </tr>
                        </table>
                    </div>
                </div>
            </td>
        </tr>
    </table>
</body>
</html>""";

# The AI writes the summary for the yellow in-app look; in order, each left side becomes its right for the letter
glob RESTYLE: list[tuple[str, str]] = [
    ("<h3", '<h3 style="color: #ffffff; margin-top: 30px; margin-bottom: 15px; font-size: 20px;"'),
    (
        '<div class="dark-info-box"',
        '<div style="background-color: #1e1e1e; padding: 20px; border-radius: 8px; margin-bottom: 25px;"',
    ),
    (
        "<h4",
        '<h4 style="color: #ffffff; margin-top: 0; margin-bottom: 15px; font-size: 18px; line-height: 1.4;"',
    ),
    ("<ul", '<ul style="padding-left: 0; list-style-type: none; margin: 0 0 15px 0;"'),
    (
        "<li",
        '<li style="margin-bottom: 12px; color: #cccccc; font-size: 16px; line-height: 1.6; display: flex;"',
    ),
    ('class="dark-text-secondary"', ""),
    (
        "•",
        '<span style="color: #20c997; font-weight: bold; margin-right: 10px; font-size: 18px;">•</span>',
    ),
    ('<strong style="color: #FDD458;">', '<strong style="color: #20c997;">'),
    ("<a ", '<a style="color: #20c997; text-decoration: none; font-weight: 600;" '),
];

"""Message copy is plain text; escaped before it goes into email HTML."""
def esc(text: str) -> str {
    return html.escape(text).replace("&#x27;", "&#39;");
}

"""One pass over the tokens, so a filled-in value (a name, AI text) can never expand another token. A token with no
value stays as it is."""
def fill(template: str, values: dict[str, str], token: str = r"\{\{(\w+)\}\}") -> str {
    return re.sub(
        token, lambda (m: re.Match) -> str { values.get(m.group(1), m.group(0)) }, template
    );
}

"""The language emails go out in for a locale (English for one we have none for) and its `Emails` messages, read
once from messages/<lang>.json: in the directory OPENSTOCK_MESSAGES names, else `messages` where the program runs,
else beside the program. Emails go out from jobs with no request to read a language from, so the caller passes it."""
def emails(locale: str) -> tuple[str, any] {
    lang = locale if locale in LOCALES else "en";
    if lang not in messages {
        beside = os.path.join(os.path.dirname(os.path.abspath(sys.argv[0])), "messages");
        folder = os.environ.get("OPENSTOCK_MESSAGES")
            or ("messages" if os.path.isdir("messages") else beside);
        with open(os.path.join(folder, f"{lang}.json"), encoding="utf-8") as f {
            messages[lang] = json.load(f)["Emails"];
        }
    }
    return (lang, messages[lang]);
}

"""A message of `group`, or of `common`, with its {placeholders} filled. With variants, the most specific that exists
wins: "title" with ["SmaAbove", "Above"] is titleSmaAbove, "heading" is headingAbove, "cta" is cta."""
def phrase(
    locale: str, group: str, name: str, values: dict[str, str] = {}, variants: list[str] = []
) -> str {
    said = emails(locale)[1];
    for g in [group, "common"] {
        for v in variants + [""] {
            if name + v in said[g] {
                return fill(said[g][name + v], values, r"\{(\w+)\}");
            }
        }
    }
    raise KeyError(f"Emails.{group}.{name}");
}

"""An email's HTML: the layout around `body`, each token filled from `given` (already HTML) or else with the escaped
message of that name."""
def page(
    locale: str,
    group: str,
    body: str,
    given: dict[str, str],
    values: dict[str, str] = {},
    variants: list[str] = [],
) -> str {
    template = SHELL.replace("{{body}}", body);
    given = given | {"lang": emails(locale)[0]};
    tokens: list[str] = re.findall(r"\{\{(\w+)\}\}", template);
    said = {
        k: esc(phrase(locale, group, k, values, variants))
        for k in set(tokens)
        if k not in given
    };
    return fill(template, said | given);
}

"""Gmail, as legacy's nodemailer `service: 'gmail'` did: one connection per letter."""
def smtp_send(to: str, subject: str, text: str, body: str) {
    user = os.environ["NODEMAILER_EMAIL"];
    msg = EmailMessage();
    (msg["From"], msg["To"], msg["Subject"]) = (f'"Openstock" <{user}>', to, subject);
    msg.set_content(text);
    msg.add_alternative(body, subtype="html");
    with smtplib.SMTP_SSL("smtp.gmail.com", 465, context=ssl.create_default_context()) as smtp {
        smtp.login(user, os.environ["NODEMAILER_PASSWORD"]);
        smtp.send_message(msg);
    }
}

"""Whether SMTP is set up; where it is not, the email is skipped with a warning and the sender answers False."""
def configured(what: str) -> bool {
    ready = bool(os.environ.get("NODEMAILER_EMAIL") and os.environ.get("NODEMAILER_PASSWORD"));
    if not ready {
        print(f"{what} email skipped: email credentials are not configured.", file=sys.stderr);
    }
    return ready;
}

"""The welcome intro is AI output from a prompt that includes sign-up fields, so it is untrusted HTML. Keep its text
and plain <strong>, drop every other tag (links, images, styles), and wrap it ourselves."""
def sanitize_intro(intro: str) -> str {
    # Keep the emphasis balanced, drop its attributes
    text = re.sub(r"<strong\b[^>]*>", "<strong>", intro, flags=re.I);
    text = re.sub(r"<(?!/?strong>)[^>]*>", "", text, flags=re.I);
    for (entity, char) in zip(["&nbsp;", "&quot;", "&#39;", "&lt;", "&gt;", "&amp;"], ' "\'<>&') {
        text = text.replace(entity, char);
    }
    safe = re.sub(r"&lt;(/?)strong&gt;", r"<\1strong>", esc(text.strip()), flags=re.I);
    return f'<p class="mobile-text" style="margin: 0 0 30px 0; font-size: 16px; line-height: 1.6; color: #CCDADC;">{safe}</p>';
}

"""False when skipped for want of SMTP settings."""
def send_welcome_email(email: str, name: str, intro: str, locale: str = "en") -> bool {
    if not configured("Welcome") {
        return False;
    }
    body = page(locale, "welcome", WELCOME, {"intro": sanitize_intro(intro)}, {"name": name});
    deliver(email, phrase(locale, "welcome", "subject"), phrase(locale, "welcome", "text"), body);
    return True;
}

"""Binance pairs are quoted in USDT, everything else Finnhub prices here is USD. Prices under a cent keep four
significant digits instead of rounding to $0.00."""
def money(symbol: str, value: float) -> str {
    if symbol.startswith("BINANCE:") {
        return f"{value:,.{6 if value < 1 else 2}f}".rstrip("0").rstrip(".") + " USDT";
    }
    if 0 < value < 0.01 {
        return "$" + f"{value:.{3 - math.floor(math.log10(value))}f}".rstrip("0");
    }
    return f"${value:,.2f}";
}

"""The alert email for a price past its target, or with sma_period for a cross of that moving average, which
`target` then is. False when skipped for want of SMTP settings."""
def send_alert_email(
    email: str,
    symbol: str,
    price: float,
    target: float,
    condition: str,
    sma_period: int = 0,
    locale: str = "en",
) -> bool {
    if not configured("Stock alert") {
        return False;
    }
    up = condition == "ABOVE";
    side = "Above" if up else "Below";
    # An SMA alert names the average in the subject, title, text and trigger; heading and callout stay shared
    variants = ([f"Sma{side}"] if sma_period else []) + [side];
    values = {
        "symbol": symbol,
        "price": money(symbol, price),
        "target": money(symbol, target),
        "period": str(sma_period),
    };
    say = lambda (name: str) -> str { phrase(locale, "stockAlert", name, values, variants) };
    now = datetime.now(timezone.utc);
    given = {k: esc(v) for (k, v) in values.items()} | {
        "timestamp": f"{now:%a, %b} {now.day}, {now:%Y, %I:%M %p} UTC",
        "company": "",  # alerts don't store the company name
        "accent": "#059669" if up else "#dc2626",
        "priceColor": "#10b981" if up else "#ef4444",
    };
    if sma_period {
        given["targetPriceLabel"] = esc(say("smaLabel"));
    }
    body = page(locale, "stockAlert", ALERT, given, values, variants);
    deliver(email, say("subject"), say("text"), body);
    return True;
}

"""The weekly letter around the AI's summary."""
def news_html(subject: str, date: str, summary: str) -> str {
    for (old, new) in RESTYLE {
        summary = summary.replace(old, new);
    }
    year = str(datetime.now(timezone.utc).year);
    return fill(NEWS, {"subject": subject, "date": date, "summary": summary, "year": year});
}
