#!/bin/bash
if ! id -u ci >/dev/null 2>&1; then
   echo -e "There is no ci user on this system, check the REAMDE.md for the required steps\n"
   exit 1
fi
ci_home=/home/ci/

sudo adduser ci \
    && sudo mkdir "$ci_home".ssh \
    && sudo ssh-keygen -f "$ci_home".ssh/id_rsa \
    && sudo chown -R ci "$ci_home".ssh/ \
    && echo -e "\nCopy this to your authorized_keys file on the rsync daemon:" \
    && sudo cat "$ci_home".ssh/id_rsa.pub
