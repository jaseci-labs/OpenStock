"""What an account must look like, shared by the forms and the server (no space holds this module)."""

# Onboarding choices; each value's label is the message Options.<group>.<message_key(value)>
glob PROFILE_OPTIONS: dict[str, list[str]] = {
    "investmentGoals": ["Growth", "Income", "Balanced", "Conservative"],
    "riskTolerance": ["Low", "Medium", "High"],
    "industries": ["Technology", "Healthcare", "Finance", "Energy", "Consumer Goods"],
};

def has_between(text: str, low: str, high: str) -> bool {
    return any([low <= c and c <= high for c in text]);
}

# Keyed by the message under Password.rules, in the order the checklist shows them
def password_checks(password: str) -> dict[str, bool] {
    return {
        "min8": len(password) >= 8,
        "upper": has_between(password, "A", "Z"),
        "lower": has_between(password, "a", "z"),
        "number": has_between(password, "0", "9"),
    };
}

def password_ok(password: str) -> bool {
    return all(password_checks(password).values());
}

def valid_email(email: str) -> bool {
    parts = email.split("@");
    if len(parts) != 2 or parts[0] == "" or any([c.isspace() for c in email]) {
        return False;
    }
    labels = parts[1].split(".");
    return len(labels) >= 2 and labels[0] != "" and len(labels[-1]) >= 2;
}

# The accounts plugin wants a username of 3-32 of a-z0-9._- that is never an email, so one is
# made from the address: its local part, and a hash of the whole so two domains never collide.
def username_for(email: str) -> str {
    address = email.strip().lower();
    local = "".join([
        c
        for c in address.split("@")[0]
        if c.isascii() and (c.isalnum() or c in "._-")
    ]).lstrip("._-");
    code = 7;
    for c in address {
        code = (code * 31 + ord(c)) % 2147483647;
    }
    return f"{local[:20] or 'user'}-{code}";
}

# The Errors.<key> message for a profile that cannot be saved, "" for one that can
def profile_problem(name: str, country: str, goal: str, risk: str, industry: str) -> str {
    if len(name.strip()) < 2 or len(name.strip()) > 80 {
        return "nameLength";
    }
    if len(country) != 2
        or not has_between(country[0], "A", "Z")
        or not has_between(country[1], "A", "Z")
    {
        return "pickCountry";
    }
    if goal not in PROFILE_OPTIONS["investmentGoals"]
        or risk not in PROFILE_OPTIONS["riskTolerance"]
        or industry not in PROFILE_OPTIONS["industries"]
    {
        return "pickEachOption";
    }
    return "";
}

test "password rules are the legacy four" {
    assert password_checks("") == {"min8": False, "upper": False, "lower": False, "number": False};
    assert password_checks("abcdefgh") == {
        "min8": True,
        "upper": False,
        "lower": True,
        "number": False,
    };
    assert not password_ok("Short1")
        and not password_ok("alllowercase1")
        and not password_ok("NoNumbers");
    assert password_ok("Passw0rdOk");
}

test "email shape" {
    for good in ["a@b.co", "first.last@mail.example.org"] {
        assert valid_email(good), good;
    }
    for bad in ["", "a", "a@b", "a@b.c", "a b@c.de", "@b.co", "a@@b.co", "a@.co"] {
        assert not valid_email(bad), bad;
    }
}

test "a username is derived from the email and fits the accounts plugin" {
    for email in [
        "Amy@Example.com",
        "a@b.co",
        "_.weird+tag@x.org",
        "ünï@x.org",
        "a-very-long-local-part-that-goes-on-and-on@example.com",
    ] {
        name = username_for(email);
        assert 3 <= len(name) and len(name) <= 32, name;
        assert "@" not in name and name[0].isalnum(), name;
        assert all([c.isdigit() or ("a" <= c and c <= "z") or c in "._-" for c in name]), name;
    }
    assert username_for("Amy@Example.com") == username_for(" amy@example.com ");
    assert username_for("amy@example.com") != username_for("amy@example.org");
    assert username_for("amy@example.com").startswith("amy-");
}

test "profile validation names the message to show" {
    assert profile_problem("Amy", "IN", "Growth", "Medium", "Technology") == "";
    assert profile_problem("A", "IN", "Growth", "Medium", "Technology") == "nameLength";
    assert profile_problem("Amy", "India", "Growth", "Medium", "Technology") == "pickCountry";
    assert profile_problem("Amy", "in", "Growth", "Medium", "Technology") == "pickCountry";
    assert profile_problem("Amy", "IN", "Moon", "Medium", "Technology") == "pickEachOption";
}
