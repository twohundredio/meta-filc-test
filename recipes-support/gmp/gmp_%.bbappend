# Port of the upstream Fil-C patch (github.com/pizlonator/fil-c projects/)
# so this package builds with TOOLCHAIN = "fil-c".
# class-target only: the patch touches x86-only configure paths and the
# configure cache presets below are fil-c-specific; *-native gcc builds
# are unaffected.
FILESEXTRAPATHS:prepend:class-target := "${THISDIR}/files:"
SRC_URI:append:class-target = " file://filc-0001-fil-c-port.patch"

# sarcasm rejects top-level labels ("label outside any function is not
# supported"), so gmp's assembly probes that emit a global label in
# conftest.s fail under filcc. Preset the cache variables with the values
# the real aarch64 assembler produces (verified with aarch64-poky-linux-as):
#   .long emits a 4-byte word (foo == 4)  -> w32 = .long
#   .align is logarithmic on aarch64 (foo == 16 after .align 4) -> yes
# upstream fil-c builds gmp with --disable-assembly (build_gmp.sh): the
# arm64 .asm sources have no sarcasm signature annotations, so use the
# generic C mpn implementations (pizlonated by filcc) instead.
EXTRA_OECONF:append:class-target = " --disable-assembly gmp_cv_asm_w32=.long gmp_cv_asm_align_log=yes"
