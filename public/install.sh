#!/usr/bin/env bash
# A-Society install script
#
# Clones the A-Society framework into a workspace directory and installs
# runtime dependencies. Does not modify PATH, install global packages, or
# make any system-level changes.
#
# Usage:
#   curl -fsSL https://a-society.dev/install.sh | bash
#   curl -fsSL https://a-society.dev/install.sh | bash -s -- /path/to/workspace
#
# After install:
#   npm --prefix ./a-society/runtime start
#   Then open http://localhost:3000

set -euo pipefail

# ── Constants ────────────────────────────────────────────────────────────────
REPO_URL="https://github.com/KartikGS/a-society.git"
REPO_DIR="a-society"
MIN_NODE_MAJOR=18

# ── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
DIM='\033[2m'
RESET='\033[0m'
BOLD='\033[1m'

info()  { printf "  ${CYAN}→${RESET}  %s\n" "$1"; }
ok()    { printf "  ${GREEN}✓${RESET}  %s\n" "$1"; }
fail()  { printf "\n  ${RED}✗  error:${RESET} %s\n\n" "$1" >&2; exit 1; }
header(){ printf "\n${BOLD}%s${RESET}\n" "$1"; }

# ── Workspace directory ───────────────────────────────────────────────────────
WORKSPACE="${1:-$(pwd)}"

# ── Dependency checks ─────────────────────────────────────────────────────────
header "Checking dependencies"

if ! command -v git &>/dev/null; then
  fail "git is not installed. Install git and re-run: https://git-scm.com"
fi
ok "git found ($(git --version | awk '{print $3}'))"

if ! command -v node &>/dev/null; then
  fail "node is not installed. Install Node.js >= ${MIN_NODE_MAJOR}: https://nodejs.org"
fi

NODE_MAJOR=$(node --version | sed 's/v//' | cut -d. -f1)
if [ "$NODE_MAJOR" -lt "$MIN_NODE_MAJOR" ]; then
  fail "Node.js >= ${MIN_NODE_MAJOR} is required (found $(node --version)). Update at https://nodejs.org"
fi
ok "node found ($(node --version))"

if ! command -v npm &>/dev/null; then
  fail "npm is not installed. It ships with Node.js — reinstall from https://nodejs.org"
fi
ok "npm found ($(npm --version))"

# ── Clone ─────────────────────────────────────────────────────────────────────
header "Installing A-Society"

TARGET="${WORKSPACE}/${REPO_DIR}"

if [ -d "$TARGET/.git" ]; then
  info "a-society/ already exists at ${TARGET} — skipping clone"
else
  if [ -e "$TARGET" ]; then
    fail "${TARGET} exists but is not a git repository. Remove it and re-run."
  fi
  info "Cloning from ${REPO_URL}..."
  git clone --depth=1 "$REPO_URL" "$TARGET"
  ok "Cloned into ${TARGET}"
fi

# ── Install runtime dependencies ──────────────────────────────────────────────
RUNTIME_DIR="${TARGET}/runtime"

if [ ! -d "$RUNTIME_DIR" ]; then
  fail "Runtime directory not found at ${RUNTIME_DIR}. The clone may be incomplete."
fi

info "Installing runtime dependencies (this may take a moment)..."
npm --prefix "$RUNTIME_DIR" install --silent
ok "Dependencies installed"

info "Building UI assets..."
npm --prefix "$RUNTIME_DIR" run build:ui --silent
ok "UI built"

# ── Done ──────────────────────────────────────────────────────────────────────
printf "\n${GREEN}${BOLD}  A-Society is ready.${RESET}\n\n"
printf "  ${DIM}Start the runtime:${RESET}\n"
printf "    ${CYAN}npm --prefix ${TARGET}/runtime start${RESET}\n\n"
printf "  ${DIM}Then open:${RESET}\n"
printf "    ${CYAN}http://localhost:3000${RESET}\n\n"
printf "  ${DIM}Docs:${RESET} https://a-society.dev/docs/getting-started\n\n"
