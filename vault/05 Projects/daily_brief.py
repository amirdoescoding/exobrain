#!/usr/bin/env python3
"""
ExoBrain — Daily Brief Helper
Utility for path construction. Called inline by Claude Code when the daily brief runs.
"""

import datetime
from pathlib import Path

VAULT = Path("{{VAULT_PATH}}")


def daily_note_path(date: datetime.date | None = None) -> Path:
    """Returns the full path for today's daily note (creates parent dirs)."""
    d = date or datetime.date.today()
    folder = VAULT / "02 Daily" / d.strftime("%Y") / d.strftime("%m")
    folder.mkdir(parents=True, exist_ok=True)
    filename = d.strftime("%m-%d-%y %a") + ".md"
    return folder / filename


if __name__ == "__main__":
    print("Today's note path:", daily_note_path())
