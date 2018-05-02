# debian-kernel-cross
Cross compile Debian kernel in chroot environment, start from armel for stretch/sid


----
Purpose
----

To make a chroot cross build environment especially for kerenel under Debian.
Currently working for Stretch/Sid on armel (marvell).


----
Howto
----

Step0, make a chroot environment. The script will debootstrap a minimal rootfs for cross compiling.

	$ sudo ./0_mkchroot.sh

Step1, get source code from Debian Kernel SCM. You could either choose to run this out-of or within chroot

	$ sudo ./1_chroot_get-source.sh

	or

	$ sudo ./chroot_shell.sh
	## Below is under chroot environment
	$ ./debian-kernel-cross/sid/1_chroot_get-source.sh

Step2, cross compile. You could either choose to run this out-of or within chroot.

	$ sudo ./2_chroot_build-deb.sh

	or

	$ sudo ./chroot_shell.sh
	## Below is under chroot environment
	$ ./debian-kernel-cross/sid/2_chroot_build-deb.sh

If something goes wrong, you can check up the Step2 script and start from the the blocked command again.


----
Status
----

The cross compiled armel kernel is confirmed to working on:

 - LS-WXL (Debian Stretch)
 - LS-WSXL (Debian Stretch)
 - LS-VL (Debian Stretch)
 - LS-WVL (Debian Stretch)


----
Credit
----

- https://kernel-handbook.debian.net
