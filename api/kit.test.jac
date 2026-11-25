glob sent: list[tuple[str, any]] = [],
     reply: tuple[int, any] = (200, {});

def fake_send(url: str, headers: dict[str, str], body: any, timeout: float) -> tuple[int, any] {
    sent.append((url, body));
    return reply;
}

def stub(status: int, data: any) {
    send = fake_send;
    reply = (status, data);
    sent.clear();
    os.environ.update({"KIT_API_KEY": "test-api-key", "KIT_API_SECRET": "test-api-secret"});
    os.environ.pop("KIT_WELCOME_FORM_ID", None);
}

def broadcast_error -> str {
    try {
        send_broadcast("Weekly news", "<p>Summary</p>");
        return "";
    } except RuntimeError as e {
        return str(e);
    }
}

test "a broadcast Kit saves as a draft is an error" {
    stub(
        422,
        {"message": "Broadcast was saved as a draft because your sender address is unconfirmed."},
    );
    assert "saved as a draft" in broadcast_error();
}

test "a confirmed broadcast gives Kit's reply unchanged" {
    stub(201, {"broadcast": {"id": 42}});
    assert send_broadcast("Weekly news", "<p>Summary</p>") == {"broadcast": {"id": 42}};
    (url, body) = sent[0];
    assert url == "https://api.convertkit.com/v3/broadcasts"
        and body["public"]
        and body["send_at"] > datetime.now(timezone.utc).isoformat();
    assert {k: v for (k, v) in body.items() if k not in ("public", "send_at")} == {
        "api_key": "test-api-key",
        "api_secret": "test-api-secret",
        "subject": "Weekly news",
        "content": "<p>Summary</p>",
    };
}

test "other Kit failures are errors that carry Kit's reply" {
    stub(401, {"message": "Invalid API key"});
    assert "Invalid API key" in broadcast_error() and "draft" not in broadcast_error();
}

test "a subscriber joins the given form, or the welcome form, or is skipped without one" {
    stub(200, {"subscription": {"id": 7}});
    assert add_subscriber("ann@example.com", "Ann") is None and not sent;
    os.environ["KIT_WELCOME_FORM_ID"] = "111";
    assert add_subscriber("ann@example.com", "Ann", {"ai_intro": "hi"}) == {
        "subscription": {"id": 7},
    };
    add_subscriber("bo@example.com", "Bo", form_id="222");
    assert sent == [
        (
            "https://api.convertkit.com/v3/forms/111/subscribe",
            {
                "api_key": "test-api-key",
                "email": "ann@example.com",
                "first_name": "Ann",
                "fields": {"ai_intro": "hi"},
            },
        ),
        (
            "https://api.convertkit.com/v3/forms/222/subscribe",
            {
                "api_key": "test-api-key",
                "email": "bo@example.com",
                "first_name": "Bo",
                "fields": {},
            },
        ),
    ];
}

test "subscribers are listed with the secret, and nothing is asked without both credentials" {
    stub(200, {"total_subscribers": 0, "subscribers": []});
    assert list_subscribers() == {"total_subscribers": 0, "subscribers": []};
    assert sent == [("https://api.convertkit.com/v3/subscribers?api_secret=test-api-secret", None)];
    os.environ.pop("KIT_API_SECRET");
    assert "KIT_API_KEY or KIT_API_SECRET" in broadcast_error() and len(sent) == 1;
}
