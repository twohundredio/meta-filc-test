SUMMARY = "Fil-C: memory-safe C/C++ compiler (prebuilt binary distribution)"
DESCRIPTION = "Fil-C is a fanatically compatible, completely memory safe \
implementation of C and C++ based on clang/LLVM. This recipe packages the \
official prebuilt pizfix binary distribution from \
https://github.com/pizlonator/fil-c/releases and installs it into the \
native sysroot, so it can be used as a build tool (e.g. via TOOLCHAIN = \
\"fil-c\", see classes/toolchain/fil-c.bbclass)."
HOMEPAGE = "https://fil-c.org/"
LICENSE = "Apache-2.0-with-LLVM-exception & BSD-2-Clause & MIT"
LIC_FILES_CHKSUM = " \
    file://LLVM-LICENSE.txt;md5=8a15a0759ef07f2682d2ba4b893c9afe \
    file://PAS-LICENSE.txt;md5=157771db8be728de2e76ebf468dbe3d6 \
    file://MUSL-LICENSE.txt;md5=b03f1cc25363d094011f8f4fd8bcfb68 \
"

# fil-c only ships Linux x86_64 and aarch64 builds
FILC_ARCH:aarch64 = "aarch64"
FILC_ARCH:x86-64 = "x86_64"
FILC_ARCH ?= "unsupported"

SRC_URI:aarch64 = "https://github.com/pizlonator/fil-c/releases/download/v${PV}/filc-${PV}-linux-aarch64.tar.xz;sha256sum=f1337799051664f93c7712141deaebe78571ae96ffcf05563d517b89440bcbc0"
SRC_URI:x86-64 = "https://github.com/pizlonator/fil-c/releases/download/v${PV}/filc-${PV}-linux-x86_64.tar.xz;sha256sum=aab538401f78a47ab261ee79afed8c6b99e1d4848e263ae159a75b03c1288da1"

# native build tool: also fetch the dist matching the image's target arch;
# its pizfix tree is what filcc uses as the cross resource dir. The image
# arch is not visible in native context (TRANSLATED_TARGET_ARCH is
# overridden to the build arch), so map it from MACHINE.
FILC_CROSS_DIST_ARCH = ""

python __anonymous() {
    if 'class-native' not in (d.getVar('CLASSOVERRIDE') or '').split():
        return
    machine = d.getVar('MACHINE') or ''
    dist = {'qemuarm64': 'aarch64', 'qemux86-64': 'x86_64'}.get(machine, '')
    sha = {'aarch64': 'f1337799051664f93c7712141deaebe78571ae96ffcf05563d517b89440bcbc0',
           'x86_64': 'aab538401f78a47ab261ee79afed8c6b99e1d4848e263ae159a75b03c1288da1'}.get(dist, '')
    if dist:
        d.setVar('FILC_CROSS_DIST_ARCH', dist)
        d.setVar('FILC_CROSS_PREFIX', {'qemuarm64': 'aarch64-poky-linux-'}.get(machine, ''))
        d.appendVar('SRC_URI', ' https://github.com/pizlonator/fil-c/releases/download/v%s/filc-%s-linux-%s.tar.xz;subdir=filc-cross;sha256sum=%s'
            % (d.getVar('PV'), d.getVar('PV'), dist, sha))
}

# cross binutils prefix of the image target (empty for target builds)
FILC_CROSS_PREFIX = ""

S = "${UNPACKDIR}/filc-${PV}-linux-${FILC_ARCH}"

DEPENDS += "patchelf-native"

# also build a native (host) variant: fil-c-native is a build tool living in
# the native sysroot, not something installed into the target image
BBCLASSEXTEND = "native"

do_configure[noexec] = "1"
do_compile[noexec] = "1"

# install prefix; the setup.sh-style patchelf below must use this runtime
# path, not ${D} (which points into the build tree). For class-native,
# ${prefix} already includes ${STAGING_DIR_NATIVE}, so the host tools get
# absolute rpaths into the native sysroot, which is where they execute from.
FILC_PREFIX = "/opt/filc"
FILC_PREFIX:class-native = "${prefix}/share/filc"

# non-empty for the native build tool: switch rpaths to $ORIGIN-relative
FILC_NATIVE_RPATH = ""
FILC_NATIVE_RPATH:class-native = "1"

# relative link targets from ${bindir} into the dist (sstate wants relative
# symlinks); note minilute/sarcasm live in pizfix/bin, the clang drivers in
# build/bin
FILC_BINDIR_LINK = "../../opt/filc/build/bin"
FILC_BINDIR_LINK:class-native = "../share/filc/build/bin"
FILC_PIZFIX_BIN_LINK = "../../opt/filc/pizfix/bin"
FILC_PIZFIX_BIN_LINK:class-native = "../share/filc/pizfix/bin"

# minilute (the luau VM that runs the sarcasm assembler script) is itself a
# fil-c binary and must run under the fil-c loader ld-fil1 as ELF
# interpreter. For target installs that is FILC_PREFIX; for the native build
# tool the per-recipe sysroots live at varying absolute paths, so point at
# the stable sstate component path instead.
FILC_MINILUTE_INTERPRETER = "${FILC_PREFIX}/pizfix/lib/ld-fil1-${FILC_ARCH}.so"
# for class-native, ${prefix} contains the STAGING_DIR_NATIVE placeholder, so
# spell out the stable sstate component path directly
FILC_COMPONENT_DIR:class-native = "${COMPONENTS_DIR}/${PACKAGE_ARCH}/${PN}/usr/share/filc"
FILC_MINILUTE_INTERPRETER:class-native = "${COMPONENTS_DIR}/${PACKAGE_ARCH}/${PN}/usr/share/filc/pizfix/lib/ld-fil1-${FILC_ARCH}.so"

do_install() {
    install -d ${D}${FILC_PREFIX}
    cp -a ${S}/. ${D}${FILC_PREFIX}/

    # musl-compatible <sys/cdefs.h> shim: the pizfix resource dir has none,
    # and the toolchain's -idirafter target include dir would otherwise make
    # <sys/cdefs.h> resolve to glibc's (which needs glibc-internal macros).
    # Installed next to the filc tree; the toolchain adds this dir with -I,
    # ahead of both the pizfix and the -idirafter glibc includes.
    if [ -n "${FILC_NATIVE_RPATH}" ]; then
        install -d ${D}${FILC_PREFIX}/include-shim/sys
        install -m 0644 ${THISDIR}/files/sys/cdefs.h \
            ${D}${FILC_PREFIX}/include-shim/sys/cdefs.h
    fi

    # replicate the tarball's setup.sh rpath fixups; for the native build
    # tool use $ORIGIN-relative rpaths so the assembled per-recipe sysroots
    # work without knowing their absolute path
    if [ -n "${FILC_NATIVE_RPATH}" ]; then
        RPATH="\$ORIGIN"
        MINILUTE_RPATH="\$ORIGIN/../lib"
    else
        RPATH="${FILC_PREFIX}/pizfix/lib64:${FILC_PREFIX}/pizfix/lib"
        MINILUTE_RPATH="$RPATH"
    fi
    for f in pizfix/lib/libc.so pizfix/lib/libpizlo.so pizfix/lib/libc++.so.1.0 \
             pizfix/lib/libc++abi.so.1.0 pizfix/lib_test/libpizlo.so \
             pizfix/lib_test_gcverify/libpizlo.so pizfix/lib_gcverify/libpizlo.so; do
        patchelf --set-rpath "$RPATH" ${D}${FILC_PREFIX}/$f
    done
    patchelf --set-rpath "$MINILUTE_RPATH" ${D}${FILC_PREFIX}/pizfix/bin/minilute
    patchelf --set-interpreter "${FILC_MINILUTE_INTERPRETER}" ${D}${FILC_PREFIX}/pizfix/bin/minilute
    if [ -f ${D}${FILC_PREFIX}/pizfix/bin/sarcasm ]; then
        # short shebang via PATH (an absolute path into the sysroot would
        # exceed the 128-char shebang limit); minilute is symlinked into
        # ${bindir} below
        sed -i "1s|.*|#!/usr/bin/env minilute|" ${D}${FILC_PREFIX}/pizfix/bin/sarcasm
    fi

    # the binary dist ships the arch-specific libc++ __config_site
    # (build/include/<triple>/c++/v1/__config_site) but not the generic
    # build/include/c++/v1/__config_site, which is what the driver falls
    # back to when cross-compiling (e.g. --target=aarch64-linux-musl finds
    # no aarch64-unknown-linux-musl dir). Without the full feature macros
    # (_LIBCPP_HAS_THREADS etc.) <mutex>/<thread> are empty and C++ code
    # fails to compile. Seed the generic one from the host arch-specific
    # file; keep the hardening default if that is missing.
    install -d ${D}${FILC_PREFIX}/build/include/c++/v1
    if [ -f ${D}${FILC_PREFIX}/build/include/${FILC_ARCH}-unknown-linux-gnu/c++/v1/__config_site ]; then
        cp ${D}${FILC_PREFIX}/build/include/${FILC_ARCH}-unknown-linux-gnu/c++/v1/__config_site \
            ${D}${FILC_PREFIX}/build/include/c++/v1/__config_site
    else
        echo '#define _LIBCPP_HARDENING_MODE_DEFAULT _LIBCPP_HARDENING_MODE_EXTENSIVE' \
            > ${D}${FILC_PREFIX}/build/include/c++/v1/__config_site
    fi

    # os-include: kernel headers of the target system
    mkdir -p ${D}${FILC_PREFIX}/pizfix/os-include
    ln -sf /usr/include/linux ${D}${FILC_PREFIX}/pizfix/os-include/linux
    ln -sf /usr/include/asm ${D}${FILC_PREFIX}/pizfix/os-include/asm
    ln -sf /usr/include/asm-generic ${D}${FILC_PREFIX}/pizfix/os-include/asm-generic

    # expose the compiler drivers on PATH (native: ${bindir} is
    # ${STAGING_BINDIR_NATIVE}, which the build puts on PATH)
    install -d ${D}${bindir}
    for tool in filcc fil++ filcpp clang clang++ clang-20; do
        ln -sf ${FILC_BINDIR_LINK}/$tool ${D}${bindir}/$tool
    done
    # minilute runs the sarcasm assembler script (shebang above). For the
    # native tool, install a wrapper that invokes minilute through the
    # fil-c loader (ld-fil1) at the stable sstate component path: minilute
    # is itself a fil-c binary needing ld-fil1, and uninative rewrites ELF
    # interpreters in the native sysroot, so the interpreter field can't be
    # relied upon.
    if [ -n "${FILC_NATIVE_RPATH}" ]; then
        # scrub LD_PRELOAD/LD_LIBRARY_PATH: during pseudo-wrapped tasks
        # (do_install/do_package/do_rootfs) those point at pseudo's glibc
        # libpseudo.so, which the fil-c loader (ld-fil1, musl) cannot load -
        # the minilute/sarcasm subprocesses would fail with "Exec format
        # error". Host tools in those tasks still get LD_PRELOAD normally.
        printf '#!/bin/sh\nunset LD_PRELOAD LD_LIBRARY_PATH\nexec %s %s "$@"\n' \
            "${FILC_COMPONENT_DIR}/pizfix/lib/ld-fil1-${FILC_ARCH}.so" \
            "${FILC_COMPONENT_DIR}/pizfix/bin/minilute" \
            > ${D}${bindir}/minilute
        chmod 0755 ${D}${bindir}/minilute
        # sarcasm shells out to a plain `as`; make sure that resolves to the
        # cross assembler for target code. Host (x86_64) assembler calls
        # carry --64/-m64 (e.g. from CC_FOR_BUILD gcc), so dispatch on that.
        if [ -n "${FILC_CROSS_PREFIX}" ]; then
            cat > ${D}${bindir}/as <<'EOF'
#!/bin/sh
for a in "$@"; do
    case "$a" in
        --64|-m64) exec /usr/bin/as "$@" ;;
    esac
done
exec CROSSPFXas "$@"
EOF
            sed -i "s/CROSSPFX/${FILC_CROSS_PREFIX}/" ${D}${bindir}/as
            chmod 0755 ${D}${bindir}/as
        fi
    else
        ln -sf ${FILC_PIZFIX_BIN_LINK}/minilute ${D}${bindir}/minilute
    fi

    # native build tool: install the target-arch pizfix tree that filcc
    # uses as its cross resource dir (--filc-resource-dir=...)
    if [ -n "${FILC_CROSS_DIST_ARCH}" ] && [ -d ${UNPACKDIR}/filc-cross ]; then
        install -d ${D}${FILC_PREFIX}/pizfix-${FILC_CROSS_DIST_ARCH}
        cp -a ${UNPACKDIR}/filc-cross/filc-${PV}-linux-${FILC_CROSS_DIST_ARCH}/pizfix/. \
            ${D}${FILC_PREFIX}/pizfix-${FILC_CROSS_DIST_ARCH}/
        # the cross dist's arch-specific libc++ __config_site, so C++ cross
        # compiles find the full feature macros under build/include/<triple>
        if [ -d ${UNPACKDIR}/filc-cross/filc-${PV}-linux-${FILC_CROSS_DIST_ARCH}/build/include/${FILC_CROSS_DIST_ARCH}-unknown-linux-gnu ]; then
            install -d ${D}${FILC_PREFIX}/build/include
            cp -a ${UNPACKDIR}/filc-cross/filc-${PV}-linux-${FILC_CROSS_DIST_ARCH}/build/include/${FILC_CROSS_DIST_ARCH}-unknown-linux-gnu \
                ${D}${FILC_PREFIX}/build/include/
        fi
        if [ -f ${D}${FILC_PREFIX}/pizfix-${FILC_CROSS_DIST_ARCH}/bin/sarcasm ]; then
            sed -i "1s|.*|#!/usr/bin/env minilute|" \
                ${D}${FILC_PREFIX}/pizfix-${FILC_CROSS_DIST_ARCH}/bin/sarcasm
        fi
    fi
}

# prebuilt binaries with private libs under the fil-c prefix: don't strip,
# don't try to resolve those private sonames to packages. The cross pizfix
# tree even contains foreign-arch (target) binaries the host strip can't
# parse, so skip sysroot stripping too.
INHIBIT_PACKAGE_STRIP = "1"
INHIBIT_SYSROOT_STRIP = "1"
# the native minilute carries the absolute sstate component path as its ELF
# interpreter (see FILC_MINILUTE_INTERPRETER)
INSANE_SKIP:${PN} += "already-stripped file-rdeps buildpaths"
