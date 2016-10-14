#!/bin/sh

echo "./quick-vm-test.sh vmname disk-image-file-path "

echo "starting vm ... ..."

NAME="$1"
DISK_FILE="$2,if=none,id=drive-scsi0-0-0-0,cache=writeback"

/usr/bin/kvm \
-name $NAME \
-m size=4096 \
-drive file=$DISK_FILE  \
-device virtio-scsi-pci,id=scsi0,bus=pci.0  \
-device scsi-hd,bus=scsi0.0,channel=0,scsi-id=0,lun=0,drive=drive-scsi0-0-0-0,id=scsi0-0-0-0,bootindex=1  \
-device virtio-net,netdev=user.0  \
-device virtio-serial-pci,id=virtio-serial0,bus=pci.0  \
-device virtserialport,bus=virtio-serial0.0,nr=1,chardev=charchannel0,id=channel0,name=org.qemu.guest_agent.0  \
-device cirrus-vga,id=video0,bus=pci.0  \
-netdev user,id=user.0,hostfwd=tcp::2228-:22 \
-device virtio-balloon-pci,id=balloon0,bus=pci.0 \
-vnc 0.0.0.0:47  \
-boot once=d  \
-smp 4,sockets=1,cores=4,threads=1  \
-chardev socket,id=charchannel0,path=/var/lib/libvirt/qemu/org.qemu.guest_agent,server,nowait  \
-machine type=pc,accel=kvm 

