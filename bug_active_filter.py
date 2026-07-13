#!/usr/bin/env python3
"""bug_active_filter.py — keep only "active" URLs for BUG Framework (mod_sqli).

Usage:
    bug_active_filter.py <input_file> <output_file> <concurrency>

Reads one URL per line from <input_file>, issues a lightweight HEAD/GET to
each, and writes the URLs that are reachable and NOT blocked by a WAF/security
filter (status 403/406/429/503) to <output_file>. <concurrency> controls the
number of parallel checks. Uses only the standard library.
"""
import concurrent.futures as cf
import os
import sys
import urllib.error
import urllib.request

UA = (
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/124.0 Safari/537.36"
)

# Treat these as "blocked" / not worth scanning.
BLOCKED = {403, 406, 429, 503}


def is_active(url: str) -> bool:
    req = urllib.request.Request(url, headers={"User-Agent": UA}, method="HEAD")
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            code = resp.getcode()
    except urllib.error.HTTPError as e:
        code = e.code
    except (urllib.error.URLError, ValueError, OSError):
        # Unreachable — treat as inactive so we don't waste sqlmap time.
        return False
    return code not in BLOCKED


def main() -> int:
    if len(sys.argv) < 4:
        sys.stderr.write(
            "usage: bug_active_filter.py <input_file> <output_file> <concurrency>\n"
        )
        return 2

    in_file, out_file, conc = sys.argv[1], sys.argv[2], sys.argv[3]
    try:
        workers = max(1, int(conc))
    except ValueError:
        workers = 10

    if not os.path.isfile(in_file):
        open(out_file, "w").close()
        return 0

    with open(in_file, "r", encoding="utf-8", errors="ignore") as fh:
        urls = []
        seen = set()
        for line in fh:
            u = line.strip()
            if u and u not in seen:
                seen.add(u)
                urls.append(u)

    active = []
    with cf.ThreadPoolExecutor(max_workers=workers) as ex:
        for url, ok in zip(urls, ex.map(is_active, urls)):
            if ok:
                active.append(url)

    with open(out_file, "w", encoding="utf-8") as fh:
        for u in active:
            fh.write(u + "\n")

    sys.stderr.write(f"[bug_active_filter] {len(active)}/{len(urls)} active URLs\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
