################################################################################
#
# waybeam-venc-star6e
#
################################################################################

WAYBEAM_VENC_STAR6E_VERSION = master
WAYBEAM_VENC_STAR6E_SITE = https://github.com/OpenIPC/waybeam_venc.git
WAYBEAM_VENC_STAR6E_SITE_METHOD = git
WAYBEAM_VENC_STAR6E_LICENSE = Autod Personal Use License
WAYBEAM_VENC_STAR6E_DEPENDENCIES = sigmastar-osdrv-infinity6e-libs

define WAYBEAM_VENC_STAR6E_BUILD_CMDS
	$(MAKE) -C $(@D) build \
		SOC_BUILD=star6e \
		STAR6E_CC="$(TARGET_CC)" \
		STAR6E_DRV="$(STAGING_DIR)/usr/lib"
endef

define WAYBEAM_VENC_STAR6E_INSTALL_TARGET_CMDS
	$(INSTALL) -m 0755 -D $(@D)/out/star6e/venc \
		$(TARGET_DIR)/usr/bin/venc
	$(INSTALL) -m 0644 -D $(@D)/config/venc.default.json \
		$(TARGET_DIR)/etc/venc.json
endef

define WAYBEAM_VENC_STAR6E_INSTALL_INIT_SYSV
	$(INSTALL) -m 0755 -D $(@D)/scripts/S99mountSD \
		$(TARGET_DIR)/etc/init.d/S99mountSD
endef

$(eval $(generic-package))
