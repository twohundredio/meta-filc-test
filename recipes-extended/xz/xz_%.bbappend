# Port of the upstream Fil-C patch (github.com/pizlonator/fil-c projects/)
# so this package builds with TOOLCHAIN = "fil-c".
# class-target only: the patch uses fil-c-only headers, must not apply
# to *-native builds (those use the host gcc toolchain).
FILESEXTRAPATHS:prepend:class-target := "${THISDIR}/files:"
SRC_URI:append:class-target = " file://filc-0001-fil-c-port.patch"
