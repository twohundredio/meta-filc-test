# Port of the upstream Fil-C patch (github.com/pizlonator/fil-c projects/)
# so this package builds with TOOLCHAIN = "fil-c"
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " file://filc-0001-fil-c-port.patch"

# gnulib-tests is built as part of `all` even with ptest removed, and some
# gnulib test programs use glibc-only APIs (pthread_rwlockattr_setkind_np)
# that fil-c's musl pizfix does not provide. Drop gnulib-tests from SUBDIRS.
do_configure:append:class-target() {
    sed -i -e 's/^SUBDIRS = \(.*\) gnulib-tests$/SUBDIRS = \1/' Makefile
}
