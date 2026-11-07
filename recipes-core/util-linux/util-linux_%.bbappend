# Fil-C port for util-linux: -Wc,--version-script= for the lib*.sym
# version scripts (filcc 0.687 pizlonates the script symbols only in
# this form).
FILESEXTRAPATHS:prepend:class-target := "${THISDIR}/files:"
SRC_URI:append:class-target = " file://filc-0001-fil-c-port.patch"
