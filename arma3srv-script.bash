#!/bin/bash

#Arma 3 server script by 7thCore
#If you do not know what any of these settings are you are better off leaving them alone. One thing might brake the other if you fiddle around with it.
export VERSION="202012090456"

#Basics
export NAME="Arma3Srv" #Name of the tmux session
if [ "$EUID" -ne "0" ]; then #Check if script executed as root and asign the username for the installation process, otherwise use the executing user
	USER="$(whoami)"
else
	if [[ "-install" == "$1" ]]; then
		echo "WARNING: Installation mode"
		read -p "Please enter username (leave empty for arma):" USER #Enter desired username that will be used when creating the new user
		USER=${USER:=arma} #If no username was given, use default
	elif [[ "-install_packages" == "$1" ]]; then
		echo "Commencing installation of required packages."
	elif [[ "-help" == "$1" ]]; then
		echo "Displaying help message"
	else
		echo "Error: This script, once installed, is meant to be used by the user it created and should not under any circumstances be used with sudo or by the root user for the $1 function. Only -install and -install_packages work with sudo/root. Log in to your created user (default: arma) with sudo -i -u arma and execute your script without root from the coresponding scripts folder."
		exit 1
	fi
fi

#Server configuration
SERVICE_NAME="arma3srv" #Name of the service files, script and script log
SRV_DIR="/home/$USER/server" #Location of the server located on your hdd/ssd
SCRIPT_NAME="$SERVICE_NAME-script.bash" #Script name
SCRIPT_DIR="/home/$USER/scripts" #Location of this script
UPDATE_DIR="/home/$USER/updates" #Location of update information for the script's automatic update feature

if [ -f "$SCRIPT_DIR/$SERVICE_NAME-config.conf" ] ; then
	#Steamcmd
	STEAMCMDUID=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep username= | cut -d = -f2) #Your steam username
	STEAMCMDPSW=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep password= | cut -d = -f2) #Your steam password
	BETA_BRANCH_ENABLED=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep beta_branch_enabled= | cut -d = -f2) #Beta branch enabled?
	BETA_BRANCH_NAME=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep beta_branch_name= | cut -d = -f2) #Beta branch name

	#Email configuration
	EMAIL_SENDER=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep email_sender= | cut -d = -f2) #Send emails from this address
	EMAIL_RECIPIENT=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep email_recipient= | cut -d = -f2) #Send emails to this address
	EMAIL_UPDATE=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep email_update= | cut -d = -f2) #Send emails when server updates
	EMAIL_UPDATE_SCRIPT=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep email_update_script= | cut -d = -f2) #Send notification when the script updates
	EMAIL_UPDATE_MOD=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep email_update= | cut -d = -f2) #Send emails when server updates
	EMAIL_START=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep email_start= | cut -d = -f2) #Send emails when the server starts up
	EMAIL_STOP=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep email_stop= | cut -d = -f2) #Send emails when the server shuts down
	EMAIL_CRASH=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep email_crash= | cut -d = -f2) #Send emails when the server crashes

	#Discord configuration
	DISCORD_UPDATE=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep discord_update= | cut -d = -f2) #Send notification when the server updates
	DISCORD_UPDATE_SCRIPT=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep discord_update_script= | cut -d = -f2) #Send notification when the script updates
	DISCORD_UPDATE_MOD=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep discord_update= | cut -d = -f2) #Send notification when the server updates
	DISCORD_START=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep discord_start= | cut -d = -f2) #Send notifications when the server starts
	DISCORD_STOP=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep discord_stop= | cut -d = -f2) #Send notifications when the server stops
	DISCORD_CRASH=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep discord_crash= | cut -d = -f2) #Send notifications when the server crashes

	#Save game configuration
	SAVE_DELOLD=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep save_delold= | cut -d = -f2) #How many latest save files should the script leave when deleting them.

	#Backup configuration
	BCKP_DELOLD=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep bckp_delold= | cut -d = -f2) #Delete old backups.

	#Log configuration
	LOG_DELOLD=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep log_delold= | cut -d = -f2) #Delete old logs.

	#Ignore failed startups during update configuration
	UPDATE_IGNORE_FAILED_ACTIVATIONS=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep update_ignore_failed_startups= | cut -d = -f2)

	#Script updates from github
	SCRIPT_UPDATES_GITHUB=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep script_updates= | cut -d = -f2) #Get configuration for script updates.

	#Mod configuration
	MODS_ENABLED=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep mods_enabled= | cut -d = -f2) #Are mods enabled?
	MODS=$(cat $SCRIPT_DIR/$SERVICE_NAME-config.conf | grep mod_list | cut -d = -f2) #Get mod list
else
	if [[ "-install" != "$1" ]] && [[ "-install_packages" != "$1" ]] && [[ "-help" != "$1" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Configuration) Error: The configuration file is missing. Generating missing configuration strings using default values."
	fi
fi

#App id of the steam game
APPID="233780"
WORKSHOP_APPID="107410"

if [ "$EUID" -ne "0" ]; then #Check if script executed as root and assign the backup source dir.
	BCKP_SRC_DIR="/home/$USER/.local/share" #Application data of the hdd/ssd
	SERVICE="$SERVICE_NAME.service" #Hdd/ssd service file name
fi

#Backup configuration
BCKP_SRC="Arma*" #What files to backup, * for all
BCKP_DIR="/home/$USER/backups" #Location of stored backups
BCKP_DEST="$BCKP_DIR/$(date +"%Y")/$(date +"%m")/$(date +"%d")" #How backups are sorted, by default it's sorted in folders by month and day

#Log configuration
export LOG_DIR="/home/$USER/logs/$(date +"%Y")/$(date +"%m")/$(date +"%d")"
export LOG_DIR_ALL="/home/$USER/logs"
export LOG_SCRIPT="$LOG_DIR/$SERVICE_NAME-script.log" #Script log
export LOG_TMP="/tmp/$USER-$SERVICE_NAME-tmux.log"
export CRASH_DIR="/home/$USER/logs/crashes/$(date +"%Y-%m-%d_%H-%M")"

#-------Do not edit anything beyond this line-------

#Console collors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
LIGHTRED='\033[1;31m'
NC='\033[0m'

#Generate log folder structure
script_logs() {
	#If there is not a folder for today, create one
	if [ ! -d "$LOG_DIR" ]; then
		mkdir -p $LOG_DIR
	fi
}

#Deletes old files
script_remove_old_files() {
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Remove old files) Beginning removal of old files." | tee -a "$LOG_SCRIPT"
	#Delete old logs
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Remove old files) Removing old script logs: $LOG_DELOLD days old." | tee -a "$LOG_SCRIPT"
	find $LOG_DIR_ALL/* -mtime +$LOG_DELOLD -delete
	#Delete empty folders
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Remove old files) Removing empty script log folders." | tee -a "$LOG_SCRIPT"
	find $LOG_DIR_ALL/ -type d -empty -delete
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Remove old files) Removal of old files complete." | tee -a "$LOG_SCRIPT"
}

#Prints out if the server is running
script_status() {
	script_logs
	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "inactive" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Status) Server is not running." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Status) Server running." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "failed" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Status) Server is in failed state. Please check logs." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "activating" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Status) Server is activating. Please wait." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "deactivating" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Status) Server is in deactivating. Please wait." | tee -a "$LOG_SCRIPT"
	fi
}

#Attaches to the server tmux session
script_attach() {
	tmux -L $USER-tmux.sock attach -t $NAME
}

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
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Disable services) Services successfully disabled." | tee -a "$LOG_SCRIPT"
}

#Disables all script services, available to the user
script_disable_services_manual() {
	script_logs
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Disable services) WARNING: This will disable all script services. The server will be disabled." | tee -a "$LOG_SCRIPT"
	read -p "Are you sure you want to disable all services? (y/n): " DISABLE_SCRIPT_SERVICES
	if [[ "$DISABLE_SCRIPT_SERVICES" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		script_disable_services
	elif [[ "$DISABLE_SCRIPT_SERVICES" =~ ^([nN][oO]|[nN])$ ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Disable services) Disable services canceled." | tee -a "$LOG_SCRIPT"
	fi
}

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
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Enable services) Services successfully Enabled." | tee -a "$LOG_SCRIPT"
}

# Enable script services by reading the configuration file, available to the user
script_enable_services_manual() {
	script_logs
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Enable services) This will enable all script services. The server will be enabled." | tee -a "$LOG_SCRIPT"
	read -p "Are you sure you want to enable all services? (y/n): " ENABLE_SCRIPT_SERVICES
	if [[ "$ENABLE_SCRIPT_SERVICES" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		script_enable_services
	elif [[ "$ENABLE_SCRIPT_SERVICES" =~ ^([nN][oO]|[nN])$ ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Enable services) Enable services canceled." | tee -a "$LOG_SCRIPT"
	fi
}

#Disables all script services an re-enables them by reading the configuration file
script_reload_services() {
	script_logs
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Reload services) This will reload all script services." | tee -a "$LOG_SCRIPT"
	read -p "Are you sure you want to reload all services? (y/n): " RELOAD_SCRIPT_SERVICES
	if [[ "$RELOAD_SCRIPT_SERVICES" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		script_disable_services
		systemctl --user daemon-reload
		script_enable_services
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Reload services) Reload services complete." | tee -a "$LOG_SCRIPT"
	elif [[ "$RELOAD_SCRIPT_SERVICES" =~ ^([nN][oO]|[nN])$ ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Reload services) Reload services canceled." | tee -a "$LOG_SCRIPT"
	fi
}

#Systemd service sends notification if notifications for start enabled
script_send_notification_start_initialized() {
	script_logs
	if [[ "$EMAIL_START" == "1" ]]; then
		mail -r "$EMAIL_SENDER ($NAME-$USER)" -s "Notification: Server startup" $EMAIL_RECIPIENT <<- EOF
		Server startup was initiated at $(date +"%d.%m.%Y %H:%M:%S")
		EOF
	fi
	if [[ "$DISCORD_START" == "1" ]]; then
		while IFS="" read -r DISCORD_WEBHOOK || [ -n "$DISCORD_WEBHOOK" ]; do
			curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Start) Server startup was initialized.\"}" "$DISCORD_WEBHOOK"
		done < $SCRIPT_DIR/discord_webhooks.txt
	fi
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Start) Server startup initialized." | tee -a "$LOG_SCRIPT"
}

#Systemd service sends notification if notifications for start enabled
script_send_notification_start_complete() {
	script_logs
	if [[ "$EMAIL_START" == "1" ]]; then
		mail -r "$EMAIL_SENDER ($NAME-$USER)" -s "Notification: Server startup" $EMAIL_RECIPIENT <<- EOF
		Server startup was completed at $(date +"%d.%m.%Y %H:%M:%S")
		EOF
	fi
	if [[ "$DISCORD_START" == "1" ]]; then
		while IFS="" read -r DISCORD_WEBHOOK || [ -n "$DISCORD_WEBHOOK" ]; do
			curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Start) Server startup complete.\"}" "$DISCORD_WEBHOOK"
		done < $SCRIPT_DIR/discord_webhooks.txt
	fi
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Start) Server startup complete." | tee -a "$LOG_SCRIPT"
}

#Systemd service sends notification if notifications for stop enabled
script_send_notification_stop_initialized() {
	script_logs
	if [[ "$EMAIL_START" == "1" ]]; then
		mail -r "$EMAIL_SENDER ($NAME-$USER)" -s "Notification: Server shutdown" $EMAIL_RECIPIENT <<- EOF
		Server shutdown was initiated at $(date +"%d.%m.%Y %H:%M:%S")
		EOF
	fi
	if [[ "$DISCORD_START" == "1" ]]; then
		while IFS="" read -r DISCORD_WEBHOOK || [ -n "$DISCORD_WEBHOOK" ]; do
			curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Start) Server shutdown in progress.\"}" "$DISCORD_WEBHOOK"
		done < $SCRIPT_DIR/discord_webhooks.txt
	fi
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Stop) Server shutdown in progress." | tee -a "$LOG_SCRIPT"
}

#Systemd service sends notification if notifications for stop enabled
script_send_notification_stop_complete() {
	script_logs
	if [[ "$EMAIL_START" == "1" ]]; then
		mail -r "$EMAIL_SENDER ($NAME-$USER)" -s "Notification: Server shutdown" $EMAIL_RECIPIENT <<- EOF
		Server shutdown was complete at $(date +"%d.%m.%Y %H:%M:%S")
		EOF
	fi
	if [[ "$DISCORD_START" == "1" ]]; then
		while IFS="" read -r DISCORD_WEBHOOK || [ -n "$DISCORD_WEBHOOK" ]; do
			curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Start) Server shutdown complete.\"}" "$DISCORD_WEBHOOK"
		done < $SCRIPT_DIR/discord_webhooks.txt
	fi
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Stop) Server shutdown complete." | tee -a "$LOG_SCRIPT"
}

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
	
	if [[ "$EMAIL_CRASH" == "1" ]]; then
		mail -a $CRASH_DIR/service_logs.zip -a $CRASH_DIR/script_logs.zip -r "$EMAIL_SENDER ($NAME-$USER)" -s "Notification: Crash" $EMAIL_RECIPIENT <<- EOF
		The server crashed 3 times in the last 5 minutes. Automatic restart is disabled and the server is inactive. Please check the logs for more information.
		
		Attachment contents:
		service_logs.zip - Logs from the systemd service
		script_logs.zip - Logs from the script
		
		DO NOT SEND ANY OF THESE TO THE DEVS!
		
		Contact the script developer 7thCore on discord for help regarding any problems the script may have caused.
		EOF
	fi
	
	if [[ "$DISCORD_CRASH" == "1" ]]; then
		while IFS="" read -r DISCORD_WEBHOOK || [ -n "$DISCORD_WEBHOOK" ]; do
			curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Crash) The server crashed 3 times in the last 5 minutes. Automatic restart is disabled and the server is inactive. Please review your logs located in $CRASH_DIR.\"}" "$DISCORD_WEBHOOK"
		done < $SCRIPT_DIR/discord_webhooks.txt
	fi
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Crash) Server crashed. Please review your logs located in $CRASH_DIR." | tee -a "$LOG_SCRIPT"
}

#Start the server
script_start() {
	script_logs
	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "inactive" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Start) Server start initialized." | tee -a "$LOG_SCRIPT"
		systemctl --user start $SERVICE
		sleep 1
		while [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "activating" ]]; do
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Start) Server is activating. Please wait..." | tee -a "$LOG_SCRIPT"
			sleep 1
		done
		if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Start) Server has been successfully activated." | tee -a "$LOG_SCRIPT"
			sleep 1
		elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "failed" ]]; then
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Start) Server failed to activate. See systemctl --user status $SERVICE for details." | tee -a "$LOG_SCRIPT"
			sleep 1
		fi
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Start) Server is already running." | tee -a "$LOG_SCRIPT"
		sleep 1
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "failed" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Start) Server is in failed state. See systemctl --user status $SERVICE for details." | tee -a "$LOG_SCRIPT"
		read -p "Do you still want to start the server? (y/n): " FORCE_START
		if [[ "$FORCE_START" =~ ^([yY][eE][sS]|[yY])$ ]]; then
			systemctl --user start $SERVICE
			sleep 1
			while [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "activating" ]]; do
				echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Start) Server is activating. Please wait..." | tee -a "$LOG_SCRIPT"
				sleep 1
			done
			if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
				echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Start) Server has been successfully activated." | tee -a "$LOG_SCRIPT"
				sleep 1
			elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "failed" ]]; then
				echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Start) Server failed to activate. See systemctl --user status $SERVICE for details." | tee -a "$LOG_SCRIPT"
				sleep 1
			fi
		fi
	fi
}

#Start the server ignorring failed states
script_start_ignore_errors() {
	script_logs
	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "inactive" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Start) Server start initialized." | tee -a "$LOG_SCRIPT"
		systemctl --user start $SERVICE
		sleep 1
		while [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "activating" ]]; do
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Start) Server is activating. Please wait..." | tee -a "$LOG_SCRIPT"
			sleep 1
		done
		if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Start) Server has been successfully activated." | tee -a "$LOG_SCRIPT"
			sleep 1
		elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "failed" ]]; then
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Start) Server failed to activate. See systemctl --user status $SERVICE for details." | tee -a "$LOG_SCRIPT"
			sleep 1
		fi
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Start) Server is already running." | tee -a "$LOG_SCRIPT"
		sleep 1
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "failed" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Start) Server is in failed state. See systemctl --user status $SERVICE for details." | tee -a "$LOG_SCRIPT"
		systemctl --user start $SERVICE
		sleep 1
		while [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "activating" ]]; do
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Start) Server is activating. Please wait..." | tee -a "$LOG_SCRIPT"
			sleep 1
		done
		if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Start) Server has been successfully activated." | tee -a "$LOG_SCRIPT"
			sleep 1
		elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "failed" ]]; then
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Start) Server failed to activate. See systemctl --user status $SERVICE for details." | tee -a "$LOG_SCRIPT"
			sleep 1
		fi
	fi
}

#Stop the server
script_stop() {
	script_logs
	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "inactive" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Stop) Server is not running." | tee -a "$LOG_SCRIPT"
		sleep 1
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Stop) Server shutdown in progress." | tee -a "$LOG_SCRIPT"
		systemctl --user stop $SERVICE
		sleep 1
		while [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "deactivating" ]]; do
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Stop) Server is deactivating. Please wait..." | tee -a "$LOG_SCRIPT"
			sleep 1
		done
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Stop) Server is deactivated." | tee -a "$LOG_SCRIPT"
	fi
}

#Restart the server
script_restart() {
	script_logs
	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "inactive" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Restart) Server is not running. Use -start to start the server." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "activating" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Restart) Server is activating. Aborting restart." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "deactivating" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Restart) Server is in deactivating. Aborting restart." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Restart) Server is going to restart in 15-30 seconds, please wait..." | tee -a "$LOG_SCRIPT"
		sleep 1
		script_stop
		sleep 1
		script_start
		sleep 1
	fi
}

#Deletes old backups
script_deloldbackup() {
	script_logs
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Delete old backup) Deleting old backups: $BCKP_DELOLD days old." | tee -a "$LOG_SCRIPT"
	# Delete old backups
	find $BCKP_DIR/* -type f -mtime +$BCKP_DELOLD -exec rm {} \;
	# Delete empty folders
	#find $BCKP_DIR/ -type d 2> /dev/null -empty -exec rm -rf {} \;
	find $BCKP_DIR/ -type d -empty -delete
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Delete old backup) Deleting old backups complete." | tee -a "$LOG_SCRIPT"
}

#Backs up the server
script_backup() {
	script_logs
	#If there is not a folder for today, create one
	if [ ! -d "$BCKP_DEST" ]; then
		mkdir -p $BCKP_DEST
	fi
	#Backup source to destination
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Backup) Backup has been initiated." | tee -a "$LOG_SCRIPT"
	cd "$BCKP_SRC_DIR"
	tar -cpvzf $BCKP_DEST/$(date +"%Y%m%d%H%M").tar.gz $BCKP_SRC #| sed -e "s/^/$(date +"%Y-%m-%d %H:%M:%S") [$NAME] [INFO] (Backup) Compressing: /" | tee -a "$LOG_SCRIPT"
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Backup) Backup complete." | tee -a "$LOG_SCRIPT"
}

#Automaticly backs up the server and deletes old backups
script_autobackup() {
	script_logs
	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" != "active" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Autobackup) Server is not running." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
		sleep 1
		script_backup
		sleep 1
		script_deloldbackup
	fi
}

#Delete the savegame from the server
script_delete_save() {
	script_logs
	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" != "active" ]] && [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" != "activating" ]] && [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" != "deactivating" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Delete save) WARNING! This will delete the server's save game." | tee -a "$LOG_SCRIPT"
		read -p "Are you sure you want to delete the server's save game? (y/n): " DELETE_SERVER_SAVE
		if [[ "$DELETE_SERVER_SAVE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
			read -p "Do you also want to delete the server.cfg file? (y/n): " DELETE_SERVER_CONFIG
			if [[ "$DELETE_SERVER_CONFIG" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				rm -rf $SRV_DIR/server.cfg
				rm -rf "/home/$USER/.local/share/Arma 3/*"
				rm -rf "/home/$USER/.local/share/Arma 3 - Other Profiles/*"
				echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Delete save) Deletion of save files and the server.cfg file complete." | tee -a "$LOG_SCRIPT"
			elif [[ "$DELETE_SERVER_CONFIG" =~ ^([nN][oO]|[nN])$ ]]; then
				rm -rf "/home/$USER/.local/share/Arma 3/*"
				rm -rf "/home/$USER/.local/share/Arma 3 - Other Profiles/*"
				echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Delete save) Deletion of save files complete. The server.cfg file is untouched." | tee -a "$LOG_SCRIPT"
			fi
		elif [[ "$DELETE_SERVER_SAVE" =~ ^([nN][oO]|[nN])$ ]]; then
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Delete save) Save deletion canceled." | tee -a "$LOG_SCRIPT"
		fi
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Clear save) The server is running. Aborting..." | tee -a "$LOG_SCRIPT"
	fi
}

#Change the steam branch of the app
script_change_branch() {
	script_logs
	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" != "active" ]] && [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" != "activating" ]] && [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" != "deactivating" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Change branch) Server branch change initiated. Waiting on user configuration." | tee -a "$LOG_SCRIPT"
		read -p "Are you sure you want to change the server branch? (y/n): " CHANGE_SERVER_BRANCH
		if [[ "$CHANGE_SERVER_BRANCH" =~ ^([yY][eE][sS]|[yY])$ ]]; then
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Change branch) Clearing game installation." | tee -a "$LOG_SCRIPT"
			rm -rf $SRV_DIR/*
			if [[ "$BETA_BRANCH_ENABLED" == "1" ]]; then
				PUBLIC_BRANCH="0"
			elif [[ "$BETA_BRANCH_ENABLED" == "0" ]]; then
				PUBLIC_BRANCH="1"
			fi
			echo "Current configuration:"
			echo 'Public branch: '"$PUBLIC_BRANCH"
			echo 'Beta branch enabled: '"$BETA_BRANCH_ENABLED"
			echo 'Beta branch name: '"$BETA_BRANCH_NAME"
			echo ""
			read -p "Public branch or beta branch? (public/beta): " SET_BRANCH_STATE
			echo ""
			if [[ "$SET_BRANCH_STATE" =~ ^([bB][eE][tT][aA]|[bB])$ ]]; then
				BETA_BRANCH_ENABLED="1"
				echo "Look up beta branch names at https://steamdb.info/app/$APPID/depots/"
				echo "Name example: experimental"
				read -p "Enter beta branch name: " BETA_BRANCH_NAME
			elif [[ "$SET_BRANCH_STATE" =~ ^([pP][uU][bB][lL][iI][cC]|[pP])$ ]]; then
				BETA_BRANCH_ENABLED="0"
				BETA_BRANCH_NAME="none"
			fi
			sed -i '/beta_branch_enabled/d' $SCRIPT_DIR/$SERVICE_NAME-config.conf
			sed -i '/beta_branch_name/d' $SCRIPT_DIR/$SERVICE_NAME-config.conf
			echo 'beta_branch_enabled='"$BETA_BRANCH_ENABLED" >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
			echo 'beta_branch_name='"$BETA_BRANCH_NAME" >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
			if [[ "$BETA_BRANCH_ENABLED" == "0" ]]; then
				steamcmd +login $STEAMCMDUID $STEAMCMDPSW +app_info_update 1 +app_info_print $APPID +quit | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"public\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"buildid\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3 > $UPDATE_DIR/available.buildid
				steamcmd +login $STEAMCMDUID $STEAMCMDPSW +app_info_update 1 +app_info_print $APPID +quit | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"public\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"timeupdated\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3 > $UPDATE_DIR/available.timeupdated
				steamcmd +login $STEAMCMDUID $STEAMCMDPSW +force_install_dir $SRV_DIR/ +app_update $APPID -beta validate +quit
			elif [[ "$BETA_BRANCH_ENABLED" == "1" ]]; then
				steamcmd +login $STEAMCMDUID $STEAMCMDPSW +app_info_update 1 +app_info_print $APPID +quit | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"$BETA_BRANCH_NAME\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"buildid\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3 > $UPDATE_DIR/available.buildid
				steamcmd +login $STEAMCMDUID $STEAMCMDPSW +app_info_update 1 +app_info_print $APPID +quit | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"$BETA_BRANCH_NAME\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"timeupdated\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3 > $UPDATE_DIR/available.timeupdated
				steamcmd +login $STEAMCMDUID $STEAMCMDPSW +force_install_dir $SRV_DIR/ +app_update $APPID -beta $BETA_BRANCH_NAME validate +quit
			fi
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Change branch) Server branch change complete." | tee -a "$LOG_SCRIPT"
		elif [[ "$CHANGE_SERVER_BRANCH" =~ ^([nN][oO]|[nN])$ ]]; then
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Change branch) Server branch change canceled." | tee -a "$LOG_SCRIPT"
		fi
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Change branch) The server is running. Aborting..." | tee -a "$LOG_SCRIPT"
	fi
}

script_install_mods() {
	if [[ "$MODS_ENABLED" == "1" ]]; then
		#rm -v /home/$USER/server/keys/ !("a3.bikey")
		IFS=","
		for MOD_NAME_ID in $MODS; do
			echo "SteamCmd is updating mod $MOD_NAME_ID"
			MOD_ID=$(echo $MOD_NAME_ID | cut -d - -f2)
			MOD_NAME=$(echo $MOD_NAME_ID | cut -d - -f1)
			steamcmd +login $STEAMCMDUID $STEAMCMDPSW +force_install_dir /home/arma-antistasi/server/ +workshop_download_item $WORKSHOP_APPID $MOD_ID +quit
			ln -s /home/$USER/server/steamapps/workshop/content/$WORKSHOP_APPID/$MOD_ID /home/$USER/server/@$MOD_NAME
			if [ -f "/home/$USER/server/steamapps/workshop/content/$WORKSHOP_APPID/$MOD_ID/keys/*.bikey" ]; then
				cp /home/$USER/server/steamapps/workshop/content/$WORKSHOP_APPID/$MOD_ID/keys/*.bikey /home/$USER/server/keys/
			fi
			if [ -f "/home/$USER/server/steamapps/workshop/content/$WORKSHOP_APPID/$MOD_ID/key/*.bikey" ]; then
				cp /home/$USER/server/steamapps/workshop/content/$WORKSHOP_APPID/$MOD_ID/key/*.bikey /home/$USER/server/keys/
			fi
		done
	fi
}

#Check for updates. If there are updates available, shut down the server, update it and restart it.
script_update() {
	script_logs
	if [[ "$STEAMCMDUID" == "disabled" ]] && [[ "$STEAMCMDPSW" == "disabled" ]]; then
		while [[ "$STEAMCMDSUCCESS" != "0" ]]; do
			read -p "Enter your Steam username: " STEAMCMDUID
			echo ""
			read -p "Enter your Steam password: " STEAMCMDPSW
			teamcmd +login $STEAMCMDUID $STEAMCMDPSW +quit
			STEAMCMDSUCCESS=$?
			if [[ "$STEAMCMDSUCCESS" == "0" ]]; then
				echo "Steam login for $STEAMCMDUID: SUCCEDED!"
			elif [[ "$STEAMCMDSUCCESS" != "0" ]]; then
				echo "Steam login for $STEAMCMDUID: FAILED!"
				echo "Please try again."
			fi
		done
	fi
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Update) Initializing update check." | tee -a "$LOG_SCRIPT"
	if [[ "$BETA_BRANCH_ENABLED" == "1" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Update) Beta branch enabled. Branch name: $BETA_BRANCH_NAME" | tee -a "$LOG_SCRIPT"
	fi
	
	if [ ! -f $UPDATE_DIR/installed.buildid ] ; then
		touch $UPDATE_DIR/installed.buildid
		echo "0" > $UPDATE_DIR/installed.buildid
	fi
	
	if [ ! -f $UPDATE_DIR/installed.timeupdated ] ; then
		touch $UPDATE_DIR/installed.timeupdated
		echo "0" > $UPDATE_DIR/installed.timeupdated
	fi
	
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Update) Removing Steam/appcache/appinfo.vdf" | tee -a "$LOG_SCRIPT"
	rm -rf "/home/$USER/.steam/appcache/appinfo.vdf"
	
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Update) Connecting to steam servers." | tee -a "$LOG_SCRIPT"
	
	if [[ "$BETA_BRANCH_ENABLED" == "0" ]]; then
		AVAILABLE_BUILDID=$(steamcmd +login $STEAMCMDUID $STEAMCMDPSW +app_info_update 1 +app_info_print $APPID +quit | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"public\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"buildid\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3)
		AVAILABLE_TIME=$(steamcmd +login $STEAMCMDUID $STEAMCMDPSW +app_info_update 1 +app_info_print $APPID +quit | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"public\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"timeupdated\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3)
	elif [[ "$BETA_BRANCH_ENABLED" == "1" ]]; then
		AVAILABLE_BUILDID=$(steamcmd +login $STEAMCMDUID $STEAMCMDPSW +app_info_update 1 +app_info_print $APPID +quit | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"$BETA_BRANCH_NAME\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"buildid\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3)
		AVAILABLE_TIME=$(steamcmd +login $STEAMCMDUID $STEAMCMDPSW +app_info_update 1 +app_info_print $APPID +quit | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"$BETA_BRANCH_NAME\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"timeupdated\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3)
	fi
	
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Update) Received application info data." | tee -a "$LOG_SCRIPT"
	
	INSTALLED_BUILDID=$(cat $UPDATE_DIR/installed.buildid)
	INSTALLED_TIME=$(cat $UPDATE_DIR/installed.timeupdated)
	
	if [ "$AVAILABLE_TIME" -gt "$INSTALLED_TIME" ]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Update) New update detected." | tee -a "$LOG_SCRIPT"
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Update) Installed: BuildID: $INSTALLED_BUILDID, TimeUpdated: $INSTALLED_TIME" | tee -a "$LOG_SCRIPT"
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Update) Available: BuildID: $AVAILABLE_BUILDID, TimeUpdated: $AVAILABLE_TIME" | tee -a "$LOG_SCRIPT"
		
		if [[ "$DISCORD_UPDATE" == "1" ]]; then
			while IFS="" read -r DISCORD_WEBHOOK || [ -n "$DISCORD_WEBHOOK" ]; do
				curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Update) New update detected. Installing update.\"}" "$DISCORD_WEBHOOK"
			done < $SCRIPT_DIR/discord_webhooks.txt
		fi
		
		if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
			sleep 1
			WAS_ACTIVE="1"
			script_stop
			sleep 1
		fi
		
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Update) Updating..." | tee -a "$LOG_SCRIPT"
		
		if [[ "$BETA_BRANCH_ENABLED" == "0" ]]; then
			steamcmd +login $STEAMCMDUID $STEAMCMDPSW +force_install_dir $SRV_DIR/ +app_update $APPID validate +quit
		elif [[ "$BETA_BRANCH_ENABLED" == "1" ]]; then
			steamcmd +login $STEAMCMDUID $STEAMCMDPSW +force_install_dir $SRV_DIR/ +app_update $APPID -beta $BETA_BRANCH_NAME validate +quit
		fi
		
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Update) Update completed." | tee -a "$LOG_SCRIPT"
		echo "$AVAILABLE_BUILDID" > $UPDATE_DIR/installed.buildid
		echo "$AVAILABLE_TIME" > $UPDATE_DIR/installed.timeupdated
		
		if [ "$WAS_ACTIVE" == "1" ]; then
			sleep 1
			if [[ "$UPDATE_IGNORE_FAILED_ACTIVATIONS" == "1" ]]; then
				script_start_ignore_errors
			else
				script_start
			fi
			script_start
		fi
		
		if [[ "$EMAIL_UPDATE" == "1" ]]; then
			mail -r "$EMAIL_SENDER ($NAME-$USER)" -s "Notification: Update" $EMAIL_RECIPIENT <<- EOF
			Server was updated. Please check the update notes if there are any additional steps to take.
			EOF
		fi
		
		if [[ "$DISCORD_UPDATE" == "1" ]]; then
			while IFS="" read -r DISCORD_WEBHOOK || [ -n "$DISCORD_WEBHOOK" ]; do
				curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Update) Server update complete.\"}" "$DISCORD_WEBHOOK"
			done < $SCRIPT_DIR/discord_webhooks.txt
		fi
	elif [ "$AVAILABLE_TIME" -eq "$INSTALLED_TIME" ]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Update) No new updates detected." | tee -a "$LOG_SCRIPT"
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Update) Installed: BuildID: $INSTALLED_BUILDID, TimeUpdated: $INSTALLED_TIME" | tee -a "$LOG_SCRIPT"
	fi
}

#Check for updates of mods. If there are updates available, shut down the server, update it and restart it.
script_update_mods() {
	script_logs
	if [[ "$MODS_ENABLED" == "1" ]]; then
		if [[ "$STEAMCMDUID" == "disabled" ]] && [[ "$STEAMCMDPSW" == "disabled" ]]; then
		while [[ "$STEAMCMDSUCCESS" != "0" ]]; do
			read -p "Enter your Steam username: " STEAMCMDUID
			echo ""
			read -p "Enter your Steam password: " STEAMCMDPSW
			steamcmd +login $STEAMCMDUID $STEAMCMDPSW +quit
			STEAMCMDSUCCESS=$?
			if [[ "$STEAMCMDSUCCESS" == "0" ]]; then
				echo "Steam login for $STEAMCMDUID: SUCCEDED!"
			elif [[ "$STEAMCMDSUCCESS" != "0" ]]; then
				echo "Steam login for $STEAMCMDUID: FAILED!"
				echo "Please try again."
			fi
		done
		fi
		MODS_TO_UPDATE=""
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Mod Update) Checking for mod updates." | tee -a "$LOG_SCRIPT"
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
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Mod Update) New mod updates detected. Installing updates." | tee -a "$LOG_SCRIPT"
			if [[ "$DISCORD_UPDATE_MOD" == "1" ]]; then
				while IFS="" read -r DISCORD_WEBHOOK || [ -n "$DISCORD_WEBHOOK" ]; do
					curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Mod Update) New updates detected. Installing updates.\"}" "$DISCORD_WEBHOOK"
				done < $SCRIPT_DIR/discord_webhooks.txt
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
				echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Mod Update) New update detected for mod $MOD_NAME." | tee -a "$LOG_SCRIPT"
				echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Mod Update) Installed: $INSTALLED_VERSION_MOD" | tee -a "$LOG_SCRIPT"
				echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Mod Update) Available: $AVAILABLE_VERSION_MOD" | tee -a "$LOG_SCRIPT"
				steamcmd +login $STEAMCMDUID $STEAMCMDPSW +force_install_dir $SRV_DIR/ +workshop_download_item $WORKSHOP_APPID $MOD_ID +quit
				ln -s /home/$USER/server/steamapps/workshop/content/$WORKSHOP_APPID/$MOD_ID /home/$USER/server/@$MOD_NAME
				if [ -f "/home/$USER/server/steamapps/workshop/content/$WORKSHOP_APPID/keys/*.bikey" ]; then
					cp -rf /home/$USER/server/steamapps/workshop/content/$WORKSHOP_APPID/keys/*.bikey /home/$USER/server/keys/
				fi
				if [ -f "/home/$USER/server/steamapps/workshop/content/$WORKSHOP_APPID/key/*.bikey" ]; then
					cp -rf /home/$USER/server/steamapps/workshop/content/$WORKSHOP_APPID/key/*.bikey /home/$USER/server/keys/
				fi
				echo "$AVAILABLE_VERSION_MOD" > $UPDATE_DIR/mods/$MOD_NAME.mod_version
				echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Mod Update) Update for mod $MOD_NAME complete." | tee -a "$LOG_SCRIPT"
			done
			
			if [ "$WAS_ACTIVE" == "1" ]; then
				sleep 1
				if [[ "$UPDATE_IGNORE_FAILED_ACTIVATIONS" == "1" ]]; then
					script_start_ignore_errors
				else
					script_start
				fi
			fi
			
			if [[ "$EMAIL_UPDATE_MOD" == "1" ]]; then
				mail -r "$EMAIL_SENDER ($NAME-$USER)" -s "Notification: Mod Update" $EMAIL_RECIPIENT <<- EOF
				Mods ware updated. Please check the update notes if there are any additional steps to take.
				Updated mods: $MODS_TO_UPDATE
				EOF
			fi
			
			if [[ "$DISCORD_UPDATE_MOD" == "1" ]]; then
				while IFS="" read -r DISCORD_WEBHOOK || [ -n "$DISCORD_WEBHOOK" ]; do
					curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Mod Update) Update complete.\nUpdated mods: $MODS_TO_UPDATE\"}" "$DISCORD_WEBHOOK"
				done < $SCRIPT_DIR/discord_webhooks.txt
			fi
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Mod Update) Update for all mods complete." | tee -a "$LOG_SCRIPT"
		else
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Mod Update) All mods are up to date." | tee -a "$LOG_SCRIPT"
		fi
	fi
}

#Shutdown any active servers, check the integrity of the server files and restart the servers.
script_verify_game_integrity() {
	script_logs
	if [[ "$STEAMCMDUID" == "disabled" ]] && [[ "$STEAMCMDPSW" == "disabled" ]]; then
		while [[ "$STEAMCMDSUCCESS" != "0" ]]; do
			read -p "Enter your Steam username: " STEAMCMDUID
			echo ""
			read -p "Enter your Steam password: " STEAMCMDPSW
			steamcmd +login $STEAMCMDUID $STEAMCMDPSW +quit
			STEAMCMDSUCCESS=$?
			if [[ "$STEAMCMDSUCCESS" == "0" ]]; then
				echo "Steam login for $STEAMCMDUID: SUCCEDED!"
			elif [[ "$STEAMCMDSUCCESS" != "0" ]]; then
				echo "Steam login for $STEAMCMDUID: FAILED!"
				echo "Please try again."
			fi
		done
	fi
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Integrity check) Initializing integrity check." | tee -a "$LOG_SCRIPT"
	if [[ "$BETA_BRANCH_ENABLED" == "1" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Integrity check) Beta branch enabled. Branch name: $BETA_BRANCH_NAME" | tee -a "$LOG_SCRIPT"
	fi
	
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Integrity check) Removing Steam/appcache/appinfo.vdf" | tee -a "$LOG_SCRIPT"
	rm -rf "/home/$USER/.steam/appcache/appinfo.vdf"
	
	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
		sleep 1
		WAS_ACTIVE="1"
		script_stop
		sleep 1
	fi
	
	if [[ "$BETA_BRANCH_ENABLED" == "0" ]]; then
		steamcmd +login $STEAMCMDUID $STEAMCMDPSW +force_install_dir $SRV_DIR/ +app_update $APPID validate +quit
	elif [[ "$BETA_BRANCH_ENABLED" == "1" ]]; then
		steamcmd +login $STEAMCMDUID $STEAMCMDPSW +force_install_dir $SRV_DIR/ +app_update $APPID -beta $BETA_BRANCH_NAME validate +quit
	fi
	
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Integrity check) Integrity check completed." | tee -a "$LOG_SCRIPT"
	
	if [ "$WAS_ACTIVE" == "1" ]; then
		sleep 1
		if [[ "$UPDATE_IGNORE_FAILED_ACTIVATIONS" == "1" ]]; then
			script_start_ignore_errors
		else
			script_start
		fi
	fi
}

script_install_alias() {
	if [ "$EUID" -ne "0" ]; then #Check if script executed as root and asign the username for the installation process, otherwise use the executing user
		script_logs
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Install .bashrc aliases) Installation of aliases in .bashrc commencing. Waiting on user configuration." | tee -a "$LOG_SCRIPT"
		read -p "Are you sure you want to install bash aliases into .bashrc? (y/n): " INSTALL_BASHRC_ALIAS
		if [[ "$INSTALL_BASHRC_ALIAS" =~ ^([yY][eE][sS]|[yY])$ ]]; then
			INSTALL_BASHRC_ALIAS_STATE="1"
		elif [[ "$INSTALL_BASHRC_ALIAS" =~ ^([nN][oO]|[nN])$ ]]; then
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Install .bashrc aliases) Installation of aliases in .bashrc aborted." | tee -a "$LOG_SCRIPT"
			INSTALL_BASHRC_ALIAS_STATE="0"
		fi
	else
		INSTALL_BASHRC_ALIAS_STATE="1"
	fi
	
	if [[ "$INSTALL_BASHRC_ALIAS_STATE" == "1" ]]; then
		cat >> /home/$USER/.bashrc <<- EOF
			alias $SERVICE_NAME="/home/$USER/scripts/$SERVICE_NAME-script.bash"
		EOF
	fi
	
	if [ "$EUID" -ne "0" ]; then
		if [[ "$INSTALL_BASHRC_ALIAS_STATE" == "1" ]]; then
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Install .bashrc aliases) Installation of aliases in .bashrc complete. Re-log for the changes to take effect." | tee -a "$LOG_SCRIPT"
			echo "Aliases:"
			echo "$SERVICE_NAME -attach = Attaches to the server console."
		fi
	fi
}

#Install tmux configuration for specific server when first ran
script_server_tmux_install() {
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Server tmux configuration) Installing tmux configuration for server." | tee -a "$LOG_SCRIPT"
	if [ ! -f /tmp/$USER-$SERVICE_NAME-tmux.conf ]; then
		touch /tmp/$USER-$SERVICE_NAME-tmux.conf
		cat > /tmp/$USER-$SERVICE_NAME-tmux.conf <<- EOF
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
		bind-key r source-file /tmp/$USER-$SERVICE_NAME-tmux.conf \; display-message "Config reloaded!"

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
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Server tmux configuration) Tmux configuration for server installed successfully." | tee -a "$LOG_SCRIPT"
	fi
}

#Install or reinstall systemd services
script_install_services() {
	if [ "$EUID" -ne "0" ]; then #Check if script executed as root and asign the username for the installation process, otherwise use the executing user
		script_logs
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Reinstall systemd services) Systemd services reinstallation commencing. Waiting on user configuration." | tee -a "$LOG_SCRIPT"
		read -p "Are you sure you want to reinstall the systemd services? (y/n): " REINSTALL_SYSTEMD_SERVICES
		if [[ "$REINSTALL_SYSTEMD_SERVICES" =~ ^([yY][eE][sS]|[yY])$ ]]; then
			INSTALL_SYSTEMD_SERVICES_STATE="1"
		elif [[ "$REINSTALL_SYSTEMD_SERVICES" =~ ^([nN][oO]|[nN])$ ]]; then
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Reinstall systemd services) Systemd services reinstallation aborted." | tee -a "$LOG_SCRIPT"
			INSTALL_SYSTEMD_SERVICES_STATE="0"
		fi
	else
		INSTALL_SYSTEMD_SERVICES_STATE="1"
	fi
	
	if [[ "$INSTALL_SYSTEMD_SERVICES_STATE" == "1" ]]; then
		if [ ! -d "/home/$USER/.config/systemd/user" ]; then
			mkdir -p /home/$USER/.config/systemd/user
		fi
		
		if [ -f "/home/$USER/.config/systemd/user/$SERVICE_NAME.service" ]; then
			rm /home/$USER/.config/systemd/user/$SERVICE_NAME.service
		fi
		
		if [ -f "/home/$USER/.config/systemd/user/$SERVICE_NAME-timer-1.timer" ]; then
			rm /home/$USER/.config/systemd/user/$SERVICE_NAME-timer-1.timer
		fi
		
		if [ -f "/home/$USER/.config/systemd/user/$SERVICE_NAME-timer-1.service" ]; then
			rm /home/$USER/.config/systemd/user/$SERVICE_NAME-timer-1.service
		fi
		
		if [ -f "/home/$USER/.config/systemd/user/$SERVICE_NAME-timer-2.timer" ]; then
			rm /home/$USER/.config/systemd/user/$SERVICE_NAME-timer-2.timer
		fi
		
		if [ -f "/home/$USER/.config/systemd/user/$SERVICE_NAME-timer-2.service" ]; then
			rm /home/$USER/.config/systemd/user/$SERVICE_NAME-timer-2.service
		fi
		
		if [ -f "/home/$USER/.config/systemd/user/$SERVICE_NAME-send-notification.service" ]; then
			rm /home/$USER/.config/systemd/user/$SERVICE_NAME-send-notification.service
		fi
		
		cat > /home/$USER/.config/systemd/user/$SERVICE_NAME.service <<- EOF
		[Unit]
		Description=$NAME Server Service
		After=network.target
		StartLimitBurst=3
		StartLimitIntervalSec=300
		StartLimitAction=none
		OnFailure=$SERVICE_NAME-send-notification.service
		
		[Service]
		Type=forking
		WorkingDirectory=$SRV_DIR/
		ExecStartPre=$SCRIPT_DIR/$SCRIPT_NAME -server_tmux_install
		ExecStartPre=$SCRIPT_DIR/$SCRIPT_NAME -send_notification_start_initialized
		ExecStart=/usr/bin/tmux -f /tmp/%u-$SERVICE_NAME-tmux.conf -L %u-tmux.sock new-session -d -s $NAME '$SRV_DIR/arma3server -name=$NAME -config=server.cfg -mod="$(find $SRV_DIR/ -maxdepth 1 -name "*@*" -printf '%f;')"'
		ExecStartPost=$SCRIPT_DIR/$SCRIPT_NAME -send_notification_start_complete
		ExecStop=$SCRIPT_DIR/$SCRIPT_NAME -send_notification_stop_initialized
		ExecStop=/usr/bin/tmux -L %u-tmux.sock send-keys -t $NAME.0 C-c
		ExecStop=/usr/bin/sleep 10
		ExecStopPost=/usr/bin/rm /tmp/%u-$SERVICE_NAME-tmux.conf
		ExecStopPost=$SCRIPT_DIR/$SCRIPT_NAME -send_notification_stop_complete
		TimeoutStartSec=infinity
		TimeoutStopSec=120
		RestartSec=10
		Restart=on-failure
		
		[Install]
		WantedBy=default.target
		EOF
		
		cat > /home/$USER/.config/systemd/user/$SERVICE_NAME-timer-1.timer <<- EOF
		[Unit]
		Description=$NAME Script Timer 1
		
		[Timer]
		OnCalendar=*-*-* 00:00:00
		OnCalendar=*-*-* 06:00:00
		OnCalendar=*-*-* 12:00:00
		OnCalendar=*-*-* 18:00:00
		Persistent=true
		
		[Install]
		WantedBy=timers.target
		EOF
		
		cat > /home/$USER/.config/systemd/user/$SERVICE_NAME-timer-1.service <<- EOF
		[Unit]
		Description=$NAME Script Timer 1 Service
		
		[Service]
		Type=oneshot
		ExecStart=$SCRIPT_DIR/$SCRIPT_NAME -timer_one
		EOF
		
		cat > /home/$USER/.config/systemd/user/$SERVICE_NAME-timer-2.timer <<- EOF
		[Unit]
		Description=$NAME Script Timer 2
		
		[Timer]
		OnCalendar=*-*-* *:15:00
		OnCalendar=*-*-* *:30:00
		OnCalendar=*-*-* *:45:00
		OnCalendar=*-*-* 01:00:00
		OnCalendar=*-*-* 02:00:00
		OnCalendar=*-*-* 03:00:00
		OnCalendar=*-*-* 04:00:00
		OnCalendar=*-*-* 05:00:00
		OnCalendar=*-*-* 07:00:00
		OnCalendar=*-*-* 08:00:00
		OnCalendar=*-*-* 09:00:00
		OnCalendar=*-*-* 10:00:00
		OnCalendar=*-*-* 11:00:00
		OnCalendar=*-*-* 13:00:00
		OnCalendar=*-*-* 14:00:00
		OnCalendar=*-*-* 15:00:00
		OnCalendar=*-*-* 16:00:00
		OnCalendar=*-*-* 17:00:00
		OnCalendar=*-*-* 19:00:00
		OnCalendar=*-*-* 20:00:00
		OnCalendar=*-*-* 21:00:00
		OnCalendar=*-*-* 22:00:00
		OnCalendar=*-*-* 23:00:00
		Persistent=true
		
		[Install]
		WantedBy=timers.target
		EOF
		
		cat > /home/$USER/.config/systemd/user/$SERVICE_NAME-timer-2.service <<- EOF
		[Unit]
		Description=$NAME Script Timer 2 Service
		
		[Service]
		Type=oneshot
		ExecStart=$SCRIPT_DIR/$SCRIPT_NAME -timer_two
		EOF
		
		cat > /home/$USER/.config/systemd/user/$SERVICE_NAME-send-notification.service <<- EOF
		[Unit]
		Description=$NAME Script Send Email notification Service
		
		[Service]
		Type=oneshot
		ExecStart=$SCRIPT_DIR/$SCRIPT_NAME -send_notification_crash
		EOF
	fi
	
	if [ "$EUID" -ne "0" ]; then
		if [[ "$INSTALL_SYSTEMD_SERVICES_STATE" == "1" ]]; then
			systemctl --user daemon-reload
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Reinstall systemd services) Systemd services reinstallation complete." | tee -a "$LOG_SCRIPT"
		fi
	fi
}

#Check github for script updates and update if newer version available
script_update_github() {
	script_logs
	if [[ "$SCRIPT_UPDATES_GITHUB" == "1" ]]; then
		GITHUB_VERSION=$(curl -s https://raw.githubusercontent.com/7thCore/$SERVICE_NAME-script/master/$SERVICE_NAME-script.bash | grep "^export VERSION=" | sed 's/"//g' | cut -d = -f2)
		if [ "$GITHUB_VERSION" -gt "$VERSION" ]; then
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Script update) Script update detected." | tee -a $LOG_SCRIPT
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Script update) Installed:$VERSION, Available:$GITHUB_VERSION" | tee -a $LOG_SCRIPT
			
			if [[ "$DISCORD_UPDATE_SCRIPT" == "1" ]]; then
				while IFS="" read -r DISCORD_WEBHOOK || [ -n "$DISCORD_WEBHOOK" ]; do
					curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Script update) Update detected. Installing update.\"}" "$DISCORD_WEBHOOK"
				done < $SCRIPT_DIR/discord_webhooks.txt
			fi
			
			git clone https://github.com/7thCore/$SERVICE_NAME-script /$UPDATE_DIR/$SERVICE_NAME-script
			rm $SCRIPT_DIR/$SERVICE_NAME-script.bash
			cp --remove-destination $UPDATE_DIR/$SERVICE_NAME-script/$SERVICE_NAME-script.bash $SCRIPT_DIR/$SERVICE_NAME-script.bash
			chmod +x $SCRIPT_DIR/$SERVICE_NAME-script.bash
			rm -rf $UPDATE_DIR/$SERVICE_NAME-script
			
			if [[ "$EMAIL_UPDATE_SCRIPT" == "1" ]]; then
				mail -r "$EMAIL_SENDER ($NAME-$USER)" -s "Notification: Script Update" $EMAIL_RECIPIENT <<- EOF
				Script was updated. Please check the update notes if there are any additional steps to take.
				Previous version: $VERSION
				Current version: $GITHUB_VERSION
				EOF
			fi
			
			if [[ "$DISCORD_UPDATE_SCRIPT" == "1" ]]; then
				while IFS="" read -r DISCORD_WEBHOOK || [ -n "$DISCORD_WEBHOOK" ]; do
					curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Script update) Update complete. Installed version: $GITHUB_VERSION.\"}" "$DISCORD_WEBHOOK"
				done < $SCRIPT_DIR/discord_webhooks.txt
			fi
		else
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Script update) No new script updates detected." | tee -a $LOG_SCRIPT
			echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Script update) Installed:$VERSION, Available:$VERSION" | tee -a $LOG_SCRIPT
		fi
	fi
}

#Get latest script from github no matter what the version
script_update_github_force() {
	script_logs
	GITHUB_VERSION=$(curl -s https://raw.githubusercontent.com/7thCore/$SERVICE_NAME-script/master/$SERVICE_NAME-script.bash | grep "^export VERSION=" | sed 's/"//g' | cut -d = -f2)
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Script update) Forcing script update." | tee -a $LOG_SCRIPT
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Script update) Installed:$VERSION, Available:$GITHUB_VERSION" | tee -a $LOG_SCRIPT
	git clone https://github.com/7thCore/$SERVICE_NAME-script /$UPDATE_DIR/$SERVICE_NAME-script
	rm $SCRIPT_DIR/$SERVICE_NAME-script.bash
	cp --remove-destination $UPDATE_DIR/$SERVICE_NAME-script/$SERVICE_NAME-script.bash $SCRIPT_DIR/$SERVICE_NAME-script.bash
	chmod +x $SCRIPT_DIR/$SERVICE_NAME-script.bash
	rm -rf $UPDATE_DIR/$SERVICE_NAME-script
	echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Script update) Forced script update complete." | tee -a $LOG_SCRIPT
}

#First timer function for systemd timers to execute parts of the script in order without interfering with each other
script_timer_one() {
	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "inactive" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Status) Server is not running." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "failed" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Status) Server is in failed state. Please check logs." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "activating" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Status) Server is activating. Please wait." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "deactivating" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Status) Server is in deactivating. Please wait." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Status) Server running." | tee -a "$LOG_SCRIPT"
		script_remove_old_files
		script_autobackup
		if [[ "$STEAMCMDUID" != "disabled" ]] && [[ "$STEAMCMDPSW" != "disabled" ]]; then
			script_update
			script_update_mods
		fi
		script_update_github
	fi
}

#Second timer function for systemd timers to execute parts of the script in order without interfering with each other
script_timer_two() {
	if [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "inactive" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Status) Server is not running." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "failed" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Status) Server is in failed state. Please check logs." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "activating" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Status) Server is activating. Please wait." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "deactivating" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Status) Server is in deactivating. Please wait." | tee -a "$LOG_SCRIPT"
	elif [[ "$(systemctl --user show -p ActiveState --value $SERVICE)" == "active" ]]; then
		echo "$(date +"%Y-%m-%d %H:%M:%S") [$VERSION] [$NAME] [INFO] (Status) Server running." | tee -a "$LOG_SCRIPT"
		script_remove_old_files
		if [[ "$STEAMCMDUID" != "disabled" ]] && [[ "$STEAMCMDPSW" != "disabled" ]]; then
			script_update
			script_update_mods
		fi
		script_update_github
	fi
}

script_diagnostics() {
	echo "Initializing diagnostics. Please wait..."
	sleep 3
	
	#Check package versions
	echo "wine version: $(wine --version)"
	echo "winetricks version: $(winetricks --version)"
	echo "tmux version: $(tmux -V)"
	echo "rsync version: $(rsync --version | head -n 1)"
	echo "curl version: $(curl --version | head -n 1)"
	echo "wget version: $(wget --version | head -n 1)"
	echo "cabextract version: $(cabextract --version)"
	echo "postfix version: $(postconf mail_version)"
	
	#Get distro name
	DISTRO=$(cat /etc/os-release | grep "^ID=" | cut -d = -f2)
	
	#Check package versions
	if [[ "$DISTRO" == "arch" ]]; then
		echo "xvfb version:$(pacman -Qi xorg-server-xvfb | grep "^Version" | cut -d : -f2)"
		echo "postfix version:$(pacman -Qi postfix | grep "^Version" | cut -d : -f2)"
		echo "zip version:$(pacman -Qi zip | grep "^Version" | cut -d : -f2)"
	elif [[ "$DISTRO" == "ubuntu" ]]; then
		echo "xvfb version:$(dpkg -s xvfb | grep "^Version" | cut -d : -f2)"
		echo "postfix version:$(dpkg -s postfix | grep "^Version" | cut -d : -f2)"
		echo "zip version:$(dpkg -s zip | grep "^Version" | cut -d : -f2)"
	fi
	
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
	
	if [ -d "/home/$USER/backups" ]; then
		echo "Backups folder present: Yes"
	else
		echo "Backups folder present: No"
	fi
	
	if [ -d "/home/$USER/logs" ]; then
		echo "Logs folder present: Yes"
	else
		echo "Logs folder present: No"
	fi
	
	if [ -d "/home/$USER/scripts" ]; then
		echo "Scripts folder present: Yes"
	else
		echo "Scripts folder present: No"
	fi
	
	if [ -d "/home/$USER/server" ]; then
		echo "Server folder present: Yes"
	else
		echo "Server folder present: No"
	fi
	
	if [ -d "/home/$USER/updates" ]; then
		echo "Updates folder present: Yes"
	else
		echo "Updates folder present: No"
	fi
	
	if [ -f "/home/$USER/.config/systemd/user/$SERVICE_NAME.service" ]; then
		echo "Basic service present: Yes"
	else
		echo "Basic service present: No"
	fi
	
	if [ -f "/home/$USER/.config/systemd/user/$SERVICE_NAME-timer-1.timer" ]; then
		echo "Timer 1 timer present: Yes"
	else
		echo "Timer 1 timer present: No"
	fi
	
	if [ -f "/home/$USER/.config/systemd/user/$SERVICE_NAME-timer-1.service" ]; then
		echo "Timer 1 service present: Yes"
	else
		echo "Timer 1 service present: No"
	fi
	
	if [ -f "/home/$USER/.config/systemd/user/$SERVICE_NAME-timer-2.timer" ]; then
		echo "Timer 2 timer present: Yes"
	else
		echo "Timer 2 timer present: No"
	fi
	
	if [ -f "/home/$USER/.config/systemd/user/$SERVICE_NAME-timer-2.service" ]; then
		echo "Timer 2 service present: Yes"
	else
		echo "Timer 2 service present: No"
	fi
	
	if [ -f "/home/$USER/.config/systemd/user/$SERVICE_NAME-send-notification.service" ]; then
		echo "Notification sending service present: Yes"
	else
		echo "Notification sending service present: No"
	fi
	
	echo "Diagnostics complete."
}

script_install_packages() {
	if [ -f "/etc/os-release" ]; then
		#Get distro name
		DISTRO=$(cat /etc/os-release | grep "^ID=" | cut -d = -f2)
		
		#Check for current distro
		if [[ "$DISTRO" == "arch" ]]; then
			#Arch distro
			
			#Add arch linux multilib repository
			echo "[multilib]" >> /etc/pacman.conf
			echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
			
			#Install packages and enable services
			sudo pacman -Syu --noconfirm rsync unzip p7zip wget curl tmux postfix zip jq
		elif [[ "$DISTRO" == "ubuntu" ]]; then
			#Ubuntu distro
			
			#Get codename
			UBUNTU_CODENAME=$(cat /etc/os-release | grep "^UBUNTU_CODENAME=" | cut -d = -f2)
			
			if [[ "$UBUNTU_CODENAME" == "bionic" || "$UBUNTU_CODENAME" == "eoan" || "$UBUNTU_CODENAME" == "focal" || "$UBUNTU_CODENAME" == "groovy" ]]; then
				#Add i386 architecture support
				apt install --yes sudo gnupg
				sudo dpkg --add-architecture i386
				
				#Install software properties common
				sudo apt install --yes software-properties-common
				
				#Check codename and install config for installation
				if [[ "$UBUNTU_CODENAME" == "bionic" ]]; then
					cat >> /etc/apt/sources.list <<- EOF
					#### ubuntu eoan #########
					deb http://archive.ubuntu.com/ubuntu eoan main restricted universe multiverse
					EOF
					
					cat > /etc/apt/preferences.d/eoan.pref <<- EOF
					Package: *
					Pin: release n=$UBUNTU_CODENAME
					Pin-Priority: 10
					
					Package: tmux
					Pin: release n=eoan
					Pin-Priority: 900
					EOF
				fi
				
				#Check for updates and update local repo database
				sudo apt update
				
				#Install packages and enable services
				sudo apt install --yes --install-recommends -y steamcmd
				sudo apt install --yes rsync unzip p7zip wget curl tmux postfix zip jq
			else
				echo "Error: This version of Ubuntu is not supported. Supported versions are: Ubuntu 18.04 LTS (Bionic Beaver), Ubuntu 19.10 (Disco Dingo), Ubuntu 20.04 LTS (Focal Fossa), Ubuntu 20.10 (Groovy Gorilla)"
				echo "Exiting"
				exit 1
			fi
		elif [[ "$DISTRO" == "debian" ]]; then
			#Debian distro
			
			#Get codename
			DEBIAN_CODENAME=$(cat /etc/os-release | grep "^VERSION_CODENAME=" | cut -d = -f2)
			
			if [[ "$DEBIAN_CODENAME" == "buster" ]]; then
				#Add i386 architecture support
				apt install --yes sudo gnupg
				sudo dpkg --add-architecture i386
				
				#Install software properties common
				sudo apt install --yes software-properties-common
				
				#Add non-free repo for steamcmd
				sudo apt-add-repository non-free
				
				#Check codename and install backport repo if needed
				if [[ "$DEBIAN_CODENAME" == "buster" ]]; then
					sudo apt-add-repository "deb http://deb.debian.org/debian $DEBIAN_CODENAME-backports main"
					sudo apt update
					sudo apt -t buster-backports install --yes "tmux"
				fi
				
				#Check for updates and update local repo database
				sudo apt update
				
				#Install packages and enable services
				sudo apt install --yes --install-recommends -y steamcmd
				sudo apt install --yes rsync unzip p7zip wget curl tmux postfix zip jq
			else
				echo "Error: This version of Debian is not supported. Supported versions are: Debian 10 (Buster)"
				echo "Exiting"
				exit 1
			fi
		else
			echo "Error: This distro is not supported. This script currently supports Arch Linux, Ubuntu 18.04 LTS (Bionic Beaver), Ubuntu 19.10 (Disco Dingo), Ubuntu 20.04 LTS (Focal Fossa), Debian 10 (Buster). If you want to try the script on your distro, install the packages manually. Check the readme for required package versions."
			echo "Exiting"
			exit 1
		fi
		
		if [[ "$DISTRO" == "arch" ]]; then
			echo "Arch Linux users have to install SteamCMD with an AUR tool or manually download it."
		fi
		echo "Package installation complete."
	else
		echo "os-release file not found. Is this distro supported?"
		echo "This script currently supports Arch Linux,  Ubuntu 18.04 LTS (Bionic Beaver), Ubuntu 19.10 (Disco Dingo), Ubuntu 20.04 LTS (Focal Fossa), Ubuntu 20.10 (Groovy Gorilla), Debian 10 (Buster)"
		exit 1
	fi
}

script_install() {
	echo "Installation"
	echo ""
	echo "Required packages that need to be installed on the server:"
	echo "tmux (minimum version: 2.9a)"
	echo "steamcmd"
	echo "postfix (optional/for the email feature)"
	echo "zip (optional but required if using the email feature)"
	echo ""
	echo "If these packages aren't installed, terminate this script with CTRL+C and install them."
	echo "The script will ask you for your steam username and password and will store it in a configuration file for automatic updates."
	echo "In the middle of the installation process you will be asked for a steam guard code. Also make sure your steam guard"
	echo "is set to email only (don't use the mobile app and don't use no second authentication. USE STEAM GUARD VIA EMAIL!"
	echo ""
	echo "The installation will enable linger for the user specified (allows user services to be ran on boot)."
	echo "It will also enable the services needed to run the game server by your specifications."
	echo ""
	echo "List of files that are going to be generated on the system:"
	echo ""
	echo "/home/$USER/.config/systemd/user/$SERVICE_NAME.service - Server service file for normal hdd/ssd use."
	echo "/home/$USER/.config/systemd/user/$SERVICE_NAME-timer-1.timer - Timer for scheduled command execution of $SERVICE_NAME-timer-1.service"
	echo "/home/$USER/.config/systemd/user/$SERVICE_NAME-timer-1.service - Executes scheduled script functions: autorestart, save, backup and update."
	echo "/home/$USER/.config/systemd/user/$SERVICE_NAME-timer-2.timer - Timer for scheduled command execution of $SERVICE_NAME-timer-2.service"
	echo "/home/$USER/.config/systemd/user/$SERVICE_NAME-timer-2.service - Executes scheduled script functions: autorestart, save and update."
	echo "/home/$USER/.config/systemd/user/$SERVICE_NAME-send-notification.service - If email notifications enabled, send email if server crashed 3 times in 5 minutes."
	echo "$SCRIPT_DIR/$SERVICE_NAME-script.bash - This script."
	echo "$SCRIPT_DIR/$SERVICE_NAME-config.conf - Stores settings for the script."
	echo "$SCRIPT_DIR/$SERVICE_NAME-tmux.conf - Tmux configuration to enable logging."
	echo "$UPDATE_DIR/installed.buildid - Information on installed buildid (AppInfo from Steamcmd)"
	echo "$UPDATE_DIR/available.buildid - Information on available buildid (AppInfo from Steamcmd)"
	echo "$UPDATE_DIR/installed.timeupdated - Information on time the server was last updated (AppInfo from Steamcmd)"
	echo "$UPDATE_DIR/available.timeupdated - Information on time the server was last updated (AppInfo from Steamcmd)"
	echo ""
	read -p "Press any key to continue" -n 1 -s -r
	echo ""
	read -p "Enter password for user $USER: " USER_PASS
	echo ""
	sudo useradd -m -g users -s /bin/bash $USER
	echo -en "$USER_PASS\n$USER_PASS\n" | sudo passwd $USER
	
	sudo chown -R "$USER":users "/home/$USER"
	
	echo ""
	echo "You will now have to enter your Steam credentials. Exepct a prompt for a Steam guard code if you have it enabled."
	echo ""
	while [[ "$STEAMCMDSUCCESS" != "0" ]]; do
		read -p "Enter your Steam username: " STEAMCMDUID
		echo ""
		read -p "Enter your Steam password: " STEAMCMDPSW
		su - $USER -c "steamcmd +login $STEAMCMDUID $STEAMCMDPSW +quit"
		STEAMCMDSUCCESS=$?
		if [[ "$STEAMCMDSUCCESS" == "0" ]]; then
			echo "Steam login for $STEAMCMDUID: SUCCEDED!"
		elif [[ "$STEAMCMDSUCCESS" != "0" ]]; then
			echo "Steam login for $STEAMCMDUID: FAILED!"
			echo "Please try again."
		fi
	done
	
	echo ""
	read -p "Do you want the script to store your Steam credentials in the script's config file for automatic updates? (y/n)" STEAM_STORE_CREDENTIALS_SETUP
	STEAM_STORE_CREDENTIALS_SETUP=${STEAM_STORE_CREDENTIALS_SETUP:=n}
	if [[ "$STEAM_STORE_CREDENTIALS_SETUP" =~ ^([nN][oO]|[nN])$ ]]; then
		echo "Your Steam credentials WILL NOT be stored on this system. You will have to update your game manually when an update is released."
		STEAM_STORE_CREDENTIALS="0"
	else
		echo "Your Steam credentials WILL be stored on this system. Updates will be installed automaticly when an update is released."
		STEAM_STORE_CREDENTIALS="1"
	fi
	
	echo ""
	read -p "Enable beta branch? Used for experimental and legacy versions. (y/n): " SET_BETA_BRANCH_STATE
	echo ""
	
	if [[ "$SET_BETA_BRANCH_STATE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		BETA_BRANCH_ENABLED="1"
		echo "Look up beta branch names at https://steamdb.info/app/$APPID/depots/"
		echo "Name example: experimental"
		read -p "Enter beta branch name: " BETA_BRANCH_NAME
	elif [[ "$SET_BETA_BRANCH_STATE" =~ ^([nN][oO]|[nN])$ ]]; then
		BETA_BRANCH_ENABLED="0"
		BETA_BRANCH_NAME="none"
	fi
	
	echo ""
	read -p "Enable automatic updates for the script from github? Read warning in readme! (y/n): " SCRIPT_UPDATE_CONFIG
	SCRIPT_UPDATE_CONFIG=${SCRIPT_UPDATE_CONFIG:=n}
	if [[ "$SCRIPT_UPDATE_CONFIG" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		SCRIPT_UPDATE_ENABLED="1"
	else
		SCRIPT_UPDATE_ENABLED="0"
	fi
	
	echo ""
	read -p "Enable email notifications (y/n): " POSTFIX_ENABLE
	if [[ "$POSTFIX_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		read -p "Is postfix already configured? (y/n): " POSTFIX_CONFIGURED
		echo ""
		read -p "Enter your email address for the server (example: example@gmail.com): " POSTFIX_SENDER
		echo ""
		if [[ "$POSTFIX_CONFIGURED" =~ ^([nN][oO]|[nN])$ ]]; then
			read -p "Enter your password for $POSTFIX_SENDER : " POSTFIX_SENDER_PSW
		fi
		echo ""
		read -p "Enter the email that will recieve the notifications (example: example2@gmail.com): " POSTFIX_RECIPIENT
		echo ""
		read -p "Email notifications for game updates? (y/n): " POSTFIX_UPDATE_ENABLE
			if [[ "$POSTFIX_UPDATE_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				POSTFIX_UPDATE="1"
			else
				POSTFIX_UPDATE="0"
			fi
		echo ""
		read -p "Email notifications for script updates from github? (y/n): " POSTFIX_UPDATE_SCRIPT_ENABLE
			if [[ "$POSTFIX_UPDATE_SCRIPT_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				POSTFIX_UPDATE_SCRIPT="1"
			else
				POSTFIX_UPDATE_SCRIPT="0"
			fi
		echo ""
		read -p "Email notifications for mod updates? (y/n): " POSTFIX_UPDATE_MOD_ENABLE
			if [[ "$POSTFIX_UPDATE_MOD_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				POSTFIX_UPDATE_MOD="1"
			else
				POSTFIX_UPDATE_MOD="0"
			fi
		echo ""
		read -p "Email notifications for server startup? (WARNING: this can be anoying) (y/n): " POSTFIX_CRASH_ENABLE
			if [[ "$POSTFIX_CRASH_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				POSTFIX_START="1"
			else
				POSTFIX_START="0"
			fi
		echo ""
		read -p "Email notifications for server shutdown? (WARNING: this can be anoying) (y/n): " POSTFIX_CRASH_ENABLE
			if [[ "$POSTFIX_CRASH_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				POSTFIX_STOP="1"
			else
				POSTFIX_STOP="0"
			fi
		echo ""
		read -p "Email notifications for crashes? (y/n): " POSTFIX_CRASH_ENABLE
			if [[ "$POSTFIX_CRASH_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				POSTFIX_CRASH="1"
			else
				POSTFIX_CRASH="0"
			fi
		if [[ "$POSTFIX_CONFIGURED" =~ ^([nN][oO]|[nN])$ ]]; then
			echo ""
			read -p "Enter the relay host (example: smtp.gmail.com): " POSTFIX_RELAY_HOST
			echo ""
			read -p "Enter the relay host port (example: 587): " POSTFIX_RELAY_HOST_PORT
			echo ""
			cat >> /etc/postfix/main.cf <<- EOF
			relayhost = [$POSTFIX_RELAY_HOST]:$POSTFIX_RELAY_HOST_PORT
			smtp_sasl_auth_enable = yes
			smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
			smtp_sasl_security_options = noanonymous
			smtp_tls_CApath = /etc/ssl/certs
			smtpd_tls_CApath = /etc/ssl/certs
			smtp_use_tls = yes
			EOF

			cat > /etc/postfix/sasl_passwd <<- EOF
			[$POSTFIX_RELAY_HOST]:$POSTFIX_RELAY_HOST_PORT    $POSTFIX_SENDER:$POSTFIX_SENDER_PSW
			EOF

			sudo chmod 400 /etc/postfix/sasl_passwd
			sudo postmap /etc/postfix/sasl_passwd
			sudo systemctl enable postfix
		fi
	elif [[ "$POSTFIX_ENABLE" =~ ^([nN][oO]|[nN])$ ]]; then
		POSTFIX_SENDER="none"
		POSTFIX_RECIPIENT="none"
		POSTFIX_UPDATE="0"
		POSTFIX_UPDATE_SCRIPT="0"
		POSTFIX_UPDATE_MOD="0"
		POSTFIX_START="0"
		POSTFIX_STOP="0"
		POSTFIX_CRASH="0"
	fi
	
	echo ""
	read -p "Enable discord notifications (y/n): " DISCORD_ENABLE
	if [[ "$DISCORD_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		echo ""
		echo "You are able to add multiple webhooks for the script to use in the discord_webhooks.txt file located in the scripts folder."
		echo "EACH ONE HAS TO BE IN IT'S OWN LINE!"
		echo ""
		read -p "Enter your first webhook for the server: " DISCORD_WEBHOOK
		if [[ "$DISCORD_WEBHOOK" == "" ]]; then
			DISCORD_WEBHOOK="none"
		fi
		echo ""
		read -p "Discord notifications for game updates? (y/n): " DISCORD_UPDATE_ENABLE
			if [[ "$DISCORD_UPDATE_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				DISCORD_UPDATE="1"
			else
				DISCORD_UPDATE="0"
			fi
		echo ""
		read -p "Discord notifications for game updates? (y/n): " DISCORD_UPDATE_SCRIPT_ENABLE
			if [[ "$DISCORD_UPDATE_SCRIPT_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				DISCORD_UPDATE_SCRIPT="1"
			else
				DISCORD_UPDATE_SCRIPT="0"
			fi
		echo ""
		read -p "Discord notifications for script updates from github? (y/n): " DISCORD_UPDATE_MOD_ENABLE
			if [[ "$DISCORD_UPDATE_MOD_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				DISCORD_UPDATE_MOD="1"
			else
				DISCORD_UPDATE_MOD="0"
			fi
		echo ""
		read -p "Discord notifications for server startup? (y/n): " DISCORD_START_ENABLE
			if [[ "$DISCORD_START_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				DISCORD_START="1"
			else
				DISCORD_START="0"
			fi
		echo ""
		read -p "Discord notifications for server shutdown? (y/n): " DISCORD_STOP_ENABLE
			if [[ "$DISCORD_STOP_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				DISCORD_STOP="1"
			else
				DISCORD_STOP="0"
			fi
		echo ""
		read -p "Discord notifications for crashes? (y/n): " DISCORD_CRASH_ENABLE
			if [[ "$DISCORD_CRASH_ENABLE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
				DISCORD_CRASH="1"
			else
				DISCORD_CRASH="0"
			fi
	elif [[ "$DISCORD_ENABLE" =~ ^([nN][oO]|[nN])$ ]]; then
		DISCORD_UPDATE="0"
		DISCORD_UPDATE_MOD="0"
		DISCORD_UPDATE_SCRIPT="0"
		DISCORD_START="0"
		DISCORD_STOP="0"
		DISCORD_CRASH="0"
	fi
	
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
			if [[ "$MODS_ANTISTASI_MODSET_INSTALL" =~ ^([yY][eE][sS]|[yY])$ ]]; then
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
	
	echo "Installing bash profile"
	cat > /home/$USER/.bash_profile <<- 'EOF'
	#
	# ~/.bash_profile
	#
	
	[[ -f ~/.bashrc ]] && . ~/.bashrc
	
	export XDG_RUNTIME_DIR="/run/user/$UID"
	export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
	EOF
	
	sudo chown $USER:users /home/$USER/.bash_profile
	
	echo "Installing service files"
	script_install_services
	
	sudo chown -R $USER:users /home/$USER/.config/systemd/user
	
	echo "Enabling linger"
	
	sudo loginctl enable-linger $USER
	
	if [ ! -f /var/lib/systemd/linger/$USER ]; then
		sudo mkdir -p /var/lib/systemd/linger/
		sudo touch /var/lib/systemd/linger/$USER
	fi
	
	echo "Enabling services"
		
	sudo systemctl start user@$(id -u $USER).service
	
	su - $USER -c "systemctl --user enable $SERVICE_NAME-timer-1.timer"
	su - $USER -c "systemctl --user enable $SERVICE_NAME-timer-2.timer"
	su - $USER -c "systemctl --user enable $SERVICE_NAME.service"
	
	echo "Creating folder structure for server..."
	mkdir -p /home/$USER/{backups,logs,scripts,server,updates}
	mkdir -p /home/$USER/updates/mods
	cp "$(readlink -f $0)" $SCRIPT_DIR
	chmod +x $SCRIPT_DIR/$SCRIPT_NAME
	
	touch $SCRIPT_DIR/$SERVICE_NAME-config.conf
	if [[ "$STEAM_STORE_CREDENTIALS" == "1" ]]; then
		echo 'username='"$STEAMCMDUID" > $SCRIPT_DIR/$SERVICE_NAME-config.conf
		echo 'password='"$STEAMCMDPSW" >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
	else
		echo 'username=disabled' > $SCRIPT_DIR/$SERVICE_NAME-config.conf
		echo 'password=disabled' >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
	fi
	echo 'beta_branch_enabled='"$BETA_BRANCH_ENABLED" >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
	echo 'beta_branch_name='"$BETA_BRANCH_NAME" >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
	echo 'email_sender='"$POSTFIX_SENDER" >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
	echo 'email_recipient='"$POSTFIX_RECIPIENT" >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
	echo 'email_update='"$POSTFIX_UPDATE" >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
	echo 'email_update_script='"$POSTFIX_UPDATE_SCRIPT" >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
	echo 'email_update_mod='"$POSTFIX_UPDATE_MOD" >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
	echo 'email_start='"$POSTFIX_START" >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
	echo 'email_stop='"$POSTFIX_STOP" >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
	echo 'email_crash='"$POSTFIX_CRASH" >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
	echo 'discord_update='"$DISCORD_UPDATE" >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
	echo 'discord_update_script='"$DISCORD_UPDATE_SCRIPT" >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
	echo 'discord_update_mod='"$DISCORD_UPDATE" >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
	echo 'discord_start='"$DISCORD_START" >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
	echo 'discord_stop='"$DISCORD_STOP" >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
	echo 'discord_crash='"$DISCORD_CRASH" >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
	echo 'mods_enabled='"$MODS_ENABLED_SETUP" >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
	echo 'mod_list='"$MOD_LIST_SETUP" >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
	echo 'script_updates='"$SCRIPT_UPDATE_ENABLED" >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
	echo 'bckp_delold=14' >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
	echo 'log_delold=7' >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
	
	echo "$DISCORD_WEBHOOK" > $SCRIPT_DIR/discord_webhooks.txt
	
	if [[ "$MODS_ANTISTASI_INSTALL" == "1" ]]; then
		echo $MODS_ANTISTASI_VERSION > $UPDATE_DIR/installed_antistasi.version
	fi
	
	sudo chown -R "$USER":users "/home/$USER"
	
	echo "Updating and logging in to Steam..."
	
	su - $USER -c "steamcmd +login $STEAMCMDUID $STEAMCMDPSW +quit"
	
	echo "Installing game..."
	
	if [[ "$BETA_BRANCH_ENABLED" == "0" ]]; then
		su - $USER <<- EOF
		steamcmd +login $STEAMCMDUID $STEAMCMDPSW +app_info_update 1 +app_info_print $APPID +quit | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"public\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"buildid\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3 > $UPDATE_DIR/installed.buildid
		EOF
	
		su - $USER <<- EOF
		steamcmd +login $STEAMCMDUID $STEAMCMDPSW +app_info_update 1 +app_info_print $APPID +quit | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"public\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"timeupdated\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3 > $UPDATE_DIR/installed.timeupdated
		EOF
		
		su - $USER -c "steamcmd +login $STEAMCMDUID $STEAMCMDPSW +force_install_dir $SRV_DIR/ +app_update $APPID validate +quit"
	elif [[ "$BETA_BRANCH_ENABLED" == "1" ]]; then
		su - $USER <<- EOF
		steamcmd +login $STEAMCMDUID $STEAMCMDPSW +app_info_update 1 +app_info_print $APPID +quit | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"$BETA_BRANCH_NAME\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"buildid\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3 > $UPDATE_DIR/installed.buildid
		EOF
	
		su - $USER <<- EOF
		steamcmd +login $STEAMCMDUID $STEAMCMDPSW +app_info_update 1 +app_info_print $APPID +quit | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"$BETA_BRANCH_NAME\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"timeupdated\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3 > $UPDATE_DIR/installed.timeupdated
		EOF
		
		su - $USER -c "steamcmd +login $STEAMCMDUID $STEAMCMDPSW +force_install_dir $SRV_DIR/ +app_update $APPID -beta $BETA_BRANCH_NAME validate +quit"
	fi
		
	if [[ "$MODS_INSTALL" == "1" ]]; then
		IFS=","
		for MOD_NAME_ID in $MOD_LIST_INSTALL; do
			echo "SteamCmd is updating mod $MOD_NAME_ID"
			MOD_ID=$(echo $MOD_NAME_ID | cut -d - -f2)
			MOD_NAME=$(echo $MOD_NAME_ID | cut -d - -f1)
			AVAILABLE_DATE_MOD=$(curl -s https://steamcommunity.com/sharedfiles/filedetails/changelog/$MOD_ID | grep "Update:" | head -n1 | awk -F 'Update: ' '{print $2}' | tr -d '\t' | awk -F '</div>' '{print $1}' | awk -F ' @ ' '{print $1}')
			AVAILABLE_TIME_MOD=$(curl -s https://steamcommunity.com/sharedfiles/filedetails/changelog/$MOD_ID | grep "Update:" | head -n1 | awk -F 'Update: ' '{print $2}' | tr -d '\t' | awk -F '</div>' '{print $1}' | awk -F ' @ ' '{print $2}')
			AVAILABLE_VERSION_MOD=$(date --date="$(printf "%s" $AVAILABLE_DATE_MOD)" +"%Y%m%d")$(date --date="$(printf "%s" $AVAILABLE_TIME_MOD)" +"%H%M")
			while [[ "$STEAMCMDSUCCESSMODS" != "0" ]]; do
				su - $USER -c "steamcmd +login $STEAMCMDUID $STEAMCMDPSW +force_install_dir $SRV_DIR/ +workshop_download_item $WORKSHOP_APPID $MOD_ID +quit"
				STEAMCMDSUCCESSMODS=$?
				if [[ "$STEAMCMDSUCCESSMODS" == "0" ]]; then
					echo "Download of mod $MOD_NAME_ID: SUCCEDED!"
				elif [[ "$STEAMCMDSUCCESSMODS" != "0" ]]; then
					echo "Download of mod $MOD_NAME_ID: FAILED!"
					echo "Retrying...."
				fi
			done
			su - $USER -c "ln -s $SRV_DIR/steamapps/workshop/content/$WORKSHOP_APPID/$MOD_ID /home/$USER/server/@$MOD_NAME"
			echo "$AVAILABLE_VERSION_MOD" > $UPDATE_DIR/mods/$MOD_NAME.mod_version
		done
		find -L /home/$USER/server/@* -name "*.bikey" -exec cp {} /home/$USER/server/keys/ \;
	fi
	
	mkdir -p "/home/$USER/.local/share/Arma 3"
	mkdir -p "/home/$USER/.local/share/Arma 3 - Other Profiles/$NAME"
	mv "$PWD/mission_pbo/$MISSION_PBO.pbo" "$SRV_DIR/mpmissions/"
	rm -rf "$PWD/mission_pbo"

	cat > /home/$USER/server/server.cfg << EOF
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
	
	cat > "/home/$USER/.local/share/Arma 3 - Other Profiles/$NAME/$NAME.Arma3Profile" << EOF
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
	
	sudo chown -R "$USER":users "/home/$USER"
	
	echo "Installation complete"
	echo ""
	echo "You can login to your the $USER account with <sudo -i -u $USER> from your primary account or root account."
	echo "The script was automaticly copied to the scripts folder located at $SCRIPT_DIR"
	echo "For any settings you'll want to change for the script, edit the $SCRIPT_DIR/$SERVICE_NAME-config.conf file."
	echo "Before running the server configure your server in $SRV_DIR/server.cfg"
	echo ""
}

#Do not allow for another instance of this script to run to prevent data loss
if [[ "-send_notification_start_initialized" != "$1" ]] && [[ "-send_notification_start_complete" != "$1" ]] && [[ "-send_notification_stop_initialized" != "$1" ]] && [[ "-send_notification_stop_complete" != "$1" ]] && [[ "-send_notification_crash" != "$1" ]] && [[ "-server_tmux_install" != "$1" ]] && [[ "-attach" != "$1" ]] && [[ "-status" != "$1" ]]; then
	SCRIPT_PID_CHECK=$(basename -- "$0")
	if pidof -x "$SCRIPT_PID_CHECK" -o $$ > /dev/null; then
		echo "An another instance of this script is already running, please clear all the sessions of this script before starting a new session"
		exit 1
	fi
fi

if [ "$EUID" -ne "0" ] && [ -f "$SCRIPT_DIR/$SERVICE_NAME-config.conf" ]; then #Check if script executed as root, if not generate missing config fields
	touch $SCRIPT_DIR/$SERVICE_NAME-config.conf
	CONFIG_FIELDS="username,password,tmpfs_enable,beta_branch_enabled,beta_branch_name,email_sender,email_recipient,email_update,email_update_script,email_update_mod,email_start,email_stop,email_crash,discord_update,discord_update_script,discord_update_mod,discord_start,discord_stop,discord_crash,mods_enabled,mod_list,script_updates,bckp_delold,log_delold,update_ignore_failed_startups"
	IFS=","
	for CONFIG_FIELD in $CONFIG_FIELDS; do
		if ! grep -q $CONFIG_FIELD $SCRIPT_DIR/$SERVICE_NAME-config.conf; then
			if [[ "$CONFIG_FIELD" == "bckp_delold" ]]; then
				echo "$CONFIG_FIELD=14" >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
			elif [[ "$CONFIG_FIELD" == "log_delold" ]]; then
				echo "$CONFIG_FIELD=7" >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
			else
				echo "$CONFIG_FIELD=0" >> $SCRIPT_DIR/$SERVICE_NAME-config.conf
			fi
		fi
	done
fi

case "$1" in
	-help)
		echo -e "${CYAN}Time: $(date +"%Y-%m-%d %H:%M:%S") ${NC}"
		echo -e "${CYAN}$NAME server script by 7thCore${NC}"
		echo "Version: $VERSION"
		echo ""
		echo -e "${GREEN}-diag ${RED}- ${GREEN}Prints out package versions and if script files are installed${NC}"
		echo -e "${GREEN}-start ${RED}- ${GREEN}Start the server${NC}"
		echo -e "${GREEN}-start_no_err ${RED}- ${GREEN}Start the server but don't require confimation if in failed state${NC}"
		echo -e "${GREEN}-stop ${RED}- ${GREEN}Stop the server${NC}"
		echo -e "${GREEN}-restart ${RED}- ${GREEN}Restart the server${NC}"
		echo -e "${GREEN}-backup ${RED}- ${GREEN}Backup files, if server running or not${NC}"
		echo -e "${GREEN}-autobackup ${RED}- ${GREEN}Automaticly backup files when server running${NC}"
		echo -e "${GREEN}-deloldbackup ${RED}- ${GREEN}Delete old backups${NC}"
		echo -e "${GREEN}-delete_save ${RED}- ${GREEN}Delete the server's save game with the option for deleting/keeping the server.cfg file${NC}"
		echo -e "${GREEN}-change_branch ${RED}- ${GREEN}Changes the game branch in use by the server (public,experimental,legacy and so on.${NC}"
		echo -e "${GREEN}-install_aliases ${RED}- ${GREEN}Installs .bashrc aliases for easy access to the server tmux session${NC}"
		echo -e "${GREEN}-rebuild_services ${RED}- ${GREEN}Reinstalls the systemd services from the script. Usefull if any service updates occoured${NC}"
		echo -e "${GREEN}-disable_services ${RED}- ${GREEN}Disables all services. The server and the script will not start up on boot anymore${NC}"
		echo -e "${GREEN}-enable_services ${RED}- ${GREEN}Enables all services dependant on the configuration file of the script${NC}"
		echo -e "${GREEN}-reload_services ${RED}- ${GREEN}Reloads all services, dependant on the configuration file${NC}"
		echo -e "${GREEN}-update ${RED}- ${GREEN}Update the server, if the server is running it will save it, shut it down, update it and restart it${NC}"
		echo -e "${GREEN}-verify ${RED}- ${GREEN}Verifiy game server files, if the server is running it will save it, shut it down, verify it and restart it${NC}"
		echo -e "${GREEN}-update_mods ${RED}- ${GREEN}Update the server mods, if the server is running it wil save it, shut it down, update it and restart it${NC}"
		echo -e "${GREEN}-update_script ${RED}- ${GREEN}Check github for script updates and update if newer version available${NC}"
		echo -e "${GREEN}-update_script_force ${RED}- ${GREEN}Get latest script from github and install it no matter what the version${NC}"
		echo -e "${GREEN}-status ${RED}- ${GREEN}Display status of server${NC}"
		echo -e "${GREEN}-install ${RED}- ${GREEN}Installs all the needed files for the script to run, the wine prefix and the game${NC}"
		echo -e "${GREEN}-install_packages ${RED}- ${GREEN}Installs all the needed packages (check supported distros)${NC}"
		echo ""
		echo -e "${LIGHTRED}If this is your first time running the script:${NC}"
		echo -e "${LIGHTRED}Use the -install argument (run only this command as root) and follow the instructions${NC}"
		echo ""
		echo -e "${LIGHTRED}Example usage: ./$SCRIPT_NAME -start${NC}"
		echo ""
		echo -e "${CYAN}Have a nice day!${NC}"
		echo ""
		;;
	-diag)
		script_diagnostics
		;;
	-start)
		script_start
		;;
	-start_no_err)
		script_start_ignore_errors $2
		;;
	-stop)
		script_stop
		;;
	-restart)
		script_restart
		;;
	-backup)
		script_backup
		;;
	-autobackup)
		script_autobackup
		;;
	-deloldbackup)
		script_deloldbackup
		;;
	-update)
		script_update
		;;
	-verify)
		script_verify_game_integrity
		;;
	-update_mods)
		script_update_mods
		;;
	-update_script)
		script_update_github
		;;
	-update_script_force)
		script_update_github_force
		;;
	-status)
		script_status
		;;
	-attach)
		script_attach
		;;
	-install_packages)
		script_install_packages
		;;
	-install)
		script_install
		;;
	-delete_save)
		script_delete_save
		;;
	-change_branch)
		script_change_branch
		;;
	-send_notification_start_initialized)
		script_send_notification_start_initialized
		;;
	-send_notification_start_complete)
		script_send_notification_start_complete
		;;
	-send_notification_stop_initialized)
		script_send_notification_stop_initialized
		;;
	-send_notification_stop_complete)
		script_send_notification_stop_complete
		;;
	-send_notification_crash)
		script_send_notification_crash
		;;
	-install_aliases)
		script_install_alias
		;;
	-server_tmux_install)
		script_server_tmux_install
		;;
	-rebuild_services)
		script_install_services
		;;
	-rebuild_prefix)
		script_install_prefix
		;;
	-disable_services)
		script_disable_services_manual
		;;
	-enable_services)
		script_enable_services_manual
		;;
	-reload_services)
		script_reload_services
		;;
	-timer_one)
		script_timer_one
		;;
	-timer_two)
		script_timer_two
		;;
	*)
	echo -e "${CYAN}Time: $(date +"%Y-%m-%d %H:%M:%S") ${NC}"
	echo -e "${CYAN}$NAME server script by 7thCore${NC}"
	echo ""
	echo "For more detailed information, execute the script with the -help argument"
	echo ""
	echo "Usage: $0 {diag|start|start_no_err|stop|restart|backup|autobackup|deloldbackup|delete_save|change_branch|install_aliases|rebuild_services|disable_services|enable_services|reload_services|update|verify|update_mods|update_script|update_script_force|attach|status|install|install_packages"
	exit 1
	;;
esac

exit 0
