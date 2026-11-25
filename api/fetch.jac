"""The outbound HTTP requests the integrations share."""
import json;
import urllib.error;
import urllib.request;

"""GET, or POST `body` as JSON: (status, body text). An error status is returned, not raised, since the
APIs explain themselves in the body; a connection that fails or times out raises."""
def fetch_text(
    url: str, headers: dict[str, str] = {}, body: any = None, timeout: float = 60.0
) -> tuple[int, str] {
    data = None if body is None else json.dumps(body).encode();
    try {
        with urllib.request.urlopen(
            urllib.request.Request(url, data=data, headers=headers), timeout=timeout
        ) as resp {
            return (resp.status, resp.read().decode());
        }
    } except urllib.error.HTTPError as e {
        return (e.code, e.read().decode());
    }
}

"""fetch_text with the body decoded: None when it is not JSON."""
def request_json(
    url: str, headers: dict[str, str] = {}, body: any = None, timeout: float = 60.0
) -> tuple[int, any] {
    (status, raw) = fetch_text(url, {"Content-Type": "application/json"} | headers, body, timeout);
    try {
        return (status, json.loads(raw));
    } except ValueError {
        return (status, None);
    }
}
