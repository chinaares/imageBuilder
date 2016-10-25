#!/bin/sh -eux

echo '==> Zeroing out empty area to save space in the final image'
# Zero out the free space to save space in the final image.  Contiguous
# zeroed space compresses down to nothing.
dd if=/dev/zero of=/EMPTY bs=1M || echo "dd exit code $? is suppressed"
rm -f /EMPTY

# Block until the empty file has been removed, otherwise, Packer
# will try to kill the box while the disk is still full and that's bad
# Add `sync` so Packer doesn't quit too early, before the large file is deleted.
sync

#echo "==> Disk usage before cleanup"
#echo ${DISK_USAGE_BEFORE_CLEANUP}

echo "==> Disk usage after cleanup"
df -h
lsblk