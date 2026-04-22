# ExoBrain — AI Second Brain

Your personal AI knowledge assistant: daily briefings, content summarization, and a living knowledge library — all in Obsidian, powered by Claude Code.

## Quick start

```bash
npx exobrain
```

The setup wizard walks you through everything in about 5 minutes. No cloning, no downloads — just one command.

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
- [Claude Code](https://claude.ai/code) + Anthropic API key (~$5–15/month at typical usage)
- [Obsidian](https://obsidian.md) (free)
- Node.js 16+
- Python 3.9+

## After setup

1. Open Obsidian → "Open folder as vault" → point to your vault
2. Settings → Community plugins → Enable "Unread Indicator"
3. Test your brief: `bash ~/Library/Scripts/exobrain-daily-brief.sh`
4. Check logs: `tail -f ~/Library/Logs/exobrain-daily-brief.log`

## Using the summarizer

**YouTube / podcast** — open Claude Code in your vault, then:
```
/summarize https://youtube.com/watch?v=...
```

**PDF / ebook** — drop the file into `_Attachments/`, then:
```
/summarize
```

Summaries land in `08 Summaries/`. Concept stubs are auto-created in `06 Research/`.

## Customizing news categories

Edit `05 Projects/daily_brief_prompt.txt` in your vault. The brief has 4 categories by default (World, AI/Tech, US Macro, Local). Add or replace any category by following the same pattern.

## Managing the daily brief

```bash
# Disable
launchctl unload ~/Library/LaunchAgents/com.exobrain.dailybrief.plist

# Re-enable
launchctl load ~/Library/LaunchAgents/com.exobrain.dailybrief.plist
```

## Roadmap

- v1.1 — Gmail + Google Calendar integration
- v1.2 — WhatsApp / Telegram via Beeper
- v2.0 — GUI installer (Windows + Linux)

## License

MIT
