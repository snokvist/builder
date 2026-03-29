################################################################################
#
# waybeam-distribution-star6e
#
################################################################################

WAYBEAM_DISTRIBUTION_STAR6E_LICENSE = Autod Personal Use License

# No download, no build — installs bundled files only

define WAYBEAM_DISTRIBUTION_STAR6E_INSTALL_TARGET_CMDS
	# Sensor tuning profiles
	$(INSTALL) -d $(TARGET_DIR)/etc/sensors
	$(INSTALL) -m 0644 $(WAYBEAM_DISTRIBUTION_STAR6E_PKGDIR)/files/imx335_spike5_colortrans.bin \
		$(TARGET_DIR)/etc/sensors/imx335_spike5_colortrans.bin
	$(INSTALL) -m 0644 $(WAYBEAM_DISTRIBUTION_STAR6E_PKGDIR)/files/imx415_greg_fpvXVIII-gpt200.bin \
		$(TARGET_DIR)/etc/sensors/imx415_greg_fpvXVIII-gpt200.bin
endef

$(eval $(generic-package))
