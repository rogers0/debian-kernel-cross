#!/bin/bash

SCRIPT_ROOT=$(readlink -f $(dirname $0))
SRC_ROOT=$(readlink -f $(dirname $0)/..)
ID=$(id -u)

. $SCRIPT_ROOT/config
[ -e "$SCRIPT_ROOT/config_local" ] && . $SCRIPT_ROOT/config_local

if [ $ID -eq 0 -a -d $CHROOT ]; then
# chroot and su to the specific normal user
	BASENAME=$(basename $SRC_ROOT)
	DEB_KERNEL_GIT=${DEB_KERNEL_DIR}.git
	LINUX_GIT=${LINUX_DIR}.git
	grep "$CHROOT/$BASENAME" /proc/mounts > /dev/null && umount $CHROOT/$BASENAME
	grep "$CHROOT/$DEB_KERNEL_GIT" /proc/mounts > /dev/null && umount $CHROOT/$DEB_KERNEL_GIT
	grep "$CHROOT/$LINUX_GIT" /proc/mounts > /dev/null && umount $CHROOT/$LINUX_GIT
	grep $CHROOT/dev/pts /proc/mounts > /dev/null && chroot $CHROOT umount /dev/pts
	grep $CHROOT/sys /proc/mounts > /dev/null && chroot $CHROOT umount /sys
	grep $CHROOT/proc /proc/mounts > /dev/null && chroot $CHROOT umount /proc
	grep $CHROOT/dev /proc/mounts > /dev/null && chroot $CHROOT umount /dev
fi
