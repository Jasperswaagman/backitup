#!/bin/bash
rsyncd_home=/home/rsyncd/

sudo adduser rsyncd \
    && sudo mkdir "$rsyncd_home".ssh \
    && sudo ssh-keygen -f "$rsyncd_home".ssh/id_rsa \
    && sudo chown -R rsyncd "$rsyncd_home".ssh/ \
    && echo -e "\nCopy this to your authorized_keys file on the rsync daemon:" \
    && sudo cat "$rsyncd_home".ssh/id_rsa.pub
