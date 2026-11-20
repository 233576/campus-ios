import io
import json
import os
import sys
import urllib.error
import urllib.request
import zipfile

TOKEN = os.environ["ZF_GITHUB_TOKEN"]
AID = sys.argv[1]
OWNER, REPO = "233576", "campus-ios"

url = f"https://api.github.com/repos/{OWNER}/{REPO}/actions/artifacts/{AID}/zip"
req = urllib.request.Request(url, headers={"Authorization": "Bearer " + TOKEN, "User-Agent": "zf"})

class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *args, **kwargs):
        return None

opener = urllib.request.build_opener(NoRedirect)
try:
    opener.open(req, timeout=60)
    raise SystemExit("unexpected 200")
except urllib.error.HTTPError as exc:
    loc = exc.headers.get("Location")
    if not loc:
        raise SystemExit(f"no location, code={exc.code}")

data = urllib.request.urlopen(urllib.request.Request(loc, headers={"User-Agent": "zf"}), timeout=180).read()
path = os.path.join(os.environ["TEMP"], "campus_log.zip")
io.open(path, "wb").write(data)
with zipfile.ZipFile(path) as zf:
    for name in zf.namelist():
        text = zf.read(name).decode("utf-8", "replace")
        print("=== ", name, len(text))
        for line in text.splitlines():
            if "error:" in line or "BUILD FAILED" in line or "The following build commands failed" in line:
                print(line)
