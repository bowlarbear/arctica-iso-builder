#!/bin/sh

####################################
# customize first run actions here..
#remove user password
sudo passwd -d whoami
#disable screen blank
gsettings set org.gnome.desktop.session idle-delay 0
#diable update notifier
gsettings set com.ubuntu.update-notifier no-show-notifications true
#copy Arctica binary from the installation media root to the home dir
cp /media/$USER/arctica-os/Arctica $HOME
#make binary executable
sudo chmod +x $HOME/Arctica
#create config.txt
echo "type=init" > $HOME/config.txt
#execute the Arctica binary
./Arctica

##############################
# keep this code, clean up...
rm -fr ~/.config/autostart/arctica-first-run.desktop
# last line
rm -fr ~/arctica-first-run.sh
