# Port of the upstream Fil-C patch (github.com/pizlonator/fil-c projects/)
# so this package builds with TOOLCHAIN = "fil-c"
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " file://filc-0001-fil-c-port.patch"

# zstd's libzstd.mk unconditionally adds decompress/*_amd64.S to the object
# list (they self-disable via arch macros); sarcasm rejects the .macro
# directives in the x86 file even when macro-disabled. zstd has no aarch64
# asm, so just disable asm entirely (C fallbacks are used).
EXTRA_OEMAKE:append:class-target = " ZSTD_NO_ASM=1"
