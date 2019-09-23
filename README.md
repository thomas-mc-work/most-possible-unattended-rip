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

It's the easiest way to run this project using docker. However it's still possible to run everything natively.

### Either: Docker based

    # grab the project
    curl -L https://github.com/thomas-mc-work/most-possible-unattended-rip/archive/master.tar.gz | tar xz
    
    # build the container
    docker build -t tmcw/mpur most-possible-unattended-rip-master

Finally put the start command into a convenient shell script, `$HOME/bin/mpur.sh`:

    #!/usr/bin/env sh
    
    # Prepare the working folders. Feel free do change these values.
    config_dir="$HOME/.config/whipper"
    output_dir="${HOME}/rip"
    log_dir="${output_dir}/_logs"
    
    [ ! -d "$config_dir" ] && mkdir -p "$config_dir"
    [ ! -d "$output_dir" ] && mkdir -p "$output_dir"
    [ ! -d "$log_dir" ] && mkdir -p "$log_dir"
    
    docker run --rm \
      --device=/dev/cdrom \
      -v "$config_dir:/home/worker/.config/whipper" \
      -v "$log_dir:/logs" \
      -v "$output_dir:/output" \
      tmcw/mpur

… and mark it executable: `chmod +x "$HOME/bin/mpur.sh"`

### Or: Native

1. [Install whipper](https://github.com/whipper-team/whipper) (you can also use the Docker based setup here. Just make sure it can be invoked by a `whipper` command anywhere)
2. Install beets:

        # Install beets via pip
        pip install --user beets
        # prepare the config folder and add the config
        mkdir -p "${HOME}/.config/beets"
        curl -Lo "${HOME}/.config/beets/config.cover.yaml" "https://raw.githubusercontent.com/thomas-mc-work/most-possible-unattended-rip/master/beets.yml"

3. Install MPUR:

        # prepare the folder by convention
        mkdir -p "${HOME}/bin"
        # Install the script and make it executable
        curl -Lo "${HOME}/bin/mpur.sh" "https://raw.githubusercontent.com/thomas-mc-work/most-possible-unattended-rip/master/auto-rip-audio-cd.sh"
        chmod +x "${HOME}/bin/mpur.sh"

## Usage

### Initial drive setup

First you're required to create a drive specific config file using whipper.

**Docker based:**

    docker run --rm \
      --device=/dev/cdrom \
      -v "$config_dir:/home/worker/.config/whipper" \
      joelametta/whipper drive analyze

**Native:**

    whipper drive analyze

This is only required once for each drive.

### Start rip process

Now you can simply execute the script after inserting the audio CD:

    mpur.sh

#### Parameters

THe native `mpur.sh` can be configured using some environment variables:

- `LOG_DIR`: override the default log files path (`$HOME/logs/audio-rip`)
- `BEETS_CONFIG`: override the default beets config file path (`$HOME/.config/beets/config.cover.yaml`)

## udev Integration

Add a udev rule to automatically trigger the script:

    echo "SUBSYSTEM==\"block\", SUBSYSTEMS==\"scsi\", KERNEL==\"sr?\", ENV{ID_TYPE}==\"cd\", ENV{ID_CDROM}==\"?*\", ENV{ID_CDROM_MEDIA_TRACK_COUNT_AUDIO}==\"?*\", ACTION==\"change\", RUN+=\"/bin/su -lc '/home/<username>/bin/mpur.sh' <username>\"" | sudo tee /etc/udev/rules.d/80-audio-cd.rules

Just be sure to substitute the placeholder `<username>` (or the entire script path) by the appropriate value. The script 
will be run with the according user permissions. This is important to get the correct locale settings in the environment.

### Config File Extension

Create a config file in your profiles config (`$HOME/.config`) folder:

If you want to use a config file then you're required to create an intermediate shell script that is invoked by the udev 
rule:

    # Install the script and mark it executable
    curl -Lo "${HOME}/bin/mpur-wrapper.sh" "https://raw.githubusercontent.com/thomas-mc-work/most-possible-unattended-rip/master/mpur_wrapper.sh"
    chmod +x "${HOME}/bin/mpur-wrapper.sh"

The config file (`~/.config/auto-rip.cfg`):

    # DISABLED={0,1}: Disable the script. Good if you like listen to some music CDs without instantly ripping them
    DISABLED=0
    # SHUTDOWN={0,1}: You can choose whether to automatically shutdown the system ofter the rip process has finished. 
    # This is good e.g. when going to bed and letting the system finish the last CD by itself. For using this you need to have the
    # permission to shutdown the system via the command line. You can achieve this by inserting 
    #     %sudo   ALL = NOPASSWD: /sbin/shutdown
    # into `/etc/sudoers`.
    SHUTDOWN=0
    # Shutdown timeout in minutes
    SHUTDOWN_TIMEOUT=3

## Links

- [whipper](https://github.com/JoeLametta/whipper)
- [good explanations and debug help with udev on arch wiki](https://wiki.archlinux.org/index.php/udev)
- [beets](http://beets.io/)

---

**Any comments, questions or pull requests are very welcome!**
