#!/usr/bin/env bash
# ================================================================
#  BUG FRAMEWORK v5.1 — setup.sh (Kali/Debian/Ubuntu/macOS)
#  Idempotent installer: safe to re-run, skips what's present.
#
#  Usage:
#     chmod +x setup.sh
#     ./setup.sh          (asks for sudo if needed)
#
#  Log: /tmp/bug_setup.log
# ================================================================
set -u

LOG="/tmp/bug_setup.log"
: > "$LOG"
log()  { echo "[*] $*" | tee -a "$LOG"; }
ok()   { echo "[+] $*" | tee -a "$LOG"; }
warn() { echo "[!] $*" | tee -a "$LOG"; }
die()  { echo "[X] $*" | tee -a "$LOG"; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

OS="$(uname -s)"
SUDO=""
if [[ "$OS" == "Linux" && "$(id -u)" -ne 0 ]]; then
    have sudo || die "sudo required — re-run as root or with sudo"
    SUDO="sudo"
fi

# Go tools must land in the REAL user's GOPATH, not root's
REAL_USER="${SUDO_USER:-$(id -un)}"
REAL_HOME="$( { getent passwd "$REAL_USER" | cut -d: -f6; } 2>/dev/null || true )"
[[ -n "$REAL_HOME" ]] || REAL_HOME="$HOME"
GOPATH_DIR="$REAL_HOME/go"
GOTOOLS_BIN="$GOPATH_DIR/bin"
REAL_GROUP="$(id -gn "$REAL_USER" 2>/dev/null || echo "$REAL_USER")"

mkdir -p "$GOPATH_DIR/bin" "$REAL_HOME/.gf"
chown -R "$REAL_USER:$REAL_GROUP" "$GOPATH_DIR" "$REAL_HOME/.gf" 2>/dev/null || true

as_user() {
    if [[ -n "$SUDO_USER" ]]; then sudo -u "$REAL_USER" env HOME="$REAL_HOME" "$@"
    else env HOME="$REAL_HOME" "$@"; fi
}
as_user_go() {
    if [[ -n "$SUDO_USER" ]]; then
        sudo -u "$REAL_USER" env HOME="$REAL_HOME" GOPATH="$GOPATH_DIR" GOBIN="$GOTOOLS_BIN" PATH="$GOTOOLS_BIN:$PATH" "$@"
    else
        env HOME="$REAL_HOME" GOPATH="$GOPATH_DIR" GOBIN="$GOTOOLS_BIN" PATH="$GOTOOLS_BIN:$PATH" "$@"
    fi
}

BIN_DIR="$(cd "$(dirname "$0")" && pwd)"
BUG_SCRIPT="$BIN_DIR/bug"
section() { log "──────────────────── $* ────────────────────────"; }

# ── 1. apt packages ──────────────────────────────────────────────
install_apt() {
    section "apt packages"
    $SUDO apt-get update -qq 2>/dev/null || true
    $SUDO apt-get install -y -qq \
        curl jq dnsutils whois nmap git python3 python3-pip \
        libpcap-dev build-essential golang-go ffuf 2>&1 | tail -2 || true
    ok "apt packages done"
}

# ── 2. Go tools ──────────────────────────────────────────────────
install_go_tools() {
    section "Go tools"
    have go || die "golang missing after apt install — re-run or install golang-go"
    local -a TOOLS=(
        "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
        "github.com/projectdiscovery/httpx/cmd/httpx@latest"
        "github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
        "github.com/projectdiscovery/naabu/v2/cmd/naabu@latest"
        "github.com/projectdiscovery/katana/cmd/katana@latest"
        "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
        "github.com/tomnomnom/waybackurls@latest"
        "github.com/lc/gau/v2/cmd/gau@latest"
        "github.com/tomnomnom/gf@latest"
        "github.com/tomnomnom/unfurl@latest"
        "github.com/tomnomnom/qsreplace@latest"
        "github.com/lc/uro@latest"
        "github.com/hahwul/dalfox/v2@latest"
    )
    local tool name
    for tool in "${TOOLS[@]}"; do
        name="$(basename "$tool")"; name="${name%@*}"
        if command -v "$name" >/dev/null 2>&1 || [[ -x "$GOTOOLS_BIN/$name" ]]; then
            ok "  ✓ $name (present)"; continue
        fi
        log "  installing $name ..."
        if as_user_go go install "$tool" >/dev/null 2>&1; then ok "  ✓ $name"
        else warn "  ✗ $name failed"; fi
    done
}

# ── 3. pip tools ─────────────────────────────────────────────────
install_pip_tools() {
    section "pip tools"
    local t
    for t in sqlmap git-dumper interlace; do
        if have "$t"; then ok "  ✓ $t (present)"; continue; fi
        log "  installing $t ..."
        $SUDO pip3 install --break-system-packages "$t" >/dev/null 2>&1 \
            || $SUDO pip3 install "$t" >/dev/null 2>&1 \
            || warn "  ✗ $t failed (try: pip3 install $t)"
    done
}

# ── 4. gf patterns ───────────────────────────────────────────────
install_gf_patterns() {
    section "gf patterns"
    have gf || { warn "  gf not found — patterns skipped"; return; }
    as_user "$GOTOOLS_BIN/gf" -save >/dev/null 2>&1 || true
    local pat url
    for pat in debug_logic idor sqli ssrf xss redirect rce; do
        if [[ ! -s "$REAL_HOME/.gf/$pat.json" ]]; then
            url="https://raw.githubusercontent.com/1ndianl33t/Gf-Patterns/main/${pat}.json"
            as_user curl -s "$url" -o "$REAL_HOME/.gf/$pat.json" 2>/dev/null || true
        fi
        if [[ -s "$REAL_HOME/.gf/$pat.json" ]]; then ok "  ✓ $pat"
        else warn "  ✗ $pat"; fi
    done
}

# ── 5. wordlists ─────────────────────────────────────────────────
install_wordlists() {
    section "wordlists"
    $SUDO mkdir -p /usr/share/wordlists
    local f u
    while IFS=':' read -r f u; do
        if [[ -s "/usr/share/wordlists/$f" ]]; then ok "  ✓ $f"; continue; fi
        log "  $f ..."
        if $SUDO curl -sL "$u" -o "/usr/share/wordlists/$f" 2>/dev/null && [[ -s "/usr/share/wordlists/$f" ]]; then
            ok "  ✓ $f"
        else
            warn "  ✗ $f"; $SUDO rm -f "/usr/share/wordlists/$f"
        fi
    done <<'WL'
common.txt:https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt
raft-medium-directories.txt:https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/raft-medium-directories.txt
subdomains-top1million-5000.txt:https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-5000.txt
big.txt:https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/big.txt
WL
}

# ── 6. install the bug script ────────────────────────────────────
install_bug_script() {
    section "install bug script"
    [[ -f "$BUG_SCRIPT" ]] || die "bug script not found next to setup.sh ($BUG_SCRIPT)"
    bash -n "$BUG_SCRIPT" || die "SYNTAX ERROR in bug — fix before installing"
    $SUDO install -m 755 "$BUG_SCRIPT" /usr/local/bin/bug
    ok "installed /usr/local/bin/bug (bash -n passed)"
    for rc in "$REAL_HOME/.bashrc" "$REAL_HOME/.zshrc"; do
        [[ -f "$rc" ]] || continue
        grep -q 'go/bin' "$rc" 2>/dev/null \
            || echo 'export PATH="$PATH:$HOME/go/bin:$HOME/.local/bin"' >> "$rc"
    done
    ok "PATH exports added to .bashrc/.zshrc (open a new shell)"
}

# ── macOS branch ─────────────────────────────────────────────────
install_macos() {
    section "macOS (brew) dependencies"
    have brew || die "Homebrew required — https://brew.sh"
    brew list bash >/dev/null 2>&1 || brew install bash
    for p in coreutils gnu-grep jq ffuf nmap go; do
        brew list "$p" >/dev/null 2>&1 || brew install "$p"
    done
    ok "brew packages done"
    install_go_tools
    for t in sqlmap git-dumper interlace; do
        have "$t" && { ok "  ✓ $t (present)"; continue; }
        pip3 install --user --break-system-packages "$t" >/dev/null 2>&1 \
            || pip3 install --user "$t" >/dev/null 2>&1 \
            || warn "  ✗ $t failed"
    done
    install_gf_patterns
    mkdir -p "$REAL_HOME/bin"
    BASH5="$(brew --prefix bash 2>/dev/null)/bin/bash"
    printf '#!/usr/bin/env bash\nexec "%s" "%s" "$@"\n' "$BASH5" "$BUG_SCRIPT" > "$REAL_HOME/bin/bug"
    chmod +x "$REAL_HOME/bin/bug"
    ok "wrapper: $REAL_HOME/bin/bug"
    warn "XAMPP head shadow: sudo mv /Applications/XAMPP/xamppfiles/bin/head /Applications/XAMPP/xamppfiles/bin/head.lwp"
}

# ── verification ─────────────────────────────────────────────────
verify() {
    section "verification"
    local t
    for t in curl jq dig nmap ffuf subfinder httpx dnsx naabu katana \
             nuclei waybackurls gau gf unfurl qsreplace uro dalfox \
             sqlmap git-dumper interlace bug; do
        if command -v "$t" >/dev/null 2>&1 || [[ -x "$GOTOOLS_BIN/$t" ]] || [[ -x /usr/local/bin/$t ]]; then
            printf "  \xE2\x9C\x93 %-14s %s\n" "$t" "$(command -v "$t" 2>/dev/null || echo "$GOTOOLS_BIN/$t")"
        else
            printf "  \xE2\x9C\x97 %-14s MISSING\n" "$t"
        fi
    done
    echo ""
    warn "Any ✗ = re-run setup.sh (single failures are non-fatal)"
}

# ── main ─────────────────────────────────────────────────────────
main() {
    log "BUG FRAMEWORK v5.1 setup — $(date) — OS: $OS"
    case "$OS" in
        Linux)  install_apt; install_go_tools; install_pip_tools; install_gf_patterns
                install_wordlists; install_bug_script ;;
        Darwin) install_macos ;;
        *)      die "unsupported OS: $OS" ;;
    esac
    verify
    ok "setup complete — log: $LOG — first run: bug -d example.com"
}
main "$@"
