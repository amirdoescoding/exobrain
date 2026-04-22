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
