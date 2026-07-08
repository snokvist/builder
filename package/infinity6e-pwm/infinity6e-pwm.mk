################################################################################
#
# infinity6e-pwm
#
################################################################################

INFINITY6E_PWM_DEPENDENCIES = linux
INFINITY6E_PWM_PATCH_DIR = $(BR2_EXTERNAL_GENERAL_PATH)/package/infinity6e-pwm/patches

# Buildroot parses EVERY package .mk regardless of whether the package is
# selected, so this must be guarded — otherwise the Infinity6E PWM kernel
# patch is appended to LINUX_PATCHES on non-6E builds and fails to apply.
# It targets drivers/sstar/pwm/infinity6e/mhal_pwm.h, which only exists in
# the 6E kernel tree (Infinity6C/Maruko has drivers/sstar/pwm/infinity6c),
# and two of its four include/linux/pwm.h hunks reject there as well.
ifeq ($(BR2_PACKAGE_INFINITY6E_PWM),y)
LINUX_PATCHES += $(INFINITY6E_PWM_PATCH_DIR)
endif

$(eval $(generic-package))
