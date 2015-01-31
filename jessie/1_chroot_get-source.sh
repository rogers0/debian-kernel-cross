#/bin/bash

SCRIPT_ROOT=$(readlink -f $(dirname $0))
SRC_ROOT=$(readlink -f $(dirname $0)/..)

. $SCRIPT_ROOT/config

if [ -z "$1" ]; then
# chroot and run this script again

	cp -a $SRC_ROOT $CHROOT
	chroot $CHROOT su $NORMALUSER -c "/$(basename $SRC_ROOT)/$(basename $SCRIPT_ROOT)/$(basename $0) chrooted"

elif [ "$1" = "chrooted" ]; then
# real script to run in chroot environment

	mkdir -p ~/${DISTRO}-kernel
	cd $_
	git init
	git svn --prefix=svn/ init -T dists/sid/linux -t releases/linux svn://svn.debian.org/kernel
	# r21785 is release of 3.16.2-1. Refer: http://anonscm.debian.org/viewvc/kernel/releases/linux/
	git svn fetch -r21785:HEAD
	git checkout -b linux_3.16.7-ckt2-1 svn/tags/3.16.7-ckt2-1
	(cd ..; wget -c $MIRROR/pool/main/l/linux/linux_3.16.7-ckt2.orig.tar.xz)
	sed -i "/compiler/s/gcc-4.8/gcc-4.9/" debian/config/defines
	sed -i "/gcc-4.8: gcc-4.8/agcc-4.9: gcc-4.9" debian/config/defines

fi