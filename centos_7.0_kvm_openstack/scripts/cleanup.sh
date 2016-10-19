#!/bin/bash

set -x

rm -fr /etc/yum.repos.d/custom.repo

# Make sure Udev doesn't block our network
# http://6.ptmc.org/?p=164
echo "cleaning up udev rules"
rm /etc/udev/rules.d/70-persistent-net.rules
mkdir /etc/udev/rules.d/70-persistent-net.rules
rm -rf /dev/.udev/
rm /lib/udev/rules.d/75-persistent-net-generator.rules

# Remove log files from the VM
find /var/log -type f -exec rm -f {} \;

# Remove locale seed
rm -f /root/locale-preseed.cfg

# rm  hosts keys
rm -f /etc/ssh/*key*

# Remove hardware specific settings from eth0
sed -i -e 's/^\(HWADDR\|UUID\|IPV6INIT\|NM_CONTROLLED\|MTU\).*//;/^$/d' \
    /etc/sysconfig/network-scripts/ifcfg-eth0
# Remove all kernels except the current version
rpm -qa | grep ^kernel-[0-9].* | sort | grep -v $(uname -r) | \
    xargs -r yum -y remove
yum -y clean all

# Have a sane vimrc
echo "set background=dark" >> /etc/vimrc
