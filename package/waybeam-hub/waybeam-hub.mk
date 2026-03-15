################################################################################
#
# waybeam-hub (vehicle build)
#
################################################################################

WAYBEAM_HUB_VERSION = main
WAYBEAM_HUB_SITE = https://github.com/snokvist/waybeam-hub.git
WAYBEAM_HUB_SITE_METHOD = git
WAYBEAM_HUB_LICENSE = Autod Personal Use License
WAYBEAM_HUB_DEPENDENCIES = sigmastar-osdrv-infinity6e-libs

# LVGL is a git submodule — fetch it
WAYBEAM_HUB_GIT_SUBMODULES = YES

# Vehicle cross-compile: use the Buildroot toolchain directly
# The Makefile's vehicle target expects VEHICLE_CC and paths to SDK/sysroot
define WAYBEAM_HUB_BUILD_CMDS
	$(MAKE) -C $(@D) vehicle \
		VEHICLE_CC="$(TARGET_CC)" \
		VEHICLE_TOOLCHAIN="$(HOST_DIR)" \
		VEHICLE_SYSROOT="$(STAGING_DIR)" \
		VEHICLE_SDK="$(@D)/vendor/sigmastar" \
		VEHICLE_DRV="$(STAGING_DIR)/usr/lib" \
		LVGL_DIR="$(@D)/lvgl"
endef

define WAYBEAM_HUB_INSTALL_TARGET_CMDS
	$(INSTALL) -m 0755 -D $(@D)/build/vehicle/waybeam_hub \
		$(TARGET_DIR)/usr/bin/waybeam_hub
	$(INSTALL) -m 0644 -D $(@D)/configs/waybeam_vehicle.conf \
		$(TARGET_DIR)/etc/waybeam_hub/waybeam_vehicle.conf
	$(INSTALL) -m 0755 -D $(@D)/scripts/S97waybeam-hub_vehicle \
		$(TARGET_DIR)/etc/init.d/S97waybeam-hub
endef

$(eval $(generic-package))
