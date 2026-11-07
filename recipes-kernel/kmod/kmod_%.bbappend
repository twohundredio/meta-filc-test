# Fil-C port for kmod: -Wc,--version-script= for libkmod.sym.
FILESEXTRAPATHS:prepend:class-target := "${THISDIR}/files:"
SRC_URI:append:class-target = " file://filc-0001-fil-c-port.patch"
