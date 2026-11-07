# qemu machines: bring up eth0 via DHCP at boot (the stock interfaces file
# only configures lo, which is not enough for qemu hostfwd). The base
# recipe installs the generic file; override it with a qemu-specific one.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append:qemuall = " file://qemuall-interfaces"

do_install:append:qemuall () {
    install -m 0644 ${S}/qemuall-interfaces ${D}${sysconfdir}/network/interfaces
}
