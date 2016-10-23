#!/bin/bash

# Configure serial console
echo '==> Configuring settings for Console Logging'
echo "NOZEROCONF=yes" >> /etc/sysconfig/network

# enable tty console
echo "ttyS0" >> /etc/securetty

cat <<'EOF' > /etc/init/ttyS0.conf
stop on runlevel [S016]
start on runlevel [2345]
respawn
instance /dev/ttyS0
exec /sbin/mingetty ttyS0
EOF

yum -y install grub2-tools

# https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/System_Administrators_Guide/sec-GRUB_2_over_Serial_Console.html#sec-Configuring_GRUB_2
cat > /etc/default/grub <<EOF
GRUB_DEFAULT=0
GRUB_HIDDEN_TIMEOUT=0
GRUB_HIDDEN_TIMEOUT_QUIET=true
GRUB_TIMEOUT=1
GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
GRUB_DEFAULT=saved
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL=serial
GRUB_SERIAL_COMMAND="serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1"
GRUB_CMDLINE_LINUX_DEFAULT="console=tty0 console=ttyS0,115200n8"
GRUB_TERMINAL_OUTPUT="console"
GRUB_DISABLE_RECOVERY="true"
EOF

grub2-mkconfig -o /boot/grub2/grub.cfg

# remove uuid
sed -i '/UUID/d' /etc/sysconfig/network-scripts/ifcfg-e*
sed -i '/HWADDR/d' /etc/sysconfig/network-scripts/ifcfg-e*

# Install Cloud-Init, epel is required
#yum -y install cloud-init
# install cloud packages
#yum -y install cloud-init cloud-utils heat-cfntools cloud-utils-growpart dracut-modules-growroot qemu-guest-agent 
#yum -y install cloud-init cloud-utils-growpart dracut-modules-growroot
yum -y install cloud-init cloud-utils cloud-utils-growpart dracut-modules-growroot
yum -y install qemu-guest-agent

# configure cloud init 'cloud-user' as sudo
# this is not configured via default cloudinit config
mkdir -p /etc/cloud
cat > /etc/cloud/cloud.cfg <<EOF
#cloud-config
users:
 - default

disable_root: 1
ssh_pwauth:   1
disable_root: 0
chpasswd:
  expire: false

mount_default_fields: [~, ~, 'auto', 'defaults,nofail', '0', '2']
resize_rootfs_tmp: /dev
ssh_deletekeys:   0
ssh_genkeytypes:  ~
syslog_fix_perms: ~
cc_ready_cmd: ['/bin/true']
locale_configfile: /etc/sysconfig/i18n
ssh_svcname:      sshd

cloud_init_modules:
 - migrator
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
 - mounts
 - ssh-import-id
 - locale
 - set-passwords
 - timezone
 - disable-ec2-metadata
 - runcmd
 - package-update-upgrade-install
 - yum-add-repo
 - timezone
 - puppet
 - chef
 - salt-minion
 - mcollective

cloud_final_modules:
 - rightscale_userdata
 - scripts-per-once
 - scripts-per-boot
 - scripts-per-instance
 - scripts-user
 - ssh-authkey-fingerprints
 - keys-to-console
 - phone-home
 - final-message

system_info:
  default_user:
    name: centos
    lock_passwd: true
    gecos: Cloud User
    groups: [wheel, adm]
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    shell: /bin/bash
  distro: rhel
  paths:
    cloud_dir: /var/lib/cloud
    templates_dir: /etc/cloud/templates
  ssh_svcname: sshd
  
#growpart:
#  mode: auto
#  devices: ['/']
#  ignore_growroot_disabled: false
#  resize_rootfs: true

# vim:syntax=yaml
EOF

#redhat/centos6 will not use mkinitrd ,but dracut instead
#mkinitrd --preload vmw_pvscsi /boot/initramfs-$(uname -r).img $(uname -r) --force

#Rebuild all initramfs images.
#This is very important. Without rebuilding the initramfs images, the module won't be 
#available and nothing will get done.
#Also note that I'm explicitly rebuilding an image for every kernel package installed - 
#this is because we might be running kernel A, and just installed newer kernel B with 
#yum update -y, so if I only used dracut -f only kernel A's image will be rebuilt, and
# next time we'll boot from kernel B's image, that doesn't have the module.
#rpm -qa kernel | sed 's/^kernel-//'  | xargs -I {} dracut -f /boot/initramfs-{}.img {}
dracut -f

# Install haveged for entropy
yum -y install haveged

# replace password from root with a encrypted one
#usermod -p "*" root


