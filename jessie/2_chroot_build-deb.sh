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

cd /home/$NORMALUSER/${DISTRO}-kernel
git clean -fd
export DEB_BUILD_OPTIONS="parallel=$PARALLEL"
touch ../build_begin.txt
fakeroot debian/rules clean 2>&1 | tee -a log_0_setup.txt
fakeroot debian/rules orig 2>&1 | tee -a log_0_setup.txt
fakeroot make -f debian/rules.gen setup_armel_none_kirkwood 2>&1 | tee -a log_0_setup.txt
fakeroot make -j$PARALLEL -f debian/rules.gen binary-arch_armel_none_kirkwood 2>&1 | tee -a log_1_binary.txt
touch ../build_end_binary.txt
fakeroot make -j$PARALLEL -f debian/rules.gen binary-indep 2>&1 | tee -a log_2_indep.txt
touch ../build_end_indep.txt
