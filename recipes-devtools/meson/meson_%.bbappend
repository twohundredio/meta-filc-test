# Fil-C toolchain fix (see patch header): meson's clang mixin must not turn
# unused link-only CC flags into errors during configure checks.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " file://filc-0001-no-unused-arg-werror.patch"
