#!/bin/bash

SCRIPT_ROOT=$(readlink -f $(dirname $0))
SRC_ROOT=$(readlink -f $(dirname $0)/..)
ID=$(id -u)

. $SCRIPT_ROOT/config

[ $ID -gt 0 ] && echo Please use root or sudo environment. && exit 1

if [ -z "$1" ]; then
# init and then chroot

	[ -d $CHROOT ] && echo Target folder: $CHROOT already exists. && exit 1
	wget -nv -O /tmp/$DEBOOTSTRAP_DEB $MIRROR$DEBOOTSTRAP_PATH/$DEBOOTSTRAP_DEB
	dpkg -i $DPKG_DEBOOTSTRAP_OPT /tmp/$DEBOOTSTRAP_DEB
	rm /tmp/$DEBOOTSTRAP_DEB

	mkdir -p $CHROOT/etc/default
	echo en_US.UTF-8 UTF-8 > $CHROOT/etc/locale.gen
	echo LANG=en_US.UTF-8 > $CHROOT/etc/default/locale
	echo cdebootstrap-static --flavour=minimal --include=aptitude,apt-utils,vim-nox,whiptail,wget,ssh,rsync,screen,less,dialog,locales $DISTRO $CHROOT $MIRROR
	cdebootstrap-static --flavour=minimal --include=aptitude,apt-utils,vim-nox,whiptail,wget,ssh,rsync,screen,less,dialog,locales $DISTRO $CHROOT $MIRROR
	cp -a $SRC_ROOT $CHROOT
	echo chroot $CHROOT /$(basename $SRC_ROOT)/$(basename $SCRIPT_ROOT)/$(basename $0) chrooted
	chroot $CHROOT /$(basename $SRC_ROOT)/$(basename $SCRIPT_ROOT)/$(basename $0) chrooted

elif [ "$1" = "chrooted" ]; then
# script to run in chroot environment

	echo "deb http://www.emdebian.org/tools/debian $DISTRO main" >> /etc/apt/sources.list
	echo "deb ${MIRROR} ${DISTRO}-backports main contrib non-free" >> /etc/apt/sources.list
	echo "deb ${MIRROR} ${DISTRO}-backports-sloppy main contrib non-free" >> /etc/apt/sources.list
	echo "deb http://security.debian.org ${DISTRO}/updates main contrib non-free" >> /etc/apt/sources.list
	wget -nv -O - http://emdebian.org/tools/debian/emdebian-toolchain-archive.key | apt-key add -
	mkdir -p ~/.aptitude
	echo 'Apt::Install-Recommends "false";' > ~/.aptitude/config
	[ -n "$HOST_ARCH" ] && dpkg --add-architecture $HOST_ARCH

	aptitude update
	aptitude install -y debhelper devscripts xmlto kernel-wedge fakeroot gcc bc cpio debian-keyring fakeroot git-svn libfile-fcntllock-perl quilt python-debian python-six patchutils
	if [ "x$HOST_ARCH" = "xarmel" ]; then
		CROSS_DEB="build-essential dpkg-cross crossbuild-essential-armel binutils-arm-linux-gnueabi"
	elif [ "x$HOST_ARCH" = "xarmhf" ]; then
		CROSS_DEB="build-essential dpkg-cross crossbuild-essential-armhf binutils-arm-linux-gnueabihf"
	elif [ "x$HOST_ARCH" = "xarm64" ]; then
		CROSS_DEB="build-essential dpkg-cross crossbuild-essential-arm64 binutils-aarch64-linux-gnu"
	fi
	echo aptitude install -y $CROSS_DEB
	aptitude install -y $CROSS_DEB
	aptitude clean

	useradd -b / -ms /bin/bash -u $NORMALUSER_UID $NORMALUSER

fi
