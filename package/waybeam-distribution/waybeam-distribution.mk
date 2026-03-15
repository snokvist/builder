################################################################################
#
# waybeam-distribution
#
################################################################################

WAYBEAM_DISTRIBUTION_LICENSE = Autod Personal Use License

# No download, no build — installs bundled files only

define WAYBEAM_DISTRIBUTION_INSTALL_TARGET_CMDS
	# Sensor tuning profiles
	$(INSTALL) -d $(TARGET_DIR)/etc/sensors
	$(INSTALL) -m 0644 $(WAYBEAM_DISTRIBUTION_PKGDIR)/files/imx335_greg_fpvVII-gpt200.bin \
		$(TARGET_DIR)/etc/sensors/imx335_greg_fpvVII-gpt200.bin
	$(INSTALL) -m 0644 $(WAYBEAM_DISTRIBUTION_PKGDIR)/files/imx415_greg_fpvXVIII-gpt200.bin \
		$(TARGET_DIR)/etc/sensors/imx415_greg_fpvXVIII-gpt200.bin
endef

$(eval $(generic-package))
