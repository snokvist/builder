################################################################################
#
# waybeam-osd
#
################################################################################

WAYBEAM_OSD_VERSION = 9b45bdf3ffb527eb2c26c3a0199ce08973554b11
WAYBEAM_OSD_SITE = https://github.com/snokvist/waybeam_osd.git
WAYBEAM_OSD_SITE_METHOD = git
WAYBEAM_OSD_GIT_SUBMODULES = YES
WAYBEAM_OSD_LICENSE = Proprietary
WAYBEAM_OSD_DEPENDENCIES += sigmastar-osdrv-infinity6e-libs

define WAYBEAM_OSD_BUILD_CMDS
	# Build main OSD binary via upstream Makefile
	CCACHE_DISABLE=1 $(TARGET_MAKE_ENV) $(MAKE) -C $(@D) -j$(PARALLEL_JOBS) -B \
		CC="$(TARGET_CC)" \
		LD="$(TARGET_CC)" \
		STRIP="$(TARGET_STRIP)" \
		SYSROOT="$(abspath $(TARGET_DIR)/../host/arm-buildroot-linux-gnueabihf/sysroot)" \
		OUTPUT="waybeam-osd" \
		DRV="$(TARGET_DIR)/usr/lib" \
		TOOLCHAIN= \
		LVGL_INCLUDE_DEMOS=0 \
		LVGL_INCLUDE_EXAMPLES=0

	# Build osd_send helper (standalone)
	$(TARGET_MAKE_ENV) $(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_LDFLAGS) \
		-o $(@D)/osd_send $(@D)/osd_send.c
endef

define WAYBEAM_OSD_INSTALL_TARGET_CMDS
	# Main binary
	$(INSTALL) -D -m 0755 $(@D)/waybeam-osd \
		$(TARGET_DIR)/usr/bin/waybeam-osd

	# Helper binary
	$(INSTALL) -D -m 0755 $(@D)/osd_send \
		$(TARGET_DIR)/usr/bin/osd_send

	$(INSTALL) -D -m 0644 $(WAYBEAM_OSD_PKGDIR)/files/waybeam_osd.json \
		$(TARGET_DIR)/etc/waybeam_osd.json

	# Default config
	#$(INSTALL) -D -m 0644 $(@D)/waybeam_osd.json \
	#	$(TARGET_DIR)/etc/waybeam_osd.json
endef

define WAYBEAM_OSD_INSTALL_INIT_SYSV
	$(INSTALL) -D -m 0755 $(WAYBEAM_OSD_PKGDIR)/files/S96waybeam-osd \
		$(TARGET_DIR)/etc/init.d/S96waybeam-osd
endef

$(eval $(generic-package))

