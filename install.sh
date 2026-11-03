#!/usr/bin/env bash

# Stop the program if any of the lines fail
set -e

# cd where install script is stored to allow use of relative paths
cd "$(dirname "$0")"

# Check if running as root, if not write error and exit
if [[ $EUID -ne 0 ]]; then
    echo "Please run with sudo" >&2
    exit 1
fi

# Install will copy file to it's destination.
# 755 allows the script to be only edited by root, read and exectute by all
# 644 allows the service file to only be edited by root, read by all
install -Dm755 ssh-inhibit-sleep.sh /usr/local/bin/ssh-inhibit-sleep.sh
install -Dm644 ssh-inhibit-sleep.service /etc/systemd/system/ssh-inhibit-sleep.service

# Reload systemd so it sees the new service file, enable it and start it
systemctl daemon-reload
systemctl enable ssh-inhibit-sleep.service
systemctl restart ssh-inhibit-sleep.service

echo "Successfully installed ssh-inhibit-sleep and the service is now active."
