#/bin/bash

SCRIPT_ROOT=$(readlink -f $(dirname $0))
SRC_ROOT=$(readlink -f $(dirname $0)/..)
ID=$(id -u)

. $SCRIPT_ROOT/config

if [ $ID -eq 0 -a -d $CHROOT ]; then
# chroot and run this script again
	cp -a $SRC_ROOT $CHROOT
	echo chroot $CHROOT su $NORMALUSER -c "/$(basename $SRC_ROOT)/$(basename $SCRIPT_ROOT)/$(basename $0)"
	chroot $CHROOT su $NORMALUSER -c "/$(basename $SRC_ROOT)/$(basename $SCRIPT_ROOT)/$(basename $0)"
	exit 0
elif [ $ID -eq 0 -o ! -d /home/$NORMALUSER/ ]; then
	echo Please chroot into \"$CHROOT\" and su to \"$NORMALUSER\".
	exit 1
fi

# real script to run in chroot environment

mkdir -p /home/$NORMALUSER/${DISTRO}-kernel
cd $_
git init
git svn --prefix=svn/ init -T dists/sid/linux -t releases/linux svn://svn.debian.org/kernel
# r21785 is release of 3.16.2-1. Refer: http://anonscm.debian.org/viewvc/kernel/releases/linux/
git svn fetch -r21785:HEAD
git checkout -b linux_3.16.7-ckt2-1bpo70 svn/tags/3.16.7-ckt2-1%7Ebpo70+1
(cd ..; wget -c $MIRROR/pool/main/l/linux/linux_3.16.7-ckt2.orig.tar.xz)
sed -i "/compiler/s/gcc-4.6/gcc-4.4/" debian/config/defines
# if you meet "check size" issue, please try the cmd below
#sed -i "s/check-size: 2097080/#&/" debian/config/armel/defines
