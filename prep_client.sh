#!/bin/bash
sudo adduser rsyncd \
    && sudo mkdir /home/rsyncd/.ssh \
    && sudo ssh-keygen -f /home/rsyncd/.ssh/rsyncd \
    && sudo chown -R rsyncd /home/rsyncd/.ssh/ \
    && echo -e "Copy this to your authorized_keys file on the rsync daemon:" \
    && sudo cat /home/rsyncd/.ssh/rsyncd.pub
