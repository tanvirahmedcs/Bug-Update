# Bug-Framework
Make it easy to hunt a BUG
# BUG — Bug Bounty Automation Framework v3.0

Aggressive recon-to-report automation. One command, full pipeline.

---

## Install

```bash
sudo bash install.sh
```

---

## Usage

```bash
bug -d example.com                    # Full aggressive scan
bug -d example.com -t 100             # 100 threads
bug -d example.com -p                 # Passive only
bug -d example.com -s                 # Skip tool check (faster re-run)
bug -d example.com -c your.oast.fun   # OOB callback for SSRF/blind XSS
bug -d example.com -o /tmp/results    # Custom output dir
```

Optional API key for more subdomain sources:
```bash
export SECTRAILS_KEY=your_key_here
bug -d example.com
```

---

## What It Runs (8 Phases)

### Phase 1 — Subdomains
subfinder (recursive, all sources) → assetfinder → crt.sh → RapidDNS →
SecurityTrails (if key set) → dnsx bruteforce → alterx permutations → amass passive
All merged and deduplicated.

### Phase 2 — Live Hosts
httpx on all subdomains, probing ports 80, 443, 8080, 8443, 8000, 8008, 8888, 3000,
5000, 9000, 4443. Groups by status code. nmap service scan. WhatWeb fingerprinting.

### Phase 3 — URL Harvesting
Wayback Machine → GAU (Wayback + OTX + URLScan + CommonCrawl) → CommonCrawl direct →
URLScan.io → Katana (active, JS-parsing, depth 5) → Gospider → Hakrawler
GF pattern matching splits all URLs into: xss, sqli, lfi, ssrf, ssti, idor, rce,
redirect, debug, interestingparams, upload, cors, aws-keys, jwt

### Phase 4 — JavaScript Analysis
Download all JS → LinkFinder on every file → regex secret hunting →
TruffleHog verified secrets → endpoint extraction → hardcoded IPs → internal hosts

### Phase 5 — Endpoint Discovery
FFUF dir + file fuzzing (raft-large + API wordlists + extensions) on all live hosts →
30+ common API path probes → Arjun hidden parameter discovery

### Phase 6 — Nuclei
Full template scan (low/medium/high/critical) + per-tag scans:
xss, sqli, lfi, rce, ssrf, idor, ssti, auth-bypass, cors, cve, exposure,
misconfig, takeover, default-login, weak-password, oast, graphql, jwt, api-key

### Phase 7 — Active Exploitation
- **XSS** — Dalfox with blind XSS support
- **SQLi** — sqlmap level 5, risk 3, all techniques
- **LFI** — 13 payloads including PHP wrappers
- **SSRF** — OOB injection + cloud metadata probes
- **CORS** — 4 origin variants
- **Open Redirect** — qsreplace injection
- **SSTI** — 6 template payloads
- **403 Bypass** — 9 headers + path tricks + method override
- **IDOR** — target identification from params + 401 hosts
- **JWT** — token extraction from all collected files

### Phase 8 — Report
Full Markdown report with all findings + tailored manual testing checklist
built from YOUR scan's discovered endpoints, 401 hosts, secrets, and confirmed vulns.

---

## Output Structure

```
~/bug-results/example.com/
├── 01-recon/
│   ├── live_hosts_full.txt    httpx full output (JSON)
│   ├── live_urls.txt          clean live URL list
│   ├── status_200.txt
│   ├── status_401.txt         ← IDOR/BAC targets
│   ├── status_403.txt         ← bypass candidates
│   ├── nmap.txt               service scan
│   └── whatweb.txt            tech fingerprints
├── 02-subdomains/
│   ├── subfinder.txt
│   ├── crtsh.txt
│   ├── amass.txt
│   └── all_subdomains.txt     ← merged unique
├── 03-urls/
│   ├── all_urls.txt
│   ├── urls_with_params.txt
│   ├── unique_params.txt
│   └── gf/                    ← xss.txt sqli.txt lfi.txt etc
├── 04-javascript/
│   ├── js_urls.txt
│   ├── files/                 downloaded JS
│   ├── endpoints_from_js.txt
│   ├── secrets_regex.txt      ← API keys, tokens
│   ├── trufflehog_verified.txt ← verified secrets
│   ├── hardcoded_ips.txt
│   └── internal_hosts.txt
├── 05-endpoints/
│   ├── known_paths.txt
│   ├── api_probe.txt
│   ├── ffuf_all.txt
│   └── arjun.txt
├── 06-vulnerabilities/
│   ├── xss_dalfox.txt
│   ├── lfi_confirmed.txt
│   ├── ssti.txt
│   ├── cors.txt
│   ├── open_redirect.txt
│   ├── 403_bypass.txt
│   ├── idor_targets.txt
│   ├── jwt_tokens.txt
│   ├── ssrf_hits.txt
│   └── sqlmap/
├── 07-nuclei/
│   ├── nuclei_all.txt
│   ├── nuclei_all.json
│   ├── cves.txt
│   ├── takeovers.txt
│   └── tag_*.txt              per-category
├── 08-report/
│   └── report.md              ← full report + checklist
└── logs/
    ├── bug.log
    ├── install.log
    └── *.log
```

---

## Tools Auto-Installed

| Tool | Purpose |
|------|---------|
| subfinder | Subdomain enumeration |
| assetfinder | Subdomain enumeration |
| amass | Subdomain enumeration |
| dnsx | DNS resolution + bruteforce |
| alterx | Subdomain permutations |
| httpx | Live host probing |
| katana | Active web crawler |
| waybackurls | Wayback Machine URLs |
| gau | Multi-source URL collection |
| gospider | Web spider |
| hakrawler | Web crawler |
| getJS | JS file discovery |
| LinkFinder | JS endpoint extraction |
| gf | Pattern-based URL filtering |
| ffuf | Directory/file fuzzing |
| arjun | Hidden parameter discovery |
| nuclei | Vuln scanning |
| dalfox | XSS scanner |
| sqlmap | SQL injection |
| trufflehog | Secret detection |
| qsreplace | URL parameter replacement |
| anew / unfurl | URL processing |
| interactsh-client | OOB callbacks |
| nmap | Port/service scan |
| whatweb | Tech fingerprinting |
| SecLists | Wordlists |

---

## Legal

Only use against targets you have explicit written permission to test.
Unauthorized use is illegal. The framework is for authorized bug bounty and pentesting only.
