# Build perl with TOOLCHAIN = "fil-c".
#
# perl-cross's checksize() determines sizeof(T) by compiling `T foo;` and
# reading the symbol size out of the object with readelf. Under fil-c the
# global is pizlonated (pizlonatedDO_foo wrapper), so the size readelf
# reports is wrong/absent and configure dies with "Cannot determine
# sizeof(char)". Preset all sizes for aarch64-musl lp64 via -D flags (the
# hint mechanism then skips the readelf probe entirely):
#   char=1 short=2 int=4 long=8 double=8 ptr=8 longlong=8 longdouble=16
#   size_t=8 off_t=8 (LFS) uid_t=4 gid_t=4 time_t=8 fpos_t=16 (musl union)
# byteorder is also probed via objdump on the .data section of a compiled
# global (pizlonated under fil-c), so hint it too: aarch64 is little-endian
# 64-bit (byteorder=12345678), IEEE754 64-bit LE doubles (doublekind=3) and
# IEEE754 128-bit LE long doubles (longdblkind=1).
PACKAGECONFIG_CONFARGS:append:class-target = " \
    -Dcharsize=1 -Dshortsize=2 -Dintsize=4 -Dlongsize=8 \
    -Ddoublesize=8 -Dptrsize=8 -Dlonglongsize=8 -Dlongdblsize=16 \
    -Dsizesize=8 -Dfpossize=16 -Dlseeksize=8 \
    -Duidsize=4 -Dgidsize=4 -Dtimesize=8 \
    -Dbyteorder=12345678 -Ddoublekind=3 -Dlongdblkind=1 \
"
