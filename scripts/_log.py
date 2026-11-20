import io
import json
import os
import re
import sys
import urllib.request

TOKEN = os.environ["ZF_GITHUB_TOKEN"]
OWNER = "233576"
REPO = "campus-ios"
RUN = sys.argv[1] if len(sys.argv) > 1 else ""


def api(path):
    req = urllib.request.Request(
        "https://api.github.com" + path,
        headers={
            "Authorization": "Bearer " + TOKEN,
            "Accept": "application/vnd.github+json",
            "User-Agent": "zf",
        },
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        return resp.read()


jobs = json.loads(api(f"/repos/{OWNER}/{REPO}/actions/runs/{RUN}/jobs"))["jobs"]
for job in jobs:
    print("=== job", job["name"], job["conclusion"])
    if job["conclusion"] != "failure":
        continue
    jid = job["id"]
    req = urllib.request.Request(
        f"https://api.github.com/repos/{OWNER}/{REPO}/actions/jobs/{jid}/logs",
        headers={"Authorization": "Bearer " + TOKEN, "User-Agent": "zf"},
    )
    try:
        with urllib.request.urlopen(req, timeout=90) as resp:
            text = resp.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as exc:
        loc = exc.headers.get("Location")
        if not loc:
            print("no log", exc.code)
            continue
        with urllib.request.urlopen(urllib.request.Request(loc, headers={"User-Agent": "zf"}), timeout=120) as r2:
            text = r2.read().decode("utf-8", "replace")
    io.open(os.path.join(os.environ["TEMP"], "campus_build.log"), "w", encoding="utf-8").write(text)
    for line in text.splitlines():
        if re.search(r"error:|warning: .*deprecated|The following build commands failed", line):
            print(line)
