# 🐛 BUG Framework v5.0
### Professional Bug Bounty Recon & Detection Suite

> **⚡ AUTHORIZED & IN-SCOPE TARGETS ONLY — STRICTLY FOR BUG BOUNTY USE ⚡**
>
> Running this tool against targets without explicit written permission is illegal. The author assumes zero liability for unauthorized or illegal use.

---

## Overview

BUG Framework is a comprehensive, modular bash-based security testing suite designed for authorized bug bounty and penetration testing engagements. It automates the full recon-to-report pipeline, covering OWASP Top 10 vulnerabilities, IDOR, Broken Access Control, OAuth flaws, and more.

---

## Features

- Full subdomain enumeration from 10+ passive sources
- Live host probing with technology fingerprinting
- Deep URL collection (Wayback, GAU, Katana, Hakrawler, waymore)
- JavaScript analysis — secrets, DOM sinks, API base URLs, JWTs
- Directory & endpoint fuzzing with 403 bypass techniques
- WAF fingerprinting & bypass payload generation
- API schema discovery (OpenAPI/Swagger + GraphQL introspection)
- Automated vulnerability detection: XSS, SQLi, SSRF, LFI, CSRF, CORS
- IDOR & Broken Access Control classification engine
- OAuth/auth flow analysis (redirect_uri, state, PKCE, JWT alg:none)
- Parameter mutation fuzzing (SSTI, type confusion, hidden params, NoSQLi)
- Technology-specific checks (WordPress, Laravel, Spring Boot, Drupal)
- HTML + Markdown report generation with manual testing guide
- Resume capability, scope-file multi-domain scanning, proxy support

---

## Installation

```bash
# Install all required tools in one command
bug --install
```

This installs Go, all Go-based tools (subfinder, httpx, nuclei, katana, dalfox, ffuf, etc.), Python tools (sqlmap, arjun, waymore, dirsearch), SecretFinder, LinkFinder, jwt_tool, GF patterns, SecLists, and nuclei templates.

**Requirements:** Ubuntu/Debian Linux, `sudo` access, internet connection.

---

## Quick Start

```bash
# Full scan (recommended starting point)
bug -d example.com

# Fast scan — skips slow modules
bug -d example.com --quick

# Ultra-aggressive — max threads, deep wordlists
bug -d example.com --deep

# Authenticated scan (provide session cookie)
bug -d example.com --cookie "session=abc123"

# Route through Burp proxy
bug -d example.com --proxy http://127.0.0.1:8080
```

---

## Scan Modes

### Full Scan Modes

| Command | Description |
|---|---|
| `bug -d <domain>` | Full aggressive recon + detection (all modules) |
| `bug -d <domain> --quick` | Fast scan — skips slow/heavy modules |
| `bug -d <domain> --deep` | Ultra aggressive — max threads + deep wordlists |
| `bug -d <domain> --no-exploit` | Recon + detection only, no active fuzzing |
| `bug -d <domain> --resume` | Resume a stopped scan from last checkpoint |

### Recon Modes

| Command | Description |
|---|---|
| `bug -d <domain> -sub` | Subdomain enumeration only |
| `bug -d <domain> -one` | Single domain only (skip subdomain enum) |
| `bug -d <domain> -url` | URL collection only |
| `bug -d <domain> -we` | URL + endpoint discovery (fast combo) |
| `bug -d <domain> -js` | JavaScript analysis only |
| `bug -d <domain> -fuzz` | Directory bruteforce + 403 bypass |
| `bug -d <domain> -ports` | Port scan only (nmap) |
| `bug -scope <file>` | Scan multiple domains from a scope file |

### Detection Modes

| Command | Description |
|---|---|
| `bug -d <domain> -vuln` | Full detection scan |
| `bug -d <domain> -nuclei` | Nuclei only |
| `bug -d <domain> -xss` | XSS detection (dalfox) |
| `bug -d <domain> -sqli` | SQLi detection (sqlmap) |
| `bug -d <domain> -ssrf` | SSRF detection |
| `bug -d <domain> -lfi` | LFI detection |
| `bug -d <domain> -csrf` | CSRF + CORS detection |
| `bug -d <domain> -cors` | CORS misconfiguration only |
| `bug -d <domain> -idor` | IDOR + BAC classification |
| `bug -d <domain> -oauth` | OAuth/auth flow analysis |
| `bug -d <domain> -tech` | Technology-specific checks |
| `bug -d <domain> -waf` | WAF fingerprint + bypass profiling |
| `bug -d <domain> -api` | API schema discovery (OpenAPI/GraphQL) |
| `bug -d <domain> -pmf` | Parameter mutation fuzzing (SSTI/hidden/JSON) |

### Report

```bash
bug -d <domain> -report    # Regenerate HTML + Markdown report
```

---

## Options

| Option | Description |
|---|---|
| `--cookie <value>` | Session cookie for authenticated scans |
| `--header <value>` | Custom header (repeatable) |
| `--proxy <url>` | Route traffic through a proxy (e.g. Burp) |
| `--wordlist <file>` | Custom wordlist for fuzzing |
| `--threads <n>` | Override thread count |
| `--rate <n>` | Override requests per second |
| `--timeout <n>` | Override connection timeout (seconds) |
| `--silent` | Suppress verbose output, show findings only |
| `--no-banner` | Skip the ASCII art banner |

---

## Module Overview

The full scan runs 20+ modules in sequence:

| # | Module | What it does |
|---|---|---|
| 01 | Subdomain Enumeration | subfinder, crt.sh, assetfinder, amass, alterx, urlscan, HackerTarget, RapidDNS |
| 02 | Live Host Probing | httpx with status codes, tech detection, CDN, CNAME, IP, takeover candidates |
| 03 | URL Collection | waybackurls, gau, waymore, urlscan, katana (standard + headless), hakrawler, GF patterns |
| 04 | JS Analysis | getJS, LinkFinder, SecretFinder, DOM sink detection, JWT/key mining, postMessage |
| 05 | Path Discovery | ffuf, feroxbuster, API endpoint fuzzing, 403 bypass (16 techniques), Arjun |
| 06 | Port Scan | nmap top-1000 with service detection |
| 07 | Exposure Check | 80+ sensitive file/path checks (.env, .git, actuator, swagger, backups, etc.) |
| 08 | Nuclei | Full + DAST + CVE + misconfig + takeover scans |
| 09 | XSS | dalfox on GF-filtered URLs, CSP header audit |
| 10 | SQLi | sqlmap with live URL filtering and tamper scripts |
| 11 | SSRF | Cloud metadata payload injection, OOB detection |
| 12 | LFI | Path traversal, PHP wrappers, log poisoning candidates |
| 13 | CSRF | POST form token detection + PoC HTML file generation |
| 14 | CORS | 6-variant origin probe with credential detection |
| 15 | IDOR / BAC | Numeric ID / UUID extraction, privilege endpoint probing, method switching |
| 16 | OAuth | redirect_uri bypass, state/PKCE checks, JWT analysis, token-in-URL detection |
| WAF | WAF Fingerprinting | wafw00f, header signatures, payload probes, rate-limit threshold |
| API | API Schema | OpenAPI/Swagger discovery, GraphQL introspection + batch/depth probes |
| PMF | Param Mutation | SSTI, type confusion, hidden param fuzzing, JSON/NoSQLi mutation |
| 17 | Classifier | Smart IDOR/BAC/OAuth/Upload/Export/Payment/Webhook classification engine |
| 18 | Tech Checks | WordPress, Laravel, Spring Boot, Drupal-specific vulnerability checks |
| 19 | Screenshots | gowitness for visual recon of all live hosts |
| 20 | Report | HTML dashboard + Markdown report with manual testing guide |

---

## Workspace Structure

All output is saved to `~/bug-bounty/<domain>/`:

```
<domain>/
├── subdomains/          # All subdomain and live host data
├── urls/                # Collected URLs, GF-filtered lists, parameter data
│   └── gf/              # GF pattern outputs (xss, sqli, ssrf, lfi, redirect, idor)
├── js/                  # JavaScript files, secrets, DOM sinks, endpoints
│   └── downloaded/      # Downloaded JS files for offline analysis
├── paths/               # ffuf/feroxbuster results, 403 bypass hits
├── endpoints/           # Merged endpoint lists, interesting paths
├── params/              # Discovered parameters, Arjun output, type buckets
├── vulns/               # Vulnerability findings by type
│   ├── xss/
│   ├── sqli/
│   ├── ssrf/
│   ├── lfi/
│   ├── csrf/
│   ├── idor/
│   ├── nuclei/
│   └── misconfig/
├── classified/          # Smart-classified targets for manual testing
│   ├── idor/            # IDOR_PRIORITY.txt, IDOR_ALL.txt, sub-categories
│   ├── bac/             # BAC_PRIORITY.txt, BAC_ALL.txt, sub-categories
│   ├── oauth/           # OAUTH_PRIORITY.txt, OAUTH_ALL.txt
│   ├── upload/
│   ├── export/
│   ├── payment/
│   ├── webhook/
│   ├── debug/
│   ├── admin/
│   └── burp_imports/    # Ready-to-import URL lists for Burp Suite
├── screenshots/         # gowitness screenshots
├── reports/             # report.html + report.md
└── logs/master.log      # Full scan log
```

---

## After the Scan — Recommended Workflow

1. **Open the HTML report** — `xdg-open ~/bug-bounty/<domain>/reports/report.html`
2. **Triage critical/high Nuclei findings** — highest accuracy, start here
3. **Verify secrets in JS** — any valid key = instant critical report
4. **IDOR with Autorize in Burp** — load `IDOR_PRIORITY.txt`, swap session cookies between two accounts
5. **BAC** — load `BAC_PRIORITY.txt` with a low-privilege cookie via Match & Replace
6. **OAuth** — manual: `redirect_uri`, missing state, PKCE, JWT alg:none
7. **SSRF** — Burp Collaborator on `gf/ssrf.txt` URLs
8. **Validate XSS** — open dalfox results in browser to confirm
9. **CSRF PoC** — open generated HTML files while logged into the target
10. **Import to Burp** — load `classified/burp_imports/` URL lists + `params/all_params.txt` into Param Miner

---

## Key Output Files

| File | Contents |
|---|---|
| `reports/report.html` | Interactive HTML dashboard with all findings |
| `reports/report.md` | Markdown report for submission/notes |
| `classified/idor/IDOR_PRIORITY.txt` | Highest-priority IDOR test targets |
| `classified/bac/BAC_PRIORITY.txt` | Highest-priority BAC test targets |
| `classified/oauth/OAUTH_PRIORITY.txt` | OAuth endpoints and risk indicators |
| `classified/burp_imports/` | URL lists ready for Burp Suite import |
| `vulns/nuclei/nuclei_critical_high.txt` | Critical and high Nuclei findings |
| `vulns/nuclei/nuclei_cves.txt` | CVE-targeted findings |
| `vulns/nuclei/nuclei_takeover.txt` | Subdomain takeover candidates |
| `js/secrets_found.txt` | API keys, tokens, credentials found in JS |
| `js/aws_keys.txt` | AWS key candidates |
| `js/dom_xss_sinks.txt` | DOM XSS sink patterns |
| `paths/403_bypass.txt` | Confirmed 403 bypass results |
| `vulns/misconfig/sensitive_files.txt` | Exposed sensitive files |
| `params/all_params.txt` | All discovered parameter names |
| `params/params_by_type.txt` | Parameters grouped by type (ID, auth, nav, injection) |
| `urls/gf/` | GF-filtered URLs by vulnerability class |
| `logs/master.log` | Full verbose scan log |

---

## Tools Used

**Go:** subfinder, httpx, nuclei, katana, dnsx, alterx, naabu, waybackurls, gf, anew, qsreplace, gau, dalfox, hakrawler, ffuf, getJS, amass, assetfinder, gowitness

**Python:** sqlmap, arjun, waymore, uro, dirsearch, wafw00f, SecretFinder, LinkFinder, jwt_tool

**System:** nmap, curl, jq, git

**Wordlists:** SecLists (raft-large, directory-list-medium, api-endpoints, burp-parameter-names), GF Patterns

---

## Legal Notice

This tool is for **authorized security testing only**. You must have explicit written permission from the target organization before running any scan. Unauthorized use may violate computer fraud and abuse laws in your jurisdiction. The author assumes zero liability for misuse.

---

*BUG Framework v5.0 — IDOR · BAC · OAuth · XSS · SQLi · SSRF · LFI · CSRF · OWASP Top 10*
