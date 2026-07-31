#!/usr/bin/env python3
# ══════════════════════════════════════════════════════════════════════════
# setup_bug.py — one-shot FIXER + INSTALLER for BUG FRAMEWORK v5.1
#   - repairs the 4 known bugs (stray redirect, macOS shims, html_esc, --install)
#   - installs every tool the framework needs (macOS/Linux aware)
#   - creates ~/bin/bug wrapper that runs the script under bash 5 (declare -A)
#   - verifies with `bash -n`
# Idempotent: safe to re-run any number of times.
# ══════════════════════════════════════════════════════════════════════════
import os, re, shutil, subprocess, sys

HOME = os.path.expanduser("~")
BUG_HINT = "BUG FRAMEWORK"

def log(msg, ok=True, icon=None):
    tag = "OK  " if ok else "WARN"
    print(f"  [{tag}] {msg}")

def run(cmd, live=False, timeout=None):
    """Run command; return (returncode, stdout)."""
    try:
        if live:
            subprocess.run(cmd, timeout=timeout)
            return 0, ""
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return r.returncode, r.stdout.strip()
    except FileNotFoundError:
        return 127, ""
    except subprocess.TimeoutExpired:
        return 124, ""

# ──────────────────────────────────────────────────────────────────────────
# 1. LOCATE THE BUG SCRIPT
# ──────────────────────────────────────────────────────────────────────────
def find_bug_script(argv):
    candidates = []
    if len(argv) > 1:
        candidates.append(os.path.abspath(argv[1]))
    candidates += [
        os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "bug")),
        os.path.abspath("bug"),
        os.path.join(HOME, "Bug-Framework", "bug"),
        os.path.join(HOME, "bug"),
    ]
    for c in candidates:
        if os.path.isfile(c):
            return c
    print("[FAIL] Could not find the 'bug' script.")
    print("       Usage: python3 setup_bug.py [path/to/bug]")
    sys.exit(1)

# ──────────────────────────────────────────────────────────────────────────
# 2. THE PATCHES (all idempotent, applied to a copy of the file)
# ──────────────────────────────────────────────────────────────────────────
SHIMS = r'''# ── macOS compat shims (added by setup_bug.py) ──
if [[ "$(uname -s)" == "Darwin" ]]; then
    command -v gtimeout >/dev/null 2>&1 && timeout() { gtimeout "$@"; }
    command -v ggrep    >/dev/null 2>&1 && grep()    { ggrep "$@"; }
    command -v gbase64  >/dev/null 2>&1 && base64()  { gbase64 "$@"; }
    md5sum() { if [[ $# -eq 0 ]]; then md5 -q; else md5 -q "$@"; fi; }
    date() { case "$*" in *%N*) python3 -c 'import time; print(int(time.time()*1e9))' ;; *) /bin/date "$@" ;; esac; }
fi
'''

HTML_ESC = r'''html_esc() {
    if [[ $# -gt 0 ]]; then printf '%s' "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g'
    else sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g'; fi
}'''

INSTALL_GUARD = r'''    if [[ "$(uname -s)" == "Darwin" ]]; then
        echo -e "[!] macOS detected - install tools with: python3 setup_bug.py (this --install is apt/Linux-only)"
        exit 0
    fi
'''

# wordlist paths: macOS has no /usr/share/seclists → point at ~/tools/wordlists
WL_PATCHES = [
    ('local WL_COMMON="/usr/share/wordlists/dirb/common.txt"',
     'local WL_COMMON="${HOME}/tools/wordlists/common.txt"'),
    ('local WL_RAFT="/usr/share/seclists/Discovery/Web-Content/raft-large-words.txt"',
     'local WL_RAFT="${HOME}/tools/wordlists/raft-large-words.txt"'),
    ('local WL_API="/usr/share/seclists/Discovery/Web-Content/api/api-endpoints.txt"',
     'local WL_API="${HOME}/tools/wordlists/api-endpoints.txt"'),
    ('local WL_MED="/usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt"',
     'local WL_MED="${HOME}/tools/wordlists/directory-list-2.3-medium.txt"'),
    ('local WL_FILES="/usr/share/seclists/Discovery/Web-Content/raft-small-files.txt"',
     'local WL_FILES="${HOME}/tools/wordlists/raft-small-files.txt"'),
    ('local PARAM_WL="/usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt"',
     'local PARAM_WL="${HOME}/tools/wordlists/burp-parameter-names.txt"'),
    ('[[ ! -f "$PARAM_WL" ]] && PARAM_WL="/usr/share/wordlists/dirb/common.txt"',
     '[[ ! -f "$PARAM_WL" ]] && PARAM_WL="${HOME}/tools/wordlists/common.txt"'),
]

def apply_patches(path):
    """Fix the bug script in place. Returns list of applied patch names."""
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        c = f.read()
    applied = []

    # PATCH A — stray `2>/dev/null; do` (the line-2631 syntax error)
    new, n = re.subn(r"^\s*2>/dev/null;\s*do\s*$", "        ; do", c, flags=re.M)
    if n:
        c = new
        applied.append(f"fixed stray '2>/dev/null; do' ({n} line{'s' if n != 1 else ''})")
    else:
        log("stray-redirect fix: pattern not found (already fixed?)", ok=False)

    # PATCH B — macOS compat shims after IFS=$'\n\t'
    if "# ── macOS compat shims" not in c:
        m = re.search(r"^IFS=\$'\\n\\t'$", c, flags=re.M)
        if m:
            c = c[:m.end()] + "\n\n" + SHIMS + c[m.end():]
            applied.append("inserted macOS compat shims (timeout/grep/base64/md5sum/date)")
        else:
            log("shims: IFS anchor line not found", ok=False)
    else:
        log("shims already present, skipping")

    # PATCH C — html_esc reads stdin OR argument
    if re.search(r"^html_esc\(\) \{", c, flags=re.M):
        c = re.sub(r"^html_esc\(\) \{.*$", HTML_ESC, c, count=1, flags=re.M)
        applied.append("replaced html_esc (stdin + argument support)")
    else:
        log("html_esc: pattern not found (already fixed?)", ok=False)

    # PATCH D — macOS guard for --install (apt-only)
    if "setup_bug.py (this --install" not in c:
        m = re.search(r"^install_tools\(\) \{", c, flags=re.M)
        if m:
            c = c[:m.end()] + "\n" + INSTALL_GUARD + c[m.end():]
            applied.append("guarded --install on macOS (points to setup_bug.py)")
        else:
            log("install_tools() guard: anchor not found", ok=False)
    else:
        log("--install guard already present, skipping")

    # PATCH E — wordlist paths → ~/tools/wordlists
    for old, new_l in WL_PATCHES:
        if old in c and new_l not in c:
            c = c.replace(old, new_l)
            applied.append(f"repointed wordlist: {new_l.split('/')[-1]}")

    with open(path, "w", encoding="utf-8") as f:
        f.write(c)
    return applied

# ──────────────────────────────────────────────────────────────────────────
# 3. BASH 5 LOCATION (needed for declare -A + process substitution)
# ──────────────────────────────────────────────────────────────────────────
def find_bash5():
    for p in ("/opt/homebrew/bin/bash", "/usr/local/bin/bash"):
        if os.path.exists(p):
            return p
    rc, out = run(["bash", "-c", "echo $BASH_VERSION"])
    if rc == 0 and out:
        try:
            major = int(out.split(".")[0])
            if major >= 4:
                return "bash"
        except ValueError:
            pass
    print("[WARN] bash 4+ not found. Run: brew install bash")
    return None

# ──────────────────────────────────────────────────────────────────────────
# 4. INSTALLATION
# ──────────────────────────────────────────────────────────────────────────
BREW_PKGS = ["bash", "coreutils", "grep", "jq", "nmap", "go", "xxd", "python3"]

GO_TOOLS = [
    ("subfinder",    "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"),
    ("httpx",        "github.com/projectdiscovery/httpx/cmd/httpx@latest"),
    ("nuclei",       "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"),
    ("katana",       "github.com/projectdiscovery/katana/cmd/katana@latest"),
    ("dnsx",         "github.com/projectdiscovery/dnsx/cmd/dnsx@latest"),
    ("alterx",       "github.com/projectdiscovery/alterx/cmd/alterx@latest"),
    ("naabu",        "github.com/projectdiscovery/naabu/v2/cmd/naabu@latest"),
    ("waybackurls",  "github.com/tomnomnom/waybackurls@latest"),
    ("gf",           "github.com/tomnomnom/gf@latest"),
    ("anew",         "github.com/tomnomnom/anew@latest"),
    ("qsreplace",    "github.com/tomnomnom/qsreplace@latest"),
    ("gau",          "github.com/lc/gau/v2/cmd/gau@latest"),
    ("dalfox",       "github.com/hahwul/dalfox/v2@latest"),
    ("hakrawler",    "github.com/hakluke/hakrawler@latest"),
    ("ffuf",         "github.com/ffuf/ffuf/v2@latest"),
    ("getJS",        "github.com/003random/getJS@latest"),
    ("amass",        "github.com/owasp-amass/amass/v4/...@master"),
    ("assetfinder",  "github.com/tomnomnom/assetfinder@latest"),
    ("gowitness",    "github.com/sensepost/gowitness@latest"),
]

PIP_PKGS = ["requests", "beautifulsoup4", "termcolor", "pycryptodome",
            "colorama", "waymore", "uro", "arjun", "dirsearch", "wafw00f",
            "git-dumper"]

WORDLISTS = {
    "common.txt":                    "Discovery/Web-Content/common.txt",
    "raft-large-words.txt":          "Discovery/Web-Content/raft-large-words.txt",
    "raft-small-files.txt":          "Discovery/Web-Content/raft-small-files.txt",
    "api-endpoints.txt":             "Discovery/Web-Content/api/api-endpoints.txt",
    "directory-list-2.3-medium.txt": "Discovery/Web-Content/directory-list-2.3-medium.txt",
    "burp-parameter-names.txt":      "Discovery/Web-Content/burp-parameter-names.txt",
}

def pip_install(pkg):
    rc, _ = run(["pip3", "install", "-q", pkg])
    if rc != 0:
        rc, _ = run(["pip3", "install", "-q", "--break-system-packages", pkg])
    return rc == 0

def install_brew():
    if not shutil.which("brew"):
        print("  [WARN] Homebrew not found - skipping brew installs.")
        return
    print("  [....] brew install:", " ".join(BREW_PKGS))
    run(["brew", "install", *BREW_PKGS], live=True)

def install_go_tools(gobin):
    for name, module in GO_TOOLS:
        if shutil.which(name):
            log(f"{name} already installed")
            continue
        print(f"  [....] go install {name} ...")
        rc, _ = run(["go", "install", module])
        log(f"{name} installed" if rc == 0 else f"{name} FAILED", ok=(rc == 0))

def install_pip():
    for pkg in PIP_PKGS:
        rc, _ = run(["pip3", "show", "-q", pkg])
        if rc == 0:
            log(f"{pkg} already installed")
            continue
        ok = pip_install(pkg)
        log(f"{pkg} installed" if ok else f"{pkg} FAILED", ok=ok)

def install_repos():
    repos = {
        "SecretFinder": "https://github.com/m4ll0k/SecretFinder.git",
        "LinkFinder":   "https://github.com/GerbenJavado/LinkFinder.git",
        "jwt_tool":     "https://github.com/ticarpi/jwt_tool.git",
    }
    tools_dir = os.path.join(HOME, "tools")
    os.makedirs(tools_dir, exist_ok=True)
    for name, url in repos.items():
        d = os.path.join(tools_dir, name)
        if os.path.isdir(d):
            log(f"{name} already cloned")
            continue
        rc, _ = run(["git", "clone", "-q", "--depth", "1", url, d])
        ok = rc == 0
        log(f"{name} cloned" if ok else f"{name} clone FAILED", ok=ok)
        if ok:
            req = os.path.join(d, "requirements.txt")
            if os.path.isfile(req):
                run(["pip3", "install", "-q", "-r", req])
                rc2, _ = run(["pip3", "install", "-q", "--break-system-packages", "-r", req])
                if rc2 != 0:
                    pass

def install_gf_patterns():
    gfd = os.path.join(HOME, ".gf")
    os.makedirs(gfd, exist_ok=True)
    if os.listdir(gfd):
        log("GF patterns already present")
        return
    run(["git", "clone", "-q", "https://github.com/1ndianl33t/Gf-Patterns.git", "/tmp/gfp"])
    run(["git", "clone", "-q", "https://github.com/tomnomnom/gf.git", "/tmp/gfsrc"])
    for src in ("/tmp/gfp", "/tmp/gfsrc/examples"):
        if os.path.isdir(src):
            for f in os.listdir(src):
                if f.endswith(".json"):
                    shutil.copy(os.path.join(src, f), os.path.join(gfd, f))
    log(f"GF patterns installed ({len(os.listdir(gfd))} files)")

def install_wordlists():
    wd = os.path.join(HOME, "tools", "wordlists")
    os.makedirs(wd, exist_ok=True)
    base = "https://raw.githubusercontent.com/danielmiessler/SecLists/master"
    for fname, rel in WORDLISTS.items():
        dst = os.path.join(wd, fname)
        if os.path.isfile(dst) and os.path.getsize(dst) > 1000:
            log(f"wordlist {fname} already present")
            continue
        rc, _ = run(["curl", "-fsSL", "-o", dst, f"{base}/{rel}"], timeout=180)
        ok = rc == 0 and os.path.getsize(dst) > 1000
        log(f"wordlist {fname} downloaded" if ok else f"wordlist {fname} FAILED", ok=ok)

def update_nuclei():
    if not shutil.which("nuclei"):
        log("nuclei not installed yet - skipping template update", ok=False)
        return
    if os.path.isdir(os.path.join(HOME, "nuclei-templates")):
        log("nuclei templates already present")
        return
    rc, _ = run(["nuclei", "-update-templates", "-silent"], timeout=600)
    log("nuclei templates updated" if rc == 0 else "nuclei template update FAILED", ok=(rc == 0))

# ──────────────────────────────────────────────────────────────────────────
# 5. WRAPPER + PATH
# ──────────────────────────────────────────────────────────────────────────
def setup_wrapper(bug_path, bash5):
    bindir = os.path.join(HOME, "bin")
    os.makedirs(bindir, exist_ok=True)
    wpath = os.path.join(bindir, "bug")
    wrapper = f'#!/usr/bin/env bash\nexec {bash5} "{bug_path}" "$@"\n'
    with open(wpath, "w") as f:
        f.write(wrapper)
    os.chmod(wpath, 0o755)
    os.chmod(bug_path, 0o755)
    log(f"wrapper created: {wpath} → exec {bash5} {bug_path}")

    zshrc = os.path.join(HOME, ".zshrc")
    line = f'export PATH="{bindir}:{HOME}/go/bin:$PATH"'
    if os.path.isfile(zshrc):
        with open(zshrc) as f:
            content = f.read()
        if line not in content:
            with open(zshrc, "a") as f:
                f.write("\n" + line + "\n")
            log(f"added PATH to {zshrc}")
        else:
            log("PATH already in .zshrc")
    else:
        with open(zshrc, "w") as f:
            f.write(line + "\n")
        log(f"created {zshrc} with PATH")

# ──────────────────────────────────────────────────────────────────────────
# 6. VERIFY
# ──────────────────────────────────────────────────────────────────────────
def verify(bug_path, bash5):
    print()
    print("  ── SYNTAX VERIFICATION ──")
    if bash5 is None:
        print("  [FAIL] No bash 4+ available - cannot verify. brew install bash")
        return False
    rc, out = run([bash5, "-n", bug_path])
    if rc == 0:
        print(f"  [OK  ] {bash5} -n {bug_path}  → clean, no syntax errors")
        return True
    print(f"  [FAIL] {bash5} -n {bug_path} → {out}")
    return False

# ──────────────────────────────────────────────────────────────────────────
# MAIN
# ──────────────────────────────────────────────────────────────────────────
def main():
    print()
    print("  ═══════════════════════════════════════════════════════")
    print("   BUG FRAMEWORK v5.1 — fixer + installer (setup_bug.py)")
    print("  ═══════════════════════════════════════════════════════")
    print()

    bug_path = find_bug_script(sys.argv)
    print(f"  Target script : {bug_path}")

    # backup once
    bak = bug_path + ".orig"
    if not os.path.exists(bak):
        shutil.copy(bug_path, bak)
        log(f"backup saved: {bak}")

    # 1. patches
    print()
    print("  ── PATCHING ──")
    applied = apply_patches(bug_path)
    for a in applied:
        log(a)
    if not applied:
        log("no patches needed - file already fixed", ok=False)

    bash5 = find_bash5()

    # 2. syntax check before touching anything else
    if not verify(bug_path, bash5):
        print("\n[FAIL] Syntax still broken - paste the error line above for a fix.")
        sys.exit(1)

    # 3. installs
    print()
    print("  ── INSTALLING ──")
    install_brew()

    # go
    if shutil.which("go"):
        rc, gopath = run(["go", "env", "GOPATH"])
        gobin = os.path.join(gopath if gopath else os.path.join(HOME, "go"), "bin")
        os.environ["PATH"] = f"{gobin}:" + os.environ.get("PATH", "")
        os.environ["GOBIN"] = gobin
        os.makedirs(gobin, exist_ok=True)
        install_go_tools(gobin)
    else:
        print("  [WARN] Go not found - skipping Go tool installs (brew install go first)")

    install_pip()
    install_repos()
    install_gf_patterns()
    install_wordlists()
    update_nuclei()

    # 4. wrapper + PATH
    print()
    print("  ── WRAPPER ──")
    if bash5:
        setup_wrapper(bug_path, bash5)

    # 5. final verify
    ok = verify(bug_path, bash5)

    print()
    print("  ═══════════════════════════════════════════════════════")
    print("   DONE. Summary:")
    print(f"    script  : {bug_path}")
    print(f"    backup  : {bug_path}.orig")
    print(f"    wrapper : ~/bin/bug  (run via:  source ~/.zshrc)")
    print("    wordlists: ~/tools/wordlists/ (6 files)")
    print("    tools    : ~/go/bin, ~/tools/ (SecretFinder, LinkFinder, jwt_tool)")
    print()
    if ok:
        print("   NEXT:  source ~/.zshrc  &&  bug -d example.com")
    else:
        print("   Syntax check FAILED - paste the error line for a targeted fix.")
    print("  ═══════════════════════════════════════════════════════")
    print()
    print("   Optional OOB:  export INTERACTSH_DOMAIN=your.oast.pro")
    print("   (SSRF/CMDi/XSS modules then auto-fire OOB callbacks to it)")
    print()

if __name__ == "__main__":
    main()
