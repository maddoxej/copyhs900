# HS900 Auto-Copy Setup
#
# This installs a systemd .path unit + service so that whenever a
# volume labelled "HS900" is mounted, today's images are automatically
# copied to ~/pictures/Year/Month.
#
# The .path unit watches for /media/$USER/HS900/images to appear
# (i.e. become non-empty), then triggers the copy service. No udev
# rules or root access required.
#
# ──────────────────────────────────────────────────────
# 1. Install the copy script
# ──────────────────────────────────────────────────────
#   mkdir -p ~/.local/bin
#   cp copy-hs900-images.sh ~/.local/bin/
#   chmod +x ~/.local/bin/copy-hs900-images.sh
#
# ──────────────────────────────────────────────────────
# 2. Install the systemd user units
# ──────────────────────────────────────────────────────
#   mkdir -p ~/.config/systemd/user
#   cp hs900-copy.service hs900-copy.path ~/.config/systemd/user/
#   systemctl --user daemon-reload
#   systemctl --user enable --now hs900-copy.path
#
# ──────────────────────────────────────────────────────
# 3. Test
# ──────────────────────────────────────────────────────
#   Plug in the HS900. Check the log:
#     cat ~/.local/log/hs900-copy.log
#
#   Or trigger it manually:
#     systemctl --user start hs900-copy.service
#
# ──────────────────────────────────────────────────────
# Note: If your distro mounts removable media under /run/media/$USER
# instead of /media/$USER, edit the PathExistsGlob line in
# hs900-copy.path and the MOUNT_POINT default in the script.
