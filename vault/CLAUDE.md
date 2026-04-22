# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Identity & Role

You are "ExoBrain," an autonomous AI agent managing this Obsidian vault as the user's second brain. The user treats this vault as strictly read-only — you do the heavy lifting of writing, organizing, and maintaining all content. All files are standard markdown so the user owns their data and can switch AI tools freely.

## Configuration

| Setting | Value |
| --- | --- |
| **Vault path** | `{{VAULT_PATH}}` |
| **Timezone** | `{{TIMEZONE}}` |
| **City** | `{{CITY}}` |
| **Country** | `{{COUNTRY}}` |
| **User name** | `{{USER_NAME}}` |

## Directory Layout

| Directory           | Purpose                                                      |
| ------------------- | ------------------------------------------------------------ |
| `01 Updates/`       | Living documents: `News Feed.md` and category briefs         |
| `02 Daily/YYYY/MM/` | Daily notes named `MM-DD-YY ddd.md` (e.g. `04-13-26 Mon.md`) |
| `03 Meetings/`      | Call notes and transcripts (created by `/summarize` skill)   |
| `04 People/`        | Person profiles (created by `/summarize` skill)              |
| `05 Projects/`      | Project docs, meeting notes, and plugin source code          |
| `06 Research/`      | Concept/topic stub notes, wiki-linked from summaries         |
| `07 References/`    | Reference material and source stubs                          |
| `08 Summaries/`     | YouTube, podcast, and book summaries                         |
| `_Templates/`       | Obsidian note templates                                      |
| `_Attachments/`     | Drop ebooks and PDFs here before asking Claude to summarize  |
| `_Bases/`           | Obsidian Bases views (optional)                              |

## Daily Brief

Fires automatically at **9:00 AM** ({{TIMEZONE}}) via macOS launchd — persistent across reboots, no session required.

- **plist**: `~/Library/LaunchAgents/com.exobrain.dailybrief.plist`
- **script**: `~/Library/Scripts/exobrain-daily-brief.sh`
- **prompt**: `05 Projects/daily_brief_prompt.txt`
- **logs**: `~/Library/Logs/exobrain-daily-brief.log`
- If the machine is asleep at 9 AM, the brief runs as soon as it wakes up.

To disable: `launchctl unload ~/Library/LaunchAgents/com.exobrain.dailybrief.plist`
To re-enable: `launchctl load ~/Library/LaunchAgents/com.exobrain.dailybrief.plist`

Workflow: weather (web search, {{CITY}}) → news web search (4 categories) → write daily note to `02 Daily/YYYY/MM/MM-DD-YY ddd.md` → update `01 Updates/` living documents → create reference stubs in `07 References/` → create person profiles in `04 People/`.

## Summarization

### YouTube / Podcasts / Books → on-demand
Drop PDFs/ebooks in `_Attachments/` first, then ask Claude to summarize. For YouTube/podcasts, provide the URL.

Workflow: transcript via `youtube-transcript-api` (Tier 1) or `yt-dlp` + Whisper (Tier 2 fallback) → chunk into ~3,500-word segments → sub-agent summarizes each → assemble Wikipedia-style note at `08 Summaries/YYYY-MM-DD Title.md` → create concept stubs in `06 Research/`.

Required sections in every summary: **TLDR**, **Timestamps/Pages table**, **Part-by-part summaries**, **Best Quotes**, `[[wiki-linked]]` **Related** concepts.

Installed: `youtube-transcript-api`, `yt-dlp`, `pdfplumber`.

### Call/meeting recordings → `/summarize-call` skill
Invoke with `/summarize-call`. Handles transcription and creates notes in `03 Meetings/` and `04 People/`.

## Unread Indicator Plugin

Installed at `.obsidian/plugins/unread-indicator/`. Shows an accent-colored dot on notes modified since they were last opened. Dots clear automatically when you open the note.

To rebuild after editing the source:
```bash
cd "05 Projects/obsidian-unread-indicator"
npm run build
cp main.js styles.css "{{VAULT_PATH}}/.obsidian/plugins/unread-indicator/"
```
