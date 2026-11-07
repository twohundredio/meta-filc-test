SUMMARY = "A portable foreign function interface library"
HOMEPAGE = "http://sourceware.org/libffi/"
DESCRIPTION = "The \`libffi' library provides a portable, high level programming interface to various calling \
conventions.  This allows a programmer to call any function specified by a call interface description at run \
time. FFI stands for Foreign Function Interface.  A foreign function interface is the popular name for the \
interface that allows code written in one language to call code written in another language.  The \`libffi' \
library really only provides the lowest, machine dependent layer of a fully featured foreign function interface.  \
A layer must exist above \`libffi' that handles type conversions for values passed between the two languages."

# 3.8.0 with the upstream Fil-C port (FFI_FILC ABI: no hand-written asm
# under __FILC__, aarch64 marshalling in C, -Wc,--version-script=) so it
# builds with TOOLCHAIN = "fil-c"; soname stays libffi.so.8.
# The fil-c patch is class-target only: *-native builds use the host gcc.

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=5e9a8df556846bb3d1edec0d968a2311"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "${GITHUB_BASE_URI}/download/v${PV}/${BPN}-${PV}.tar.gz \
           file://not-win32.patch \
           "
SRC_URI[sha256sum] = "7da3e2d9a171eb0a038f592ecad3ff2bb2550f3496d87b3b29ad0cf4430c0db4"

# the Fil-C port only applies to target builds (gcc native/nativesdk must
# not see the __FILC__ code paths)
SRC_URI:append:class-target = " file://filc-0001-fil-c-port.patch"

EXTRA_OECONF = "--disable-builddir --disable-exec-static-tramp"
EXTRA_OECONF:class-native += "--with-gcc-arch=generic"
EXTRA_OEMAKE:class-target = "LIBTOOLFLAGS='--tag=CC'"

inherit autotools texinfo multilib_header github-releases

do_install:append() {
	oe_multilib_header ffi.h ffitarget.h
}

# Doesn't compile in MIPS16e mode due to use of hand-written
# assembly
MIPS_INSTRUCTION_SET = "mips"

BBCLASSEXTEND = "native nativesdk"
