#!/usr/bin/env python3
"""
Google Calendar brief helper for ExoBrain daily brief.
Outputs today's events as plain-text markdown lines.

Usage:
  python3 calendar_brief.py [YYYY-MM-DD]   # defaults to today ({{TIMEZONE}})
"""

import sys
from pathlib import Path
from datetime import datetime, timedelta
import zoneinfo

TOKEN_FILE = Path.home() / ".exobrain_google_token.json"
SCOPES = [
    "https://www.googleapis.com/auth/gmail.readonly",
    "https://www.googleapis.com/auth/calendar.readonly",
]
TZ = zoneinfo.ZoneInfo("{{TIMEZONE}}")

def get_creds():
    from google.oauth2.credentials import Credentials
    from google.auth.transport.requests import Request
    if not TOKEN_FILE.exists():
        print("_Google Calendar not connected — run: python3 \"05 Projects/google_auth_setup.py\"_")
        sys.exit(1)
    creds = Credentials.from_authorized_user_file(str(TOKEN_FILE), SCOPES)
    if creds.expired and creds.refresh_token:
        creds.refresh(Request())
        TOKEN_FILE.write_text(creds.to_json())
    return creds

def main():
    date_str = sys.argv[1] if len(sys.argv) > 1 else \
        datetime.now(TZ).strftime("%Y-%m-%d")

    date = datetime.strptime(date_str, "%Y-%m-%d").replace(tzinfo=TZ)
    time_min = date.isoformat()
    time_max = (date + timedelta(days=1) - timedelta(seconds=1)).isoformat()

    creds = get_creds()
    from googleapiclient.discovery import build
    service = build("calendar", "v3", credentials=creds, cache_discovery=False)

    events_result = service.events().list(
        calendarId="primary",
        timeMin=time_min,
        timeMax=time_max,
        singleEvents=True,
        orderBy="startTime",
        timeZone="{{TIMEZONE}}",
    ).execute()

    events = events_result.get("items", [])
    if not events:
        print("_No events scheduled._")
        sys.exit(0)

    lines = []
    for event in events:
        summary = event.get("summary", "(No title)")
        start   = event.get("start", {})

        if "dateTime" in start:
            dt = datetime.fromisoformat(start["dateTime"]).astimezone(TZ)
            time_label = dt.strftime("%H:%M")
        else:
            time_label = "All day"

        location = event.get("location", "")
        loc_str  = f" @ {location}" if location else ""

        lines.append(f"- **{time_label}** — {summary}{loc_str}")

    print("\n".join(lines))

if __name__ == "__main__":
    main()
