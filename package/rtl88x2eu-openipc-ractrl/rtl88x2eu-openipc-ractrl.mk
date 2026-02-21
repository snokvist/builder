################################################################################
#
# rtl88x2eu-openipc-ractrl
#
################################################################################

RTL88X2EU_OPENIPC_RACTRL_SITE = https://github.com/snokvist/rtl88x2eu-20230815.git
RTL88X2EU_OPENIPC_RACTRL_VERSION = d81ae8c7426a4fb2d1d50bb254db176e8fa23d1d
RTL88X2EU_OPENIPC_RACTRL_SITE_METHOD = git
RTL88X2EU_OPENIPC_RACTRL_LICENSE = GPL-2.0
RTL88X2EU_OPENIPC_RACTRL_LICENSE_FILES = COPYING

RTL88X2EU_OPENIPC_RACTRL_MODULE_MAKE_OPTS = CONFIG_RTL8822EU=m \
	KVER=$(LINUX_VERSION_PROBED) \
	KSRC=$(LINUX_DIR)

$(eval $(kernel-module))
$(eval $(generic-package))
