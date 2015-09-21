#!/bin/bash

SCRIPT_ROOT=$(readlink -f $(dirname $0))
SRC_ROOT=$(readlink -f $(dirname $0)/..)
ID=$(id -u)

. $SCRIPT_ROOT/config
[ -e "$SCRIPT_ROOT/config_local" ] && . $SCRIPT_ROOT/config_local

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
	GITCONF=`find /home -maxdepth 2 -name .gitconfig|head -n1`
	[ -n "$GITCONF" -a -e "$GITCONF" ] && cp -a $GITCONF $CHROOT/$NORMALUSER && chown $NORMALUSER_UID.$NORMALUSER_UID $CHROOT/$NORMALUSER/.gitconfig

elif [ "$1" = "chrooted" ]; then
# script to run in chroot environment

	echo "deb ${MIRROR}-lts squeeze main contrib non-free" >> /etc/apt/sources.list
	echo "deb http://www.emdebian.org/debian squeeze main" >> /etc/apt/sources.list
	echo "deb ${MIRROR}-backports squeeze-backports main contrib non-free" >> /etc/apt/sources.list
	echo "deb ${MIRROR}-backports squeeze-backports-sloppy main contrib non-free" >> /etc/apt/sources.list
	echo "deb http://security.debian.org ${DISTRO}/updates main contrib non-free" >> /etc/apt/sources.list

	mkdir -p ~/.aptitude
	echo 'Apt::Install-Recommends "false";' > ~/.aptitude/config

	aptitude update
	aptitude install -y debhelper devscripts xmlto kernel-wedge fakeroot gcc bc cpio debian-keyring fakeroot git-svn libfile-fcntllock-perl quilt emdebian-archive-keyring python-support xz-lzma
	if [ "x$HOST_ARCH" = "xarmel" ]; then
		CROSS_DEB="build-essential dpkg-cross g++-4.3-arm-linux-gnueabi binutils-arm-linux-gnueabi"
	fi
	echo aptitude install -y $CROSS_DEB
	aptitude install -y $CROSS_DEB
	aptitude clean

	useradd -b / -ms /bin/bash -u $NORMALUSER_UID $NORMALUSER

fi
