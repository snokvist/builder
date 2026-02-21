################################################################################
#
# autod
#
################################################################################

AUTOD_VERSION = 6fc9cee4737912b7ebd321ea22aba3d32f537bf4
AUTOD_SITE = https://github.com/snokvist/autod.git
AUTOD_SITE_METHOD = git
AUTOD_LICENSE = Proprietary

# No external deps needed (civetweb/parson are vendored); links pthread only.

define AUTOD_BUILD_CMDS
	$(TARGET_MAKE_ENV) \
		CFLAGS="$(TARGET_CFLAGS)" \
		CPPFLAGS="$(TARGET_CPPFLAGS)" \
		LDFLAGS="$(TARGET_LDFLAGS)" \
		$(MAKE) -C $(@D) \
			CC="$(TARGET_CC)" \
			STRIP="$(TARGET_STRIP)" \
			PREFIX="/usr"
endef

define AUTOD_INSTALL_TARGET_CMDS
	# Binary
	$(INSTALL) -D -m 0755 $(@D)/autod \
		$(TARGET_DIR)/usr/bin/autod

	$(INSTALL) -d $(TARGET_DIR)/usr/share/autod/vtx

	# Exec handler + optional .msg helpers
	$(INSTALL) -D -m 0755 $(@D)/scripts/vtx/exec-handler.sh \
		$(TARGET_DIR)/usr/share/autod/vtx/exec-handler.sh
	@if ls $(@D)/scripts/vtx/*.msg >/dev/null 2>&1; then \
		$(INSTALL) -d $(TARGET_DIR)/usr/share/autod/vtx; \
		for f in $(@D)/scripts/vtx/*.msg; do \
			$(INSTALL) -m 0644 $$f $(TARGET_DIR)/usr/share/autod/vtx/; \
		done; \
	fi

	# Config
	$(INSTALL) -d $(TARGET_DIR)/etc/autod
	$(INSTALL) -m 0644 $(@D)/configs/autod_vtx.conf \
		$(TARGET_DIR)/etc/autod/autod.conf

endef

# SysV init (BusyBox/sysvinit)
define AUTOD_INSTALL_INIT_SYSV
	$(INSTALL) -D -m 0755 $(AUTOD_PKGDIR)/files/S99autod \
		$(TARGET_DIR)/etc/init.d/S99autod
endef

$(eval $(generic-package))
