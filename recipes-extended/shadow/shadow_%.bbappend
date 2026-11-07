# fil-c port for shadow (class-target only; *-native builds keep the host
# gcc/glibc toolchain).
#
# 1. The target sysroot still contains glibc headers (reached via the
#    toolchain's -idirafter), and shadow picks up glibc's <gshadow.h> via
#    __has_include() in lib/shadow/gshadow/*.h|*.c. glibc headers expect
#    glibc's <features.h> to provide __BEGIN_DECLS/__END_DECLS (via its
#    sys/cdefs.h); musl's features.h does not - the pizfix has no
#    sys/cdefs.h at all. Force-include the toolchain's sys/cdefs.h shim
#    (recipes-devtools/fil-c/files/sys/cdefs.h, passed with -I ahead of
#    everything) in every translation unit so those macros are defined.
CFLAGS:append:class-target = " -include sys/cdefs.h"

# 2. pizfix musl has no gshadow API (no <gshadow.h>, no getsgent family).
#    Because glibc's <gshadow.h> is visible via -idirafter, shadow's
#    __has_include(<gshadow.h>) guards select glibc's declarations and
#    compile out shadow's own implementations -> "undefined reference to
#    pizlonated_endsgent" at link. The patch forces shadow to always use
#    its own gshadow declarations/definitions (all #include <gshadow.h>
#    uses sit inside those guards, so they become dead).
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append:class-target = " file://filc-0001-fil-c-use-own-gshadow.patch"

# 3. libsubid links with libtool's -export-symbols-regex '^subid_', which
#    needs lt_cv_sys_global_symbol_pipe: libtool's configure probe greps nm
#    output for a plain global symbol, but filcc pizlonates globals
#    (pizlonated_subid_*, with the DO_/FO_ copies local), so the probe
#    fails and the pipe is empty ("syntax error near unexpected token `|>'"
#    at link time). Subordinate IDs are not needed (the sshd privsep user
#    only), so skip libsubid entirely.
EXTRA_OECONF:append:class-target = " --disable-subordinate-ids"
