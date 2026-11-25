import from "@jac/runtime" { __getLocalStorage, __setLocalStorage }
import from "../messages/en.json" { default as en }
import from "../messages/pl.json" { default as pl }
import from "../messages/ar.json" { default as ar }

glob LOCALES: list[str] = ["en", "pl", "ar"],
     # Each in its own language, so anyone can find theirs
     LOCALE_NAMES: dict[str, str] = {"en": "English", "pl": "Polski", "ar": "العربية"},
     MESSAGES: dict[str, any] = {"en": en, "pl": pl, "ar": ar},
     current: str = "";

# Saved choice first, then the browser's languages, then English
def detect -> str {
    saved = __getLocalStorage("openstock-locale") or "";
    for code in [saved] + [str(tag).lower().split("-")[0] for tag in navigator.languages] {
        if code in LOCALES {
            return code;
        }
    }
    return "en";
}

def:pub locale -> str {
    if current == "" {
        current = detect();
    }
    return current;
}

# web.jac listens for "localechange" and shows every page again in the new language
def:pub set_locale(code: str) {
    if code in LOCALES and code != locale() {
        current = code;
        __setLocalStorage("openstock-locale", code);
        window.dispatchEvent(new(Event, "localechange"));
    }
}

def:pub is_rtl(code: str) -> bool {
    return code == "ar";
}

def lookup(loc: str, key: str) -> any {
    found: any = MESSAGES[loc];
    for part in key.split(".") {
        if not found {
            return None;
        }
        found = found[part];
    }
    return found;
}

def closing(text: str, start: int) -> int {
    depth = 0;
    for i in range(start, len(text)) {
        if text[i] == "{" {
            depth += 1;
        } elif text[i] == "}" {
            depth -= 1;
            if depth == 0 {
                return i;
            }
        }
    }
    return len(text) - 1;
}

# The branch of `{n, plural, one {..} other {..}}` or `{x, select, a {..} other {..}}` for a value
def choose(loc: str, kind: str, value: any, options: str) -> str {
    picks: dict[str, str] = {};
    i = 0;
    while "{" in options[i:] {
        start = options.index("{", i);
        end = closing(options, start);
        picks[options[i:start].strip()] = options[start + 1:end];
        i = end + 1;
    }
    fallback = picks.get("other", "");
    if kind == "plural" {
        category = str(new(Intl.PluralRules, loc).select(value));
        return picks.get(f"={value}", picks.get(category, fallback));
    }
    return picks.get(str(value), fallback);
}

# ICU as the messages use it: {name}, plural with #, select; branches may nest
def fill(loc: str, text: str, vars: dict[str, any], count: str = "") -> str {
    out = "";
    i = 0;
    while i < len(text) {
        ch = text[i];
        if ch == "{" {
            end = closing(text, i);
            parts = text[i + 1:end].split(",", 2);
            name = parts[0].strip();
            value: any = vars.get(name, "{" + name + "}");
            if len(parts) == 3 {
                out += fill(loc, choose(loc, parts[1].strip(), value, parts[2]), vars, str(value));
            } else {
                out += str(value);
            }
            i = end;
        } elif ch == "#" and count != "" {
            out += count;
        } else {
            out += ch;
        }
        i += 1;
    }
    return out;
}

def:pub tr(loc: str, key: str, vars: dict[str, any] = {}) -> str {
    found = lookup(loc, key) or lookup("en", key);
    return fill(loc, str(found), vars) if found else key;
}

def:pub t(key: str, vars: dict[str, any] = {}) -> str {
    return tr(locale(), key, vars);
}

# A message with <tag>chunks</tag>: each tag's function turns its chunk into an element
def:pub rich(
    key: str, tags: dict[str, Callable[[str], any]], vars: dict[str, any] = {}
) -> list[any] {
    text = t(key, vars);
    out: list[any] = [];
    while "<" in text and ">" in text {
        start = text.index("<");
        name = text[start + 1:text.index(">", start)];
        stop = text.find(f"</{name}>");
        if stop < 0 or name not in tags {
            break;
        }
        out += [text[:start], tags[name](text[start + len(name) + 2:stop])];
        text = text[stop + len(name) + 3:];
    }
    return out + [text];
}

# Message keys for data titles: "Consumer Goods" -> "consumerGoods"
def:pub message_key(text: str) -> str {
    words = "".join([c if c.isalnum() else " " for c in text]).split();
    return "".join([
        w[0].lower() + w[1:] if i == 0 else w[0].upper() + w[1:]
        for (i, w) in enumerate(words)
    ]);
}
