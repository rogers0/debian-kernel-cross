#!/bin/sh

SCRIPT_ROOT=$(readlink -f $(dirname $0))
SRC_ROOT=$(readlink -f $(dirname $0)/..)

. $SCRIPT_ROOT/config_common
[ -e "$SCRIPT_ROOT/config" ] && . $SCRIPT_ROOT/config
[ -e "$SCRIPT_ROOT/config_local" ] && . $SCRIPT_ROOT/config_local

if [ $LOCAL_UID -eq 0 -a -d $CHROOT ]; then
# chroot and run this script again
	if [ ! -d "$DEB_KERNEL_DIR/.git" ]; then
		echo git clone -n $DEB_KERNEL_REPO $DEB_KERNEL_DIR
		git clone -n $DEB_KERNEL_REPO $DEB_KERNEL_DIR
	fi
	(cd $DEB_KERNEL_DIR; echo -n Repo $(basename $DEB_KERNEL_DIR):\ ; git fetch --all)
	if [ ! -d "$LINUX_DIR/.git" ]; then
		echo git clone -n $LINUX_REPO $LINUX_DIR
		git clone -n $LINUX_REPO $LINUX_DIR
		(cd $LINUX_DIR;
		[ -n "$UBUNTU_REPO" ] && git remote add ubuntu $UBUNTU_REPO;
		[ -n "$LINUX_STABLE_REPO" ] && git remote add stable $LINUX_STABLE_REPO)
	fi
	(cd $LINUX_DIR; echo -n Repo $(basename $LINUX_DIR):\ ; git fetch --all)
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

if [ ! -d "$DEB_KERNEL_PATH" ]; then
	echo git clone --reference $DEB_KERNEL_GIT $DEB_KERNEL_REPO $DEB_KERNEL_PATH
	git clone --reference $DEB_KERNEL_GIT $DEB_KERNEL_REPO $DEB_KERNEL_PATH
fi
if [ -d "$DEB_KERNEL_PATH" ]; then
	cd $DEB_KERNEL_PATH
	git fetch --all
fi
git checkout $DEB_KERNEL_BRANCH
DEB_KERNEL_VER=$(dpkg-parsechangelog -SVersion|sed -e 's/-[^-]*$//')
DEB_KERNEL_FILE=linux_${DEB_KERNEL_VER}.orig.tar.xz
[ -e ../$DEB_KERNEL_FILE ] || (cd ..; wget -t3 -c $MIRROR/pool/main/l/linux/$DEB_KERNEL_FILE)
[ -e ../$DEB_KERNEL_FILE ] || debian/bin/genorig.py $LINUX_GIT

# if you meet "ABI changed" issue, please try the cmd below
#sed -i "/^abiname:./s/$/.test/" debian/config/defines
