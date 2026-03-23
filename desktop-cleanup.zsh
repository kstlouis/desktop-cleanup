#!/usr/bin/env zsh
#
# desktop-cleanup.zsh — macOS: move screenshots from Desktop into Desktop/screenshots
#

set -e

# When run by launchd, HOME may be unset; resolve it so we use the correct Desktop
[[ -z "$HOME" ]] && export HOME=$(eval echo ~$(id -un))
DESKTOP="${DESKTOP:-$HOME/Desktop}"
SCREENSHOTS_DIR="$DESKTOP/screenshots"

if [[ ! -d "$DESKTOP" ]]; then
  print -u2 "Desktop not found: $DESKTOP"
  exit 1
fi

# Log lives in the screenshots folder; ensure dir exists then redirect output there
mkdir -p "$SCREENSHOTS_DIR"
LOG="$SCREENSHOTS_DIR/desktop-cleanup.log"
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

# macOS screenshot names: "Screen Shot …" or "Screenshot …" (PNG)
is_screenshot() {
  local name="${1:t}"
  [[ "$name" == Screen\ Shot*.png ]] || [[ "$name" == Screenshot*.png ]]
}

# Pick a destination path; if file exists, use macOS-style " copy", " copy 2", … before .png
dest_path() {
  local dir="$1" base="${2:t}" stem="${base%.png}"
  local dest="$dir/$base" n=1
  while [[ -e "$dest" ]]; do
    if (( n == 1 )); then
      dest="$dir/${stem} copy.png"
    else
      dest="$dir/${stem} copy $n.png"
    fi
    n=$((n+1))
  done
  print -r "$dest"
}

# 1. Move screenshots from Desktop into screenshots/
moved=0
for f in "$DESKTOP"/*.png(N); do
  is_screenshot "$f" || continue
  dest=$(dest_path "$SCREENSHOTS_DIR" "$f")
  mv "$f" "$dest"
  print "  ${dest:t}"
  moved=$((moved+1))
done
if (( moved > 0 )); then
  print "Moved: $moved screenshot(s)"
else
  print "Moved: 0 (none on Desktop)"
fi
print ""
