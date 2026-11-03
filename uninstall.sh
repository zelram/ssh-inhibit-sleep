#!/usr/bin/env bash

# Stop the program if any of the lines fail
set -e

# Check if running as root, if not write error and exit
if [[ $EUID -ne 0 ]]; then
    echo "Please run with sudo" >&2
    exit 1
fi

# Stop and disable the service. || true in case it returns failure when the service doesn't exist
systemctl disable --now ssh-inhibit-sleep.service || true

# Remove the two files, -f in case they were not installed
rm -f /usr/local/bin/ssh-inhibit-sleep.sh /etc/systemd/system/ssh-inhibit-sleep.service

# Referesh systemd daemon so the service doesn't exist anymore
systemctl daemon-reload

echo "Successfully removed ssh-inhibit-sleep from this system."
