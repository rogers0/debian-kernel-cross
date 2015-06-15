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

cd $KERNEL_PATH
git clean -fd
touch ../build_begin.txt

export XZ_DEFAULTS=-7   # limit memory usage
LOCAL_INST=../local_install
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- mrproper
[ -e ../config ] && cp -a ../config .config
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- oldconfig
[ ! -e ../config ] && cp -a .config ../config
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j$PARALLEL zImage modules 2>&1 | tee log.0_zImage_modules
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- dtbs 2>&1 | tee log.1_zImage_modules
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- modules_install INSTALL_MOD_PATH=$LOCAL_INST 2>&1 | tee log.2_modules_install
mkdir -p $LOCAL_INST/boot $LOCAL_INST/dtbs
cp -a arch/arm/boot/zImage $LOCAL_INST/boot/vmlinuz-`cat include/config/kernel.release`
cp -a arch/arm/boot/dts/*.dtb $LOCAL_INST/dtbs/

touch ../build_end_binary.txt
