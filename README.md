# HS900 Auto-Copy Setup
#
# This installs a udev rule + systemd user service so that whenever a
# volume labelled "HS900" is mounted, today's images and videos are automatically
# copied to ~/pictures/Year/Month.
#
# The udev rule detects when the volume is mounted and triggers the copy service.
#
# ──────────────────────────────────────────────────────
# 1. Install the copy script
# ──────────────────────────────────────────────────────
#   mkdir -p ~/.local/bin
#   cp hs900-copy.sh ~/.local/bin/
#   chmod +x ~/.local/bin/hs900-copy.sh
#
# ──────────────────────────────────────────────────────
# 2. Install the systemd user service
# ──────────────────────────────────────────────────────
#   mkdir -p ~/.config/systemd/user
#   cp hs900-copy.service ~/.config/systemd/user/
#   systemctl --user daemon-reload
#
# ──────────────────────────────────────────────────────
# 3. Install the udev rule (requires sudo)
# ──────────────────────────────────────────────────────
#   sudo cp 99-hs900.rules /etc/udev/rules.d/
#   sudo udevadm control --reload-rules
#   sudo udevadm trigger
#
# ──────────────────────────────────────────────────────
# 4. Test
# ──────────────────────────────────────────────────────
#   Plug in the HS900. Check the log:
#     journalctl --user -u hs900-copy.service
#
#   Or trigger it manually:
#     systemctl --user start hs900-copy.service
#
# ──────────────────────────────────────────────────────
# Note: The .path unit is no longer used. The udev rule handles triggering the service directly.
#
# ──────────────────────────────────────────────────────
# How duplicate prevention works
# ──────────────────────────────────────────────────────
# Files are processed newest-first. After a successful run, the name
# of the first (newest) copied file is saved to:
#   ${XDG_STATE_HOME:-~/.local/state}/hs900-copy/last_file
#
# On the next run, when the script encounters that filename it stops
# immediately, since everything from that point on was already copied.
# This means re-inserting the card or re-triggering the service will
# only copy files that are new since the last run.
