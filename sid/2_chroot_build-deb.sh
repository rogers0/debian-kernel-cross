#!/bin/sh

SCRIPT_ROOT=$(readlink -f $(dirname $0))
SRC_ROOT=$(readlink -f $(dirname $0)/..)

. $SCRIPT_ROOT/config_common
[ -e "$SCRIPT_ROOT/config" ] && . $SCRIPT_ROOT/config
[ -e "$SCRIPT_ROOT/config_local" ] && . $SCRIPT_ROOT/config_local

if [ $LOCAL_UID -eq 0 -a -d $CHROOT ]; then
# chroot and run this script again
	$SCRIPT_ROOT/chroot_shell.sh prepare
	echo chroot $CHROOT su $NORMALUSER -c "~/$(basename $SRC_ROOT)/$(basename $SCRIPT_ROOT)/$(basename $0)"
	chroot $CHROOT su $NORMALUSER -c "~/$(basename $SRC_ROOT)/$(basename $SCRIPT_ROOT)/$(basename $0)"
	#echo you need to run \"./umount_chroot_device.sh\" to release some chrooted device mounting after finishing all chroot shells.
	$SCRIPT_ROOT/umount_chroot_device.sh
	exit 0
elif [ $LOCAL_UID -eq 0 -o ! -d /$NORMALUSER/ ]; then
	echo Please chroot into \"$CHROOT\" and su to \"$NORMALUSER\".
	exit 1
fi

# real script to run in chroot environment
DEB_KERNEL_GIT=/$(basename $DEB_KERNEL_DIR).git
LINUX_GIT=/$(basename $LINUX_DIR).git

if [ -d $DEB_KERNEL_PATH ]; then
	cd $DEB_KERNEL_PATH
	export PATH=/usr/lib/ccache:$PATH
	export $(dpkg-architecture -a$HOST_ARCH)
	export DEB_BUILD_PROFILES="cross nocheck nopython nodoc pkg.linux.notools"
	export MAKEFLAGS="-j$(($(nproc)*2))"
	echo DEB_BUILD_PROFILES=$DEB_BUILD_PROFILES
	echo MAKEFLAGS=$MAKEFLAGS
	# only possible when distribution="UNRELEASED" in d/changelog
	export DEBIAN_KERNEL_DISABLE_DEBUG=
	[ "$(dpkg-parsechangelog --show-field Distribution)" = "UNRELEASED" ] &&
		export DEBIAN_KERNEL_DISABLE_DEBUG=yes

	mkdir -p ../log
	fakeroot debian/rules clean 2>&1 | tee -a ../log/0_clean.txt
	fakeroot debian/rules orig 2>&1 | tee -a ../log/1_orig.txt
	fakeroot make -f debian/rules.gen setup_${HOST_ARCH} 2>&1 | tee -a ../log/2_setup.txt

	# tentative hack for building udeb
	sed -i 's/binary-arch_armel:: binary-arch_armel_extra binary-arch_armel_none binary-arch_armel_real/binary-arch_armel:: binary-arch_armel_extra binary-arch_armel_none/' debian/rules.gen

	date > ../log/3_binary.txt
	fakeroot make -f debian/rules.gen binary-arch_${HOST_ARCH} 2>&1 | tee -a ../log/3_binary.txt
	date >> ../log/3_binary.txt
	start=$(head -n1 ../log/3_binary.txt)
	end=$(tail -n1 ../log/3_binary.txt)
	echo Start: $start
	echo \ End\ : $end
	echo Build took $((($(date -d "$end" +%s)-$(date -d "$start" +%s)+30)/60)) min.

	#fakeroot make -f debian/rules.gen binary-indep 2>&1 | tee -a ../log/4_indep.txt
fi
