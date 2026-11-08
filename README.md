# meta-filc-test — fil-c as the Yocto toolchain on qemuarm64

> **Warning:** This project is AI generated. The patches have **not** been
> reviewed or checked, and they could introduce security issues. Do not use
> this in production or anywhere untrusted without a full audit.

Builds `core-image-minimal` for `qemuarm64` with a **100% fil-c userspace**.
The compiler is the prebuilt fil-c dist (`fil-c-native`, see
`recipes-devtools/fil-c/`), driven as the cross toolchain by
`classes/toolchain/fil-c.bbclass` (selected via
`PREFERRED_TOOLCHAIN_TARGET = "fil-c"` in `kas/kas.yml`). Kernel and bootloader stay on gcc (`conf/nonfilcable.conf`).

## Layout

```
kas/kas.yml                     kas project file (layers, machine, local.conf)
classes/toolchain/fil-c.bbclass fil-c cross toolchain (CC=filcc, LD=ld.bfd, ...)
conf/nonfilcable.conf           recipes that must stay on gcc
recipes-devtools/fil-c/         fil-c-native (build tool) + fil-c-rt (image runtime)
recipes-*/<pkg>/                bbappends + filc-*.patch ports for OE recipes
```

## Build

```sh
mkdir -p ../meta-fil-c-build && cd ../meta-fil-c-build
kas build ../meta-fil-c/kas/kas.yml
```

Outputs land in `build/tmp/deploy/images/qemuarm64/`
(`core-image-minimal-qemuarm64.rootfs.ext4.zst`, `Image`, ...).

## Run the image with kas + runqemu (standard OE way)

```sh
cd ../meta-fil-c-build
kas shell ../meta-fil-c/kas/kas.yml -c \
  'QB_SLIRP_OPT="-netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:80" \
   runqemu qemuarm64 core-image-minimal snapshot slirp nographic qemuparams="-m 2048"'
```

This boots the image under the freshly built `qemu-system-aarch64` with the
serial console on stdio (login: `root`, empty password; `Ctrl-A x` quits).
Notes:

- `snapshot` is required because the deployed rootfs is `.ext4.zst` (runqemu
  decompresses it and cleans up on exit; guest changes are discarded).
- `qemuparams="-m 2048"` sets both qemu `-m` and kernel `mem=`. Do NOT rely on
  `QB_MEM` env: the machine's `qemuboot.conf` pins `qb_mem = -m 256` and the
  conf wins over env. fil-c's libpas mlocks committed heap, so < 2GB OOMs on
  `halt`.
- `QB_SLIRP_OPT` must be the full `-netdev user,id=net0,...` string (bare
  `hostfwd=...` breaks the qemu argv). `slirp` gives the guest DHCP; the `hostfwd` entries forward host 2222→guest 22 (ssh) and
  8080→guest 80 (lighttpd).
- `runqemu help` lists all options (`tcpserial=PORT` for serial over TCP,
  `bootparams=...`, `nonetwork`, ...).

Then from the host:

```sh
sshpass -p '' ssh -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  -o PreferredAuthentications=password -o PubkeyAuthentication=no root@127.0.0.1 'uname -a; busybox wget -qO- http://127.0.0.1/'
curl http://127.0.0.1:8080/        # lighttpd: <h1>It works!</h1>
```
