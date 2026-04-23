#!/usr/bin/env python3
"""
One-time setup: OAuth consent flow for Gmail + Google Calendar.
Run this interactively ONCE — it saves a persistent token to
~/.exobrain_google_token.json (refresh token never expires unless
you revoke access in your Google account).

Requirements:
  1. Go to https://console.cloud.google.com/
  2. Create a project (or reuse one)
  3. Enable APIs: Gmail API + Google Calendar API
  4. OAuth consent screen: External, add your email as test user
  5. Credentials → Create OAuth client ID → Desktop app
  6. Download the JSON → save as ~/.exobrain_google_credentials.json

Then run: python3 "05 Projects/google_auth_setup.py"
"""

from pathlib import Path
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials

CREDENTIALS_FILE = Path.home() / ".exobrain_google_credentials.json"
TOKEN_FILE       = Path.home() / ".exobrain_google_token.json"

SCOPES = [
    "https://www.googleapis.com/auth/gmail.readonly",
    "https://www.googleapis.com/auth/calendar.readonly",
]

def main():
    if not CREDENTIALS_FILE.exists():
        print(f"ERROR: credentials file not found at {CREDENTIALS_FILE}")
        print()
        print("Steps to create it:")
        print("  1. Go to https://console.cloud.google.com/")
        print("  2. Create/select a project")
        print("  3. APIs & Services → Enable: Gmail API, Google Calendar API")
        print("  4. APIs & Services → OAuth consent screen → External")
        print("     Add your Google email as a Test user")
        print("  5. APIs & Services → Credentials → Create OAuth client ID")
        print("     Application type: Desktop app")
        print("  6. Download JSON → save as ~/.exobrain_google_credentials.json")
        return

    creds = None
    if TOKEN_FILE.exists():
        creds = Credentials.from_authorized_user_file(str(TOKEN_FILE), SCOPES)

    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
            print("Token refreshed automatically.")
        else:
            flow = InstalledAppFlow.from_client_secrets_file(str(CREDENTIALS_FILE), SCOPES)
            creds = flow.run_local_server(port=0)
            print("Authorization complete.")

        TOKEN_FILE.write_text(creds.to_json())
        print(f"Token saved to {TOKEN_FILE}")

    print()
    print("✓ Gmail API and Google Calendar API are authorized.")
    print("  Your daily brief will now include calendar events and unread emails.")

if __name__ == "__main__":
    main()
