################################################################################
#
# waybeam-venc-star6e (pre-built binary from waybeam-releases)
#
# Built from OpenIPC/waybeam_venc (open-sourced upstream). The star6e build
# now produces a single binary named `waybeam` (was `venc_star6e`); it loads
# its config from a fixed /etc/waybeam.json and is managed by S95waybeam.
#
################################################################################

WAYBEAM_VENC_STAR6E_VERSION = v0.8.0
WAYBEAM_VENC_STAR6E_SITE = https://github.com/snokvist/waybeam-releases/releases/download/$(WAYBEAM_VENC_STAR6E_VERSION)
WAYBEAM_VENC_STAR6E_SOURCE = venc-star6e-arm.tar.gz
WAYBEAM_VENC_STAR6E_LICENSE = Autod Personal Use License

define WAYBEAM_VENC_STAR6E_INSTALL_TARGET_CMDS
	$(INSTALL) -m 0755 -D $(@D)/waybeam \
		$(TARGET_DIR)/usr/bin/waybeam
	$(INSTALL) -m 0644 -D $(WAYBEAM_VENC_STAR6E_PKGDIR)/files/waybeam.json \
		$(TARGET_DIR)/etc/waybeam.json
endef

define WAYBEAM_VENC_STAR6E_INSTALL_INIT_SYSV
	$(INSTALL) -m 0755 -D $(WAYBEAM_VENC_STAR6E_PKGDIR)/files/S94sensor-detect \
		$(TARGET_DIR)/etc/init.d/S94sensor-detect
	$(INSTALL) -m 0755 -D $(WAYBEAM_VENC_STAR6E_PKGDIR)/files/S95waybeam \
		$(TARGET_DIR)/etc/init.d/S95waybeam
endef

$(eval $(generic-package))
