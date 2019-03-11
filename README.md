# Most Possible Unattended Rip Workflow

This project allows you to quickly rip a large collection of audio CD's only with the minimum of manual intervention: 
__insert cd - remove cd__

## Structure

This project comprises two components:

1. A wrapper shell script for:

    - ripping and tagging (using [whipper](https://github.com/whipper-team/whipper))
    - grab the cover art (using [beets](http://beets.io/))
    - eject the CD

2. (optional) A [udev](https://en.wikipedia.org/wiki/Udev) rule to automatically run the shell script when a CD is 
being inserted

## Installation (Docker based)

It's the easiest way to run this project using docker. However it's still possible to only use the script 
`auto-rip-audio-cd.sh`.

### Prepare the working folders

    # feel free do change these values
    config_dir="$HOME/.config/whipper"
    log_dir="$PWD/logs"
    output_dir="$PWD/output"
    
    [ ! -d "$config_dir" ] && mkdir -p "$config_dir"
    [ ! -d "$log_dir" ] && mkdir -p "$log_dir"
    [ ! -d "$output_dir" ] && mkdir -p "$output_dir"

### Build The Container

    # grab the project
    curl -L https://github.com/thomas-mc-work/most-possible-unattended-rip/archive/master.tar.gz | tar xz
    
    # build the container
    docker build -t tmcw/mpur most-possible-unattended-rip-master

## Usage

### Initial drive setup

First you're required to create a drive specific config file using whipper:

    docker run --rm \
      --device=/dev/cdrom \
      -v "$config_dir:/home/worker/.config/whipper" \
      joelametta/whipper drive analyze

This is only required once for each drive.

### Run The Container

    docker run --rm \
      --device=/dev/cdrom \
      -v "$config_dir:/home/worker/.config/whipper" \
      -v "$log_dir:/logs" \
      -v "$output_dir:/output" \
      tmcw/mpur

It's recommended to put this command into a shell script (e.g. `$HOME/bin/mpur.sh`)

## Classical Setup

### Installation

    # prepare the folders by convention
    mkdir -p "${HOME}/bin" "${HOME}/.config/beets"
    # Install the script and make it executable
    curl -Lo "${HOME}/bin/mpur.sh" "https://raw.githubusercontent.com/thomas-mc-work/most-possible-unattended-rip/master/auto-rip-audio-cd.sh"
    chmod +x "${HOME}/bin/mpur.sh"
    # Install beets via pip
    pip install --user beets
    # Add the beets configuration
    curl -Lo "${HOME}/.config/beets/config.yaml" "https://raw.githubusercontent.com/thomas-mc-work/most-possible-unattended-rip/master/beets.yml"

### Usage

Now you can simply execute the script after inserting the audio CD:

    $ mpur.sh

#### Parameters

- `LOG_DIR`: override the default log files path (`$HOME/logs/audio-rip`)
- `BEETS_CONFIG`: override the default beets config file path (`$HOME/.config/beets/config.yaml`)

## udev Integration

Add a udev rule to automatically trigger the script:

    echo "SUBSYSTEM==\"block\", SUBSYSTEMS==\"scsi\", KERNEL==\"sr?\", ENV{ID_TYPE}==\"cd\", ENV{ID_CDROM}==\"?*\", ENV{ID_CDROM_MEDIA_TRACK_COUNT_AUDIO}==\"?*\", ACTION==\"change\", RUN+=\"/bin/su -lc '/home/<username>/bin/mpur.sh' <username>\"" | sudo tee 80-audio-cd.rules

Just be sure to substitute the placeholder `<username>` (or the entire script path) by the appropriate value. The script 
will be run with the according user permissions. This is important to get the correct locale settings in the environment.

### Config File Extension

Create a config file in your profiles config (`$HOME/.config`) folder:

If you want to use a config file then you're required to create an intermediate shell script that is invoked by the udev 
rule (e.g. `$HOME/bin/mpur-wrapper.sh):

    #!/usr/bin/env bash

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

    nice -n 19 ionice -c 3 $HOME/mpur.sh

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

The config file:

    # disable auto ripping?
    DISABLED=0
    # shutdown after finish?
    SHUTDOWN=0
    # shutdown timeout in minutes
    SHUTDOWN_TIMEOUT=3

These options are available:

    - `DISABLED={0,1}`: Disable the script. Good if you like listen to some music CDs without instantly ripping them
    - `SHUTDOWN={0,1}`: You can choose whether to automatically shutdown the system ofter the rip process has finished. 
      This is good e.g. when going to bed and letting the system finish the last CD by itself. For using this you need to have the permission to shutdown the system via the command line. You can achieve this by inserting `%sudo   ALL = NOPASSWD: /sbin/shutdown` into `/etc/sudoers`.
    - `SHUTDOWN_TIMEOUT=<value>`: Lets you define the shutdown timeout

## Links

- [whipper](https://github.com/JoeLametta/whipper)
- [good explanations and debug help with udev on arch wiki](https://wiki.archlinux.org/index.php/udev)
- [beets](http://beets.io/)

---

**Any comments, questions or pull requests are very welcome!**
