#!/bin/bash
# Automatically copies files from HS900/image and HS900/video to ~/pictures/Year/Month
# Triggered by systemd .path unit when HS900 volume is mounted.

# --- Configuration -----------------------------------------------------------
# Override the mount point by passing it as the first argument, or set the
# MOUNT_POINT environment variable. Falls back to /media/$USER/HS900.
MOUNT_POINT="${1:-${MOUNT_POINT:-/media/$USER/HS900}}"
SOURCE_DIRS=("image" "video")
DEST_BASE="/mnt/storage/ericpic"
LOG_TAG="hs900-copy"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hs900-copy"
LAST_COPIED_FILE="$STATE_DIR/last_file"
mkdir -p "$STATE_DIR"
PREV_FIRST=""
if [ -f "$LAST_COPIED_FILE" ]; then
    PREV_FIRST=$(cat "$LAST_COPIED_FILE")
fi

log() {
    logger -t "$LOG_TAG" "$1"
}

# Verify the image source directory exists (video is assumed to follow)
if [ ! -d "$MOUNT_POINT/image" ]; then
    log "ERROR: Source directory '$MOUNT_POINT/image' does not exist. Exiting."
    exit 1
fi

log "HS900 mounted at: $MOUNT_POINT"

# Build destination path: ~/pictures/YYYY/MMMonth (e.g. ~/pictures/2026/03March)
YEAR=$(date '+%Y')
MONTH=$(date '+%m%B')   # e.g. "03March"
DEST="$DEST_BASE/$YEAR/$MONTH"
TODAY=$(date '+%Y-%m-%d')

mkdir -p "$DEST"
log "Destination: $DEST"

# ------------------------------------------------------------------
# copy_today_files <source_dir>
#   Copies today's files from <source_dir> to $DEST, newest-first,
#   stopping at the first file that is not from today.
# ------------------------------------------------------------------
copy_today_files() {
    local src="$1"
    local dir_copied=0 dir_skipped=0 dir_failed=0

    log "Processing: $src"

    while IFS= read -r file; do
        file_date=$(date -r "$file" '+%Y-%m-%d')
        if [ "$file_date" != "$TODAY" ]; then
            log "  Reached older files, stopping. (first old: $(basename "$file"), date: $file_date)"
            break
        fi

        filename=$(basename "$file")
        dest_file="$DEST/$filename"

        # If we encounter the first file from the previous run, stop
        if [ -n "$PREV_FIRST" ] && [ "$filename" = "$PREV_FIRST" ]; then
            log "  Reached previously copied file '$filename', stopping."
            STOP_REACHED=1
            break
        fi

        if [ -f "$dest_file" ] && cmp -s "$file" "$dest_file"; then
            dir_skipped=$((dir_skipped + 1))
            continue
        fi

        if cp -a "$file" "$dest_file"; then
            dir_copied=$((dir_copied + 1))
            # Record the first successfully copied file
            if [ -z "$FIRST_COPIED" ]; then
                FIRST_COPIED="$filename"
            fi
            log "  Copied: $filename"
        else
            dir_failed=$((dir_failed + 1))
            log "  FAILED: $filename"
        fi
    done < <(find "$src" -maxdepth 1 -type f -printf '%T@ %p\n' | sort -rn | cut -d' ' -f2-)

    COPIED=$((COPIED + dir_copied))
    SKIPPED=$((SKIPPED + dir_skipped))
    FAILED=$((FAILED + dir_failed))
}

COPIED=0
SKIPPED=0
FAILED=0
FIRST_COPIED=""
STOP_REACHED=0

for dir in "${SOURCE_DIRS[@]}"; do
    copy_today_files "$MOUNT_POINT/$dir"
    if [ "$STOP_REACHED" -eq 1 ]; then
        break
    fi
done

# Save the first copied filename for next run
if [ -n "$FIRST_COPIED" ]; then
    echo "$FIRST_COPIED" > "$LAST_COPIED_FILE"
    log "Marker saved: $FIRST_COPIED"
fi

SUMMARY="Done. Copied: $COPIED"
[ "$SKIPPED" -gt 0 ] && SUMMARY="$SUMMARY | Skipped (already exists): $SKIPPED"
[ "$FAILED" -gt 0 ] && SUMMARY="$SUMMARY | Failed: $FAILED"
log "$SUMMARY"
exit 0
