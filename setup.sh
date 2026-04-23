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
        err "Claude Code CLI not found"
        echo ""
        echo "     ExoBrain is powered by Claude Code — Anthropic's AI CLI."
        echo "     It requires an Anthropic API key (~\$5–15/month at typical usage)."
        echo ""
        echo "     Install it:"
        echo "       1. Go to https://claude.ai/code"
        echo "       2. Download and install Claude Code"
        echo "       3. Run: claude  (follow the API key setup prompt)"
        echo "       4. Re-run: npx exobrain"
        echo ""
        missing=1
    fi

    # Python 3
    if command -v python3 &>/dev/null; then
        ok "Python 3 found ($(python3 --version 2>&1))"
    else
        err "Python 3 not found"
        echo ""
        echo "     Python 3 is required for Gmail, Calendar, and PDF summarization."
        echo ""
        echo "     Install it:"
        echo "       Option A (recommended): https://brew.sh — then: brew install python3"
        echo "       Option B: https://python.org/downloads"
        echo "       Re-run: npx exobrain"
        echo ""
        missing=1
    fi

    # Node / npm (for building Obsidian plugin)
    if command -v npm &>/dev/null; then
        ok "npm found ($(npm --version))"
    else
        warn "npm not found — unread-indicator plugin will use pre-built version (no action needed)"
    fi

    # Obsidian
    if [ -d "/Applications/Obsidian.app" ]; then
        ok "Obsidian found"
    else
        warn "Obsidian not found in /Applications"
        echo "     Install from https://obsidian.md (free) before opening your vault"
    fi

    if [ "$missing" -eq 1 ]; then
        echo ""
        err "Fix the above and re-run: npx exobrain"
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

    # npm strips empty directories from packages — create them explicitly
    local dirs=(
        "02 Daily"
        "03 Meetings"
        "04 People"
        "06 Research"
        "07 References"
        "08 Summaries"
        "_Attachments"
        "_Bases"
    )
    for dir in "${dirs[@]}"; do
        mkdir -p "$VAULT_PATH/$dir"
    done

    ok "Vault structure created"
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
        "$VAULT_PATH/05 Projects/gmail_brief.py"
        "$VAULT_PATH/05 Projects/calendar_brief.py"
        "$VAULT_PATH/05 Projects/google_auth_setup.py"
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
# 7. Optional: Gmail + Google Calendar
# ──────────────────────────────────────────────────────────────
setup_google_auth() {
    step "Gmail + Google Calendar (optional)"
    echo "  Adds calendar events and unread emails to your daily brief."
    echo "  Requires a free Google Cloud project (~5 min one-time setup)."
    echo ""
    echo "  You can always set this up later by running:"
    echo "    python3 \"$VAULT_PATH/05 Projects/google_auth_setup.py\""
    echo ""
    read -r -p "  Set up Gmail + Google Calendar? [y/N]: " google_confirm
    google_confirm="${google_confirm:-N}"

    if [[ ! "$google_confirm" =~ ^[Yy]$ ]]; then
        ok "Skipped — brief will show weather + news only"
        return
    fi

    echo ""
    echo "  Follow these steps to create your Google credentials:"
    echo ""
    echo "  1. Go to https://console.cloud.google.com/"
    echo "  2. Create a new project (or select an existing one)"
    echo "  3. APIs & Services → Library → Enable:"
    echo "       Gmail API"
    echo "       Google Calendar API"
    echo "  4. APIs & Services → OAuth consent screen"
    echo "       User type: External → Create"
    echo "       Add your Google email under 'Test users'"
    echo "  5. APIs & Services → Credentials → + Create Credentials"
    echo "       → OAuth client ID → Application type: Desktop app"
    echo "  6. Download the JSON file"
    echo ""

    # Try to auto-detect a downloaded credentials file
    local detected_creds=""
    local newest
    newest="$(ls -t "$HOME/Downloads"/client_secret*.json 2>/dev/null | head -1)"
    if [ -n "$newest" ]; then
        detected_creds="$newest"
    fi

    local default_display="${detected_creds:-~/Downloads/client_secret_*.json}"
    read -r -p "  Path to downloaded credentials JSON [$default_display]: " creds_input
    creds_input="${creds_input:-$detected_creds}"
    creds_input="${creds_input/#\~/$HOME}"

    if [ -z "$creds_input" ] || [ ! -f "$creds_input" ]; then
        warn "Credentials file not found — skipping Google setup"
        echo "  Run manually when ready:"
        echo "    cp ~/Downloads/client_secret_*.json ~/.exobrain_google_credentials.json"
        echo "    python3 \"$VAULT_PATH/05 Projects/google_auth_setup.py\""
        return
    fi

    cp "$creds_input" "$HOME/.exobrain_google_credentials.json"
    ok "Credentials saved to ~/.exobrain_google_credentials.json"

    echo ""
    echo "  Opening browser for Google authorization..."
    echo "  (A browser window will open — sign in and grant access)"
    echo ""

    if python3 "$VAULT_PATH/05 Projects/google_auth_setup.py"; then
        ok "Gmail + Google Calendar connected"
    else
        warn "Authorization failed — run manually when ready:"
        echo "    python3 \"$VAULT_PATH/05 Projects/google_auth_setup.py\""
    fi
}

# ──────────────────────────────────────────────────────────────
# 8. Create launchd automation
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
    setup_google_auth
    build_plugin
    setup_launchd
    print_next_steps
}

main
