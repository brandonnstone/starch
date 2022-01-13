#!/bin/bash

# Find the name of the folder the scripts are in

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
echo -ne "
-------------------------------------------------------------------------
   ________  ________  ________  ________  ________  ________ 
  ╱        ╲╱        ╲╱        ╲╱        ╲╱        ╲╱    ╱   ╲
 ╱        _╱        _╱         ╱         ╱         ╱         ╱
╱-        ╱╱       ╱╱         ╱        _╱       --╱         ╱ 
╲________╱ ╲______╱ ╲___╱____╱╲____╱___╱╲________╱╲___╱____╱  

-------------------------------------------------------------------------
                    automated arch installer
-------------------------------------------------------------------------
                scripts are in directory named starch
"
    bash startup.sh
    source $SCRIPT_DIR/setup.conf
    bash 0-preinstall.sh
    arch-chroot /mnt /root/starch/1-setup.sh
    arch-chroot /mnt /usr/bin/runuser -u $USERNAME -- /home/$USERNAME/starch/2-user.sh
    arch-chroot /mnt /root/starch/3-post-setup.sh

echo -ne "
-------------------------------------------------------------------------
   ________  ________  ________  ________  ________  ________ 
  ╱        ╲╱        ╲╱        ╲╱        ╲╱        ╲╱    ╱   ╲
 ╱        _╱        _╱         ╱         ╱         ╱         ╱
╱-        ╱╱       ╱╱         ╱        _╱       --╱         ╱ 
╲________╱ ╲______╱ ╲___╱____╱╲____╱___╱╲________╱╲___╱____╱  

-------------------------------------------------------------------------
                    automated arch installer
-------------------------------------------------------------------------
                done - pls eject ur install thing and reboot
"