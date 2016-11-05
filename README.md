# Most possible unattended rip workflow

This is a script that allows you to quickly rip a large collection of audio cd's only with the minimum of manual intervention: __insert cd - remove cd__!

## Structure

This project comprises three parts:

1. A __shell script__:
    - rip a cd with [whipper](https://github.com/JoeLametta/whipper) (fka. morituri) with a very low cpu and storage usage priority
    - fall back to abcde if that fails
    - finally grab the cover art
    - eject the cd

2. (optional) A __udev rule__ to automatically run the shell script when a cd is being inserted.

3. (optional) A __config file__ which lets you do some decision regarding the shell script.

All steps within the script are well documented which makes it easy to customize it to any special needs. Furthermore this makes it easy for beginners to understand each step.

## Installation

1. Simply download the shell script and give it the executable flag:
    
    `wget https://github.com/thomas-mc-work/most-possible-unattended-rip/auto-rip-audio-cd.sh && chmod +x auto-rip-audio-cd.sh`
    
    1b. If you like to use have the script grabbing the cover for you then you need to install [beets](http://beets.io/) (`pip install beets`) and place a special config only for the cover grabbing process into `$HOME/.config/beets/config.albums-cover.yaml`:
    
        import:
            copy: no
            write: no
        
        plugins: fetchart

2. (optional) Add a udev rule to automatically trigger the script:

    `echo "SUBSYSTEM==\"block\", SUBSYSTEMS==\"scsi\", KERNEL==\"sr?\", ENV{ID_TYPE}==\"cd\", ENV{ID_CDROM}==\"?*\", ENV{ID_CDROM_MEDIA_TRACK_COUNT_AUDIO}==\"?*\", ACTION==\"change\", RUN+=\"/bin/su -lc '<path-to-script>/auto-rip-audio-cd.sh' <username>\"" | sudo tee 80-audio-cd.rules`

    It's important here to replace `<username>` and `<path-to-script>` with the appropriate values. The script will be run with the according user permissions. This is important to get the correct locale settings in the environment.

3. (optional) Download the config file template into your profiles config (`$HOME/.config`) folder:

    `wget https://github.com/thomas-mc-work/most-possible-unattended-rip/auto-rip.cfg -O $HOME/.config/auto-rip.cfg`

    These options are available:

    - `DISABLED={0,1}`: Disable the script. Good if you like listen to some music CDs without instantly ripping them
    - `SHUTDOWN={0,1}`: You can choose whether to automatically shutdown the system ofter the rip process has finished. This is good e.g. when going to bed and letting the system finish the last CD by itself. For using this you need to have the permission to shutdown the system via the command line. You can achieve this by inserting `%sudo   ALL = NOPASSWD: /sbin/shutdown` into `/etc/sudoers`.
    - `SHUTDOWN_TIMEOUT=3`: Lets you define the shutdown timeout

## Links

- [whipper](https://github.com/JoeLametta/whipper)
- [good explanations and debug help with udev on arch wiki](https://wiki.archlinux.org/index.php/udev)
- [beets](http://beets.io/)

Any comments, questions or PRs are very welcome!