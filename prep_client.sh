#!/bin/bash
ci_home=/home/ci/

sudo adduser ci \
    && sudo mkdir "$ci_home".ssh \
    && sudo ssh-keygen -f "$ci_home".ssh/id_rsa \
    && sudo chown -R ci "$ci_home".ssh/ \
    && echo -e "\nCopy this to your authorized_keys file on the rsync daemon:" \
    && sudo cat "$ci_home".ssh/id_rsa.pub
