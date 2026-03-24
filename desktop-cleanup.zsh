#!/usr/bin/env zsh
#
# desktop-cleanup.zsh — macOS: move screenshots from Desktop into Desktop/screenshots
#

set -e

# zsh/datetime provides strftime and EPOCHSECONDS; not auto-loaded in launchd context
zmodload zsh/datetime

# When run by launchd, HOME may be unset; resolve it so we use the correct Desktop
[[ -z "$HOME" ]] && export HOME=$(eval echo ~$(id -un))
DESKTOP="${DESKTOP:-$HOME/Desktop}"
SCREENSHOTS_DIR="$DESKTOP/screenshots"

if [[ ! -d "$DESKTOP" ]]; then
  print -u2 "Desktop not found: $DESKTOP"
  exit 1
fi

# Log lives outside Desktop; launchd lacks TCC permission to write inside ~/Desktop
LOG="$HOME/Library/Logs/desktop-cleanup.log"
exec >> "$LOG" 2>&1

# Cap log size (trim to last 50KB when over 100KB)
MAX_LOG_BYTES=102400
KEEP_BYTES=51200
if [[ -f "$LOG" ]]; then
  sz=$(stat -f%z "$LOG" 2>/dev/null || echo 0)
  if (( sz > MAX_LOG_BYTES )); then
    tmp=$(mktemp) \
      && tail -c "$KEEP_BYTES" "$LOG" > "$tmp" \
      && mv "$tmp" "$LOG" \
      || rm -f "$tmp"
  fi
fi

# Log header for each run
print "---"
print "Run: $(strftime '%Y-%m-%d %H:%M:%S' $EPOCHSECONDS)"
print "DESKTOP: $DESKTOP"

# Use Finder via osascript for all Desktop file operations.
# launchd agents lack Desktop TCC permission; routing through Finder bypasses this.
result=$(osascript <<APPLESCRIPT
tell application "Finder"
  try
    make new folder at (POSIX file "$DESKTOP") with properties {name:"screenshots"}
  end try
  set dest to (POSIX file "$SCREENSHOTS_DIR") as alias
  set fileNames to name of every file of folder (POSIX file "$DESKTOP")
  set moved to {}
  repeat with fname in fileNames
    set fstr to fname as text
    if ((fstr starts with "Screenshot") or (fstr starts with "Screen Shot")) and fstr ends with ".png" then
      try
        move file fstr of folder (POSIX file "$DESKTOP") to dest
        set end of moved to fstr
      end try
    end if
  end repeat
  set output to ""
  repeat with fname in moved
    set output to output & (fname as text) & linefeed
  end repeat
  return output
end tell
APPLESCRIPT
)

moved=0
while IFS= read -r fname; do
  if [[ -n "$fname" ]]; then
    print "  $fname"
    moved=$((moved+1))
  fi
done <<< "$result"

if (( moved > 0 )); then
  print "Moved: $moved screenshot(s)"
else
  print "Moved: 0 (none on Desktop)"
fi
print ""
