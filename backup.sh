#!/bin/bash 
# Write backups to a remote host with rsync
# Maintainer: j.swaagman@peperzaken.nl
# Todo:
#   * Make it iterative so users can add more cronjobs at once

# The files/directories to backup
BACKUPPED_DIR_ROOT=     # Has to be in the form of /foo

# Can be a host in the form of host::module, host:/dir
BACKUP_DAEMON= # backup.peperzaken.nl::backup

# Cron patterns
cron_daily="30 2 * * *"                 # Every day at 02:30
cron_every_other_day="30 2 1-31/2 * *"  # Every other day at 02:30
cron_weekly="30 2 * * 6"                # Every Saturday at 02:30

# Speedtest
speedtest="http://speedtest.wdc01.softlayer.com/downloads/test500.zip"

search_cronjob() {
    if $(crontab -l | grep -qw "$1"); then
        # Already has a back-up
        return 1
    fi
}

new_crontab() {
    if $(! crontab -l); then
        export EDITOR=vi
        crontab -e << EOF
            dG:wq!
EOF
    fi
}

set_bandwidth() {
    echo -e "Checking your bandwidth..."
    if [ ! -f speed ]; then
        wget -O /dev/null "$speedtest" 2>speed  # Write the download to the speed file
    fi
    bandwidth=$(tail -n2 speed | head -n1 | perl -pe 's/.*\((\d+).+\).*/\1/p')    # Get the bandwidth in MB
    bandwidth=$(($bandwidth * 900))   # We don't want to take all the bandwidth, so instead of 1024 we use 900, to converse to KBytes
    echo -e "Your bandwith is set to: $bandwidth bytes"
}

set_cronjob() {
    set_bandwidth
    echo -e "Creating cronjob for: ""$dir_to_backup"
    crontab -l > /tmp/mycron
    echo "$cron_time" "rsync -zav -e '"trickle -d "$bandwidth" ssh"' -e '"ssh -l rsyncd -i /home/rsyncd/.ssh/id_rsa"' "$BACKUPPED_DIR_ROOT"/"$dir_to_backup" "$BACKUP_DAEMON" | logger -t BACKUP" >> /tmp/mycron
    if crontab /tmp/mycron; then
        echo -e "Cronjob added!"
    else 
        echo -e "Could not create cronjob"
    fi
    rm /tmp/mycron
}

what_to_backup() {
    # First we make sure there is an existing crontab for the current user
    echo -e "\nCreating a crontab for you..."
    new_crontab &> /dev/null    # Hide outpout of vi
    echo -e "Done, now let's set up your backup job\n"
    
    # What to backup
    echo "Possible directories you can back-up:"
    local arr=(); local i=0
    for f in $(ls $BACKUPPED_DIR_ROOT); do
        if $(search_cronjob $f); then
            echo [$i] - "$f"
            arr[$i]="$f"
            ((i++))
        fi
    done
    echo -n "Which directory do you want to back-up?: "
    read dir
    dir_to_backup=${arr[$dir]}

    # How often
    echo -en "\n[0] - Every day\n[1] - Every other day\n[2] - Every saturday\nHow often do you want it to back-up [0]: "
    read timesneeded; timesneeded="${timesneeded:=0}"

    if [ "$timesneeded" == "0" ]; then
        cron_time="$cron_daily"
        return 0
    elif [ "$timesneeded" == "1" ]; then
        cron_time="$cron_every_other_day"
        return 0
    elif [ "$timesneeded" == "2" ]; then
        cron_time="$cron_weekly"
        return 0
    fi

    # No valid values
    return 1
} 

# Check for root
if [ "$EUID" -ne 0 ]; then
    echo -e "You must be root\n"
    exit 1
fi

# Check if vars are set. (Perhaps make this interactive?)
if [[ "$BACKUPPED_DIR_ROOT" == "" ]] || [[ "$BACKUP_DAEMON" == "" ]]; then
    echo -e "To make use of this script you have to set the following variables, BACKUPPED_DIR_ROOT and BACKUP_DAEMON"
    exit
fi

# Install Trickle to manage our bandwidth
if dpkg -l trickle; then
    echo -e "You already have Trickle installed, awesome! Let's continue"
else 
    echo -e "We are going to install Trickle for you, this will let us truly limit our bandwidth speed"
    echo -e "Installing."
    apt-get update  > /dev/null
    echo -en "."
    apt-get install -y trickle > /dev/null
fi

# Run the main thingy
if what_to_backup; then
   set_cronjob 
else 
    echo -e "You did something wrong!"
fi
