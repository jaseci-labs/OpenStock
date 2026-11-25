"""Community links and the public paths, used across the app, landing page and emails."""

obj RepoStats {
    has stars: int,
        forks: int,
        license: str;
}

glob REPO_URL: str = "https://github.com/Open-Dev-Society/OpenStock";

# GitHub account that receives sponsorships. Switch to 'Open-Dev-Society' once the org's
# GitHub Sponsors listing is live (github.com/sponsors/Open-Dev-Society); every link follows.
glob SPONSOR_GITHUB_ACCOUNT: str = "ravixalgorithm",
     SPONSOR_URL: str = f"https://github.com/sponsors/{SPONSOR_GITHUB_ACCOUNT}",
     DISCORD_URL: str = "https://discord.gg/JkJ8kfxgxB",
     GOOD_FIRST_ISSUES_URL: str = f"{REPO_URL}/issues?q=is%3Aopen+label%3A%22good+first+issue%22";

# Exact paths the marketing site serves, plus the public SEO sections.
glob PUBLIC_EXACT_PATHS: list[str] = "/ /about /help /terms /api-docs /sponsor /love /changelog /s /compare".split();

"""GitHub's checkout with the amount and frequency ("recurring" or "one-time") already picked."""
def sponsor_checkout_url(amount: int = 0, frequency: str = "recurring") -> str {
    return f"{SPONSOR_URL}/sponsorships?frequency={frequency}"
        + (f"&amount={amount}" if amount else "");
}

# Prefix checks are whole segments: `/s` must not unlock `/stocks` or `/sponsor`.
def is_public_path(path: str) -> bool {
    return path in PUBLIC_EXACT_PATHS
        or path in ["/robots.txt", "/sitemap.xml"]
        or path.startswith(("/s/", "/compare/"));
}

"""1234 as "1.2K": compact, at most one decimal."""
def format_count(n: int) -> str {
    for (unit, size) in [("B", 1000000000), ("M", 1000000), ("K", 1000)] {
        if n >= size {
            return f"{round(n / size, 1):g}{unit}";
        }
    }
    return str(n);
}
