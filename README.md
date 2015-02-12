# Backitup
All the credits on the rsync part go to the writer of this [post][guide].
This script lets you make cronjobs which will rsync specific files/dir to your backup-server ing ssh.

## Server prerequisites
Follow the steps under **Prepare serverhost** of the mentioned [guide][guide]

## Client prerequisites
The script assumes there is an rsyncd user on the host of which you want to backup things.
To make this user:
```bash
sudo adduser rysncd
```
After this, follow the steps of the **Foreach localhost** part of the [guide][guide]

## Usage

### First use
To make use of the script, one has to fill in these two variables:
```bash
BACKUPPED_DIR_ROOT=     # The directory which contains all the dirs/files you want to backup
BACKUP_DAEMON=          # The server where you store your backups. Can be a host in the form of: host::module, host:/dir
```

### Run it
To run the script:
```bash
sudo ./backitup
```
[guide]: http://mennucc1.debian.net/howto-ssh-rsyncd.html