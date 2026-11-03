#!/usr/bin/env bash
#
# ssh-inhibit-sleep.sh
# Prevent the system from sleeping while any SSH connection is active.
#
# Author:  Zack Elramly <github@zelram.com>
# Repo:    https://github.com/ZackElramly/ssh-inhibit-sleep
# SPDX-License-Identifier: MIT

PORT=22           # What port it checks for SSH connection on (Default: 22)
CHECK_INTERVAL=30 # how often the script checks for an active SSH session
inhibit_pid=""    # Variable to hold the Process ID of the Sleep inhibitor

# Function to check for any active network connections that match our port and stores the IPs
ssh_peers() {
    ss -Htn state established "( sport = :$PORT )" | awk '{print $4}'
}

# Function to start the inhibitor
acquire_inhibitor() {
    systemd-inhibit \
        --what=sleep:idle \
        --who="ssh-inhibit" \
        --why="Active SSH connection" \
        --mode=block \
        sleep infinity &
    # Once the inhibitor is started, this captures it's PID (The & in the line above
    # detaches the inhibitor and returns it's PID)
    inhibit_pid=$!
    echo "SSH connection detected from: $1 - acquired sleep inhibitor"
}

# Function to release the inhibitor
release_inhibitor() {
    # Ending the child 'sleep' makes systemd-inhibit exit cleanly, releasing the lock
    # the -P in pkill means kill any child with the parent of PID, not the main PID
    # itseelf, preventing isues with systemd-inhibit
    pkill -P "$inhibit_pid"
    # waits for the inhibitor to fully close before continuing
    wait "$inhibit_pid" 2>/dev/null
    inhibit_pid="" # reset PID to empty since we are no longer inhibiting
    echo "No SSH connections remain - released sleep inhibitor"
}

## START OF SCRIPT

# Trap signals either sent by Ctrl-C or systemctl stop
# when code received, check if there is an inhibitor running, if so run release_inhibitor
# then exit with code 0 to cleanly shutdown
# This is basically a oneline cleanup script
trap '[[ -n $inhibit_pid ]] && release_inhibitor; exit 0' SIGTERM SIGINT

echo "Watching for SSH connections on port $PORT"
# main loop that runs once every check interval
while true; do
    peers=$(ssh_peers) # check for any ssh connections
    # If there are any SSH connections and there is not an inhibitor running, then acquire_inhibitor
    if [[ -n $peers && -z $inhibit_pid ]]; then
        acquire_inhibitor "$(echo $peers)"
    # Otherwise, check if there are NO SSH connections, but we DO have an inhibitor, then release_inhibitor
    elif [[ -z $peers && -n $inhibit_pid ]]; then
        release_inhibitor
    fi
    # we release sleep with & and then wait on it's process with $! we do this to prevent
    # sleep from running in foreground so it does not stall the trap logic, since trap will
    # run instantly with wait but not with a sleep
    sleep "$CHECK_INTERVAL" &
    wait $!
done
