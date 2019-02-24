#!/bin/bash
printf "\n Welcome to Linux Server Configuration Wizard \n"
echo "       ======================================="
printf "      ....Software Services Ltd....\n\n"

read -p " Enter the hostname of server : " new_hostname

vgname="$(vgs | sed -n '2p' | awk {'print $1'})"

#echo "$vgname"

if [ $(id -u) -eq 0 ]; then
        cp /etc/fstab /etc/fstab.orig
        cp /boot/grub/grub.conf /boot/grub/grub.conf.orig
        sed -i "s/$vgname/$new_hostname/g" /etc/fstab
        sed -i "s/$vgname/$new_hostname/g" /etc/grub.conf
        sed -i "s/$vgname/$new_hostname/g" /boot/grub/grub.conf
        sed -i "s/$vgname/$new_hostname/g" /boot/grub/menu.lst

printf "...Please check the below Informations are Correct ...\n\n "

        printf "..fstab entries..\n\n"
        cat /etc/fstab | grep -i "$new_hostname"
        printf "../etc/grub.conf entries..\n\n"
        cat /etc/grub.conf | grep -i "$new_hostname"
        printf "../boot/grub/grub.conf entries..\n\n"
        cat /boot/grub/grub.conf | grep -i "$new_hostname"
        printf "../boot/grub/menu/lst entries..\n\n"
        cat /boot/grub/menu.lst | grep -i "$new_hostname"

read -p "...Can we go to the next step ..? yes/no : " answer
        if [ "$answer" == "yes" ]; then
                vgrename /dev/"$vgname" /dev/vg_"$new_hostname"
                mv /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r).img.backup
                echo -n "...Installing initramfs ..."; dracut -v /boot/initramfs-$(uname -r).img $(uname -r) > /dev/null 2>&1 ; echo " done.";
#       dracut -v /boot/initramfs-$(uname -r).img $(uname -r) >> /dev/null
        else
                exit 1
        fi
else
        echo "Only root may add a user to the system ...!!"
        exit 2
fi
