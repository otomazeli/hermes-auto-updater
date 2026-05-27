---
name: hermes-auto-updater
description: "Daily auto-update for Hermes Agent with an optional grace window and messaging gateway notifications."
version: 2.0.0
author: Ody Thomas / JARVIS
license: MIT
platforms: [linux, macos]
metadata:
  hermes:
    tags: [devops, maintenance, hermes, update, cron, automation]
    homepage: https://github.com/NousResearch/hermes-agent
    related_skills: [hermes-agent, hermes-self-backup]
---

# Hermes Auto-Updater

A two-stage cron-based auto-update routine for Hermes Agent that **notifies you before applying updates** and gives you a pause/resume gate.

## What it does

1. **Daily check** at a scheduled time — pings upstream, counts commits behind, drops a pending marker.
2. **Grace window** (10 min by default) — time for you to pause if you want.
3. **Daily apply** after the grace window — runs `hermes update -y` only if you didn't block it.

Optional notifications are delivered through **your existing Hermes messaging gateway** (Telegram, Discord, Signal, etc.).

## Requirements

- Hermes Agent installed via git
- `gh` CLI authenticated (for GitHub-based installs)
- Optional: Hermes messaging gateway already configured

## Quick Start

### 1. Install the skill

```bash
hermes skills install hermes-auto-updater
```

### 2. (Optional) Enable notifications

```bash
bash ~/.hermes/skills/devops/hermes-auto-updater/scripts/setup.sh
```

This checks your Hermes config and asks whether to wire notifications to your existing messaging gateway. No API keys are stored in the skill — it reuses whatever is already configured in your Hermes `.env`.

### 3. Set up cron jobs

```bash
# Check at 6:00 AM
hermes cron create "0 6 * * *" --name "hermes-update-check" \
  --no-agent --script "hermes-update-check.sh"

# Apply at 6:10 AM
hermes cron create "10 6 * * *" --name "hermes-update-apply" \
  --no-agent --script "hermes-update-apply.sh"
```

Adjust times as you like. The two must be separated by your desired grace window.

### 4. Verify

```bash
hermes cron list
```

You should see two active jobs:
* `hermes-update-check`
* `hermes-update-apply`

## Manual daily workflow

You don't need to do anything, but you have these controls:

| Action | Command |
|---|---|
| **Pause next update** | `echo "reason" > ~/.hermes/.pause-auto-update` |
| **Resume** | `rm ~/.hermes/.pause-auto-update` |
| **Check now** | `hermes update --check` |
| **Apply now** | `hermes update -y` |
| **View logs** | `tail -f ~/.hermes/logs/auto-update.log` |
| **Delete jobs** | `hermes cron remove <id>` (see `hermes cron list`) |

## Files shipped

| File | Purpose |
|---|---|
| `scripts/hermes-update-check.sh` | Stage 1 — check + mark pending |
| `scripts/hermes-update-apply.sh` | Stage 2 — apply update if not paused |
| `scripts/setup.sh` | One-time setup: enables notifications from your Hermes config |
| `SKILL.md` | This file |

## Customisation

To change schedule or grace window:

1. Remove old cron jobs: `hermes cron list`, then `hermes cron remove <id>`
2. Re-create with new times (e.g. `0 3 * * *` and `20 3 * * *`)
3. Re-copy scripts if you edited them in place

## Troubleshooting

**"hermes not in PATH"**
Ensure the cron job runs under your normal user where `hermes` is available.

**No notification received**
Run `~/.hermes/skills/devops/hermes-auto-updater/scripts/setup.sh` to refresh the notification config from your Hermes environment. If no gateway is configured, notifications are silently skipped.

**Update applies even when paused**
Check that `~/.hermes/.pause-auto-update` exists. The apply job checks for this file's existence, not content.

## License

MIT
