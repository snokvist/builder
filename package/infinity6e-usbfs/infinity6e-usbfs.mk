################################################################################
#
# infinity6e-usbfs
#
################################################################################

INFINITY6E_USBFS_DEPENDENCIES = linux
INFINITY6E_USBFS_PATCH_DIR = $(BR2_EXTERNAL_GENERAL_PATH)/package/infinity6e-usbfs/patches

# Same guard as infinity6e-pwm: Buildroot parses every package .mk, so the
# patch dir may join LINUX_PATCHES only when this package is selected. The
# patches are written against openipc/linux sigmastar-infinity6e (4.9.84)
# drivers/usb/core/devio.c.
#
# Carried until OpenIPC/linux#280 is merged. After the merge the tarball
# already holds both changes, patch(1) reports them as reversed and the
# kernel build stops: drop this package and its defconfig line then.
ifeq ($(BR2_PACKAGE_INFINITY6E_USBFS),y)
LINUX_PATCHES += $(INFINITY6E_USBFS_PATCH_DIR)
endif

$(eval $(generic-package))
