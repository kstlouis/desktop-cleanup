# desktop-cleanup

macOS-only zsh script that:

1. Creates **Desktop/screenshots** if it doesn’t exist
2. Moves any macOS-style screenshots from the Desktop into that folder (PNGs named `Screen Shot …` or `Screenshot …`)

## Usage

```bash
./desktop-cleanup.zsh
```

## Requirements

- zsh
- macOS (screenshot naming)
- `DESKTOP` defaults to `$HOME/Desktop`; override if needed

## LaunchAgent

A LaunchAgent runs the script every hour at :45. Plist: `com.jobber.desktop-cleanup.plist` (symlinked to `~/Library/LaunchAgents/`). Script: symlinked to `/Library/Application Support/Jobber/Scripts/`. Log: **Desktop/screenshots/desktop-cleanup.log** (trimmed to 100KB max).

### Setup

```bash
# Symlink the plist into LaunchAgents
ln -s ~/workspace/personal\ projects/desktop-cleanup/com.jobber.desktop-cleanup.plist ~/Library/LaunchAgents/com.jobber.desktop-cleanup.plist

# Symlink the script into Application Support
mkdir -p "/Library/Application Support/Jobber/Scripts"
ln -s ~/workspace/personal\ projects/desktop-cleanup/desktop-cleanup.zsh "/Library/Application Support/Jobber/Scripts/desktop-cleanup.zsh"

# Load the agent
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.jobber.desktop-cleanup.plist
```

### Useful commands

```bash
# Check it’s loaded
launchctl list | grep desktop-cleanup

# Run once now
launchctl start com.jobber.desktop-cleanup

# Reload after editing the plist
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.jobber.desktop-cleanup.plist && launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.jobber.desktop-cleanup.plist

# Stop and unload
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.jobber.desktop-cleanup.plist
```
