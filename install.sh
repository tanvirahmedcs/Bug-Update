#!/usr/bin/env bash
# BUG FRAMEWORK — Installer
# Run this once to set up the `bug` command system-wide

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
BOLD='\033[1m'

echo -e "${BOLD}${CYAN}"
echo " ██████╗ ██╗   ██╗ ██████╗     ███████╗██████╗  █████╗ ███╗   ███╗███████╗██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗"
echo -e "${NC}"
echo -e "${CYAN}Installing BUG FRAMEWORK...${NC}\n"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copy helper scripts to /usr/local/bin
for helper in bug.sh bug_js_dl.py bug_active_filter.py; do
    if [[ -f "$SCRIPT_DIR/$helper" ]]; then
        sudo cp "$SCRIPT_DIR/$helper" /usr/local/bin/"$helper"
        sudo chmod +x /usr/local/bin/"$helper"
    fi
done

# Create bug command symlink
if [[ -f "/usr/local/bin/bug.sh" ]]; then
    sudo ln -sf /usr/local/bin/bug.sh /usr/local/bin/bug
fi

echo -e "${GREEN}✔ 'bug' command installed to /usr/local/bin/bug${NC}"
echo -e "${GREEN}✔ Usage: bug -d example.com${NC}"
echo ""
echo -e "${CYAN}Run 'bug --install' to install all tools${NC}"
echo -e "${CYAN}Run 'bug -d example.com' to start scanning${NC}"
