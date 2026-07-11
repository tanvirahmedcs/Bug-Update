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

# Copy to /usr/local/bin
sudo cp "$SCRIPT_DIR/bug.sh" /usr/local/bin/bug
sudo chmod +x /usr/local/bin/bug

echo -e "${GREEN}✔ 'bug' command installed to /usr/local/bin/bug${NC}"
echo -e "${GREEN}✔ Usage: bug -d example.com${NC}"
echo ""
echo -e "${CYAN}Run 'bug --install' to install all tools${NC}"
echo -e "${CYAN}Run 'bug -d example.com' to start scanning${NC}"
