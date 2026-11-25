"""The one outbound JSON request the integrations share."""
import json;
import urllib.error;
import urllib.request;

"""GET, or POST `body` as JSON: (status, decoded body, None when it is not JSON). An error
status is returned, not raised, since the APIs explain themselves in the body; a connection
that fails or times out raises."""
def request_json(
    url: str, headers: dict[str, str] = {}, body: any = None, timeout: float = 60.0
) -> tuple[int, any] {
    req = urllib.request.Request(
        url,
        data=None if body is None else json.dumps(body).encode(),
        headers={"Content-Type": "application/json"} | headers,
    );
    try {
        with urllib.request.urlopen(req, timeout=timeout) as resp {
            (status, raw) = (resp.status, resp.read());
        }
    } except urllib.error.HTTPError as e {
        (status, raw) = (e.code, e.read());
    }
    try {
        return (status, json.loads(raw));
    } except ValueError {
        return (status, None);
    }
}
