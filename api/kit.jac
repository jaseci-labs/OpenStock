"""The email list, kept in Kit (ConvertKit): subscribers and broadcasts."""
import json;
import os;
import sys;
import from datetime { datetime, timedelta, timezone }

glob API: str = "https://api.convertkit.com/v3",
     send: Callable[[str, dict[str, str], any, float], tuple[int, any]] = request_json;

def credentials -> tuple[str, str] {
    (key, secret) = (os.environ.get("KIT_API_KEY", ""), os.environ.get("KIT_API_SECRET", ""));
    if not key or not secret {
        raise RuntimeError(
            "KIT_API_KEY or KIT_API_SECRET is not defined in environment variables."
        );
    }
    return (key, secret);
}

"""Kit's reply to one call; an error reply is raised with its JSON as the message."""
def call(path: str, body: any = None) -> any {
    (status, data) = send(f"{API}/{path}", {}, body, 60.0);
    if not 200 <= status < 300 {
        print(f"Kit API error ({path.split('?')[0]}): {data}", file=sys.stderr);
        message = data.get("message") if isinstance(data, dict) else None;
        # Kit keeps a broadcast as a draft, and answers with an error, when the sender address is unconfirmed
        if isinstance(message, str) and "saved as a draft" in message {
            raise RuntimeError(f"Kit saved the broadcast as a draft: {message}");
        }
        raise RuntimeError(json.dumps(data));
    }
    return data;
}

"""Subscribe an email to a form (KIT_WELCOME_FORM_ID unless one is given); skipped, giving None, with no form."""
def add_subscriber(
    email: str, first_name: str, fields: dict[str, str] = {}, form_id: str = ""
) -> any {
    (key, _) = credentials();
    form = form_id or os.environ.get("KIT_WELCOME_FORM_ID", "");
    if not form {
        print("Skipping Kit subscription: No Form ID provided.", file=sys.stderr);
        return None;
    }
    return call(
        f"forms/{form}/subscribe",
        {"api_key": key, "email": email, "first_name": first_name, "fields": fields},
    );
}

"""Send `content` (HTML) to the whole list."""
def send_broadcast(subject: str, content: str) -> any {
    (key, secret) = credentials();
    # A minute ahead, so Kit has processed the broadcast before its send time
    send_at = (datetime.now(timezone.utc) + timedelta(minutes=1)).isoformat();
    return call(
        "broadcasts",
        {
            "api_key": key,
            "api_secret": secret,
            "subject": subject,
            "content": content,
            "public": True,
            "send_at": send_at,
        },
    );
}

"""Kit's subscriber page: total_subscribers, page, total_pages, subscribers."""
def list_subscribers -> any {
    return call(f"subscribers?api_secret={credentials()[1]}");
}
