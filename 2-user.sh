#!/usr/bin/env bash
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
    installing AUR packs
------------------------------------------------------------------------------------
"
# You can solve users running this script as root with this and then doing the same for the next for statement. However I will leave this up to you.
source $HOME/starch/setup.conf

cd ~
touch "~/.cache/zshhistory"
git clone "https://github.com/brandonnstone/zsh"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
ln -s "~/zsh/.zshrc" ~/.zshrc

yay -S --noconfirm --needed - < ~/starch/pkg-files/aur-pkgs.txt

export PATH=$PATH:~/.local/bin
cp -r ~/starch/dotfiles/* ~/.config/

exit