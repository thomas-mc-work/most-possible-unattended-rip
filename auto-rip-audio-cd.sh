#!/usr/bin/env bash
# automatisches rippen einer audio-cd
# https://github.com/JoeLametta/whipper
# Vorbereitung morituri:
# # rip offset find
# # rip drive analyze

LOG_DIR="$HOME/logs/audio-rip"
OUTPUT_DIR="$HOME/rip"

# ============

LOG_FILE="$LOG_DIR/rip-$(date +%Y-%m-%dT%H-%M-%S).log"

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
    echo "# omitting auto rip due to config setting" | tee -a "$LOG_FILE"
    exit 0
fi

echo "# auto rip started" | tee -a "$LOG_FILE"

# PYTHONIOENCODING: workaround for an issue: https://github.com/JoeLametta/whipper/issues/43
nice -n 19 ionice -c 3  rip cd rip --output-directory="$OUTPUT_DIR" -U true >>"$LOG_FILE" 2>&1
SC=$?
echo "# auto rip ended" | tee -a "$LOG_FILE"
echo "## SC: $SC"

# grab the cover art
if [ $SC == 0 ]; then
    # replace the carriage returns with proper line breaks and search for the output pattern
    FOLDER_LINE=$(tr '\015' "\n" < "${LOG_FILE}" | grep "utput directory")
    echo "# folder line: $FOLDER_LINE" >> "${LOG_FILE}"

    if [ "$FOLDER_LINE" == "" ]; then
        echo "# result: success (but couldn't find output folder for fetching cover art)" | tee -a "$LOG_FILE"
    else
        # remove the search pattern
        FOLDER=${FOLDER_LINE/Creating output directory /}
        echo "# output path: $FOLDER" >> "${LOG_FILE}"

        # if you have beets then grab image with beets
        # can be removed once this is closed: https://github.com/JoeLametta/whipper/issues/50
        if type beet >/dev/null 2>&1; then
            # -l: discard all additions to the library
            # -c: path to the config file
            # import: normally you import the file here and grab the cover alongside
            # -q: quiet - don't ask for user input. Either it works or forget about it
            beet -l /dev/null -c "$HOME/.config/beets/config.albums-cover.yaml" import -q "$FOLDER" >> "${LOG_FILE}"
            echo "# result: success" | tee -a "$LOG_FILE"
        fi
    fi
else
    echo "# result: no success with whipper/morituri: status code = ${SC}" | tee -a "$LOG_FILE"
    
    # if you have abcde then use it as fallback
    if type abcde >/dev/null 2>&1; then
        echo "# trying abcde" | tee -a "$LOG_FILE"
        abcde | tee -a "$LOG_FILE"
        SC=$?
        
        if [ $SC == 0 ]; then
            echo "# result: success with abcde" | tee -a "$LOG_FILE"
            eject
        else
            echo "# result: no success with abcde: status code = ${SC}" | tee -a "$LOG_FILE"
        fi
    fi
fi

# reread the config file to include a late shutdown decision
if [ -f "$CONFIG_FILE" ]; then
    . "$CONFIG_FILE"
fi

# optionally shutdown after a short delay
if [ "$SHUTDOWN" = 1 ]; then
    echo "# shutting down the system" | tee -a "$LOG_FILE"
    if ! [[ $SHUTDOWN_TIMEOUT =~ ^[0-9]+$ ]]; then SHUTDOWN_TIMEOUT=3; fi
    sudo shutdown -h $SHUTDOWN_TIMEOUT | tee -a "$LOG_FILE"
fi
