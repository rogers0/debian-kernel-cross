#!/bin/sh

SCRIPT_ROOT=$(readlink -f $(dirname $0))
SRC_ROOT=$(readlink -f $(dirname $0)/..)

. $SCRIPT_ROOT/config_common
[ -e "$SCRIPT_ROOT/config" ] && . $SCRIPT_ROOT/config
[ -e "$SCRIPT_ROOT/config_local" ] && . $SCRIPT_ROOT/config_local

if [ $LOCAL_UID -eq 0 -a -d $CHROOT ]; then

	$SCRIPT_ROOT/chroot_shell.sh prepare
	chroot $CHROOT apt-get update
	chroot $CHROOT apt-get upgrade -y
	chroot $CHROOT apt-get dist-upgrade
	chroot $CHROOT apt-get autoremove
	chroot $CHROOT apt-get clean

	#echo you need to run \"./umount_chroot_device.sh\" to release some chrooted device mounting after finishing all chroot shells.
	$SCRIPT_ROOT/umount_chroot_device.sh
fi
