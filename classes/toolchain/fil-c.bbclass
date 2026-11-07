# Fil-C as the cross toolchain (select with TOOLCHAIN = "fil-c").
#
# filcc/filcpp come from fil-c-native (prebuilt dist in the native sysroot,
# on PATH via STAGING_BINDIR_NATIVE). fil-c is clang-based, so the usual
# clang-style flags apply. Instead of OE's --sysroot, filcc gets its
# target libc/crt/includes from the pizfix tree of the dist matching the
# target arch, installed by fil-c-native as the cross resource dir.

FILC_NATIVE_PREFIX = "${STAGING_DIR_NATIVE}${prefix_native}/share/filc"
FILC_TARGET_PIZFIX = "${FILC_NATIVE_PREFIX}/pizfix-${TRANSLATED_TARGET_ARCH}"

# musl triple: the pizfix resource dir provides musl libc/crt/ld-fil1, so
# the driver must not look for glibc bits (/lib/libc.so.6, libc_nonshared.a)
# note: -L for the pizfix lib must come before the OE target libdir, or ld
# picks up glibc's libc.so linker script from the target sysroot and links
# against the host's /lib/libc.so.6. The OE target include dir is added with
# -idirafter (not --filc-os-include) so musl/pizfix headers win for standard
# headers and the glibc dir only supplies kernel headers (linux/, asm/).
TOOLCHAIN_OPTIONS = " --target=${TRANSLATED_TARGET_ARCH}-linux-musl --filc-resource-dir=${FILC_TARGET_PIZFIX} -I${FILC_NATIVE_PREFIX}/include-shim -idirafter ${STAGING_DIR_TARGET}/usr/include -L${FILC_TARGET_PIZFIX}/lib -L${STAGING_DIR_TARGET}${libdir} -L${STAGING_DIR_TARGET}/lib -Wl,-rpath-link,${STAGING_DIR_TARGET}${libdir} -Wl,-rpath-link,${STAGING_DIR_TARGET}/lib --ld-path=${STAGING_BINDIR_TOOLCHAIN}/${TARGET_PREFIX}ld.bfd -Wno-unused-command-line-argument"

CC = "${CCACHE}filcc ${HOST_CC_ARCH}${TOOLCHAIN_OPTIONS}"
# note: fil++ is the C++ driver; filcpp only preprocesses
CXX = "${CCACHE}fil++ ${HOST_CC_ARCH}${TOOLCHAIN_OPTIONS}"
CPP = "${CCACHE}filcc ${HOST_CC_ARCH}${TOOLCHAIN_OPTIONS} -E"
CCLD = "${CCACHE}filcc ${HOST_CC_ARCH}${TOOLCHAIN_OPTIONS}"
# LD is the raw GNU ld.bfd, not filcc: libtool's configure probes run
# "$LD --version" / "$LD -v" to detect GNU ld (with_gnu_ld) and whether
# shared libraries are supported; filcc prints a clang version string
# there, which made libtool conclude with_gnu_ld=no and silently link
# only static libs (archive_cmds=""). Actual linking goes through CC/CCLD
# (filcc), which drives ld.bfd via --ld-path.
LD = "${HOST_PREFIX}ld.bfd ${HOST_LD_ARCH}"

# no llvm binutils in the fil-c dist: reuse the cross binutils for the rest
AR = "${HOST_PREFIX}ar"
AS = "${HOST_PREFIX}as ${HOST_AS_ARCH}"
RANLIB = "${HOST_PREFIX}ranlib"
STRIP = "${HOST_PREFIX}strip"
OBJCOPY = "${HOST_PREFIX}objcopy"
OBJDUMP = "${HOST_PREFIX}objdump"
STRINGS = "${HOST_PREFIX}strings"
NM = "${HOST_PREFIX}nm"
READELF = "${HOST_PREFIX}readelf"

# make sure the fil-c build tool and the cross binutils it drives (ar via
# AR, ld.bfd via --ld-path) are in the sysroot before compiling. The
# cross-binutils dep is skipped for special TARGET_ARCH contexts
# (buildtools-tarball uses none, allarch recipes use allarch) where it would
# resolve to unbuildable binutils-cross-none/-allarch.
FILC_EXTRA_DEPS = "${@'virtual/${MLPREFIX}cross-binutils' if d.getVar('TARGET_ARCH') not in ('none', 'allarch') else ''}"
DEPENDS:append:class-target = " fil-c-native ${FILC_EXTRA_DEPS}"
POPULATESYSROOTDEPS:append:class-target = " fil-c-native:do_populate_sysroot ${@d.getVar('FILC_EXTRA_DEPS') + ':do_populate_sysroot' if d.getVar('FILC_EXTRA_DEPS') else ''}"

# the compiler is a native build tool, not a target package
PREFERRED_PROVIDER_virtual/${MLPREFIX}cross-cc = "fil-c-native"
PREFERRED_PROVIDER_virtual/${MLPREFIX}cross-c++ = "fil-c-native"
# runtime libs and the SDK toolchain stay on the gcc recipes
PREFERRED_PROVIDER_virtual/${MLPREFIX}compilerlibs = "gcc-runtime"
PREFERRED_PROVIDER_virtual/${MLPREFIX}cross-cc:class-nativesdk = "gcc-crosssdk-${SDK_SYS}"
PREFERRED_PROVIDER_virtual/${MLPREFIX}cross-c++:class-nativesdk = "gcc-crosssdk-${SDK_SYS}"
PREFERRED_PROVIDER_virtual/${MLPREFIX}compilerlibs:class-nativesdk = "nativesdk-gcc-runtime"
PREFERRED_PROVIDER_virtual/nativesdk-cross-cc:class-crosssdk = "gcc-crosssdk-${SDK_SYS}"
PREFERRED_PROVIDER_virtual/nativesdk-cross-c++:class-crosssdk = "gcc-crosssdk-${SDK_SYS}"
PREFERRED_PROVIDER_virtual/nativesdk-compilerlibs:class-crosssdk = "nativesdk-gcc-runtime"
PREFERRED_PROVIDER_virtual/nativesdk-cross-cc:class-cross-canadian = "gcc-crosssdk-${SDK_SYS}"
PREFERRED_PROVIDER_virtual/nativesdk-cross-c++:class-cross-canadian = "gcc-crosssdk-${SDK_SYS}"
PREFERRED_PROVIDER_virtual/nativesdk-compilerlibs:class-cross-canadian = "nativesdk-gcc-runtime"

# wrynose's default LDFLAGS has -fuse-ld=bfd, which conflicts with the
# --ld-path we pass in TOOLCHAIN_OPTIONS ("invalid linker name")
LDFLAGS:remove:toolchain-fil-c = "-fuse-ld=bfd"

TCOVERRIDE = "toolchain-fil-c"

# fil-c binaries bake the build-sysroot pizfix path as RPATH (rewritten to
# /opt/filc/... at image time by the core-image-minimal filc_rootfs_fixup
# postprocess), NEED the pizfix musl libc.so/libpizlo.so (no glibc provider
# exists), and embed build paths. Skip the corresponding QA checks for
# target recipes built with fil-c.
INSANE_SKIP:append:class-target = " rpaths file-rdeps buildpaths"

# meson's meson-qemuwrapper points qemu's LD_LIBRARY_PATH at the glibc target
# sysroot, so a fil-c sanity-check binary loads glibc's libc.so instead of
# the pizfix musl ("Exec format error" / missing pizlonated_* symbols).
# Override write_qemuwrapper (meson.bbclass) for ALL meson target recipes so
# the pizfix lib dir comes first in LD_LIBRARY_PATH.
write_qemuwrapper:class-target() {
    if [ "${TOOLCHAIN}" != "fil-c" ]; then
        return
    fi
    qemu_binary="${@qemu_wrapper_cmdline(d, '${STAGING_DIR_HOST}', ['${FILC_TARGET_PIZFIX}/lib','${STAGING_LIBDIR}','${STAGING_BASELIBDIR}'])}"
    cat > ${WORKDIR}/meson-qemuwrapper << EOF
#!/bin/sh
export GIO_MODULE_DIR=${STAGING_LIBDIR}/gio/modules-dummy
unset LD_LIBRARY_PATH

$qemu_binary "\$@"
EOF
    chmod +x ${WORKDIR}/meson-qemuwrapper
}
