#!/usr/bin/env bash
# Intermediate script that decorates the rip process of mpur.sh by a configuration provided by an external file.
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

# end previous shutdown if one is active
sudo shutdown -c

# marker file for skipping the automated ripping
CONFIG_FILE="${HOME}/.config/auto-rip.cfg"

# include config file
if [ -f "$CONFIG_FILE" ]; then
    . "$CONFIG_FILE"
fi

# optionally omit the process by config setting
if [ "$DISABLED" = 1 ]; then
    echo "# omitting auto rip due to config setting"
    exit 0
fi

nice -n 19 ionice -c 3 mpur.sh

# reread the config file to include a late shutdown decision
if [ -f "$CONFIG_FILE" ]; then
    . "$CONFIG_FILE"
fi

# optionally shutdown after a short delay
if [ "$SHUTDOWN" = 1 ]; then
    echo "# shutting down the system"
    if ! [[ $SHUTDOWN_TIMEOUT =~ ^[0-9]+$ ]]; then SHUTDOWN_TIMEOUT=3; fi
    sudo shutdown -h $SHUTDOWN_TIMEOUT
fi
