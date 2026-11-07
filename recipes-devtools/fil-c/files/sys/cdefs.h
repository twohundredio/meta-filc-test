/* Minimal <sys/cdefs.h> shim for the fil-c (musl pizfix) toolchain.
 *
 * The pizfix resource dir has no sys/cdefs.h, but the toolchain adds the OE
 * target (glibc) include dir with -idirafter for kernel headers (linux/,
 * asm/), so without this shim <sys/cdefs.h> resolves to glibc's, which uses
 * __GNUC_PREREQ (defined only by glibc's features.h) and errors under musl.
 * This shim is passed with -I, ahead of both, and provides the common macros.
 *
 * NOTE: __unused and __used are deliberately NOT defined: musl's own bits
 * headers use __unused as a plain struct member name (e.g. "unsigned
 * __unused[2]" in bits/stat.h), so defining it as an attribute macro breaks
 * musl headers. Code that wants the attribute uses __attribute__ directly.
 */
#ifndef _SYS_CDEFS_H
#define _SYS_CDEFS_H

#define __GNUC_PREREQ(maj, min) \
    (defined(__GNUC__) && \
     ((__GNUC__ << 16) + __GNUC_MINOR__ >= ((maj) << 16) + (min)))
#define __glibc_has_attribute(attr)   __has_attribute(attr)
#define __glibc_has_builtin(name)     __has_builtin(name)
#define __glibc_has_extension(ext)    __has_extension(ext)
#define __glibc_has_c_attribute(attr) __has_c_attribute(attr)

#define __P(args)   args
#define __PMT(args) args

#define __THROW     __attribute__((__nothrow__))
#define __THROWNL   __attribute__((__nothrow__))
#define __const     __attribute__((__const__))
#define __dead      __attribute__((__noreturn__))
#define __pure      __attribute__((__pure__))
#define __wur       __attribute__((__warn_unused_result__))
#define __nonnull(params) __attribute__((__nonnull__ params))
#define __alloc_size(x)   __attribute__((__alloc_size__ x))
#define __flexarr   []

#ifdef __cplusplus
# define __BEGIN_DECLS  extern "C" {
# define __END_DECLS    }
#else
# define __BEGIN_DECLS
# define __END_DECLS
#endif

#endif /* _SYS_CDEFS_H */
