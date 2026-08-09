#!/usr/bin/env bash

# ============================================================
# BUG FRAMEWORK v5.1 — setup.sh
# Parrot / Kali / Debian / Ubuntu Linux
# ============================================================

set -u

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

LOG="/tmp/bug_setup.log"
: > "$LOG"

log() {
    echo "[*] $*" | tee -a "$LOG"
}

ok() {
    echo -e "${GREEN}[+]${NC} $*" | tee -a "$LOG"
}

warn() {
    echo -e "${YELLOW}[!]${NC} $*" | tee -a "$LOG"
}

die() {
    echo -e "${RED}[X]${NC} $*" | tee -a "$LOG"
    exit 1
}

have() {
    command -v "$1" >/dev/null 2>&1
}

# ------------------------------------------------------------
# Environment
# ------------------------------------------------------------

OS="$(uname -s)"
SUDO=""

if [[ "$OS" == "Linux" && "$(id -u)" -ne 0 ]]; then
    have sudo || die "sudo is required. Install sudo or run as root."
    SUDO="sudo"
fi

REAL_USER="${SUDO_USER:-$(id -un)}"

if have getent; then
    REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"
else
    REAL_HOME="$HOME"
fi

[[ -n "$REAL_HOME" ]] || REAL_HOME="$HOME"

REAL_GROUP="$(id -gn "$REAL_USER" 2>/dev/null || echo "$REAL_USER")"

GOPATH_DIR="$REAL_HOME/go"
GOTOOLS_BIN="$GOPATH_DIR/bin"

PY_VENV="$REAL_HOME/.bug-venv"
PY_BIN="$PY_VENV/bin"

BIN_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$GOTOOLS_BIN"
mkdir -p "$REAL_HOME/.gf"

chown -R "$REAL_USER:$REAL_GROUP" \
    "$GOPATH_DIR" \
    "$REAL_HOME/.gf" \
    2>/dev/null || true

# ------------------------------------------------------------
# Run command as real user
# ------------------------------------------------------------

as_user() {
    if [[ -n "${SUDO_USER:-}" ]]; then
        sudo -u "$REAL_USER" \
            env HOME="$REAL_HOME" \
            "$@"
    else
        env HOME="$REAL_HOME" "$@"
    fi
}

as_user_go() {
    if [[ -n "${SUDO_USER:-}" ]]; then
        sudo -u "$REAL_USER" \
            env \
            HOME="$REAL_HOME" \
            GOPATH="$GOPATH_DIR" \
            GOBIN="$GOTOOLS_BIN" \
            PATH="$GOTOOLS_BIN:$PATH" \
            "$@"
    else
        env \
            HOME="$REAL_HOME" \
            GOPATH="$GOPATH_DIR" \
            GOBIN="$GOTOOLS_BIN" \
            PATH="$GOTOOLS_BIN:$PATH" \
            "$@"
    fi
}

# ------------------------------------------------------------
# Banner
# ------------------------------------------------------------

banner() {
    echo -e "${CYAN}"
    echo "██████╗ ██╗   ██╗ ██████╗     ███████╗██████╗  █████╗ ███╗   ███╗███████╗"
    echo "██╔══██╗██║   ██║██╔════╝     ██╔════╝██╔══██╗██╔══██╗████╗ ████║██╔════╝"
    echo "██████╔╝██║   ██║██║  ███╗    █████╗  ██████╔╝███████║██╔████╔██║█████╗"
    echo "██╔══██╗██║   ██║██║   ██║    ██╔══╝  ██╔══██╗██╔══██║██║╚██╔╝██║██╔══╝"
    echo "██████╔╝╚██████╔╝╚██████╔╝    ███████╗██║  ██║██║  ██║██║ ╚═╝ ██║███████╗"
    echo -e "${NC}"
    echo -e "${CYAN}Installing BUG FRAMEWORK...${NC}"
    echo
}

section() {
    log "──────────────────── $* ────────────────────────"
}

# ------------------------------------------------------------
# Locate BUG script
# ------------------------------------------------------------

BUG_SCRIPT=""

for candidate in \
    "$BIN_DIR/bug" \
    "$BIN_DIR/bug.sh"
do
    if [[ -f "$candidate" ]]; then
        BUG_SCRIPT="$candidate"
        break
    fi
done

[[ -n "$BUG_SCRIPT" ]] || \
    die "BUG script not found next to setup.sh."

# ------------------------------------------------------------
# APT packages
# ------------------------------------------------------------

install_apt() {
    section "APT packages"

    [[ "$OS" == "Linux" ]] || return 0

    log "Updating APT..."

    $SUDO apt-get update -qq \
        >> "$LOG" 2>&1 || \
        warn "APT update returned an error."

    log "Installing dependencies..."

    $SUDO apt-get install -y \
        curl \
        jq \
        dnsutils \
        whois \
        nmap \
        git \
        python3 \
        python3-pip \
        python3-venv \
        libpcap-dev \
        build-essential \
        golang-go \
        ffuf \
        sqlmap \
        pipx \
        >> "$LOG" 2>&1 || \
        warn "Some APT packages could not be installed."

    ok "APT packages finished"
}

# ------------------------------------------------------------
# Go tools
# ------------------------------------------------------------

install_go_tools() {
    section "Go tools"

    have go || die "Go is missing."

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
        "github.com/hahwul/dalfox/v2@latest"
    )

    local tool
    local module_path
    local name

    for tool in "${TOOLS[@]}"; do

        module_path="${tool%@*}"
        name="${module_path##*/}"

        if [[ "$name" == "v2" ]]; then
            name="dalfox"
        fi

        if command -v "$name" >/dev/null 2>&1 || \
           [[ -x "$GOTOOLS_BIN/$name" ]]; then

            ok "$name already installed"
            continue
        fi

        log "Installing $name..."

        if as_user_go go install "$tool" >> "$LOG" 2>&1; then
            ok "$name installed"
        else
            warn "$name installation failed"
            warn "See $LOG"
        fi
    done
}

# ------------------------------------------------------------
# Python virtual environment
# ------------------------------------------------------------

setup_python_venv() {
    section "Python virtual environment"

    have python3 || die "python3 is missing."

    if [[ ! -x "$PY_BIN/python" ]]; then

        log "Creating Python venv:"
        log "$PY_VENV"

        if ! as_user python3 -m venv "$PY_VENV" >> "$LOG" 2>&1; then
            die "Could not create Python virtual environment."
        fi

        chown -R "$REAL_USER:$REAL_GROUP" \
            "$PY_VENV" \
            2>/dev/null || true

        ok "Python venv created"

    else
        ok "Python venv already exists"
    fi

    if ! as_user "$PY_BIN/python" -m pip install \
        --upgrade pip setuptools wheel \
        >> "$LOG" 2>&1; then

        warn "Could not upgrade pip/setuptools/wheel."
    fi

    ok "Python environment ready"
}

# ------------------------------------------------------------
# Python tools
# ------------------------------------------------------------

install_python_tools() {
    section "Python tools"

    setup_python_venv

    local -a PY_TOOLS=(
        uro
        git-dumper
    )

    local tool

    for tool in "${PY_TOOLS[@]}"; do

        if [[ -x "$PY_BIN/$tool" ]]; then
            ok "$tool already installed"
            continue
        fi

        log "Installing $tool..."

        if as_user "$PY_BIN/python" -m pip install \
            --upgrade "$tool" \
            >> "$LOG" 2>&1; then

            ok "$tool installed"

        else
            warn "$tool installation failed"
            warn "See $LOG"
        fi
    done

    if have sqlmap; then
        ok "sqlmap installed"
    elif [[ -x "$PY_BIN/sqlmap" ]]; then
        ok "sqlmap installed in venv"
    else
        warn "sqlmap missing"
    fi
}

# ------------------------------------------------------------
# GF patterns
# ------------------------------------------------------------

install_gf_patterns() {
    section "gf patterns"

    local gf_bin="$GOTOOLS_BIN/gf"

    if [[ ! -x "$gf_bin" ]] && ! have gf; then
        warn "gf not found — skipping patterns"
        return 0
    fi

    local pattern_repo
    pattern_repo="https://raw.githubusercontent.com/1ndianl33t/Gf-Patterns/main"

    local pat
    local url

    for pat in \
        debug_logic \
        idor \
        sqli \
        ssrf \
        xss \
        redirect \
        rce
    do

        if [[ -s "$REAL_HOME/.gf/$pat.json" ]]; then
            ok "gf pattern: $pat"
            continue
        fi

        url="$pattern_repo/$pat.json"

        log "Downloading gf pattern: $pat"

        if as_user curl -fsSL \
            "$url" \
            -o "$REAL_HOME/.gf/$pat.json" \
            >> "$LOG" 2>&1; then

            ok "gf pattern: $pat"

        else
            warn "gf pattern unavailable: $pat"
            rm -f "$REAL_HOME/.gf/$pat.json"
        fi
    done

    chown -R "$REAL_USER:$REAL_GROUP" \
        "$REAL_HOME/.gf" \
        2>/dev/null || true
}

# ------------------------------------------------------------
# Wordlists
# ------------------------------------------------------------

install_wordlists() {
    section "Wordlists"

    $SUDO mkdir -p /usr/share/wordlists

    local f
    local u

    while IFS='|' read -r f u; do

        [[ -z "$f" ]] && continue

        if [[ -s "/usr/share/wordlists/$f" ]]; then
            ok "wordlist: $f"
            continue
        fi

        log "Downloading wordlist: $f"

        if $SUDO curl -fsSL \
            "$u" \
            -o "/usr/share/wordlists/$f" \
            >> "$LOG" 2>&1; then

            if [[ -s "/usr/share/wordlists/$f" ]]; then
                ok "wordlist: $f"
            else
                warn "wordlist empty: $f"
                $SUDO rm -f "/usr/share/wordlists/$f"
            fi

        else
            warn "wordlist failed: $f"
            $SUDO rm -f "/usr/share/wordlists/$f"
        fi

    done <<'WORDLISTS'
common.txt|https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt
raft-medium-directories.txt|https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/raft-medium-directories.txt
subdomains-top1million-5000.txt|https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-5000.txt
big.txt|https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/big.txt
WORDLISTS
}

# ------------------------------------------------------------
# Install BUG command
# ------------------------------------------------------------

install_bug_script() {
    section "BUG command"

    [[ -f "$BUG_SCRIPT" ]] || \
        die "BUG script not found."

    log "Checking BUG script syntax..."

    if ! bash -n "$BUG_SCRIPT" >> "$LOG" 2>&1; then
        die "Syntax error in $(basename "$BUG_SCRIPT")."
    fi

    $SUDO install \
        -m 755 \
        "$BUG_SCRIPT" \
        /usr/local/bin/bug

    ok "bug installed at /usr/local/bin/bug"
}

# ------------------------------------------------------------
# PATH
# ------------------------------------------------------------

configure_path() {
    section "PATH configuration"

    local rc

    for rc in \
        "$REAL_HOME/.bashrc" \
        "$REAL_HOME/.zshrc"
    do

        [[ -f "$rc" ]] || continue

        if ! grep -q 'BUG_FRAMEWORK_PATH' "$rc" 2>/dev/null; then

            cat >> "$rc" <<'PATH_BLOCK'

# BUG_FRAMEWORK_PATH
export PATH="$HOME/go/bin:$HOME/.bug-venv/bin:$HOME/.local/bin:$PATH"
PATH_BLOCK

            ok "PATH updated: $rc"

        else
            ok "PATH already configured: $rc"
        fi
    done

    export PATH="$GOTOOLS_BIN:$PY_BIN:$REAL_HOME/.local/bin:$PATH"
}

# ------------------------------------------------------------
# Verification
# ------------------------------------------------------------

verify_command() {
    local name="$1"

    if command -v "$name" >/dev/null 2>&1; then
        printf "  ${GREEN}✓${NC} %-18s %s\n" \
            "$name" \
            "$(command -v "$name")"
        return 0
    fi

    if [[ -x "$GOTOOLS_BIN/$name" ]]; then
        printf "  ${GREEN}✓${NC} %-18s %s\n" \
            "$name" \
            "$GOTOOLS_BIN/$name"
        return 0
    fi

    if [[ -x "$PY_BIN/$name" ]]; then
        printf "  ${GREEN}✓${NC} %-18s %s\n" \
            "$name" \
            "$PY_BIN/$name"
        return 0
    fi

    if [[ -x "/usr/local/bin/$name" ]]; then
        printf "  ${GREEN}✓${NC} %-18s %s\n" \
            "$name" \
            "/usr/local/bin/$name"
        return 0
    fi

    printf "  ${RED}✗${NC} %-18s MISSING\n" "$name"
    return 1
}

verify() {
    section "Verification"

    local failed=0
    local tool

    for tool in \
        curl \
        jq \
        dig \
        nmap \
        ffuf \
        subfinder \
        httpx \
        dnsx \
        naabu \
        katana \
        nuclei \
        waybackurls \
        gau \
        gf \
        unfurl \
        qsreplace \
        uro \
        dalfox \
        sqlmap \
        git-dumper \
        bug
    do
        verify_command "$tool" || failed=1
    done

    echo

    if [[ "$failed" -eq 0 ]]; then
        ok "All requested tools are available."
    else
        warn "Some tools are missing."
        warn "Check $LOG for details."
    fi
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

main() {

    banner

    log "BUG FRAMEWORK v5.1 setup"
    log "Date: $(date)"
    log "User: $REAL_USER"
    log "Home: $REAL_HOME"
    log "OS: $OS"

    case "$OS" in

        Linux)
            install_apt
            install_go_tools
            install_python_tools
            install_gf_patterns
            install_wordlists
            configure_path
            install_bug_script
            ;;

        Darwin)
            die "This installer currently supports Linux only."

            ;;

        *)
            die "Unsupported OS: $OS"
            ;;
    esac

    verify

    echo
    ok "Setup complete."
    echo

    echo -e "${CYAN}BUG command:${NC}"
    echo "  bug -d example.com"
    echo

    echo -e "${CYAN}uro:${NC}"
    echo "  $PY_BIN/uro"
    echo

    echo -e "${CYAN}Go tools:${NC}"
    echo "  $GOTOOLS_BIN"
    echo

    echo -e "${CYAN}GF patterns:${NC}"
    echo "  $REAL_HOME/.gf"
    echo

    echo -e "${CYAN}Log:${NC}"
    echo "  $LOG"
}

main "$@"
