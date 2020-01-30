# arma3srv-script
Bash script for running Arma 3 on a linux server with Antistasi mod integration 

-------------------------

# What does this script do?

This script creates a new non-sudo enabled user and installes the game in a folder called server in the user's home folder. It also installes systemd services for starting and shutting down the game server when the computer starts up, shuts down or reboots and also installs systemd timers so the script is executed on timed intervals (every 15 minutes) to do it's work like automatic game and mod updates and backups. It will also create a config file in the script folder that will save the configuration you defined between the installation process. The reason for user creation is to limit the script's privliges so it CAN NOT be used with sudo when handeling the game server. Sudo is only needed for installing the script (for user creation) and installing packages (it the script supports the distro you are running).

-------------------------

**Features:**

- auto backups

- auto updates

- script logging

- auto restart if crashed

- delete old backups

- delete old logs

- start on os boot

- shutdown gracefully on os shutdown

- script auto update from github (optional)

- send email notifications after 3 crashes within a 5 minute time limit (optional)

- send email notifications when server updated (optional)

- send email notifications on server startup (optional)

- send email notifications on server shutdown (optional)

- send discord notifications after 3 crashes within a 5 minute time limit (optional)

- send discord notifications when server updated (optional)

- send discord notifications on server startup (optional)

- send discord notifications on server shutdown (optional)

- supports multiple discord webhooks

-------------------------

# Supported distros

- Arch Linux

- Ubuntu 19.10

I will add suport for the next Ubuntu LTS version when it's released.

The script can, in theory run on any systemd-enabled distro. So if you are not using Arch Linux or Ubuntu 19.10 I suggest you check your distro's wiki on how to install the required packages. The script can, in theory install packages for any Ubuntu version, but the repositories for old versions of Ubuntu might have outdated packages and cause problems.

-------------------------

# WARNING

- Steam: A Steam username and password owning the game in question is needed to download all the needed files (workshop items and DLCs) and allow automated updates. If you want for automated updates for the game and mods enabled you are advised to enable Steam 2 factor authentication via email because Steam Guard via phone will ask for the authentication password every time the script runs a function using SteamCMD and will brake certain functions. Your steam credentials will be stored in the script's configuration file. If you are not comfortable with this you can disable auto updates for the game and mods. You will be however required to manually log in to the server and manually update each time an update is released and each time you will be prompted to enter your Steam credentials wich will not be saved on the server.

- Script updates from GitHub: These may include malicious code to steal any info the script uses to work, like Steam and email credentials and discord webhooks.
Now I'm not saying that I'm that kind of person that would do that but:

**IF YOU DON'T TRUST ME, LEAVE THIS OFF FOR SECURITY REASONS!**

-------------------------

# Installation

-------------------------

**Required packages**

- rsync

- tmux (minimum version: 2.9a)

- steamcmd 

- curl

- wget

- postfix (optional for email notifications)

- zip (optional but required if using the email feature)

-------------------------

**Download the script:**

Log in to your server with ssh and execute:

`git clone https://github.com/7thCore/arma3srv-script`

Make it executable:

`chmod +x ./arma3srv-script.bash`

The script will ask you for your steam username and password and will store it in a configuration file for automatic updates. The username and password are neded for the script to be able to update mods. If you are not planning to use mods you can use Steam's anonymous user. Also if you have Steam Guard on your mobile phone activated, disable it because steamcmd always asks for the two factor authentication code and breaks the auto update feature. Use Steam Guard via email.

Sometime between the installation process you will be prompted for steam's two factor authentication code and after that steamcmd will not ask you for another code once it runs if you are using steam guard via email.

-------------------------

**Installation:**

If you wish you can have the script install the required packages with (Only for Arch Linux & Ubuntu 19.10):

`sudo ./arma3srv-script.bash -install_packages`

After that run the script with root permitions like so (necessary for user creation):

`sudo ./arma3srv-script.bash -install`

You can also install bash aliases to make your life easier by logging in to the newly created user and executing the script with the following command:

`./arma3srv-script.bash -install_aliases`

After the installation finishes you can log in to the newly created user and fine tune your game configuration and then reboot the operating system and the service files will start the game server automaticly on boot.

-------------------------

# Available commands:

| Command | Description |
| ------- | ----------- |
| `-help` | Prints a list of commands and their description |
| `-start` | Start the server |
| `-stop` | Stop the server |
| `-restart` | Restart the server |
| `-backup` | Backup files, if server running or not |
| `-autobackup` | Automaticly backup files when server running |
| `-deloldbackup` | Delete old backups |
| `-delete_save` | Delete the server's save game with the option for deleting/keeping the server.cfg file |
| `-change_branch` | Changes the game branch in use by the server (public,experimental,legacy and so on) |
| `-rebuild_tmux_config` | Reinstalls the tmux configuration file from the script. Usefull if any tmux configuration updates occoured |
| `-rebuild_services` | Reinstalls the systemd services from the script. Usefull if any service updates occoured |
| `-disable_services` | Disables all services. The server and the script will not start up on boot anymore |
| `-enable_services` | Enables all services dependant on the configuration file of the script |
| `-reload_services` | Reloads all services, dependant on the configuration file |
| `-update` | Update the server, if the server is running it wil save it, shut it down, update it and restart it |
| `-update_mods` | Update the server mods, if the server is running it wil save it, shut it down, update it and restart it |
| `-update_script` | Check github for script updates and update if newer version available |
| `-update_script_force` | Get latest script from github and install it no matter what the version |
| `-status` | Display status of server |
| `-install` | Installs all the needed files for the script to run, systemd services and timers and the game |
| `-install_packages` | Installs all the needed packages (Supports only Arch linux & Ubuntu 19.10 and onward) |

-------------------------

**Known issues are:**

-None at the moment
