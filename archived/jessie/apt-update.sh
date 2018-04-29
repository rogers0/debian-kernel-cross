#!/bin/bash

SCRIPT_ROOT=$(readlink -f $(dirname $0))
SRC_ROOT=$(readlink -f $(dirname $0)/..)
ID=$(id -u)

. $SCRIPT_ROOT/config
[ -e "$SCRIPT_ROOT/config_local" ] && . $SCRIPT_ROOT/config_local

if [ $ID -eq 0 -a -d $CHROOT ]; then

	$SCRIPT_ROOT/chroot_shell.sh prepare
	APT=apt-get
	chroot $CHROOT which apt &>/dev/null && APT=apt
echo $APT
	chroot $CHROOT $APT update
	chroot $CHROOT $APT upgrade -y --no-install-recommends
	chroot $CHROOT apt-get clean
	chroot $CHROOT $APT dist-upgrade --no-install-recommends
	chroot $CHROOT apt-get clean

	echo you need to run \"./umount_chroot_device.sh\" to release some chrooted device mounting after finishing all chroot shells.
fi
