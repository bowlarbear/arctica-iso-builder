#!/bin/sh

# exit on error
set -e

ISO_TARGET_FILES=/cdrom/target-files
COMMAND_LOG="/target/var/log/installer-late-command.log"

USERNAME="ubuntu"

# exec > will redirect the rest of the scripts output to file
# /var/log is mounted as a filesystem on the install media, so the log can be viewed on the USB drive later
exec > ${COMMAND_LOG} 2>&1
echo "Running preseed success command script."

# remove initial setup greeting from gnome
in-target apt-get remove -y gnome-initial-setup

# auto login of ubuntu user
sed -i "s/.*AutomaticLoginEnable.*/AutomaticLoginEnable = true/g" /target/etc/gdm3/custom.conf
sed -i "s/.*AutomaticLogin =.*/AutomaticLogin = ${USERNAME}/g" /target/etc/gdm3/custom.conf

# sudo without password
echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" > /target/etc/sudoers.d/${USERNAME} 
chmod 0440 /target/etc/sudoers.d/${USERNAME}

# install first run script
cp /cdrom/arctica-first-run.sh /target/home/${USERNAME}/arctica-first-run.sh
chmod +x /target/home/${USERNAME}/arctica-first-run.sh
chown -R 1000:1000 /target/home/${USERNAME}/arctica-first-run.sh

# Create an autostart launcher for first-run script
mkdir -p /target/home/${USERNAME}/.config/autostart
cat << EOF > /target/home/${USERNAME}/.config/autostart/arctica-first-run.desktop
[Desktop Entry]
Type=Application
Exec=/home/ubuntu/arctica-first-run.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=FirstRunScript
Comment=First Run for Arctic
EOF
chown -R 1000:1000 /target/home/${USERNAME}/.config

echo "Finished preseed success command script."
