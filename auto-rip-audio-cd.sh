#!/usr/bin/env sh
# Automated rip process of an audio CD.
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable

log_dir=${LOG_DIR:-"$HOME/logs/audio-rip"}
beets_config=${BEETS_CONFIG:-"$HOME/.config/beets/config.yaml"}

mkdir -p -- "$log_dir"
log_file="${log_dir}/rip-$(date +%Y-%m-%dT%H-%M-%S).log"

fn_log () {
    echo "### $*" | tee -a "$log_file"
}

fn_log "starting rip process with whipper"

# PYTHONIOENCODING: workaround for an issue: https://github.com/JoeLametta/whipper/issues/43
export PYTHONIOENCODING="utf-8"
whipper cd rip --unknown 2>&1 | tee -a "$log_file"
sc_whipper=$?

# grab the cover art
if [ $sc_whipper = 0 ]; then
    # example line:
    # INFO:whipper.image.cue:parsing .cue file u'unknown/Unknown Artist - m3JTAxsMcVKGGAiW6CKcaYJ5TG8-/Unknown Artist - m3JTAxsMcVKGGAiW6CKcaYJ5TG8-.cue'
    pattern="INFO:whipper\.image\.cue:parsing \.cue file u'.*.cue'"

    # replace the carriage returns with proper line breaks and search for the output pattern
    if cue_file_line=$(tr '\015' "\n" < "$log_file" | grep -E "$pattern"); then
        # remove the search pattern
        cue_file=$(echo $cue_file_line | sed "s/.*'\(.*\)'/\1/")
        output_path=$(dirname "$cue_file")
        fn_log "output path: $output_path"

        # Use beets for image grabbing if it is available.
        # Can be removed once this is implemented: https://github.com/JoeLametta/whipper/issues/50
        if type beet >/dev/null 2>&1; then
            fn_log "fetching cover art using beets"
            # -l: discard all additions to the library
            # -c: path to the config file
            # import: normally you import the file here and grab the cover alongside
            # -q: quiet - don't ask for user input. Either it works or forget about it
            echo a | beet -c "$beets_config" import "$output_path" >> "$log_file"
            exit $?
        else
            fn_log "failed to find beets to fetch the cover art"
        fi
    else
        fn_log "result: success (but couldn't find output folder for fetching cover art)"
    fi
else
    fn_log "whipper failed with status code ${sc_whipper}"
    exit $sc_whipper
fi

