# add custom script in here

VM_INIT='http://172.16.2.254/Packer/qga/vm_init.sh'
QEMU_GA='http://172.16.2.254/Packer/qga/qemu-ga.ubuntu14'

# add respawn script
# add respawn script
cat <<'EOF' > /etc/init/qemu-ga.conf 
# qemu-ga
start on runlevel [2345]
stop on runlevel [016]

respawn
env TRANSPORT_METHOD="virtio-serial"
env DEVPATH="/dev/virtio-ports/org.qemu.guest_agent.0"
env LOGFILE="/var/log/qemu-ga/qemu-ga.log"
env PIDFILE="/var/run/qemu-ga.pid"
env BLACKLIST_RPC="guest-file-open guest-file-close guest-file-read guest-file-write guest-file-seek guest-file-flush"

pre-start script
    [ -d /var/log/qemu-ga ] || mkdir -p /var/log/qemu-ga
    [ -d /usr/var/run/ ] || mkdir -p /usr/var/run/
end script
exec /usr/bin/qemu-ga --method $TRANSPORT_METHOD --path $DEVPATH --logfile $LOGFILE --pidfile $PIDFILE --blacklist $BLACKLIST_RPC
EOF

mkdir -p /usr/var/run/

# wget vm_init
cd /etc/ && wget $VM_INIT && chmod +x vm_init.sh
rm -rf /bin/sh && ln -s /bin/bash /bin/sh

sed -i -e 's/sleep 40/# sleep 40/' -e 's/sleep 59/# sleep 59/' /etc/init/failsafe.conf

# wget qemu_ga
cd /usr/bin && wget $QEMU_GA && mv qemu-ga.ubuntu14 qemu-ga && chmod +x qemu-ga

# enable tty console
PATH=/sbin:/usr/sbin:/bin:/usr/bin
sed -i -e 's#GRUB_CMDLINE_LINUX=.*$#GRUB_CMDLINE_LINUX="text console=tty1 console=ttyS0,115200n8"#' \
-e 's/#GRUB_TERMINAL=console/GRUB_TERMINAL=console/' \
-e 's#GRUB_CMDLINE_LINUX_DEFAULT="quiet"#GRUB_CMDLINE_LINUX_DEFAULT=""#' /etc/default/grub
update-grub

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

# delete nic config
sed -i '/eth0/,$d' /etc/network/interfaces