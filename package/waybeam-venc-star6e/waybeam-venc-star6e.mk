################################################################################
#
# waybeam-venc-star6e (pre-built binary from waybeam-releases)
#
################################################################################

WAYBEAM_VENC_STAR6E_VERSION = v0.6.0-bundled-release
WAYBEAM_VENC_STAR6E_SITE = https://github.com/snokvist/waybeam-releases/releases/download/$(WAYBEAM_VENC_STAR6E_VERSION)
WAYBEAM_VENC_STAR6E_SOURCE = venc-star6e-arm.tar.gz
WAYBEAM_VENC_STAR6E_LICENSE = Autod Personal Use License

define WAYBEAM_VENC_STAR6E_INSTALL_TARGET_CMDS
	$(INSTALL) -m 0755 -D $(@D)/venc_star6e \
		$(TARGET_DIR)/usr/bin/venc
	$(INSTALL) -m 0644 -D $(WAYBEAM_VENC_STAR6E_PKGDIR)/files/venc.json \
		$(TARGET_DIR)/etc/venc.json
endef

define WAYBEAM_VENC_STAR6E_INSTALL_INIT_SYSV
	$(INSTALL) -m 0755 -D $(WAYBEAM_VENC_STAR6E_PKGDIR)/files/S94sensor-detect \
		$(TARGET_DIR)/etc/init.d/S94sensor-detect
	$(INSTALL) -m 0755 -D $(WAYBEAM_VENC_STAR6E_PKGDIR)/files/S95venc \
		$(TARGET_DIR)/etc/init.d/S95venc
endef

$(eval $(generic-package))
