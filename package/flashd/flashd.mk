################################################################################
#
# flashd (pre-built binary from waybeam-releases)
#
# Vendor-neutral on-device firmware flasher, Mode A agent. Built from
# snokvist/flashd (dynamic ARM, SigmaStar Infinity6E glibc). The baked
# flashd.json carries an empty board_override which is stamped with the
# build's SoC model below — stock OpenIPC os-release has no BOARD= so
# flashd's board gate needs it set explicitly.
#
################################################################################

FLASHD_VERSION = v0.8.0
FLASHD_SITE = https://github.com/snokvist/waybeam-releases/releases/download/$(FLASHD_VERSION)
FLASHD_SOURCE = flashd-arm.tar.gz
FLASHD_LICENSE = Autod Personal Use License

FLASHD_SOC_MODEL = $(call qstrip,$(BR2_OPENIPC_SOC_MODEL))

define FLASHD_INSTALL_TARGET_CMDS
	$(INSTALL) -m 0755 -D $(@D)/flashd \
		$(TARGET_DIR)/usr/bin/flashd
	$(INSTALL) -m 0644 -D $(FLASHD_PKGDIR)/files/flashd.json \
		$(TARGET_DIR)/etc/flashd.json
	$(SED) 's|"board_override": *""|"board_override": "$(FLASHD_SOC_MODEL)"|' \
		$(TARGET_DIR)/etc/flashd.json
	$(INSTALL) -m 0644 -D $(FLASHD_PKGDIR)/files/sources.json \
		$(TARGET_DIR)/etc/flashd/sources.json
endef

define FLASHD_INSTALL_INIT_SYSV
	$(INSTALL) -m 0755 -D $(FLASHD_PKGDIR)/files/S98flashd \
		$(TARGET_DIR)/etc/init.d/S98flashd
endef

$(eval $(generic-package))
