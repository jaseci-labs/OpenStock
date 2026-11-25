import os;

# The arguments and <tags> a message uses, at any depth of its plural and select branches
def message_args(text: str, found: set[str]) -> set[str] {
    i = 0;
    while i < len(text) {
        if text[i] == "<" and ">" in text[i:] and text[i + 1] != "/" {
            found.add(text[i:text.index(">", i) + 1]);
        } elif text[i] == "{" {
            depth = 0;
            end = i;
            for j in range(i, len(text)) {
                depth += 1 if text[j] == "{" else -1 if text[j] == "}" else 0;
                if depth == 0 {
                    end = j;
                    break;
                }
            }
            parts = text[i + 1:end].split(",", 2);
            found.add(parts[0].strip());
            if len(parts) == 3 {
                # Each branch is `key {text}`: the text is a message of its own
                message_args(" ".join(parts[2].replace("{", " {").split(" {")[1:]), found);
            }
            i = end;
        }
        i += 1;
    }
    return found;
}

def flat(tree: dict[str, any], prefix: str = "") -> dict[str, str] {
    out: dict[str, str] = {};
    for (key, value) in tree.items() {
        if isinstance(value, dict) {
            out.update(flat(value, f"{prefix}{key}."));
        } else {
            out[prefix + key] = str(value);
        }
    }
    return out;
}

def messages(code: str) -> dict[str, str] {
    with open(os.path.join("messages", f"{code}.json"), encoding="utf-8") as f {
        return flat(json.loads(f.read()));
    }
}

test "every locale has exactly the English keys" {
    base = sorted(messages("en"));
    assert len(base) > 300;
    for code in ["pl", "ar"] {
        assert sorted(messages(code)) == base, code;
    }
}

test "a translation keeps every argument English shows" {
    english = messages("en");
    assert message_args(english["SearchCommand.addingTo"], set()) == {"<name>", "list"};
    assert message_args(english["Sidebar.sponsorSlotsLeft"], set()) == {"count"};
    for code in ["pl", "ar"] {
        theirs = messages(code);
        for (key, text) in english.items() {
            lost = message_args(text, set()) - message_args(theirs[key], set());
            assert not lost, f"{code}:{key} lost {lost}";
        }
    }
}

test "a profile is saved once at sign-up, read back and updated" {
    # Saving sends the welcome email beside the call: with no keys it stops before any network
    for key in "GEMINI_API_KEY MINIMAX_API_KEY SIRAY_API_KEY KIT_API_KEY NODEMAILER_EMAIL".split() {
        os.environ.pop(key, None);
    }
    assert get_profile() == {};
    assert save_profile("Amy", "amy@example.com", "Mars", "Growth", "Medium", "Technology")
        == "signUpFailed";
    assert save_profile(" Amy Lee ", "Amy@Example.com", "IN", "Growth", "Medium", "Technology")
        == "";
    answers = dict(
        investmentGoals="Growth", riskTolerance="Medium", preferredIndustry="Technology"
    );
    assert get_profile() == dict(name="Amy Lee", email="amy@example.com", country="IN") | answers;
    assert save_profile("Amy", "amy@example.com", "IN", "Growth", "Medium", "Technology")
        == "signUpFailed", "only once";
    assert update_profile("A", "IN", "Growth", "Medium", "Technology") == "nameLength";
    assert update_profile("Amy L", "PL", "Income", "Low", "Consumer Goods") == "";
    assert get_profile()["country"] == "PL" and get_profile()["email"] == "amy@example.com";
    assert len([root --> [?:Profile]]) == 1 and [root --> [?:Profile]][0].locale == "en";
}
