#/bin/bash

SCRIPT_ROOT=$(readlink -f $(dirname $0))
SRC_ROOT=$(readlink -f $(dirname $0)/..)
ID=$(id -u)

. $SCRIPT_ROOT/config

if [ $ID -eq 0 -a -d $CHROOT ]; then
# chroot and su to the specific normal user
	echo Start to work under chroot shell
	echo chroot $CHROOT su -l $NORMALUSER
	chroot $CHROOT su -l $NORMALUSER
fi
