################################################################################
#
# waybeam
#
################################################################################

# Pinned: an image is a tested set. 0.90.0 (#148).
WAYBEAM_VERSION = 2ca7b6bd43b40d3c13f1dc848b1d0cf7dd8174fc
WAYBEAM_SITE = https://github.com/OpenIPC/waybeam.git
WAYBEAM_SITE_METHOD = git
WAYBEAM_GIT_SUBMODULES = YES
WAYBEAM_LICENSE = MIT
WAYBEAM_LICENSE_FILES = LICENSE

ifeq ($(OPENIPC_SOC_FAMILY),hi3516cv6xx)
# Hi3516CV610. After upstream OpenIPC/firmware's arm (#2860) for the daemon,
# the IMX662 plugin and the vendor MPP libraries, plus the encoder's own
# runtime: its init script and module loader (load-cv610-online, which sets
# the sensor clock and the audio modules; the image's S70vendor steps aside
# for it) and its sys_config/PM kernel modules, built here against this
# kernel. Not installed: libbin.so, the vendor PQ library, so
# isp.sensorBin and /api/v1/iq/export_bin are no-ops.
WAYBEAM_SOC = cv610
WAYBEAM_CV610_MPP_LIB_DIR = $(HISILICON_OSDRV_HI3516CV6XX_PKGDIR)/files/lib
# The set the daemon's link line reaches, closed over DT_NEEDED (upstream).
WAYBEAM_CV610_MPP_LIBS = \
	libaac_comm.so libaac_dec.so libaac_enc.so libaac_sbr_dec.so \
	libaac_sbr_enc.so libacs.so libbnr.so libcalcflicker.so libdehaze.so \
	libdnvqe.so libdrc.so libextend_stats.so libir_auto.so libldci.so \
	libmp3_dec.so libmp3_enc.so libmp3_lame.so libopus.so libot_mpi_isp.so \
	libot_osal.so libsecurec.so libss_mpi.so libss_mpi_ae.so \
	libss_mpi_audio.so libss_mpi_audio_adp.so libss_mpi_awb.so \
	libss_mpi_isp.so libss_mpi_sysbind.so libss_mpi_sysmem.so libupvqe.so \
	libvoice_engine.so
WAYBEAM_MAKE_OPTS = SOC_BUILD=cv610 CV610_CC="$(TARGET_CC)" \
	CV610_SDK_INC="$(HISILICON_OPENSDK_DIR)" \
	CV610_SDK_LIB="$(WAYBEAM_CV610_MPP_LIB_DIR)"
WAYBEAM_DEPENDENCIES += hisilicon-osdrv-hi3516cv6xx hisilicon-opensdk opus-openipc linux

define WAYBEAM_BUILD_CMDS
	$(MAKE) -C $(@D) build sensor-cv610 $(WAYBEAM_MAKE_OPTS)
	$(MAKE) -C $(@D)/drivers/cv610 modules KSRC="$(LINUX_DIR)" \
		SDK="$(HISILICON_OPENSDK_DIR)" CROSS="$(TARGET_CROSS)"
endef

define WAYBEAM_INSTALL_TARGET_CMDS
	$(INSTALL) -m 0755 -D $(@D)/out/cv610/waybeam $(TARGET_DIR)/usr/bin/waybeam
	$(INSTALL) -m 0755 -D $(@D)/init.d/load-cv610-online \
		$(TARGET_DIR)/usr/bin/load-cv610-online
	$(INSTALL) -m 0644 -D $(@D)/config/waybeam.default.cv610.json \
		$(TARGET_DIR)/etc/waybeam.json
	$(INSTALL) -m 0644 -D $(@D)/config/waybeam-cv610-platform.conf \
		$(TARGET_DIR)/etc/waybeam-cv610.conf
	$(INSTALL) -m 0644 -D $(@D)/sensors/cv610/imx662/libsns_imx662.so \
		$(TARGET_DIR)/usr/lib/cv610/libsns_imx662.so
	$(INSTALL) -m 0644 -t $(TARGET_DIR)/usr/lib/cv610 $(@D)/drivers/cv610/build/*.ko
	$(INSTALL) -m 0644 -t $(TARGET_DIR)/usr/lib \
		$(addprefix $(WAYBEAM_CV610_MPP_LIB_DIR)/,$(WAYBEAM_CV610_MPP_LIBS))
endef

define WAYBEAM_INSTALL_INIT_SYSV
	$(INSTALL) -m 0755 -D $(@D)/init.d/S95waybeam.cv610 \
		$(TARGET_DIR)/etc/init.d/S95waybeam
endef

else
# The encoder ships a single source tree with two SoC backends selected by
# SOC_BUILD. Derive it from the target SoC family and build with Buildroot's
# toolchain; CC_BIN / CC_MARUKO_BIN point the tree's toolchain check at the
# same compiler so it does not fetch its own. The `stage` target also lays out
# the Maruko sensor modules and ISP bins under out/maruko/.
ifeq ($(OPENIPC_SOC_FAMILY),infinity6c)
WAYBEAM_SOC = maruko
WAYBEAM_MAKE_OPTS = SOC_BUILD=maruko MARUKO_CC="$(TARGET_CC)" CC_MARUKO_BIN="$(TARGET_CC)"
# Built after the stock sensor and MI-library packages so the modified Maruko
# sensor modules install over the stock sensor_imx*_mipi.ko names.
WAYBEAM_DEPENDENCIES += sigmastar-osdrv-sensors sigmastar-osdrv-infinity6c
else
WAYBEAM_SOC = star6e
WAYBEAM_MAKE_OPTS = SOC_BUILD=star6e STAR6E_CC="$(TARGET_CC)" CC_BIN="$(TARGET_CC)"
endif

define WAYBEAM_BUILD_CMDS
	$(MAKE) -C $(@D) stage json_cli $(WAYBEAM_MAKE_OPTS)
endef

define WAYBEAM_INSTALL_TARGET_CMDS
	$(INSTALL) -m 0755 -D $(@D)/out/$(WAYBEAM_SOC)/waybeam \
		$(TARGET_DIR)/usr/bin/waybeam
	$(INSTALL) -m 0755 -D $(@D)/out/$(WAYBEAM_SOC)/json_cli \
		$(TARGET_DIR)/usr/bin/json_cli
	$(INSTALL) -m 0644 -D $(WAYBEAM_PKGDIR)/files/waybeam.json \
		$(TARGET_DIR)/etc/waybeam.json
endef

# The encoder dlopens the SigmaStar MI libraries at runtime. They are
# installed to /usr/lib by sigmastar-osdrv-infinity6{e,c}, which does so
# only when Majestic is not selected; waybeam depends on !MAJESTIC, so
# that path always applies and the package ships no libraries itself.

# Infinity6C (Maruko) has no in-tree modules for these sensors and Waybeam
# uses its own modified imx335/imx415 drivers. Install them under the stock
# _mipi.ko names, plus the matching ISP tuning bins.
ifeq ($(WAYBEAM_SOC),maruko)
define WAYBEAM_INSTALL_MARUKO_SENSORS
	$(INSTALL) -m 0644 -D $(@D)/out/maruko/drivers/sensor_imx335_mipi.ko \
		$(TARGET_DIR)/lib/modules/5.10.61/sigmastar/sensor_imx335_mipi.ko
	$(INSTALL) -m 0644 -D $(@D)/out/maruko/drivers/sensor_imx415_mipi.ko \
		$(TARGET_DIR)/lib/modules/5.10.61/sigmastar/sensor_imx415_mipi.ko
	$(INSTALL) -m 0644 -D $(@D)/out/maruko/isp-bins/imx335.bin \
		$(TARGET_DIR)/etc/sensors/imx335.bin
	$(INSTALL) -m 0644 -D $(@D)/out/maruko/isp-bins/imx415.bin \
		$(TARGET_DIR)/etc/sensors/imx415.bin
endef
WAYBEAM_POST_INSTALL_TARGET_HOOKS += WAYBEAM_INSTALL_MARUKO_SENSORS
endif

# BR2_PACKAGE_WAYBEAM_STAR6E_OWN (Infinity6E): the encoder's own imx335/imx415
# drivers, whose modes its config names (the stock drivers list different
# ones: the same sensor.mode selects another resolution), built here against
# this kernel and installed under the stock _mipi.ko names after the stock
# modules, so they win. And its own init script, which raises
# net.unix.max_dgram_qlen for unix:// output.
ifeq ($(BR2_PACKAGE_WAYBEAM_STAR6E_OWN),y)
WAYBEAM_DEPENDENCIES += sigmastar-osdrv-sensors linux
define WAYBEAM_BUILD_STAR6E_SENSORS
	$(MAKE) -C $(@D)/drivers sensor SOC=star6e \
		KSRC="$(LINUX_DIR)" CROSS="$(TARGET_CROSS)"
endef
WAYBEAM_POST_BUILD_HOOKS += WAYBEAM_BUILD_STAR6E_SENSORS
define WAYBEAM_INSTALL_STAR6E_SENSORS
	$(INSTALL) -m 0644 -D $(@D)/drivers/sensor_imx335_star6e.ko \
		$(TARGET_DIR)/lib/modules/$(LINUX_VERSION_PROBED)/sigmastar/sensor_imx335_mipi.ko
	$(INSTALL) -m 0644 -D $(@D)/drivers/sensor_imx415_star6e.ko \
		$(TARGET_DIR)/lib/modules/$(LINUX_VERSION_PROBED)/sigmastar/sensor_imx415_mipi.ko
endef
WAYBEAM_POST_INSTALL_TARGET_HOOKS += WAYBEAM_INSTALL_STAR6E_SENSORS
WAYBEAM_INIT_SCRIPT = $(@D)/init.d/S95waybeam
else
WAYBEAM_INIT_SCRIPT = $(WAYBEAM_PKGDIR)/files/S95waybeam
endif

define WAYBEAM_INSTALL_INIT_SYSV
	$(INSTALL) -m 0755 -D $(WAYBEAM_INIT_SCRIPT) \
		$(TARGET_DIR)/etc/init.d/S95waybeam
endef

endif

$(eval $(generic-package))
