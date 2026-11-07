# Port of the upstream Fil-C patch (github.com/pizlonator/fil-c projects/)
# so this package builds with TOOLCHAIN = "fil-c"
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " file://filc-0001-fil-c-port.patch"
