################################################################################
#
# waybeam-hub (vehicle build — pre-built binary from waybeam-releases)
#
################################################################################

WAYBEAM_HUB_VERSION = v0.8.0
WAYBEAM_HUB_SITE = https://github.com/snokvist/waybeam-releases/releases/download/$(WAYBEAM_HUB_VERSION)
WAYBEAM_HUB_LICENSE = Autod Personal Use License

# The prebuilt is libc-specific, so one tarball cannot serve every board:
# Infinity6E links glibc (arm-openipc-linux-gnueabihf) while Infinity6C links
# musl (arm-openipc-linux-musleabihf). The vehicle tarball asks for
# /lib/ld-linux-armhf.so.3, which an Infinity6C rootfs does not have, so it
# fails to exec rather than misbehaving — and the MI_RGN ABI differs on top of
# that (Infinity6C takes a u16SocId arg on every MI_RGN_* call). Pick per SoC
# family; anything that is not Infinity6C keeps the historical vehicle build.
WAYBEAM_HUB_SOC_FAMILY = $(call qstrip,$(BR2_OPENIPC_SOC_FAMILY))

ifeq ($(WAYBEAM_HUB_SOC_FAMILY),infinity6c)
WAYBEAM_HUB_SOURCE = waybeam-hub-maruko-arm.tar.gz
else
WAYBEAM_HUB_SOURCE = waybeam-hub-vehicle-arm.tar.gz
endif

# json_cli: built from source files bundled in package/files/
define WAYBEAM_HUB_BUILD_CMDS
	$(TARGET_CC) -Os -Wall -Wextra -std=c11 -D_GNU_SOURCE \
		-include stddef.h -I$(WAYBEAM_HUB_PKGDIR)/files \
		-o $(@D)/json_cli \
		$(WAYBEAM_HUB_PKGDIR)/files/json_cli.c -lm
endef

define WAYBEAM_HUB_INSTALL_TARGET_CMDS
	$(INSTALL) -m 0755 -D $(@D)/waybeam_hub \
		$(TARGET_DIR)/usr/bin/waybeam_hub
	$(INSTALL) -m 0755 -D $(@D)/json_cli \
		$(TARGET_DIR)/usr/bin/json_cli
	$(INSTALL) -m 0644 -D $(WAYBEAM_HUB_PKGDIR)/files/waybeam_vehicle.conf \
		$(TARGET_DIR)/etc/waybeam_hub/waybeam_vehicle.conf
	$(INSTALL) -m 0644 -D $(WAYBEAM_HUB_PKGDIR)/files/waybeam_osd.json \
		$(TARGET_DIR)/etc/waybeam_osd.json
	$(INSTALL) -m 0755 -D $(WAYBEAM_HUB_PKGDIR)/files/S97waybeam-hub \
		$(TARGET_DIR)/etc/init.d/S97waybeam-hub
endef

$(eval $(generic-package))
