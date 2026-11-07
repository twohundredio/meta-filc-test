# Fil-C port for openssl: build without assembly (perlasm output is not
# sarcasm-annotated; the C fallbacks are memory-safe). Also skip the
# -Wa,--noexecstack probe flag via the ported Configure patch.
FILESEXTRAPATHS:prepend:class-target := "${THISDIR}/files:"
SRC_URI:append:class-target = " file://filc-0001-fil-c-port.patch"
EXTRA_OECONF:append:class-target = " no-asm"
