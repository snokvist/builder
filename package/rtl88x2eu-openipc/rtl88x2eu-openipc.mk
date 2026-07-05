################################################################################
#
# rtl88x2eu-openipc
#
# Waybeam overlay of the upstream OpenIPC package (copied over it by
# builder.sh copy_extra_packages, so this .mk replaces the shared one for
# EVERY device that builds rtl88x2eu). On the Waybeam eu air unit it enables
# the driver per-rate TXAGC: ships /lib/firmware/PHY_REG_PG.txt +
# /etc/modprobe.d/realtek_88x2eu.conf (rtw_tx_pwr_by_rate=1,
# rtw_tx_pwr_lmt_enable=0) and flips radio.tx_pwr_by_rate -> true in
# /etc/wfb-link.json.
#
# SCOPING: many non-Waybeam OpenIPC fpv/rubyfpv devices also build this driver
# (BR2_PACKAGE_RTL88X2EU_OPENIPC=y), so the TXAGC enable is guarded on
# BR2_PACKAGE_WFB_AIR — set ONLY by the waybeam_* defconfigs (the wfb-ng air
# line). Non-Waybeam images build the driver exactly as upstream: no wfb-air
# dependency, no assets, no flag flip. Within the Waybeam family only the eu
# variant builds this package (cu/bu use other Realtek drivers), so the guard
# resolves to "Waybeam eu".
#
################################################################################

RTL88X2EU_OPENIPC_SITE = $(call github,libc0607,rtl88x2eu-20230815,$(RTL88X2EU_OPENIPC_VERSION))
RTL88X2EU_OPENIPC_VERSION = HEAD

RTL88X2EU_OPENIPC_LICENSE = GPL-2.0
RTL88X2EU_OPENIPC_LICENSE_FILES = COPYING

RTL88X2EU_OPENIPC_MODULE_MAKE_OPTS = CONFIG_RTL8822EU=m \
	KVER=$(LINUX_VERSION_PROBED) \
	KSRC=$(LINUX_DIR)

# TXAGC enable — guarded on BR2_PACKAGE_WFB_AIR so ONLY Waybeam wfb-ng air
# images (the eu variant) get the dependency, assets, and flag flip; every
# other OpenIPC device that builds this driver is left as plain upstream.
ifeq ($(BR2_PACKAGE_WFB_AIR),y)

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

endif # BR2_PACKAGE_WFB_AIR

$(eval $(kernel-module))
$(eval $(generic-package))
