#!/usr/bin/env bash
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
                        SCRIPTHOME: starch
-------------------------------------------------------------------------

final setup and sonfig
GRUB EFI bootloader install & check
"
source /root/starch/setup.conf
if [[ -d "/sys/firmware/efi" ]]; then
    grub-install --efi-directory=/boot ${DISK}
fi
# set kernel parameter for decrypting the drive
if [[ "${FS}" == "luks" ]]; then
sed -i "s%GRUB_CMDLINE_LINUX_DEFAULT=\"%GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=${encryped_partition_uuid}:ROOT root=/dev/mapper/ROOT %g" /etc/default/grub
fi

echo -e "installing a neat Grub theme..."
THEME_DIR="/boot/grub/themes"
THEME_NAME=CyberRe
echo -e "creating the theme dir..."
mkdir -p "${THEME_DIR}/${THEME_NAME}"
echo -e "copying theme..."
cd ${HOME}/starch
cp -a ${THEME_NAME}/* ${THEME_DIR}/${THEME_NAME}
echo -e "making back up of GRUB config..."
cp -an /etc/default/grub /etc/default/grub.bak
echo -e "setting default theme..."
grep "GRUB_THEME=" /etc/default/grub 2>&1 >/dev/null && sed -i '/GRUB_THEME=/d' /etc/default/grub
echo "GRUB_THEME=\"${THEME_DIR}/${THEME_NAME}/theme.txt\"" >> /etc/default/grub
echo -e "updating GRUB..."
grub-mkconfig -o /boot/grub/grub.cfg
echo -e "B)"

echo -ne "
-------------------------------------------------------------------------
                    enabling LDM
-------------------------------------------------------------------------
"
systemctl enable sddm.service
echo -ne "
-------------------------------------------------------------------------
                    setting up SDDM theme
-------------------------------------------------------------------------
"
cat <<EOF > /etc/sddm.conf
[Theme]
Current=Nordic
EOF

echo -ne "
-------------------------------------------------------------------------
                    enabling essential services
-------------------------------------------------------------------------
"
systemctl enable cups.service
ntpd -qg
systemctl enable ntpd.service
systemctl disable dhcpcd.service
systemctl stop dhcpcd.service
systemctl enable NetworkManager.service
systemctl enable bluetooth
echo -ne "
-------------------------------------------------------------------------
                    cleaning 
-------------------------------------------------------------------------
"
# Remove no password sudo rights
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
# Add sudo rights
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

rm -r /root/starch
rm -r /home/$USERNAME/starch

# Replace in the same state
cd $pwd
