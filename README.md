# arma3srv-script
Bash script for running Arma 3 on a linux server

**Required packages**

- rsync

- tmux

- steamcmd

- curl

- wget

- postfix (optional for email notifications)

- zip (optional but required if using the email feature)

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

**Instructions:**

Log in to your server with ssh and execute:

```git clone https://github.com/7thCore/arma3srv-script```

Make it executable:

```chmod +x ./arma3srv-script.bash```

The script will ask you for your steam username and password and will store it in a configuration file for automatic updates. The username and passwordare neded for the script to be able to update mods. If you are not planning to use mods you can use Steam's anonymous user. Also if you have Steam Guard on your mobile phone activated, disable it because steamcmd always asks for the two factor authentication code and breaks the auto update feature. Use Steam Guard via email.

Sometime between the installation process you will be prompted for steam's two factor authentication code and after that steamcmd will not ask you for another code once it runs if you are using steam guard via email.

Now for the installation.

If you wish you can have the script install the required packages with (Only for Arch Linux & Ubuntu 19.10):

```sudo ./arma3srv-script.bash -install_packages```

After that run the script with root permitions like so (necessary for user creation):

```sudo ./arma3srv-script.bash -install```

The script will create a new non-sudo enabled user from wich the game server will run. If you want to have multiple game servers on the same machine just run the script multiple times but with a diffrent username inputted to the script.


You can also install bash aliases to make your life easier with the following command:

```./arma3srv-script.bash -install_aliases```

After that relog.

Any other script commands are available with:

```./arma3srv-script.bash -help```

That should be it.

**Known issues are:**

-None at the moment
