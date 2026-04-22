# ExoBrain — AI Second Brain

Your personal AI knowledge assistant: daily briefings, content summarization, and a living knowledge library — all in Obsidian, powered by Claude Code.

## What you get

| Feature | What it does |
|---|---|
| **Daily Brief** | Every morning: weather + world/AI/macro/local news, auto-written to your vault |
| **Summarizer** | YouTube videos, podcasts, PDFs → structured Wikipedia-style notes |
| **Library** | Concept stubs in `06 Research/`, source profiles in `07 References/` |
| **People** | Auto-created profiles for public figures mentioned in news |
| **Unread Indicator** | Accent dot on notes you haven't read yet |

Everything is plain Markdown — you own your data.

## Requirements

- **macOS** (Monterey 12+)
- [Claude Code CLI](https://claude.ai/code) + Anthropic API key (~$5–15/month at typical usage)
- [Obsidian](https://obsidian.md) (free)
- Python 3.9+
- Node.js + npm (for rebuilding the Obsidian plugin — optional, pre-built version included)

## Quick start

```bash
git clone https://github.com/yourusername/exobrain
cd exobrain
bash setup.sh
```

The installer walks you through everything in about 5 minutes:
1. Checks prerequisites
2. Asks: vault location, name, city, country, timezone, brief time
3. Creates your vault, substitutes your settings, schedules the daily brief

## After setup

1. Open Obsidian → "Open folder as vault" → point to your vault
2. Settings → Community plugins → Enable "Unread Indicator"
3. Test: `bash ~/Library/Scripts/exobrain-daily-brief.sh`
4. Logs: `tail -f ~/Library/Logs/exobrain-daily-brief.log`

## Using the summarizer

**YouTube / podcast:**
```
Open Claude Code in your vault directory, then:
/summarize https://youtube.com/watch?v=...
```

**PDF / ebook:**
1. Drop the file into `_Attachments/`
2. In Claude Code: `/summarize` and tell it the filename

Summaries land in `08 Summaries/`. Concept stubs are auto-created in `06 Research/`.

## Customizing news categories

Edit `05 Projects/daily_brief_prompt.txt` — the news step has 4 categories by default (World, AI/Tech, US Macro, Local). Add or replace categories by following the same pattern.

## Disabling / re-enabling the daily brief

```bash
# Disable
launchctl unload ~/Library/LaunchAgents/com.exobrain.dailybrief.plist

# Re-enable
launchctl load ~/Library/LaunchAgents/com.exobrain.dailybrief.plist
```

## Coming soon

- Gmail + Google Calendar integration (v1.1)
- WhatsApp / Telegram / messages via Beeper (v1.2)
- GUI installer for non-technical users (v2.0)

## License

MIT
