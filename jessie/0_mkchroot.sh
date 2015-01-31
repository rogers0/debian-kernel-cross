#!/bin/bash

SCRIPT_ROOT=$(readlink -f $(dirname $0))
SRC_ROOT=$(readlink -f $(dirname $0)/..)

DEBOOTSTRAP_DEB=cdebootstrap-static_0.6.4_amd64.deb
DEBOOTSTRAP_PATH=/pool/main/c/cdebootstrap

. $SCRIPT_ROOT/config

if [ -z "$1" ]; then
# init and then chroot

	wget -nv -O /tmp/$DEBOOTSTRAP_DEB $MIRROR$DEBOOTSTRAP_PATH/$DEBOOTSTRAP_DEB
	dpkg -i $DPKG_DEBOOTSTRAP_OPT /tmp/$DEBOOTSTRAP_DEB
	rm /tmp/$DEBOOTSTRAP_DEB

	mkdir -p $CHROOT/etc/default
	echo en_US.UTF-8 UTF-8 > $CHROOT/etc/locale.gen
	echo LANG=en_US.UTF-8 > $CHROOT/etc/default/locale
	cdebootstrap-static --flavour=minimal --include=aptitude,apt-utils,vim-nox,whiptail,wget,ssh,rsync,screen,less,dialog,locales jessie $CHROOT $MIRROR
	cp -a $SRC_ROOT $CHROOT
	chroot $CHROOT /$(basename $SRC_ROOT)/$(basename $SCRIPT_ROOT)/$(basename $0) chrooted

elif [ "$1" = "chrooted" ]; then
# script to run in chroot environment

	echo "deb http://www.emdebian.org/tools/debian jessie main" >> /etc/apt/sources.list
	wget -nv -O - http://emdebian.org/tools/debian/emdebian-toolchain-archive.key | apt-key add -
	mkdir -p ~/.aptitude
	echo 'Apt::Install-Recommends "false";' > ~/.aptitude/config
	[ -n "$HOST_ARCH" ] && dpkg --add-architecture $HOST_ARCH

	aptitude update
	aptitude install -y debhelper devscripts xmlto kernel-wedge python-six fakeroot gcc python3-debian git quilt bc cpio debian-keyring fakeroot git-svn
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

	useradd -ms /bin/bash $NORMALUSER

fi
