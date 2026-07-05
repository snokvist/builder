################################################################################
#
# waybeam
#
################################################################################

WAYBEAM_VERSION = HEAD
WAYBEAM_SITE = https://github.com/OpenIPC/waybeam_venc.git
WAYBEAM_SITE_METHOD = git
WAYBEAM_LICENSE = Autod Personal Use License

# The encoder ships a single source tree with two SoC backends selected by
# SOC_BUILD. Derive it from the target SoC family and build with Buildroot's
# toolchain; CC_BIN / CC_MARUKO_BIN point the tree's toolchain check at the
# same compiler so it does not fetch its own.
ifeq ($(OPENIPC_SOC_FAMILY),infinity6c)
WAYBEAM_SOC = maruko
WAYBEAM_MAKE_OPTS = SOC_BUILD=maruko MARUKO_CC="$(TARGET_CC)" CC_MARUKO_BIN="$(TARGET_CC)"
else
WAYBEAM_SOC = star6e
WAYBEAM_MAKE_OPTS = SOC_BUILD=star6e STAR6E_CC="$(TARGET_CC)" CC_BIN="$(TARGET_CC)"
endif

define WAYBEAM_BUILD_CMDS
	$(MAKE) -C $(@D) build $(WAYBEAM_MAKE_OPTS)
endef

define WAYBEAM_INSTALL_TARGET_CMDS
	$(INSTALL) -m 0755 -D $(@D)/out/$(WAYBEAM_SOC)/waybeam \
		$(TARGET_DIR)/usr/bin/waybeam
	$(INSTALL) -m 0644 -D $(WAYBEAM_PKGDIR)/files/waybeam.json \
		$(TARGET_DIR)/etc/waybeam.json
endef

# The encoder dlopens the SigmaStar MI libraries at runtime. They are
# installed to /usr/lib by sigmastar-osdrv-infinity6{e,c}, which does so
# only when Majestic is not selected; waybeam depends on !MAJESTIC, so
# that path always applies and the package ships no libraries itself.

define WAYBEAM_INSTALL_INIT_SYSV
	$(INSTALL) -m 0755 -D $(WAYBEAM_PKGDIR)/files/S95waybeam \
		$(TARGET_DIR)/etc/init.d/S95waybeam
endef

$(eval $(generic-package))
