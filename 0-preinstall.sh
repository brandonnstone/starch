#!/usr/bin/env bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
echo -ne "
-------------------------------------------------------------------------

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

-------------------------------------------------------------------------
                    automated arch installer
-------------------------------------------------------------------------

setting up mirrors for optimal download
"
source setup.conf
iso=$(curl -4 ifconfig.co/country-iso)
timedatectl set-ntp true
pacman -S --noconfirm pacman-contrib terminus-font
setfont ter-v22b
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
pacman -S --noconfirm reflector rsync grub
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
echo -ne "
-------------------------------------------------------------------------
                    setting up $iso mirrors for optimal download
-------------------------------------------------------------------------
"
reflector -a 48 -c $iso -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist
mkdir /mnt &>/dev/null # Hiding error message if any
echo -ne "
-------------------------------------------------------------------------
                    installing prereqs
-------------------------------------------------------------------------
"
pacman -S --noconfirm gptfdisk btrfs-progs
echo -ne "
-------------------------------------------------------------------------
                    formatting disk
-------------------------------------------------------------------------
"
# disk prep
sgdisk -Z ${DISK} # zap all on disk
sgdisk -a 2048 -o ${DISK} # new gpt disk 2048 alignment

# create partitions
sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' ${DISK} # partition 1 (BIOS Boot Partition)
sgdisk -n 2::+300M --typecode=2:ef00 --change-name=2:'EFIBOOT' ${DISK} # partition 2 (UEFI Boot Partition)
sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' ${DISK} # partition 3 (Root), default start, remaining
if [[ ! -d "/sys/firmware/efi" ]]; then # Checking for bios system
    sgdisk -A 1:set:2 ${DISK}
fi
# make filesystems
echo -ne "
-------------------------------------------------------------------------
                    creating fs
-------------------------------------------------------------------------
"
createsubvolumes () {
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@var
    btrfs subvolume create /mnt/@tmp
    btrfs subvolume create /mnt/@.snapshots
}

mountallsubvol () {
    mount -o ${mountoptions},subvol=@home /dev/mapper/ROOT /mnt/home
    mount -o ${mountoptions},subvol=@tmp /dev/mapper/ROOT /mnt/tmp
    mount -o ${mountoptions},subvol=@.snapshots /dev/mapper/ROOT /mnt/.snapshots
    mount -o ${mountoptions},subvol=@var /dev/mapper/ROOT /mnt/var
}

if [[ "${DISK}" =~ "nvme" ]]; then
    partition2=${DISK}p2
    partition3=${DISK}p3
else
    partition2=${DISK}2
    partition3=${DISK}3
fi

if [[ "${FS}" == "btrfs" ]]; then
    mkfs.vfat -F32 -n "EFIBOOT" ${partition2}
    mkfs.btrfs -L ROOT ${partition3} -f
    mount -t btrfs ${partition3} /mnt
elif [[ "${FS}" == "ext4" ]]; then
    mkfs.vfat -F32 -n "EFIBOOT" ${partition2}
    mkfs.ext4 -L ROOT ${partition3}
    mount -t ext4 ${partition3} /mnt
elif [[ "${FS}" == "luks" ]]; then
    mkfs.vfat -F32 -n "EFIBOOT" ${partition2}
# enter luks password to cryptsetup and format root partition
    echo -n "${luks_password}" | cryptsetup -y -v luksFormat ${partition3} -
# open luks container and ROOT will be place holder 
    echo -n "${luks_password}" | cryptsetup open ${partition3} ROOT -
# now format that container
    mkfs.btrfs -L ROOT /dev/mapper/ROOT
# create subvolumes for btrfs
    mount -t btrfs /dev/mapper/ROOT /mnt
    createsubvolumes       
    umount /mnt
# mount @ subvolume
    mount -o ${mountoptions},subvol=@ /dev/mapper/ROOT /mnt
# make directories home, .snapshots, var, tmp
    mkdir -p /mnt/{home,var,tmp,.snapshots}
# mount subvolumes
    mountallsubvol
# store uuid of encrypted partition for grub
    echo encryped_partition_uuid=$(blkid -s UUID -o value ${partition3}) >> setup.conf
fi

# checking if user selected btrfs
if [[ ${FS} =~ "btrfs" ]]; then
ls /mnt | xargs btrfs subvolume delete
btrfs subvolume create /mnt/@
umount /mnt
mount -t btrfs -o subvol=@ -L ROOT /mnt
fi

# mount target
mkdir /mnt/boot
mkdir /mnt/boot/efi
mount -t vfat -L EFIBOOT /mnt/boot/

if ! grep -qs '/mnt' /proc/mounts; then
    echo "drive not mounted. can not continue"
    echo "rebooting in 3 ..." && sleep 1
    echo "rebooting in 2 ..." && sleep 1
    echo "rebooting in 1 ..." && sleep 1
    reboot now
fi
echo -ne "
-------------------------------------------------------------------------
                    install on main drive
-------------------------------------------------------------------------
"
pacstrap /mnt base base-devel linux linux-firmware vim nano sudo archlinux-keyring wget libnewt --noconfirm --needed
genfstab -U /mnt >> /mnt/etc/fstab
echo "keyserver hkp://keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf
cp -R ${SCRIPT_DIR} /mnt/root/starch
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
echo -ne "
-------------------------------------------------------------------------
                    GRUB BIOS install & check
-------------------------------------------------------------------------
"
if [[ ! -d "/sys/firmware/efi" ]]; then
    grub-install --boot-directory=/mnt/boot ${DISK}
fi
echo -ne "
-------------------------------------------------------------------------
                    checking for low mem systems (<8G)
-------------------------------------------------------------------------
"
TOTALMEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
if [[  $TOTALMEM -lt 8000000 ]]; then
    # Put swap into the actual system, not into RAM disk, otherwise there is no point in it, it'll cache RAM into RAM. So, /mnt/ everything.
    mkdir /mnt/opt/swap # make a dir that we can apply NOCOW to to make it btrfs-friendly.
    chattr +C /mnt/opt/swap # apply NOCOW, btrfs needs that.
    dd if=/dev/zero of=/mnt/opt/swap/swapfile bs=1M count=2048 status=progress
    chmod 600 /mnt/opt/swap/swapfile # set permissions.
    chown root /mnt/opt/swap/swapfile
    mkswap /mnt/opt/swap/swapfile
    swapon /mnt/opt/swap/swapfile
    # The line below is written to /mnt/ but doesn't contain /mnt/, since it's just / for the system itself.
    echo "/opt/swap/swapfile	none	swap	sw	0	0" >> /mnt/etc/fstab # Add swap to fstab, so it KEEPS working after installation.
fi
echo -ne "
-------------------------------------------------------------------------
                    SYSTEM READY FOR setup.sh
-------------------------------------------------------------------------
"
