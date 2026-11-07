# Fil-C port: fil-c's musl pizfix returns ENOSYS for prctl(PR_CAP_AMBIENT,
# PR_CAP_AMBIENT_CLEAR_ALL); lighttpd only tolerated EINVAL and exited 255.
# class-target only: *-native builds with gcc are unaffected.
FILESEXTRAPATHS:prepend:class-target := "${THISDIR}/files:"
SRC_URI:append:class-target = " file://filc-0001-prctl-enosys.patch"
