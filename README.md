# Backitup
All the credits on the rsync part go to the writer of this [post][guide].
This script lets you make cronjobs which will rsync specific files/dir to your backup-server ing ssh.

## Server prerequisites
Follow the steps under **Prepare serverhost** of the mentioned [guide][guide]

## Client prerequisites
The script assumes there is an rsyncd user on the host of which you want to backup things.
To make this user, run:
```bash
./prep_client.sh
```
After this, add the echoed public key to your server's authorized_keys file ([guide][guide]).

## Usage
Running the script requires two options that are mandatory.
```bash
Usage: ./backup.sh -d /your/dir/ -b host::module

options:
  -d directory which contains the files you want to backup (Mark the trailing slash!)
  -b Server ip/domain where you want rsync to send the files to. for ::module see 'man rsync'
```
[guide]: http://mennucc1.debian.net/howto-ssh-rsyncd.html
