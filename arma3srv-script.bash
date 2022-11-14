#!/bin/bash

#    Copyright (C) 2022 7thCore
#    This file is part of Arma3Srv-Script.
#
#    Arma3Srv-Script is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    Arma3Srv-Script is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

#Arma 3 server script by 7thCore
#If you do not know what any of these settings are you are better off leaving them alone. One thing might brake the other if you fiddle around with it.

#Static script variables
export NAME="Arma3Srv" #Name of the tmux session
export VERSION="1.1-3" #Package and script version
export SERVICE_NAME="arma3srv" #Name of the service files, user, script and script log
export LOG_DIR="/srv/$SERVICE_NAME/logs" #Location of the script's log files.
export LOG_STRUCTURE="$LOG_DIR/$(date +"%Y")/$(date +"%m")/$(date +"%d")" #Folder structure of the script's log files.
export LOG_SCRIPT="$LOG_STRUCTURE/$SERVICE_NAME-script.log" #Script log.
SRV_DIR="$SRV_DIR" #Location of the server located on your hdd/ssd.
CONFIG_DIR="/srv/$SERVICE_NAME/config" #Location of this script's configuration.
UPDATE_DIR="$UPDATE_DIR" #Location of update information for the script's automatic update feature.
BCKP_DIR="/srv/$SERVICE_NAME/backups" #Location of stored backups
BCKP_STRUCTURE="$(date +"%Y")/$(date +"%m")/$(date +"%d")" #How backups are sorted, by default it's sorted in folders by month and day.

#Static game variables
APPID="233780" #Steam app id for the server
WORKSHOP_APPID="107410" #Steam app id for the workshop

#Script config file variables
BCKP_DELOLD=$(cat $CONFIG_DIR/$SERVICE_NAME-script.conf 2> /dev/null | grep script_bckp_delold= | cut -d = -f2) #Delete old backups.
LOG_DELOLD=$(cat $CONFIG_DIR/$SERVICE_NAME-script.conf 2> /dev/null | grep script_log_delold= | cut -d = -f2) #Delete old logs.
UPDATE_IGNORE_FAILED_ACTIVATIONS=$(cat $CONFIG_DIR/$SERVICE_NAME-script.conf 2> /dev/null | grep script_update_ignore_failed_startups= | cut -d = -f2) #Ignore failed startups during update configuration

#Script config variables if config doesn't exist
BCKP_DELOLD=${BCKP_DELOLD:="7"} #If the variable for old backup deletion is not defined, assign a default value.
LOG_DELOLD=${LOG_DELOLD:="7"} #If the variable for old log deletion is not defined, assign a default value.
UPDATE_IGNORE_FAILED_ACTIVATIONS=$(cat $CONFIG_DIR/$SERVICE_NAME-script.conf 2> /dev/null | grep script_update_ignore_failed_startups= | cut -d = -f2) #Defines if errors during startup after updates should be ignored.

#Steamcmd config file variables
STEAMCMD_UID=$(cat $CONFIG_DIR/$SERVICE_NAME-steam.conf 2> /dev/null | grep steamcmd_username= | cut -d = -f2) #Defines your steam username.
STEAMCMD_PSW=$(cat $CONFIG_DIR/$SERVICE_NAME-steam.conf 2> /dev/null | grep steamcmd_password= | cut -d = -f2) #Defines your steam password.
STEAMCMD_BETA_BRANCH=$(cat $CONFIG_DIR/$SERVICE_NAME-steam.conf 2> /dev/null | grep steamcmd_beta_branch= | cut -d = -f2) #Defines if the beta branch is enabled.
STEAMCMD_BETA_BRANCH_NAME=$(cat $CONFIG_DIR/$SERVICE_NAME-steam.conf 2> /dev/null | grep steamcmd_beta_branch_name= | cut -d = -f2) #Defines the beta branch name.
STEAMGUARD_CLI=$(cat $CONFIG_DIR/$SERVICE_NAME-steam.conf 2> /dev/null | grep steamguard_cli= | cut -d = -f2) #Defines usage of steamguard_cli.

#Steamcmd config variables if config doesn't exist
STEAMCMD_UID=${STEAMCMD_UID:="disabled"} #If the variable for steam username is not defined, assign a default value.
STEAMCMD_PSW=${STEAMCMD_PSW:="disabled"} #If the variable for steam password is not defined, assign a default value.
STEAMCMD_BETA_BRANCH=${STEAMCMD_BETA_BRANCH:="0"} #If the variable for steam beta branch selection is not defined, assign a default value.
STEAMCMD_BETA_BRANCH_NAME=${STEAMCMD_BETA_BRANCH_NAME:="none"} #If the variable for steam beta branch name is not defined, assign a default value.
STEAMGUARD_CLI=${STEAMGUARD_CLI:="0"} #If the variable for steam guard is not defined, assign a default value.

#Mod config file variables
MODS_ENABLED=$(cat $SCRIPT_DIR/$SERVICE_NAME-mods.conf 2> /dev/null | grep mods_enabled= | cut -d = -f2) #Are mods enabled?
MODS=$(cat $SCRIPT_DIR/$SERVICE_NAME-mods.conf 2> /dev/null | grep mod_list | cut -d = -f2) #Get mod list

#Mod config variables if config doesn't exist
MODS_ENABLED=${MODS_ENABLED:="0"} #If the variable for steam username is not defined, assign a default value.
MODS=${MODS:="0"} #If the variable for steam username is not defined, assign a default value.

#Discord config file variables
DISCORD_UPDATE=$(cat $CONFIG_DIR/$SERVICE_NAME-discord.conf 2> /dev/null | grep discord_update= | cut -d = -f2) #Send notification when the server updates.
DISCORD_START=$(cat $CONFIG_DIR/$SERVICE_NAME-discord.conf 2> /dev/null | grep discord_start= | cut -d = -f2) #Send notifications when the server starts.
DISCORD_STOP=$(cat $CONFIG_DIR/$SERVICE_NAME-discord.conf 2> /dev/null | grep discord_stop= | cut -d = -f2) #Send notifications when the server stops.
DISCORD_CRASH=$(cat $CONFIG_DIR/$SERVICE_NAME-discord.conf 2> /dev/null | grep discord_crash= | cut -d = -f2) #Send notifications when the server crashes.
DISCORD_TMPFS_SPACE=$(cat $CONFIG_DIR/$SERVICE_NAME-discord.conf 2> /dev/null | grep discord_tmpfs_space= | cut -d = -f2) #Send notifications if tmpfs space is over the designated percentage.
DISCORD_COLOR_PRESTART=$(cat $CONFIG_DIR/$SERVICE_NAME-discord.conf 2> /dev/null | grep discord_color_prestart= | cut -d = -f2) #Discord embed color for prestart.
DISCORD_COLOR_POSTSTART=$(cat $CONFIG_DIR/$SERVICE_NAME-discord.conf 2> /dev/null | grep discord_color_poststart= | cut -d = -f2) #Discord embed color for poststart.
DISCORD_COLOR_PRESTOP=$(cat $CONFIG_DIR/$SERVICE_NAME-discord.conf 2> /dev/null | grep discord_color_prestop= | cut -d = -f2) #Discord embed color for prestop.
DISCORD_COLOR_POSTSTOP=$(cat $CONFIG_DIR/$SERVICE_NAME-discord.conf 2> /dev/null | grep discord_color_poststop= | cut -d = -f2) #Discord embed color for poststop.
DISCORD_COLOR_UPDATE=$(cat $CONFIG_DIR/$SERVICE_NAME-discord.conf 2> /dev/null | grep discord_color_update= | cut -d = -f2) #Discord embed color for update.
DISCORD_COLOR_CRASH=$(cat $CONFIG_DIR/$SERVICE_NAME-discord.conf 2> /dev/null | grep discord_color_crash= | cut -d = -f2) #Discord embed color for crash.

#Discord config variables if config doesn't exist
DISCORD_UPDATE=${DISCORD_UPDATE:="0"} #If the variable for discord update is not defined, assign a default value.
DISCORD_START=${DISCORD_START:="0"} #If the variable for discord start is not defined, assign a default value.
DISCORD_STOP=${DISCORD_STOP:="0"} #If the variable for discord stop is not defined, assign a default value.
DISCORD_CRASH=${DISCORD_CRASH:="0"} #If the variable for discord crash is not defined, assign a default value.
DISCORD_TMPFS_SPACE=${DISCORD_TMPFS_SPACE:="0"} #If the variable for discord tmpfs space is not defined, assign a default value.
DISCORD_COLOR_PRESTART=${DISCORD_COLOR_PRESTART:="16776960"} #If the variable discord pre-start color is not defined, assign a default value.
DISCORD_COLOR_POSTSTART=${DISCORD_COLOR_POSTSTART:="65280"} #If the variable discord post-start color is not defined, assign a default value.
DISCORD_COLOR_PRESTOP=${DISCORD_COLOR_PRESTOP:="16776960"} #If the variable discord pre-stop color is not defined, assign a default value.
DISCORD_COLOR_POSTSTOP=${DISCORD_COLOR_POSTSTOP:="65280"} #If the variable discord post-stop color is not defined, assign a default value.
DISCORD_COLOR_UPDATE=${DISCORD_COLOR_UPDATE:="47083"} #If the variable discord update color is not defined, assign a default value.
DISCORD_COLOR_CRASH=${DISCORD_COLOR_CRASH:="16711680"} #If the variable for discord crash color is not defined, assign a default value.

#Email config file variables
EMAIL_SENDER=$(cat $CONFIG_DIR/$SERVICE_NAME-email.conf 2> /dev/null | grep email_sender= | cut -d = -f2) #Send emails from this address.
EMAIL_RECIPIENT=$(cat $CONFIG_DIR/$SERVICE_NAME-email.conf 2> /dev/null | grep email_recipient= | cut -d = -f2) #Send emails to this address.
EMAIL_UPDATE=$(cat $CONFIG_DIR/$SERVICE_NAME-email.conf 2> /dev/null | grep email_update= | cut -d = -f2) #Send emails when server updates.
EMAIL_START=$(cat $CONFIG_DIR/$SERVICE_NAME-email.conf 2> /dev/null | grep email_start= | cut -d = -f2) #Send emails when the server starts up.
EMAIL_STOP=$(cat $CONFIG_DIR/$SERVICE_NAME-email.conf 2> /dev/null | grep email_stop= | cut -d = -f2) #Send emails when the server shuts down.
EMAIL_CRASH=$(cat $CONFIG_DIR/$SERVICE_NAME-email.conf 2> /dev/null | grep email_crash= | cut -d = -f2) #Send emails when the server crashes.

#Email config variables if config doesn't exist
EMAIL_SENDER=${EMAIL_SENDER:="none"} #If the variable for email sender is not defined, assign a default value.
EMAIL_RECIPIENT=${EMAIL_RECIPIENT:="none"} #If the variable for email recipient is not defined, assign a default value.
EMAIL_UPDATE=${EMAIL_UPDATE:="0"} #If the variable for email update is not defined, assign a default value.
EMAIL_START=${EMAIL_START:="0"} #If the variable for email start is not defined, assign a default value.
EMAIL_STOP=${EMAIL_STOP:="0"} #If the variable for email stop is not defined, assign a default value.
EMAIL_CRASH=${EMAIL_CRASH:="0"} #If the variable for email crash is not defined, assign a default value.

#Console collors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
LIGHTRED='\033[1;31m'
NC='\033[0m'

#-------Do not edit anything beyond this line-------

#Generate log folder structure
script_logs() {
	#If there is not a folder for today, create one
	if [ ! -d "$LOG_STRUCTURE" ]; then
		mkdir -p $LOG_STRUCTURE
	fi
}

#---------------------------

#Discord webhook message send
script_discord_message() {
		while IFS="" read -r DISCORD_WEBHOOK || [ -n "$DISCORD_WEBHOOK" ]; do
			curl -H "Content-Type: application/json" -X POST -d "{\"embeds\": [{ \"author\": { \"name\": \"$NAME Script\", \"url\": \"https://github.com/7thCore/$SERVICE_NAME-script\" }, \"color\": \"$1\", \"description\": \"$2\", \"footer\": {\"text\": \"Version $VERSION\"}, \"timestamp\": \"$(date -u --iso-8601=seconds)\"}] }" "$DISCORD_WEBHOOK"
		done < $CONFIG_DIR/discord_webhooks.txt
}

#--------------------------

#Send email message
script_email_message() {
	mail -r "$EMAIL_SENDER ($1)" -s "$2" $EMAIL_RECIPIENT <<- EOF
	$3
	EOF
}

#--------------------------

#Attaches to the server tmux session
script_attach() {
	script_logs
	tmux -L $SERVICE_NAME-tmux.sock has-session -t $NAME 2>/dev/null
	if [ $? == 0 ]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Attach) User attached to server session with ID: $1" | tee -a "$LOG_SCRIPT"
		tmux -L $SERVICE_NAME-tmux.sock attach -t $NAME
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Attach) User deattached from server session with ID: $1" | tee -a "$LOG_SCRIPT"
	else
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Attach) Failed to attach to server session with ID: $1" | tee -a "$LOG_SCRIPT"
	fi
}

#--------------------------

#Deletes old files
script_remove_old_files() {
	script_logs
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Remove old files) Beginning removal of old files." | tee -a "$LOG_SCRIPT"
	#Delete old logs
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Remove old files) Removing old script logs: $LOG_DELOLD days old." | tee -a "$LOG_SCRIPT"
	find $LOG_DIR/* -mtime +$LOG_DELOLD -delete
	#Delete empty folders
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Remove old files) Removing empty script log folders." | tee -a "$LOG_SCRIPT"
	find $LOG_DIR/ -type d -empty -delete
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Remove old files) Removal of old files complete." | tee -a "$LOG_SCRIPT"
}

#---------------------------

#Prints out if the server is running
script_status() {
	script_logs
	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "inactive" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Status) Server is not running." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Status) Server running." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "failed" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Status) Server is in failed state. Please check logs." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "activating" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Status) Server is activating. Please wait." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "deactivating" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Status) Server is in deactivating. Please wait." | tee -a "$LOG_SCRIPT"
	fi
}

#---------------------------

#Disable all script services
script_disable_services() {
	script_logs
	if [[ "$(systemctl --user show -p UnitFileState --value $SERVICE_NAME.service)" == "enabled" ]]; then
		systemctl --user disable $SERVICE_NAME.service
	fi
	if [[ "$(systemctl --user show -p UnitFileState --value $SERVICE_NAME-timer-1.timer)" == "enabled" ]]; then
		systemctl --user disable $SERVICE_NAME-timer-1.timer
	fi
	if [[ "$(systemctl --user show -p UnitFileState --value $SERVICE_NAME-timer-2.timer)" == "enabled" ]]; then
		systemctl --user disable $SERVICE_NAME-timer-2.timer
	fi
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Disable services) Services successfully disabled." | tee -a "$LOG_SCRIPT"
}

#---------------------------

#Disables all script services, available to the user
script_disable_services_manual() {
	script_logs
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Disable services) WARNING: This will disable all script services. The server will be disabled." | tee -a "$LOG_SCRIPT"
	read -p "Are you sure you want to disable all services? (y/n): " DISABLE_SCRIPT_SERVICES
	if [[ "$DISABLE_SCRIPT_SERVICES" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		script_disable_services
	elif [[ "$DISABLE_SCRIPT_SERVICES" =~ ^([nN][oO]|[nN])$ ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Disable services) Disable services canceled." | tee -a "$LOG_SCRIPT"
	fi
}

#---------------------------

# Enable script services by reading the configuration file
script_enable_services() {
	script_logs
	if [[ "$(systemctl --user show -p UnitFileState --value $SERVICE_NAME.service)" == "disabled" ]]; then
		systemctl --user enable $SERVICE_NAME.service
	fi
	if [[ "$(systemctl --user show -p UnitFileState --value $SERVICE_NAME-timer-1.timer)" == "disabled" ]]; then
		systemctl --user enable $SERVICE_NAME-timer-1.timer
	fi
	if [[ "$(systemctl --user show -p UnitFileState --value $SERVICE_NAME-timer-2.timer)" == "disabled" ]]; then
		systemctl --user enable $SERVICE_NAME-timer-2.timer
	fi
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Enable services) Services successfully Enabled." | tee -a "$LOG_SCRIPT"
}

#---------------------------

# Enable script services by reading the configuration file, available to the user
script_enable_services_manual() {
	script_logs
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Enable services) This will enable all script services. The server will be enabled." | tee -a "$LOG_SCRIPT"
	read -p "Are you sure you want to enable all services? (y/n): " ENABLE_SCRIPT_SERVICES
	if [[ "$ENABLE_SCRIPT_SERVICES" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		script_enable_services
	elif [[ "$ENABLE_SCRIPT_SERVICES" =~ ^([nN][oO]|[nN])$ ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Enable services) Enable services canceled." | tee -a "$LOG_SCRIPT"
	fi
}

#---------------------------

#Disables all script services an re-enables them by reading the configuration file
script_reload_services() {
	script_logs
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Reload services) This will reload all script services." | tee -a "$LOG_SCRIPT"
	read -p "Are you sure you want to reload all services? (y/n): " RELOAD_SCRIPT_SERVICES
	if [[ "$RELOAD_SCRIPT_SERVICES" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		script_disable_services
		systemctl --user daemon-reload
		script_enable_services
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Reload services) Reload services complete." | tee -a "$LOG_SCRIPT"
	elif [[ "$RELOAD_SCRIPT_SERVICES" =~ ^([nN][oO]|[nN])$ ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Reload services) Reload services canceled." | tee -a "$LOG_SCRIPT"
	fi
}

#---------------------------

#Pre-start functions to be called by the systemd service
script_prestart() {
	script_logs
	if [[ "$DISCORD_START" == "1" ]]; then
		script_discord_message "$DISCORD_COLOR_PRESTART" "Server startup for $1 was initialized."
	fi
	if [[ "$EMAIL_START" == "1" ]]; then
		script_email_message "$NAME-$1" "Notification: Server startup $1" "Server startup for $1 was initialized at $(date +"%d.%m.%Y %H:%M:%S")"
	fi
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Start) Server startup was initialized." | tee -a "$LOG_SCRIPT"
}

#---------------------------

#Post-start functions to be called by the systemd service
script_poststart() {
	script_logs
	if [[ "$DISCORD_START" == "1" ]]; then
		script_discord_message "$DISCORD_COLOR_POSTSTART" "Server startup for $1 complete."
	fi
	if [[ "$EMAIL_START" == "1" ]]; then
		script_email_message "$NAME-$1" "Notification: Server startup $1" "Server startup for $1 was completed at $(date +"%d.%m.%Y %H:%M:%S")"
	fi
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Start) Server startup complete." | tee -a "$LOG_SCRIPT"
}

#---------------------------

#Pre-stop functions to be called by the systemd service
script_prestop() {
	script_logs
	if [[ "$DISCORD_STOP" == "1" ]]; then
		script_discord_message "$DISCORD_COLOR_PRESTOP" "Server shutdown for $1 was initialized."
	fi
	if [[ "$EMAIL_STOP" == "1" ]]; then
		script_email_message "$NAME-$1" "Notification: Server shutdown $1" "Server shutdown was initiated at $(date +"%d.%m.%Y %H:%M:%S")"
	fi
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Stop) Server shutdown was initialized." | tee -a "$LOG_SCRIPT"
}

#---------------------------

#Post-stop functions to be called by the systemd service
script_poststop() {
	script_logs

	#Check if the server is still running, if it is wait for it to stop.
	while true; do
		tmux -L $SERVICE_NAME-tmux.sock has-session -t $NAME 2>/dev/null
		if [ $? -eq 1 ]; then
			break
		fi
		sleep 1
	done

	if [ -f "/tmp/$SERVICE_NAME-tmux.log" ]; then
		rm /tmp/$SERVICE_NAME-tmux.log
	fi

	if [ -f "/tmp/$SERVICE_NAME-tmux.conf" ]; then
		rm /tmp/$SERVICE_NAME-tmux.conf
	fi

	if [[ "$DISCORD_STOP" == "1" ]]; then
		script_discord_message "$DISCORD_COLOR_POSTSTOP" "Server shutdown for $1 complete."
	fi
	if [[ "$EMAIL_STOP" == "1" ]]; then
		script_email_message "$NAME-$1" "Notification: Server shutdown $1" "Server shutdown was complete at $(date +"%d.%m.%Y %H:%M:%S")"
	fi
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Stop) Server shutdown complete." | tee -a "$LOG_SCRIPT"
}

#---------------------------

#Start the server
script_start() {
	script_logs

	#Loop until the server is active and output the state of it
	script_start_loop() {
		while [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "activating" ]]; do
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Start) Server is activating. Please wait..." | tee -a "$LOG_SCRIPT"
			sleep 1
		done
		if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Start) Server has been successfully activated." | tee -a "$LOG_SCRIPT"
			sleep 1
		elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "failed" ]]; then
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Start) Server failed to activate. See systemctl --user status $SERVICE for details." | tee -a "$LOG_SCRIPT"
			sleep 1
		fi
	}

	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "inactive" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Start) Server start initialized." | tee -a "$LOG_SCRIPT"
		systemctl --user start $SERVICE
		script_start_loop
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Start) Server is already running." | tee -a "$LOG_SCRIPT"
		sleep 1
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "failed" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Start) Server is in failed state. See systemctl --user status $SERVICE for details." | tee -a "$LOG_SCRIPT"
		if [[ "$1" == "ignore" ]]; then
			systemctl --user start $SERVER_SERVICE
			script_start_loop $SERVER_SERVICE
		else
			read -p "Do you still want to start the server? (y/n): " FORCE_START
			if [[ "$FORCE_START" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				systemctl --user start $SERVER_SERVICE
				script_start_loop $SERVER_SERVICE
			fi
		fi
	fi
}

#---------------------------

#Stop the server
script_stop() {
	script_logs
	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "inactive" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Stop) Server is not running." | tee -a "$LOG_SCRIPT"
		sleep 1
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Stop) Server shutdown in progress." | tee -a "$LOG_SCRIPT"
		systemctl --user stop $SERVICE
		sleep 1
		while [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "deactivating" ]]; do
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Stop) Server is deactivating. Please wait..." | tee -a "$LOG_SCRIPT"
			sleep 1
		done
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Stop) Server is deactivated." | tee -a "$LOG_SCRIPT"
	fi
}

#---------------------------

#Restart the server
script_restart() {
	script_logs
	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "inactive" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Restart) Server is not running. Use -start to start the server." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "activating" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Restart) Server is activating. Aborting restart." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "deactivating" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Restart) Server is in deactivating. Aborting restart." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Restart) Server is going to restart in 15-30 seconds, please wait..." | tee -a "$LOG_SCRIPT"
		sleep 1
		script_stop
		sleep 1
		script_start
		sleep 1
	fi
}

#---------------------------

#Systemd service sends email if email notifications for crashes enabled
script_send_notification_crash() {
	script_logs
	if [ ! -d "$CRASH_DIR" ]; then
		mkdir -p "$CRASH_DIR"
	fi

	systemctl --user status $SERVICE > $CRASH_DIR/service_log.txt
	zip -j $CRASH_DIR/service_logs.zip $CRASH_DIR/service_log.txt
	zip -j $CRASH_DIR/script_logs.zip $LOG_SCRIPT
	rm $CRASH_DIR/service_log.txt

	if [[ "$DISCORD_CRASH" == "1" ]]; then
		script_discord_message "$DISCORD_COLOR_CRASH" "Server crashed 3 times in the last 5 minutes.\nAutomatic restart is disabled and the server is inactive.\n\nPlease review your logs located in $LOG_STRUCTURE/Server-crash_$CRASH_TIME."
	fi

	if [[ "$EMAIL_CRASH" == "1" ]]; then
		mail -a $CRASH_DIR/service_logs.zip -a $CRASH_DIR/script_logs.zip -r "$EMAIL_SENDER ($NAME-$SERVICE_NAME)" -s "Notification: Crash" $EMAIL_RECIPIENT <<- EOF
		The server crashed 3 times in the last 5 minutes. Automatic restart is disabled and the server is inactive. Please check the logs for more information.

		Attachment contents:
		service_logs.zip - Logs from the systemd service
		script_logs.zip - Logs from the script

		DO NOT SEND ANY OF THESE TO THE DEVS!
		EOF
	fi

	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Crash) Server crashed. Please review your logs located in $CRASH_DIR." | tee -a "$LOG_SCRIPT"
}

#--------------------------

#Creates a backup of the server
script_backup() {
	script_logs

	#If there is not a folder for today, create one
	script_backup_create_folder() {
		if [ ! -d "$BCKP_DIR/$BCKP_STRUCTURE" ]; then
			mkdir -p "$BCKP_DIR/$BCKP_STRUCTURE"
		fi
	}

	#Backup source to destination
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Backup) Backup has been initiated." | tee -a  "$LOG_SCRIPT"
	if [[ "$(systemctl --user show -p ActiveState --value $SERVER_SERVICE)" != "active" ]] && [[ "$(systemctl --user show -p UnitFileState --value $SERVER_SERVICE)" == "enabled" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Autobackup) Server is not running." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVER_SERVICE)" == "active" ]] && [[ "$(systemctl --user show -p UnitFileState --value $SERVER_SERVICE)" == "enabled" ]]; then
		script_backup_create_folder
		cd "/srv/$SERVICE_NAME/.local/share"
		tar -cpvzf $BCKP_DIR/$BCKP_STRUCTURE/$(date +"%Y%m%d%H%M").tar.gz /srv/$SERVICE_NAME/.local/share/Arma*
	fi
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Backup) Backup complete." | tee -a  "$LOG_SCRIPT"
}

#--------------------------

#Get steam credentials for script operations
script_steamcmd_credentials() {
	while [[ "$STEAMCMDSUCCESS" != "0" ]]; do
		read -p "Enter your Steam username: " STEAMCMD_UID
		echo ""
		read -p "Enter your Steam password: " STEAMCMD_PSW
		steamcmd +login $STEAMCMD_UID $STEAMCMD_PSW +quit
		STEAMCMDSUCCESS=$?
		if [[ "$STEAMCMDSUCCESS" == "0" ]]; then
			echo "Steam login for $STEAMCMD_UID: SUCCEDED!"
		elif [[ "$STEAMCMDSUCCESS" != "0" ]]; then
			echo "Steam login for $STEAMCMD_UID: FAILED!"
			echo "Please try again."
		fi
	done
}

#--------------------------

#Change the steam branch of the app
script_change_branch() {
	script_logs
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Change branch) Server branch change initiated. Waiting on user configuration." | tee -a "$LOG_SCRIPT"
	if [[ "$STEAMCMD_UID" == "disabled" ]] && [[ "$STEAMCMD_PSW" == "disabled" ]]; then
		script_steamcmd_credentials
	fi

	read -p "Are you sure you want to change the server branch? (y/n): " CHANGE_SERVER_BRANCH
	if [[ "$CHANGE_SERVER_BRANCH" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Change branch) Clearing game installation." | tee -a "$LOG_SCRIPT"
		rm -rf $SRV_DIR/*
		if [[ "$STEAMCMD_BETA_BRANCH" == "1" ]]; then
			PUBLIC_BRANCH="0"
		elif [[ "$STEAMCMD_BETA_BRANCH" == "0" ]]; then
			PUBLIC_BRANCH="1"
		fi
		echo "Current configuration:"
		echo 'Public branch: '"$PUBLIC_BRANCH"
		echo 'Beta branch enabled: '"$STEAMCMD_BETA_BRANCH"
		echo 'Beta branch name: '"$STEAMCMD_BETA_BRANCH_NAME"
		echo ""
		read -p "Public branch or beta branch? (public/beta): " SET_BRANCH_STATE
		echo ""
		if [[ "$SET_BRANCH_STATE" =~ ^([bB][eE][tT][aA]|[bB])$ ]]; then
			STEAMCMD_BETA_BRANCH="1"
			echo "Look up beta branch names at https://steamdb.info/app/$APPID/depots/"
			echo "Name example: experimental"
			read -p "Enter beta branch name: " STEAMCMD_BETA_BRANCH_NAME
		elif [[ "$SET_BRANCH_STATE" =~ ^([pP][uU][bB][lL][iI][cC]|[pP])$ ]]; then
			STEAMCMD_BETA_BRANCH="0"
			STEAMCMD_BETA_BRANCH_NAME="none"
		fi
		sed -i '/beta_branch_enabled/d' $SCRIPT_DIR/$SERVICE_NAME-steam.conf
		sed -i '/beta_branch_name/d' $SCRIPT_DIR/$SERVICE_NAME-steam.conf
		echo 'beta_branch_enabled='"$STEAMCMD_BETA_BRANCH" >> $SCRIPT_DIR/$SERVICE_NAME-steam.conf
		echo 'beta_branch_name='"$STEAMCMD_BETA_BRANCH_NAME" >> $SCRIPT_DIR/$SERVICE_NAME-steam.conf
		steamcmd +login anonymous +app_info_update 1 +app_info_print $APPID +quit > $UPDATE_DIR/steam_app_data.txt

		if [[ "$(systemctl --user show -p ActiveState --value $SERVICE_NAME)" == "active" ]]; then
			script_stop
			WAS_ACTIVE="1"
		fi

		if [[ "$STEAMCMD_BETA_BRANCH" == "0" ]]; then
			INSTALLED_BUILDID=$(cat $UPDATE_DIR/steam_app_data.txt | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"public\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"buildid\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3)
			echo "$INSTALLED_BUILDID" > $UPDATE_DIR/installed.buildid

			INSTALLED_TIME=$(cat $UPDATE_DIR/steam_app_data.txt | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"public\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"timeupdated\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3)
			echo "$INSTALLED_TIME" > $UPDATE_DIR/installed.timeupdated

			if [[ "$STEAMGUARD_CLI" == "1" ]]; then
				steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir $SRV_DIR/$WINE_PREFIX_GAME_DIR +login $STEAMCMD_UID $STEAMCMD_PSW $(steamguard) +app_update $APPID validate +quit
			else
				steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir $SRV_DIR/$WINE_PREFIX_GAME_DIR +login $STEAMCMD_UID $STEAMCMD_PSW +app_update $APPID validate +quit
			fi
		elif [[ "$STEAMCMD_BETA_BRANCH" == "1" ]]; then
			INSTALLED_BUILDID=$(cat $UPDATE_DIR/steam_app_data.txt | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"$STEAMCMD_BETA_BRANCH_NAME\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"buildid\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3)
			echo "$INSTALLED_BUILDID" > $UPDATE_DIR/installed.buildid

			INSTALLED_TIME=$(cat $UPDATE_DIR/steam_app_data.txt | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"$STEAMCMD_BETA_BRANCH_NAME\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"timeupdated\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3)
			echo "$INSTALLED_TIME" > $UPDATE_DIR/installed.timeupdated

			if [[ "$STEAMGUARD_CLI" == "1" ]]; then
				steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir $SRV_DIR/$WINE_PREFIX_GAME_DIR +login $STEAMCMD_UID $STEAMCMD_PSW $(steamguard) +app_update $APPID -beta $INSTALL_STEAMCMD_BETA_BRANCH_NAME validate +quit
			else
				steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir $SRV_DIR/$WINE_PREFIX_GAME_DIR +login $STEAMCMD_UID $STEAMCMD_PSW +app_update $APPID -beta $STEAMCMD_BETA_BRANCH_NAME validate +quit
			fi
		fi

		if [[ "$WAS_ACTIVE" == "1" ]]; then
			script_start
		fi
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Change branch) Server branch change complete." | tee -a "$LOG_SCRIPT"
	elif [[ "$CHANGE_SERVER_BRANCH" =~ ^([nN][oO]|[nN])$ ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Change branch) Server branch change canceled." | tee -a "$LOG_SCRIPT"
	fi
}

#---------------------------

#Check for updates. If there are updates available, shut down the server, update it and restart it.
script_update() {
	script_logs
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Update) Initializing update check." | tee -a "$LOG_SCRIPT"
	if [[ "$STEAMCMD_UID" == "disabled" ]] && [[ "$STEAMCMD_PSW" == "disabled" ]]; then
		script_steamcmd_credentials
	fi

	if [[ "$STEAMCMD_BETA_BRANCH" == "1" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Update) Beta branch enabled. Branch name: $STEAMCMD_BETA_BRANCH_NAME" | tee -a "$LOG_SCRIPT"
	fi

	if [ ! -f $UPDATE_DIR/installed.buildid ] ; then
		touch $UPDATE_DIR/installed.buildid
		echo "0" > $UPDATE_DIR/installed.buildid
	fi

	if [ ! -f $UPDATE_DIR/installed.timeupdated ] ; then
		touch $UPDATE_DIR/installed.timeupdated
		echo "0" > $UPDATE_DIR/installed.timeupdated
	fi

	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Update) Removing Steam/appcache/appinfo.vdf" | tee -a "$LOG_SCRIPT"
	rm -rf "/srv/$SERVICE_NAME/.steam/appcache/appinfo.vdf"

	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Update) Connecting to steam servers." | tee -a "$LOG_SCRIPT"
	steamcmd +login anonymous +app_info_update 1 +app_info_print $APPID +quit > $UPDATE_DIR/steam_app_data.txt

	if [[ "$STEAMCMD_BETA_BRANCH" == "0" ]]; then
		AVAILABLE_BUILDID=$(cat $UPDATE_DIR/steam_app_data.txt | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"public\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"buildid\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3)
		AVAILABLE_TIME=$(cat $UPDATE_DIR/steam_app_data.txt | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"public\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"timeupdated\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3)
	elif [[ "$STEAMCMD_BETA_BRANCH" == "1" ]]; then
		AVAILABLE_BUILDID=$(cat $UPDATE_DIR/steam_app_data.txt | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"$STEAMCMD_BETA_BRANCH_NAME\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"buildid\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3)
		AVAILABLE_TIME=$(cat $UPDATE_DIR/steam_app_data.txt | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"$STEAMCMD_BETA_BRANCH_NAME\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"timeupdated\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3)
	fi

	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Update) Received application info data." | tee -a "$LOG_SCRIPT"

	INSTALLED_BUILDID=$(cat $UPDATE_DIR/installed.buildid)
	INSTALLED_TIME=$(cat $UPDATE_DIR/installed.timeupdated)

	if [ "$AVAILABLE_TIME" -gt "$INSTALLED_TIME" ]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Update) New update detected." | tee -a "$LOG_SCRIPT"
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Update) Installed: BuildID: $INSTALLED_BUILDID, TimeUpdated: $INSTALLED_TIME" | tee -a "$LOG_SCRIPT"
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Update) Available: BuildID: $AVAILABLE_BUILDID, TimeUpdated: $AVAILABLE_TIME" | tee -a "$LOG_SCRIPT"

		if [[ "$DISCORD_UPDATE" == "1" ]]; then
			script_discord_message "$DISCORD_COLOR_UPDATE" "New update detected. Installing update."
		fi

		if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
			sleep 1
			WAS_ACTIVE="1"
			script_stop
			sleep 1
		fi

		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Update) Updating..." | tee -a "$LOG_SCRIPT"

		if [[ "$STEAMGUARD_CLI" == "1" ]]; then
			if [[ "$STEAMCMD_BETA_BRANCH" == "0" ]]; then
				steamcmd +force_install_dir $SRV_DIR/ +login $STEAMCMD_UID $STEAMCMD_PSW $(steamguard) +app_update $APPID validate +quit
			elif [[ "$STEAMCMD_BETA_BRANCH" == "1" ]]; then
				steamcmd +force_install_dir $SRV_DIR/ +login $STEAMCMD_UID $STEAMCMD_PSW $(steamguard) +app_update +app_update $APPID -beta $STEAMCMD_BETA_BRANCH_NAME validate +quit
			fi
		else
			if [[ "$STEAMCMD_BETA_BRANCH" == "0" ]]; then
				steamcmd +force_install_dir $SRV_DIR/ +login $STEAMCMD_UID $STEAMCMD_PSW +app_update $APPID validate +quit
			elif [[ "$STEAMCMD_BETA_BRANCH" == "1" ]]; then
				steamcmd +force_install_dir $SRV_DIR/ +login $STEAMCMD_UID $STEAMCMD_PSW +app_update $APPID -beta $STEAMCMD_BETA_BRANCH_NAME validate +quit
			fi
		fi

		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Update) Update completed." | tee -a "$LOG_SCRIPT"
		echo "$AVAILABLE_BUILDID" > $UPDATE_DIR/installed.buildid
		echo "$AVAILABLE_TIME" > $UPDATE_DIR/installed.timeupdated

		if [ "$WAS_ACTIVE" == "1" ]; then
			sleep 1
			if [[ "$UPDATE_IGNORE_FAILED_ACTIVATIONS" == "1" ]]; then
				script_start "ignore"
			else
				script_start
			fi
		fi

		if [[ "$DISCORD_UPDATE" == "1" ]]; then
			script_discord_message "$DISCORD_COLOR_UPDATE" "Server update complete."
		fi

		if [[ "$EMAIL_UPDATE" == "1" ]]; then
			script_email_message "$NAME" "Notification: Update" "Server was updated. Please check the update notes if there are any additional steps to take."
		fi
	elif [ "$AVAILABLE_TIME" -eq "$INSTALLED_TIME" ]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Update) No new updates detected." | tee -a "$LOG_SCRIPT"
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Update) Installed: BuildID: $INSTALLED_BUILDID, TimeUpdated: $INSTALLED_TIME" | tee -a "$LOG_SCRIPT"
	fi
}

#---------------------------

#Check for updates of mods. If there are updates available, shut down the server, update it and restart it.
script_update_mods() {
	script_logs
	if [[ "$MODS_ENABLED" == "1" ]]; then
		script_logs
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Mod Update) Initializing update check." | tee -a "$LOG_SCRIPT"
		if [[ "$STEAMCMD_UID" == "disabled" ]] && [[ "$STEAMCMD_PSW" == "disabled" ]]; then
			script_steamcmd_credentials
		fi

		MODS_TO_UPDATE=""
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Mod Update) Checking for mod updates." | tee -a "$LOG_SCRIPT"
		IFS=","
		for MOD_NAME_ID in $MODS; do
			MOD_ID=$(echo $MOD_NAME_ID | cut -d - -f2)
			MOD_NAME=$(echo $MOD_NAME_ID | cut -d - -f1)
			AVAILABLE_DATE_MOD=$(curl -s https://steamcommunity.com/sharedfiles/filedetails/changelog/$MOD_ID | grep "Update:" | head -n1 |awk -F 'Update: ' '{print $2}' | tr -d '\t' | awk -F '</div>' '{print $1}' | awk -F ' @ ' '{print $1}')
			AVAILABLE_TIME_MOD=$(curl -s https://steamcommunity.com/sharedfiles/filedetails/changelog/$MOD_ID | grep "Update:" | head -n1 |awk -F 'Update: ' '{print $2}' | tr -d '\t' | awk -F '</div>' '{print $1}' | awk -F ' @ ' '{print $2}')
			AVAILABLE_VERSION_MOD=$(date --date="$(printf "%s" $AVAILABLE_DATE_MOD)" +"%Y%m%d")$(date --date="$(printf "%s" $AVAILABLE_TIME_MOD)" +"%H%M")
			INSTALLED_VERSION_MOD=$(cat $UPDATE_DIR/mods/$MOD_NAME.mod_version)
			if [[ ! "$INSTALLED_VERSION_MOD" ]]; then
				INSTALLED_VERSION_MOD="0"
			fi
			if [ "$AVAILABLE_VERSION_MOD" -gt "$INSTALLED_VERSION_MOD" ]; then
				MODS_TO_UPDATE="$MODS_TO_UPDATE$MOD_NAME_ID,"
			fi
		done
		if [ ! -z "$MODS_TO_UPDATE" ]; then
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Mod Update) New mod updates detected. Installing updates." | tee -a "$LOG_SCRIPT"
			if [[ "$DISCORD_UPDATE_MOD" == "1" ]]; then
				script_discord_message "$DISCORD_COLOR_UPDATE" "New updates for mods detected. Installing updates."
			fi

			if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
				sleep 1
				WAS_ACTIVE="1"
				script_stop
				sleep 1
			fi

			IFS=","
			for MOD_NAME_ID in $MODS_TO_UPDATE; do
				MOD_ID=$(echo $MOD_NAME_ID | cut -d - -f2)
				MOD_NAME=$(echo $MOD_NAME_ID | cut -d - -f1)
				AVAILABLE_DATE_MOD=$(curl -s https://steamcommunity.com/sharedfiles/filedetails/changelog/$MOD_ID | grep "Update:" | head -n1 |awk -F 'Update: ' '{print $2}' | tr -d '\t' | awk -F '</div>' '{print $1}' | awk -F ' @ ' '{print $1}')
				AVAILABLE_TIME_MOD=$(curl -s https://steamcommunity.com/sharedfiles/filedetails/changelog/$MOD_ID | grep "Update:" | head -n1 |awk -F 'Update: ' '{print $2}' | tr -d '\t' | awk -F '</div>' '{print $1}' | awk -F ' @ ' '{print $2}')
				AVAILABLE_VERSION_MOD=$(date --date="$(printf "%s" $AVAILABLE_DATE_MOD)" +"%Y%m%d")$(date --date="$(printf "%s" $AVAILABLE_TIME_MOD)" +"%H%M")
				echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Mod Update) New update detected for mod $MOD_NAME." | tee -a "$LOG_SCRIPT"
				echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Mod Update) Installed: $INSTALLED_VERSION_MOD" | tee -a "$LOG_SCRIPT"
				echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Mod Update) Available: $AVAILABLE_VERSION_MOD" | tee -a "$LOG_SCRIPT"

				if [[ "$STEAMGUARD_CLI" == "1" ]]; then
					steamcmd +force_install_dir $SRV_DIR/ +login $STEAMCMD_UID $STEAMCMD_PSW $(steamguard) +workshop_download_item $WORKSHOP_APPID $MOD_ID +quit
				else
					steamcmd +force_install_dir $SRV_DIR/ +login $STEAMCMD_UID $STEAMCMD_PSW +workshop_download_item $WORKSHOP_APPID $MOD_ID +quit
				fi

				ln -s $SRV_DIR/steamapps/workshop/content/$WORKSHOP_APPID/$MOD_ID $SRV_DIR/@${MOD_NAME}

				if [ -f "$SRV_DIR/steamapps/workshop/content/$WORKSHOP_APPID/keys/*.bikey" ]; then
					cp -rf $SRV_DIR/steamapps/workshop/content/$WORKSHOP_APPID/keys/*.bikey $SRV_DIR/keys/
				fi

				if [ -f "$SRV_DIR/steamapps/workshop/content/$WORKSHOP_APPID/key/*.bikey" ]; then
					cp -rf $SRV_DIR/steamapps/workshop/content/$WORKSHOP_APPID/key/*.bikey $SRV_DIR/keys/
				fi

				echo "$AVAILABLE_VERSION_MOD" > $UPDATE_DIR/mods/$MOD_NAME.mod_version
				echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Mod Update) Update for mod $MOD_NAME complete." | tee -a "$LOG_SCRIPT"
			done

			if [ "$WAS_ACTIVE" == "1" ]; then
				sleep 1
				if [[ "$UPDATE_IGNORE_FAILED_ACTIVATIONS" == "1" ]]; then
					script_start "ignore"
				else
					script_start
				fi
			fi

			if [[ "$EMAIL_UPDATE_MOD" == "1" ]]; then
				mail -r "$EMAIL_SENDER ($NAME-$SERVICE_NAME)" -s "Notification: Mod Update" $EMAIL_RECIPIENT <<- EOF
				Mods ware updated. Please check the update notes if there are any additional steps to take.
				Updated mods: $MODS_TO_UPDATE
				EOF
			fi

			if [[ "$DISCORD_UPDATE_MOD" == "1" ]]; then
				while IFS="" read -r DISCORD_WEBHOOK || [ -n "$DISCORD_WEBHOOK" ]; do
					curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Mod Update) Update complete.\nUpdated mods: $MODS_TO_UPDATE\"}" "$DISCORD_WEBHOOK"
				done < $SCRIPT_DIR/discord_webhooks.txt
			fi



			if [[ "$DISCORD_UPDATE" == "1" ]]; then
				script_discord_message "$DISCORD_COLOR_UPDATE" "Mods update complete.\n\nUpdated mods: $MODS_TO_UPDATE"
			fi

			if [[ "$EMAIL_UPDATE" == "1" ]]; then
				script_email_message "$NAME" "Notification: Mod Update" "Mods ware updated. Please check the update notes if there are any additional steps to take.\nUpdated mods: $MODS_TO_UPDATE"
			fi
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Mod Update) Update for all mods complete." | tee -a "$LOG_SCRIPT"
		else
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Mod Update) All mods are up to date." | tee -a "$LOG_SCRIPT"
		fi
	fi
}

#---------------------------

#Shutdown any active servers, check the integrity of the server files and restart the servers.
script_verify_game_integrity() {
	script_logs
	if [[ "$STEAMCMD_UID" == "disabled" ]] && [[ "$STEAMCMD_PSW" == "disabled" ]]; then
		script_steamcmd_credentials
	fi

	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Integrity check) Initializing integrity check." | tee -a "$LOG_SCRIPT"
	if [[ "$STEAMCMD_BETA_BRANCH" == "1" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Integrity check) Beta branch enabled. Branch name: $STEAMCMD_BETA_BRANCH_NAME" | tee -a "$LOG_SCRIPT"
	fi

	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Integrity check) Removing Steam/appcache/appinfo.vdf" | tee -a "$LOG_SCRIPT"
	rm -rf "/srv/$SERVICE_NAME/.steam/appcache/appinfo.vdf"

	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
		sleep 1
		WAS_ACTIVE="1"
		script_stop
		sleep 1
	fi

	if [[ "$STEAMGUARD_CLI" == "1" ]]; then
		if [[ "$STEAMCMD_BETA_BRANCH" == "0" ]]; then
			steamcmd +force_install_dir $SRV_DIR/$WINE_PREFIX_GAME_DIR +login $STEAMCMD_UID $STEAMCMD_PSW $(steamguard) +app_update $APPID validate +quit
		elif [[ "$STEAMCMD_BETA_BRANCH" == "1" ]]; then
			steamcmd +force_install_dir $SRV_DIR/$WINE_PREFIX_GAME_DIR +login $STEAMCMD_UID $STEAMCMD_PSW $(steamguard) +app_update $APPID -beta $STEAMCMD_BETA_BRANCH_NAME validate +quit
		fi
	else
		if [[ "$STEAMCMD_BETA_BRANCH" == "0" ]]; then
			steamcmd +force_install_dir $SRV_DIR/$WINE_PREFIX_GAME_DIR +login $STEAMCMD_UID $STEAMCMD_PSW +app_update $APPID validate +quit
		elif [[ "$STEAMCMD_BETA_BRANCH" == "1" ]]; then
			steamcmd +force_install_dir $SRV_DIR/$WINE_PREFIX_GAME_DIR +login $STEAMCMD_UID $STEAMCMD_PSW +app_update $APPID -beta $STEAMCMD_BETA_BRANCH_NAME validate +quit
		fi
	fi

	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Integrity check) Integrity check completed." | tee -a "$LOG_SCRIPT"

	if [ "$WAS_ACTIVE" == "1" ]; then
		sleep 1
		if [[ "$UPDATE_IGNORE_FAILED_ACTIVATIONS" == "1" ]]; then
			script_start "ignore"
		else
			script_start
		fi
	fi
}

#---------------------------

#First timer function for systemd timers to execute parts of the script in order without interfering with each other
script_timer_one() {
	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "inactive" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Status) Server is not running." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "failed" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Status) Server is in failed state. Please check logs." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "activating" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Status) Server is activating. Please wait." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "deactivating" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Status) Server is in deactivating. Please wait." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Status) Server running." | tee -a "$LOG_SCRIPT"
		script_remove_old_files
		script_backup
		if [[ "$STEAMCMDUID" != "disabled" ]] && [[ "$STEAMCMDPSW" != "disabled" ]]; then
			script_update
			script_update_mods
		fi
	fi
}

#---------------------------

#Second timer function for systemd timers to execute parts of the script in order without interfering with each other
script_timer_two() {
	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "inactive" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Status) Server is not running." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "failed" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Status) Server is in failed state. Please check logs." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "activating" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Status) Server is activating. Please wait." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "deactivating" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Status) Server is in deactivating. Please wait." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Status) Server running." | tee -a "$LOG_SCRIPT"
		script_remove_old_files
		if [[ "$STEAMCMDUID" != "disabled" ]] && [[ "$STEAMCMDPSW" != "disabled" ]]; then
			script_update
			script_update_mods
		fi
	fi
}

#---------------------------

#Runs the diagnostics
script_diagnostics() {
	echo "Initializing diagnostics. Please wait..."
	echo ""
	sleep 3

	#Check package versions
	echo "Checkign package versions:"
	if [ -f "/usr/bin/pacman" ]; then
		echo "bash version:$(pacman -Qi bash | grep "^Version" | cut -d : -f2)"
		echo "coreutils version:$(pacman -Qi coreutils | grep "^Version" | cut -d : -f2)"
		echo "sudo version:$(pacman -Qi sudo | grep "^Version" | cut -d : -f2)"
		echo "grep version:$(pacman -Qi grep | grep "^Version" | cut -d : -f2)"
		echo "sed version:$(pacman -Qi sed | grep "^Version" | cut -d : -f2)"
		echo "awk version:$(pacman -Qi awk | grep "^Version" | cut -d : -f2)"
		echo "curl version:$(pacman -Qi curl | grep "^Version" | cut -d : -f2)"
		echo "rsync version:$(pacman -Qi rsync | grep "^Version" | cut -d : -f2)"
		echo "wget version:$(pacman -Qi wget | grep "^Version" | cut -d : -f2)"
		echo "findutils version:$(pacman -Qi findutils | grep "^Version" | cut -d : -f2)"
		echo "tmux version:$(pacman -Qi tmux | grep "^Version" | cut -d : -f2)"
		echo "jq version:$(pacman -Qi jq | grep "^Version" | cut -d : -f2)"
		echo "zip version:$(pacman -Qi zip | grep "^Version" | cut -d : -f2)"
		echo "unzip version:$(pacman -Qi unzip | grep "^Version" | cut -d : -f2)"
		echo "p7zip version:$(pacman -Qi p7zip | grep "^Version" | cut -d : -f2)"
		echo "postfix version:$(pacman -Qi postfix | grep "^Version" | cut -d : -f2)"
		echo "samba version:$(pacman -Qi samba | grep "^Version" | cut -d : -f2)"
	elif [ -f "/usr/bin/dpkg" ]; then
		echo "bash version:$(dpkg -s bash | grep "^Version" | cut -d : -f2)"
		echo "coreutils version:$(dpkg -s coreutils | grep "^Version" | cut -d : -f2)"
		echo "sudo version:$(dpkg -s sudo | grep "^Version" | cut -d : -f2)"
		echo "libpam-systemd version:$(dpkg -s libpam-systemd | grep "^Version" | cut -d : -f2)"
		echo "grep version:$(dpkg -s grep | grep "^Version" | cut -d : -f2)"
		echo "sed version:$(dpkg -s sed | grep "^Version" | cut -d : -f2)"
		echo "gawk version:$(dpkg -s gawk | grep "^Version" | cut -d : -f2)"
		echo "curl version:$(dpkg -s curl | grep "^Version" | cut -d : -f2)"
		echo "rsync version:$(dpkg -s rsync | grep "^Version" | cut -d : -f2)"
		echo "wget version:$(dpkg -s wget | grep "^Version" | cut -d : -f2)"
		echo "findutils version:$(dpkg -s findutils | grep "^Version" | cut -d : -f2)"
		echo "tmux version:$(dpkg -s tmux | grep "^Version" | cut -d : -f2)"
		echo "jq version:$(dpkg -s jq | grep "^Version" | cut -d : -f2)"
		echo "zip version:$(dpkg -s zip | grep "^Version" | cut -d : -f2)"
		echo "unzip version:$(dpkg -s unzip | grep "^Version" | cut -d : -f2)"
		echo "p7zip version:$(dpkg -s p7zip | grep "^Version" | cut -d : -f2)"
		echo "postfix version:$(dpkg -s postfix | grep "^Version" | cut -d : -f2)"
	fi
	echo ""

	echo "Checking if files and folders present:"
	#Check if files/folders present
	if [ -f "$SCRIPT_DIR/$SCRIPT_NAME" ] ; then
		echo "Script installed: Yes"
	else
		echo "Script installed: No"
	fi

	if [ -f "$SCRIPT_DIR/$SERVICE_NAME-config.conf" ] ; then
		echo "Configuration file present: Yes"
	else
		echo "Configuration file present: No"
	fi

	if [ -d "$BCKP_DIR" ]; then
		echo "Backups folder present: Yes"
	else
		echo "Backups folder present: No"
	fi

	if [ -d "/srv/$SERVICE_NAME/logs" ]; then
		echo "Logs folder present: Yes"
	else
		echo "Logs folder present: No"
	fi

	if [ -d "/srv/$SERVICE_NAME/scripts" ]; then
		echo "Scripts folder present: Yes"
	else
		echo "Scripts folder present: No"
	fi

	if [ -d "$SRV_DIR" ]; then
		echo "Server folder present: Yes"
	else
		echo "Server folder present: No"
	fi

	if [ -d "$UPDATE_DIR" ]; then
		echo "Updates folder present: Yes"
	else
		echo "Updates folder present: No"
	fi

	if [ -f "/srv/$SERVICE_NAME/.config/systemd/user/$SERVICE_NAME.service" ]; then
		echo "Basic service present: Yes"
	else
		echo "Basic service present: No"
	fi

	if [ -f "/srv/$SERVICE_NAME/.config/systemd/user/$SERVICE_NAME-timer-1.timer" ]; then
		echo "Timer 1 timer present: Yes"
	else
		echo "Timer 1 timer present: No"
	fi

	if [ -f "/srv/$SERVICE_NAME/.config/systemd/user/$SERVICE_NAME-timer-1.service" ]; then
		echo "Timer 1 service present: Yes"
	else
		echo "Timer 1 service present: No"
	fi

	if [ -f "/srv/$SERVICE_NAME/.config/systemd/user/$SERVICE_NAME-timer-2.timer" ]; then
		echo "Timer 2 timer present: Yes"
	else
		echo "Timer 2 timer present: No"
	fi

	if [ -f "/srv/$SERVICE_NAME/.config/systemd/user/$SERVICE_NAME-timer-2.service" ]; then
		echo "Timer 2 service present: Yes"
	else
		echo "Timer 2 service present: No"
	fi

	if [ -f "/srv/$SERVICE_NAME/.config/systemd/user/$SERVICE_NAME-send-notification.service" ]; then
		echo "Notification sending service present: Yes"
	else
		echo "Notification sending service present: No"
	fi

	echo "Diagnostics complete."
}

#---------------------------

#Install tmux configuration for specific server when first ran
script_server_tmux_install() {
	if [ -z "$1" ]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Server tmux configuration) Installing tmux configuration for server." | tee -a "$LOG_SCRIPT"
		TMUX_CONFIG_FILE="/tmp/$SERVICE_NAME-tmux.conf"
	elif [[ "$1" == "override" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Server tmux configuration) Installing tmux override configuration for server." | tee -a "$LOG_SCRIPT"
		TMUX_CONFIG_FILE="$CONFIG_DIR/$SERVICE_NAME-tmux.conf"
	fi

	if [ -f $CONFIG_DIR/$SERVICE_NAME-tmux.conf ]; then
		cp $CONFIG_DIR/$SERVICE_NAME-tmux.conf /tmp/$SERVICE_NAME-tmux.conf
	else
		if [ ! -f $TMUX_CONFIG_FILE ]; then
			touch $TMUX_CONFIG_FILE
			cat > $TMUX_CONFIG_FILE <<- EOF
			#Tmux configuration
			set -g activity-action other
			set -g allow-rename off
			set -g assume-paste-time 1
			set -g base-index 0
			set -g bell-action any
			set -g default-command "${SHELL}"
			set -g default-terminal "tmux-256color"
			set -g default-shell "/bin/bash"
			set -g default-size "132x42"
			set -g destroy-unattached off
			set -g detach-on-destroy on
			set -g display-panes-active-colour red
			set -g display-panes-colour blue
			set -g display-panes-time 1000
			set -g display-time 3000
			set -g history-limit 10000
			set -g key-table "root"
			set -g lock-after-time 0
			set -g lock-command "lock -np"
			set -g message-command-style fg=yellow,bg=black
			set -g message-style fg=black,bg=yellow
			set -g mouse on
			#set -g prefix C-b
			set -g prefix2 None
			set -g renumber-windows off
			set -g repeat-time 500
			set -g set-titles off
			set -g set-titles-string "#S:#I:#W - \"#T\" #{session_alerts}"
			set -g silence-action other
			set -g status on
			set -g status-bg green
			set -g status-fg black
			set -g status-format[0] "#[align=left range=left #{status-left-style}]#{T;=/#{status-left-length}:status-left}#[norange default]#[list=on align=#{status-justify}]#[list=left-marker]<#[list=right-marker]>#[list=on]#{W:#[range=window|#{window_index} #{window-status-style}#{?#{&&:#{window_last_flag},#{!=:#{window-status-last-style},default}}, #{window-status-last-style},}#{?#{&&:#{window_bell_flag},#{!=:#{window-status-bell-style},default}}, #{window-status-bell-style},#{?#{&&:#{||:#{window_activity_flag},#{window_silence_flag}},#{!=:#{window-status-activity-style},default}}, #{window-status-activity-style},}}]#{T:window-status-format}#[norange default]#{?window_end_flag,,#{window-status-separator}},#[range=window|#{window_index} list=focus #{?#{!=:#{window-status-current-style},default},#{window-status-current-style},#{window-status-style}}#{?#{&&:#{window_last_flag},#{!=:#{window-status-last-style},default}}, #{window-status-last-style},}#{?#{&&:#{window_bell_flag},#{!=:#{window-status-bell-style},default}}, #{window-status-bell-style},#{?#{&&:#{||:#{window_activity_flag},#{window_silence_flag}},#{!=:#{window-status-activity-style},default}}, #{window-status-activity-style},}}]#{T:window-status-current-format}#[norange list=on default]#{?window_end_flag,,#{window-status-separator}}}#[nolist align=right range=right #{status-right-style}]#{T;=/#{status-right-length}:status-right}#[norange default]"
			set -g status-format[1] "#[align=centre]#{P:#{?pane_active,#[reverse],}#{pane_index}[#{pane_width}x#{pane_height}]#[default] }"
			set -g status-interval 15
			set -g status-justify left
			set -g status-keys emacs
			set -g status-left "[#S] "
			set -g status-left-length 10
			set -g status-left-style default
			set -g status-position bottom
			set -g status-right "#{?window_bigger,[#{window_offset_x}#,#{window_offset_y}] ,}\"#{=21:pane_title}\" %H:%M %d-%b-%y"
			set -g status-right-length 40
			set -g status-right-style default
			set -g status-style fg=black,bg=green
			set -g update-environment[0] "DISPLAY"
			set -g update-environment[1] "KRB5CCNAME"
			set -g update-environment[2] "SSH_ASKPASS"
			set -g update-environment[3] "SSH_AUTH_SOCK"
			set -g update-environment[4] "SSH_AGENT_PID"
			set -g update-environment[5] "SSH_CONNECTION"
			set -g update-environment[6] "WINDOWID"
			set -g update-environment[7] "XAUTHORITY"
			set -g visual-activity off
			set -g visual-bell off
			set -g visual-silence off
			set -g word-separators " -_@"

			#Change prefix key from ctrl+b to ctrl+a
			unbind C-b
			set -g prefix C-a
			bind C-a send-prefix

			#Bind C-a r to reload the config file
			bind-key r source-file /tmp/$SERVICE_NAME-tmux.conf \; display-message "Config reloaded!"

			set-hook -g session-created 'resize-window -y 24 -x 10000'
			set-hook -g client-attached 'resize-window -y 24 -x 10000'
			set-hook -g client-detached 'resize-window -y 24 -x 10000'
			set-hook -g client-resized 'resize-window -y 24 -x 10000'

			#Default key bindings (only here for info)
			#Ctrl-b l (Move to the previously selected window)
			#Ctrl-b w (List all windows / window numbers)
			#Ctrl-b <window number> (Move to the specified window number, the default bindings are from 0 – 9)
			#Ctrl-b q  (Show pane numbers, when the numbers show up type the key to goto that pane)

			#Ctrl-b f <window name> (Search for window name)
			#Ctrl-b w (Select from interactive list of windows)

			#Copy/ scroll mode
			#Ctrl-b [ (in copy mode you can navigate the buffer including scrolling the history. Use vi or emacs-style key bindings in copy mode. The default is emacs. To exit copy mode use one of the following keybindings: vi q emacs Esc)
			EOF
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] (Server tmux configuration) Tmux configuration for server installed successfully." | tee -a "$LOG_SCRIPT"
		fi
	fi
}

#---------------------------

#Installs the steam configuration files and the game if the user so chooses
script_config_steam() {
	echo ""
	read -p "Do you want to use steam to download the game files and be resposible for maintaining them? (y/n): " INSTALL_STEAMCMD_ENABLE
	if [[ "$INSTALL_STEAMCMD_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		if [[ "$STEAMCMD_UID" == "disabled" ]] && [[ "$STEAMCMD_PSW" == "disabled" ]]; then
			script_steamcmd_credentials
		fi

		echo ""
		read -p "Do you have a Steam Guard Authentication app installed and configured? (y/n): " INSTALL_STEAMGUARD_CLI_ENABLE
		if [[ "$INSTALL_STEAMGUARD_CLI_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
			INSTALL_STEAMGUARD_CLI="1"
		else
			INSTALL_STEAMGUARD_CLI="0"
		fi

		echo ""
		read -p "Do you want the script to store your Steam credentials in the script's config file for automatic updates? (y/n): " INSTALL_STEAMCMD_STORE_CREDENTIALS_ENABLE
		INSTALL_STEAMCMD_STORE_CREDENTIALS_ENABLE=${INSTALL_STEAMCMD_STORE_CREDENTIALS_ENABLE:=n}
		if [[ "$INSTALL_STEAMCMD_STORE_CREDENTIALS_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
			echo "Your Steam credentials WILL be stored on this system. Updates will be installed automaticly when an update is released."
			INSTALL_STEAMCMD_STORE_CREDENTIALS="1"
		else
			echo "Your Steam credentials WILL NOT be stored on this system. You will have to update your game manually when an update is released."
			INSTALL_STEAMCMD_STORE_CREDENTIALS="0"
		fi

		echo ""
		read -p "Enable beta branch? Used for experimental and legacy versions. (y/n): " INSTALL_STEAMCMD_BETA_BRANCH_ENABLE
		if [[ "$INSTALL_STEAMCMD_BETA_BRANCH_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
			INSTALL_STEAMCMD_BETA_BRANCH="1"
			echo "Look up beta branch names at https://steamdb.info/app/$APPID/depots/"
			echo "Name example: ir_0.2.8"
			read -p "Enter beta branch name: " INSTALL_STEAMCMD_BETA_BRANCH_NAME
		elif [[ "$INSTALL_STEAMCMD_BETA_BRANCH_ENABLE" =~ ^([nN][oO]|[nN])$ ]]; then
			INSTALL_STEAMCMD_BETA_BRANCH="0"
			INSTALL_STEAMCMD_BETA_BRANCH_NAME="none"
		fi

		read -p "Do you want to install the server files with steam now? (y/n): " INSTALL_STEAMCMD_GAME_FILES_ENABLE
		if [[ "$INSTALL_STEAMCMD_GAME_FILES_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
			echo ""
			read -p "Enable mods? (y/n): " MODS_SETUP
			if [[ "$MODS_SETUP" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				MODS_INSTALL="1"
				echo ""
				read -p "Install Antistasi? (y/n): " MODS_ANTISTASI_SETUP
				if [[ "$MODS_ANTISTASI_SETUP" =~ ^([yY][eE][sS]|[yY])$ ]]; then
					MODS_ANTISTASI_INSTALL="1"
					echo ""
					echo "Downloading mission files from github. Please wait for mission selection..."
					sleep 3

					mkdir "$PWD/mission_pbo"
					cd "$PWD/mission_pbo"
					MODS_ANTISTASI_VERSION=$(curl -s "https://api.github.com/repos/official-antistasi-community/A3-Antistasi/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
					curl -s https://api.github.com/repos/official-antistasi-community/A3-Antistasi/releases/latest | jq -r ".assets[] | select(.name | contains(\"pbo\")) | .browser_download_url" | wget -i -
					cd ./..

					prompt="Please select a mission file:" options=( $(find "$PWD/mission_pbo" -maxdepth 1 -name "*.pbo" -exec basename \{} .pbo \;) )
					PS3="$prompt "
					select MISSION_PBO in "${options[@]}" "Quit" ; do
						if (( REPLY == 1 + ${#options[@]} )) ; then
							exit
						elif (( REPLY > 0 && REPLY <= ${#options[@]} )) ; then
							echo "Mission file $MISSION_PBO selected"
							break
						else
							echo "Invalid option. Try again."
						fi
					done

					echo ""
					read -p "Install an official Antistasi Server Modset? (y/n): " MODS_ANTISTASI_MODSET_INSTALL
					if [[ "$MODS_ANTISTASI_MODSET_INSTALL" =~ ^([yY][eE][sS]|[yY])$ ]]; then
						MOD_LIST_INSTALL="ace-463939057,ace_cpr_adv-1104460924,backpack_chest-820924072,cba_a3-450814997"
						while [[ "$MODS_ANTISTASI_MODSET_INSTALL_SELLECTION" != [1234] ]]; do
							echo ""
							echo "These will be installed on top of the vanilla pack, wich is the default."
							echo "Available Antistasi Modsets:"
							echo ""
							echo "1 - Antistasi Official Server Modset - 3CB"
							echo "2 - Antistasi Official Server Modset - RHS"
							echo "3 - Antistasi Official Server Modset - WW2 / Armia Krajowa"
							echo "4 - Antistasi Official Server Modset - Vanilla"
							read -p "Enter sellection (ENTER ONLY SINGLE SELLECTION! Default is vanilla): " MODS_ANTISTASI_MODSET_INSTALL_SELLECTION
							if [[ "$MODS_ANTISTASI_MODSET_INSTALL_SELLECTION" == "1" ]]; then
								MOD_LIST_INSTALL="$MOD_LIST_INSTALL,3cb_baf_equipment-893328083,3cb_baf_units-893346105,3cb_baf_units_ace-1135539579,3cb_baf_units_rhs-1135541175,3cb_baf_vehicles-893349825,3cb_baf_vehicles_rhs_reskins-1515851169,3cb_baf_vehicles_service-1135543967,3cb_baf_weapons-893339590,3cb_baf_weapons_rhs_compat-1515845502,3cb_baf_factions-1673456286,ace_rhs_afrf_compat-773131200,ace_rhs_usaf_compat-773125288,ace_rhs_gref_compat-884966711,rhs_afrf-843425103,rhs_usaf-843577117,rhs_gref-843593391,rksl_attachments-1661066023"
							elif [[ "$MODS_ANTISTASI_MODSET_INSTALL_SELLECTION" == "2" ]]; then
								MOD_LIST_INSTALL="$MOD_LIST_INSTALL,ace_rhs_afrf_compat-773131200,ace_rhs_usaf_compat-773125288,ace_rhs_gref_compat-884966711,rhs_afrf-843425103,rhs_usaf-843577117,rhs_gref-843593391"
							elif [[ "$MODS_ANTISTASI_MODSET_INSTALL_SELLECTION" == "3" ]]; then
								MOD_LIST_INSTALL="ace_iron_front_compat-773759919,cup_terrains_core-583496184,cup_terrains_maps-583544987"
							elif [[ "$MODS_ANTISTASI_MODSET_INSTALL_SELLECTION" == "4" ]]; then
								continue
							fi
						done
						echo ""
						read -p "Install Task force radio (You need a teamspeak server for this)? (y/n): " MODS_ANTISTASI_TFR_INSTALL
						if [[ "$MODS_ANTISTASI_TFR_INSTALL" =~ ^([yY][eE][sS]|[yY])$ ]]; then
							MOD_LIST_INSTALL="$MOD_LIST_INSTALL,task_force_radio-620019431"
						else
							MODS_ANTISTASI_TFR_INSTALL="0"
						fi
						echo ""
						read -p "Install Squad radar? (y/n): " MODS_ANTISTASI_SQR_INSTALL
						if [[ "$MODS_ANTISTASI_TFR_INSTALL" =~ ^([yY][eE][sS]|[yY])$ ]]; then
							MOD_LIST_INSTALL="$MOD_LIST_INSTALL,squad_radar-1638341685"
						else
							MODS_ANTISTASI_SQR_INSTALL="0"
						fi
					fi
				else
					MODS_ANTISTASI_INSTALL="0"
					MODS_ANTISTASI_TFR_INSTALL="0"
					MODS_ANTISTASI_SQR_INSTALL="0"
					MISSION_PBO="Your mission file name without the .pbo extension"
					echo ""
					read -p "Install custom modset? (y/n): " MOD_LIST_CUSTOM
					if [[ "$MOD_LIST_CUSTOM" =~ ^([yY][eE][sS]|[yY])$ ]]; then
						echo ""
						read -p "Enter custom mod names (without spaces or caps) and their workshop ids (ex: cba_a3-450814997,ace-463939057): " MOD_LIST_INSTALL
					else
						MOD_LIST_INSTALL="0"
					fi
				fi
			else
				MODS_INSTALL="0"
				MOD_LIST_INSTALL=""
				MODS_ANTISTASI_INSTALL="0"
				MODS_ANTISTASI_TFR_INSTALL="0"
				MODS_ANTISTASI_SQR_INSTALL="0"
				MISSION_PBO="Your mission file name without the .pbo extension"
			fi

			if [[ "$MODS_ANTISTASI_INSTALL" == "1" ]]; then
				echo $MODS_ANTISTASI_VERSION > $UPDATE_DIR/installed_antistasi.version
			fi

			echo "Installing game..."
			steamcmd +login anonymous +app_info_update 1 +app_info_print $APPID +quit > $UPDATE_DIR/steam_app_data.txt

			if [[ "$INSTALL_STEAMCMD_BETA_BRANCH" == "0" ]]; then
				INSTALLED_BUILDID=$(cat $UPDATE_DIR/steam_app_data.txt | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"public\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"buildid\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3)
				echo "$INSTALLED_BUILDID" > $UPDATE_DIR/installed.buildid

				INSTALLED_TIME=$(cat $UPDATE_DIR/steam_app_data.txt | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"public\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"timeupdated\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3)
				echo "$INSTALLED_TIME" > $UPDATE_DIR/installed.timeupdated

				if [[ "$INSTALL_STEAMGUARD_CLI" == "1" ]]; then
					steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir $SRV_DIR/ +login $INSTALL_STEAMCMD_UID $INSTALL_STEAMCMD_PSW $(steamguard) +app_update $APPID validate +quit
				else
					steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir $SRV_DIR/ +login $INSTALL_STEAMCMD_UID $INSTALL_STEAMCMD_PSW +app_update $APPID validate +quit
				fi
			elif [[ "$INSTALL_STEAMCMD_BETA_BRANCH" == "1" ]]; then
				INSTALLED_BUILDID=$(cat $UPDATE_DIR/steam_app_data.txt | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"$INSTALL_STEAMCMD_BETA_BRANCH_NAME\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"buildid\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3)
				echo "$INSTALLED_BUILDID" > $UPDATE_DIR/installed.buildid

				INSTALLED_TIME=$(cat $UPDATE_DIR/steam_app_data.txt | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"$INSTALL_STEAMCMD_BETA_BRANCH_NAME\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"timeupdated\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3)
				echo "$INSTALLED_TIME" > $UPDATE_DIR/installed.timeupdated

				if [[ "$INSTALL_STEAMGUARD_CLI" == "1" ]]; then
					steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir $SRV_DIR/ +login $INSTALL_STEAMCMD_UID $INSTALL_STEAMCMD_PSW $(steamguard) +app_update $APPID -beta $INSTALL_STEAMCMD_BETA_BRANCH_NAME validate +quit
				else
					steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir $SRV_DIR/ +login $INSTALL_STEAMCMD_UID $INSTALL_STEAMCMD_PSW +app_update $APPID -beta $INSTALL_STEAMCMD_BETA_BRANCH_NAME validate +quit
				fi
			fi

			if [[ "$MODS_INSTALL" == "1" ]]; then
				IFS=","
				for MOD_NAME_ID in $MOD_LIST_INSTALL; do
					echo "SteamCMD is updating mod $MOD_NAME_ID"
					MOD_ID=$(echo $MOD_NAME_ID | cut -d - -f2)
					MOD_NAME=$(echo $MOD_NAME_ID | cut -d - -f1)
					AVAILABLE_DATE_MOD=$(curl -s https://steamcommunity.com/sharedfiles/filedetails/changelog/$MOD_ID | grep "Update:" | head -n1 | awk -F 'Update: ' '{print $2}' | tr -d '\t' | awk -F '</div>' '{print $1}' | awk -F ' @ ' '{print $1}')
					AVAILABLE_TIME_MOD=$(curl -s https://steamcommunity.com/sharedfiles/filedetails/changelog/$MOD_ID | grep "Update:" | head -n1 | awk -F 'Update: ' '{print $2}' | tr -d '\t' | awk -F '</div>' '{print $1}' | awk -F ' @ ' '{print $2}')
					AVAILABLE_VERSION_MOD=$(date --date="$(printf "%s" $AVAILABLE_DATE_MOD)" +"%Y%m%d")$(date --date="$(printf "%s" $AVAILABLE_TIME_MOD)" +"%H%M")
					while [[ "$STEAMCMDSUCCESSMODS" != "0" ]]; do
						steamcmd +login $INSTALL_STEAMCMD_UID $INSTALL_STEAMCMD_PSW +force_install_dir $SRV_DIR/ +workshop_download_item $APPID_WORKSHOP $MOD_ID +quit
						INSTALL_STEAMCMD_SUCCESS_MODS=$?
						if [[ "$INSTALL_STEAMCMD_SUCCESS_MODS" == "0" ]]; then
							echo "Download of mod $MOD_NAME_ID: SUCCEDED!"
						elif [[ "$INSTALL_STEAMCMD_SUCCESS_MODS" != "0" ]]; then
							echo "Download of mod $MOD_NAME_ID: FAILED!"
							echo "Retrying...."
						fi
					done
					ln -s $SRV_DIR/steamapps/workshop/content/$APPID_WORKSHOP/$MOD_ID $SRV_DIR/@${MOD_NAME}
					echo "$AVAILABLE_VERSION_MOD" > $UPDATE_DIR/mods/$MOD_NAME.mod_version
				done
				find -L $SRV_DIR/@* -name "*.bikey" -exec cp {} $SRV_DIR/keys/ \;
			fi

			mkdir -p "/srv/$SERVICE_NAME/.local/share/Arma 3"
			mkdir -p "/srv/$SERVICE_NAME/.local/share/Arma 3 - Other Profiles/$NAME"
			mv "$PWD/mission_pbo/$MISSION_PBO.pbo" "$SRV_DIR/mpmissions/"
			rm -rf "$PWD/mission_pbo"

			cat > /$SRV_DIR/server.cfg <<- EOF
			//
			// server.cfg
			//
			// comments are written with "//" in front of them.

			// GLOBAL SETTINGS
			hostname = "Server name"; // The name of the server that shall be displayed in the public server list
			password = "Server password"; // Password for joining, eg connecting to the server
			passwordAdmin = "Admin password"; // Password to become server admin. When you're in Arma MP and connected to the server, type '#login xyz'
			serverCommandPassword = "";
			admins[] = {"Admin steam64id"}; //add arma3 profile id to add default admins

			headlessClients[]={"127.0.0.1"}; // add headlessclient address
			localClient[]={"127.0.0.1"};

			logFile = "server_console.log";			// Tells ArmA-server where the logfile should go and what it should be called

			// WELCOME MESSAGE ("message of the day")
			// It can be several lines, separated by comma
			// Empty messages "" will not be displayed at all but are only for increasing the interval
			motd[] = {
				"", "",
				"Antistasi Server",
				"Welcome",
				"", "",
			};
			motdInterval = 300;				// Time interval (in seconds) between each message

			// JOINING RULES
			maxPlayers = 32; // Maximum amount of players. Civilians and watchers, beholder, bystanders and so on also count as player.
			kickDuplicate = 1; // Each ArmA version has its own ID. If kickDuplicate is set to 1, a player will be kicked when he joins a server where another player with the same ID is playing.
			verifySignatures = 1; // Verifies the players files by checking them with the .bisign signatures. Works properly from 1.08 on
			equalModRequired = 0; // Outdated. If set to 1, player has to use exactly the same -mod= startup parameter as the server.

			// VOTING
			voteMissionPlayers = 1; // Tells the server how many people must connect so that it displays the mission selection screen.
			voteThreshold = 0.33; // 33% or more players need to vote for something, for example an admin or a new map, to become effective
			allowedVoteCmds[] = {};

			// INGAME SETTINGS
			disableVoN = 1; // If set to 1, Voice over Net will not be available
			vonCodecQuality = 5; // Quality from 1 to 10
			persistent = 1; // If 1, missions still run on even after the last player disconnected.
			timeStampFormat = "short"; // Set the timestamp format used on each report line in server-side RPT file. Possible values are "none" (default),"short","full".
			BattlEye = 0; // Server to use BattlEye system

			// SIGNATURE VERIFICATION
			onUnsignedData = "kick (_this select 0)"; // unsigned data detected
			onHackedData = ""; // tampering of the signature detected
			onDifferentData = ""; // data with a valid signature, but different version than the one present on server detected

			regularcheck="";

			// MISSIONS CYCLE (see below)
			class Missions {
				class A3Antistasi {
					template ="$MISSION_PBO";
						difficulty = "Custom";
							class Params {
								loadSave = 1; //Load last Persistent Save
								gameMode = 1; //1 - Reb vs Gov vs Inv, 2 - Reb vs Gov & Inv, 3 - Reb vs Gov, 4 - Reb vs Inv
								autoSave = 1; //Enable Autosave (every hour)
								membership = 0; //Enable Server Membership
								switchComm = 0; //Enable Commander Switch (highest ranked player)
								tkPunish = 0; //Enable Teamkill Punish
								mRadius = 2500; //Distance from HQ for Sidemissions
								allowPVP = 1; //Allow PvP Slots
								pMarkers = 1; //Allow Friendly Player Markers
								AISkill = 0.5; //AI Skill, 0.5 - Easy, 1- Normal, 2 - Hard
								unlockItem = 15; //Number of the same weapons required to unlock. 15,25,40
								memberOnlyMagLimit = 10; //Number of magazines needed for guests to be able to use them. 10,20,30,40,50,60
								civTraffic = 1; //Rate of civ traffic. 0.5 - Low, 1 - Medium, 2 - JAM
								memberSlots = 20; //Percentage of Reserved Slots for Members. 0,20,40,60,80,100
								memberDistance = 16000; //Max distance non members can be from the closest member or HQ (they will be teleported to HQ after some timeout). 4000 - 4Kmts,5000 - 5Kmts,6000 - 6Kmts,7000 - 7Kmts,8000 - 8Kmts,16000 - Unlimited
								allowFT = 1; //Limited Fast Travel
								napalmEnabled = 0; //Enable Napalm Bombing for AI
								teamSwitchDelay = 1800; //Delay After Leaving Before a Player Can Join Another Team. 0, 900, 1800, 3600
							};
				};
			};// An empty Missions class means there will be no mission rotation
			EOF

				cat > "/srv/$SERVICE_NAME/.local/share/Arma 3 - Other Profiles/$NAME/$NAME.Arma3Profile" <<- EOF
			difficulty="custom";
			class DifficultyPresets
			{
				defaultPreset="custom";
				class CustomDifficulty
				{
					class Options
					{
						reducedDamage=0;
						groupIndicators=1;
						friendlyTags=2;
						enemyTags=0;
						detectedMines=2;
						commands=2;
						waypoints=2;
						weaponInfo=2;
						stanceIndicator=2;
						staminaBar=1;
						weaponCrosshair=1;
						visionAid=1;
						squadRadar=1;
						thirdPersonView=1;
						cameraShake=1;
						scoreTable=0;
						deathMessages=1;
						vonID=0;
						mapContent=1;
						autoReport=1;
						multipleSaves=0;
					};
					aiLevelPreset=3;
				};
				class CustomAILevel
				{
					skillFriendly=1;
					skillEnemy=1;
					precisionFriendly=0.30000001;
					precisionEnemy=0.30000001;
				};
			};
			singleVoice=0;
			maxSamplesPlayed=96;
			version=1;
			blood=1;
			gamma=1;
			brightness=1;
			activeKeys[]=
			{
				"BIS_A3-Antistasi.Altis_done",
				"BIS_A3AS_Altis_(G).Altis_done"
			};
			soundEnableEAX=1;
			soundEnableHW=0;
			playedKeys[]=
			{
				"BIS_EXP_m01.Tanoa_done",
				"BIS_Showcase_FiringFromVehicles.Altis_done",
				"BIS_EXP_m07.Tanoa_done",
				"BIS_Showcase_Tanks.Altis_done"
			};
			sceneComplexity=1000000;
			shadowZDistance=100;
			viewDistance=3400;
			preferredObjectViewDistance=2000;
			terrainGrid=3.125;
			vonRecThreshold=0.029999999;
			volumeCD=10;
			volumeFX=10;
			volumeSpeech=10;
			volumeVoN=10;
			EOF
		else
			echo "Manual game installation selected. Copy your game files to $SRV_DIR/ after installation."
		fi
	else
		echo ""
		echo "Manual game installation selected. Copy your game files to $SRV_DIR/ after installation."
		INSTALL_STEAMCMD_UID="disabled"
		INSTALL_STEAMCMD_PSW="disabled"
		INSTALL_STEAMGUARD_CLI="0"
		INSTALL_STEAMCMD_STORE_CREDENTIALS="0"
		INSTALL_STEAMCMD_BETA_BRANCH="0"
		INSTALL_STEAMCMD_BETA_BRANCH_NAME="none"
	fi

	echo "Writing configuration file..."
	touch $CONFIG_DIR/$SERVICE_NAME-steam.conf
	if [[ "$INSTALL_STEAMCMD_STORE_CREDENTIALS" == "1" ]]; then
		echo 'steamcmd_username='"$INSTALL_STEAMCMD_UID" > $CONFIG_DIR/$SERVICE_NAME-steam.conf
		echo 'steamcmd_password='"$INSTALL_STEAMCMD_PSW" >> $CONFIG_DIR/$SERVICE_NAME-steam.conf
		echo "steamcmd_steamguardapp=$INSTALL_STEAMGUARD_CLI" > $CONFIG_DIR/$SERVICE_NAME-steam.conf
	else
		echo 'steamcmd_username=disabled' > $CONFIG_DIR/$SERVICE_NAME-steam.conf
		echo 'steamcmd_password=disabled' >> $CONFIG_DIR/$SERVICE_NAME-steam.conf
		echo "steamcmd_steamguardapp=0" > $CONFIG_DIR/$SERVICE_NAME-steam.conf
	fi
	echo 'steamcmd_beta_branch='"$INSTALL_STEAMCMD_BETA_BRANCH" >> $CONFIG_DIR/$SERVICE_NAME-steam.conf
	echo 'steamcmd_beta_branch_name='"$INSTALL_STEAMCMD_BETA_BRANCH_NAME" >> $CONFIG_DIR/$SERVICE_NAME-steam.conf
	echo 'steamguard_cli='"$INSTALL_STEAMGUARD_CLI" >> $CONFIG_DIR/$SERVICE_NAME-steam.conf

	touch $CONFIG_DIR/$SERVICE_NAME-mods.conf
	echo 'mods_enabled='"$MODS_INSTALL" > $CONFIG_DIR/$SERVICE_NAME-mods.conf
	echo 'mod_list='"$MOD_LIST_INSTALL" > $CONFIG_DIR/$SERVICE_NAME-mods.conf
	echo "Done"
}

#---------------------------

#Configures discord integration
script_config_discord() {
	echo ""
	read -p "Enable discord notifications (y/n): " INSTALL_DISCORD_ENABLE
	if [[ "$INSTALL_DISCORD_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		echo ""
		echo "You are able to add multiple webhooks for the script to use in the discord_webhooks.txt file located in the config folder."
		echo "EACH ONE HAS TO BE IN IT'S OWN LINE!"
		echo ""
		read -p "Enter your first webhook for the server: " INSTALL_DISCORD_WEBHOOK
		if [[ "$INSTALL_DISCORD_WEBHOOK" == "" ]]; then
			INSTALL_DISCORD_WEBHOOK="none"
		fi
		echo ""
		read -p "Discord notifications for game updates? (y/n): " INSTALL_DISCORD_UPDATE_ENABLE
			if [[ "$INSTALL_DISCORD_UPDATE_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				INSTALL_DISCORD_UPDATE="1"
			else
				INSTALL_DISCORD_UPDATE="0"
			fi
		echo ""
		read -p "Discord notifications for server startup? (y/n): " INSTALL_DISCORD_START_ENABLE
			if [[ "$INSTALL_DISCORD_START_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				INSTALL_DISCORD_START="1"
			else
				INSTALL_DISCORD_START="0"
			fi
		echo ""
		read -p "Discord notifications for server shutdown? (y/n): " INSTALL_DISCORD_STOP_ENABLE
			if [[ "$INSTALL_DISCORD_STOP_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				INSTALL_DISCORD_STOP="1"
			else
				INSTALL_DISCORD_STOP="0"
			fi
		echo ""
		read -p "Discord notifications for crashes? (y/n): " INSTALL_DISCORD_CRASH_ENABLE
			if [[ "$INSTALL_DISCORD_CRASH_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				INSTALL_DISCORD_CRASH="1"
			else
				INSTALL_DISCORD_CRASH="0"
			fi
	elif [[ "$INSTALL_DISCORD_ENABLE" =~ ^([nN][oO]|[nN])$ ]]; then
		INSTALL_DISCORD_UPDATE="0"
		INSTALL_DISCORD_START="0"
		INSTALL_DISCORD_STOP="0"
		INSTALL_DISCORD_CRASH="0"
	fi

	echo "Writing configuration file..."
	touch $CONFIG_DIR/$SERVICE_NAME-discord.conf
	echo 'discord_update='"$INSTALL_DISCORD_UPDATE" >> $CONFIG_DIR/$SERVICE_NAME-discord.conf
	echo 'discord_start='"$INSTALL_DISCORD_START" >> $CONFIG_DIR/$SERVICE_NAME-discord.conf
	echo 'discord_stop='"$INSTALL_DISCORD_STOP" >> $CONFIG_DIR/$SERVICE_NAME-discord.conf
	echo 'discord_crash='"$INSTALL_DISCORD_CRASH" >> $CONFIG_DIR/$SERVICE_NAME-discord.conf
	echo "$INSTALL_DISCORD_WEBHOOK" > $CONFIG_DIR/discord_webhooks.txt
	echo "Done"
}

#---------------------------

#Configures email integration
script_config_email() {
	echo ""
	read -p "Enable email notifications (y/n): " INSTALL_EMAIL_ENABLE
	if [[ "$INSTALL_EMAIL_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		echo ""
		read -p "Enter the email that will send the notifications (example: sender@gmail.com): " INSTALL_EMAIL_SENDER
		echo ""
		read -p "Enter the email that will recieve the notifications (example: recipient@gmail.com): " INSTALL_EMAIL_RECIPIENT
		echo ""
		read -p "Email notifications for game updates? (y/n): " INSTALL_EMAIL_UPDATE_ENABLE
			if [[ "$INSTALL_EMAIL_UPDATE_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				INSTALL_EMAIL_UPDATE="1"
			else
				INSTALL_EMAIL_UPDATE="0"
			fi
		echo ""
		read -p "Email notifications for server startup? (WARNING: this can be anoying) (y/n): " INSTALL_EMAIL_START_ENABLE
			if [[ "$INSTALL_EMAIL_START_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				INSTALL_EMAIL_START="1"
			else
				INSTALL_EMAIL_START="0"
			fi
		echo ""
		read -p "Email notifications for server shutdown? (WARNING: this can be anoying) (y/n): " INSTALL_EMAIL_STOP_ENABLE
			if [[ "$INSTALL_EMAIL_STOP_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				INSTALL_EMAIL_STOP="1"
			else
				INSTALL_EMAIL_STOP="0"
			fi
		echo ""
		read -p "Email notifications for crashes? (y/n): " INSTALL_EMAIL_CRASH_ENABLE
			if [[ "$INSTALL_EMAIL_CRASH_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				INSTALL_EMAIL_CRASH="1"
			else
				INSTALL_EMAIL_CRASH="0"
			fi
		if [[ "$EUID" == "$(id -u root)" ]] ; then
			read -p "Configure postfix? (y/n): " INSTALL_EMAIL_CONFIGURE
			if [[ "$INSTALL_EMAIL_CONFIGURE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				echo ""
				read -p "Enter the relay host (example: smtp.gmail.com): " INSTALL_EMAIL_RELAY_HOSTNAME
				echo ""
				read -p "Enter the relay host port (example: 587): " INSTALL_EMAIL_RELAY_PORT
				echo ""
				read -p "Enter your password for $INSTALL_EMAIL_SENDER : " INSTALL_EMAIL_SENDER_PSW

				cat >> /etc/postfix/main.cf <<- EOF
				relayhost = [$INSTALL_EMAIL_RELAY_HOST]:$INSTALL_EMAIL_RELAY_PORT
				smtp_sasl_auth_enable = yes
				smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
				smtp_sasl_security_options = noanonymous
				smtp_tls_CApath = /etc/ssl/certs
				smtpd_tls_CApath = /etc/ssl/certs
				smtp_use_tls = yes
				EOF

				cat > /etc/postfix/sasl_passwd <<- EOF
				[$INSTALL_EMAIL_RELAY_HOST]:$INSTALL_EMAIL_RELAY_PORT    $INSTALL_EMAIL_SENDER:$INSTALL_EMAIL_SENDER_PSW
				EOF

				sudo chmod 400 /etc/postfix/sasl_passwd
				sudo postmap /etc/postfix/sasl_passwd
				sudo systemctl enable --now postfix
			fi
		else
			echo "Add the following lines to /etc/postfix/main.cf"
			echo "relayhost = [$INSTALL_EMAIL_RELAY_HOST]:$INSTALL_EMAIL_RELAY_HOST_PORT"
			echo "smtp_sasl_auth_enable = yes"
			echo "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd"
			echo "smtp_sasl_security_options = noanonymous"
			echo "smtp_tls_CApath = /etc/ssl/certs"
			echo "smtpd_tls_CApath = /etc/ssl/certs"
			echo "smtp_use_tls = yes"
			echo ""
			echo "Add the following line to /etc/postfix/sasl_passwd"
			echo "[$INSTALL_EMAIL_RELAY_HOST]:$INSTALL_EMAIL_RELAY_HOST_PORT    $INSTALL_EMAIL_SENDER:$INSTALL_EMAIL_SENDER_PSW"
			echo ""
			echo "Execute the following commands:"
			echo "sudo chmod 400 /etc/postfix/sasl_passwd"
			echo "sudo postmap /etc/postfix/sasl_passwd"
			echo "sudo systemctl enable postfix"
		fi
	elif [[ "$INSTALL_EMAIL_ENABLE" =~ ^([nN][oO]|[nN])$ ]]; then
		INSTALL_EMAIL_SENDER="none"
		INSTALL_EMAIL_RECIPIENT="none"
		INSTALL_EMAIL_UPDATE="0"
		INSTALL_EMAIL_START="0"
		INSTALL_EMAIL_STOP="0"
		INSTALL_EMAIL_CRASH="0"
	fi

	echo "Writing configuration file..."
	echo 'email_sender='"$INSTALL_EMAIL_SENDER" >> $CONFIG_DIR/$SERVICE_NAME-email.conf
	echo 'email_recipient='"$INSTALL_EMAIL_RECIPIENT" >> $CONFIG_DIR/$SERVICE_NAME-email.conf
	echo 'email_update='"$INSTALL_EMAIL_UPDATE" >> $CONFIG_DIR/$SERVICE_NAME-email.conf
	echo 'email_start='"$INSTALL_EMAIL_START" >> $CONFIG_DIR/$SERVICE_NAME-email.conf
	echo 'email_stop='"$INSTALL_EMAIL_STOP" >> $CONFIG_DIR/$SERVICE_NAME-email.conf
	echo 'email_crash='"$INSTALL_EMAIL_CRASH" >> $CONFIG_DIR/$SERVICE_NAME-email.conf
	chown $SERVICE_NAME $CONFIG_DIR/$SERVICE_NAME-email.conf
	echo "Done"
}

#---------------------------

#Configures the script
script_config_script() {
	echo -e "${CYAN}Script configuration${NC}"
	echo -e ""
	echo -e "The script uses steam to download the game server files, however you have the option to manualy copy the files yourself."
	echo -e ""
	echo -e "The script can work either way. The $SERVICE_NAME user's home directory is located in /srv/$SERVICE_NAME and all files are located there."
	echo -e "This configuration installation will only install the essential configuration. No steam, discord, email or tmpfs/ramdisk"
	echo -e "Default configuration will be applied and it can work without it. You can run the optional configuration for each using the"
	echo -e "following arguments with the script:"
	echo -e ""
	echo -e "${GREEN}config_steam   ${RED}- ${GREEN}Configures steamcmd, automatic updates and installs the game server files.${NC}"
	echo -e "${GREEN}config_discord ${RED}- ${GREEN}Configures discord integration.${NC}"
	echo -e "${GREEN}config_email   ${RED}- ${GREEN}Configures email integration. Due to postfix configuration files being in /etc this has to be executed as root.${NC}"
	echo -e "${GREEN}config_tmpfs   ${RED}- ${GREEN}Configures tmpfs/ramdisk. Due to it adding a line to /etc/fstab this has to be executed as root.${NC}"
	echo -e ""
	echo -e ""
	read -p "Press any key to continue" -n 1 -s -r
	echo ""

	echo "Enable services"

	systemctl --user enable $SERVICE_NAME.service
	systemctl --user enable --now $SERVICE_NAME-timer-1.timer
	systemctl --user enable --now $SERVICE_NAME-timer-2.timer

	echo "Writing config files"

	if [ -f "$CONFIG_DIR/$SERVICE_NAME-script.conf" ]; then
		rm $CONFIG_DIR/$SERVICE_NAME-script.conf
	fi

	touch $CONFIG_DIR/$SERVICE_NAME-script.conf
	echo 'script_bckp_delold=14' >> $CONFIG_DIR/$SERVICE_NAME-script.conf
	echo 'script_log_delold=7' >> $CONFIG_DIR/$SERVICE_NAME-script.conf
	echo 'script_update_ignore_failed_startups=0' >> $CONFIG_DIR/$SERVICE_NAME-script.conf

	if [ ! -d "$BCKP_SRC_DIR" ]; then
		mkdir -p "$BCKP_SRC_DIR"
	fi

	echo "Configuration complete"
	echo "For any settings you'll want to change, edit the files located in $CONFIG_DIR/"
	echo "To enable additional fuctions like steam, discord, email and tmpfs execute the script with the help argument."
}

#---------------------------

if [[ "pre-start" != "$1" ]] && [[ "post-start" != "$1" ]] && [[ "pre-stop" != "$1" ]] && [[ "post-stop" != "$1" ]] && [[ "send_notification_crash" != "$1" ]] && [[ "server_tmux_install" != "$1" ]] && [[ "attach" != "$1" ]] && [[ "status" != "$1" ]]; then
	SCRIPT_PID_CHECK=$(basename -- "$0")
	if pidof -x "$SCRIPT_PID_CHECK" -o $$ > /dev/null; then
		echo "An another instance of this script is already running, please clear all the sessions of this script before starting a new session"
		exit 2
	fi
fi

#---------------------------

#Check what user is executing the script and allow root to execute certain functions.
if [[ "$EUID" != "$(id -u $SERVICE_NAME)" ]] && [[ "config_email" != "$1" ]] && [[ "config_tmpfs" != "$1" ]]; then
	echo "This script is only able to be executed by the $SERVICE_NAME user."
	echo "The following functions can also be executed as root: config_email, config_tmpfs"
	exit 3
fi

#---------------------------

#Script help page
case "$1" in
	help)
		echo -e "${CYAN}Time: $(date +"%Y-%m-%d %H:%M:%S") ${NC}"
		echo -e "${CYAN}$NAME server script by 7thCore${NC}"
		echo "Version: $VERSION"
		echo ""
		echo "Basic script commands:"
		echo -e "${GREEN}diag   ${RED}- ${GREEN}Prints out package versions and if script files are installed.${NC}"
		echo -e "${GREEN}status ${RED}- ${GREEN}Display status of server.${NC}"
		echo ""
		echo "Configuration and installation:"
		echo -e "${GREEN}config_script  ${RED}- ${GREEN}Configures the script, enables the systemd services and installs the wine prefix.${NC}"
		echo -e "${GREEN}config_steam   ${RED}- ${GREEN}Configures steamcmd, automatic updates and installs the game server files.${NC}"
		echo -e "${GREEN}config_discord ${RED}- ${GREEN}Configures discord integration.${NC}"
		echo -e "${GREEN}config_email   ${RED}- ${GREEN}Configures email integration. Due to postfix configuration files being in /etc this has to be executed as root.${NC}"
		echo ""
		echo "Server services managment:"
		echo -e "${GREEN}enable_services  ${RED}- ${GREEN}Enables all services dependant on the configuration file of the script.${NC}"
		echo -e "${GREEN}disable_services ${RED}- ${GREEN}Disables all services. The server and the script will not start up on boot anymore.${NC}"
		echo -e "${GREEN}reload_services  ${RED}- ${GREEN}Reloads all services, dependant on the configuration file.${NC}"
		echo ""
		echo "Server and console managment:"
		echo -e "${GREEN}start        ${RED}- ${GREEN}Start the server. If the server number is not specified the function will start all servers.${NC}"
		echo -e "${GREEN}stop         ${RED}- ${GREEN}Stop the server. If the server number is not specified the function will stop all servers.${NC}"
		echo -e "${GREEN}restart      ${RED}- ${GREEN}Restart the server. If the server number is not specified the function will restart all servers.${NC}"
		echo -e "${GREEN}attach       ${RED}- ${GREEN}Attaches to the tmux session of the specified server.${NC}"
		echo ""
		echo "Backup managment:"
		echo -e "${GREEN}backup        ${RED}- ${GREEN}Backup files, if server running or not.${NC}"
		echo ""
		echo "Steam managment:"
		echo -e "${GREEN}update        ${RED}- ${GREEN}Update the server, if the server is running it will save it, shut it down, update it and restart it.${NC}"
		echo -e "${GREEN}update_mods   ${RED}- ${GREEN}Update the server mods, if the server is running it wil save it, shut it down, update it and restart it${NC}"
		echo -e "${GREEN}verify        ${RED}- ${GREEN}Verifiy game server files, if the server is running it will save it, shut it down, verify it and restart it.${NC}"
		echo -e "${GREEN}change_branch ${RED}- ${GREEN}Changes the game branch in use by the server (public,experimental,legacy and so on).${NC}"
		echo ""
		echo "Game specific functions:"
		echo -e "${GREEN}delete_save   ${RED}- ${GREEN}Delete the server's save game with the option for deleting/keeping the server.json and other server files.${NC}"
		echo ""
		;;
#---------------------------
#Basic script functions
	diag)
		script_diagnostics
		;;
	status)
		script_status
		;;
#---------------------------
#Configuration and installation
	config_script)
		script_config_script
		;;
	config_steam)
		script_config_steam
		;;
	config_discord)
		script_config_discord
		;;
	config_email)
		script_config_email
		;;
#---------------------------
#Server services managment
	enable_services)
		script_enable_services_manual
		;;
	disable_services)
		script_disable_services_manual
		;;
	reload_services)
		script_reload_services
		;;
#---------------------------
#Server and console managment
	start)
		script_start
		;;
	stop)
		script_stop
		;;
	restart)
		script_restart
		;;
	save)
		script_save
		;;
	attach)
		script_attach
		;;
#---------------------------
#Backup managment
	backup)
		script_backup
		;;
#---------------------------
#Steam managment
	update)
		script_update
		;;
	update_mods)
		script_update_mods
		;;
	verify)
		script_verify_game_integrity
		;;
	change_branch)
		script_change_branch
		;;
#---------------------------
#Game specific functions
	delete_save)
		script_delete_save
		;;
#---------------------------
#Hidden functions meant for systemd service use
	pre-start)
		script_prestart
		;;
	post-start)
		script_poststart
		;;
	pre-stop)
		script_prestop
		;;
	post-stop)
		script_poststop
		;;
	send_notification_crash)
		script_send_notification_crash
		;;
	server_tmux_install)
		script_server_tmux_install $2 $3
		;;
	timer_one)
		script_timer_one
		;;
	timer_two)
		script_timer_two
		;;
	*)
#---------------------------
#General output if the script does not recognise the argument provided
	echo -e "${CYAN}Time: $(date +"%Y-%m-%d %H:%M:%S") ${NC}"
	echo -e "${CYAN}$NAME server script by 7thCore${NC}"
	echo ""
	echo "For more detailed information, execute the script with the -help argument"
	echo ""
	echo -e "${GREEN}Basic script commands${RED}: ${GREEN}help, diag, status${NC}"
	echo -e "${GREEN}Configuration and installation${RED}: ${GREEN}config_script, config_steam, config_discord, config_email${NC}"
	echo -e "${GREEN}Server services managment${RED}: ${GREEN}enable_services, disable_services, reload_services${NC}"
	echo -e "${GREEN}Server and console managment${RED}: ${GREEN}start, start_no_err, stop, restart, save, attach${NC}"
	echo -e "${GREEN}Backup managment${RED}: ${GREEN}backup${NC}"
	echo -e "${GREEN}Steam managment${RED}: ${GREEN}update, update_mods, verify, change_branch${NC}"
	echo -e "${GREEN}Game specific functions${RED}: ${GREEN}delete_save${NC}"
	exit 1
	;;
esac

exit 0
