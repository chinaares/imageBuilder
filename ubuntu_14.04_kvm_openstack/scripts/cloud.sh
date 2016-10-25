#!/bin/sh -eux

apt-get -y --force-yes install grub-pc
export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
dpkg-reconfigure grub-pc
# enable tty console
PATH=/sbin:/usr/sbin:/bin:/usr/bin
sed -i 's|#GRUB_DISABLE_LINUX_UUID=true|GRUB_DISABLE_LINUX_UUID=true|g' /etc/default/grub
sed -i 's|#GRUB_DISABLE_RECOVERY="true"|GRUB_DISABLE_RECOVERY="true"|g' /etc/default/grub
sed -i 's|GRUB_TIMEOUT=10|GRUB_TIMEOUT=5|g' /etc/default/grub
#sed -i 's|GRUB_CMDLINE_LINUX=""|GRUB_CMDLINE_LINUX="consoleblank=0"|g' /etc/default/grub
#sed -i 's|GRUB_CMDLINE_LINUX_DEFAULT="quiet"|GRUB_CMDLINE_LINUX_DEFAULT="consoleblank=0"|g' /etc/default/grub
sed -i -e 's#GRUB_CMDLINE_LINUX=.*$#GRUB_CMDLINE_LINUX="text console=tty1 console=ttyS0,115200n8"#' \
-e 's/#GRUB_TERMINAL=console/GRUB_TERMINAL=console/' \
-e 's#GRUB_CMDLINE_LINUX_DEFAULT="quiet"#GRUB_CMDLINE_LINUX_DEFAULT=""#' /etc/default/grub
#update-grub

cat <<'EOF' > /etc/init/ttyS0.conf
# ttyS0 - getty
#
# This service maintains a getty on tty1 from the point the system is
# started until it is shut down again.

start on stopped rc RUNLEVEL=[2345] and (
            not-container or
            container CONTAINER=lxc or
            container CONTAINER=lxc-libvirt)

stop on runlevel [!2345]

respawn
exec /sbin/getty -8 115200 ttyS0
EOF

# Install Cloud-Init
apt-get -y install cloud-init cloud-utils cloud-initramfs-growroot
apt-get -y install qemu-guest-agent

# configure cloud init 'cloud-user' as sudo
# this is not configured via default cloudinit config
mkdir -p /etc/cloud
cat > /etc/cloud/cloud.cfg <<EOF
#cloud-config
users:
 - default

disable_root: true
ssh_pwauth:   1
disable_root: 0
chpasswd:
  expire: false

preserve_hostname: false

cloud_init_modules:
 - migrator
 - seed_random
 - bootcmd
 - write-files
 - growpart
 - resizefs
 - set_hostname
 - update_hostname
 - update_etc_hosts
 - ca-certs
 - rsyslog
 - users-groups
 - ssh

cloud_config_modules:
 - emit_upstart
 - disk_setup
 - mounts
 - ssh-import-id
 - locale
 - set-passwords
 - grub-dpkg
 - apt-pipelining
 - apt-configure
 - package-update-upgrade-install
 - landscape
 - timezone
 - puppet
 - chef
 - salt-minion
 - mcollective
 - disable-ec2-metadata
 - runcmd
 - byobu

cloud_final_modules:
 - rightscale_userdata
 - scripts-vendor
 - scripts-per-once
 - scripts-per-boot
 - scripts-per-instance
 - scripts-user
 - ssh-authkey-fingerprints
 - keys-to-console
 - phone-home
 - final-message
 - power-state-change

system_info:
  default_user:
    name: ubuntu
    lock_passwd: true
    gecos: Ubuntu Cloud User
    groups: [adm, audio, cdrom, dialout, dip, floppy, netdev, video]
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    shell: /bin/bash
  distro: ubuntu
  paths:
    cloud_dir: /var/lib/cloud
    templates_dir: /etc/cloud/templates
    upstart_dir: /etc/init/
  ssh_svcname: ssh

# vim:syntax=yaml
EOF

#Rebuild all initramfs images.
#This is very important. Without rebuilding the initramfs images, the module won't be 
#available and nothing will get done.
#Also note that I'm explicitly rebuilding an image for every kernel package installed - 
#this is because we might be running kernel A, and just installed newer kernel B with 
#yum update -y, so if I only used dracut -f only kernel A's image will be rebuilt, and
# next time we'll boot from kernel B's image, that doesn't have the module.
#rpm -qa kernel | sed 's/^kernel-//'  | xargs -I {} dracut -f /boot/initramfs-{}.img {}
# apt-get -y install kpartx kbd dracut
# conflict to ....
# problem has been identified and is tracked in the bug report Package dracut cannot 
#be installed on Ubuntu 12.10. The underlying issue is tracked in the bug report Depend 
#on linux-initramfs-tools.
#Together with the Debian maintainer of the dracut package, we came up with a workaround 
#for installing dracut by removing the conflict to initramfs-tools. 
#Detailed information can be found in the blog post Installing and configuring dracut to 
#boot Ubuntu 12.10 from an NFS-root over a VLAN tagged network using bonded interfaces.
#apt-get -y build-dep dracut     # install build dependencies for dracut
#apt-get -y install dpkg-dev nfs # install dpkg-dev to build dracut .deb package
#cd ~                            # change to your home folder
##git clone git://git.kernel.org/pub/scm/boot/dracut/dracut.git # checkout dracut
#apt-get source dracut
#cd dracut*
#sed -i 's/Conflicts: initramfs-tools/Conflicts: /' debian/control # fix conflict
#sed -i 's/usr\/etc/etc/g' debian/dracut.install # fix another issue
#dpkg-buildpackage -b          # build .deb packages
#cd ..
#dpkg -i dracut*.deb           # install dracut and dracut-network
#rm ./* -rf
#dracut -f

update-initramfs -u
update-grub

# Install haveged for entropy
apt-get -y install haveged

# replace password from root with a encrypted one
#usermod -p "*" root


