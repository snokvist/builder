################################################################################
#
# waybeam-distribution-star6c
#
################################################################################

WAYBEAM_DISTRIBUTION_STAR6C_LICENSE = Autod Personal Use License

# No download, no build — installs bundled files only

define WAYBEAM_DISTRIBUTION_STAR6C_INSTALL_TARGET_CMDS
	@echo "waybeam-distribution-star6c: no files to install yet"
endef

$(eval $(generic-package))
