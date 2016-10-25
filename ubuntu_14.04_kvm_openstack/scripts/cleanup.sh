#!/bin/sh -eux

echo "==> Cleaning up udev rules"
rm -rf /dev/.udev/

echo "==> Cleaning up leftover dhcp leases"
# Ubuntu 10.04
if [ -d "/var/lib/dhcp3" ]; then
    rm /var/lib/dhcp3/*
fi
# Ubuntu 12.04 & 14.04
if [ -d "/var/lib/dhcp" ]; then
    rm /var/lib/dhcp/*
fi

rm -rf /tmp/*  /etc/ssh/ssh_host*

uname -a
export APT_LISTCHANGES_FRONTEND=none
export DEBIAN_FRONTEND=noninteractive
apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy purge $(dpkg --list | grep '^rc' |awk '{print $2}')
#apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy purge $(dpkg --list | awk -v image="$(uname -r)" '/linux-image-[0-9]/{if($0 !~ image) print $2 }')
apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy autoremove --purge
apt-get -o Dpkg::Options::="--force-confnew" --force-yes -y clean
apt-get -o Dpkg::Options::="--force-confnew" --force-yes -y autoclean

unset HISTFILE
rm -f /root/.bash_history
rm -f /home/vagrant/.bash_history

# Clean up log files
find /var/log -type f | while read f; do echo -ne '' > $f; done;

apt-get -y autoremove --purge
apt-get -y autoclean
apt-get -y clean

#for p in ufw ntfs-3g netcat-openbsd 'language-pack-gnome-*' ureadahead rsyslog tcpd accountsservice install-info  krb5-locales laptop-detect lshw mlocate ntpdate command-not-found-data powermgmt-base build-essential ppp pppconfig pppoeconf popularity-contest installation-report landscape-common wireless-tools wpasupplicant; do
#    apt-get -y purge $p || true;
#done

find /var/lib/apt/lists/ -type f -delete
