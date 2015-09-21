#!/bin/bash

SCRIPT_ROOT=$(readlink -f $(dirname $0))
SRC_ROOT=$(readlink -f $(dirname $0)/..)
ID=$(id -u)

. $SCRIPT_ROOT/config
[ -e "$SCRIPT_ROOT/config_local" ] && . $SCRIPT_ROOT/config_local

if [ $ID -eq 0 -a -d $CHROOT ]; then
# chroot and run this script again
	if [ ! -d "$LOCAL_HOME/$DEB_KERNEL_DIR" ]; then
		git clone -n $DEB_KERNEL_REPO $LOCAL_HOME/$DEB_KERNEL_DIR
		(cd $LOCAL_HOME/$LINUX_DIR;
		echo -e \\\t'fetch = +refs/heads/*:refs/heads/*'\\\n\\\t'fetch = +refs/tags/*:refs/tags/*' >> .git/config)
	fi
	(cd $LOCAL_HOME/$DEB_KERNEL_DIR;
	git fetch --all)
	if [ ! -d "$LOCAL_HOME/$LINUX_DIR" ]; then
		git clone -n $LINUX_REPO $LOCAL_HOME/$LINUX_DIR
		(cd $LOCAL_HOME/$LINUX_DIR;
		echo -e \\\t'fetch = +refs/heads/*:refs/heads/*'\\\n\\\t'fetch = +refs/tags/*:refs/tags/*' >> .git/config;
		git remote add ubuntu $UBUNTU_REPO;
		echo -e \\\t'fetch = +refs/heads/*:refs/heads/*'\\\n\\\t'fetch = +refs/tags/*:refs/tags/*' >> .git/config)
	fi
	(cd $LOCAL_HOME/$LINUX_DIR;
	git fetch --all)
	$SCRIPT_ROOT/chroot_shell.sh prepare
	echo chroot $CHROOT su $NORMALUSER -c "/$(basename $SRC_ROOT)/$(basename $SCRIPT_ROOT)/$(basename $0)"
	chroot $CHROOT su $NORMALUSER -c "/$(basename $SRC_ROOT)/$(basename $SCRIPT_ROOT)/$(basename $0)"
	exit 0
elif [ $ID -eq 0 -o ! -d /$NORMALUSER/ ]; then
	echo Please chroot into \"$CHROOT\" and su to \"$NORMALUSER\".
	exit 1
fi

# real script to run in chroot environment

if [ ! -d "$KERNEL_PATH" ]; then
	echo git clone -n /${DEB_KERNEL_DIR}.git $KERNEL_PATH
	git clone -n /${DEB_KERNEL_DIR}.git $KERNEL_PATH
	cd $KERNEL_PATH
else
	cd $KERNEL_PATH
	git clean -fd
	git reset --hard
fi
git checkout -b $GIT_BRANCH $GIT_TAG || (git checkout --orphan ORPHAN; git branch -D $GIT_BRANCH; git checkout -fb $GIT_BRANCH $GIT_TAG)
#(cd ..; [ -n "$KERNEL_SRC" ] && wget -nv -c $MIRROR/pool/main/l/linux/${KERNEL_SRC})
[ -f "../linux_${DEB_KERNEL_VER}.orig.tar.xz" ] || debian/bin/genorig.py -V $DEB_KERNEL_VER /${LINUX_DIR}.git

sed -i "/^compiler:/s/gcc-4.6/gcc-4.4/" debian/config/defines
sed -i "/^compiler:/s/gcc-4.8/gcc-4.4/" debian/config/defines

# if you meet "ABI changed" issue, please try the cmd below
#sed -i "/^abiname:./s/$/.test/" debian/config/defines
# if you meet "check size" issue, please try the cmd below
#sed -i "s/check-size: 2097080/#&/" debian/config/armel/defines
