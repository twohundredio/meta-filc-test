SUMMARY = "Fil-C target runtime (pizfix tree) for running fil-c-compiled binaries"
DESCRIPTION = "Installs the target-arch pizfix tree (musl libc, ld-fil1 loader, \
libpizlo/libyoloc runtime) from the prebuilt fil-c dist into the image at \
/opt/filc/pizfix-<target-arch>, so binaries compiled with filcc can run under \
qemu. The cross pizfix is produced by fil-c-native (it downloads the dist \
matching the image's target arch)."
HOMEPAGE = "https://fil-c.org/"
LICENSE = "Apache-2.0-with-LLVM-exception & BSD-2-Clause & MIT"
# no SRC_URI, so no LIC_FILES_CHKSUM; the license texts ship inside the
# pizfix tree itself (copied verbatim from the fil-c dist)

# the runtime content comes from the fil-c-native build tool's sysroot
DEPENDS = "fil-c-native"

FILC_RT_PREFIX = "/opt/filc"
FILC_PIZFIX = "pizfix-${TRANSLATED_TARGET_ARCH}"

do_configure[noexec] = "1"
do_compile[noexec] = "1"

do_install() {
    install -d ${D}${FILC_RT_PREFIX}
    # NB: plain cp -r, not cp -a: the native sysroot files are owned by the
    # build user, and preserving that ownership breaks do_package's sstate
    # ownership check. Under fakeroot plain cp creates root-owned files.
    cp -r ${STAGING_DIR_NATIVE}${prefix_native}/share/filc/${FILC_PIZFIX} \
        ${D}${FILC_RT_PREFIX}/
}

FILES:${PN} = "${FILC_RT_PREFIX}/${FILC_PIZFIX}"

# the pizfix tree contains foreign-arch (target) binaries the host strip
# cannot parse, and private sonames that must not be resolved to packages
INHIBIT_PACKAGE_STRIP = "1"
INHIBIT_SYSROOT_STRIP = "1"
# the pizfix tree intentionally ships .a libs, .so symlinks and unversioned
# loader .so files alongside the runtime libs
INSANE_SKIP:${PN} += "already-stripped file-rdeps buildpaths staticdev dev-so"

# fil-c binaries' rpm metadata requires rtld(GNU_HASH); without a provider
# in this package the solver pulls glibc's libc6 into the image just to
# satisfy it. The pizfix ld-fil1 loader provides rtld(GNU_HASH), so claim it.
RPROVIDES:${PN} += "rtld(GNU_HASH)"
