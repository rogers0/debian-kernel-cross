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

	cd ~/${DISTRO}-kernel
	export DEB_BUILD_OPTIONS=parallel=7
	git clean -fd
	fakeroot debian/rules clean
	fakeroot debian/rules orig
	fakeroot make -f debian/rules.gen setup_armel_none_kirkwood
	fakeroot make -f debian/rules.gen binary-arch_armel_none_kirkwood binary-indep

fi
