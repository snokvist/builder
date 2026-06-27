################################################################################
#
# wfb-air (waybeam_wfb_ng mega binary — pre-built from waybeam-releases)
#
# Single multicall ELF (wfb-air) that replaces the stock wfb-bins-only
# package. libpcap is static-linked into the binary; libsodium.so.23 is a
# runtime dependency (declared below so it stays in the rootfs once
# wfb-bins-only is dropped). libstdc++.so.6 ships with the base rootfs.
#
################################################################################

WFB_AIR_VERSION = v0.8.0
WFB_AIR_SITE = https://github.com/snokvist/waybeam-releases/releases/download/$(WFB_AIR_VERSION)
WFB_AIR_SOURCE = wfb-air-arm.tar.gz
WFB_AIR_LICENSE = GPL-3.0

WFB_AIR_DEPENDENCIES = libsodium

define WFB_AIR_INSTALL_TARGET_CMDS
	$(INSTALL) -m 0755 -D $(@D)/wfb-air \
		$(TARGET_DIR)/usr/bin/wfb-air
	$(INSTALL) -m 0644 -D $(WFB_AIR_PKGDIR)/files/wfb-link.json \
		$(TARGET_DIR)/etc/wfb-link.json
	$(INSTALL) -m 0644 -D $(WFB_AIR_PKGDIR)/files/wfb-common.sh \
		$(TARGET_DIR)/etc/wfb-common.sh
endef

define WFB_AIR_INSTALL_INIT_SYSV
	$(INSTALL) -m 0755 -D $(WFB_AIR_PKGDIR)/files/S99wfb \
		$(TARGET_DIR)/etc/init.d/S99wfb
endef

$(eval $(generic-package))
