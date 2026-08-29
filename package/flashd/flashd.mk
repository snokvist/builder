################################################################################
#
# flashd (pre-built binary from waybeam-releases)
#
# Vendor-neutral on-device firmware flasher, Mode A agent. Built from
# snokvist/flashd as a dynamic ARM binary. The baked flashd.json carries an
# empty board_override which is stamped with the build's SoC model below —
# stock OpenIPC os-release has no BOARD= so flashd's board gate needs it set
# explicitly.
#
################################################################################

FLASHD_VERSION = v0.8.0
FLASHD_SITE = https://github.com/snokvist/waybeam-releases/releases/download/$(FLASHD_VERSION)
FLASHD_LICENSE = Autod Personal Use License

# One tarball cannot serve every board: Infinity6E links glibc
# (arm-openipc-linux-gnueabihf, interpreter /lib/ld-linux-armhf.so.3) and
# Infinity6C links musl (arm-openipc-linux-musleabihf, interpreter
# /lib/ld-musl-armhf.so.1). Neither interpreter exists on the other's rootfs,
# so a mismatched binary fails to exec. Same keying as waybeam-hub.mk.
FLASHD_SOC_FAMILY = $(call qstrip,$(BR2_OPENIPC_SOC_FAMILY))

ifeq ($(FLASHD_SOC_FAMILY),infinity6c)
FLASHD_SOURCE = flashd-maruko-arm.tar.gz
else
FLASHD_SOURCE = flashd-arm.tar.gz
endif

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
