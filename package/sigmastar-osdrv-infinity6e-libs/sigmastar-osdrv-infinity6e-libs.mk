################################################################################
#
# sigmastar-osdrv-infinity6e-libs
#
################################################################################

SIGMASTAR_OSDRV_INFINITY6E_LIBS_VERSION = cc4dc004b80ad73b6ef26ab0cf1fa5d80851c232
SIGMASTAR_OSDRV_INFINITY6E_LIBS_SITE = https://github.com/OpenIPC/firmware.git
SIGMASTAR_OSDRV_INFINITY6E_LIBS_SITE_METHOD = git
SIGMASTAR_OSDRV_INFINITY6E_LIBS_LICENSE = Proprietary
SIGMASTAR_OSDRV_INFINITY6E_LIBS_INSTALL_STAGING = YES

# Where the prebuilt libs live inside the OpenIPC/firmware repo:
SIGMASTAR_OSDRV_INFINITY6E_LIBS_SRC_LIBDIR = \
	general/package/sigmastar-osdrv-infinity6e/files/lib

define SIGMASTAR_OSDRV_INFINITY6E_LIBS_INSTALL_STAGING_CMDS
	$(INSTALL) -d $(STAGING_DIR)/usr/lib
	# Copy all MI libs into staging for link-time
	cp -a $(@D)/$(SIGMASTAR_OSDRV_INFINITY6E_LIBS_SRC_LIBDIR)/* \
		$(STAGING_DIR)/usr/lib/
endef

define SIGMASTAR_OSDRV_INFINITY6E_LIBS_INSTALL_TARGET_CMDS
	$(INSTALL) -d $(TARGET_DIR)/usr/lib
	# Copy all MI libs into target for runtime
	cp -a $(@D)/$(SIGMASTAR_OSDRV_INFINITY6E_LIBS_SRC_LIBDIR)/* \
		$(TARGET_DIR)/usr/lib/
endef

$(eval $(generic-package))
