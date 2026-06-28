#!/bin/sh
# /etc/wfb/recovery-apfpv.sh — Return-to-APFPV recovery hook (firmware-baked).
#
# link_controller fork+execs recovery.apfpv_cmd (default this path) from two
# converging paths, both of which land here:
#   - key 64 — keyless/open (-xx) recovery backdoor (unauthenticated RF), gated
#     by recovery_dispatch()'s 3-frame-arm + arm_window_ms + cooldown_ms.
#   - key 20 — authenticated return_apfpv WCMD on the keyed uplink, gated by
#     cmd.allow_keys_mask + the 500 ms per-key burst-dedup.
#
# Action: arm APFPV-next-boot (u-boot env wfbmode=0) AND reboot, so 1->0 (wfb_ng
# -> APFPV) completes without a second manual step. On the APFPV boot S99wfb
# skips the wfb stack and S95waybeam switches venc to udp:// output; the box
# comes up as the waybeam-03 AP. Idempotent (re-arming wfbmode=0 is harmless)
# and quick to reach the reboot (link_controller waits synchronously). Bounded
# against reboot-loops by the keyless 3-frame-arm + arm_window + cooldown and
# the keyed path's mask-gating + authentication.
#
# Reference/source: waybeam_wfb_ng vehicle/scripts/recovery-apfpv.sh.example.

logger -t recovery "Return-to-APFPV: fw_setenv wfbmode 0 + reboot" 2>/dev/null
fw_setenv wfbmode 0 && sync && reboot
exit 0
