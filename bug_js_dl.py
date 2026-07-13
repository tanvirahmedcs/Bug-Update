#!/usr/bin/env python3
"""bug_js_dl.py — download JavaScript files for BUG Framework (mod_js).

Usage:
    bug_js_dl.py <download_dir> <url_list_file>

Reads one JS URL per line from <url_list_file> and downloads each into
<download_dir> as <md5(url)>.js. Already-downloaded files are skipped so
re-runs are cheap. Uses only the standard library (no external deps).
"""
import hashlib
import os
import sys
import urllib.error
import urllib.request

UA = (
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/124.0 Safari/537.36"
)


def safe_name(url: str) -> str:
    return hashlib.md5(url.encode("utf-8")).hexdigest()[:16] + ".js"


def download(url: str, out_dir: str) -> bool:
    path = os.path.join(out_dir, safe_name(url))
    if os.path.exists(path) and os.path.getsize(path) > 0:
        return True
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            data = resp.read(5 * 1024 * 1024)  # cap 5 MB per file
        if not data:
            return False
        with open(path, "wb") as fh:
            fh.write(data)
        return True
    except (urllib.error.URLError, urllib.error.HTTPError, ValueError, OSError):
        return False


def main() -> int:
    if len(sys.argv) < 3:
        sys.stderr.write("usage: bug_js_dl.py <download_dir> <url_list_file>\n")
        return 2

    out_dir, url_file = sys.argv[1], sys.argv[2]
    os.makedirs(out_dir, exist_ok=True)

    if not os.path.isfile(url_file):
        return 0

    with open(url_file, "r", encoding="utf-8", errors="ignore") as fh:
        urls = [line.strip() for line in fh if line.strip()]

    ok = 0
    for url in urls:
        if download(url, out_dir):
            ok += 1
    sys.stderr.write(f"[bug_js_dl] downloaded {ok}/{len(urls)} JS files\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
