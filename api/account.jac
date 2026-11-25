"""The signed-in caller's profile, and what the public header shows of the repository."""
import json;
import time;
import urllib.request;

# Onboarding answers live on the caller's own root; the accounts plugin keeps only the sign-in
node Profile {
    has name: str = "",
        email: str = "",
        country: str = "",
        investment_goals: str = "",
        risk_tolerance: str = "",
        preferred_industry: str = "";
}

glob stars: int = 0,
     stars_read: float = 0.0;

# Hook: the welcome email is connected here
def on_signed_up(profile: Profile) {}

def my_profile -> Profile | None {
    found = [root --> [?:Profile]];
    return found[0] if found else None;
}

def write(profile: Profile, name: str, country: str, goal: str, risk: str, industry: str) {
    profile.name = name.strip();
    profile.country = country;
    profile.investment_goals = goal;
    profile.risk_tolerance = risk;
    profile.preferred_industry = industry;
}

# Called once by the sign-up form, after the plugin made the account. Returns the Errors.<key>
# message of a refusal, or "". These answers go into the welcome email's prompt, so only the
# form's own values are taken.
def:protect save_profile(
    name: str,
    email: str,
    country: str,
    investment_goals: str,
    risk_tolerance: str,
    preferred_industry: str,
) -> str {
    problem = profile_problem(name, country, investment_goals, risk_tolerance, preferred_industry);
    if problem or not valid_email(email) or my_profile() is not None {
        return "signUpFailed";
    }
    profile = root ++> Profile(email=email.strip().lower());
    write(profile, name, country, investment_goals, risk_tolerance, preferred_industry);
    on_signed_up(profile);
    return "";
}

# {} for an account with no profile yet (one made through GitHub or Google)
def:protect get_profile -> dict[str, str] {
    profile = my_profile();
    if profile is None {
        return {};
    }
    return {
        "name": profile.name,
        "email": profile.email,
        "country": profile.country,
        "investmentGoals": profile.investment_goals,
        "riskTolerance": profile.risk_tolerance,
        "preferredIndustry": profile.preferred_industry,
    };
}

def:protect update_profile(
    name: str, country: str, investment_goals: str, risk_tolerance: str, preferred_industry: str
) -> str {
    problem = profile_problem(name, country, investment_goals, risk_tolerance, preferred_industry);
    if problem == "" {
        write(
            my_profile() or (root ++> Profile()),
            name,
            country,
            investment_goals,
            risk_tolerance,
            preferred_industry,
        );
    }
    return problem;
}

# The repository's star count for the public header, read from GitHub once a day; 0 hides it
def:pub repo_stars -> int {
    if time.time() - stars_read > 86400.0 {
        stars_read = time.time();
        try {
            with urllib.request.urlopen(
                "https://api.github.com/repos/Open-Dev-Society/OpenStock", timeout=4
            ) as reply {
                stars = int(json.loads(reply.read()).get("stargazers_count", 0));
            }
        } except Exception {}
    }
    return stars;
}
