# Builder

OpenIPC firmware builder with Waybeam package definitions. Based on
Buildroot, builds complete firmware images for supported camera/FPV devices.

## Build

```bash
./builder.sh                    # Interactive device selector (whiptail menu)
./builder.sh <device_profile>   # Direct build, e.g. ./builder.sh ssc30kq_waybeam_bu
```

The script clones OpenIPC firmware into `openipc/`, copies device overlays
and extra packages, then runs `make BOARD=<profile>`. Output goes to
`archive/<profile>/<timestamp>/`.

Other scripts:
- `package.sh <pkg>` -- Clean-rebuild a single Buildroot package
- `repack.sh <uboot> <firmware> [ssid] [pass]` -- Repack firmware with WiFi credentials

## Device profiles

Each profile is a directory under `devices/`:

```
devices/<profile_name>/
  br-ext-chip-<vendor>/configs/<profile_name>_defconfig   # Buildroot defconfig
  general/overlay/...                                      # Root filesystem overlay
  general/scripts/excludes/<profile>.list                  # Package exclude list
```

Naming: `<soc>_<flavor>_<vendor-model>` (e.g. `ssc30kq_waybeam_bu`).

The `devices/common/` directory holds shared configs inherited by multiple
profiles. The `devices/waybeam/` directory contains all Waybeam FPV profiles
(SSC338Q, SSC30KQ, SSC378QE variants).

To add a new profile: copy an existing profile directory with similar SoC,
rename the directory and defconfig file to match the new naming convention,
adjust the defconfig (sensor driver, WiFi driver, flash size), and update
the customizer.sh overlay script. Add the profile name to
`.github/workflows/master.yml` matrix to enable CI builds.

## Packages

Extra Buildroot packages live in `package/`. Each has a `Config.in`
(Kconfig menu entry), a `<name>.mk` (Buildroot makefile), and optionally
a `files/` directory with config files or init scripts.

| Package | Purpose |
|---|---|
| `waybeam-hub` | Vehicle build of waybeam-hub daemon (OSD, telemetry, PWM, WebUI) |
| `waybeam-venc-star6e` | Video encoder for SigmaStar Infinity6E (SSC338Q/SSC30KQ) |
| `waybeam-venc-maruko` | Video encoder variant (Maruko work) |
| `waybeam-distribution-star6e` | ISP sensor binary distribution (IMX335, IMX415) |
| `waybeam-distribution-star6c` | ISP sensor binary distribution (Star6C) |
| `infinity6e-pwm` | Kernel PWM patches for SigmaStar (legacy) |
| `linux-patcher` | Generic kernel patch applicator |
| `wfb-bins-only` | Pre-built WFB-ng binaries |
| `demo-openipc` | Demo/example package |

Packages are copied into the OpenIPC tree at build time by `builder.sh`
(`copy_extra_packages` function) and auto-registered in `Config.in`.

To update a package version: edit the `_VERSION` variable in its `.mk` file
(e.g. `WAYBEAM_HUB_VERSION = HEAD` fetches latest from git). To pin a
specific commit, replace `HEAD` with the commit hash or tag.

## CI

GitHub Actions workflow: `.github/workflows/master.yml`
- Triggered daily (3:00 UTC) and on manual dispatch
- Builds all profiles in the matrix, uploads firmware to GitHub Releases (tag: `latest`)
- Uses ccache for faster rebuilds

## Key files

| File | Purpose |
|---|---|
| `builder.sh` | Main build orchestrator |
| `package.sh` | Single-package rebuild helper |
| `repack.sh` | Firmware repacker with WiFi credentials |
| `.github/workflows/master.yml` | CI build matrix |
| `devices/` | All device profiles (90+ devices) |
| `package/` | Extra Buildroot packages (Waybeam ecosystem) |
| `archive/` | Local build output (gitignored) |

## Branching rules

- **Never commit directly to master.** Always use a feature branch.
- **Never push directly to master.** All changes go through pull requests.
- Branch naming: `feature/`, `fix/`, `refactor/` prefixes.
- Workflow: branch from master, commit, push, `gh pr create --base master`.
