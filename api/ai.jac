"""Text from a language model: Gemini by default, MiniMax or Siray when AI_PROVIDER names one,
with a second provider tried when the first fails."""
import os;
import sys;

obj Provider {
    has name: str,
        api_key: str,
        base_url: str,
        model: str;
}

glob DEFAULTS: dict[str, dict[str, str]] = {
         "gemini": {
             "base_url": "https://generativelanguage.googleapis.com/v1beta/models",
             "model": "gemini-2.5-flash-lite",
         },
         "minimax": {"base_url": "https://api.minimax.io/v1", "model": "MiniMax-M3.1-Flash"},
         "siray": {"base_url": "https://api.siray.ai/v1", "model": "siray-1.0-ultra"},
     },
     # The only defaults the environment may replace; <NAME>_API_KEY is read for every provider.
     OVERRIDES: list[str] = ["GEMINI_MODEL", "MINIMAX_MODEL", "MINIMAX_BASE_URL"],
     TIMEOUT: float = 60.0,
     send: Callable[[str, dict[str, str], any, float], tuple[int, any]] = request_json;

"""The provider to use: the one named, else AI_PROVIDER, else gemini (also for an unknown name)."""
def provider(name: str = "") -> Provider {
    name = name or os.environ.get("AI_PROVIDER", "");
    name = name if name in DEFAULTS else "gemini";
    env = lambda (field: str) -> str { os.environ.get(f"{name}_{field}".upper(), "") };
    setting = lambda (field: str) -> str {
        (f"{name}_{field}".upper() in OVERRIDES and env(field)) or DEFAULTS[name][field]
    };
    return Provider(
        name=name, api_key=env("api_key"), base_url=setting("base_url"), model=setting("model")
    );
}

"""Who to try when `primary` fails: gemini, or from gemini whichever of minimax and siray has a key."""
def fallback_name(primary: str) -> str {
    if primary != "gemini" {
        return "gemini";
    }
    return "siray"
        if os.environ.get("SIRAY_API_KEY") and not os.environ.get("MINIMAX_API_KEY")
        else "minimax";
}

"""One provider's answer to a prompt. Gemini has its own REST shape; the others are OpenAI-compatible."""
def ask_provider(prompt: str, name: str = "") -> str {
    p = provider(name);
    if not p.api_key {
        raise RuntimeError(f"{p.name.upper()}_API_KEY is not set");
    }
    if p.name == "gemini" {
        (status, data) = send(
            f"{p.base_url}/{p.model}:generateContent?key={p.api_key}",
            {},
            {"contents": [{"role": "user", "parts": [{"text": prompt}]}]},
            TIMEOUT,
        );
    } else {
        (status, data) = send(
            f"{p.base_url}/chat/completions",
            {"Authorization": f"Bearer {p.api_key}"},
            {
                "model": p.model,
                "messages": [{"role": "user", "content": prompt}],
                "temperature": 0.7,
            },
            TIMEOUT,
        );
    }
    if not 200 <= status < 300 {
        raise RuntimeError(f"{p.name} API error: {status}");
    }
    try {
        answer: any = data["candidates"][0]["content"]["parts"][0]["text"]
            if p.name == "gemini"
            else data["choices"][0]["message"]["content"];
    } except (KeyError, IndexError, TypeError) {
        answer = None;
    }
    if not isinstance(answer, str) or not answer {
        raise RuntimeError(f"{p.name} returned empty response");
    }
    return answer;
}

"""The configured provider's answer, or the fallback provider's when that fails."""
def ask_ai(prompt: str) -> str {
    primary = provider().name;
    try {
        return ask_provider(prompt, primary);
    } except Exception as e {
        print(f"{primary} failed, switching to {fallback_name(primary)}: {e}", file=sys.stderr);
        return ask_provider(prompt, fallback_name(primary));
    }
}
