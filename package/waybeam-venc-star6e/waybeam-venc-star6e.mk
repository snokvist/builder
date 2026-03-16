################################################################################
#
# waybeam-venc-star6e
#
################################################################################

WAYBEAM_VENC_STAR6E_VERSION = HEAD
WAYBEAM_VENC_STAR6E_SITE = https://github.com/OpenIPC/waybeam_venc.git
WAYBEAM_VENC_STAR6E_SITE_METHOD = git
WAYBEAM_VENC_STAR6E_LICENSE = Autod Personal Use License

# Links against vendored MI libs in libs/star6e (no staging dep needed)
define WAYBEAM_VENC_STAR6E_BUILD_CMDS
	$(MAKE) -C $(@D) build \
		SOC_BUILD=star6e \
		STAR6E_CC="$(TARGET_CC)" \
		STAR6E_DRV="$(@D)/libs/star6e"
endef

define WAYBEAM_VENC_STAR6E_INSTALL_TARGET_CMDS
	$(INSTALL) -m 0755 -D $(@D)/out/star6e/venc \
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
