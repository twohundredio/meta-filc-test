# Deploy the fil-c target runtime (pizfix: musl libc, ld-fil1 loader,
# libpizlo/libyoloc) into the image and rewrite the ELF interpreter/rpath of
# fil-c-compiled binaries to that fixed path. filcc bakes the build-sysroot
# pizfix path into INTERP/RUNPATH, which does not exist on the target.
IMAGE_INSTALL += " fil-c-rt lighttpd lua"

do_rootfs[depends] += " patchelf-native:do_populate_sysroot"

filc_rootfs_fixup() {
    pizlib="/opt/filc/pizfix-${TRANSLATED_TARGET_ARCH}/lib"
    loader="$pizlib/ld-fil1-${TRANSLATED_TARGET_ARCH}.so"
    find ${IMAGE_ROOTFS} -xdev -type f -print0 | while IFS= read -r -d '' f; do
        # only fil-c-compiled ELF executables/shared libs (they NEED
        # libpizlo.so); skip static archives and non-ELF files
        if readelf -d "$f" 2>/dev/null | grep -q 'libpizlo\.so'; then
            if patchelf --print-interpreter "$f" >/dev/null 2>&1; then
                patchelf --set-interpreter "$loader" "$f" \
                    || bbwarn "filc_rootfs_fixup: set-interpreter failed on $f"
            fi
            patchelf --set-rpath "$pizlib" "$f" \
                || bbwarn "filc_rootfs_fixup: set-rpath failed on $f"
        fi
    done
    return 0
}
ROOTFS_POSTPROCESS_COMMAND += "filc_rootfs_fixup; "
