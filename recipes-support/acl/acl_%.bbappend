# Port of the upstream Fil-C fix (version-script flag form for filcc)
# so libacl exports its (pizlonated) symbols when built with fil-c.
FILESEXTRAPATHS:prepend:class-target := "${THISDIR}/files:"
SRC_URI:append:class-target = " file://filc-0001-fil-c-port.patch"
