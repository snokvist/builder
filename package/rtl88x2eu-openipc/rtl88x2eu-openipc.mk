################################################################################
#
# rtl88x2eu-openipc
#
# Waybeam overlay of the upstream OpenIPC package (copied over it by
# builder.sh copy_extra_packages). Adds the eu-vehicle per-rate TXAGC enable:
# ships /lib/firmware/PHY_REG_PG.txt + /etc/modprobe.d/realtek_88x2eu.conf
# (rtw_tx_pwr_by_rate=1, rtw_tx_pwr_lmt_enable=0) and flips
# radio.tx_pwr_by_rate -> true in /etc/wfb-link.json. All three are scoped to
# the eu image automatically: only the *_eu defconfigs set
# BR2_PACKAGE_RTL88X2EU_OPENIPC=y, so cu/bu images never run these hooks.
#
################################################################################

RTL88X2EU_OPENIPC_SITE = $(call github,libc0607,rtl88x2eu-20230815,$(RTL88X2EU_OPENIPC_VERSION))
RTL88X2EU_OPENIPC_VERSION = HEAD

RTL88X2EU_OPENIPC_LICENSE = GPL-2.0
RTL88X2EU_OPENIPC_LICENSE_FILES = COPYING

RTL88X2EU_OPENIPC_MODULE_MAKE_OPTS = CONFIG_RTL8822EU=m \
	KVER=$(LINUX_VERSION_PROBED) \
	KSRC=$(LINUX_DIR)

# Flip the shared wfb-link.json flag after wfb-air has installed it, so the
# eu air uses `iw txpower auto` + link_controller --tx-pwr-by-rate.
#
# CO-REQUISITE: the flag only takes effect once the wfb-air mega binary
# understands it — i.e. WFB_AIR_VERSION (package/wfb-air/wfb-air.mk) points at a
# waybeam-releases build that carries config-env `WFB_TX_PWR_BY_RATE` emit AND
# link_controller `--tx-pwr-by-rate` (waybeam_wfb_ng per-rate-txagc branch,
# > v0.8.1). With an older binary the flip is inert-safe: config-env never emits
# the var, S99wfb takes the legacy `iw txpower fixed` path, and link_controller
# is never handed the unknown option. Bump WFB_AIR_VERSION before relying on the
# eu image to enable the curve. Bench-verify on the vehicle first (see
# files/PHY_REG_PG.txt header).
RTL88X2EU_OPENIPC_DEPENDENCIES += wfb-air

# Per-rate TXAGC assets + wfb-link.json flag flip. The driver reads
# /lib/firmware/PHY_REG_PG.txt at load because CONFIG_LOAD_PHY_PARA_FROM_FILE=y
# and REALTEK_CONFIG_PATH="/lib/firmware/" (no IC-name subfolder).
define RTL88X2EU_OPENIPC_WAYBEAM_TXAGC
	$(INSTALL) -m 0644 -D $(RTL88X2EU_OPENIPC_PKGDIR)/files/PHY_REG_PG.txt \
		$(TARGET_DIR)/lib/firmware/PHY_REG_PG.txt
	$(INSTALL) -m 0644 -D $(RTL88X2EU_OPENIPC_PKGDIR)/files/realtek_88x2eu.conf \
		$(TARGET_DIR)/etc/modprobe.d/realtek_88x2eu.conf
	if [ -f $(TARGET_DIR)/etc/wfb-link.json ]; then \
		$(SED) 's/"tx_pwr_by_rate": *false/"tx_pwr_by_rate": true/' \
			$(TARGET_DIR)/etc/wfb-link.json ; \
	fi
endef
RTL88X2EU_OPENIPC_POST_INSTALL_TARGET_HOOKS += RTL88X2EU_OPENIPC_WAYBEAM_TXAGC

$(eval $(kernel-module))
$(eval $(generic-package))
