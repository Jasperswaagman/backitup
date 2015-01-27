#!/bin/bash

# Write backups to a remote host with rsync

BACKUPPED_DIR_ROOT=foobar   # Has to be in the form of /foo
BACKUP_SERVER=barfoo        # Can be a host in the form of host:/dir

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
    else 
        return 0
    fi
}

new_crontab() {
    if $(! crontab -l); then
        echo -e "Creating a crontab for you..."
        export EDITOR=vi
        crontab -e <<EOF
            dG:wq!
EOF
    fi
}

set_bandwidth() {
    echo -e "Checking your bandwidth..."
    if [ ! -f speed ]; then
        wget -O /dev/null "$speedtest" 2>speed  # Write the download to the speed file
    fi
    bandwidth=$(tail -n1 speed | egrep -o "\((\d+).+\)" | cut -c 2-3)    # Get the bandwidth in MB
    let bandwidth="$bandwidth * 7000"   # We don't want to take all the bandwidth, so *7 instead of *8 to Kbytes
    echo -e "Your bandwith is set to: $bandwidth bytes"
}

set_cronjob() {
    echo -e "Creating cronjob for: ""$dir_to_backup"
    set_bandwidth
    crontab -l > /tmp/mycron
    echo "$cron_time"" rsync -zv --max-bandwidth=$bandwidth "$BACKUPPED_DIR_ROOT"/"$dir_to_backup" "$BACKUP_SERVER"" >> /tmp/mycron
    if crontab /tmp/mycron; then
        echo -e "Cronjob added!"
    else 
        echo -e "Could not create cronjob"
    fi
    rm /tmp/mycron
}

what_to_backup() {
    # First we make sure there is an existing crontab for the current user
    new_crontab &> /dev/null    # Hide outpout of vi
    
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

if what_to_backup; then
   set_cronjob 
else 
    echo -e "You did something wrong!"
fi
