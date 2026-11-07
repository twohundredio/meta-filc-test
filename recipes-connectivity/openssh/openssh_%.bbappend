# fil-c port for openssh (class-target only; *-native/nativesdk keep gcc).
#
# The seccomp_filter sandbox (upstream default on Linux) is incompatible
# with fil-c: right after the filter is attached, libpas's allocator fails
# (pas_bootstrap_free_heap_allocate ... did_succeed failed - the filter
# blocks the mmap/madvise variants libpas needs) and the pre-auth child dies
# with a filc panic ("mm_reap: child terminated by signal 5"). fil-c is
# memory-safe by construction, so OpenSSH's syscall sandbox adds nothing here;
# build with the null sandbox (privsep user separation still applies).
EXTRA_OECONF:append:class-target = " --with-sandbox=no"

# generate an ed25519 host key in addition to ecdsa (modern clients prefer it)
PACKAGECONFIG:append:class-target = " hostkey-ed25519"
