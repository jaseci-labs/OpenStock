glob sent: list[tuple[str, dict[str, str], any]] = [],
     replies: dict[str, tuple[int, any]] = {};  # part of a URL: its reply, the first match wins

def fake_send(url: str, headers: dict[str, str], body: any, timeout: float) -> tuple[int, any] {
    sent.append((url, headers, body));
    for (part, reply) in replies.items() {
        if part in url {
            return reply;
        }
    }
    raise OSError("network failed");
}

"""Start from `env` alone for the provider variables, answering requests from `answers`."""
def stub(env: dict[str, str] = {}, answers: dict[str, tuple[int, any]] = {}) {
    for name in [
        "AI_PROVIDER",
        "GEMINI_API_KEY",
        "GEMINI_MODEL",
        "MINIMAX_API_KEY",
        "MINIMAX_MODEL",
        "MINIMAX_BASE_URL",
        "SIRAY_API_KEY",
    ] {
        os.environ.pop(name, None);
    }
    os.environ.update(env);
    send = fake_send;
    replies = answers;
    sent.clear();
}

def gemini_says(answer: str) -> tuple[int, any] {
    return (200, {"candidates": [{"content": {"parts": [{"text": answer}]}}]});
}

def chat_says(answer: str) -> tuple[int, any] {
    return (200, {"choices": [{"message": {"content": answer}}]});
}

def failure(prompt: str, name: str = "") -> str {
    try {
        return "answered: " + (ask_provider(prompt, name) if name else ask_ai(prompt));
    } except RuntimeError as e {
        return str(e);
    }
}

test "the provider defaults to gemini" {
    stub();
    assert provider()
        == Provider(
            name="gemini",
            api_key="",
            base_url="https://generativelanguage.googleapis.com/v1beta/models",
            model="gemini-2.5-flash-lite",
        );
    stub({"AI_PROVIDER": "nonsense"});
    assert provider().name == "gemini";
}

test "minimax and siray have their own settings and keys" {
    stub({"MINIMAX_API_KEY": "test-key", "SIRAY_API_KEY": "siray-key"});
    assert provider("minimax")
        == Provider(
            name="minimax",
            api_key="test-key",
            base_url="https://api.minimax.io/v1",
            model="MiniMax-M3.1-Flash",
        );
    assert provider("siray")
        == Provider(
            name="siray",
            api_key="siray-key",
            base_url="https://api.siray.ai/v1",
            model="siray-1.0-ultra",
        );
}

test "the environment replaces the gemini model and the minimax model and base URL, nothing of siray's" {
    stub({
        "MINIMAX_MODEL": "MiniMax-M2.5-highspeed",
        "MINIMAX_BASE_URL": "https://custom.minimax.example/v1",
        "GEMINI_MODEL": "gemini-2.0-flash",
        "SIRAY_MODEL": "other",
        "GEMINI_BASE_URL": "https://other.example",
    });
    assert (provider("minimax").model, provider("minimax").base_url)
        == ("MiniMax-M2.5-highspeed", "https://custom.minimax.example/v1");
    assert provider("gemini").model == "gemini-2.0-flash"
        and "googleapis" in provider("gemini").base_url;
    assert provider("siray").model == "siray-1.0-ultra";
    os.environ.pop("SIRAY_MODEL");
    os.environ.pop("GEMINI_BASE_URL");
}

test "AI_PROVIDER names the provider when none is given" {
    stub({"AI_PROVIDER": "minimax", "MINIMAX_API_KEY": "k"});
    assert provider().name == "minimax" and provider("siray").name == "siray";
}

test "gemini falls back to minimax, or to siray when only it has a key; the others to gemini" {
    stub({"MINIMAX_API_KEY": "k", "SIRAY_API_KEY": "s"});
    assert fallback_name("gemini") == "minimax";
    stub({"SIRAY_API_KEY": "s"});
    assert fallback_name("gemini") == "siray";
    stub();
    assert fallback_name("gemini") == "minimax";
    assert fallback_name("minimax") == "gemini" and fallback_name("siray") == "gemini";
}

test "a provider without its key is refused before any request" {
    stub();
    for name in ["gemini", "minimax", "siray"] {
        assert failure("hello", name) == f"{name.upper()}_API_KEY is not set";
    }
    assert not sent;
}

test "gemini is asked in its own format" {
    stub({"GEMINI_API_KEY": "test-gemini-key"}, {"": gemini_says("Hello from Gemini")});
    assert ask_provider("test prompt", "gemini") == "Hello from Gemini";
    assert sent == [
        (
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=test-gemini-key",
            {},
            {"contents": [{"role": "user", "parts": [{"text": "test prompt"}]}]},
        ),
    ];
}

test "siray is asked in the OpenAI-compatible format" {
    stub({"SIRAY_API_KEY": "test-siray-key"}, {"": chat_says("Hello from Siray")});
    assert ask_provider("test prompt", "siray") == "Hello from Siray";
    assert sent == [
        (
            "https://api.siray.ai/v1/chat/completions",
            {"Authorization": "Bearer test-siray-key"},
            {
                "model": "siray-1.0-ultra",
                "messages": [{"role": "user", "content": "test prompt"}],
                "temperature": 0.7,
            },
        ),
    ];
}

test "an error status and an empty answer are errors" {
    stub(
        {"GEMINI_API_KEY": "k", "MINIMAX_API_KEY": "k"},
        {"googleapis": (429, None), "": (200, {"choices": [{"message": {}}]})},
    );
    assert failure("hello", "gemini") == "gemini API error: 429";
    assert failure("hello", "minimax") == "minimax returned empty response";
    replies = {"": (200, {"candidates": []})};
    assert failure("hello", "gemini") == "gemini returned empty response";
}

# The email jobs call ask_ai with no provider. Exact equality of the request also guards against
# injecting parameters MiniMax does not support (thinking, reasoning_effort, service_tier...).
test "minimax requests keep the configured model and base URL, as the primary and as the fallback" {
    prompt = "Summarize this week's market news.";
    for base in ["", "https://api.minimaxi.com/v1", "https://custom.minimax.example/v1"] {
        for model in [
            "",
            "MiniMax-M3.1-Flash",
            "MiniMax-M3",
            "MiniMax-M2.5-highspeed",
            "custom-model",
        ] {
            env = {"MINIMAX_API_KEY": "test-minimax-key", "GEMINI_API_KEY": "test-primary-key"}
                | ({"MINIMAX_MODEL": model} if model else {})
                | ({"MINIMAX_BASE_URL": base} if base else {});
            expected = (
                f"{base or 'https://api.minimax.io/v1'}/chat/completions",
                {"Authorization": "Bearer test-minimax-key"},
                {
                    "model": model or "MiniMax-M3.1-Flash",
                    "messages": [{"role": "user", "content": prompt}],
                    "temperature": 0.7,
                },
            );
            answers = {"googleapis": (503, None), "": chat_says("MiniMax response")};
            stub(env | {"AI_PROVIDER": "minimax"}, answers);
            assert ask_ai(prompt) == "MiniMax response" and sent == [expected];
            stub(env, answers);
            got = ask_ai(prompt);
            assert got == "MiniMax response" and sent[1:] == [expected] and len(sent) == 2;
        }
    }
}

test "ask_ai falls back to gemini when the primary provider fails" {
    stub(
        {"AI_PROVIDER": "minimax", "MINIMAX_API_KEY": "k", "GEMINI_API_KEY": "g"},
        {"minimax": (500, None), "": gemini_says("Gemini fallback")},
    );
    assert ask_ai("test") == "Gemini fallback" and len(sent) == 2;
}

test "ask_ai falls back when the primary cannot be reached at all" {
    stub({"GEMINI_API_KEY": "g", "SIRAY_API_KEY": "s"}, {"siray": chat_says("Siray fallback")});
    assert ask_ai("test") == "Siray fallback" and len(sent) == 2;
}

test "ask_ai fails when both the primary and the fallback fail" {
    stub(
        {"AI_PROVIDER": "minimax", "MINIMAX_API_KEY": "k", "GEMINI_API_KEY": "g"}, {"": (500, None)}
    );
    assert failure("test") == "gemini API error: 500" and len(sent) == 2;
}
