# Most Possible Unattended Rip Workflow

This project allows you to quickly rip a large collection of audio CD's only with the minimum of manual intervention: __insert cd - remove cd__

## Structure

This project comprises two components:

1. A shell script for the actual process:

    - riping, tagging and naming a CD using [whipper](https://github.com/JoeLametta/whipper)
    - grab the cover art using [beets](http://beets.io/)
    - eject the CD

2. (optional) __UDEV Integration__: A UDEV rule to automatically run the shell script when a CD is being inserted.

## Installation

First you need to download and extract the project:

    curl -L https://github.com/thomas-mc-work/most-possible-unattended-rip/archive/master.tar.gz | tar xz
    cd most-possible-unattended-rip-master

### Docker

At the moment it's required to build the whipper image yourself as the official Docker support is not yet integrated (https://github.com/JoeLametta/whipper/pull/237).

    git clone https://github.com/thomas-mc-work/whipper.git
    cd whipper
    git checkout -b dockerfile
    docker build -t whipper/whipper .
    # remove the sources again
    cd ..
    rm -rf whipper

#### Build The Image

    docker build -t tmcw/mpur .

#### Run The Container

    [ ! -d config ] && mkdir config
    [ ! -d logs ] && mkdir logs
    [ ! -d output ] && mkdir output

    docker run --rm \
      --device=/dev/cdrom \
      -v "${PWD}/config":/home/worker/.config/whipper \
      -v "${PWD}/logs":/logs \
      -v "${PWD}/output":/output \
      tmcw/mpur

### Native

    # Mark the script executable
    chmod +x auto-rip-audio-cd.sh
    # Install beets via pip
    pip install --user beets
    # Add the beets configuration
    curl -Lo "${HOME}/.config/beets/config.albums-cover.yaml https://raw.githubusercontent.com/thomas-mc-work/most-possible-unattended-rip/master/beets.yml

Now you can simply execute the script after inserting th audio CD:

    ./auto-rip-audio-cd.sh

### UDEV Integration

Add a UDEV rule to automatically trigger the script:

    echo "SUBSYSTEM==\"block\", SUBSYSTEMS==\"scsi\", KERNEL==\"sr?\", ENV{ID_TYPE}==\"cd\", ENV{ID_CDROM}==\"?*\", ENV{ID_CDROM_MEDIA_TRACK_COUNT_AUDIO}==\"?*\", ACTION==\"change\", RUN+=\"/bin/su -lc '<path-to-script>/auto-rip-audio-cd.sh' <username>\"" | sudo tee 80-audio-cd.rules

Just be sure to substitude the placeholders `<username>` and `<path-to-script>` by the appropriate values. The script will be run with the according user permissions. This is important to get the correct locale settings in the environment.

**Config File To Control The UDEV Automatism**

Create a config file in your profiles config (`$HOME/.config`) folder:

If you want to use a config file then you're required to create an intermediate shell script that is invoked by the UDEV rule:

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

    nice -n 19 ionice -c 3 /path/to/auto-rip-audio-cd.sh

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
    - `SHUTDOWN={0,1}`: You can choose whether to automatically shutdown the system ofter the rip process has finished. This is good e.g. when going to bed and letting the system finish the last CD by itself. For using this you need to have the permission to shutdown the system via the command line. You can achieve this by inserting `%sudo   ALL = NOPASSWD: /sbin/shutdown` into `/etc/sudoers`.
    - `SHUTDOWN_TIMEOUT=<value>`: Lets you define the shutdown timeout

## Links

- [whipper](https://github.com/JoeLametta/whipper)
- [good explanations and debug help with udev on arch wiki](https://wiki.archlinux.org/index.php/udev)
- [beets](http://beets.io/)

---

**Any comments, questions or PRs are very welcome!**