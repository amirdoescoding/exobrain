#!/bin/bash
# ExoBrain Setup — AI Second Brain powered by Claude Code + Obsidian
# https://github.com/yourusername/exobrain
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

print_header() {
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  ExoBrain — AI Second Brain Setup${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
warn() { echo -e "  ${YELLOW}!${NC} $1"; }
err()  { echo -e "  ${RED}✗${NC} $1"; }
step() { echo -e "\n${BLUE}▶ $1${NC}"; }

# ──────────────────────────────────────────────────────────────
# 1. Prerequisites
# ──────────────────────────────────────────────────────────────
check_prerequisites() {
    step "Checking prerequisites"
    local missing=0

    # Claude Code CLI
    if command -v claude &>/dev/null || [ -x "$HOME/.local/bin/claude" ]; then
        ok "Claude Code CLI found"
    else
        err "Claude Code CLI not found. Install from: https://claude.ai/code"
        missing=1
    fi

    # Python 3
    if command -v python3 &>/dev/null; then
        ok "Python 3 found ($(python3 --version 2>&1))"
    else
        err "Python 3 not found. Install from: https://python.org"
        missing=1
    fi

    # Node / npm (for building Obsidian plugin)
    if command -v npm &>/dev/null; then
        ok "npm found ($(npm --version))"
    else
        warn "npm not found — unread-indicator plugin won't be rebuilt (pre-built version will be used)"
    fi

    # Obsidian
    if [ -d "/Applications/Obsidian.app" ]; then
        ok "Obsidian found"
    else
        warn "Obsidian not found in /Applications — install from https://obsidian.md before opening your vault"
    fi

    if [ "$missing" -eq 1 ]; then
        echo ""
        err "Please install missing prerequisites and re-run setup."
        exit 1
    fi
}

# ──────────────────────────────────────────────────────────────
# 2. Gather user configuration
# ──────────────────────────────────────────────────────────────
gather_config() {
    step "Configuration"
    echo "  Press Enter to accept the default shown in [brackets]."
    echo ""

    # Vault location
    read -r -p "  Vault location [$HOME/ExoBrain]: " VAULT_PATH
    VAULT_PATH="${VAULT_PATH:-$HOME/ExoBrain}"
    VAULT_PATH="${VAULT_PATH/#\~/$HOME}"

    # User name
    read -r -p "  Your name [User]: " USER_NAME
    USER_NAME="${USER_NAME:-User}"

    # City
    read -r -p "  Your city (for weather & local news) [New York]: " CITY
    CITY="${CITY:-New York}"

    # Country
    read -r -p "  Your country [United States]: " COUNTRY
    COUNTRY="${COUNTRY:-United States}"

    # Timezone — resolve full IANA name (e.g. Europe/Rome, not legacy alias "Rome")
    local detected_tz
    detected_tz="$(python3 -c 'import datetime; print(datetime.datetime.now().astimezone().tzname())' 2>/dev/null)" || true
    detected_tz="$(readlink /etc/localtime 2>/dev/null | sed 's|.*/zoneinfo/||')" || true
    detected_tz="${detected_tz:-America/New_York}"
    echo "  Tip: use full IANA format, e.g. Europe/Rome, America/New_York, Asia/Tokyo"
    read -r -p "  Timezone [$detected_tz]: " TIMEZONE
    TIMEZONE="${TIMEZONE:-$detected_tz}"

    # Brief time
    read -r -p "  Daily brief time — hour in 24h format [9]: " BRIEF_HOUR
    BRIEF_HOUR="${BRIEF_HOUR:-9}"
    read -r -p "  Daily brief time — minute [0]: " BRIEF_MINUTE
    BRIEF_MINUTE="${BRIEF_MINUTE:-0}"

    echo ""
    echo -e "  ${BOLD}Summary:${NC}"
    echo "    Vault:    $VAULT_PATH"
    echo "    Name:     $USER_NAME"
    echo "    City:     $CITY, $COUNTRY"
    echo "    Timezone: $TIMEZONE"
    echo "    Brief at: $(printf '%02d:%02d' "$BRIEF_HOUR" "$BRIEF_MINUTE")"
    echo ""
    read -r -p "  Continue? [Y/n]: " confirm
    confirm="${confirm:-Y}"
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "  Aborted."
        exit 0
    fi
}

# ──────────────────────────────────────────────────────────────
# 3. Copy vault skeleton
# ──────────────────────────────────────────────────────────────
copy_vault() {
    step "Creating vault at $VAULT_PATH"

    if [ -d "$VAULT_PATH" ]; then
        warn "Directory already exists — merging (existing files won't be overwritten)"
        cp -rn "$REPO_DIR/vault/." "$VAULT_PATH/" 2>/dev/null || true
    else
        cp -r "$REPO_DIR/vault" "$VAULT_PATH"
    fi
    ok "Vault skeleton copied"
}

# ──────────────────────────────────────────────────────────────
# 4. Substitute placeholders
# ──────────────────────────────────────────────────────────────
substitute_placeholders() {
    step "Configuring vault with your settings"

    # Escape for sed (replace / with \/)
    local vault_escaped city_escaped country_escaped tz_escaped name_escaped
    vault_escaped="$(echo "$VAULT_PATH" | sed 's/[\/&]/\\&/g')"
    city_escaped="$(echo "$CITY" | sed 's/[\/&]/\\&/g')"
    country_escaped="$(echo "$COUNTRY" | sed 's/[\/&]/\\&/g')"
    tz_escaped="$(echo "$TIMEZONE" | sed 's/[\/&]/\\&/g')"
    name_escaped="$(echo "$USER_NAME" | sed 's/[\/&]/\\&/g')"

    local files=(
        "$VAULT_PATH/CLAUDE.md"
        "$VAULT_PATH/05 Projects/daily_brief_prompt.txt"
        "$VAULT_PATH/05 Projects/daily_brief.py"
    )

    for f in "${files[@]}"; do
        if [ -f "$f" ]; then
            sed -i '' \
                "s/{{VAULT_PATH}}/$vault_escaped/g;
                 s/{{CITY}}/$city_escaped/g;
                 s/{{COUNTRY}}/$country_escaped/g;
                 s/{{TIMEZONE}}/$tz_escaped/g;
                 s/{{USER_NAME}}/$name_escaped/g" "$f"
        fi
    done
    ok "Placeholders substituted"
}

# ──────────────────────────────────────────────────────────────
# 5. Install Python dependencies
# ──────────────────────────────────────────────────────────────
install_python_deps() {
    step "Installing Python dependencies"
    if python3 -m pip install --quiet yt-dlp youtube-transcript-api pdfplumber; then
        ok "Python packages installed"
    else
        warn "pip install failed — try manually: pip3 install yt-dlp youtube-transcript-api pdfplumber"
    fi
}

# ──────────────────────────────────────────────────────────────
# 6. Build unread-indicator Obsidian plugin
# ──────────────────────────────────────────────────────────────
build_plugin() {
    step "Building Obsidian unread-indicator plugin"
    local src="$VAULT_PATH/05 Projects/obsidian-unread-indicator"
    local dst="$VAULT_PATH/.obsidian/plugins/unread-indicator"

    if command -v npm &>/dev/null && [ -d "$src" ]; then
        (cd "$src" && npm install --silent && npm run build --silent) && \
        cp "$src/main.js" "$dst/" && \
        cp "$src/styles.css" "$dst/" && \
        ok "Plugin built and installed" || \
        warn "Plugin build failed — pre-built version already in place"
    else
        ok "Using pre-built plugin (npm not available)"
    fi
}

# ──────────────────────────────────────────────────────────────
# 7. Create launchd automation
# ──────────────────────────────────────────────────────────────
setup_launchd() {
    step "Setting up daily brief automation (launchd)"

    local script_path="$HOME/Library/Scripts/exobrain-daily-brief.sh"
    local plist_path="$HOME/Library/LaunchAgents/com.exobrain.dailybrief.plist"
    local log_path="$HOME/Library/Logs/exobrain-daily-brief.log"
    local vault_escaped
    vault_escaped="$(echo "$VAULT_PATH" | sed 's/[\/&]/\\&/g')"

    # Create Scripts dir if needed
    mkdir -p "$HOME/Library/Scripts" "$HOME/Library/LaunchAgents"

    # Write runner script
    sed \
        "s|EXOBRAIN_VAULT|$VAULT_PATH|g" \
        "$REPO_DIR/scripts/runner_template.sh" > "$script_path"
    chmod +x "$script_path"
    ok "Runner script created at $script_path"

    # Write plist
    sed \
        -e "s|EXOBRAIN_SCRIPT_PATH|$script_path|g" \
        -e "s|EXOBRAIN_LOG_PATH|$log_path|g" \
        -e "s|EXOBRAIN_HOME|$HOME|g" \
        -e "s|EXOBRAIN_HOUR|$BRIEF_HOUR|g" \
        -e "s|EXOBRAIN_MINUTE|$BRIEF_MINUTE|g" \
        "$REPO_DIR/scripts/launchd_template.plist" > "$plist_path"
    ok "Launchd plist created at $plist_path"

    # Unload existing job if present, then load
    launchctl unload "$plist_path" 2>/dev/null || true
    if launchctl load "$plist_path"; then
        ok "Daily brief scheduled at $(printf '%02d:%02d' "$BRIEF_HOUR" "$BRIEF_MINUTE") ($TIMEZONE)"
    else
        warn "launchctl load failed — run manually: launchctl load $plist_path"
    fi
}

# ──────────────────────────────────────────────────────────────
# 8. Done
# ──────────────────────────────────────────────────────────────
print_next_steps() {
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}${BOLD}  ExoBrain is ready!${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  Next steps:"
    echo ""
    echo "  1. Open Obsidian and add your vault:"
    echo "     Open Obsidian → Open folder as vault → $VAULT_PATH"
    echo ""
    echo "  2. Enable the unread-indicator plugin:"
    echo "     Settings → Community plugins → Enable 'Unread Indicator'"
    echo ""
    echo "  3. Test your daily brief:"
    echo "     bash ~/Library/Scripts/exobrain-daily-brief.sh"
    echo ""
    echo "  4. Check logs if anything goes wrong:"
    echo "     tail -f ~/Library/Logs/exobrain-daily-brief.log"
    echo ""
    echo "  5. Summarize content by running in Claude Code:"
    echo "     /summarize  (YouTube URL, podcast, or PDF in _Attachments/)"
    echo ""
    echo "  The daily brief runs automatically at $(printf '%02d:%02d' "$BRIEF_HOUR" "$BRIEF_MINUTE") every day."
    echo "  If your Mac is asleep, it runs when it wakes up."
    echo ""
}

# ──────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────
main() {
    print_header
    check_prerequisites
    gather_config
    copy_vault
    substitute_placeholders
    install_python_deps
    build_plugin
    setup_launchd
    print_next_steps
}

main
