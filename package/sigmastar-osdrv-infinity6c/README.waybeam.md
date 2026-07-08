# sigmastar-osdrv-infinity6c — Waybeam overrides

This directory does **not** define a new package. It carries file-level
overrides that `builder.sh`'s `copy_extra_packages()` merges into the upstream
OpenIPC package of the same name (`cp -af package/* openipc/general/package/`),
so they survive the `rm -rf openipc` re-clone.

## `files/lib/libmi_ive.so` — BSP-matched IVE blob

**Why:** the IVE motion detector (`MI_IVE_Shift_Detector`) is the basis for
`video.framing` **stab** / **stab-fill**. With the blob OpenIPC ships,
`MI_IVE_Create()` fails on Infinity6C:

    [ALGO_MSG_ERR] mmap failed!!
    [ALGO_MSG_ERR] Unexpected IC version
    [ALGO_MSG_ERR] The platform check is incorrect while MI_MVE_Init() is called!!
    MI_IVE_Create(0) -> -1610604513

This is **not** a kernel bug. OpenIPC's i6c `msys` + `ive` kernel driver source
is byte-identical to the vendor BSP's (Maruko-ILS00_TINY_V1.4.0), and OpenIPC's
blob reads the RIU base from exactly the offset `msys_get_riu_map_verchk()`
writes it to. The divergence is **blob vintage**:

| | OpenIPC blob | BSP blob (this file) |
|---|---|---|
| watermark | `MVX1##I6C#####d10fcfb#ive` | `MVX1##I6C#####c6a1e30#ive` |
| IC-version check | raw-mmaps `/dev/mem` at the RIU base — **EINVALs here** | `/dev/mstar_ive0` ioctls; never opens `/dev/mem` |
| size | 754,672 B | 446,908 B |

The BSP blob performs the same platform check through the kernel IVE driver and
structurally avoids the failing path.

**Source:** `Maruko-ILS00_TINY_V1.4.0`
`project/release/chip/i6c/sigma_common_libs/uclibc/9.1.0/dynamic/libmi_ive.so`
(md5 `d608368e2348855adab63667fc1d359c`).

**Why the uClibc variant:** the OpenIPC i6c rootfs is musl with uClibc-compat
symlinks (`/lib/ld-uClibc.so.0` → `libc.so`, `/lib/libc.so.0` → `libc.so`), and
the blob's only `NEEDED` entries are `libc.so.0` and `libgcc_s.so.1`, both
present. The glibc variant would additionally need `libc.so.6`.

**Swap only `libmi_ive.so`.** Do *not* also import the BSP's `libmi_sys.so` /
`libmi_common.so`: the BSP's uClibc `libmi_sys` segfaults inside `MI_SYS_Init`
on a musl rootfs. `libmi_ive` needs just five stable MI_SYS symbols
(`MI_SYS_MMA_Alloc/Free`, `MI_SYS_Mmap/Munmap`, `MI_SYS_FlushInvCache`), so it
rides fine on the MI stack osdrv already installs.

Overriding the blob here (rather than adding a separate package that installs
over osdrv) keeps a single writer for `/usr/lib/libmi_ive.so` and avoids
install-order races under `BR2_PER_PACKAGE_DIRECTORIES`. The upstream
`SIGMASTAR_OSDRV_INFINITY6C_LIBRARIES` hook installs `files/lib/*` verbatim
(when Majestic is not selected, which is always true for Waybeam images).

## Verified

On `root@192.168.2.233` (i6c/SSC378QE, clean boot):

    MI_SYS_Init(0)    -> 0
    MI_IVE_Create(0)  -> 0
    MI_IVE_Destroy(0) -> 0
    MI_IVE_Shift_Detector: 5/5 synthetic shifts recovered exactly

Note the detector is **CPU-bound**, not hardware-accelerated: 16.8 ms/call at
100% of one A7 core, with the `ive isr` (IRQ 78) count pinned at 0. Budget stab
on Maruko at roughly Star6E's ~19 ms/frame cost.

Reproduce with `waybeam_venc/tools/ive_i6c_probe.c` and `tools/ive_i6c_shift.c`.
