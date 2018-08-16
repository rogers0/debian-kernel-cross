#!/bin/sh

SCRIPT_ROOT=$(readlink -f $(dirname $0))
SRC_ROOT=$(readlink -f $(dirname $0)/..)

. $SCRIPT_ROOT/config_common
[ -e "$SCRIPT_ROOT/config" ] && . $SCRIPT_ROOT/config
[ -e "$SCRIPT_ROOT/config_local" ] && . $SCRIPT_ROOT/config_local
LOCAL_HOME=$(eval echo ~$(id -nu $LOCAL_UID 2>/dev/null))

[ $LOCAL_UID -gt 0 ] && echo Please use root or sudo environment. && exit 1

if [ -z "$1" ]; then
# init and then chroot

	[ -d $CHROOT ] && echo Target folder: $CHROOT already exists. && exit 1
	wget -nv -O /tmp/$DEBOOTSTRAP_DEB $MIRROR$DEBOOTSTRAP_PATH/$DEBOOTSTRAP_DEB
	dpkg -i $DPKG_DEBOOTSTRAP_OPT /tmp/$DEBOOTSTRAP_DEB
	rm /tmp/$DEBOOTSTRAP_DEB

	mkdir -p $CHROOT/etc/default $CHROOT/$NORMALUSER
	echo en_US.UTF-8 UTF-8 > $CHROOT/etc/locale.gen
	echo LANG=en_US.UTF-8 > $CHROOT/etc/default/locale
	[ -f /etc/timezone ] && cp -a /etc/timezone $CHROOT/etc
	echo cdebootstrap-static --flavour=minimal --include=apt,apt-utils,vim,whiptail,wget,ssh,rsync,screen,less,locales,tzdata $DISTRO $CHROOT $MIRROR
	cdebootstrap-static --flavour=minimal --include=apt,apt-utils,vim,whiptail,wget,ssh,rsync,screen,less,locales,tzdata $DISTRO $CHROOT $MIRROR
	echo >> $CHROOT/$NORMALUSER/.bashrc
	[ -n "$http_proxy" ] &&
		echo export http_proxy=$http_proxy >> $CHROOT/$NORMALUSER/.bashrc
	[ -n "$no_proxy" ] &&
		echo export no_proxy=$no_proxy >> $CHROOT/$NORMALUSER/.bashrc
	echo 'export PATH=/usr/lib/ccache:$PATH' >> $CHROOT/$NORMALUSER/.bashrc
	cp -a $SRC_ROOT $CHROOT
	echo chroot $CHROOT /$(basename $SRC_ROOT)/$(basename $SCRIPT_ROOT)/$(basename $0) chrooted
	chroot $CHROOT /$(basename $SRC_ROOT)/$(basename $SCRIPT_ROOT)/$(basename $0) chrooted
	mv $CHROOT/$(basename $SRC_ROOT) $CHROOT/$NORMALUSER
	GITCONF=$(find ~ -maxdepth 2 -name .gitconfig|head -n1)
	[ -n "$GITCONF" -a -e "$GITCONF" ] && cp $GITCONF $CHROOT/$NORMALUSER
	chown -R $NORMALUSER_UID.$NORMALUSER_UID $CHROOT/$NORMALUSER

elif [ "$1" = "chrooted" ]; then
# script to run in chroot environment

	echo "deb ${MIRROR} ${DISTRO} main contrib non-free" > /etc/apt/sources.list
	if [ "${DISTRO}" != "sid" -a "${DISTRO}" != "unstable" -a "${DISTRO}" != "testing" ]; then
		echo "deb ${MIRROR} ${DISTRO}-backports main contrib non-free" >> /etc/apt/sources.list
		echo "deb ${MIRROR} ${DISTRO}-backports-sloppy main contrib non-free" >> /etc/apt/sources.list
	fi
	echo "deb http://security.debian.org ${DISTRO}/updates main contrib non-free" >> /etc/apt/sources.list
	echo APT::Install-Recommends \"false\"\; >> /etc/apt/apt.conf
	[ -n "$http_proxy" ] &&
		echo Acquire::http::Proxy \"$http_proxy\"\; >> /etc/apt/apt.conf
	[ -n "$APT_NO_PROXY" ] &&
		echo Acquire::http::Proxy::$APT_NO_PROXY DIRECT\; >> /etc/apt/apt.conf
	[ -n "$HOST_ARCH" ] && dpkg --add-architecture $HOST_ARCH

	apt-get update
	apt-get install -y debhelper devscripts xmlto kernel-wedge fakeroot gcc bc cpio debian-keyring fakeroot libfile-fcntllock-perl quilt python-debian python-six patchutils flex bison libssl-dev ccache mount dh-exec kmod bash-completion
	if [ "x$HOST_ARCH" = "xarmel" ]; then
		CROSS_DEB="build-essential dpkg-cross crossbuild-essential-armel binutils-arm-linux-gnueabi"
	elif [ "x$HOST_ARCH" = "xarmhf" ]; then
		CROSS_DEB="build-essential dpkg-cross crossbuild-essential-armhf binutils-arm-linux-gnueabihf"
	elif [ "x$HOST_ARCH" = "xarm64" ]; then
		CROSS_DEB="build-essential dpkg-cross crossbuild-essential-arm64 binutils-aarch64-linux-gnu"
	fi
	echo apt-get install -y $CROSS_DEB
	apt-get install -y $CROSS_DEB
	apt-get install -y git-email ca-certificates
	apt-get upgrade -y
	apt-get clean

	useradd -d /$NORMALUSER -ms /bin/bash -u $NORMALUSER_UID $NORMALUSER

fi
