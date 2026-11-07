# Port of the upstream Fil-C patch (github.com/pizlonator/fil-c projects/)
# so this package builds with TOOLCHAIN = "fil-c".
# class-target only: -Wc,--version-script= is a fil-c-only flag.
FILESEXTRAPATHS:prepend:class-target := "${THISDIR}/files:"
SRC_URI:append:class-target = " file://filc-0001-fil-c-port.patch"
