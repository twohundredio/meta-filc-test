# Build with TOOLCHAIN = "fil-c".
# The top-level `tests` dir is built as part of `all` even with ptest
# removed, and its gnulib test programs use glibc-only APIs
# (pthread_rwlockattr_setkind_np) that fil-c's musl pizfix lacks.
# Drop `tests` from SUBDIRS after configure.
do_configure:append:class-target() {
    sed -i -e 's/^SUBDIRS = \(.*\) tests\( .*\)\?$/SUBDIRS = \1\2/' Makefile
}
