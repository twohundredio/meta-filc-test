# Fil-C port for busybox: not_const_pp inline-asm fix (see patch).
# vfork is not declared by the pizfix musl and fil-c pizlonates the call so
# it cannot link to libyoloc; map vfork to fork (the xvfork branch is dead
# on MMU systems anyway).
FILESEXTRAPATHS:prepend:class-target := "${THISDIR}/files:"
SRC_URI:append:class-target = " file://filc-0001-fil-c-port.patch"
# route the libc wrappers that are still "bad syscall" stubs in fil-c 0.687's
# usermusl (sethostname/klogctl/clock_settime/settimeofday) to the zsys_*
# implementations that exist in libpizlo - fixes the boot-time filc panics
# from hostname.sh/dmesg.sh/hwclock.sh
SRC_URI:append:class-target += " file://filc-0002-zsys-syscalls.patch"
CFLAGS:append:class-target = " -Dvfork=fork"

# busybox Makefile hardcodes LD = $(CC) -nostdlib, and filcc -r still links
# filc_mincrt.o (defines main) even with -nostdlib, colliding with busybox
# main at the final link. Use the raw cross ld for kbuild -r partial links.
EXTRA_OEMAKE:append:class-target = " LD=${HOST_PREFIX}ld.bfd"
