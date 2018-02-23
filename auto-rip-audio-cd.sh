#!/usr/bin/env bash
# Automated rip process of an audio CD.
set -u

log_dir=${LOG_DIR:-"$HOME/logs/audio-rip"}
output_dir=${OUTPUT_DIR:-"$HOME/rip"}
beets_config=${BEETS_CONFIG:-"$HOME/.config/beets/config.albums-cover.yaml"}

log_file="${log_dir}/rip-$(date +%Y-%m-%dT%H-%M-%S).log"

fn_log () {
    echo "### $*" | tee -a "$log_file"
}

fn_log "auto rip started"

# PYTHONIOENCODING: workaround for an issue: https://github.com/JoeLametta/whipper/issues/43
export PYTHONIOENCODING="utf-8"
whipper cd rip --output-directory="$output_dir" -U >> "$log_file" 2>&1
sc_whipper=$?

# grab the cover art
if [ $sc_whipper == 0 ]; then
    fn_log "whipper rip finished"
    
    # replace the carriage returns with proper line breaks and search for the output pattern
    folder_line=$(tr '\015' "\n" < "$log_file" | grep "utput directory")

    if [ -z "$folder_line" ]; then
        fn_log "result: success (but couldn't find output folder for fetching cover art)"
    else
        # remove the search pattern
        output_path=${folder_line/Creating output directory /}
        fn_log "output path: $output_path"

        # Use beets for image grabbing if it is available.
        # Can be removed once this is implemented: https://github.com/JoeLametta/whipper/issues/50
        if type beet >/dev/null 2>&1; then
            # -l: discard all additions to the library
            # -c: path to the config file
            # import: normally you import the file here and grab the cover alongside
            # -q: quiet - don't ask for user input. Either it works or forget about it
            echo a | beet -c "$beets_config" import "$output_path" >> "$log_file"
            sc_beets=$?
            fn_log "beet result: ${sc_beets}"
            exit $sc_beets
        fi
    fi
else
    fn_log "failed to rip: ${sc_whipper}"
    exit $sc_whipper
fi

