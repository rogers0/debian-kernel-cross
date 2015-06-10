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
elif [ $ID -eq 0 -o ! -d /$NORMALUSER/ ]; then
	echo Please chroot into \"$CHROOT\" and su to \"$NORMALUSER\".
	exit 1
fi

# real script to run in chroot environment

if [ ! -d $KERNEL_PATH ]; then
	mkdir $KERNEL_PATH
	cd $_
	git init
	git svn --prefix=svn/ init -T dists/sid/linux -t releases/linux svn://svn.debian.org/kernel
	# r21785 is release of 3.16.2-1. Refer: http://anonscm.debian.org/viewvc/kernel/releases/linux/
	git svn fetch -r21785:HEAD
else
	cd $KERNEL_PATH
fi
git clean -fd
git reset --hard
git checkout -b $GIT_BRANCH $GIT_TAG || (git checkout --orphan ORPHAN; git branch -D $GIT_BRANCH; git checkout -fb $GIT_BRANCH $GIT_TAG)
(cd ..; [ -n "$KERNEL_SRC" ] && wget -nv -c $MIRROR/pool/main/l/linux/${KERNEL_SRC})

sed -i "/^compiler:/s/gcc-4.8/gcc-4.9/" debian/config/defines
sed -i "/^gcc-4.8: gcc-4.8$/agcc-4.9: gcc-4.9" debian/config/defines

# if you meet "ABI changed" issue, please try the cmd below
#sed -i "/^abiname:./s/$/.test/" debian/config/defines
# if you meet "check size" issue, please try the cmd below
#sed -i "s/check-size: 2097080/#&/" debian/config/armel/defines
