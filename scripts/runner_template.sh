#!/bin/bash
# ExoBrain — Daily Brief Runner
# Called by launchd every day at scheduled time.

LOG="$HOME/Library/Logs/exobrain-daily-brief.log"
PROMPT_FILE="EXOBRAIN_VAULT/05 Projects/daily_brief_prompt.txt"
VAULT="EXOBRAIN_VAULT"
CLAUDE="$HOME/.local/bin/claude"

echo "======================================" >> "$LOG"
echo "$(date '+%Y-%m-%d %H:%M:%S') — Starting daily brief" >> "$LOG"

if [ ! -x "$CLAUDE" ]; then
    echo "ERROR: claude not found at $CLAUDE" >> "$LOG"
    exit 1
fi

if [ ! -f "$PROMPT_FILE" ]; then
    echo "ERROR: prompt file not found at $PROMPT_FILE" >> "$LOG"
    exit 1
fi

# Wait for network — the machine may have just woken from sleep
NETWORK_WAIT=0
until curl -s --max-time 5 https://api.anthropic.com > /dev/null 2>&1; do
    if [ "$NETWORK_WAIT" -ge 120 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') — ERROR: network not available after 2 min, aborting" >> "$LOG"
        exit 1
    fi
    sleep 5
    NETWORK_WAIT=$((NETWORK_WAIT + 5))
done
echo "$(date '+%Y-%m-%d %H:%M:%S') — Network ready (waited ${NETWORK_WAIT}s)" >> "$LOG"

cd "$VAULT"
"$CLAUDE" \
    --dangerously-skip-permissions \
    --print \
    "$(cat "$PROMPT_FILE")" \
    >> "$LOG" 2>&1 &
CLAUDE_PID=$!
( sleep 900 && kill "$CLAUDE_PID" 2>/dev/null && echo "$(date '+%Y-%m-%d %H:%M:%S') — Watchdog killed claude after 15 min timeout" >> "$LOG" ) &
WATCHDOG_PID=$!
wait "$CLAUDE_PID"

EXIT_CODE=$?
kill "$WATCHDOG_PID" 2>/dev/null
wait "$WATCHDOG_PID" 2>/dev/null
echo "$(date '+%Y-%m-%d %H:%M:%S') — Finished (exit code: $EXIT_CODE)" >> "$LOG"
exit $EXIT_CODE
