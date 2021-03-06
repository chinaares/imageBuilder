#!/bin/bash

# Remove log files from the VM
find /var/log -type f -exec rm -f {} \;

# Remove locale seed
rm -f /root/locale-preseed.cfg

# rm  hosts keys
rm -f /etc/ssh/*key*

# remove ip and mac address
rm -fr /etc/udev/rules.d/70-persistent-net.rules
sed -i '/HWADDR=.*/d' /etc/sysconfig/network-scripts/ifcfg-eth0

# Remove hardware specific settings from eth0
sed -i -e 's/^\(HWADDR\|UUID\|IPV6INIT\|NM_CONTROLLED\|MTU\).*//;/^$/d' \
    /etc/sysconfig/network-scripts/ifcfg-eth0
# Remove all kernels except the current version
rpm -qa | grep ^kernel-[0-9].* | sort | grep -v $(uname -r) | \
    xargs -r yum -y remove

#yum -y erase gtk2 libX11 hicolor-icon-theme avahi freetype bitstream-vera-fonts
yum -y clean all

# Have a sane vimrc
echo "set background=dark" >> /etc/vimrc
