#!/usr/bin/env bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CONFIG_FILE=$SCRIPT_DIR/setup.conf
if [ ! -f $CONFIG_FILE ]; then # check if file exists
    touch -f $CONFIG_FILE # create file if not exists
fi

set_option() {
    if grep -Eq "^${1}.*" $CONFIG_FILE; then # check if option exists
        sed -i -e "/^${1}.*/d" $CONFIG_FILE # delete option if exists
    fi
    echo "${1}=${2}" >>$CONFIG_FILE # add option
}
logo () {
# This will be shown on every set as user is progressing
echo -ne "
------------------------------------------------------------------------------------
      ___                         ___           ___           ___           ___     
     /  /\          ___          /  /\         /  /\         /  /\         /  /\    
    /  /::\        /__/\        /  /::\       /  /::\       /  /::\       /  /:/    
   /__/:/\:\       \  \:\      /  /:/\:\     /  /:/\:\     /  /:/\:\     /  /:/     
  _\_ \:\ \:\       \__\:\    /  /::\ \:\   /  /::\ \:\   /  /:/  \:\   /  /::\ ___ 
 /__/\ \:\ \:\      /  /::\  /__/:/\:\_\:\ /__/:/\:\_\:\ /__/:/ \  \:\ /__/:/\:\  /\ 
 \  \:\ \:\_\/     /  /:/\:\ \__\/  \:\/:/ \__\/~|::\/:/ \  \:\  \__\/ \__\/  \:\/:/
  \  \:\_\:\      /  /:/__\/      \__\::/     |  |:|::/   \  \:\            \__\::/ 
   \  \:\/:/     /__/:/           /  /:/      |  |:|\/     \  \:\           /  /:/  
    \  \::/      \__\/           /__/:/       |__|:|~       \  \:\         /__/:/   
     \__\/                       \__\/         \__\|         \__\/         \__\/    
------------------------------------------------------------------------------------
    pre-setup settings
------------------------------------------------------------------------------------
"
}
filesystem () {
# This function will handle file systems. At this movement we are handling only
# btrfs and ext4. Others will be added in future.
echo -ne "
    select a fs for both boot and root
    1)      btrfs
    2)      ext4
    3)      luks with btrfs
    0)      exit
"
read FS
case $FS in
1) set_option FS btrfs;;
2) set_option FS ext4;;
3) 
echo -ne "enter luks password: "
read -s luks_password # read password without echo
set_option luks_password $luks_password
set_option FS luks;;
0) exit ;;
*) echo "try again"; filesystem;;
esac
}
timezone () {
# Added this from arch wiki https://wiki.archlinux.org/title/System_time
time_zone="$(curl --fail https://ipapi.co/timezone)"
echo -ne "system detected timezone: '$time_zone' \n"
echo -ne "is this correct? yes/no:" 
read answer
case $answer in
    y|Y|yes|Yes|YES)
    set_option TIMEZONE $time_zone;;
    n|N|no|NO|No)
    echo "enter desired timezone (example: Europe/London):" 
    read new_timezone
    set_option TIMEZONE $new_timezone;;
    *) echo "try again";timezone;;
esac
}
keymap () {
# These are default key maps as presented in official arch repo archinstall
echo -ne "
select keyboard layout:
    -by
    -ca
    -cf
    -cz
    -de
    -dk
    -es
    -et
    -fa
    -fi
    -fr
    -gr
    -hu
    -il
    -it
    -lt
    -lv
    -mk
    -nl
    -no
    -pl
    -ro
    -ru
    -sg
    -ua
    -uk
    -us

"
read -p "layout:" keymap
set_option KEYMAP $keymap
}

drivessd () {
echo -ne "
ssd? yes/no:
"
read ssd_drive

case $ssd_drive in
    y|Y|yes|Yes|YES)
    echo "mountoptions=noatime,compress=zstd,ssd,commit=120" >> setup.conf;;
    n|N|no|NO|No)
    echo "mountoptions=noatime,compress=zstd,commit=120" >> setup.conf;;
    *) echo "wrong option please select again";drivessd;;
esac
}

# selection for disk type
diskpart () {
# show disks present on system
lsblk -n --output TYPE,KNAME,SIZE | awk '$1=="disk"{print NR,"/dev/"$2" - "$3}' # show disks with /dev/ prefix and size
echo -ne "
------------------------------------------------------------------------------------
    THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK
------------------------------------------------------------------------------------

enter full path to disk: (example: /dev/sda):
"
read option
echo "DISK=$option" >> setup.conf

drivessd
set_option DISK $option
}
userinfo () {
read -p "please enter your username: " username
set_option USERNAME ${username,,} # convert to lower case as in issue #109 
echo -ne "please enter your password: \n"
read -s password # read password without echo
set_option PASSWORD $password
read -rep "please enter your hostname: " nameofmachine
set_option nameofmachine $nameofmachine
}
# More features in future
# language (){}

# Starting functions
clear
logo
userinfo
clear
logo
diskpart
clear
logo
filesystem
clear
logo
timezone
clear
logo
keymap