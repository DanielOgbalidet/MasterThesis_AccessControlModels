from flask import Flask, request, Response
import requests
import os

app = Flask(__name__)

AUTH_MODE = os.getenv("AUTH_MODE", "rbac")
TEST_LEVEL = os.getenv("TEST_LEVEL", "level1")
OPA_URL = os.getenv("OPA_URL", "http://opa:8181/v1/data/authz/allow")


@app.route("/check", defaults={"path": ""}, methods=["GET", "POST"])
@app.route("/check/<path:path>", methods=["GET", "POST"])
def check(path):
    user_id = request.headers.get("x-user-id")
    action = request.headers.get("x-action")
    resource_id = request.headers.get("x-resource-id")

    # Optional level 4 context headers
    access_time = request.headers.get("x-time")
    location = request.headers.get("x-location")

    if not user_id or not action or not resource_id:
        return Response("missing headers", status=403)

    input_payload = {
        "user": user_id,
        "action": action,
        "resource": resource_id,
        "model": AUTH_MODE,
        "level": TEST_LEVEL
    }

    # Only include these if used when lvl 4
    if access_time:
        input_payload["time"] = access_time

    if location:
        input_payload["location"] = location

    payload = {
        "input": input_payload
    }

    try:
        r = requests.post(OPA_URL, json=payload, timeout=2)
    except Exception as e:
        print(f"OPA request failed: {e}", flush=True)
        return Response("auth backend exception", status=500)

    if r.status_code != 200:
        print(f"OPA error: {r.status_code} {r.text}", flush=True)
        return Response("auth backend error", status=500)

    try:
        allowed = r.json().get("result", False)
    except Exception as e:
        print(f"OPA parse error: {e}", flush=True)
        return Response("auth backend parse error", status=500)

    print(
        f"AUTH_MODE={AUTH_MODE}, TEST_LEVEL={TEST_LEVEL}, "
        f"user={user_id}, action={action}, resource={resource_id}, "
        f"time={access_time}, location={location}, allowed={allowed}",
        flush=True
    )

    if allowed:
        return Response("ok", status=200)

    return Response("forbidden", status=403)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=9000)