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

if [ ! -d "$KERNEL_PATH" ]; then
	echo git clone -n $GIT_REPO $KERNEL_PATH
	git clone -n $GIT_REPO $KERNEL_PATH
	cd $KERNEL_PATH
else
	cd $KERNEL_PATH
	git clean -fd
	git reset --hard
fi
git checkout -b $GIT_BRANCH $GIT_TAG || (git checkout --orphan ORPHAN; git branch -D $GIT_BRANCH; git checkout -fb $GIT_BRANCH $GIT_TAG)
(cd ..; [ -n "$KERNEL_SRC" ] && wget -nv -c $MIRROR/pool/main/l/linux-2.6/${KERNEL_SRC})

echo
echo Example for how to continue in chroot environment:
echo -e \\t./chroot_shell.sh
echo -e \\tgit add -u \# add all updated files to index
echo -e \\tgit \#add -A \# add all new files to index to prevent being ereased by \"git clean -fd\" in script 2
echo -e \\tgit diff --cached
echo -e \\tlogout
echo -e \\t./2_chroot_build.sh
