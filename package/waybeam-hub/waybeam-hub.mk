################################################################################
#
# waybeam-hub (vehicle build — pre-built binary from waybeam-releases)
#
################################################################################

WAYBEAM_HUB_VERSION = v0.6.0-bundled-release
WAYBEAM_HUB_SITE = https://github.com/snokvist/waybeam-releases/releases/download/$(WAYBEAM_HUB_VERSION)
WAYBEAM_HUB_SOURCE = waybeam-hub-vehicle-arm.tar.gz
WAYBEAM_HUB_LICENSE = Autod Personal Use License

# json_cli: built from single C source file bundled in package/files/
define WAYBEAM_HUB_BUILD_CMDS
	$(TARGET_CC) -Os -Wall -Wextra -std=c11 -D_GNU_SOURCE \
		-include stddef.h -o $(@D)/json_cli \
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
