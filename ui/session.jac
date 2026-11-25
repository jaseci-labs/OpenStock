"""Signing in and out through the accounts plugin with the app's own forms, and who is signed in."""
import from "@jac/runtime" {
    RemoteError,
    RemoteRejected,
    __getLocalStorage,
    __removeLocalStorage,
    __setLocalStorage,
    navigate,
    sign_out,
}

glob user: dict[str, str] = {};

# The plugin's replies are its own English; these are the ones a form can say in the user's language
glob REFUSALS: dict[str, str] = {
    "incorrect username or password": "SignIn.invalidCredentials",
    "too many attempts: try again later": "Errors.tooManyAttempts",
    "this app mails no links": "Errors.resetEmailNotConfigured",
};

# POST /__jac/auth/<action>. A reply that carries a session is kept the way @jac/runtime keeps
# one (jac_token, jac_name), so every crossing after it is that caller's. Returns "" or why not.
async def:pub auth_post(action: str, body: dict[str, any]) -> str {
    try {
        reply = await (
            await fetch(f"/__jac/auth/{action}", {"method": "POST", "body": JSON.stringify(body)})
        ).json();
    } except Exception as e {
        return str(e);
    }
    if not reply.ok {
        detail = str(reply.detail);
        return t(REFUSALS[detail]) if detail in REFUSALS else detail;
    }
    if reply.data and reply.data.token {
        __setLocalStorage("jac_token", reply.data.token);
        if reply.data.name {
            __setLocalStorage("jac_name", reply.data.name);
        } else {
            __removeLocalStorage("jac_name");
        }
    }
    return "";
}

# What signing in takes here: `actions` (github and google among them where their keys are set)
# and `forgot`, "" where the app mails no reset links
async def:pub auth_ways -> any {
    return (await (await fetch("/__jac/auth/")).json()).data;
}

# Leave for GitHub or Google. What the plugin's return page reads is kept where it looks for it.
def:pub social_sign_in(action: any, back: str = "/dashboard") {
    sessionStorage.setItem("jac_sign_in", JSON.stringify({"keeps": action.keeps, "back": back}));
    location.assign(action.redirect);
}

def:pub has_session -> bool {
    return bool(__getLocalStorage("jac_token"));
}

# Reads the signed-in user (their profile's name, email, country, investmentGoals, riskTolerance,
# preferredIndustry) for me(); False for no one. An account made through GitHub or Google has
# no profile, and is called what that service calls it.
async def:pub load_user -> bool {
    user = {};
    if has_session() {
        try {
            profile: dict[str, str] = await get_profile();
            called = __getLocalStorage("jac_name") or "";
            user = {"name": called, "email": called if "@" in called else "", **profile};
        } except RemoteRejected {
            # The session ended elsewhere
            __removeLocalStorage("jac_token");
        } except RemoteError {}
    }
    window.dispatchEvent(new(Event, "userchange"));
    return len(user) > 0;
}

# The signed-in user as last loaded; {} for no one. Inside the app shell there always is one.
def:pub me -> dict[str, str] {
    return user;
}

async def:pub leave {
    await sign_out();
    user = {};
    window.dispatchEvent(new(Event, "userchange"));
    navigate("/sign-in");
}
