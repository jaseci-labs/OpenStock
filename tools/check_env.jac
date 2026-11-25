"""Checks the environment (and a .env file here) against what OpenStock reads.

    neojac run tools/check_env.jac
"""
import os;
import sys;

glob FINNHUB: list[str] = ["FINNHUB_API_KEYS", "FINNHUB_API_KEY", "NEXT_PUBLIC_FINNHUB_API_KEY"],
     REQUIRED: dict[str, str] = {
         "BETTER_AUTH_URL": "Public URL of the app, e.g. http://localhost:8000 or https://your-domain.com",
     },
     OPTIONAL: str = """
NEXT_PUBLIC_OPENSTOCK_DATA_MODE|"cached" (default, hourly quotes) or "realtime" (every 15 s, with price alerts)
NODEMAILER_EMAIL|Gmail address for welcome and price-alert emails
NODEMAILER_PASSWORD|Gmail app password (not your regular password)
JAC_AUTH_ORIGIN|Where callers reach the app: needed for password-reset links and Google sign-in
JAC_MAIL_HOST|SMTP server for password-reset links
JAC_MAIL_SENDER|From address of those links
AI_PROVIDER|"gemini" (default), "minimax" or "siray"
GEMINI_API_KEY|Google Gemini key (welcome emails and news summaries)
GEMINI_MODEL|Gemini model override (default: gemini-2.5-flash-lite)
MINIMAX_API_KEY|MiniMax key (AI_PROVIDER=minimax, or the fallback)
MINIMAX_MODEL|MiniMax model override (default: MiniMax-M3.1-Flash)
MINIMAX_BASE_URL|MiniMax base URL override (default: https://api.minimax.io/v1)
SIRAY_API_KEY|Siray.ai key (AI_PROVIDER=siray, or the fallback)
ADANOS_API_KEY|Adanos key for the sentiment card
ADANOS_API_BASE_URL|Adanos base URL override (default: https://api.adanos.org)
ALPHAI_API_KEY|AlphAI key for the scored news card
KIT_API_KEY|Kit key (weekly news broadcast)
KIT_API_SECRET|Kit secret (weekly news broadcast)
KIT_WELCOME_FORM_ID|Kit form new users are subscribed to
SSO_GITHUB_CLIENT_ID|GitHub OAuth client ID (callback: <JAC_AUTH_ORIGIN>/__jac/auth/github)
SSO_GITHUB_CLIENT_SECRET|GitHub OAuth client secret
SSO_GOOGLE_CLIENT_ID|Google OAuth client ID (callback: <JAC_AUTH_ORIGIN>/__jac/auth/google)
SSO_GOOGLE_CLIENT_SECRET|Google OAuth client secret
""",
     # Read by the Next.js version only: safe to delete
     GONE: list[str] = "MONGODB_URI BETTER_AUTH_SECRET INNGEST_SIGNING_KEY INNGEST_EVENT_KEY MONGO_ROOT_PASSWORD FINNHUB_BASE_URL".split();

def dotenv(path: str = ".env") -> dict[str, str] {
    found: dict[str, str] = {};
    if os.path.exists(path) {
        with open(path) as f {
            for line in f {
                (name, eq, value) = line.strip().partition("=");
                if eq and not name.startswith("#") {
                    found[name.strip()] = value.strip().strip("'\"");
                }
            }
        }
    }
    return found;
}

# The lines to print, and whether every required variable is set
def check(env: dict[str, str]) -> tuple[list[str], bool] {
    isset = lambda (name: str) -> bool { env.get(name, "").strip() != "" };
    missing = [(n, d) for (n, d) in REQUIRED.items() if not isset(n)];
    if not any([isset(n) for n in FINNHUB]) {
        missing.append((" or ".join(FINNHUB), "Finnhub API key (free at finnhub.io)"));
    }
    total = len(REQUIRED) + 1;
    lines = [f"Summary: {total - len(missing)}/{total} required variables present"];
    lines += [f"  missing  {n}: {d}" for (n, d) in missing];
    for row in OPTIONAL.strip().splitlines() {
        (name, _, about) = row.partition("|");
        lines.append(f"  {'set    ' if isset(name) else 'unset  '}  {name}: {about}");
    }
    lines += [f"  unused   {n}: the app no longer reads it" for n in GONE if isset(n)];
    return (lines, not missing);
}

with entry:__main__ {
    (lines, ok) = check({**dotenv(), **dict(os.environ)});
    print("\n".join(lines));
    sys.exit(0 if ok else 1);
}

test "every Finnhub alias satisfies the key check" {
    for name in FINNHUB {
        (lines, ok) = check({"BETTER_AUTH_URL": "http://x", name: "k"});
        assert ok and lines[0] == "Summary: 2/2 required variables present";
    }
}

test "a missing Finnhub key lists its aliases" {
    (lines, ok) = check({"BETTER_AUTH_URL": "http://x"});
    assert not ok and lines[0].startswith("Summary: 1/2");
    assert "FINNHUB_API_KEYS or FINNHUB_API_KEY or NEXT_PUBLIC_FINNHUB_API_KEY" in lines[1];
}

test "nothing set reports every required check, and blank values do not count" {
    (lines, ok) = check({"BETTER_AUTH_URL": "  "});
    assert not ok and lines[0].startswith("Summary: 0/2") and "BETTER_AUTH_URL" in lines[1];
}

test "variables of the old stack are called out" {
    (lines, _) = check({"MONGODB_URI": "mongodb://x"});
    assert any(["MONGODB_URI" in line and "unused" in line for line in lines]);
}
