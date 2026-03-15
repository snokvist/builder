################################################################################
#
# waybeam-venc-maruko
#
################################################################################

WAYBEAM_VENC_MARUKO_VERSION = 98efe00
WAYBEAM_VENC_MARUKO_SITE = https://github.com/OpenIPC/waybeam_venc.git
WAYBEAM_VENC_MARUKO_SITE_METHOD = git
WAYBEAM_VENC_MARUKO_LICENSE = Autod Personal Use License

define WAYBEAM_VENC_MARUKO_BUILD_CMDS
	$(MAKE) -C $(@D) build \
		SOC_BUILD=maruko \
		MARUKO_CC="$(TARGET_CC)" \
		MARUKO_MI_LIB_DIR="$(@D)/libs/maruko" \
		MARUKO_COMMON_LIB_DIR="$(@D)/libs/maruko"
endef

define WAYBEAM_VENC_MARUKO_INSTALL_TARGET_CMDS
	$(INSTALL) -m 0755 -D $(@D)/out/maruko/venc \
		$(TARGET_DIR)/usr/bin/venc
	$(INSTALL) -m 0644 -D $(@D)/config/venc.default.json \
		$(TARGET_DIR)/etc/venc.json
	# Maruko uclibc shim
	$(INSTALL) -m 0755 -D $(@D)/tools/libmaruko_uclibc_shim.so \
		$(TARGET_DIR)/usr/lib/libmaruko_uclibc_shim.so
endef

$(eval $(generic-package))
