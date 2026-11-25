"""The signed-in caller's profile."""
import json;

# Onboarding answers live on the caller's own root; the accounts plugin keeps only the sign-in
node Profile {
    has name: str = "",
        email: str = "",
        country: str = "",
        investment_goals: str = "",
        risk_tolerance: str = "",
        preferred_industry: str = "",
        locale: str = "en";  # the language emails to this caller go out in
}

# The welcome email goes out beside the call (send_welcome returns at once), in the language picked at sign-up
def on_signed_up(profile: Profile) {
    send_welcome(
        profile.email,
        profile.name,
        profile.country,
        profile.investment_goals,
        profile.risk_tolerance,
        profile.preferred_industry,
        profile.locale,
    );
}

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
    locale: str = "en",
) -> str {
    problem = profile_problem(name, country, investment_goals, risk_tolerance, preferred_industry);
    if problem or not valid_email(email) or my_profile() is not None {
        return "signUpFailed";
    }
    profile = root ++> Profile(email=email.strip().lower(), locale=locale);
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
