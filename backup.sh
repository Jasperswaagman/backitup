#!/bin/bash 
# Write backups to a remote host with rsync
# Maintainer: j.swaagman@peperzaken.nl

# =============================================================================
# Global variables
# =============================================================================
# Speedtest
speedtest="http://speedtest.wdc01.softlayer.com/downloads/test500.zip"

# =============================================================================
# Setup checks
# =============================================================================
# Check if there is a rsyncd user
if ! id -u rsyncd >/dev/null 2>&1; then
   echo -e "There is no rsyncd user on this system, check the REAMDE.md for the required steps\n"
   exit 1
fi 

# =============================================================================
# Runtime checks
# =============================================================================
# Check for root
if [ "$EUID" -ne 0 ]; then
    echo -e "You must be root"
    exit 1
fi

usage() { 
    echo -e "Usage: "$0" -d /your/dir/ -b host::module/path\n\noptions:\n  -d directory which contains the files you want to backup (Mark the trailing slash!)\n  -b Server ip/domain where you want rsync to send the files to. for ::module see 'man rsync'" 1>&2
    exit 1;
}

while getopts ":d:b:" opts; do
    case "${opts}" in
        d) 
	    # The directory which contains all the dirs/files you want to backup
            BACKUPPED_DIR_ROOT=${OPTARG}
	    ;;
        b)
	    # The server where you store your backups. Can be a host in the form of: host::module/path, host:/dir
            BACKUP_DAEMON=${OPTARG}            
	    ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${BACKUPPED_DIR_ROOT}" ] || [ -z "${BACKUP_DAEMON}" ]; then
    usage
fi

# =============================================================================
# Functions
# =============================================================================
set_known_host() {
    known_host=$(echo "$BACKUP_DAEMON" | perl -wnE 'say /^.*?(?=:)/g')
    if [[ -z $(sudo -u rsyncd ssh-keygen -H -F "$known_host") ]]; then
        ssh-keyscan -H "$known_host" >> /home/rsyncd/.ssh/known_hosts
    fi
}

get_crontimer() {
    minute=$(grep -m1 -ao '[0-9]' /dev/urandom | sed s/0/10/ | head -n1)
    hour=$(grep -m1 -ao '[1-4]' /dev/urandom | head -n1)
    cron_daily=""$minute" "$hour" * * *"                 # Every day at 01-04:01-10 hour
    cron_every_other_day=""$minute" "$hour" 1-31/2 * *"  # Every other day at 01-04:01-10 hour
    cron_weekly=""$minute" "$hour" * * 6"                # Every Saturday at 01-04:01-10 hour
}

search_cronjob() {
    if $(crontab -u rsyncd -l | grep -qw "$1"); then
        # Already has a back-up
        return 1
    fi
}

new_crontab() {
    if $(! crontab -u rsyncd -l); then
        export EDITOR=vi
        crontab -u rsyncd -e << EOF
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
    echo -e "Your bandwith is set to: $bandwidth Kbytes"
}

set_cronjob() {
    set_bandwidth
    echo -e "Creating cronjob for: ""$BACKUPPED_DIR_ROOT""$dir_to_backup"
    crontab -u rsyncd -l > /tmp/mycron
    echo "$cron_time" "rsync -zahv -e '"trickle -d "$bandwidth" ssh"' -e '"ssh -l rsyncd -i /home/rsyncd/.ssh/rsyncd"' "$BACKUPPED_DIR_ROOT""$dir_to_backup" "$BACKUP_DAEMON"/"$HOSTNAME" | logger -t BACKUP" >> /tmp/mycron
    if crontab -u rsyncd /tmp/mycron; then
        echo -e "Cronjob added!"
    else 
        echo -e "Could not create cronjob"
    fi
    rm /tmp/mycron
}

what_to_backup() {
    # First we make sure there is an existing crontab for the current user
    echo -e "\nCreating a crontab if needed, this might take a few seconds.."
    new_crontab >/dev/null 2>&1

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
    echo -n "Which directory do you want to back-up? [0-"$(($i-1))"]: "
    read dir
    
    if [ "$dir" -lt "$i" ]; then
    	dir_to_backup=${arr[$dir]}
    else 
	echo -e "Don't try to cheat the system, that number is not valid!"
	exit 1
    fi

    # How often
    echo -en "\n[0] - Every day\n[1] - Every other day\n[2] - Every saturday\nHow often do you want it to back-up [0]: "
    read timesneeded; timesneeded="${timesneeded:=0}"

    get_crontimer
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

install_trickle() {
    echo -e "We are going to install Trickle for you, this will let us truly limit our bandwidth speed"
    echo -en "Installing."
    apt-get update  > /dev/null
    echo -e "."
    apt-get install -y trickle > /dev/null
    echo -e "."
}

# =============================================================================
# Main
# =============================================================================
run=0
while [ "$run" -eq 0 ]; do
    # Install trickle if needed
    if ! dpkg -l trickle > /dev/null; then
    	install_trickle 
    fi
    if what_to_backup; then
        set_known_host
        set_cronjob
        echo -en "Do you want to backup more? [y/N]: "
        read input; input="${input:=n}"
        if [ "$input" == "n" ]; then
            run=1	
        fi
    else 
	echo -e "You did something wrong!"
    fi
done
