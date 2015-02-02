# debian-kernel-cross
Cross compile Debian kernel in chroot environment, start from armel for jessie


----
Purpose
----

To make a chroot cross build environment especially for kerenel under Debian.
Currently working for Jessie on armel (kirkwood).


----
Howto
----

Step0, make a chroot environment. The script will debootstrap a minimal rootfs for cross compiling.
2_chroot_build-deb.sh  chroot_roger  chroot_shell.sh

	./0_mkchroot.sh

Step1, get source code from Debian Kernel SCM. You could either choose to run this out-of or within chroot

	./1_chroot_get-source.sh

	or

	./chroot_shell.sh
	/debian-kernel-cross/jessie/1_chroot_get-source.sh

Step2, cross compile. You could either choose to run this out-of or within chroot.

	./2_chroot_build-deb.sh

	or

	./chroot_shell.sh
	/debian-kernel-cross/jessie/2_chroot_build-deb.sh

If something goes wrong, you can check up the Step2 script and start from the the blocked command again.


----
Status
----

The cross compiled armel kernel is confirmed to working on:

 - LS-WXL (Debian Jessie, with own kernel DTB)
 - LS-WSXL (Debian Jessie, with own kernel DTB)


----
Credit
----

- http://kernel-handbook.alioth.debian.org/
