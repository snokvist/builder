################################################################################
#
# waybeam-hub (vehicle build)
#
################################################################################

WAYBEAM_HUB_VERSION = main
WAYBEAM_HUB_SITE = https://github.com/snokvist/waybeam-hub.git
WAYBEAM_HUB_SITE_METHOD = git
WAYBEAM_HUB_LICENSE = Autod Personal Use License

# LVGL is a git submodule — fetch it
WAYBEAM_HUB_GIT_SUBMODULES = YES

# Vehicle cross-compile: use the Buildroot toolchain directly
# Links against vendored MI libs in vendor/sigmastar/lib (no staging dep needed)
define WAYBEAM_HUB_BUILD_CMDS
	$(MAKE) -C $(@D) vehicle \
		VEHICLE_CC="$(TARGET_CC)" \
		VEHICLE_TOOLCHAIN="$(HOST_DIR)" \
		VEHICLE_SYSROOT="$(STAGING_DIR)" \
		VEHICLE_SDK="$(@D)/vendor/sigmastar" \
		VEHICLE_DRV="$(@D)/vendor/sigmastar/lib" \
		LVGL_DIR="$(@D)/lvgl"
	# json_cli tool (standalone, single .c file)
	mkdir -p $(@D)/build/tools
	$(TARGET_CC) -Os -Wall -Wextra -std=c11 -D_GNU_SOURCE \
		-include stddef.h -I$(@D)/tools -o $(@D)/build/tools/json_cli \
		$(@D)/tools/json_cli.c -lm
endef

define WAYBEAM_HUB_INSTALL_TARGET_CMDS
	$(INSTALL) -m 0755 -D $(@D)/build/vehicle/waybeam_hub \
		$(TARGET_DIR)/usr/bin/waybeam_hub
	$(INSTALL) -m 0755 -D $(@D)/build/tools/json_cli \
		$(TARGET_DIR)/usr/bin/json_cli
	$(INSTALL) -m 0644 -D $(@D)/configs/waybeam_vehicle.conf \
		$(TARGET_DIR)/etc/waybeam_hub/waybeam_vehicle.conf
	$(INSTALL) -m 0644 -D $(@D)/configs/waybeam_osd.json \
		$(TARGET_DIR)/etc/waybeam_osd.json
	$(INSTALL) -m 0644 -D $(@D)/web/waybeam_vehicle.html \
		$(TARGET_DIR)/var/www/waybeam_vehicle.html
	$(INSTALL) -m 0755 -D $(@D)/scripts/S97waybeam-hub_vehicle \
		$(TARGET_DIR)/etc/init.d/S97waybeam-hub
endef

$(eval $(generic-package))
