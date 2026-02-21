################################################################################
#
# aalink (binary-only, shipped in package/aalink/files)
#
################################################################################

AALINK_LICENSE = Proprietary
AALINK_LICENSE_FILES = LICENSE  # optional: only if you actually ship one in the package dir

# No download / no build: we just install prebuilt bits from files/
define AALINK_INSTALL_TARGET_CMDS
	# Binary -> /usr/bin (adjust name/path to match your files/)
	$(INSTALL) -D -m 0755 $(AALINK_PKGDIR)/files/aalink \
		$(TARGET_DIR)/usr/bin/aalink

	$(INSTALL) -D -m 0644 $(AALINK_PKGDIR)/files/aalink.conf \
		$(TARGET_DIR)/etc/aalink.conf
endef

define AALINK_INSTALL_INIT_SYSV
	# Init script -> /etc/init.d
	$(INSTALL) -D -m 0755 $(AALINK_PKGDIR)/files/S99aalink \
		$(TARGET_DIR)/etc/init.d/S99aalink
	$(INSTALL) -D -m 0755 $(AALINK_PKGDIR)/files/S99osd_send \
		$(TARGET_DIR)/etc/init.d/S99osd_send
endef

$(eval $(generic-package))

