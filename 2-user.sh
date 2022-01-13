#!/usr/bin/env bash
echo -ne "
-------------------------------------------------------------------------
   ________  ________  ________  ________  ________  ________ 
  ╱        ╲╱        ╲╱        ╲╱        ╲╱        ╲╱    ╱   ╲
 ╱        _╱        _╱         ╱         ╱         ╱         ╱
╱-        ╱╱       ╱╱         ╱        _╱       --╱         ╱ 
╲________╱ ╲______╱ ╲___╱____╱╲____╱___╱╲________╱╲___╱____╱  

-------------------------------------------------------------------------
                    automated arch installer
                        SCRIPTHOME: starch
-------------------------------------------------------------------------

installing AUR packs
"
# You can solve users running this script as root with this and then doing the same for the next for statement. However I will leave this up to you.
source $HOME/starch/setup.conf

cd ~
git clone "https://aur.archlinux.org/yay.git"
cd ~/yay
makepkg -si --noconfirm
cd ~
touch "~/.cache/zshhistory"
git clone "https://github.com/brandonnstone/zsh"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
ln -s "~/zsh/.zshrc" ~/.zshrc

yay -S --noconfirm --needed - < ~/starch/pkg-files/aur-pkgs.txt

export PATH=$PATH:~/.local/bin
cp -r ~/starch/dotfiles/* ~/.config/
pip install konsave
konsave -i ~/starch/kde.knsv
sleep 1
konsave -a kde

echo -ne "
-------------------------------------------------------------------------
                    SYSTEM READY FOR post-setup.sh
-------------------------------------------------------------------------
"
exit
