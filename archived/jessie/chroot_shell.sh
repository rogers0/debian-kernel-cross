#!/bin/bash

SCRIPT_ROOT=$(readlink -f $(dirname $0))
SRC_ROOT=$(readlink -f $(dirname $0)/..)
ID=$(id -u)
ARG=$1

. $SCRIPT_ROOT/config
[ -e "$SCRIPT_ROOT/config_local" ] && . $SCRIPT_ROOT/config_local

if [ $ID -eq 0 -a -d $CHROOT ]; then
# chroot and su to the specific normal user
	grep $CHROOT/dev /proc/mounts > /dev/null || mount --bind /dev $CHROOT/dev
	grep $CHROOT/proc /proc/mounts > /dev/null || chroot $CHROOT mount -t proc proc /proc
	grep $CHROOT/sys /proc/mounts > /dev/null || chroot $CHROOT mount -t sysfs sysfs /sys
	grep $CHROOT/dev/pts /proc/mounts > /dev/null || chroot $CHROOT mount -t devpts devpts /dev/pts

	BASENAME=$(basename $SRC_ROOT)
	DEB_KERNEL_GIT=${DEB_KERNEL_DIR}.git
	LINUX_GIT=${LINUX_DIR}.git
	[ -d "$CHROOT/$BASENAME" ] || mkdir $CHROOT/$BASENAME
	[ -d "$CHROOT/$DEB_KERNEL_GIT" ] || mkdir $CHROOT/$DEB_KERNEL_GIT
	[ -d "$CHROOT/$LINUX_GIT" ] || mkdir $CHROOT/$LINUX_GIT
	grep "$CHROOT/$BASENAME" /proc/mounts > /dev/null || mount --bind $SRC_ROOT $CHROOT/$BASENAME
	if ! grep "$CHROOT/$DEB_KERNEL_GIT" /proc/mounts > /dev/null; then
		[ -n $DEB_KERNEL_DIR ] && [ -d "$LOCAL_HOME/${DEB_KERNEL_DIR}/.git" ] && mount --bind $LOCAL_HOME/${DEB_KERNEL_DIR}/.git $CHROOT/$DEB_KERNEL_GIT
	fi
	grep "$CHROOT/$LINUX_GIT" /proc/mounts > /dev/null || mount --bind $LOCAL_HOME/${LINUX_DIR}/.git $CHROOT/$LINUX_GIT

	[ "x$ARG" = "xprepare" ] && exit 0
	echo Start to work under chroot shell
	echo chroot $CHROOT su -l $NORMALUSER
	chroot $CHROOT su -l $NORMALUSER
	echo you need to run \"./umount_chroot_device.sh\" to release some chrooted device mounting after finishing all chroot shells.
fi
