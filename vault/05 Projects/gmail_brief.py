#!/usr/bin/env python3
"""
Gmail brief helper for ExoBrain daily brief.
Outputs plain-text markdown lines of unread emails from the last 24h.

Usage:
  python3 gmail_brief.py

Exit codes: 0 = success, 1 = auth error / not configured
"""

import sys
import re
from pathlib import Path
from datetime import datetime, timezone, timedelta

TOKEN_FILE = Path.home() / ".exobrain_google_token.json"
SCOPES = [
    "https://www.googleapis.com/auth/gmail.readonly",
    "https://www.googleapis.com/auth/calendar.readonly",
]

SKIP_SENDERS = [
    "linkedin", "instagram", "noreply", "no-reply", "notifications@",
    "google.com", "googlemail", "accounts.google", "newsletter",
    "info@", "hello@", "support@", "team@", "updates@",
]

def get_creds():
    from google.oauth2.credentials import Credentials
    from google.auth.transport.requests import Request
    if not TOKEN_FILE.exists():
        print("_Gmail not connected — run: python3 \"05 Projects/google_auth_setup.py\"_")
        sys.exit(1)
    creds = Credentials.from_authorized_user_file(str(TOKEN_FILE), SCOPES)
    if creds.expired and creds.refresh_token:
        creds.refresh(Request())
        TOKEN_FILE.write_text(creds.to_json())
    return creds

def get_header(headers, name):
    for h in headers:
        if h["name"].lower() == name.lower():
            return h["value"]
    return ""

def is_noise(sender, subject):
    s = (sender + subject).lower()
    return any(kw in s for kw in SKIP_SENDERS)

def main():
    creds = get_creds()
    from googleapiclient.discovery import build
    service = build("gmail", "v1", credentials=creds, cache_discovery=False)

    yesterday = (datetime.now(timezone.utc) - timedelta(days=1)).strftime("%Y/%m/%d")
    query = f"is:unread after:{yesterday}"

    result = service.users().messages().list(
        userId="me", q=query, maxResults=20
    ).execute()

    messages = result.get("messages", [])
    if not messages:
        print("_No unread emails._")
        sys.exit(0)

    lines = []
    for msg_ref in messages:
        msg = service.users().messages().get(
            userId="me", id=msg_ref["id"], format="metadata",
            metadataHeaders=["From", "Subject", "Date"]
        ).execute()
        headers = msg.get("payload", {}).get("headers", [])
        sender  = get_header(headers, "From")
        subject = get_header(headers, "Subject")

        if is_noise(sender, subject):
            continue

        name_match = re.match(r'^"?([^"<]+)"?\s*<', sender)
        display = name_match.group(1).strip() if name_match else sender.split("@")[0]

        lines.append(f"- **{display}** — {subject}")

    if not lines:
        print("_No time-sensitive emails._")
    else:
        print("\n".join(lines))

if __name__ == "__main__":
    main()
